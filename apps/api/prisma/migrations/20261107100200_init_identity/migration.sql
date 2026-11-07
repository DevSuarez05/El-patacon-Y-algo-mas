CREATE TABLE "users" (
  "id" UUID NOT NULL,
  "organization_id" UUID NOT NULL,
  "email" TEXT NOT NULL,
  "password_hash" TEXT NOT NULL,
  "display_name" TEXT NOT NULL,
  "active" BOOLEAN NOT NULL DEFAULT true,
  "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "users_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "users_organization_id_id_key" UNIQUE ("organization_id", "id"),
  CONSTRAINT "users_organization_id_email_key" UNIQUE ("organization_id", "email"),
  CONSTRAINT "users_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "organizations"("id")
);

CREATE TABLE "roles" (
  "id" UUID NOT NULL,
  "organization_id" UUID NOT NULL,
  "code" TEXT NOT NULL,
  "name" TEXT NOT NULL,
  CONSTRAINT "roles_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "roles_organization_id_id_key" UNIQUE ("organization_id", "id"),
  CONSTRAINT "roles_organization_id_code_key" UNIQUE ("organization_id", "code"),
  CONSTRAINT "roles_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "organizations"("id")
);

CREATE TABLE "permissions" (
  "id" UUID NOT NULL,
  "code" TEXT NOT NULL,
  "description" TEXT NOT NULL,
  CONSTRAINT "permissions_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "permissions_code_key" UNIQUE ("code")
);

CREATE TABLE "role_permissions" (
  "role_id" UUID NOT NULL,
  "permission_id" UUID NOT NULL,
  CONSTRAINT "role_permissions_pkey" PRIMARY KEY ("role_id", "permission_id"),
  CONSTRAINT "role_permissions_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "roles"("id"),
  CONSTRAINT "role_permissions_permission_id_fkey" FOREIGN KEY ("permission_id") REFERENCES "permissions"("id")
);

CREATE TABLE "user_roles" (
  "id" UUID NOT NULL,
  "organization_id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "user_id" UUID NOT NULL,
  "role_id" UUID NOT NULL,
  CONSTRAINT "user_roles_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "user_roles_branch_user_role_key" UNIQUE ("branch_id", "user_id", "role_id"),
  CONSTRAINT "user_roles_branch_fkey" FOREIGN KEY ("organization_id", "branch_id") REFERENCES "branches"("organization_id", "id"),
  CONSTRAINT "user_roles_user_fkey" FOREIGN KEY ("organization_id", "user_id") REFERENCES "users"("organization_id", "id"),
  CONSTRAINT "user_roles_role_fkey" FOREIGN KEY ("organization_id", "role_id") REFERENCES "roles"("organization_id", "id")
);

CREATE TABLE "sessions" (
  "id" UUID NOT NULL,
  "user_id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "token_hash" TEXT NOT NULL,
  "expires_at" TIMESTAMPTZ(6) NOT NULL,
  "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "sessions_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "sessions_token_hash_key" UNIQUE ("token_hash"),
  CONSTRAINT "sessions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id"),
  CONSTRAINT "sessions_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "branches"("id")
);

CREATE TABLE "authorization_pins" (
  "id" UUID NOT NULL,
  "user_id" UUID NOT NULL,
  "branch_id" UUID NOT NULL,
  "pin_hash" TEXT NOT NULL,
  "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "authorization_pins_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "authorization_pins_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id"),
  CONSTRAINT "authorization_pins_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "branches"("id")
);

CREATE TABLE "audit_events" (
  "id" UUID NOT NULL,
  "organization_id" UUID NOT NULL,
  "branch_id" UUID,
  "actor_user_id" UUID,
  "action" TEXT NOT NULL,
  "entity_type" TEXT NOT NULL,
  "entity_id" UUID,
  "payload" JSONB NOT NULL DEFAULT '{}',
  "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "audit_events_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "audit_events_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "branches"("id")
);

CREATE FUNCTION "app_forbid_mutation"() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION 'append_only:%', TG_TABLE_NAME;
END;
$$;

CREATE TRIGGER "audit_events_append_only"
BEFORE UPDATE OR DELETE ON "audit_events"
FOR EACH ROW EXECUTE FUNCTION "app_forbid_mutation"();
