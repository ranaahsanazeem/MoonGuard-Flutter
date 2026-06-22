# Usage: .\run_with_env.ps1 -d chrome
#        .\run_with_env.ps1 -d <android_device_id>
# Requires env.json (copy from env.json.example) in this folder.
param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$Remaining
)
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
if (-not (Test-Path "env.json")) {
  Write-Error "Missing env.json. Copy env.json.example to env.json and paste your Supabase anon key."
  exit 1
}
$jsonPath = (Resolve-Path "env.json").Path
$cmd = @("run")
if ($null -ne $Remaining -and $Remaining.Count -gt 0) {
  $cmd += $Remaining
}
$cmd += "--dart-define-from-file=$jsonPath"
& flutter @cmd
