import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { PrismaClient } from '@prisma/client';
import request from 'supertest';
import { v7 as uuidv7 } from 'uuid';
import { seed } from '../prisma/seed';
import { AppModule } from './app.module';
import { configureApp } from './configure-app';
import { IdempotencyService } from './shared/idempotency.service';
import { hashSecret } from './shared/password';

describe('Fase 1', () => {
  let app: INestApplication;
  let prisma: PrismaClient;
  let branchId = '';
  let adminId = '';

  beforeAll(async () => {
    prisma = new PrismaClient();
    const seeded = await seed(prisma);
    branchId = seeded.branchId;
    adminId = seeded.adminUserId;
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleRef.createNestApplication();
    configureApp(app);
    await app.init();
  });

  afterAll(async () => {
    await app.close();
    await prisma.$disconnect();
  });

  it('aplicó las 14 migraciones y no sembró una tasa', async () => {
    const migrations = await prisma.$queryRaw<{ migration_name: string }[]>`
      SELECT migration_name FROM _prisma_migrations ORDER BY migration_name
    `;
    expect(migrations).toHaveLength(14);
    const salesColumns = await prisma.$queryRaw<{ column_name: string }[]>`
      SELECT column_name FROM information_schema.columns
      WHERE table_name = 'sales'
    `;
    expect(salesColumns.map((column) => column.column_name)).not.toContain('tip_minor');
    const taxColumns = await prisma.$queryRaw<{ column_name: string }[]>`
      SELECT column_name FROM information_schema.columns
      WHERE table_name = 'tax_configurations'
    `;
    const names = taxColumns.map((column) => column.column_name);
    expect(names).toContain('price_mode');
    expect(names.join(' ')).not.toMatch(/rate/);
    const reservationColumns = await prisma.$queryRaw<{ column_name: string }[]>`
      SELECT column_name FROM information_schema.columns
      WHERE table_name = 'stock_reservations'
    `;
    expect(reservationColumns.map((column) => column.column_name)).toContain('created_at');
    const releasers = await prisma.$queryRaw<{ proname: string }[]>`
      SELECT proname FROM pg_proc
      WHERE proname ILIKE '%release%' OR proname ILIKE '%auto_reserv%'
    `;
    expect(releasers).toHaveLength(0);
    expect(await prisma.taxConfiguration.count()).toBe(0);
    const sessionColumns = await prisma.$queryRaw<{ column_name: string }[]>`
      SELECT column_name FROM information_schema.columns
      WHERE table_name = 'sessions'
    `;
    const sessionNames = sessionColumns.map((column) => column.column_name);
    expect(sessionNames).toContain('token_hash');
    expect(sessionNames).not.toContain('token');
  });

  it('inicia sesión con Argon2id, guarda solo el hash y niega otra sede o un permiso', async () => {
    const password = process.env.SEED_ADMIN_PASSWORD ?? '';
    const login = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email: 'admin@local.test', password, branchId });
    expect(login.status).toBe(201);
    const token = login.body.token as string;
    const session = await prisma.session.findFirst({
      where: { userId: adminId },
      orderBy: { createdAt: 'desc' },
    });
    expect(session?.tokenHash).not.toBe(token);
    expect(session?.tokenHash).toHaveLength(64);
    const admin = await prisma.user.findUniqueOrThrow({ where: { id: adminId } });
    expect(admin.passwordHash.startsWith('$argon2id$')).toBe(true);

    const me = await request(app.getHttpServer())
      .get('/auth/me')
      .set('Authorization', `Bearer ${token}`);
    expect(me.status).toBe(200);
    expect(me.body.permissions).toContain('cash_drawer.read');

    const drawers = await request(app.getHttpServer())
      .get(`/branches/${branchId}/cash-drawers`)
      .set('Authorization', `Bearer ${token}`);
    expect(drawers.status).toBe(200);
    expect(drawers.body[0].name).toBe('Caja de desarrollo');

    const otherBranch = await prisma.branch.create({
      data: {
        id: uuidv7(),
        organizationId: admin.organizationId,
        name: 'Otra sede de prueba',
      },
    });
    const foreign = await request(app.getHttpServer())
      .get(`/branches/${otherBranch.id}/cash-drawers`)
      .set('Authorization', `Bearer ${token}`);
    expect(foreign.status).toBe(403);

    const kitchenRole = await prisma.role.findFirstOrThrow({
      where: { organizationId: admin.organizationId, code: 'KITCHEN' },
    });
    const kitchen = await prisma.user.create({
      data: {
        id: uuidv7(),
        organizationId: admin.organizationId,
        email: `cocina-${uuidv7()}@local.test`,
        passwordHash: await hashSecret(password),
        displayName: 'Cocina de prueba',
      },
    });
    await prisma.userRole.create({
      data: {
        id: uuidv7(),
        organizationId: admin.organizationId,
        branchId,
        userId: kitchen.id,
        roleId: kitchenRole.id,
      },
    });
    const kitchenLogin = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email: kitchen.email, password, branchId });
    const denied = await request(app.getHttpServer())
      .get(`/branches/${branchId}/cash-drawers`)
      .set('Authorization', `Bearer ${kitchenLogin.body.token}`);
    expect(denied.status).toBe(403);
  });

  it('la auditoría y el saldo negativo se comportan como el modelo', async () => {
    const audit = await prisma.auditEvent.findFirstOrThrow();
    await expect(
      prisma.$executeRaw`UPDATE audit_events SET action = 'EDITED' WHERE id = ${audit.id}::uuid`,
    ).rejects.toThrow(/append_only/);

    const unit = await prisma.unit.create({
      data: {
        id: uuidv7(),
        branchId,
        code: `g-${uuidv7()}`,
        name: 'Gramo',
        dimension: 'MASS',
      },
    });
    const item = await prisma.inventoryItem.create({
      data: {
        id: uuidv7(),
        branchId,
        name: 'Ítem de prueba',
        kind: 'INGREDIENT',
        unitId: unit.id,
      },
    });
    const balance = await prisma.stockBalance.create({
      data: {
        id: uuidv7(),
        branchId,
        inventoryItemId: item.id,
        onHandQty: 0,
      },
    });
    await expect(
      prisma.stockBalance.update({
        where: { id: balance.id },
        data: { onHandQty: -1 },
      }),
    ).rejects.toThrow(/negative_stock_requires_exception/);

    const movement = await prisma.stockMovement.create({
      data: {
        id: uuidv7(),
        branchId,
        inventoryItemId: item.id,
        movementType: 'ADJUSTMENT',
        quantity: -1,
        sourceType: 'adjustment',
        idempotencyKey: uuidv7(),
      },
    });
    const exception = await prisma.stockException.create({
      data: {
        id: uuidv7(),
        branchId,
        inventoryItemId: item.id,
        stockMovementId: movement.id,
        authorizerUserId: adminId,
        responsibleUserId: adminId,
        reason: 'Prueba de excepción auditada',
        authorizedQty: 1,
      },
    });
    await prisma.$transaction(async (tx) => {
      await tx.$executeRaw`SELECT set_config('app.stock_exception_id', ${exception.id}, true)`;
      await tx.stockBalance.update({
        where: { id: balance.id },
        data: { onHandQty: -1 },
      });
    });
    const updated = await prisma.stockBalance.findUniqueOrThrow({
      where: { id: balance.id },
    });
    expect(updated.onHandQty.toString()).toBe('-1');
  });

  it('confirma la llave y el efecto juntos, y rechaza otro cuerpo', async () => {
    const idempotency = app.get(IdempotencyService);
    const key = uuidv7();
    const first = await idempotency.commit(
      branchId,
      'foundation.test',
      key,
      { n: 1 },
      async (tx) => {
        await tx.auditEvent.create({
          data: {
            id: uuidv7(),
            organizationId: (await prisma.branch.findUniqueOrThrow({ where: { id: branchId } })).organizationId,
            branchId,
            actorUserId: adminId,
            action: 'IDEMPOTENCY_TEST',
            entityType: 'idempotency',
            payload: { n: 1 },
          },
        });
        return { stored: true, n: 1 };
      },
    );
    const replay = await idempotency.commit(
      branchId,
      'foundation.test',
      key,
      { n: 1 },
      async () => ({ stored: false, n: 1 }),
    );
    expect(replay).toEqual(first);
    await expect(
      idempotency.commit(branchId, 'foundation.test', key, { n: 2 }, async () => ({
        stored: false,
        n: 2,
      })),
    ).rejects.toThrow(/idempotency_body_conflict/);

    const failingKey = uuidv7();
    await expect(
      idempotency.commit(branchId, 'foundation.test', failingKey, { n: 3 }, async () => {
        throw new Error('efecto fallido');
      }),
    ).rejects.toThrow(/efecto fallido/);
    expect(
      await prisma.idempotencyRecord.findFirst({
        where: { requestKey: failingKey },
      }),
    ).toBeNull();
  });

  it('el texto de tarjeta no afirma una confirmación bancaria', async () => {
    const labels = await request(app.getHttpServer()).get('/foundation/tender-labels');
    expect(labels.status).toBe(200);
    expect(labels.body.card).toBe('Registro local atestiguado por el cajero.');
    expect(JSON.stringify(labels.body)).not.toMatch(/confirmaci[oó]n bancaria/i);
    const health = await request(app.getHttpServer()).get('/health');
    expect(health.status).toBe(200);
    const docs = await request(app.getHttpServer()).get('/docs-json');
    expect(docs.status).toBe(200);
    expect(JSON.stringify(docs.body)).not.toMatch(/confirmaci[oó]n bancaria/i);
    expect(docs.body.paths['/payments']).toBeUndefined();
  });
});
