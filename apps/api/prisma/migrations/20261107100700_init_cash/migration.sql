CREATE TABLE "cash_drawers" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "name" TEXT NOT NULL,
  "label_note" TEXT NOT NULL,
  "active" BOOLEAN NOT NULL DEFAULT true,
  CONSTRAINT "cash_drawers_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "cash_drawers_branch_id_id_key" UNIQUE ("branch_id", "id"),
  CONSTRAINT "cash_drawers_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "branches"("id")
);

CREATE TABLE "cash_shifts" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "cash_drawer_id" UUID NOT NULL,
  "cashier_user_id" UUID NOT NULL,
  "opening_minor" BIGINT NOT NULL,
  "status" TEXT NOT NULL,
  "version" INTEGER NOT NULL DEFAULT 0,
  "opened_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "closed_at" TIMESTAMPTZ(6),
  CONSTRAINT "cash_shifts_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "cash_shifts_branch_id_id_key" UNIQUE ("branch_id", "id"),
  CONSTRAINT "cash_shifts_status_check" CHECK ("status" IN ('OPEN', 'CLOSED')),
  CONSTRAINT "cash_shifts_opening_check" CHECK ("opening_minor" >= 0),
  CONSTRAINT "cash_shifts_drawer_fkey" FOREIGN KEY ("branch_id", "cash_drawer_id") REFERENCES "cash_drawers"("branch_id", "id"),
  CONSTRAINT "cash_shifts_cashier_fkey" FOREIGN KEY ("cashier_user_id") REFERENCES "users"("id")
);

CREATE UNIQUE INDEX "cash_shifts_one_open" ON "cash_shifts" ("cash_drawer_id") WHERE "status" = 'OPEN';

CREATE TABLE "cash_movements" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "cash_shift_id" UUID NOT NULL,
  "movement_type" TEXT NOT NULL,
  "method" TEXT NOT NULL,
  "amount_minor" BIGINT NOT NULL,
  "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "cash_movements_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "cash_movements_type_check" CHECK ("movement_type" IN ('OPENING', 'TENDER', 'DEPOSIT', 'TIP', 'CHANGE', 'REFUND', 'EXPENSE', 'MANUAL_IN', 'MANUAL_OUT')),
  CONSTRAINT "cash_movements_method_check" CHECK ("method" IN ('CASH', 'CARD', 'TRANSFER')),
  CONSTRAINT "cash_movements_amount_check" CHECK ("amount_minor" >= 0),
  CONSTRAINT "cash_movements_shift_fkey" FOREIGN KEY ("branch_id", "cash_shift_id") REFERENCES "cash_shifts"("branch_id", "id")
);

CREATE FUNCTION "cash_movements_open_shift"() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE
  shift_status TEXT;
BEGIN
  SELECT "status" INTO shift_status FROM "cash_shifts" WHERE "id" = NEW."cash_shift_id";
  IF shift_status IS DISTINCT FROM 'OPEN' THEN
    RAISE EXCEPTION 'closed_shift_rejects_movement';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER "cash_movements_open_shift"
BEFORE INSERT ON "cash_movements"
FOR EACH ROW EXECUTE FUNCTION "cash_movements_open_shift"();

CREATE TRIGGER "cash_movements_append_only"
BEFORE UPDATE OR DELETE ON "cash_movements"
FOR EACH ROW EXECUTE FUNCTION "app_forbid_mutation"();

CREATE TABLE "cash_counts" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "cash_shift_id" UUID NOT NULL,
  "method" TEXT NOT NULL,
  "counted_minor" BIGINT NOT NULL,
  CONSTRAINT "cash_counts_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "cash_counts_method_check" CHECK ("method" IN ('CASH', 'CARD', 'TRANSFER')),
  CONSTRAINT "cash_counts_amount_check" CHECK ("counted_minor" >= 0),
  CONSTRAINT "cash_counts_shift_fkey" FOREIGN KEY ("branch_id", "cash_shift_id") REFERENCES "cash_shifts"("branch_id", "id")
);

CREATE TABLE "shift_closes" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "cash_shift_id" UUID NOT NULL,
  "consolidated_diff_minor" BIGINT NOT NULL,
  "closed_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "shift_closes_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "shift_closes_cash_shift_id_key" UNIQUE ("cash_shift_id"),
  CONSTRAINT "shift_closes_shift_fkey" FOREIGN KEY ("cash_shift_id") REFERENCES "cash_shifts"("id")
);

CREATE TRIGGER "shift_closes_append_only"
BEFORE UPDATE OR DELETE ON "shift_closes"
FOR EACH ROW EXECUTE FUNCTION "app_forbid_mutation"();

CREATE TABLE "shift_close_lines" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "shift_close_id" UUID NOT NULL,
  "method" TEXT NOT NULL,
  "expected_minor" BIGINT NOT NULL,
  "counted_minor" BIGINT NOT NULL,
  "difference_minor" BIGINT NOT NULL,
  CONSTRAINT "shift_close_lines_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "shift_close_lines_method_key" UNIQUE ("shift_close_id", "method"),
  CONSTRAINT "shift_close_lines_method_check" CHECK ("method" IN ('CASH', 'CARD', 'TRANSFER')),
  CONSTRAINT "shift_close_lines_identity_check" CHECK ("difference_minor" = "counted_minor" - "expected_minor"),
  CONSTRAINT "shift_close_lines_close_fkey" FOREIGN KEY ("shift_close_id") REFERENCES "shift_closes"("id")
);

CREATE TRIGGER "shift_close_lines_append_only"
BEFORE UPDATE OR DELETE ON "shift_close_lines"
FOR EACH ROW EXECUTE FUNCTION "app_forbid_mutation"();

ALTER TABLE "expenses" ADD COLUMN "cash_shift_id" UUID;
ALTER TABLE "expenses"
  ADD CONSTRAINT "expenses_shift_fkey" FOREIGN KEY ("branch_id", "cash_shift_id") REFERENCES "cash_shifts"("branch_id", "id");
