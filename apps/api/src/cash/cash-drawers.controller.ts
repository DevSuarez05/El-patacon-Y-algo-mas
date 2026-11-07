import { Controller, Get, Headers, Param } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { IdentityService } from '../identity/identity.service';
import { readBearer } from '../identity/auth.controller';
import { PrismaService } from '../prisma/prisma.service';

@ApiTags('cash')
@ApiBearerAuth()
@Controller('branches/:branchId/cash-drawers')
export class CashDrawersController {
  constructor(
    private readonly identity: IdentityService,
    private readonly prisma: PrismaService,
  ) {}

  @Get()
  async list(
    @Param('branchId') branchId: string,
    @Headers('authorization') authorization?: string,
  ): Promise<{ id: string; name: string; labelNote: string }[]> {
    const session = await this.identity.authenticate(readBearer(authorization));
    this.identity.requireBranch(session, branchId);
    this.identity.requirePermission(session, 'cash_drawer.read');
    return this.prisma.cashDrawer.findMany({
      where: { branchId: session.branchId, active: true },
      select: { id: true, name: true, labelNote: true },
      orderBy: { name: 'asc' },
    });
  }
}
