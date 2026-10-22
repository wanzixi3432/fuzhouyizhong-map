-- 福州一中回忆地图：匿名文字与照片存储
-- 在 Supabase Dashboard -> SQL Editor 中一次性运行。

create table if not exists public.fuzhou_one_memories (
  id text primary key,
  place_id text not null,
  text text not null check (char_length(text) between 2 and 1000),
  images jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);

-- 兼容此前登录版创建的旧表。
alter table public.fuzhou_one_memories
  add column if not exists user_id uuid;
alter table public.fuzhou_one_memories
  add column if not exists author text;
alter table public.fuzhou_one_memories
  alter column user_id drop not null;
alter table public.fuzhou_one_memories
  alter column author drop not null;

create index if not exists fuzhou_one_memories_place_created_idx
  on public.fuzhou_one_memories (place_id, created_at desc);

alter table public.fuzhou_one_memories enable row level security;

drop policy if exists "authenticated read fuzhou memories" on public.fuzhou_one_memories;
drop policy if exists "authenticated add own fuzhou memory" on public.fuzhou_one_memories;
drop policy if exists "authenticated update own fuzhou memory" on public.fuzhou_one_memories;
drop policy if exists "authenticated delete own fuzhou memory" on public.fuzhou_one_memories;
drop policy if exists "anonymous read fuzhou memories" on public.fuzhou_one_memories;
drop policy if exists "anonymous add fuzhou memory" on public.fuzhou_one_memories;

create policy "anonymous read fuzhou memories"
  on public.fuzhou_one_memories for select
  to anon, authenticated
  using (true);

create policy "anonymous add fuzhou memory"
  on public.fuzhou_one_memories for insert
  to anon, authenticated
  with check (user_id is null);

insert into storage.buckets (id, name, public)
values ('fuzhou-memory-images', 'fuzhou-memory-images', true)
on conflict (id) do update set public = true;

drop policy if exists "authenticated fuzhou image reads" on storage.objects;
drop policy if exists "authenticated fuzhou image uploads" on storage.objects;
drop policy if exists "owner fuzhou image updates" on storage.objects;
drop policy if exists "owner fuzhou image deletes" on storage.objects;
drop policy if exists "anonymous fuzhou image reads" on storage.objects;
drop policy if exists "anonymous fuzhou image uploads" on storage.objects;

create policy "anonymous fuzhou image reads"
  on storage.objects for select
  to anon, authenticated
  using (bucket_id = 'fuzhou-memory-images');

create policy "anonymous fuzhou image uploads"
  on storage.objects for insert
  to anon, authenticated
  with check (
    bucket_id = 'fuzhou-memory-images'
    and (storage.foldername(name))[1] = 'anonymous'
  );
