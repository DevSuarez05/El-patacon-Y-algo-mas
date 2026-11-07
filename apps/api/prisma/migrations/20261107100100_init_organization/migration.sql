CREATE TABLE "organizations" (
  "id" UUID NOT NULL,
  "name" TEXT NOT NULL,
  "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "organizations_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "branches" (
  "id" UUID NOT NULL,
  "organization_id" UUID NOT NULL,
  "name" TEXT NOT NULL,
  "timezone" TEXT NOT NULL DEFAULT 'America/Bogota',
  "currency_code" TEXT NOT NULL DEFAULT 'COP',
  "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "branches_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "branches_organization_id_id_key" UNIQUE ("organization_id", "id"),
  CONSTRAINT "branches_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "organizations"("id")
);
