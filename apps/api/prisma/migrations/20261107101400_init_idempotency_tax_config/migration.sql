CREATE TABLE "idempotency_records" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "operation" TEXT NOT NULL,
  "request_key" TEXT NOT NULL,
  "request_hash" TEXT NOT NULL,
  "status" TEXT NOT NULL,
  "response" JSONB NOT NULL,
  "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "idempotency_records_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "idempotency_records_key" UNIQUE ("branch_id", "operation", "request_key"),
  CONSTRAINT "idempotency_records_status_check" CHECK ("status" IN ('SUCCEEDED', 'PENDING', 'PROCESSING', 'FAILED', 'UNKNOWN')),
  CONSTRAINT "idempotency_records_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "branches"("id")
);

CREATE TABLE "tax_configurations" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "price_mode" TEXT NOT NULL,
  "effective_from" TIMESTAMPTZ(6) NOT NULL,
  "created_by_user_id" UUID NOT NULL,
  "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "tax_configurations_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "tax_configurations_mode_check" CHECK ("price_mode" IN ('INCLUDED', 'EXCLUDED')),
  CONSTRAINT "tax_configurations_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "branches"("id"),
  CONSTRAINT "tax_configurations_user_fkey" FOREIGN KEY ("created_by_user_id") REFERENCES "users"("id")
);

CREATE TRIGGER "tax_configurations_append_only"
BEFORE UPDATE OR DELETE ON "tax_configurations"
FOR EACH ROW EXECUTE FUNCTION "app_forbid_mutation"();
