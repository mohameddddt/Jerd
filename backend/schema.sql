-- Jerd backend schema for Supabase (PostgreSQL).
-- The Flask app also creates these tables on start; run this in the Supabase
-- SQL editor if you prefer to manage the schema yourself.
-- The app never talks to Supabase directly: everything goes through the API.

create table if not exists shops (
  id          varchar(36) primary key,
  name        varchar(120) not null,
  created_at  varchar(32) not null
);

create table if not exists users (
  id             varchar(36) primary key,
  shop_id        varchar(36) not null references shops(id),
  name           varchar(80) not null,
  email          varchar(254) not null unique,
  password_hash  varchar(255) not null,
  role           varchar(16) not null default 'staff' check (role in ('owner', 'staff')),
  active         boolean not null default true,
  created_at     varchar(32) not null
);

create table if not exists products (
  uuid               varchar(36) primary key,
  shop_id            varchar(36) not null references shops(id),
  barcode            varchar(32) not null,
  name               varchar(120) not null,
  unit               varchar(24) not null,
  reorder_point      integer not null default 0 check (reorder_point >= 0),
  image_url          text,
  updated_at         varchar(32) not null,  -- client clock: last-write-wins
  updated_by         varchar(80) not null default '',
  deleted            boolean not null default false,
  server_updated_at  varchar(32) not null   -- server clock: "changed since" pulls
);
create index if not exists idx_products_shop_changed on products (shop_id, server_updated_at);
create index if not exists idx_products_shop_barcode on products (shop_id, barcode);

-- Append-only ledger. Stock is always sum(delta); it is never stored.
create table if not exists movements (
  uuid                varchar(36) primary key,  -- client-generated: retries cannot double-apply
  shop_id             varchar(36) not null references shops(id),
  product_uuid        varchar(36) not null,
  delta               integer not null check (delta <> 0),
  reason              varchar(16) not null check (reason in ('received', 'sold', 'adjusted', 'counted')),
  note                text,
  created_at          varchar(32) not null,
  user_id             varchar(36) not null,
  user_name           varchar(80) not null default '',
  server_received_at  varchar(32) not null
);
create index if not exists idx_movements_shop_received on movements (shop_id, server_received_at);
create index if not exists idx_movements_product on movements (product_uuid);

create table if not exists device_tokens (
  token       varchar(512) primary key,
  user_id     varchar(36) not null references users(id),
  shop_id     varchar(36) not null references shops(id),
  platform    varchar(16) not null,
  updated_at  varchar(32) not null
);

-- Supabase exposes tables through its REST API by default. Lock them down:
-- only the Flask backend (connecting as the database owner) may touch them.
alter table shops enable row level security;
alter table users enable row level security;
alter table products enable row level security;
alter table movements enable row level security;
alter table device_tokens enable row level security;
