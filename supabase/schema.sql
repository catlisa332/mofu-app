-- MOFU データベーススキーマ
-- Supabase SQL Editorで実行してください

-- ユーザー設定
create table if not exists user_preferences (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null unique,
  favorite_animals text[] default '{}',
  avoid_tags text[] default '{}',
  preferred_moods text[] default '{}',
  is_tired_mode boolean default false,
  is_night_mode boolean default false,
  show_calm_score boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- お気に入り
create table if not exists favorites (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  post_id text not null,
  post_url text not null,
  thumbnail_url text not null,
  animal_type text,
  tags text[] default '{}',
  calm_score float,
  created_at timestamptz default now(),
  unique(user_id, post_id)
);

-- NGリスト（しんどい）
create table if not exists dislikes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  post_id text not null,
  tags text[] default '{}',
  created_at timestamptz default now(),
  unique(user_id, post_id)
);

-- 視聴ログ（学習用）
create table if not exists watch_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  post_id text not null,
  watch_seconds int default 0,
  did_favorite boolean default false,
  did_dislike boolean default false,
  created_at timestamptz default now()
);

-- RLS (Row Level Security) 設定
alter table user_preferences enable row level security;
alter table favorites enable row level security;
alter table dislikes enable row level security;
alter table watch_logs enable row level security;

-- ポリシー: 自分のデータのみアクセス可能
create policy "own data only" on user_preferences
  for all using (auth.uid() = user_id);

create policy "own data only" on favorites
  for all using (auth.uid() = user_id);

create policy "own data only" on dislikes
  for all using (auth.uid() = user_id);

create policy "own data only" on watch_logs
  for all using (auth.uid() = user_id);
