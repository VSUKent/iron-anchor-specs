-- Iron Anchor MVP schema snapshot v1.0.0 for Supabase PostgreSQL.
-- Entity UUIDs are the cross-device keys. Identity `id` columns are server-only indexes.
-- Run as the Supabase database owner (normally `postgres`).

create schema if not exists public;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := pg_catalog.now();
  return new;
end;
$$;

create or replace function public.set_listing_published_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' and new.status = 'active' then
    new.published_at := pg_catalog.now();
  elsif tg_op = 'UPDATE' and new.status = 'active'
        and old.status is distinct from 'active' then
    new.published_at := pg_catalog.now();
  end if;
  return new;
end;
$$;

create table if not exists public.profiles (
  id bigint generated always as identity primary key,
  profile_uuid uuid not null default gen_random_uuid() unique,
  user_uuid uuid not null unique references auth.users (id) on delete cascade,
  display_name text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.user_roles (
  id bigint generated always as identity primary key,
  user_role_uuid uuid not null default gen_random_uuid() unique,
  user_uuid uuid not null references auth.users (id) on delete cascade,
  role text not null check (role in ('system_administrator', 'administrator', 'moderator')),
  created_at timestamptz not null default now(),
  unique (user_uuid, role)
);

create table if not exists public.barangays (
  id bigint generated always as identity primary key,
  barangay_uuid uuid not null default gen_random_uuid() unique,
  name text not null unique,
  slug text not null unique,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.land_types (
  id bigint generated always as identity primary key,
  land_type_uuid uuid not null default gen_random_uuid() unique,
  name text not null unique,
  slug text not null unique,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.listings (
  id bigint generated always as identity primary key,
  listing_uuid uuid not null default gen_random_uuid() unique,
  owner_uuid uuid not null references auth.users (id) on delete cascade,
  barangay_uuid uuid references public.barangays (barangay_uuid) on delete restrict,
  land_type_uuid uuid references public.land_types (land_type_uuid) on delete restrict,
  title text,
  transaction_type text check (transaction_type in ('sale', 'rent')),
  price numeric(14, 2) check (price is null or price >= 0),
  price_period text check (price_period in ('once', 'day', 'month', 'year')),
  area_value numeric(14, 4) check (area_value is null or area_value > 0),
  area_unit text check (area_unit in ('hectare', 'square_meter')),
  -- Store only an intentionally coarsened pin here; exact coordinates belong in listing_locations.
  public_latitude numeric(9, 6) check (public_latitude is null or public_latitude between -90 and 90),
  public_longitude numeric(9, 6) check (public_longitude is null or public_longitude between -180 and 180),
  status text not null default 'draft'
    check (status in ('draft', 'active', 'hidden', 'rejected', 'removed', 'closed')),
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check ((public_latitude is null) = (public_longitude is null))
);

create table if not exists public.listing_private_details (
  id bigint generated always as identity primary key,
  listing_private_details_uuid uuid not null default gen_random_uuid() unique,
  listing_uuid uuid not null unique references public.listings (listing_uuid) on delete cascade,
  description text,
  road_access text,
  water_source text,
  has_electricity boolean,
  terrain text,
  crops_or_trees text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.listing_locations (
  id bigint generated always as identity primary key,
  listing_location_uuid uuid not null default gen_random_uuid() unique,
  listing_uuid uuid not null unique references public.listings (listing_uuid) on delete cascade,
  exact_latitude numeric(9, 6) not null check (exact_latitude between -90 and 90),
  exact_longitude numeric(9, 6) not null check (exact_longitude between -180 and 180),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.listing_photos (
  id bigint generated always as identity primary key,
  listing_photo_uuid uuid not null default gen_random_uuid() unique,
  listing_uuid uuid not null references public.listings (listing_uuid) on delete cascade,
  storage_path text not null unique check (storage_path like listing_uuid::text || '/%'),
  caption text,
  display_order integer not null default 0 check (display_order >= 0),
  created_at timestamptz not null default now(),
  unique (listing_uuid, display_order)
);

create table if not exists public.listing_documents (
  id bigint generated always as identity primary key,
  listing_document_uuid uuid not null default gen_random_uuid() unique,
  listing_uuid uuid not null references public.listings (listing_uuid) on delete cascade,
  submitted_by_uuid uuid not null references auth.users (id) on delete cascade,
  document_type text not null,
  storage_path text not null unique check (storage_path like listing_uuid::text || '/%'),
  created_at timestamptz not null default now()
);

create table if not exists public.listing_verifications (
  id bigint generated always as identity primary key,
  listing_verification_uuid uuid not null default gen_random_uuid() unique,
  listing_uuid uuid not null unique references public.listings (listing_uuid) on delete cascade,
  status text not null default 'unverified'
    check (status in ('unverified', 'pending', 'verified', 'rejected')),
  reviewed_by_uuid uuid references auth.users (id) on delete set null,
  reviewed_at timestamptz,
  moderator_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (
    (status in ('verified', 'rejected') and reviewed_at is not null)
    or status in ('unverified', 'pending')
  )
);

create table if not exists public.favorites (
  id bigint generated always as identity primary key,
  favorite_uuid uuid not null default gen_random_uuid() unique,
  user_uuid uuid not null references auth.users (id) on delete cascade,
  listing_uuid uuid not null references public.listings (listing_uuid) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_uuid, listing_uuid)
);

create table if not exists public.barangay_alerts (
  id bigint generated always as identity primary key,
  barangay_alert_uuid uuid not null default gen_random_uuid() unique,
  user_uuid uuid not null references auth.users (id) on delete cascade,
  barangay_uuid uuid not null references public.barangays (barangay_uuid) on delete cascade,
  is_enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_uuid, barangay_uuid)
);

create table if not exists public.inquiries (
  id bigint generated always as identity primary key,
  inquiry_uuid uuid not null default gen_random_uuid() unique,
  listing_uuid uuid not null references public.listings (listing_uuid) on delete cascade,
  sender_uuid uuid not null references auth.users (id) on delete cascade,
  recipient_uuid uuid not null references auth.users (id) on delete cascade,
  status text not null default 'open' check (status in ('open', 'closed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (sender_uuid <> recipient_uuid)
);

create table if not exists public.inquiry_messages (
  id bigint generated always as identity primary key,
  inquiry_message_uuid uuid not null default gen_random_uuid() unique,
  inquiry_uuid uuid not null references public.inquiries (inquiry_uuid) on delete cascade,
  sender_uuid uuid not null references auth.users (id) on delete cascade,
  body text not null check (length(btrim(body)) > 0),
  created_at timestamptz not null default now()
);

create table if not exists public.listing_reports (
  id bigint generated always as identity primary key,
  listing_report_uuid uuid not null default gen_random_uuid() unique,
  listing_uuid uuid not null references public.listings (listing_uuid) on delete cascade,
  reporter_uuid uuid not null references auth.users (id) on delete cascade,
  reason text not null,
  description text,
  status text not null default 'open' check (status in ('open', 'reviewing', 'resolved', 'dismissed')),
  reviewed_by_uuid uuid references auth.users (id) on delete set null,
  reviewed_at timestamptz,
  resolution_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.moderation_actions (
  id bigint generated always as identity primary key,
  moderation_action_uuid uuid not null default gen_random_uuid() unique,
  listing_uuid uuid references public.listings (listing_uuid) on delete set null,
  listing_report_uuid uuid references public.listing_reports (listing_report_uuid) on delete set null,
  moderator_uuid uuid not null references auth.users (id) on delete restrict,
  action text not null check (action in ('hide', 'reject', 'remove', 'restore', 'verify', 'unverify', 'resolve_report', 'dismiss_report')),
  note text,
  created_at timestamptz not null default now(),
  check (listing_uuid is not null or listing_report_uuid is not null)
);

create table if not exists public.system_settings (
  id bigint generated always as identity primary key,
  system_setting_uuid uuid not null default gen_random_uuid() unique,
  setting_key text not null unique,
  setting_value jsonb not null,
  updated_by_uuid uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists listings_public_search_idx
  on public.listings (status, barangay_uuid, land_type_uuid, transaction_type, price, area_value);
create index if not exists listings_owner_status_idx
  on public.listings (owner_uuid, status, updated_at desc);
create index if not exists listings_public_location_idx
  on public.listings (public_latitude, public_longitude) where status = 'active';
create index if not exists listing_photos_listing_order_idx
  on public.listing_photos (listing_uuid, display_order);
create index if not exists listing_documents_listing_idx
  on public.listing_documents (listing_uuid, created_at desc);
create index if not exists favorites_listing_idx
  on public.favorites (listing_uuid, created_at desc);
create index if not exists barangay_alerts_user_enabled_idx
  on public.barangay_alerts (user_uuid, is_enabled, barangay_uuid);
create index if not exists inquiries_participants_updated_idx
  on public.inquiries (sender_uuid, recipient_uuid, updated_at desc);
create index if not exists inquiry_messages_thread_created_idx
  on public.inquiry_messages (inquiry_uuid, created_at);
create index if not exists listing_reports_queue_idx
  on public.listing_reports (status, created_at);
create index if not exists moderation_actions_listing_created_idx
  on public.moderation_actions (listing_uuid, created_at desc);

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
    perform public.assert_listing_publishable(new.listing_uuid);
  elsif tg_op = 'DELETE' then
    perform public.assert_listing_publishable(old.listing_uuid);
  else
    perform public.assert_listing_publishable(new.listing_uuid);
    if tg_op = 'UPDATE' and old.listing_uuid is distinct from new.listing_uuid then
      perform public.assert_listing_publishable(old.listing_uuid);
    end if;
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
      from public.listings where status = 'active'
    union all
    select 'new_listings_7d', count(*)::bigint
      from public.listings where created_at >= now() - interval '7 days'
    union all
    select 'favorites', count(*)::bigint from public.favorites
    union all
    select 'inquiries', count(*)::bigint from public.inquiries
    union all
    select 'open_reports', count(*)::bigint
      from public.listing_reports where status in ('open', 'reviewing')
    union all
    select 'verified_listings', count(*)::bigint
      from public.listing_verifications where status = 'verified'
  ) as m
  order by m.metric;
end;
$$;

create or replace function public.touch_inquiry_updated_at()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.inquiries
  set updated_at = pg_catalog.now()
  where inquiry_uuid = new.inquiry_uuid;
  return new;
end;
$$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at before update on public.profiles
  for each row execute function public.set_updated_at();
drop trigger if exists barangays_set_updated_at on public.barangays;
create trigger barangays_set_updated_at before update on public.barangays
  for each row execute function public.set_updated_at();
drop trigger if exists land_types_set_updated_at on public.land_types;
create trigger land_types_set_updated_at before update on public.land_types
  for each row execute function public.set_updated_at();
drop trigger if exists listings_set_updated_at on public.listings;
create trigger listings_set_updated_at before update on public.listings
  for each row execute function public.set_updated_at();
drop trigger if exists listings_set_published_at on public.listings;
create trigger listings_set_published_at before insert or update on public.listings
  for each row execute function public.set_listing_published_at();
drop trigger if exists listings_prevent_owner_change on public.listings;
create trigger listings_prevent_owner_change before update of owner_uuid on public.listings
  for each row execute function public.prevent_listing_owner_change();
drop trigger if exists listing_private_details_set_updated_at on public.listing_private_details;
create trigger listing_private_details_set_updated_at before update on public.listing_private_details
  for each row execute function public.set_updated_at();
drop trigger if exists listing_locations_set_updated_at on public.listing_locations;
create trigger listing_locations_set_updated_at before update on public.listing_locations
  for each row execute function public.set_updated_at();
drop trigger if exists listing_verifications_set_updated_at on public.listing_verifications;
create trigger listing_verifications_set_updated_at before update on public.listing_verifications
  for each row execute function public.set_updated_at();
drop trigger if exists barangay_alerts_set_updated_at on public.barangay_alerts;
create trigger barangay_alerts_set_updated_at before update on public.barangay_alerts
  for each row execute function public.set_updated_at();
drop trigger if exists inquiries_set_updated_at on public.inquiries;
create trigger inquiries_set_updated_at before update on public.inquiries
  for each row execute function public.set_updated_at();
drop trigger if exists inquiry_messages_touch_inquiry on public.inquiry_messages;
create trigger inquiry_messages_touch_inquiry after insert on public.inquiry_messages
  for each row execute function public.touch_inquiry_updated_at();
drop trigger if exists listing_reports_set_updated_at on public.listing_reports;
create trigger listing_reports_set_updated_at before update on public.listing_reports
  for each row execute function public.set_updated_at();
drop trigger if exists system_settings_set_updated_at on public.system_settings;
create trigger system_settings_set_updated_at before update on public.system_settings
  for each row execute function public.set_updated_at();

drop trigger if exists listings_validate_publishable on public.listings;
create constraint trigger listings_validate_publishable
  after insert or update on public.listings
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
  using (is_active);
drop policy if exists barangays_read_active_authenticated on public.barangays;
create policy barangays_read_active_authenticated on public.barangays for select to authenticated
  using (is_active or public.has_platform_role('administrator') or public.has_platform_role('system_administrator'));
drop policy if exists barangays_manage_admin on public.barangays;
create policy barangays_manage_admin on public.barangays for all to authenticated
  using (public.has_platform_role('administrator') or public.has_platform_role('system_administrator'))
  with check (public.has_platform_role('administrator') or public.has_platform_role('system_administrator'));

drop policy if exists land_types_read_active_anon on public.land_types;
create policy land_types_read_active_anon on public.land_types for select to anon
  using (is_active);
drop policy if exists land_types_read_active_authenticated on public.land_types;
create policy land_types_read_active_authenticated on public.land_types for select to authenticated
  using (is_active or public.has_platform_role('administrator') or public.has_platform_role('system_administrator'));
drop policy if exists land_types_manage_admin on public.land_types;
create policy land_types_manage_admin on public.land_types for all to authenticated
  using (public.has_platform_role('administrator') or public.has_platform_role('system_administrator'))
  with check (public.has_platform_role('administrator') or public.has_platform_role('system_administrator'));

drop policy if exists listings_read_authenticated on public.listings;
create policy listings_read_authenticated on public.listings for select to authenticated
  using (
    status = 'active'
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
        and (l.status = 'active' or l.owner_uuid = (select auth.uid()))
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
        and (l.status = 'active' or l.owner_uuid = (select auth.uid())))
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
        and (l.status = 'active' or l.owner_uuid = (select auth.uid())))
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
        and (l.status = 'active' or l.owner_uuid = (select auth.uid())))
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
        and i.status = 'open')
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
      where l.listing_uuid = listing_reports.listing_uuid and l.status = 'active')
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
left join public.listing_verifications as v on v.listing_uuid = l.listing_uuid
where l.status = 'active';

create or replace view public.public_listing_photos
with (security_barrier = true, security_invoker = false)
as
select p.listing_photo_uuid, p.listing_uuid, p.storage_path, p.display_order
from public.listing_photos as p
join public.listings as l on l.listing_uuid = p.listing_uuid
where l.status = 'active';

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
      select 1
      from public.public_listing_photos as p
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
        and (
          l.status = 'active'
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
      exists (
        select 1 from public.listings as l
        where storage.objects.name like l.listing_uuid::text || '/%'
          and l.owner_uuid = (select auth.uid())
      )
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
      exists (
        select 1 from public.listings as l
        where storage.objects.name like l.listing_uuid::text || '/%'
          and l.owner_uuid = (select auth.uid())
      )
      or public.has_platform_role('moderator')
      or public.has_platform_role('administrator')
      or public.has_platform_role('system_administrator')
    )
  );

revoke all on function public.has_platform_role(text) from public, anon;
revoke all on function public.assert_listing_publishable(uuid) from public, anon, authenticated;
revoke all on function public.check_listing_publishable_trigger() from public, anon, authenticated;
revoke all on function public.prevent_listing_owner_change() from public, anon, authenticated;
revoke all on function public.get_admin_platform_metrics() from public, anon;
revoke all on function public.touch_inquiry_updated_at() from public, anon, authenticated;
grant execute on function public.has_platform_role(text) to authenticated;
grant execute on function public.get_admin_platform_metrics() to authenticated;

grant usage on schema public to anon, authenticated, service_role;
grant select on public.public_listing_search, public.public_listing_photos to anon, authenticated;
revoke all on
  public.profiles,
  public.user_roles,
  public.barangays,
  public.land_types,
  public.listings,
  public.listing_private_details,
  public.listing_locations,
  public.listing_photos,
  public.listing_documents,
  public.listing_verifications,
  public.favorites,
  public.barangay_alerts,
  public.inquiries,
  public.inquiry_messages,
  public.listing_reports,
  public.moderation_actions,
  public.system_settings
from anon, authenticated;
grant select on public.barangays, public.land_types to anon;
grant delete on
  public.profiles,
  public.user_roles,
  public.barangays,
  public.land_types,
  public.listings,
  public.listing_private_details,
  public.listing_locations,
  public.listing_photos,
  public.listing_documents,
  public.listing_verifications,
  public.favorites,
  public.barangay_alerts,
  public.inquiries,
  public.inquiry_messages,
  public.listing_reports,
  public.moderation_actions,
  public.system_settings
to authenticated;

grant select (profile_uuid, user_uuid, display_name, avatar_url, created_at, updated_at)
  on public.profiles to authenticated;
grant insert (profile_uuid, user_uuid, display_name, avatar_url)
  on public.profiles to authenticated;
grant update (display_name, avatar_url) on public.profiles to authenticated;
grant select (user_role_uuid, user_uuid, role, created_at)
  on public.user_roles to authenticated;
grant select (barangay_uuid, name, slug, is_active, created_at, updated_at)
  on public.barangays to authenticated;
grant insert (barangay_uuid, name, slug, is_active)
  on public.barangays to authenticated;
grant update (name, slug, is_active) on public.barangays to authenticated;
grant select (land_type_uuid, name, slug, is_active, created_at, updated_at)
  on public.land_types to authenticated;
grant insert (land_type_uuid, name, slug, is_active)
  on public.land_types to authenticated;
grant update (name, slug, is_active) on public.land_types to authenticated;
grant select (
  listing_uuid, owner_uuid, barangay_uuid, land_type_uuid, title, transaction_type,
  price, price_period, area_value, area_unit, public_latitude, public_longitude,
  status, published_at, created_at, updated_at
) on public.listings to authenticated;
grant insert (
  listing_uuid, owner_uuid, barangay_uuid, land_type_uuid, title, transaction_type,
  price, price_period, area_value, area_unit, public_latitude, public_longitude, status
) on public.listings to authenticated;
grant update (
  barangay_uuid, land_type_uuid, title, transaction_type, price, price_period,
  area_value, area_unit, public_latitude, public_longitude, status
) on public.listings to authenticated;
grant select (
  listing_private_details_uuid, listing_uuid, description, road_access, water_source,
  has_electricity, terrain, crops_or_trees, created_at, updated_at
) on public.listing_private_details to authenticated;
grant insert (
  listing_private_details_uuid, listing_uuid, description, road_access, water_source,
  has_electricity, terrain, crops_or_trees
) on public.listing_private_details to authenticated;
grant update (
  description, road_access, water_source, has_electricity, terrain, crops_or_trees
) on public.listing_private_details to authenticated;
grant select (
  listing_location_uuid, listing_uuid, exact_latitude, exact_longitude, created_at, updated_at
) on public.listing_locations to authenticated;
grant insert (
  listing_location_uuid, listing_uuid, exact_latitude, exact_longitude
) on public.listing_locations to authenticated;
grant update (exact_latitude, exact_longitude)
  on public.listing_locations to authenticated;
grant select (
  listing_photo_uuid, listing_uuid, storage_path, caption, display_order, created_at
) on public.listing_photos to authenticated;
grant insert (
  listing_photo_uuid, listing_uuid, storage_path, caption, display_order
) on public.listing_photos to authenticated;
grant update (listing_uuid, storage_path, caption, display_order) on public.listing_photos to authenticated;
grant select (
  listing_document_uuid, listing_uuid, submitted_by_uuid, document_type, storage_path, created_at
) on public.listing_documents to authenticated;
grant insert (
  listing_document_uuid, listing_uuid, submitted_by_uuid, document_type, storage_path
) on public.listing_documents to authenticated;
grant select (
  listing_verification_uuid, listing_uuid, status, reviewed_by_uuid, reviewed_at,
  moderator_note, created_at, updated_at
) on public.listing_verifications to authenticated;
grant insert (
  listing_verification_uuid, listing_uuid, status, reviewed_by_uuid, reviewed_at, moderator_note
) on public.listing_verifications to authenticated;
grant update (status, reviewed_by_uuid, reviewed_at, moderator_note)
  on public.listing_verifications to authenticated;
grant select (favorite_uuid, user_uuid, listing_uuid, created_at)
  on public.favorites to authenticated;
grant insert (favorite_uuid, user_uuid, listing_uuid)
  on public.favorites to authenticated;
grant select (barangay_alert_uuid, user_uuid, barangay_uuid, is_enabled, created_at, updated_at)
  on public.barangay_alerts to authenticated;
grant insert (barangay_alert_uuid, user_uuid, barangay_uuid, is_enabled)
  on public.barangay_alerts to authenticated;
grant update (barangay_uuid, is_enabled) on public.barangay_alerts to authenticated;
grant select (inquiry_uuid, listing_uuid, sender_uuid, recipient_uuid, status, created_at, updated_at)
  on public.inquiries to authenticated;
grant insert (inquiry_uuid, listing_uuid, sender_uuid, recipient_uuid)
  on public.inquiries to authenticated;
grant select (inquiry_message_uuid, inquiry_uuid, sender_uuid, body, created_at)
  on public.inquiry_messages to authenticated;
grant insert (inquiry_message_uuid, inquiry_uuid, sender_uuid, body)
  on public.inquiry_messages to authenticated;
grant select (
  listing_report_uuid, listing_uuid, reporter_uuid, reason, description, status,
  reviewed_by_uuid, reviewed_at, resolution_note, created_at, updated_at
) on public.listing_reports to authenticated;
grant insert (
  listing_report_uuid, listing_uuid, reporter_uuid, reason, description
) on public.listing_reports to authenticated;
grant update (status, reviewed_by_uuid, reviewed_at, resolution_note, updated_at)
  on public.listing_reports to authenticated;
grant select (
  moderation_action_uuid, listing_uuid, listing_report_uuid, moderator_uuid, action, note, created_at
) on public.moderation_actions to authenticated;
grant insert (
  moderation_action_uuid, listing_uuid, listing_report_uuid, moderator_uuid, action, note
) on public.moderation_actions to authenticated;
grant select (
  system_setting_uuid, setting_key, setting_value, updated_by_uuid, created_at, updated_at
) on public.system_settings to authenticated;
grant insert (
  system_setting_uuid, setting_key, setting_value, updated_by_uuid
) on public.system_settings to authenticated;
grant update (setting_key, setting_value, updated_by_uuid, updated_at)
  on public.system_settings to authenticated;
grant all on
  public.profiles,
  public.user_roles,
  public.barangays,
  public.land_types,
  public.listings,
  public.listing_private_details,
  public.listing_locations,
  public.listing_photos,
  public.listing_documents,
  public.listing_verifications,
  public.favorites,
  public.barangay_alerts,
  public.inquiries,
  public.inquiry_messages,
  public.listing_reports,
  public.moderation_actions,
  public.system_settings
to service_role;
revoke update on public.inquiries from authenticated;
grant update (status) on public.inquiries to authenticated;

grant usage, select on sequence
  public.profiles_id_seq,
  public.user_roles_id_seq,
  public.barangays_id_seq,
  public.land_types_id_seq,
  public.listings_id_seq,
  public.listing_private_details_id_seq,
  public.listing_locations_id_seq,
  public.listing_photos_id_seq,
  public.listing_documents_id_seq,
  public.listing_verifications_id_seq,
  public.favorites_id_seq,
  public.barangay_alerts_id_seq,
  public.inquiries_id_seq,
  public.inquiry_messages_id_seq,
  public.listing_reports_id_seq,
  public.moderation_actions_id_seq,
  public.system_settings_id_seq
to service_role;
revoke usage, select on sequence
  public.profiles_id_seq,
  public.user_roles_id_seq,
  public.barangays_id_seq,
  public.land_types_id_seq,
  public.listings_id_seq,
  public.listing_private_details_id_seq,
  public.listing_locations_id_seq,
  public.listing_photos_id_seq,
  public.listing_documents_id_seq,
  public.listing_verifications_id_seq,
  public.favorites_id_seq,
  public.barangay_alerts_id_seq,
  public.inquiries_id_seq,
  public.inquiry_messages_id_seq,
  public.listing_reports_id_seq,
  public.moderation_actions_id_seq,
  public.system_settings_id_seq
from authenticated;
