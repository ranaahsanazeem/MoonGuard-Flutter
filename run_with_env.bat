@echo off
setlocal
cd /d "%~dp0"
if not exist "env.json" (
  echo Missing env.json. Copy env.json.example to env.json and add your Supabase anon key.
  exit /b 1
)
set "JSONFILE=%~dp0env.json"
flutter run %* --dart-define-from-file="%JSONFILE%"
