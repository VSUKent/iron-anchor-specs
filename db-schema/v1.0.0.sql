-- Iron Anchor MVP schema snapshot v1.0.0 for Supabase PostgreSQL.
-- UUID columns are the cross-device identities and relationship keys.
-- Identity `id` columns are server-only surrogate keys; never expose or sync them.
-- This snapshot assumes Supabase's auth and storage schemas are installed.

begin;

create schema if not exists public;

-- A creator is stamped from the authenticated session. Clients must omit this
-- column on writes; row UUIDs and *_uuid relationships are minted client-side.
create or replace function public.set_created_by()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.created_by is null then
    new.created_by := (select auth.uid());
  end if;
  return new;
end;
$$;

create or replace function public.set_listing_published_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    if new.status = 'active' then
      new.published_at := pg_catalog.now();
    end if;
  elsif new.status = 'active' and old.status is distinct from 'active' then
    new.published_at := pg_catalog.now();
  end if;
  return new;
end;
$$;

create table if not exists public.profiles (
  id bigint generated always as identity primary key,
  profile_uuid uuid not null default gen_random_uuid() unique,
  user_uuid uuid not null,
  display_name text,
  avatar_url text,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  archived_at timestamptz
);

create table if not exists public.user_roles (
  id bigint generated always as identity primary key,
  user_role_uuid uuid not null default gen_random_uuid() unique,
  user_uuid uuid not null,
  role text not null check (role in ('system_administrator', 'administrator', 'moderator')),
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  archived_at timestamptz
);

create table if not exists public.barangays (
  id bigint generated always as identity primary key,
  barangay_uuid uuid not null default gen_random_uuid() unique,
  name text not null,
  slug text not null,
  is_active boolean not null default true,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  archived_at timestamptz
);

create table if not exists public.land_types (
  id bigint generated always as identity primary key,
  land_type_uuid uuid not null default gen_random_uuid() unique,
  name text not null,
  slug text not null,
  is_active boolean not null default true,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  archived_at timestamptz
);

create table if not exists public.listings (
  id bigint generated always as identity primary key,
  listing_uuid uuid not null default gen_random_uuid() unique,
  owner_uuid uuid not null,
  barangay_uuid uuid,
  land_type_uuid uuid,
  title text,
  transaction_type text check (transaction_type in ('sale', 'rent')),
  price numeric(14, 2) check (price is null or price >= 0),
  price_period text check (price_period in ('once', 'day', 'month', 'year')),
  area_value numeric(14, 4) check (area_value is null or area_value > 0),
  area_unit text check (area_unit in ('hectare', 'square_meter')),
  -- Store only an intentionally coarsened map pin here.
  public_latitude numeric(9, 3) check (public_latitude is null or public_latitude between -90 and 90),
  public_longitude numeric(9, 3) check (public_longitude is null or public_longitude between -180 and 180),
  status text not null default 'draft'
    check (status in ('draft', 'active', 'hidden', 'rejected', 'removed', 'closed')),
  published_at timestamptz,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  archived_at timestamptz,
  check ((public_latitude is null) = (public_longitude is null))
);

create table if not exists public.listing_private_details (
  id bigint generated always as identity primary key,
  listing_private_details_uuid uuid not null default gen_random_uuid() unique,
  listing_uuid uuid not null,
  description text,
  road_access text,
  water_source text,
  has_electricity boolean,
  terrain text,
  crops_or_trees text,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  archived_at timestamptz
);

create table if not exists public.listing_locations (
  id bigint generated always as identity primary key,
  listing_location_uuid uuid not null default gen_random_uuid() unique,
  listing_uuid uuid not null,
  exact_latitude numeric(9, 6) not null check (exact_latitude between -90 and 90),
  exact_longitude numeric(9, 6) not null check (exact_longitude between -180 and 180),
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  archived_at timestamptz
);

create table if not exists public.listing_photos (
  id bigint generated always as identity primary key,
  listing_photo_uuid uuid not null default gen_random_uuid() unique,
  listing_uuid uuid not null,
  storage_path text not null unique,
  caption text,
  display_order integer not null default 0 check (display_order >= 0),
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  archived_at timestamptz,
  check (storage_path like listing_uuid::text || '/%')
);

create table if not exists public.listing_documents (
  id bigint generated always as identity primary key,
  listing_document_uuid uuid not null default gen_random_uuid() unique,
  listing_uuid uuid not null,
  submitted_by_uuid uuid not null,
  document_type text not null,
  storage_path text not null unique,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  archived_at timestamptz,
  check (storage_path like listing_uuid::text || '/%')
);

create table if not exists public.listing_verifications (
  id bigint generated always as identity primary key,
  listing_verification_uuid uuid not null default gen_random_uuid() unique,
  listing_uuid uuid not null,
  status text not null default 'unverified'
    check (status in ('unverified', 'pending', 'verified', 'rejected')),
  reviewed_by_uuid uuid,
  reviewed_at timestamptz,
  moderator_note text,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  archived_at timestamptz,
  check (
    (status in ('verified', 'rejected') and reviewed_at is not null)
    or status in ('unverified', 'pending')
  )
);

create table if not exists public.favorites (
  id bigint generated always as identity primary key,
  favorite_uuid uuid not null default gen_random_uuid() unique,
  user_uuid uuid not null,
  listing_uuid uuid not null,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  archived_at timestamptz
);

create table if not exists public.barangay_alerts (
  id bigint generated always as identity primary key,
  barangay_alert_uuid uuid not null default gen_random_uuid() unique,
  user_uuid uuid not null,
  barangay_uuid uuid not null,
  is_enabled boolean not null default true,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  archived_at timestamptz
);

create table if not exists public.inquiries (
  id bigint generated always as identity primary key,
  inquiry_uuid uuid not null default gen_random_uuid() unique,
  listing_uuid uuid not null,
  sender_uuid uuid not null,
  recipient_uuid uuid not null,
  status text not null default 'open' check (status in ('open', 'closed')),
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  archived_at timestamptz,
  check (sender_uuid <> recipient_uuid)
);

create table if not exists public.inquiry_messages (
  id bigint generated always as identity primary key,
  inquiry_message_uuid uuid not null default gen_random_uuid() unique,
  inquiry_uuid uuid not null,
  sender_uuid uuid not null,
  body text not null check (length(btrim(body)) > 0),
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  archived_at timestamptz
);

