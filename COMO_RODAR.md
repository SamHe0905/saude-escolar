# Controle de Atestados — passo a passo

App Flutter Web (PWA) com Supabase para a direção/coordenação registrar atestados dos professores.

## 1. Criar projeto Supabase

1. Acesse https://supabase.com → New project.
2. Em **SQL Editor**, cole o conteúdo de `supabase_setup.sql` e execute.
3. Em **Storage**, crie um bucket chamado `atestados` e marque como **Private**. Depois volte ao SQL Editor e rode novamente a parte das policies de storage do `supabase_setup.sql` (já está no script).
4. Em **Authentication → Providers**, deixe Email ativo. Em **Users**, crie manualmente as contas da direção e da coordenação (botão "Add user" → "Create new user", marque "Auto Confirm User").

## 2. Conectar o app ao Supabase

1. Em **Project Settings → API**, copie:
   - `Project URL`
   - `anon public` key
2. Abra `lib/config.dart` e cole nos dois lugares.

## 3. Rodar local

```
cd C:\dev\atestados_professores
flutter run -d chrome
```

## 4. Build de produção (PWA)

```
flutter build web --release
```
Gera `build/web`. É só hospedar essa pasta (Vercel, Netlify, etc.).

### Deploy Vercel rápido

```
cd build/web
vercel --prod
```

## Como funciona

- **Login:** só quem você cadastrou em Authentication entra.
- **Lista:** mostra todos os atestados, com chip "Ativo / Futuro / Encerrado" baseado na data de hoje, e busca por professor/substituto.
- **Novo atestado:** professor, substituto, datas de início/fim, observações e anexo (PDF/JPG/PNG vai pro Storage privado).
- **Detalhe:** abre o anexo via URL assinada (10 min) e permite excluir.

## PWA

O `manifest.json` já está configurado. No Chrome, depois de servir o build, aparece "Instalar app" — vira ícone na área de trabalho/celular.
