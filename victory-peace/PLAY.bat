@echo off
rem Double-click to play. Asks once for the game's exe and remembers it (game-path.txt).
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0play.ps1" %*
pause
