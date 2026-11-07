import {
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { v7 as uuidv7 } from 'uuid';
import { PrismaService } from '../prisma/prisma.service';
import { hashSecret, verifySecret } from '../shared/password';
import { createSessionToken, hashSessionToken } from '../shared/token';
import { SessionContext } from './session';

const SESSION_HOURS = 12;

@Injectable()
export class IdentityService {
  constructor(private readonly prisma: PrismaService) {}

  async login(
    email: string,
    password: string,
    branchId: string,
  ): Promise<{ token: string; expiresAt: string; branchId: string }> {
    const user = await this.prisma.user.findFirst({
      where: { email: email.toLowerCase(), active: true },
      include: {
        userRoles: {
          where: { branchId },
          include: {
            role: {
              include: {
                rolePermissions: { include: { permission: true } },
              },
            },
          },
        },
      },
    });
    if (!user || user.userRoles.length === 0) {
      throw new UnauthorizedException('credenciales invalidas');
    }
    const passwordMatches = await verifySecret(password, user.passwordHash);
    if (!passwordMatches) {
      throw new UnauthorizedException('credenciales invalidas');
    }
    const token = createSessionToken();
    const expiresAt = new Date(Date.now() + SESSION_HOURS * 60 * 60 * 1000);
    const sessionId = uuidv7();
    await this.prisma.$transaction([
      this.prisma.session.create({
        data: {
          id: sessionId,
          userId: user.id,
          branchId,
          tokenHash: hashSessionToken(token),
          expiresAt,
        },
      }),
      this.prisma.auditEvent.create({
        data: {
          id: uuidv7(),
          organizationId: user.organizationId,
          branchId,
          actorUserId: user.id,
          action: 'SESSION_STARTED',
          entityType: 'session',
          entityId: sessionId,
          payload: {},
        },
      }),
    ]);
    return { token, expiresAt: expiresAt.toISOString(), branchId };
  }

  async authenticate(token: string): Promise<SessionContext> {
    const session = await this.prisma.session.findUnique({
      where: { tokenHash: hashSessionToken(token) },
      include: {
        user: true,
        branch: true,
      },
    });
    if (!session || session.expiresAt.getTime() <= Date.now() || !session.user.active) {
      throw new UnauthorizedException('sesion invalida');
    }
    const roles = await this.prisma.userRole.findMany({
      where: { userId: session.userId, branchId: session.branchId },
      include: {
        role: { include: { rolePermissions: { include: { permission: true } } } },
      },
    });
    const permissions = new Set<string>();
    for (const assignment of roles) {
      for (const link of assignment.role.rolePermissions) {
        permissions.add(link.permission.code);
      }
    }
    return {
      sessionId: session.id,
      userId: session.userId,
      organizationId: session.user.organizationId,
      branchId: session.branchId,
      permissions,
    };
  }

  requirePermission(session: SessionContext, permission: string): void {
    if (!session.permissions.has(permission)) {
      throw new ForbiddenException('permiso denegado');
    }
  }

  requireBranch(session: SessionContext, branchId: string): void {
    if (session.branchId !== branchId) {
      throw new ForbiddenException('la sede no es la de la sesion');
    }
  }
}

export async function hashPassword(password: string): Promise<string> {
  return hashSecret(password);
}
