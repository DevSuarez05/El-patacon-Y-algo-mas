import { PrismaClient } from '@prisma/client';
import { v7 as uuidv7 } from 'uuid';
import { hashSecret } from '../src/shared/password';

const ROLES = [
  ['ADMIN', 'Administrador'],
  ['OWNER', 'Propietario'],
  ['CASHIER', 'Cajero'],
  ['WAITER', 'Mesero'],
  ['KITCHEN', 'Cocina'],
  ['WAREHOUSE', 'Bodega'],
  ['SUPERVISOR', 'Supervisor'],
] as const;

const PERMISSIONS = [
  ['cash_drawer.read', 'Ver las cajas de la sede de la sesión'],
  ['branch.read', 'Ver la sede de la sesión'],
  ['discount.authorize', 'Autorizar un descuento'],
  ['sale.void', 'Anular una venta'],
  ['waste.record', 'Registrar una merma'],
  ['inventory.adjust', 'Ajustar inventario'],
  ['noshow.resolve', 'Tratar un no-show'],
  ['shift.close_with_difference', 'Cerrar un turno con diferencia'],
  ['refund.record', 'Registrar una devolución'],
] as const;

const ALL = PERMISSIONS.map(([code]) => code);

const ROLE_GRANTS: Record<(typeof ROLES)[number][0], readonly string[]> = {
  ADMIN: ALL,
  OWNER: ALL,
  SUPERVISOR: ALL,
  CASHIER: [
    'cash_drawer.read',
    'branch.read',
    'discount.authorize',
    'sale.void',
    'shift.close_with_difference',
    'refund.record',
  ],
  WAITER: ['branch.read'],
  KITCHEN: ['branch.read'],
  WAREHOUSE: ['branch.read', 'inventory.adjust', 'waste.record'],
};

const DEV_DRAWER_NOTE =
  'Dato de desarrollo. La cantidad real de cajas sigue pendiente y esta fila no la decide.';

export async function seed(prisma: PrismaClient): Promise<{
  organizationId: string;
  branchId: string;
  adminUserId: string;
  drawerId: string;
  stationId: string;
}> {
  const email = process.env.SEED_ADMIN_EMAIL ?? 'admin@local.test';
  const password = process.env.SEED_ADMIN_PASSWORD;
  if (!password || password.length < 8) {
    throw new Error('SEED_ADMIN_PASSWORD debe tener al menos 8 caracteres');
  }

  const organization = await prisma.organization.upsert({
    where: { id: await existingOrganizationId(prisma) },
    update: { name: 'El Patacón – Y algo más' },
    create: { id: uuidv7(), name: 'El Patacón – Y algo más' },
  });

  let branch = await prisma.branch.findFirst({
    where: { organizationId: organization.id, name: 'Sede de desarrollo' },
  });
  if (!branch) {
    branch = await prisma.branch.create({
      data: {
        id: uuidv7(),
        organizationId: organization.id,
        name: 'Sede de desarrollo',
        timezone: 'America/Bogota',
        currencyCode: 'COP',
      },
    });
  }

  const permissionIds = new Map<string, string>();
  for (const [code, description] of PERMISSIONS) {
    const existing = await prisma.permission.findUnique({ where: { code } });
    const row = existing
      ? await prisma.permission.update({
          where: { code },
          data: { description },
        })
      : await prisma.permission.create({
          data: { id: uuidv7(), code, description },
        });
    permissionIds.set(code, row.id);
  }

  const roleIds = new Map<string, string>();
  for (const [code, name] of ROLES) {
    const existing = await prisma.role.findUnique({
      where: {
        organizationId_code: { organizationId: organization.id, code },
      },
    });
    const role = existing ?? (await prisma.role.create({
      data: { id: uuidv7(), organizationId: organization.id, code, name },
    }));
    roleIds.set(code, role.id);
    for (const permissionCode of ROLE_GRANTS[code]) {
      const permissionId = permissionIds.get(permissionCode);
      if (!permissionId) {
        throw new Error(`permiso ausente: ${permissionCode}`);
      }
      await prisma.rolePermission.upsert({
        where: { roleId_permissionId: { roleId: role.id, permissionId } },
        update: {},
        create: { roleId: role.id, permissionId },
      });
    }
  }

  const passwordHash = await hashSecret(password);
  const existingUser = await prisma.user.findUnique({
    where: {
      organizationId_email: {
        organizationId: organization.id,
        email: email.toLowerCase(),
      },
    },
  });
  const admin = existingUser
    ? await prisma.user.update({
        where: { id: existingUser.id },
        data: { passwordHash, displayName: 'Administrador de desarrollo', active: true },
      })
    : await prisma.user.create({
        data: {
          id: uuidv7(),
          organizationId: organization.id,
          email: email.toLowerCase(),
          passwordHash,
          displayName: 'Administrador de desarrollo',
        },
      });

  const adminRoleId = roleIds.get('ADMIN');
  if (!adminRoleId) {
    throw new Error('rol ADMIN ausente');
  }
  const assignment = await prisma.userRole.findFirst({
    where: { userId: admin.id, roleId: adminRoleId, branchId: branch.id },
  });
  if (!assignment) {
    await prisma.userRole.create({
      data: {
        id: uuidv7(),
        organizationId: organization.id,
        branchId: branch.id,
        userId: admin.id,
        roleId: adminRoleId,
      },
    });
  }

  let drawer = await prisma.cashDrawer.findFirst({
    where: { branchId: branch.id, name: 'Caja de desarrollo' },
  });
  if (!drawer) {
    drawer = await prisma.cashDrawer.create({
      data: {
        id: uuidv7(),
        branchId: branch.id,
        name: 'Caja de desarrollo',
        labelNote: DEV_DRAWER_NOTE,
      },
    });
  }

  let station = await prisma.prepStation.findFirst({
    where: { branchId: branch.id, name: 'Estación de desarrollo' },
  });
  if (!station) {
    station = await prisma.prepStation.create({
      data: {
        id: uuidv7(),
        branchId: branch.id,
        name: 'Estación de desarrollo',
        kind: 'KITCHEN',
      },
    });
  }

  const taxRows = await prisma.taxConfiguration.count();
  if (taxRows !== 0) {
    throw new Error('la semilla no debe encontrar tasas configuradas');
  }

  return {
    organizationId: organization.id,
    branchId: branch.id,
    adminUserId: admin.id,
    drawerId: drawer.id,
    stationId: station.id,
  };
}

async function existingOrganizationId(prisma: PrismaClient): Promise<string> {
  const existing = await prisma.organization.findFirst({
    where: { name: 'El Patacón – Y algo más' },
  });
  return existing?.id ?? '00000000-0000-0000-0000-000000000000';
}

async function main(): Promise<void> {
  const prisma = new PrismaClient();
  try {
    await seed(prisma);
  } finally {
    await prisma.$disconnect();
  }
}

if (require.main === module) {
  main().catch((error: unknown) => {
    console.error(error);
    process.exit(1);
  });
}
