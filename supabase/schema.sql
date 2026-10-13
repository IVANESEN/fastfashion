-- ============================================================================
-- FastFashion · esquema de Supabase
--
-- Cómo usarlo:
--   1. Crea un proyecto en https://supabase.com
--   2. SQL Editor → pega y ejecuta este archivo completo.
--   3. Copia la URL y la anon key (Project Settings → API) y compila con:
--        --dart-define=BACKEND=supabase
--        --dart-define=SUPABASE_URL=https://xxxx.supabase.co
--        --dart-define=SUPABASE_ANON_KEY=...
--
-- Las columnas coinciden 1:1 con las filas que produce la app
-- (ver lib/domain/entities/*.dart → toRow()).
-- ============================================================================

-- ---------- Perfiles --------------------------------------------------------
create table if not exists public.profiles (
  id           uuid primary key references auth.users (id) on delete cascade,
  email        text not null default '',
  display_name text not null default '',
  city         text not null default 'San Salvador',
  created_at   timestamptz not null default now()
);

-- Crea el perfil automáticamente cuando alguien se registra.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email, display_name)
  values (
    new.id,
    coalesce(new.email, ''),
    coalesce(new.raw_user_meta_data ->> 'display_name', split_part(coalesce(new.email, ''), '@', 1))
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------- Prendas ---------------------------------------------------------
create table if not exists public.garments (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users (id) on delete cascade,
  name         text not null,
  category     text not null check (category in ('top', 'bottom', 'shoes', 'jacket')),
  style        text not null check (style in ('casual', 'formal', 'sporty')),
  color_name   text not null,
  color_value  bigint not null,
  image_url    text,
  wear_count   integer not null default 0,
  last_worn_at timestamptz,
  created_at   timestamptz not null default now()
);
create index if not exists garments_user_idx on public.garments (user_id, created_at desc);

-- ---------- Outfits elegidos (uno por día y usuario) -------------------------
create table if not exists public.outfits (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users (id) on delete cascade,
  outfit_date date not null,
  top_id      uuid not null references public.garments (id) on delete cascade,
  bottom_id   uuid not null references public.garments (id) on delete cascade,
  shoes_id    uuid references public.garments (id) on delete set null,
  jacket_id   uuid references public.garments (id) on delete set null,
  title       text not null default 'Outfit',
  occasion    text not null default 'classes',
  style       text not null default 'casual',
  created_at  timestamptz not null default now(),
  unique (user_id, outfit_date)
);

-- ---------- Recordatorios (una fila por usuario) ----------------------------
create table if not exists public.reminder_settings (
  user_id        uuid primary key references auth.users (id) on delete cascade,
  hour           smallint not null default 6 check (hour between 0 and 23),
  minute         smallint not null default 30 check (minute between 0 and 59),
  days           jsonb not null default '[true,true,true,true,true,false,false]'::jsonb,
  daily_outfit   boolean not null default true,
  weather_change boolean not null default true,
  smart_alerts   boolean not null default false
);

-- ---------- Seguridad a nivel de fila (RLS) ---------------------------------
alter table public.profiles          enable row level security;
alter table public.garments          enable row level security;
alter table public.outfits           enable row level security;
alter table public.reminder_settings enable row level security;

drop policy if exists "profiles: dueño"          on public.profiles;
drop policy if exists "garments: dueño"          on public.garments;
drop policy if exists "outfits: dueño"           on public.outfits;
drop policy if exists "reminder_settings: dueño" on public.reminder_settings;

create policy "profiles: dueño" on public.profiles
  for all using (auth.uid() = id) with check (auth.uid() = id);

create policy "garments: dueño" on public.garments
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "outfits: dueño" on public.outfits
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "reminder_settings: dueño" on public.reminder_settings
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ---------- Storage: fotos de prendas ----------------------------------------
-- Bucket público de lectura (las URLs se usan con Image.network);
-- cada usuario solo escribe dentro de su carpeta <user_id>/...
insert into storage.buckets (id, name, public)
values ('garments', 'garments', true)
on conflict (id) do nothing;

drop policy if exists "garments storage: lectura pública" on storage.objects;
drop policy if exists "garments storage: subir propio"    on storage.objects;
drop policy if exists "garments storage: editar propio"   on storage.objects;
drop policy if exists "garments storage: borrar propio"   on storage.objects;

create policy "garments storage: lectura pública" on storage.objects
  for select using (bucket_id = 'garments');

create policy "garments storage: subir propio" on storage.objects
  for insert with check (
    bucket_id = 'garments' and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "garments storage: editar propio" on storage.objects
  for update using (
    bucket_id = 'garments' and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "garments storage: borrar propio" on storage.objects
  for delete using (
    bucket_id = 'garments' and (storage.foldername(name))[1] = auth.uid()::text
  );