create table if not exists public.listing_reports (
  id bigint generated always as identity primary key,
  listing_report_uuid uuid not null default gen_random_uuid() unique,
  listing_uuid uuid not null,
  reporter_uuid uuid not null,
  reason text not null,
  description text,
  status text not null default 'open' check (status in ('open', 'reviewing', 'resolved', 'dismissed')),
  reviewed_by_uuid uuid,
  reviewed_at timestamptz,
  resolution_note text,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  archived_at timestamptz
);

create table if not exists public.moderation_actions (
  id bigint generated always as identity primary key,
  moderation_action_uuid uuid not null default gen_random_uuid() unique,
  listing_uuid uuid,
  listing_report_uuid uuid,
  moderator_uuid uuid not null,
  action text not null check (
    action in ('hide', 'reject', 'remove', 'restore', 'verify', 'unverify', 'resolve_report', 'dismiss_report')
  ),
  note text,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  archived_at timestamptz,
  check (listing_uuid is not null or listing_report_uuid is not null)
);

create table if not exists public.system_settings (
  id bigint generated always as identity primary key,
  system_setting_uuid uuid not null default gen_random_uuid() unique,
  setting_key text not null,
  setting_value jsonb not null,
  updated_by_uuid uuid,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  archived_at timestamptz
);

-- UUID relationship columns are indexed, but intentionally have no REFERENCES
-- constraints: offline clients can push child rows before parent rows.
create index if not exists profiles_user_uuid_idx on public.profiles (user_uuid);
create unique index if not exists profiles_user_live_idx
  on public.profiles (user_uuid) where archived_at is null;
create index if not exists user_roles_user_uuid_idx on public.user_roles (user_uuid);
create unique index if not exists user_roles_live_idx
  on public.user_roles (user_uuid, role) where archived_at is null;
create unique index if not exists barangays_name_live_idx
  on public.barangays (name) where archived_at is null;
create unique index if not exists barangays_slug_live_idx
  on public.barangays (slug) where archived_at is null;
create unique index if not exists land_types_name_live_idx
  on public.land_types (name) where archived_at is null;
create unique index if not exists land_types_slug_live_idx
  on public.land_types (slug) where archived_at is null;

create index if not exists listings_public_search_idx
  on public.listings (status, barangay_uuid, land_type_uuid, transaction_type, price, area_value)
  where archived_at is null;
create index if not exists listings_owner_status_idx
  on public.listings (owner_uuid, status, updated_at desc);
create index if not exists listings_public_location_idx
  on public.listings (public_latitude, public_longitude)
  where status = 'active' and archived_at is null;
create index if not exists listing_private_details_listing_idx
  on public.listing_private_details (listing_uuid);
create unique index if not exists listing_private_details_live_idx
  on public.listing_private_details (listing_uuid) where archived_at is null;
create index if not exists listing_locations_listing_idx
  on public.listing_locations (listing_uuid);
create unique index if not exists listing_locations_live_idx
  on public.listing_locations (listing_uuid) where archived_at is null;
create index if not exists listing_photos_listing_order_idx
  on public.listing_photos (listing_uuid, display_order) where archived_at is null;
create unique index if not exists listing_photos_live_order_idx
  on public.listing_photos (listing_uuid, display_order) where archived_at is null;
create index if not exists listing_documents_listing_idx
  on public.listing_documents (listing_uuid, created_at desc);
create index if not exists listing_documents_submitter_idx
  on public.listing_documents (submitted_by_uuid);
create index if not exists listing_verifications_listing_idx
  on public.listing_verifications (listing_uuid);
create unique index if not exists listing_verifications_live_idx
  on public.listing_verifications (listing_uuid) where archived_at is null;
create index if not exists favorites_user_idx
  on public.favorites (user_uuid, created_at desc);
create index if not exists favorites_listing_idx
  on public.favorites (listing_uuid, created_at desc);
create unique index if not exists favorites_live_idx
  on public.favorites (user_uuid, listing_uuid) where archived_at is null;
create index if not exists barangay_alerts_user_enabled_idx
  on public.barangay_alerts (user_uuid, is_enabled, barangay_uuid);
create unique index if not exists barangay_alerts_live_idx
  on public.barangay_alerts (user_uuid, barangay_uuid) where archived_at is null;
create index if not exists inquiries_listing_idx on public.inquiries (listing_uuid);
create index if not exists inquiries_sender_idx on public.inquiries (sender_uuid, updated_at desc);
create index if not exists inquiries_recipient_idx on public.inquiries (recipient_uuid, updated_at desc);
create index if not exists inquiries_participants_updated_idx
  on public.inquiries (sender_uuid, recipient_uuid, updated_at desc);
create index if not exists inquiry_messages_thread_created_idx
  on public.inquiry_messages (inquiry_uuid, created_at);
create index if not exists listing_reports_listing_idx on public.listing_reports (listing_uuid);
create index if not exists listing_reports_reporter_idx on public.listing_reports (reporter_uuid);
create index if not exists listing_reports_queue_idx
  on public.listing_reports (status, created_at) where archived_at is null;
create index if not exists moderation_actions_listing_created_idx
  on public.moderation_actions (listing_uuid, created_at desc);
create index if not exists moderation_actions_report_created_idx
  on public.moderation_actions (listing_report_uuid, created_at desc);
create unique index if not exists system_settings_key_live_idx
  on public.system_settings (setting_key) where archived_at is null;

create or replace function public.has_platform_role(_role text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.user_roles as ur
    where ur.user_uuid = (select auth.uid())
      and ur.role = _role
      and ur.archived_at is null
  );
$$;

