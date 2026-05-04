$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$serverPath = Join-Path $root "stream_token_server"

Start-Process powershell -ArgumentList "-NoExit", "-Command", "Set-Location -Path '$serverPath'; npm start"

Set-Location -Path $root
flutter run -d emulator-5554 --dart-define=STREAM_API_KEY=j5tkkdvknj3p --dart-define=STREAM_TOKEN_SERVER_URL=http://10.0.2.2:8787
