CREATE TABLE "prep_stations" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "name" TEXT NOT NULL,
  "kind" TEXT NOT NULL,
  "active" BOOLEAN NOT NULL DEFAULT true,
  CONSTRAINT "prep_stations_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "prep_stations_branch_id_id_key" UNIQUE ("branch_id", "id"),
  CONSTRAINT "prep_stations_kind_check" CHECK ("kind" IN ('KITCHEN', 'BAR')),
  CONSTRAINT "prep_stations_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "branches"("id")
);

CREATE TABLE "kitchen_tickets" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "order_id" UUID NOT NULL,
  "prep_station_id" UUID NOT NULL,
  "kind" TEXT NOT NULL,
  "sequence" INTEGER NOT NULL,
  "status" TEXT NOT NULL,
  "idempotency_key" TEXT NOT NULL,
  "sent_by_user_id" UUID NOT NULL,
  "sent_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "kitchen_tickets_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "kitchen_tickets_branch_id_id_key" UNIQUE ("branch_id", "id"),
  CONSTRAINT "kitchen_tickets_key" UNIQUE ("branch_id", "idempotency_key"),
  CONSTRAINT "kitchen_tickets_kind_check" CHECK ("kind" IN ('FIRE', 'ADDITION', 'CANCEL')),
  CONSTRAINT "kitchen_tickets_status_check" CHECK ("status" IN ('QUEUED', 'IN_PREPARATION', 'READY', 'HANDED_TO_SERVICE', 'CANCELLED')),
  CONSTRAINT "kitchen_tickets_order_fkey" FOREIGN KEY ("branch_id", "order_id") REFERENCES "orders"("branch_id", "id"),
  CONSTRAINT "kitchen_tickets_station_fkey" FOREIGN KEY ("branch_id", "prep_station_id") REFERENCES "prep_stations"("branch_id", "id"),
  CONSTRAINT "kitchen_tickets_sender_fkey" FOREIGN KEY ("sent_by_user_id") REFERENCES "users"("id")
);

CREATE TABLE "kitchen_ticket_lines" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "kitchen_ticket_id" UUID NOT NULL,
  "order_line_id" UUID NOT NULL,
  "quantity" DECIMAL(18, 6) NOT NULL,
  "name_snapshot" TEXT NOT NULL,
  "modifiers_snapshot" JSONB NOT NULL DEFAULT '[]',
  CONSTRAINT "kitchen_ticket_lines_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "kitchen_ticket_lines_qty_check" CHECK ("quantity" > 0),
  CONSTRAINT "kitchen_ticket_lines_ticket_fkey" FOREIGN KEY ("branch_id", "kitchen_ticket_id") REFERENCES "kitchen_tickets"("branch_id", "id"),
  CONSTRAINT "kitchen_ticket_lines_order_line_fkey" FOREIGN KEY ("branch_id", "order_line_id") REFERENCES "order_lines"("branch_id", "id")
);

CREATE TABLE "kitchen_ticket_events" (
  "id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "kitchen_ticket_id" UUID NOT NULL,
  "event_type" TEXT NOT NULL,
  "reason" TEXT,
  "actor_user_id" UUID,
  "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "kitchen_ticket_events_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "kitchen_ticket_events_ticket_fkey" FOREIGN KEY ("branch_id", "kitchen_ticket_id") REFERENCES "kitchen_tickets"("branch_id", "id")
);

CREATE TRIGGER "kitchen_ticket_events_append_only"
BEFORE UPDATE OR DELETE ON "kitchen_ticket_events"
FOR EACH ROW EXECUTE FUNCTION "app_forbid_mutation"();

ALTER TABLE "products" ADD COLUMN "default_station_id" UUID;
ALTER TABLE "products"
  ADD CONSTRAINT "products_default_station_fkey" FOREIGN KEY ("branch_id", "default_station_id") REFERENCES "prep_stations"("branch_id", "id");