create or replace function public.assert_listing_publishable(_listing_uuid uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if exists (
    select 1
    from public.listings as l
    where l.listing_uuid = _listing_uuid
      and l.status = 'active'
      and l.archived_at is null
      and (
        l.title is null or length(btrim(l.title)) = 0
        or l.barangay_uuid is null
        or l.land_type_uuid is null
        or l.transaction_type is null
        or l.price is null
        or l.area_value is null
        or l.area_unit is null
        or l.public_latitude is null
        or not exists (
          select 1
          from public.listing_photos as p
          where p.listing_uuid = l.listing_uuid
            and p.archived_at is null
        )
      )
  ) then
    raise exception 'An active listing must have complete core details, a public map pin, and at least one photo'
      using errcode = '23514';
  end if;
end;
$$;

create or replace function public.check_listing_publishable_trigger()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_table_name = 'listings' then
    if tg_op = 'INSERT' then
      perform public.assert_listing_publishable(new.listing_uuid);
    elsif tg_op = 'DELETE' then
      perform public.assert_listing_publishable(old.listing_uuid);
    else
      perform public.assert_listing_publishable(new.listing_uuid);
      if old.listing_uuid is distinct from new.listing_uuid then
        perform public.assert_listing_publishable(old.listing_uuid);
      end if;
    end if;
  elsif tg_op = 'DELETE' then
    perform public.assert_listing_publishable(old.listing_uuid);
  elsif tg_op = 'UPDATE' then
    perform public.assert_listing_publishable(new.listing_uuid);
    if old.listing_uuid is distinct from new.listing_uuid then
      perform public.assert_listing_publishable(old.listing_uuid);
    end if;
  else
    perform public.assert_listing_publishable(new.listing_uuid);
  end if;
  return null;
end;
$$;

create or replace function public.prevent_listing_owner_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (select auth.uid()) is not null
     and old.owner_uuid is distinct from new.owner_uuid
     and not (
       public.has_platform_role('moderator')
       or public.has_platform_role('administrator')
       or public.has_platform_role('system_administrator')
     ) then
    raise exception 'Only a moderator or administrator may change listing ownership'
      using errcode = '42501';
  end if;
  return new;
end;
$$;

create or replace function public.stamp_listing_verification_review()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.status in ('verified', 'rejected') then
    if tg_op = 'INSERT' then
      new.reviewed_by_uuid := coalesce((select auth.uid()), new.reviewed_by_uuid);
      new.reviewed_at := pg_catalog.now();
    elsif old.status is distinct from new.status then
      new.reviewed_by_uuid := coalesce((select auth.uid()), new.reviewed_by_uuid);
      new.reviewed_at := pg_catalog.now();
    end if;
  else
    new.reviewed_by_uuid := null;
    new.reviewed_at := null;
  end if;
  return new;
end;
$$;

create or replace function public.stamp_listing_report_review()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.status <> 'open' then
    if tg_op = 'INSERT' then
      new.reviewed_by_uuid := coalesce((select auth.uid()), new.reviewed_by_uuid);
      new.reviewed_at := pg_catalog.now();
    elsif old.status is distinct from new.status then
      new.reviewed_by_uuid := coalesce((select auth.uid()), new.reviewed_by_uuid);
      new.reviewed_at := pg_catalog.now();
    end if;
  end if;
  return new;
end;
$$;

create or replace function public.stamp_moderation_action_actor()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.moderator_uuid := coalesce((select auth.uid()), new.moderator_uuid);
  new.created_by := coalesce((select auth.uid()), new.created_by);
  return new;
end;
$$;

create or replace function public.stamp_system_setting_actor()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_by_uuid := coalesce((select auth.uid()), new.updated_by_uuid);
  return new;
end;
$$;

create or replace function public.get_admin_platform_metrics()
returns table (metric text, metric_value bigint)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not (
    public.has_platform_role('administrator')
    or public.has_platform_role('system_administrator')
  ) then
    raise exception 'Administrator role required' using errcode = '42501';
  end if;

  return query
  select m.metric, case when m.metric_value >= 10 then m.metric_value else null end
  from (
    select 'active_listings'::text as metric, count(*)::bigint as metric_value
      from public.listings where status = 'active' and archived_at is null
    union all
    select 'new_listings_7d', count(*)::bigint
      from public.listings where created_at >= now() - interval '7 days' and archived_at is null
    union all
    select 'favorites', count(*)::bigint from public.favorites where archived_at is null
    union all
    select 'inquiries', count(*)::bigint from public.inquiries where archived_at is null
    union all
    select 'open_reports', count(*)::bigint
      from public.listing_reports where status in ('open', 'reviewing') and archived_at is null
    union all
    select 'verified_listings', count(*)::bigint
      from public.listing_verifications where status = 'verified' and archived_at is null
  ) as m
  order by m.metric;
end;
$$;

create or replace function public.touch_inquiry_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  update public.inquiries
  set updated_at = greatest(updated_at, new.created_at)
  where inquiry_uuid = new.inquiry_uuid;
  return new;
end;
$$;

drop trigger if exists profiles_set_created_by on public.profiles;
create trigger profiles_set_created_by before insert on public.profiles
  for each row execute function public.set_created_by();
drop trigger if exists user_roles_set_created_by on public.user_roles;
create trigger user_roles_set_created_by before insert on public.user_roles
  for each row execute function public.set_created_by();
drop trigger if exists barangays_set_created_by on public.barangays;
create trigger barangays_set_created_by before insert on public.barangays
  for each row execute function public.set_created_by();
drop trigger if exists land_types_set_created_by on public.land_types;
create trigger land_types_set_created_by before insert on public.land_types
  for each row execute function public.set_created_by();
drop trigger if exists listings_set_created_by on public.listings;
create trigger listings_set_created_by before insert on public.listings
  for each row execute function public.set_created_by();
drop trigger if exists listing_private_details_set_created_by on public.listing_private_details;
create trigger listing_private_details_set_created_by before insert on public.listing_private_details
  for each row execute function public.set_created_by();
drop trigger if exists listing_locations_set_created_by on public.listing_locations;
create trigger listing_locations_set_created_by before insert on public.listing_locations
  for each row execute function public.set_created_by();
drop trigger if exists listing_photos_set_created_by on public.listing_photos;
create trigger listing_photos_set_created_by before insert on public.listing_photos
  for each row execute function public.set_created_by();
drop trigger if exists listing_documents_set_created_by on public.listing_documents;
create trigger listing_documents_set_created_by before insert on public.listing_documents
  for each row execute function public.set_created_by();
drop trigger if exists listing_verifications_set_created_by on public.listing_verifications;
create trigger listing_verifications_set_created_by before insert on public.listing_verifications
  for each row execute function public.set_created_by();
drop trigger if exists favorites_set_created_by on public.favorites;
create trigger favorites_set_created_by before insert on public.favorites
  for each row execute function public.set_created_by();
drop trigger if exists barangay_alerts_set_created_by on public.barangay_alerts;
create trigger barangay_alerts_set_created_by before insert on public.barangay_alerts
  for each row execute function public.set_created_by();
drop trigger if exists inquiries_set_created_by on public.inquiries;
create trigger inquiries_set_created_by before insert on public.inquiries
  for each row execute function public.set_created_by();
drop trigger if exists inquiry_messages_set_created_by on public.inquiry_messages;
create trigger inquiry_messages_set_created_by before insert on public.inquiry_messages
  for each row execute function public.set_created_by();
drop trigger if exists listing_reports_set_created_by on public.listing_reports;
create trigger listing_reports_set_created_by before insert on public.listing_reports
  for each row execute function public.set_created_by();
drop trigger if exists system_settings_set_created_by on public.system_settings;
create trigger system_settings_set_created_by before insert on public.system_settings
  for each row execute function public.set_created_by();

drop trigger if exists listings_set_published_at on public.listings;
create trigger listings_set_published_at before insert or update of status on public.listings
  for each row execute function public.set_listing_published_at();
drop trigger if exists listings_prevent_owner_change on public.listings;
create trigger listings_prevent_owner_change before update of owner_uuid on public.listings
  for each row execute function public.prevent_listing_owner_change();
drop trigger if exists listing_verifications_stamp_review on public.listing_verifications;
create trigger listing_verifications_stamp_review before insert or update of status on public.listing_verifications
  for each row execute function public.stamp_listing_verification_review();
drop trigger if exists listing_reports_stamp_review on public.listing_reports;
create trigger listing_reports_stamp_review before insert or update of status on public.listing_reports
  for each row execute function public.stamp_listing_report_review();
drop trigger if exists moderation_actions_stamp_actor on public.moderation_actions;
create trigger moderation_actions_stamp_actor before insert on public.moderation_actions
  for each row execute function public.stamp_moderation_action_actor();
drop trigger if exists system_settings_stamp_actor on public.system_settings;
create trigger system_settings_stamp_actor before insert or update on public.system_settings
  for each row execute function public.stamp_system_setting_actor();
drop trigger if exists inquiry_messages_touch_inquiry on public.inquiry_messages;
create trigger inquiry_messages_touch_inquiry after insert on public.inquiry_messages
  for each row execute function public.touch_inquiry_updated_at();

drop trigger if exists listings_validate_publishable on public.listings;
create constraint trigger listings_validate_publishable
  after insert or update or delete on public.listings
  deferrable initially deferred
  for each row execute function public.check_listing_publishable_trigger();
drop trigger if exists listing_photos_validate_publishable on public.listing_photos;
create constraint trigger listing_photos_validate_publishable
  after insert or update or delete on public.listing_photos
  deferrable initially deferred
  for each row execute function public.check_listing_publishable_trigger();

alter table public.profiles enable row level security;
alter table public.user_roles enable row level security;
alter table public.barangays enable row level security;
alter table public.land_types enable row level security;
alter table public.listings enable row level security;
alter table public.listing_private_details enable row level security;
alter table public.listing_locations enable row level security;
alter table public.listing_photos enable row level security;
alter table public.listing_documents enable row level security;
alter table public.listing_verifications enable row level security;
alter table public.favorites enable row level security;
alter table public.barangay_alerts enable row level security;
alter table public.inquiries enable row level security;
alter table public.inquiry_messages enable row level security;
alter table public.listing_reports enable row level security;
alter table public.moderation_actions enable row level security;
alter table public.system_settings enable row level security;

drop policy if exists profiles_read_own on public.profiles;
create policy profiles_read_own on public.profiles for select to authenticated
  using (user_uuid = (select auth.uid()));
drop policy if exists profiles_insert_own on public.profiles;
create policy profiles_insert_own on public.profiles for insert to authenticated
  with check (user_uuid = (select auth.uid()));
drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own on public.profiles for update to authenticated
  using (user_uuid = (select auth.uid()))
  with check (user_uuid = (select auth.uid()));

drop policy if exists user_roles_read_own_or_admin on public.user_roles;
create policy user_roles_read_own_or_admin on public.user_roles for select to authenticated
  using (
    user_uuid = (select auth.uid())
    or public.has_platform_role('administrator')
    or public.has_platform_role('system_administrator')
  );

drop policy if exists barangays_read_active_anon on public.barangays;
create policy barangays_read_active_anon on public.barangays for select to anon
  using (is_active and archived_at is null);
drop policy if exists barangays_read_active_authenticated on public.barangays;
create policy barangays_read_active_authenticated on public.barangays for select to authenticated
  using (
    (is_active and archived_at is null)
    or public.has_platform_role('administrator')
    or public.has_platform_role('system_administrator')
  );
drop policy if exists barangays_manage_admin on public.barangays;
create policy barangays_manage_admin on public.barangays for all to authenticated
  using (public.has_platform_role('administrator') or public.has_platform_role('system_administrator'))
  with check (public.has_platform_role('administrator') or public.has_platform_role('system_administrator'));

drop policy if exists land_types_read_active_anon on public.land_types;
create policy land_types_read_active_anon on public.land_types for select to anon
  using (is_active and archived_at is null);
drop policy if exists land_types_read_active_authenticated on public.land_types;
create policy land_types_read_active_authenticated on public.land_types for select to authenticated
  using (
    (is_active and archived_at is null)
    or public.has_platform_role('administrator')
    or public.has_platform_role('system_administrator')
  );
drop policy if exists land_types_manage_admin on public.land_types;
create policy land_types_manage_admin on public.land_types for all to authenticated
  using (public.has_platform_role('administrator') or public.has_platform_role('system_administrator'))
  with check (public.has_platform_role('administrator') or public.has_platform_role('system_administrator'));

drop policy if exists listings_read_authenticated on public.listings;
create policy listings_read_authenticated on public.listings for select to authenticated
  using (
    (status = 'active' and archived_at is null)
    or owner_uuid = (select auth.uid())
    or public.has_platform_role('moderator')
    or public.has_platform_role('administrator')
    or public.has_platform_role('system_administrator')
  );
drop policy if exists listings_insert_owner on public.listings;
create policy listings_insert_owner on public.listings for insert to authenticated
  with check (
    owner_uuid = (select auth.uid())
    or public.has_platform_role('moderator')
    or public.has_platform_role('administrator')
    or public.has_platform_role('system_administrator')
  );
drop policy if exists listings_update_owner_or_moderator on public.listings;
create policy listings_update_owner_or_moderator on public.listings for update to authenticated
  using (
    owner_uuid = (select auth.uid())
    or public.has_platform_role('moderator')
    or public.has_platform_role('administrator')
    or public.has_platform_role('system_administrator')
  )
  with check (
    owner_uuid = (select auth.uid())
    or public.has_platform_role('moderator')
    or public.has_platform_role('administrator')
    or public.has_platform_role('system_administrator')
  );
drop policy if exists listings_delete_owner_or_moderator on public.listings;
create policy listings_delete_owner_or_moderator on public.listings for delete to authenticated
  using (
    owner_uuid = (select auth.uid())
    or public.has_platform_role('moderator')
    or public.has_platform_role('administrator')
    or public.has_platform_role('system_administrator')
  );

drop policy if exists listing_private_details_read_members on public.listing_private_details;
create policy listing_private_details_read_members on public.listing_private_details for select to authenticated
  using (
    exists (
      select 1 from public.listings as l
      where l.listing_uuid = listing_private_details.listing_uuid
        and (
          (l.status = 'active' and l.archived_at is null and listing_private_details.archived_at is null)
          or l.owner_uuid = (select auth.uid())
        )
    )
    or public.has_platform_role('moderator')
    or public.has_platform_role('administrator')
    or public.has_platform_role('system_administrator')
  );
drop policy if exists listing_private_details_write_owner_or_moderator on public.listing_private_details;
create policy listing_private_details_write_owner_or_moderator on public.listing_private_details for all to authenticated
  using (
    exists (select 1 from public.listings as l
      where l.listing_uuid = listing_private_details.listing_uuid and l.owner_uuid = (select auth.uid()))
    or public.has_platform_role('moderator')
    or public.has_platform_role('administrator')
    or public.has_platform_role('system_administrator')
  )
  with check (
    exists (select 1 from public.listings as l
      where l.listing_uuid = listing_private_details.listing_uuid and l.owner_uuid = (select auth.uid()))
    or public.has_platform_role('moderator')
    or public.has_platform_role('administrator')
    or public.has_platform_role('system_administrator')
  );

drop policy if exists listing_locations_read_members on public.listing_locations;
create policy listing_locations_read_members on public.listing_locations for select to authenticated
  using (
    exists (select 1 from public.listings as l
      where l.listing_uuid = listing_locations.listing_uuid
        and (
          (l.status = 'active' and l.archived_at is null and listing_locations.archived_at is null)
          or l.owner_uuid = (select auth.uid())
        ))
    or public.has_platform_role('moderator')
    or public.has_platform_role('administrator')
    or public.has_platform_role('system_administrator')
  );
drop policy if exists listing_locations_write_owner_or_moderator on public.listing_locations;
create policy listing_locations_write_owner_or_moderator on public.listing_locations for all to authenticated
  using (
    exists (select 1 from public.listings as l
      where l.listing_uuid = listing_locations.listing_uuid and l.owner_uuid = (select auth.uid()))
    or public.has_platform_role('moderator')
    or public.has_platform_role('administrator')
    or public.has_platform_role('system_administrator')
  )
  with check (
    exists (select 1 from public.listings as l
      where l.listing_uuid = listing_locations.listing_uuid and l.owner_uuid = (select auth.uid()))
    or public.has_platform_role('moderator')
    or public.has_platform_role('administrator')
    or public.has_platform_role('system_administrator')
  );

drop policy if exists listing_photos_read_authenticated on public.listing_photos;
create policy listing_photos_read_authenticated on public.listing_photos for select to authenticated
  using (
    exists (select 1 from public.listings as l
      where l.listing_uuid = listing_photos.listing_uuid
        and (
          (l.status = 'active' and l.archived_at is null and listing_photos.archived_at is null)
          or l.owner_uuid = (select auth.uid())
        ))
    or public.has_platform_role('moderator')
    or public.has_platform_role('administrator')
    or public.has_platform_role('system_administrator')
  );
drop policy if exists listing_photos_write_owner_or_moderator on public.listing_photos;
create policy listing_photos_write_owner_or_moderator on public.listing_photos for all to authenticated
  using (
    exists (select 1 from public.listings as l
      where l.listing_uuid = listing_photos.listing_uuid and l.owner_uuid = (select auth.uid()))
    or public.has_platform_role('moderator')
    or public.has_platform_role('administrator')
    or public.has_platform_role('system_administrator')
  )
  with check (
    exists (select 1 from public.listings as l
      where l.listing_uuid = listing_photos.listing_uuid and l.owner_uuid = (select auth.uid()))
    or public.has_platform_role('moderator')
    or public.has_platform_role('administrator')
    or public.has_platform_role('system_administrator')
  );

drop policy if exists listing_documents_read_owner_or_moderator on public.listing_documents;
create policy listing_documents_read_owner_or_moderator on public.listing_documents for select to authenticated
  using (
    submitted_by_uuid = (select auth.uid())
    or exists (select 1 from public.listings as l
      where l.listing_uuid = listing_documents.listing_uuid and l.owner_uuid = (select auth.uid()))
    or public.has_platform_role('moderator')
    or public.has_platform_role('administrator')
    or public.has_platform_role('system_administrator')
  );
drop policy if exists listing_documents_insert_owner on public.listing_documents;
create policy listing_documents_insert_owner on public.listing_documents for insert to authenticated
  with check (
    submitted_by_uuid = (select auth.uid())
    and exists (select 1 from public.listings as l
      where l.listing_uuid = listing_documents.listing_uuid and l.owner_uuid = (select auth.uid()))
  );
drop policy if exists listing_documents_delete_owner_or_moderator on public.listing_documents;
create policy listing_documents_delete_owner_or_moderator on public.listing_documents for delete to authenticated
  using (
    submitted_by_uuid = (select auth.uid())
    or public.has_platform_role('moderator')
    or public.has_platform_role('administrator')
    or public.has_platform_role('system_administrator')
  );

drop policy if exists listing_verifications_read_members on public.listing_verifications;
create policy listing_verifications_read_members on public.listing_verifications for select to authenticated
  using (
    exists (select 1 from public.listings as l
      where l.listing_uuid = listing_verifications.listing_uuid
        and (
          (l.status = 'active' and l.archived_at is null and listing_verifications.archived_at is null)
          or l.owner_uuid = (select auth.uid())
        ))
    or public.has_platform_role('moderator')
    or public.has_platform_role('administrator')
    or public.has_platform_role('system_administrator')
  );
drop policy if exists listing_verifications_manage_moderator on public.listing_verifications;
create policy listing_verifications_manage_moderator on public.listing_verifications for all to authenticated
  using (
    public.has_platform_role('moderator')
    or public.has_platform_role('administrator')
    or public.has_platform_role('system_administrator')
  )
  with check (
    public.has_platform_role('moderator')
    or public.has_platform_role('administrator')
    or public.has_platform_role('system_administrator')
  );

drop policy if exists favorites_manage_own on public.favorites;
create policy favorites_manage_own on public.favorites for all to authenticated
  using (user_uuid = (select auth.uid()))
  with check (user_uuid = (select auth.uid()));

drop policy if exists barangay_alerts_manage_own on public.barangay_alerts;
create policy barangay_alerts_manage_own on public.barangay_alerts for all to authenticated
  using (user_uuid = (select auth.uid()))
  with check (user_uuid = (select auth.uid()));

drop policy if exists inquiries_read_participants on public.inquiries;
create policy inquiries_read_participants on public.inquiries for select to authenticated
  using (
    sender_uuid = (select auth.uid())
    or recipient_uuid = (select auth.uid())
    or public.has_platform_role('moderator')
    or public.has_platform_role('administrator')
    or public.has_platform_role('system_administrator')
  );
drop policy if exists inquiries_insert_sender on public.inquiries;
create policy inquiries_insert_sender on public.inquiries for insert to authenticated
  with check (
    sender_uuid = (select auth.uid())
    and exists (select 1 from public.listings as l
      where l.listing_uuid = inquiries.listing_uuid
        and l.status = 'active'
        and l.archived_at is null
        and l.owner_uuid = inquiries.recipient_uuid)
  );
drop policy if exists inquiries_update_participants on public.inquiries;
create policy inquiries_update_participants on public.inquiries for update to authenticated
  using (sender_uuid = (select auth.uid()) or recipient_uuid = (select auth.uid()))
  with check (sender_uuid = (select auth.uid()) or recipient_uuid = (select auth.uid()));

drop policy if exists inquiry_messages_read_participants on public.inquiry_messages;
create policy inquiry_messages_read_participants on public.inquiry_messages for select to authenticated
  using (
    exists (select 1 from public.inquiries as i
      where i.inquiry_uuid = inquiry_messages.inquiry_uuid
        and (i.sender_uuid = (select auth.uid()) or i.recipient_uuid = (select auth.uid())))
    or public.has_platform_role('moderator')
    or public.has_platform_role('administrator')
    or public.has_platform_role('system_administrator')
  );
drop policy if exists inquiry_messages_insert_participant on public.inquiry_messages;
create policy inquiry_messages_insert_participant on public.inquiry_messages for insert to authenticated
  with check (
    sender_uuid = (select auth.uid())
    and exists (select 1 from public.inquiries as i
      where i.inquiry_uuid = inquiry_messages.inquiry_uuid
        and (i.sender_uuid = (select auth.uid()) or i.recipient_uuid = (select auth.uid()))
        and i.status = 'open'
        and i.archived_at is null)
  );

drop policy if exists listing_reports_read_reporter_or_moderator on public.listing_reports;
create policy listing_reports_read_reporter_or_moderator on public.listing_reports for select to authenticated
  using (
    reporter_uuid = (select auth.uid())
    or public.has_platform_role('moderator')
    or public.has_platform_role('administrator')
    or public.has_platform_role('system_administrator')
  );
drop policy if exists listing_reports_insert_reporter on public.listing_reports;
create policy listing_reports_insert_reporter on public.listing_reports for insert to authenticated
  with check (
    reporter_uuid = (select auth.uid())
    and exists (select 1 from public.listings as l
      where l.listing_uuid = listing_reports.listing_uuid
        and l.status = 'active' and l.archived_at is null)
  );
drop policy if exists listing_reports_update_moderator on public.listing_reports;
create policy listing_reports_update_moderator on public.listing_reports for update to authenticated
  using (
    public.has_platform_role('moderator')
    or public.has_platform_role('administrator')
    or public.has_platform_role('system_administrator')
  )
  with check (
    public.has_platform_role('moderator')
    or public.has_platform_role('administrator')
    or public.has_platform_role('system_administrator')
  );

drop policy if exists moderation_actions_read_moderator on public.moderation_actions;
create policy moderation_actions_read_moderator on public.moderation_actions for select to authenticated
  using (
    public.has_platform_role('moderator')
    or public.has_platform_role('administrator')
    or public.has_platform_role('system_administrator')
  );
drop policy if exists moderation_actions_insert_moderator on public.moderation_actions;
create policy moderation_actions_insert_moderator on public.moderation_actions for insert to authenticated
  with check (
    moderator_uuid = (select auth.uid())
    and (
      public.has_platform_role('moderator')
      or public.has_platform_role('administrator')
      or public.has_platform_role('system_administrator')
    )
  );

drop policy if exists system_settings_manage_admin on public.system_settings;
create policy system_settings_manage_admin on public.system_settings for all to authenticated
  using (public.has_platform_role('administrator') or public.has_platform_role('system_administrator'))
  with check (public.has_platform_role('administrator') or public.has_platform_role('system_administrator'));

create or replace view public.public_listing_search
with (security_barrier = true, security_invoker = false)
as
select
  l.listing_uuid,
  l.barangay_uuid,
  l.land_type_uuid,
  l.title,
  l.transaction_type,
  l.price,
  l.price_period,
  l.area_value,
  l.area_unit,
  l.public_latitude,
  l.public_longitude,
  coalesce(v.status, 'unverified') as verification_status,
  l.published_at
from public.listings as l
left join public.listing_verifications as v
  on v.listing_uuid = l.listing_uuid and v.archived_at is null
where l.status = 'active' and l.archived_at is null;

create or replace view public.public_listing_photos
with (security_barrier = true, security_invoker = false)
as
select p.listing_photo_uuid, p.listing_uuid, p.storage_path, p.display_order
from public.listing_photos as p
join public.listings as l on l.listing_uuid = p.listing_uuid
where l.status = 'active' and l.archived_at is null and p.archived_at is null;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('listing-photos', 'listing-photos', false, 10485760, array['image/jpeg', 'image/png', 'image/webp']),
  ('listing-documents', 'listing-documents', false, 20971520, array['application/pdf', 'image/jpeg', 'image/png'])
on conflict (id) do update
set public = false,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists listing_photo_objects_read_public on storage.objects;
create policy listing_photo_objects_read_public on storage.objects for select to anon
  using (
    bucket_id = 'listing-photos'
    and exists (
      select 1 from public.public_listing_photos as p
      where p.storage_path = storage.objects.name
    )
  );
drop policy if exists listing_photo_objects_read_authenticated on storage.objects;
create policy listing_photo_objects_read_authenticated on storage.objects for select to authenticated
  using (
    bucket_id = 'listing-photos'
    and exists (
      select 1
      from public.listing_photos as p
      join public.listings as l on l.listing_uuid = p.listing_uuid
      where p.storage_path = storage.objects.name
        and p.archived_at is null
        and (
          (l.status = 'active' and l.archived_at is null)
          or l.owner_uuid = (select auth.uid())
          or public.has_platform_role('moderator')
          or public.has_platform_role('administrator')
          or public.has_platform_role('system_administrator')
        )
    )
  );
drop policy if exists listing_photo_objects_insert_owner on storage.objects;
create policy listing_photo_objects_insert_owner on storage.objects for insert to authenticated
  with check (
    bucket_id = 'listing-photos'
    and exists (
      select 1 from public.listings as l
      where storage.objects.name like l.listing_uuid::text || '/%'
        and l.owner_uuid = (select auth.uid())
    )
  );
drop policy if exists listing_photo_objects_delete_owner_or_moderator on storage.objects;
create policy listing_photo_objects_delete_owner_or_moderator on storage.objects for delete to authenticated
  using (
    bucket_id = 'listing-photos'
    and (
      exists (select 1 from public.listings as l
        where storage.objects.name like l.listing_uuid::text || '/%'
          and l.owner_uuid = (select auth.uid()))
      or public.has_platform_role('moderator')
      or public.has_platform_role('administrator')
      or public.has_platform_role('system_administrator')
    )
  );

drop policy if exists listing_document_objects_read_owner_or_moderator on storage.objects;
create policy listing_document_objects_read_owner_or_moderator on storage.objects for select to authenticated
  using (
    bucket_id = 'listing-documents'
    and (
      exists (
        select 1
        from public.listing_documents as d
        join public.listings as l on l.listing_uuid = d.listing_uuid
        where d.storage_path = storage.objects.name
          and d.archived_at is null
          and (d.submitted_by_uuid = (select auth.uid()) or l.owner_uuid = (select auth.uid()))
      )
      or public.has_platform_role('moderator')
      or public.has_platform_role('administrator')
      or public.has_platform_role('system_administrator')
    )
  );
drop policy if exists listing_document_objects_insert_owner on storage.objects;
create policy listing_document_objects_insert_owner on storage.objects for insert to authenticated
  with check (
    bucket_id = 'listing-documents'
    and exists (
      select 1 from public.listings as l
      where storage.objects.name like l.listing_uuid::text || '/%'
        and l.owner_uuid = (select auth.uid())
    )
  );
drop policy if exists listing_document_objects_delete_owner_or_moderator on storage.objects;
create policy listing_document_objects_delete_owner_or_moderator on storage.objects for delete to authenticated
  using (
    bucket_id = 'listing-documents'
    and (
      exists (select 1 from public.listings as l
        where storage.objects.name like l.listing_uuid::text || '/%'
          and l.owner_uuid = (select auth.uid()))
      or public.has_platform_role('moderator')
      or public.has_platform_role('administrator')
      or public.has_platform_role('system_administrator')
    )
  );

-- Deny default access to these tables and sequences; IDs stay server-only.
revoke all on
  public.profiles, public.user_roles, public.barangays, public.land_types, public.listings,
  public.listing_private_details, public.listing_locations, public.listing_photos,
  public.listing_documents, public.listing_verifications, public.favorites,
  public.barangay_alerts, public.inquiries, public.inquiry_messages, public.listing_reports,
  public.moderation_actions, public.system_settings, public.public_listing_search,
  public.public_listing_photos
from public, anon, authenticated;
revoke all on sequence
  public.profiles_id_seq, public.user_roles_id_seq, public.barangays_id_seq,
  public.land_types_id_seq, public.listings_id_seq, public.listing_private_details_id_seq,
  public.listing_locations_id_seq, public.listing_photos_id_seq, public.listing_documents_id_seq,
  public.listing_verifications_id_seq, public.favorites_id_seq, public.barangay_alerts_id_seq,
  public.inquiries_id_seq, public.inquiry_messages_id_seq, public.listing_reports_id_seq,
  public.moderation_actions_id_seq, public.system_settings_id_seq
from public, anon, authenticated;
grant usage on schema public to anon, authenticated, service_role;

revoke all on function public.has_platform_role(text) from public, anon;
revoke all on function public.assert_listing_publishable(uuid) from public, anon, authenticated;
revoke all on function public.check_listing_publishable_trigger() from public, anon, authenticated;
revoke all on function public.prevent_listing_owner_change() from public, anon, authenticated;
revoke all on function public.set_created_by() from public, anon, authenticated;
revoke all on function public.set_listing_published_at() from public, anon, authenticated;
revoke all on function public.stamp_listing_verification_review() from public, anon, authenticated;
revoke all on function public.stamp_listing_report_review() from public, anon, authenticated;
revoke all on function public.stamp_moderation_action_actor() from public, anon, authenticated;
revoke all on function public.stamp_system_setting_actor() from public, anon, authenticated;
revoke all on function public.touch_inquiry_updated_at() from public, anon, authenticated;
revoke all on function public.get_admin_platform_metrics() from public, anon;
grant execute on function public.has_platform_role(text) to authenticated;
grant execute on function public.get_admin_platform_metrics() to authenticated;

grant select on public.public_listing_search, public.public_listing_photos to anon, authenticated;
grant select (barangay_uuid, name, slug, is_active) on public.barangays to anon;
grant select (land_type_uuid, name, slug, is_active) on public.land_types to anon;

grant select (profile_uuid, user_uuid, display_name, avatar_url, created_by, created_at, updated_at, archived_at)
  on public.profiles to authenticated;
grant insert (profile_uuid, user_uuid, display_name, avatar_url, created_at, updated_at, archived_at)
  on public.profiles to authenticated;
grant update (display_name, avatar_url, updated_at, archived_at) on public.profiles to authenticated;

grant select (user_role_uuid, user_uuid, role, created_by, created_at, updated_at, archived_at)
  on public.user_roles to authenticated;

grant select (barangay_uuid, name, slug, is_active, created_by, created_at, updated_at, archived_at)
  on public.barangays to authenticated;
grant insert (barangay_uuid, name, slug, is_active, created_at, updated_at, archived_at)
  on public.barangays to authenticated;
grant update (name, slug, is_active, updated_at, archived_at) on public.barangays to authenticated;

grant select (land_type_uuid, name, slug, is_active, created_by, created_at, updated_at, archived_at)
  on public.land_types to authenticated;
grant insert (land_type_uuid, name, slug, is_active, created_at, updated_at, archived_at)
  on public.land_types to authenticated;
grant update (name, slug, is_active, updated_at, archived_at) on public.land_types to authenticated;

grant select (
  listing_uuid, owner_uuid, barangay_uuid, land_type_uuid, title, transaction_type,
  price, price_period, area_value, area_unit, public_latitude, public_longitude,
  status, published_at, created_by, created_at, updated_at, archived_at
) on public.listings to authenticated;
grant insert (
  listing_uuid, owner_uuid, barangay_uuid, land_type_uuid, title, transaction_type,
  price, price_period, area_value, area_unit, public_latitude, public_longitude,
  status, created_at, updated_at, archived_at
) on public.listings to authenticated;
grant update (
  barangay_uuid, land_type_uuid, title, transaction_type, price, price_period,
  area_value, area_unit, public_latitude, public_longitude, status, updated_at, archived_at
) on public.listings to authenticated;

grant select (
  listing_private_details_uuid, listing_uuid, description, road_access, water_source,
  has_electricity, terrain, crops_or_trees, created_by, created_at, updated_at, archived_at
) on public.listing_private_details to authenticated;
grant insert (
  listing_private_details_uuid, listing_uuid, description, road_access, water_source,
  has_electricity, terrain, crops_or_trees, created_at, updated_at, archived_at
) on public.listing_private_details to authenticated;
grant update (
  listing_uuid, description, road_access, water_source, has_electricity,
  terrain, crops_or_trees, updated_at, archived_at
) on public.listing_private_details to authenticated;

grant select (
  listing_location_uuid, listing_uuid, exact_latitude, exact_longitude,
  created_by, created_at, updated_at, archived_at
) on public.listing_locations to authenticated;
grant insert (
  listing_location_uuid, listing_uuid, exact_latitude, exact_longitude, created_at, updated_at, archived_at
) on public.listing_locations to authenticated;
grant update (listing_uuid, exact_latitude, exact_longitude, updated_at, archived_at)
  on public.listing_locations to authenticated;

grant select (
  listing_photo_uuid, listing_uuid, storage_path, caption, display_order,
  created_by, created_at, updated_at, archived_at
) on public.listing_photos to authenticated;
grant insert (
  listing_photo_uuid, listing_uuid, storage_path, caption, display_order, created_at, updated_at, archived_at
) on public.listing_photos to authenticated;
grant update (listing_uuid, storage_path, caption, display_order, updated_at, archived_at)
  on public.listing_photos to authenticated;

grant select (
  listing_document_uuid, listing_uuid, submitted_by_uuid, document_type, storage_path,
  created_by, created_at, updated_at, archived_at
) on public.listing_documents to authenticated;
grant insert (
  listing_document_uuid, listing_uuid, submitted_by_uuid, document_type,
  storage_path, created_at, updated_at, archived_at
) on public.listing_documents to authenticated;
grant update (document_type, storage_path, updated_at, archived_at) on public.listing_documents to authenticated;

grant select (
  listing_verification_uuid, listing_uuid, status, reviewed_by_uuid, reviewed_at,
  moderator_note, created_by, created_at, updated_at, archived_at
) on public.listing_verifications to authenticated;
grant insert (listing_verification_uuid, listing_uuid, status, moderator_note, created_at, updated_at, archived_at)
  on public.listing_verifications to authenticated;
grant update (status, moderator_note, updated_at, archived_at) on public.listing_verifications to authenticated;

grant select (favorite_uuid, user_uuid, listing_uuid, created_by, created_at, updated_at, archived_at)
  on public.favorites to authenticated;
grant insert (favorite_uuid, user_uuid, listing_uuid, created_at, updated_at, archived_at)
  on public.favorites to authenticated;
grant update (updated_at, archived_at) on public.favorites to authenticated;

grant select (
  barangay_alert_uuid, user_uuid, barangay_uuid, is_enabled, created_by, created_at, updated_at, archived_at
) on public.barangay_alerts to authenticated;
grant insert (barangay_alert_uuid, user_uuid, barangay_uuid, is_enabled, created_at, updated_at, archived_at)
  on public.barangay_alerts to authenticated;
grant update (barangay_uuid, is_enabled, updated_at, archived_at) on public.barangay_alerts to authenticated;

grant select (
  inquiry_uuid, listing_uuid, sender_uuid, recipient_uuid, status, created_by, created_at, updated_at, archived_at
) on public.inquiries to authenticated;
grant insert (inquiry_uuid, listing_uuid, sender_uuid, recipient_uuid, created_at, updated_at, archived_at)
  on public.inquiries to authenticated;
grant update (status, updated_at, archived_at) on public.inquiries to authenticated;

grant select (
  inquiry_message_uuid, inquiry_uuid, sender_uuid, body, created_by, created_at, updated_at, archived_at
) on public.inquiry_messages to authenticated;
grant insert (inquiry_message_uuid, inquiry_uuid, sender_uuid, body, created_at, updated_at, archived_at)
  on public.inquiry_messages to authenticated;

grant select (
  listing_report_uuid, listing_uuid, reporter_uuid, reason, description, status,
  reviewed_by_uuid, reviewed_at, resolution_note, created_by, created_at, updated_at, archived_at
) on public.listing_reports to authenticated;
grant insert (listing_report_uuid, listing_uuid, reporter_uuid, reason, description, created_at, updated_at, archived_at)
  on public.listing_reports to authenticated;
grant update (status, resolution_note, updated_at, archived_at) on public.listing_reports to authenticated;

grant select (
  moderation_action_uuid, listing_uuid, listing_report_uuid, moderator_uuid, action,
  note, created_by, created_at, updated_at, archived_at
) on public.moderation_actions to authenticated;
grant insert (moderation_action_uuid, listing_uuid, listing_report_uuid, action, note, created_at, updated_at)
  on public.moderation_actions to authenticated;

grant select (
  system_setting_uuid, setting_key, setting_value, updated_by_uuid,
  created_by, created_at, updated_at, archived_at
) on public.system_settings to authenticated;
grant insert (system_setting_uuid, setting_key, setting_value, created_at, updated_at, archived_at)
  on public.system_settings to authenticated;
grant update (setting_key, setting_value, updated_at, archived_at) on public.system_settings to authenticated;

grant all on
  public.profiles, public.user_roles, public.barangays, public.land_types, public.listings,
  public.listing_private_details, public.listing_locations, public.listing_photos,
  public.listing_documents, public.listing_verifications, public.favorites,
  public.barangay_alerts, public.inquiries, public.inquiry_messages, public.listing_reports,
  public.moderation_actions, public.system_settings
to service_role;
grant usage, select on sequence
  public.profiles_id_seq, public.user_roles_id_seq, public.barangays_id_seq,
  public.land_types_id_seq, public.listings_id_seq, public.listing_private_details_id_seq,
  public.listing_locations_id_seq, public.listing_photos_id_seq, public.listing_documents_id_seq,
  public.listing_verifications_id_seq, public.favorites_id_seq, public.barangay_alerts_id_seq,
  public.inquiries_id_seq, public.inquiry_messages_id_seq, public.listing_reports_id_seq,
  public.moderation_actions_id_seq, public.system_settings_id_seq
to service_role;

commit;
