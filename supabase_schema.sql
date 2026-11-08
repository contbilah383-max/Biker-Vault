-- انسخ هاد الكود كامل فـ Supabase > SQL Editor > Run

create table public.bikes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  brand text not null,
  model text not null,
  year int,
  mileage int default 0,
  created_at timestamptz default now()
);

create table public.reminders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  bike_id uuid not null references public.bikes(id) on delete cascade,
  type text not null check (type in ('oil','insurance','inspection','vignette','other')),
  due_date date not null,
  note text,
  done boolean default false,
  created_at timestamptz default now()
);

-- الأمان: كل مستخدم كيشوف غير الداتا ديالو
alter table public.bikes enable row level security;
alter table public.reminders enable row level security;

create policy "own bikes" on public.bikes
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "own reminders" on public.reminders
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
