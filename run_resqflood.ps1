
$envFile = Join-Path $PSScriptRoot ".env.json"

if (-not (Test-Path $envFile)) {
    throw ".env.json not found!"
}

$config = Get-Content $envFile -Raw | ConvertFrom-Json

$url = $config.SUPABASE_URL
$key = $config.SUPABASE_ANON_KEY

if ([string]::IsNullOrWhiteSpace($url) -or
    [string]::IsNullOrWhiteSpace($key)) {
    throw "Supabase URL or key is missing!"
}

flutter run `
  "--dart-define=SUPABASE_URL=$url" `
  "--dart-define=SUPABASE_ANON_KEY=$key"
