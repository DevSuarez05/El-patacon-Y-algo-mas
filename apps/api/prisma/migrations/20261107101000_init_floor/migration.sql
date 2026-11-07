CREATE TABLE "dining_rooms" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "name" TEXT NOT NULL,
  "sort_order" INTEGER NOT NULL,
  CONSTRAINT "dining_rooms_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "dining_rooms_branch_id_id_key" UNIQUE ("branch_id", "id"),
  CONSTRAINT "dining_rooms_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "branches"("id")
);

CREATE TABLE "dining_tables" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "room_id" UUID NOT NULL,
  "name" TEXT NOT NULL,
  "capacity" INTEGER NOT NULL,
  "status" TEXT NOT NULL,
  "version" INTEGER NOT NULL DEFAULT 0,
  CONSTRAINT "dining_tables_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "dining_tables_branch_id_id_key" UNIQUE ("branch_id", "id"),
  CONSTRAINT "dining_tables_status_check" CHECK ("status" IN ('FREE', 'OCCUPIED', 'AWAITING_BILL', 'RESERVED', 'CLEANING')),
  CONSTRAINT "dining_tables_capacity_check" CHECK ("capacity" > 0),
  CONSTRAINT "dining_tables_room_fkey" FOREIGN KEY ("branch_id", "room_id") REFERENCES "dining_rooms"("branch_id", "id")
);

CREATE TABLE "table_sessions" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "primary_table_id" UUID NOT NULL,
  "waiter_user_id" UUID NOT NULL,
  "guest_count" INTEGER NOT NULL,
  "status" TEXT NOT NULL,
  "close_reason" TEXT,
  "opened_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "table_sessions_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "table_sessions_branch_id_id_key" UNIQUE ("branch_id", "id"),
  CONSTRAINT "table_sessions_status_check" CHECK ("status" IN ('OPEN', 'CLOSED')),
  CONSTRAINT "table_sessions_close_check" CHECK ("close_reason" IS NULL OR "close_reason" IN ('SETTLED', 'MERGED', 'CANCELLED')),
  CONSTRAINT "table_sessions_guests_check" CHECK ("guest_count" >= 0),
  CONSTRAINT "table_sessions_table_fkey" FOREIGN KEY ("branch_id", "primary_table_id") REFERENCES "dining_tables"("branch_id", "id"),
  CONSTRAINT "table_sessions_waiter_fkey" FOREIGN KEY ("waiter_user_id") REFERENCES "users"("id")
);

CREATE TABLE "table_occupancies" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "table_session_id" UUID NOT NULL,
  "dining_table_id" UUID NOT NULL,
  "role" TEXT NOT NULL,
  CONSTRAINT "table_occupancies_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "table_occupancies_role_check" CHECK ("role" IN ('PRIMARY', 'JOINED')),
  CONSTRAINT "table_occupancies_session_fkey" FOREIGN KEY ("branch_id", "table_session_id") REFERENCES "table_sessions"("branch_id", "id"),
  CONSTRAINT "table_occupancies_table_fkey" FOREIGN KEY ("branch_id", "dining_table_id") REFERENCES "dining_tables"("branch_id", "id")
);

CREATE TABLE "table_session_events" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "table_session_id" UUID NOT NULL,
  "event_type" TEXT NOT NULL,
  "actor_user_id" UUID,
  "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "table_session_events_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "table_session_events_session_fkey" FOREIGN KEY ("branch_id", "table_session_id") REFERENCES "table_sessions"("branch_id", "id")
);

CREATE TRIGGER "table_session_events_append_only"
BEFORE UPDATE OR DELETE ON "table_session_events"
FOR EACH ROW EXECUTE FUNCTION "app_forbid_mutation"();

ALTER TABLE "orders" ADD COLUMN "table_session_id" UUID;
ALTER TABLE "orders"
  ADD CONSTRAINT "orders_table_session_fkey" FOREIGN KEY ("branch_id", "table_session_id") REFERENCES "table_sessions"("branch_id", "id");

CREATE FUNCTION "orders_channel_rules"() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF NEW."channel" = 'DINE_IN' AND NEW."fulfillment_status" <> 'DRAFT' AND NEW."table_session_id" IS NULL THEN
    RAISE EXCEPTION 'dine_in_requires_table_session';
  END IF;
  IF NEW."channel" <> 'DINE_IN' AND NEW."table_session_id" IS NOT NULL THEN
    RAISE EXCEPTION 'table_session_only_for_dine_in';
  END IF;
  IF NEW."channel" IN ('DELIVERY', 'PICKUP') AND NEW."fulfillment_status" <> 'DRAFT' AND NEW."customer_id" IS NULL THEN
    RAISE EXCEPTION 'delivery_or_pickup_requires_customer';
  END IF;
  IF NEW."channel" = 'PICKUP' AND NEW."fulfillment_status" <> 'DRAFT' AND NEW."promised_at" IS NULL THEN
    RAISE EXCEPTION 'pickup_requires_promised_at';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER "orders_channel_rules"
BEFORE INSERT OR UPDATE ON "orders"
FOR EACH ROW EXECUTE FUNCTION "orders_channel_rules"();
