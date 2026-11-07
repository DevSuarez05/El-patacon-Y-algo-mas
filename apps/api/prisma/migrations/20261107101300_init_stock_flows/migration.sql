CREATE TABLE "stock_reservations" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "order_line_id" UUID NOT NULL,
  "portion_key" TEXT NOT NULL,
  "inventory_item_id" UUID NOT NULL,
  "quantity" DECIMAL(18, 6) NOT NULL,
  "status" TEXT NOT NULL,
  "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "stock_reservations_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "stock_reservations_status_check" CHECK ("status" IN ('ACTIVE', 'CONSUMED', 'RELEASED')),
  CONSTRAINT "stock_reservations_qty_check" CHECK ("quantity" > 0),
  CONSTRAINT "stock_reservations_line_fkey" FOREIGN KEY ("branch_id", "order_line_id") REFERENCES "order_lines"("branch_id", "id"),
  CONSTRAINT "stock_reservations_item_fkey" FOREIGN KEY ("branch_id", "inventory_item_id") REFERENCES "inventory_items"("branch_id", "id")
);

COMMENT ON TABLE "stock_reservations" IS 'La antigüedad es created_at. No existe un proceso que libere la reserva por tiempo.';

CREATE UNIQUE INDEX "stock_reservations_one_active"
ON "stock_reservations" ("order_line_id", "portion_key", "inventory_item_id")
WHERE "status" = 'ACTIVE';

CREATE TABLE "stock_movements" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "inventory_item_id" UUID NOT NULL,
  "movement_type" TEXT NOT NULL,
  "quantity" DECIMAL(18, 6) NOT NULL,
  "cost_minor" BIGINT,
  "source_type" TEXT NOT NULL,
  "source_id" UUID,
  "idempotency_key" TEXT NOT NULL,
  "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "stock_movements_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "stock_movements_key" UNIQUE ("branch_id", "idempotency_key"),
  CONSTRAINT "stock_movements_type_check" CHECK ("movement_type" IN ('RECEIPT', 'CONSUMPTION', 'WASTE', 'ADJUSTMENT', 'PRODUCTION_OUT', 'PRODUCTION_IN')),
  CONSTRAINT "stock_movements_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "branches"("id"),
  CONSTRAINT "stock_movements_item_fkey" FOREIGN KEY ("branch_id", "inventory_item_id") REFERENCES "inventory_items"("branch_id", "id")
);

CREATE TRIGGER "stock_movements_append_only"
BEFORE UPDATE OR DELETE ON "stock_movements"
FOR EACH ROW EXECUTE FUNCTION "app_forbid_mutation"();

CREATE TABLE "waste_movements" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "inventory_item_id" UUID NOT NULL,
  "quantity" DECIMAL(18, 6) NOT NULL,
  "reason" TEXT NOT NULL,
  "origin" TEXT NOT NULL,
  "responsible_user_id" UUID NOT NULL,
  "authorizer_user_id" UUID,
  "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "waste_movements_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "waste_movements_qty_check" CHECK ("quantity" > 0 AND length("reason") > 0),
  CONSTRAINT "waste_movements_origin_check" CHECK ("origin" IN ('INGREDIENT', 'PREPARATION', 'PRODUCTION_LOSS', 'DAMAGED')),
  CONSTRAINT "waste_movements_item_fkey" FOREIGN KEY ("branch_id", "inventory_item_id") REFERENCES "inventory_items"("branch_id", "id"),
  CONSTRAINT "waste_movements_responsible_fkey" FOREIGN KEY ("responsible_user_id") REFERENCES "users"("id"),
  CONSTRAINT "waste_movements_authorizer_fkey" FOREIGN KEY ("authorizer_user_id") REFERENCES "users"("id")
);

CREATE TRIGGER "waste_movements_append_only"
BEFORE UPDATE OR DELETE ON "waste_movements"
FOR EACH ROW EXECUTE FUNCTION "app_forbid_mutation"();

CREATE TABLE "stock_exceptions" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "inventory_item_id" UUID NOT NULL,
  "stock_movement_id" UUID NOT NULL,
  "authorizer_user_id" UUID NOT NULL,
  "responsible_user_id" UUID NOT NULL,
  "reason" TEXT NOT NULL,
  "authorized_qty" DECIMAL(18, 6) NOT NULL,
  "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "stock_exceptions_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "stock_exceptions_reason_check" CHECK (length("reason") > 0 AND "authorized_qty" > 0),
  CONSTRAINT "stock_exceptions_movement_fkey" FOREIGN KEY ("stock_movement_id") REFERENCES "stock_movements"("id"),
  CONSTRAINT "stock_exceptions_item_fkey" FOREIGN KEY ("branch_id", "inventory_item_id") REFERENCES "inventory_items"("branch_id", "id"),
  CONSTRAINT "stock_exceptions_authorizer_fkey" FOREIGN KEY ("authorizer_user_id") REFERENCES "users"("id"),
  CONSTRAINT "stock_exceptions_responsible_fkey" FOREIGN KEY ("responsible_user_id") REFERENCES "users"("id")
);

CREATE FUNCTION "stock_balances_guard"() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE
  exception_id TEXT;
BEGIN
  IF NEW."on_hand_qty" < 0 THEN
    exception_id := current_setting('app.stock_exception_id', true);
    IF exception_id IS NULL OR exception_id = '' THEN
      RAISE EXCEPTION 'negative_stock_requires_exception';
    END IF;
    IF NOT EXISTS (
      SELECT 1 FROM "stock_exceptions" e
      WHERE e."id" = exception_id::uuid
        AND e."branch_id" = NEW."branch_id"
        AND e."inventory_item_id" = NEW."inventory_item_id"
        AND e."authorizer_user_id" IS NOT NULL
        AND e."responsible_user_id" IS NOT NULL
        AND length(e."reason") > 0
    ) THEN
      RAISE EXCEPTION 'negative_stock_exception_incomplete';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER "stock_balances_guard"
BEFORE INSERT OR UPDATE ON "stock_balances"
FOR EACH ROW EXECUTE FUNCTION "stock_balances_guard"();
