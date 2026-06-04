# Deploy do "Saúde Escolar" para produção na Vercel.
# Uso:  .\deploy.ps1
#
# Por que prebuilt? O link da Vercel fica na raiz do projeto, então um
# `vercel deploy` normal subiria o repositório inteiro (sem index.html na
# raiz) e daria 404. Aqui a gente compila, monta a saída estática no
# formato Build Output API e sobe com --prebuilt.
#
# OBS: NÃO usar `$ErrorActionPreference = "Stop"` — o wrapper do vercel
# escreve uma linha em stderr que, com Stop, aborta o deploy no meio.

$root = $PSScriptRoot
Set-Location $root

Write-Host "1/3  Compilando Flutter Web (release)..." -ForegroundColor Cyan
flutter build web --release
if ($LASTEXITCODE -ne 0) { Write-Host "Build falhou. Abortando." -ForegroundColor Red; exit 1 }

Write-Host "2/3  Montando saida prebuilt (.vercel/output)..." -ForegroundColor Cyan
$out = "$root\.vercel\output"
if (Test-Path $out) { Remove-Item $out -Recurse -Force }
New-Item -ItemType Directory -Force "$out\static" | Out-Null
Get-ChildItem "$root\build\web" -Force | Where-Object { $_.Name -ne '.vercel' } | ForEach-Object {
  Copy-Item $_.FullName "$out\static" -Recurse -Force
}
# Serve arquivos estaticos; qualquer rota desconhecida cai no index.html (SPA).
[System.IO.File]::WriteAllText(
  "$out\config.json",
  '{"version":3,"routes":[{"handle":"filesystem"},{"src":"/(.*)","dest":"/index.html"}]}'
)

Write-Host "3/3  Publicando na Vercel..." -ForegroundColor Cyan
vercel deploy --prebuilt --prod --yes

Write-Host "`nPronto! https://saude-escolar-sigma.vercel.app" -ForegroundColor Green
