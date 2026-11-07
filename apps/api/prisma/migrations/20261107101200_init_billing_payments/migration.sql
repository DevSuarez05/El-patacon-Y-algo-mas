CREATE TABLE "sales" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "order_id" UUID NOT NULL,
  "status" TEXT NOT NULL,
  "product_gross_minor" BIGINT NOT NULL,
  "discount_minor" BIGINT NOT NULL,
  "tax_minor" BIGINT NOT NULL,
  "charge_minor" BIGINT NOT NULL,
  "sale_total_minor" BIGINT NOT NULL,
  "theoretical_cost_minor" BIGINT NOT NULL,
  "idempotency_key" TEXT NOT NULL,
  "created_by_user_id" UUID NOT NULL,
  "posted_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "sales_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "sales_branch_id_id_key" UNIQUE ("branch_id", "id"),
  CONSTRAINT "sales_key" UNIQUE ("branch_id", "idempotency_key"),
  CONSTRAINT "sales_status_check" CHECK ("status" IN ('POSTED', 'VOIDED')),
  CONSTRAINT "sales_non_negative_check" CHECK (
    "product_gross_minor" >= 0 AND "discount_minor" >= 0 AND "tax_minor" >= 0
    AND "charge_minor" >= 0 AND "sale_total_minor" >= 0 AND "theoretical_cost_minor" >= 0
  ),
  CONSTRAINT "sales_total_check" CHECK (
    "sale_total_minor" = "product_gross_minor" - "discount_minor" + "tax_minor" + "charge_minor"
  ),
  CONSTRAINT "sales_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "branches"("id"),
  CONSTRAINT "sales_order_fkey" FOREIGN KEY ("branch_id", "order_id") REFERENCES "orders"("branch_id", "id"),
  CONSTRAINT "sales_user_fkey" FOREIGN KEY ("created_by_user_id") REFERENCES "users"("id")
);

CREATE FUNCTION "sales_money_immutable"() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF OLD."product_gross_minor" IS DISTINCT FROM NEW."product_gross_minor"
    OR OLD."discount_minor" IS DISTINCT FROM NEW."discount_minor"
    OR OLD."tax_minor" IS DISTINCT FROM NEW."tax_minor"
    OR OLD."charge_minor" IS DISTINCT FROM NEW."charge_minor"
    OR OLD."sale_total_minor" IS DISTINCT FROM NEW."sale_total_minor"
    OR OLD."theoretical_cost_minor" IS DISTINCT FROM NEW."theoretical_cost_minor"
    OR OLD."order_id" IS DISTINCT FROM NEW."order_id"
    OR OLD."branch_id" IS DISTINCT FROM NEW."branch_id" THEN
    RAISE EXCEPTION 'sale_money_immutable';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER "sales_money_immutable"
BEFORE UPDATE ON "sales"
FOR EACH ROW EXECUTE FUNCTION "sales_money_immutable"();

CREATE TRIGGER "sales_no_delete"
BEFORE DELETE ON "sales"
FOR EACH ROW EXECUTE FUNCTION "app_forbid_mutation"();

CREATE TABLE "sale_lines" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "sale_id" UUID NOT NULL,
  "order_line_id" UUID NOT NULL,
  "quantity" DECIMAL(18, 6) NOT NULL,
  "amount_minor" BIGINT NOT NULL,
  CONSTRAINT "sale_lines_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "sale_lines_check" CHECK ("quantity" > 0 AND "amount_minor" >= 0),
  CONSTRAINT "sale_lines_sale_fkey" FOREIGN KEY ("branch_id", "sale_id") REFERENCES "sales"("branch_id", "id"),
  CONSTRAINT "sale_lines_order_line_fkey" FOREIGN KEY ("branch_id", "order_line_id") REFERENCES "order_lines"("branch_id", "id")
);

CREATE TRIGGER "sale_lines_append_only"
BEFORE UPDATE OR DELETE ON "sale_lines"
FOR EACH ROW EXECUTE FUNCTION "app_forbid_mutation"();

