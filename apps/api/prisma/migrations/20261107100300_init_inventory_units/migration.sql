CREATE TABLE "units" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "code" TEXT NOT NULL,
  "name" TEXT NOT NULL,
  "dimension" TEXT NOT NULL,
  CONSTRAINT "units_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "units_branch_id_id_key" UNIQUE ("branch_id", "id"),
  CONSTRAINT "units_branch_id_code_key" UNIQUE ("branch_id", "code"),
  CONSTRAINT "units_dimension_check" CHECK ("dimension" IN ('MASS', 'VOLUME', 'COUNT')),
  CONSTRAINT "units_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "branches"("id")
);

CREATE TABLE "unit_conversions" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "from_unit_id" UUID NOT NULL,
  "to_unit_id" UUID NOT NULL,
  "factor" DECIMAL(18, 6) NOT NULL,
  CONSTRAINT "unit_conversions_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "unit_conversions_pair_key" UNIQUE ("branch_id", "from_unit_id", "to_unit_id"),
  CONSTRAINT "unit_conversions_factor_check" CHECK ("factor" > 0),
  CONSTRAINT "unit_conversions_from_fkey" FOREIGN KEY ("branch_id", "from_unit_id") REFERENCES "units"("branch_id", "id"),
  CONSTRAINT "unit_conversions_to_fkey" FOREIGN KEY ("branch_id", "to_unit_id") REFERENCES "units"("branch_id", "id")
);

CREATE TABLE "inventory_items" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "name" TEXT NOT NULL,
  "kind" TEXT NOT NULL,
  "unit_id" UUID NOT NULL,
  "active" BOOLEAN NOT NULL DEFAULT true,
  CONSTRAINT "inventory_items_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "inventory_items_branch_id_id_key" UNIQUE ("branch_id", "id"),
  CONSTRAINT "inventory_items_kind_check" CHECK ("kind" IN ('INGREDIENT', 'PREPARATION', 'RESALE')),
  CONSTRAINT "inventory_items_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "branches"("id"),
  CONSTRAINT "inventory_items_unit_fkey" FOREIGN KEY ("branch_id", "unit_id") REFERENCES "units"("branch_id", "id")
);

CREATE TABLE "stock_balances" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "inventory_item_id" UUID NOT NULL,
  "on_hand_qty" DECIMAL(18, 6) NOT NULL DEFAULT 0,
  "reserved_qty" DECIMAL(18, 6) NOT NULL DEFAULT 0,
  "average_cost_minor" BIGINT NOT NULL DEFAULT 0,
  "version" INTEGER NOT NULL DEFAULT 0,
  CONSTRAINT "stock_balances_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "stock_balances_branch_item_key" UNIQUE ("branch_id", "inventory_item_id"),
  CONSTRAINT "stock_balances_reserved_check" CHECK ("reserved_qty" >= 0),
  CONSTRAINT "stock_balances_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "branches"("id"),
  CONSTRAINT "stock_balances_item_fkey" FOREIGN KEY ("branch_id", "inventory_item_id") REFERENCES "inventory_items"("branch_id", "id")
);
