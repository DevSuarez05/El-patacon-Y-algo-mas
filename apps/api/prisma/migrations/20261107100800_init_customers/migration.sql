CREATE TABLE "customers" (
  "id" UUID NOT NULL,
  "organization_id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "name" TEXT NOT NULL,
  "phone" TEXT,
  CONSTRAINT "customers_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "customers_branch_id_id_key" UNIQUE ("branch_id", "id"),
  CONSTRAINT "customers_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "organizations"("id"),
  CONSTRAINT "customers_branch_fkey" FOREIGN KEY ("organization_id", "branch_id") REFERENCES "branches"("organization_id", "id")
);

CREATE TABLE "customer_addresses" (
  "id" UUID NOT NULL,
  "customer_id" UUID NOT NULL,
  "line" TEXT NOT NULL,
  "neighborhood" TEXT,
  "reference" TEXT,
  "city" TEXT,
  CONSTRAINT "customer_addresses_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "customer_addresses_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "customers"("id")
);
