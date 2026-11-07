CREATE TABLE "orders" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "channel" TEXT NOT NULL,
  "fulfillment_status" TEXT NOT NULL,
  "settlement_status" TEXT NOT NULL,
  "version" INTEGER NOT NULL DEFAULT 0,
  "opened_by_user_id" UUID NOT NULL,
  "owner_user_id" UUID,
  "customer_id" UUID,
  "promised_at" TIMESTAMPTZ(6),
  "opened_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "closed_at" TIMESTAMPTZ(6),
  CONSTRAINT "orders_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "orders_branch_id_id_key" UNIQUE ("branch_id", "id"),
  CONSTRAINT "orders_channel_check" CHECK ("channel" IN ('COUNTER', 'DINE_IN', 'DELIVERY', 'PICKUP')),
  CONSTRAINT "orders_fulfillment_check" CHECK ("fulfillment_status" IN ('DRAFT', 'OPEN', 'IN_PREPARATION', 'READY', 'FULFILLED', 'CANCELLED')),
  CONSTRAINT "orders_settlement_check" CHECK ("settlement_status" IN ('UNPAID', 'PARTIALLY_PAID', 'PAID', 'VOID')),
  CONSTRAINT "orders_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "branches"("id"),
  CONSTRAINT "orders_opened_by_fkey" FOREIGN KEY ("opened_by_user_id") REFERENCES "users"("id"),
  CONSTRAINT "orders_customer_fkey" FOREIGN KEY ("branch_id", "customer_id") REFERENCES "customers"("branch_id", "id")
);

CREATE TABLE "order_lines" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "order_id" UUID NOT NULL,
  "product_id" UUID NOT NULL,
  "variant_id" UUID,
  "quantity" DECIMAL(18, 6) NOT NULL,
  "guest_label" TEXT,
  "status" TEXT NOT NULL,
  "inventory_effect" TEXT NOT NULL,
  "quoted_unit_price_minor" BIGINT NOT NULL,
  "discount_minor" BIGINT NOT NULL DEFAULT 0,
  "authorizer_user_id" UUID,
  "theoretical_cost_minor" BIGINT,
  "cancel_reason" TEXT,
  CONSTRAINT "order_lines_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "order_lines_branch_id_id_key" UNIQUE ("branch_id", "id"),
  CONSTRAINT "order_lines_status_check" CHECK ("status" IN ('DRAFT', 'SENT', 'IN_PREPARATION', 'READY', 'HANDED_TO_SERVICE', 'FULFILLED', 'CANCELLED')),
  CONSTRAINT "order_lines_effect_check" CHECK ("inventory_effect" IN ('NONE', 'RESERVED', 'CONSUMED', 'REVERSED', 'WASTED')),
  CONSTRAINT "order_lines_money_check" CHECK ("quoted_unit_price_minor" >= 0 AND "discount_minor" >= 0 AND "quantity" > 0),
  CONSTRAINT "order_lines_order_fkey" FOREIGN KEY ("branch_id", "order_id") REFERENCES "orders"("branch_id", "id"),
  CONSTRAINT "order_lines_product_fkey" FOREIGN KEY ("branch_id", "product_id") REFERENCES "products"("branch_id", "id"),
  CONSTRAINT "order_lines_variant_fkey" FOREIGN KEY ("branch_id", "variant_id") REFERENCES "variants"("branch_id", "id")
);

CREATE TABLE "order_line_modifiers" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "order_line_id" UUID NOT NULL,
  "modifier_id" UUID NOT NULL,
  "quantity" DECIMAL(18, 6) NOT NULL,
  "price_delta_minor" BIGINT NOT NULL,
  "snapshot" JSONB NOT NULL DEFAULT '{}',
  CONSTRAINT "order_line_modifiers_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "order_line_modifiers_line_fkey" FOREIGN KEY ("branch_id", "order_line_id") REFERENCES "order_lines"("branch_id", "id"),
  CONSTRAINT "order_line_modifiers_modifier_fkey" FOREIGN KEY ("branch_id", "modifier_id") REFERENCES "modifiers"("branch_id", "id")
);

CREATE TABLE "order_charges" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "order_id" UUID NOT NULL,
  "charge_type" TEXT NOT NULL,
  "amount_minor" BIGINT NOT NULL,
  CONSTRAINT "order_charges_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "order_charges_amount_check" CHECK ("amount_minor" >= 0),
  CONSTRAINT "order_charges_order_fkey" FOREIGN KEY ("branch_id", "order_id") REFERENCES "orders"("branch_id", "id")
);

CREATE TABLE "order_events" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "order_id" UUID NOT NULL,
  "event_type" TEXT NOT NULL,
  "actor_user_id" UUID,
  "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "reference" TEXT,
  CONSTRAINT "order_events_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "order_events_order_fkey" FOREIGN KEY ("branch_id", "order_id") REFERENCES "orders"("branch_id", "id")
);

CREATE TRIGGER "order_events_append_only"
BEFORE UPDATE OR DELETE ON "order_events"
FOR EACH ROW EXECUTE FUNCTION "app_forbid_mutation"();

CREATE TABLE "fulfillments" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "order_id" UUID NOT NULL,
  "kind" TEXT NOT NULL,
  "status" TEXT NOT NULL,
  "address_line" TEXT,
  "fee_minor" BIGINT,
  "assignee" TEXT,
  "dispatched_at" TIMESTAMPTZ(6),
  "completed_at" TIMESTAMPTZ(6),
  CONSTRAINT "fulfillments_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "fulfillments_order_id_key" UNIQUE ("order_id"),
  CONSTRAINT "fulfillments_kind_check" CHECK ("kind" IN ('DELIVERY', 'PICKUP')),
  CONSTRAINT "fulfillments_status_check" CHECK ("status" IN ('PENDING', 'READY', 'DISPATCHED', 'COMPLETED', 'CANCELLED', 'NO_SHOW')),
  CONSTRAINT "fulfillments_pickup_check" CHECK ("kind" <> 'PICKUP' OR "status" <> 'DISPATCHED'),
  CONSTRAINT "fulfillments_order_fkey" FOREIGN KEY ("order_id") REFERENCES "orders"("id")
);
