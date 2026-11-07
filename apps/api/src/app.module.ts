import { Module } from '@nestjs/common';
import { CashDrawersController } from './cash/cash-drawers.controller';
import { TenderLabelsController } from './foundation/tender-labels.controller';
import { HealthController } from './health/health.controller';
import { AuthController } from './identity/auth.controller';
import { IdentityService } from './identity/identity.service';
import {
  BillingModule,
  CatalogModule,
  CustomersModule,
  FloorModule,
  InventoryModule,
  KitchenModule,
  OrdersModule,
  PaymentsModule,
  PurchasingModule,
  RecipesModule,
  ReportingModule,
} from './modules';
import { PrismaService } from './prisma/prisma.service';
import { IdempotencyService } from './shared/idempotency.service';

@Module({
  imports: [
    CatalogModule,
    InventoryModule,
    RecipesModule,
    PurchasingModule,
    OrdersModule,
    FloorModule,
    KitchenModule,
    BillingModule,
    PaymentsModule,
    CustomersModule,
    ReportingModule,
  ],
  controllers: [
    HealthController,
    AuthController,
    CashDrawersController,
    TenderLabelsController,
  ],
  providers: [PrismaService, IdentityService, IdempotencyService],
})
export class AppModule {}
