CREATE TABLE "recipe_versions" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "product_id" UUID,
  "preparation_item_id" UUID,
  "version_number" INTEGER NOT NULL,
  "expected_yield_qty" DECIMAL(18, 6) NOT NULL,
  "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "recipe_versions_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "recipe_versions_branch_id_id_key" UNIQUE ("branch_id", "id"),
  CONSTRAINT "recipe_versions_owner_check" CHECK (
    ("product_id" IS NOT NULL AND "preparation_item_id" IS NULL)
    OR ("product_id" IS NULL AND "preparation_item_id" IS NOT NULL)
  ),
  CONSTRAINT "recipe_versions_yield_check" CHECK ("expected_yield_qty" > 0),
  CONSTRAINT "recipe_versions_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "branches"("id"),
  CONSTRAINT "recipe_versions_product_fkey" FOREIGN KEY ("branch_id", "product_id") REFERENCES "products"("branch_id", "id"),
  CONSTRAINT "recipe_versions_preparation_fkey" FOREIGN KEY ("branch_id", "preparation_item_id") REFERENCES "inventory_items"("branch_id", "id")
);

CREATE TABLE "recipe_lines" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "recipe_version_id" UUID NOT NULL,
  "inventory_item_id" UUID NOT NULL,
  "quantity" DECIMAL(18, 6) NOT NULL,
  "unit_id" UUID NOT NULL,
  CONSTRAINT "recipe_lines_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "recipe_lines_quantity_check" CHECK ("quantity" > 0),
  CONSTRAINT "recipe_lines_version_fkey" FOREIGN KEY ("branch_id", "recipe_version_id") REFERENCES "recipe_versions"("branch_id", "id"),
  CONSTRAINT "recipe_lines_item_fkey" FOREIGN KEY ("branch_id", "inventory_item_id") REFERENCES "inventory_items"("branch_id", "id"),
  CONSTRAINT "recipe_lines_unit_fkey" FOREIGN KEY ("branch_id", "unit_id") REFERENCES "units"("branch_id", "id")
);

CREATE FUNCTION "recipe_lines_no_self"() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM "recipe_versions" v
    WHERE v."id" = NEW."recipe_version_id"
      AND v."preparation_item_id" = NEW."inventory_item_id"
  ) THEN
    RAISE EXCEPTION 'recipe_cannot_contain_itself';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER "recipe_lines_no_self"
BEFORE INSERT OR UPDATE ON "recipe_lines"
FOR EACH ROW EXECUTE FUNCTION "recipe_lines_no_self"();

CREATE TABLE "production_orders" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "preparation_item_id" UUID NOT NULL,
  "recipe_version_id" UUID NOT NULL,
  "status" TEXT NOT NULL,
  "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "production_orders_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "production_orders_branch_id_id_key" UNIQUE ("branch_id", "id"),
  CONSTRAINT "production_orders_status_check" CHECK ("status" IN ('DRAFT', 'CONFIRMED', 'COMPLETED', 'CANCELLED')),
  CONSTRAINT "production_orders_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "branches"("id"),
  CONSTRAINT "production_orders_item_fkey" FOREIGN KEY ("branch_id", "preparation_item_id") REFERENCES "inventory_items"("branch_id", "id"),
  CONSTRAINT "production_orders_recipe_fkey" FOREIGN KEY ("branch_id", "recipe_version_id") REFERENCES "recipe_versions"("branch_id", "id")
);

CREATE TABLE "production_order_lines" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "production_order_id" UUID NOT NULL,
  "inventory_item_id" UUID NOT NULL,
  "quantity" DECIMAL(18, 6) NOT NULL,
  CONSTRAINT "production_order_lines_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "production_order_lines_quantity_check" CHECK ("quantity" > 0),
  CONSTRAINT "production_order_lines_order_fkey" FOREIGN KEY ("branch_id", "production_order_id") REFERENCES "production_orders"("branch_id", "id"),
  CONSTRAINT "production_order_lines_item_fkey" FOREIGN KEY ("branch_id", "inventory_item_id") REFERENCES "inventory_items"("branch_id", "id")
);

CREATE TABLE "production_batches" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "production_order_id" UUID NOT NULL,
  "good_qty" DECIMAL(18, 6) NOT NULL,
  "waste_qty" DECIMAL(18, 6) NOT NULL,
  "status" TEXT NOT NULL,
  "idempotency_key" TEXT NOT NULL,
  "published_at" TIMESTAMPTZ(6),
  CONSTRAINT "production_batches_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "production_batches_branch_id_id_key" UNIQUE ("branch_id", "id"),
  CONSTRAINT "production_batches_key" UNIQUE ("branch_id", "idempotency_key"),
  CONSTRAINT "production_batches_status_check" CHECK ("status" IN ('DRAFT', 'PUBLISHED')),
  CONSTRAINT "production_batches_qty_check" CHECK ("good_qty" >= 0 AND "waste_qty" >= 0),
  CONSTRAINT "production_batches_order_fkey" FOREIGN KEY ("branch_id", "production_order_id") REFERENCES "production_orders"("branch_id", "id")
);

CREATE TABLE "production_batch_lines" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "production_batch_id" UUID NOT NULL,
  "inventory_item_id" UUID NOT NULL,
  "consumed_qty" DECIMAL(18, 6) NOT NULL,
  CONSTRAINT "production_batch_lines_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "production_batch_lines_qty_check" CHECK ("consumed_qty" >= 0),
  CONSTRAINT "production_batch_lines_batch_fkey" FOREIGN KEY ("branch_id", "production_batch_id") REFERENCES "production_batches"("branch_id", "id"),
  CONSTRAINT "production_batch_lines_item_fkey" FOREIGN KEY ("branch_id", "inventory_item_id") REFERENCES "inventory_items"("branch_id", "id")
);