CREATE TABLE "sale_taxes" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "sale_id" UUID NOT NULL,
  "tax_code" TEXT NOT NULL,
  "base_minor" BIGINT NOT NULL,
  "rate_bps" INTEGER,
  "amount_minor" BIGINT NOT NULL,
  CONSTRAINT "sale_taxes_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "sale_taxes_check" CHECK ("base_minor" >= 0 AND "amount_minor" >= 0),
  CONSTRAINT "sale_taxes_sale_fkey" FOREIGN KEY ("branch_id", "sale_id") REFERENCES "sales"("branch_id", "id")
);

CREATE TABLE "sale_voids" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "sale_id" UUID NOT NULL,
  "reason" TEXT NOT NULL,
  "authorizer_user_id" UUID NOT NULL,
  "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "sale_voids_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "sale_voids_sale_id_key" UNIQUE ("sale_id"),
  CONSTRAINT "sale_voids_sale_fkey" FOREIGN KEY ("sale_id") REFERENCES "sales"("id"),
  CONSTRAINT "sale_voids_authorizer_fkey" FOREIGN KEY ("authorizer_user_id") REFERENCES "users"("id")
);

CREATE TRIGGER "sale_voids_append_only"
BEFORE UPDATE OR DELETE ON "sale_voids"
FOR EACH ROW EXECUTE FUNCTION "app_forbid_mutation"();

CREATE TABLE "payments" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "cash_shift_id" UUID NOT NULL,
  "order_id" UUID NOT NULL,
  "target" TEXT NOT NULL,
  "method" TEXT NOT NULL,
  "tendered_minor" BIGINT NOT NULL,
  "applied_minor" BIGINT NOT NULL,
  "tip_minor" BIGINT NOT NULL,
  "change_minor" BIGINT NOT NULL,
  "status" TEXT NOT NULL,
  "external_reference" TEXT,
  "idempotency_key" TEXT NOT NULL,
  "created_by_user_id" UUID NOT NULL,
  "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "payments_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "payments_branch_id_id_key" UNIQUE ("branch_id", "id"),
  CONSTRAINT "payments_key" UNIQUE ("branch_id", "idempotency_key"),
  CONSTRAINT "payments_target_check" CHECK ("target" IN ('SALE', 'ORDER')),
  CONSTRAINT "payments_method_check" CHECK ("method" IN ('CASH', 'CARD', 'TRANSFER')),
  CONSTRAINT "payments_status_check" CHECK ("status" IN ('PENDING', 'PROCESSING', 'SUCCEEDED', 'FAILED', 'UNKNOWN')),
  CONSTRAINT "payments_identity_check" CHECK (
    "tendered_minor" = "applied_minor" + "tip_minor" + "change_minor"
    AND "tendered_minor" >= 0 AND "applied_minor" >= 0 AND "tip_minor" >= 0 AND "change_minor" >= 0
  ),
  CONSTRAINT "payments_change_cash_check" CHECK ("change_minor" = 0 OR "method" = 'CASH'),
  CONSTRAINT "payments_cash_not_unknown_check" CHECK ("method" <> 'CASH' OR "status" <> 'UNKNOWN'),
  CONSTRAINT "payments_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "branches"("id"),
  CONSTRAINT "payments_shift_fkey" FOREIGN KEY ("branch_id", "cash_shift_id") REFERENCES "cash_shifts"("branch_id", "id"),
  CONSTRAINT "payments_order_fkey" FOREIGN KEY ("branch_id", "order_id") REFERENCES "orders"("branch_id", "id"),
  CONSTRAINT "payments_user_fkey" FOREIGN KEY ("created_by_user_id") REFERENCES "users"("id")
);

CREATE FUNCTION "payments_money_immutable"() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF OLD."tendered_minor" IS DISTINCT FROM NEW."tendered_minor"
    OR OLD."applied_minor" IS DISTINCT FROM NEW."applied_minor"
    OR OLD."tip_minor" IS DISTINCT FROM NEW."tip_minor"
    OR OLD."change_minor" IS DISTINCT FROM NEW."change_minor"
    OR OLD."method" IS DISTINCT FROM NEW."method"
    OR OLD."order_id" IS DISTINCT FROM NEW."order_id" THEN
    RAISE EXCEPTION 'payment_money_immutable';
  END IF;
  IF NEW."method" IN ('CASH', 'CARD', 'TRANSFER') AND NEW."status" = 'UNKNOWN' AND OLD."status" IS DISTINCT FROM 'UNKNOWN' THEN
    IF NEW."method" = 'CASH' THEN
      RAISE EXCEPTION 'cash_cannot_be_unknown';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER "payments_money_immutable"
