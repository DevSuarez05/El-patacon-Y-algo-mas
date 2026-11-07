CREATE TABLE "categories" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "name" TEXT NOT NULL,
  CONSTRAINT "categories_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "categories_branch_id_id_key" UNIQUE ("branch_id", "id"),
  CONSTRAINT "categories_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "branches"("id")
);

CREATE TABLE "products" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "category_id" UUID NOT NULL,
  "name" TEXT NOT NULL,
  "active" BOOLEAN NOT NULL DEFAULT true,
  CONSTRAINT "products_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "products_branch_id_id_key" UNIQUE ("branch_id", "id"),
  CONSTRAINT "products_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "branches"("id"),
  CONSTRAINT "products_category_fkey" FOREIGN KEY ("branch_id", "category_id") REFERENCES "categories"("branch_id", "id")
);

CREATE TABLE "variants" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "product_id" UUID NOT NULL,
  "name" TEXT NOT NULL,
  CONSTRAINT "variants_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "variants_branch_id_id_key" UNIQUE ("branch_id", "id"),
  CONSTRAINT "variants_product_fkey" FOREIGN KEY ("branch_id", "product_id") REFERENCES "products"("branch_id", "id")
);

CREATE TABLE "modifier_groups" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "product_id" UUID NOT NULL,
  "name" TEXT NOT NULL,
  CONSTRAINT "modifier_groups_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "modifier_groups_branch_id_id_key" UNIQUE ("branch_id", "id"),
  CONSTRAINT "modifier_groups_product_fkey" FOREIGN KEY ("branch_id", "product_id") REFERENCES "products"("branch_id", "id")
);

CREATE TABLE "modifiers" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "group_id" UUID NOT NULL,
  "name" TEXT NOT NULL,
  CONSTRAINT "modifiers_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "modifiers_branch_id_id_key" UNIQUE ("branch_id", "id"),
  CONSTRAINT "modifiers_group_fkey" FOREIGN KEY ("branch_id", "group_id") REFERENCES "modifier_groups"("branch_id", "id")
);

CREATE TABLE "prices" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "product_id" UUID NOT NULL,
  "variant_id" UUID,
  "amount_minor" BIGINT NOT NULL,
  "effective_from" TIMESTAMPTZ(6) NOT NULL,
  "created_by_user_id" UUID NOT NULL,
  "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "prices_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "prices_amount_check" CHECK ("amount_minor" >= 0),
  CONSTRAINT "prices_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "branches"("id"),
  CONSTRAINT "prices_product_fkey" FOREIGN KEY ("branch_id", "product_id") REFERENCES "products"("branch_id", "id"),
  CONSTRAINT "prices_variant_fkey" FOREIGN KEY ("branch_id", "variant_id") REFERENCES "variants"("branch_id", "id")
);

CREATE TRIGGER "prices_append_only"
BEFORE UPDATE OR DELETE ON "prices"
FOR EACH ROW EXECUTE FUNCTION "app_forbid_mutation"();
