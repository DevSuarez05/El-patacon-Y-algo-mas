import { ConflictException, Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { canonicalHash } from 'money';
import { v7 as uuidv7 } from 'uuid';
import { PrismaService } from '../prisma/prisma.service';

type Tx = Prisma.TransactionClient;

@Injectable()
export class IdempotencyService {
  constructor(private readonly prisma: PrismaService) {}

  async commit<T extends Prisma.InputJsonObject>(
    branchId: string,
    operation: string,
    requestKey: string,
    body: unknown,
    effect: (tx: Tx) => Promise<T>,
  ): Promise<T> {
    const requestHash = canonicalHash(body);
    try {
      return await this.prisma.$transaction(async (tx) => {
        const existing = await tx.idempotencyRecord.findUnique({
          where: {
            branchId_operation_requestKey: {
              branchId,
              operation,
              requestKey,
            },
          },
        });
        if (existing) {
          if (existing.requestHash !== requestHash) {
            throw new ConflictException('idempotency_body_conflict');
          }
          return existing.response as T;
        }
        const response = await effect(tx);
        await tx.idempotencyRecord.create({
          data: {
            id: uuidv7(),
            branchId,
            operation,
            requestKey,
            requestHash,
            status: 'SUCCEEDED',
            response,
          },
        });
        return response;
      });
    } catch (error) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        const existing = await this.prisma.idempotencyRecord.findUnique({
          where: {
            branchId_operation_requestKey: {
              branchId,
              operation,
              requestKey,
            },
          },
        });
        if (existing && existing.requestHash === requestHash) {
          return existing.response as T;
        }
        throw new ConflictException('idempotency_body_conflict');
      }
      throw error;
    }
  }
}