BEFORE UPDATE ON "payments"
FOR EACH ROW EXECUTE FUNCTION "payments_money_immutable"();

CREATE TRIGGER "payments_no_delete"
BEFORE DELETE ON "payments"
FOR EACH ROW EXECUTE FUNCTION "app_forbid_mutation"();

CREATE TABLE "payment_allocations" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "payment_id" UUID NOT NULL,
  "sale_id" UUID NOT NULL,
  "amount_minor" BIGINT NOT NULL,
  CONSTRAINT "payment_allocations_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "payment_allocations_amount_check" CHECK ("amount_minor" > 0),
  CONSTRAINT "payment_allocations_payment_fkey" FOREIGN KEY ("branch_id", "payment_id") REFERENCES "payments"("branch_id", "id"),
  CONSTRAINT "payment_allocations_sale_fkey" FOREIGN KEY ("branch_id", "sale_id") REFERENCES "sales"("branch_id", "id")
);

CREATE TABLE "tip_distributions" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "payment_id" UUID NOT NULL,
  "amount_minor" BIGINT NOT NULL,
  "method" TEXT NOT NULL,
  "status" TEXT NOT NULL DEFAULT 'PENDING_DISTRIBUTION',
  "responsible_user_id" UUID,
  CONSTRAINT "tip_distributions_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "tip_distributions_payment_id_key" UNIQUE ("payment_id"),
  CONSTRAINT "tip_distributions_status_check" CHECK ("status" IN ('PENDING_DISTRIBUTION', 'DISTRIBUTED', 'ADJUSTED')),
  CONSTRAINT "tip_distributions_amount_check" CHECK ("amount_minor" >= 0),
  CONSTRAINT "tip_distributions_payment_fkey" FOREIGN KEY ("payment_id") REFERENCES "payments"("id")
);

CREATE TABLE "tip_adjustments" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "tip_distribution_id" UUID NOT NULL,
  "amount_minor" BIGINT NOT NULL,
  "authorizer_user_id" UUID NOT NULL,
  "reason" TEXT NOT NULL,
  "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "tip_adjustments_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "tip_adjustments_distribution_fkey" FOREIGN KEY ("tip_distribution_id") REFERENCES "tip_distributions"("id"),
  CONSTRAINT "tip_adjustments_authorizer_fkey" FOREIGN KEY ("authorizer_user_id") REFERENCES "users"("id")
);

CREATE TRIGGER "tip_adjustments_append_only"
BEFORE UPDATE OR DELETE ON "tip_adjustments"
FOR EACH ROW EXECUTE FUNCTION "app_forbid_mutation"();

ALTER TABLE "cash_movements" ADD COLUMN "payment_id" UUID;
ALTER TABLE "cash_movements"
  ADD CONSTRAINT "cash_movements_payment_fkey" FOREIGN KEY ("branch_id", "payment_id") REFERENCES "payments"("branch_id", "id");

CREATE FUNCTION "cash_movements_payment_rules"() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE
  payment_status TEXT;
  payment_method TEXT;
BEGIN
  IF NEW."movement_type" = 'CHANGE' AND NEW."payment_id" IS NULL THEN
    RAISE EXCEPTION 'change_requires_payment';
  END IF;
  IF NEW."payment_id" IS NULL THEN
    RETURN NEW;
  END IF;
  SELECT "status", "method" INTO payment_status, payment_method
  FROM "payments" WHERE "id" = NEW."payment_id";
  IF payment_status IS DISTINCT FROM 'SUCCEEDED' THEN
    RAISE EXCEPTION 'movement_requires_succeeded_payment';
  END IF;
  IF NEW."movement_type" = 'CHANGE' AND (payment_method IS DISTINCT FROM 'CASH' OR NEW."method" IS DISTINCT FROM 'CASH') THEN
    RAISE EXCEPTION 'change_requires_cash';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER "cash_movements_payment_rules"
BEFORE INSERT ON "cash_movements"
FOR EACH ROW EXECUTE FUNCTION "cash_movements_payment_rules"();
