# Pinned localhost URL so Supabase redirect list stays stable: add
#   http://localhost:8080
# to Supabase → Authentication → URL Configuration → Redirect URLs.
param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$Remaining
)
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
if (-not (Test-Path "env.json")) {
  Write-Error "Copy env.json.example to env.json and set SUPABASE_ANON_KEY."
  exit 1
}
$jsonPath = (Resolve-Path "env.json").Path
$cmd = @(
  "run", "-d", "web-server",
  "--web-hostname=localhost", "--web-port=8080",
  "--dart-define-from-file=$jsonPath"
)
if ($Remaining -and $Remaining.Count -gt 0) {
  $cmd += $Remaining
}
& flutter @cmd
