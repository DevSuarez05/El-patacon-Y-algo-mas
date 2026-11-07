import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Headers,
  Post,
  UnauthorizedException,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { z } from 'zod';
import { IdentityService } from './identity.service';

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
  branchId: z.string().uuid(),
});

@ApiTags('identity')
@Controller('auth')
export class AuthController {
  constructor(private readonly identity: IdentityService) {}

  @Post('login')
  async login(@Body() body: unknown): Promise<{
    token: string;
    tokenType: 'Bearer';
    expiresAt: string;
    branchId: string;
  }> {
    const parsed = loginSchema.safeParse(body);
    if (!parsed.success) {
      throw new BadRequestException(parsed.error.flatten());
    }
    const result = await this.identity.login(
      parsed.data.email,
      parsed.data.password,
      parsed.data.branchId,
    );
    return { ...result, tokenType: 'Bearer' };
  }

  @ApiBearerAuth()
  @Get('me')
  async me(@Headers('authorization') authorization?: string): Promise<{
    userId: string;
    branchId: string;
    permissions: string[];
  }> {
    const token = readBearer(authorization);
    const session = await this.identity.authenticate(token);
    return {
      userId: session.userId,
      branchId: session.branchId,
      permissions: [...session.permissions].sort(),
    };
  }
}

export function readBearer(authorization?: string): string {
  if (!authorization?.startsWith('Bearer ')) {
    throw new UnauthorizedException('sesion invalida');
  }
  return authorization.slice('Bearer '.length);
}
