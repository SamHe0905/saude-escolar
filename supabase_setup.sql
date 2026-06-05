-- =====================================================================
-- Saúde Escolar — setup completo do banco (Supabase)
-- =====================================================================
-- Como usar:
--   1) SQL Editor > New query > cole tudo > Run.
--   2) Storage > New bucket > nome "atestados" > Private.
--   3) Rode de novo a seção STORAGE abaixo (após criar o bucket).
--   4) Authentication > Providers > Email: ligado, "Confirm email" desligado.
-- =====================================================================

-- ---------- Tabelas ----------
create table if not exists public.professores (
  id         uuid primary key default gen_random_uuid(),
  nome       text not null unique,
  area       text not null,
  criado_em  timestamptz not null default now()
);

create table if not exists public.substitutos (
  id         uuid primary key default gen_random_uuid(),
  nome       text not null unique,
  area       text not null,
  criado_em  timestamptz not null default now()
);

create table if not exists public.atestados (
  id            uuid primary key default gen_random_uuid(),
  professor_id  uuid not null references public.professores(id) on delete restrict,
  substituto_id uuid references public.substitutos(id) on delete set null,
  data_inicio   date not null,
  data_fim      date not null,
  turno         text[] not null default '{}',   -- múltiplos: manha/tarde/noite/integral
  observacoes   text,
  arquivo_path  text,
  criado_por    text,
  criado_em     timestamptz not null default now()
);

-- ---------- RLS (qualquer usuário autenticado: direção + coordenação) ----------
alter table public.professores  enable row level security;
alter table public.substitutos  enable row level security;
alter table public.atestados    enable row level security;

drop policy if exists prof_auth_all  on public.professores;
drop policy if exists subs_auth_all  on public.substitutos;
drop policy if exists atest_auth_all on public.atestados;

create policy prof_auth_all  on public.professores
  for all to authenticated using (true) with check (true);
create policy subs_auth_all  on public.substitutos
  for all to authenticated using (true) with check (true);
create policy atest_auth_all on public.atestados
  for all to authenticated using (true) with check (true);

-- ---------- STORAGE (rode após criar o bucket privado "atestados") ----------
drop policy if exists atestados_storage_all on storage.objects;
create policy atestados_storage_all on storage.objects
  for all to authenticated
  using (bucket_id = 'atestados') with check (bucket_id = 'atestados');
