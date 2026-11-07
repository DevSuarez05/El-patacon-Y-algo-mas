CREATE TABLE "suppliers" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "name" TEXT NOT NULL,
  CONSTRAINT "suppliers_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "suppliers_branch_id_id_key" UNIQUE ("branch_id", "id"),
  CONSTRAINT "suppliers_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "branches"("id")
);

CREATE TABLE "purchase_orders" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "supplier_id" UUID NOT NULL,
  "status" TEXT NOT NULL,
  CONSTRAINT "purchase_orders_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "purchase_orders_branch_id_id_key" UNIQUE ("branch_id", "id"),
  CONSTRAINT "purchase_orders_status_check" CHECK ("status" IN ('DRAFT', 'SENT', 'PARTIAL', 'RECEIVED', 'CANCELLED')),
  CONSTRAINT "purchase_orders_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "branches"("id"),
  CONSTRAINT "purchase_orders_supplier_fkey" FOREIGN KEY ("branch_id", "supplier_id") REFERENCES "suppliers"("branch_id", "id")
);

CREATE TABLE "purchase_order_lines" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "purchase_order_id" UUID NOT NULL,
  "inventory_item_id" UUID NOT NULL,
  "ordered_qty" DECIMAL(18, 6) NOT NULL,
  CONSTRAINT "purchase_order_lines_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "purchase_order_lines_qty_check" CHECK ("ordered_qty" > 0),
  CONSTRAINT "purchase_order_lines_order_fkey" FOREIGN KEY ("branch_id", "purchase_order_id") REFERENCES "purchase_orders"("branch_id", "id"),
  CONSTRAINT "purchase_order_lines_item_fkey" FOREIGN KEY ("branch_id", "inventory_item_id") REFERENCES "inventory_items"("branch_id", "id")
);

CREATE TABLE "goods_receipts" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "purchase_order_id" UUID NOT NULL,
  "idempotency_key" TEXT NOT NULL,
  "confirmed_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "goods_receipts_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "goods_receipts_branch_id_id_key" UNIQUE ("branch_id", "id"),
  CONSTRAINT "goods_receipts_key" UNIQUE ("branch_id", "idempotency_key"),
  CONSTRAINT "goods_receipts_order_fkey" FOREIGN KEY ("branch_id", "purchase_order_id") REFERENCES "purchase_orders"("branch_id", "id")
);

CREATE TABLE "goods_receipt_lines" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "goods_receipt_id" UUID NOT NULL,
  "inventory_item_id" UUID NOT NULL,
  "received_qty" DECIMAL(18, 6) NOT NULL,
  "unit_cost_minor" BIGINT NOT NULL,
  CONSTRAINT "goods_receipt_lines_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "goods_receipt_lines_check" CHECK ("received_qty" >= 0 AND "unit_cost_minor" >= 0),
  CONSTRAINT "goods_receipt_lines_receipt_fkey" FOREIGN KEY ("branch_id", "goods_receipt_id") REFERENCES "goods_receipts"("branch_id", "id"),
  CONSTRAINT "goods_receipt_lines_item_fkey" FOREIGN KEY ("branch_id", "inventory_item_id") REFERENCES "inventory_items"("branch_id", "id")
);

CREATE TABLE "supplier_obligations" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "goods_receipt_id" UUID NOT NULL,
  "amount_minor" BIGINT NOT NULL,
  CONSTRAINT "supplier_obligations_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "supplier_obligations_goods_receipt_id_key" UNIQUE ("goods_receipt_id"),
  CONSTRAINT "supplier_obligations_amount_check" CHECK ("amount_minor" >= 0),
  CONSTRAINT "supplier_obligations_receipt_fkey" FOREIGN KEY ("goods_receipt_id") REFERENCES "goods_receipts"("id")
);

CREATE TABLE "supplier_payments" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "obligation_id" UUID NOT NULL,
  "amount_minor" BIGINT NOT NULL,
  "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "supplier_payments_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "supplier_payments_amount_check" CHECK ("amount_minor" > 0),
  CONSTRAINT "supplier_payments_obligation_fkey" FOREIGN KEY ("obligation_id") REFERENCES "supplier_obligations"("id")
);

CREATE TRIGGER "supplier_payments_append_only"
BEFORE UPDATE OR DELETE ON "supplier_payments"
FOR EACH ROW EXECUTE FUNCTION "app_forbid_mutation"();

CREATE TABLE "expenses" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "amount_minor" BIGINT NOT NULL,
  "reason" TEXT NOT NULL,
  "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "expenses_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "expenses_amount_check" CHECK ("amount_minor" >= 0),
  CONSTRAINT "expenses_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "branches"("id")
);
