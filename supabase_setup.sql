-- Rode este SQL no Supabase: SQL Editor > New query.
-- Depois, em Storage, crie um bucket PRIVADO chamado "atestados".

create table if not exists public.atestados (
  id           uuid primary key default gen_random_uuid(),
  professor    text not null,
  substituto   text,
  data_inicio  date not null,
  data_fim     date not null,
  observacoes  text,
  arquivo_path text,
  criado_por   text,
  criado_em    timestamptz not null default now()
);

alter table public.atestados enable row level security;

-- Qualquer usuário autenticado pode ler/escrever (direção + coordenação).
create policy "auth_select"
  on public.atestados for select
  to authenticated using (true);

create policy "auth_insert"
  on public.atestados for insert
  to authenticated with check (true);

create policy "auth_update"
  on public.atestados for update
  to authenticated using (true) with check (true);

create policy "auth_delete"
  on public.atestados for delete
  to authenticated using (true);

-- Policies do bucket "atestados" (Storage).
-- Rode depois de criar o bucket privado "atestados".
create policy "atestados_storage_select"
  on storage.objects for select
  to authenticated using (bucket_id = 'atestados');

create policy "atestados_storage_insert"
  on storage.objects for insert
  to authenticated with check (bucket_id = 'atestados');

create policy "atestados_storage_delete"
  on storage.objects for delete
  to authenticated using (bucket_id = 'atestados');
