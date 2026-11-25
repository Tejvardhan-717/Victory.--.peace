# Runs the game with this VIctory build and the settings tested on 2026-11-25.
#   powershell -ExecutionPolicy Bypass -File play.ps1 [-Game "<path>\game_scarlett_master.exe"] [-SeriesX] [-FullTextures] [-RayShadows]
# Without -Game it asks once for the path and remembers it in game-path.txt.
param(
    [string]$Game = "",
    [switch]$SeriesX,          # Series X profile instead of Series S (slower, needs more GPU memory)
    [switch]$FullTextures,     # full texture detail (on 6 GB cards some textures then stay black)
    [switch]$RayShadows        # let the game trace rays (black faces, speckle and blue squares on this build)
)
$here = $PSScriptRoot
$saved = Join-Path $here "game-path.txt"
if (-not $Game -and (Test-Path $saved)) { $Game = (Get-Content $saved -Raw).Trim() }
if (-not $Game) {
    Write-Host "Path to the game's executable (the Xbox Series build), for example D:\gta5\game_scarlett_master.exe"
    $Game = (Read-Host "Game exe").Trim('"', ' ')
}
if (-not (Test-Path $Game -PathType Leaf)) {
    Write-Host "Not found: $Game" -ForegroundColor Red
    Write-Host "Point it at game_scarlett_master.exe inside your game folder." -ForegroundColor Red
    if (Test-Path $saved) { Remove-Item $saved }
    exit 1
}
Set-Content -Path $saved -Value $Game -Encoding utf8

$rt = Join-Path $here "runtime"
New-Item -ItemType Directory -Force "$rt\cache", "$rt\data" | Out-Null
$env:VICTORY_CACHE_DIR    = "$rt\cache"
$env:VICTORY_DATA_DIR     = "$rt\data"
$env:VICTORY_HOLD         = "71B6330:1"
$env:VICTORY_PATCH        = "5AD8E60:E8DB605FFF:B800000100,5ABB240:E8FB3C61FF:B800000100"
$env:VICTORY_DISPLAY_MODE = "1920x1080"
$env:VICTORY_WINDOW_KB    = "256"
$env:VICTORY_WINDOW_TAILS = "1"
$env:VICTORY_RELAY        = "2"
$env:VICTORY_CARD_BUFFERS_MIN_MB = "1"
$env:VICTORY_TEXTURE_ROOM_PCT    = "96"
$env:VICTORY_WAVE_WIDE_FOR       = "CS_Visibility_"
if (-not $FullTextures) { $env:VICTORY_TEXTURES = "reduced" }
if (-not $RayShadows) { $env:VICTORY_RT_MISS = "1" }   # every ray misses: lit faces, no speckle
$console = if ($SeriesX) { "series-x" } else { "series-s" }

Write-Host "Starting $Game ($console). The first start compiles shaders: expect several extra minutes on loading screens."
Write-Host "Log: $rt\last-run.log"
$exe = Join-Path $here "victory.exe"
cmd /c "`"$exe`" run `"$Game`" --execute --console $console > `"$rt\last-run.log`" 2>&1"
$code = $LASTEXITCODE
Write-Host "Game exited (code $code)."
if ($code -ne 0) {
    Write-Host "Last lines of the log:" -ForegroundColor Yellow
    Get-Content "$rt\last-run.log" -Tail 15
}
