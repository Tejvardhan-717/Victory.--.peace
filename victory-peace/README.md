# victory-peace

An experimental VIctory build for running the Xbox Series X|S version of **Grand Theft Auto VI** on Windows using a game copy supplied by the user.

> **Status: experimental and not yet playable smoothly.** This repository is a community build, is not affiliated with Rockstar Games, and includes no game files.

## Shader translation progress

The current development estimate is that **about 22,000 of roughly 26,000 shader programs have been translated** (approximately 85%). The remaining programs and rendering paths are incomplete or unverified. This count does not mean every translated shader renders correctly on every GPU.

## Current state and known issues

- The game has reached the opening cutscene and prologue on an RTX 4050 Laptop GPU.
- User-reported captures show roughly 1 FPS in some scenes, with frame times around 0.8–2 seconds.
- Some textures and objects appear black, missing, low-detail, or late; facial expression details can be absent.
- Ray-traced lighting and reflections are not working correctly in this build. Its default launcher setting makes ray queries miss to avoid some severe rendering artifacts, so shadows/reflections are absent.
- Some shaders, GPU formats, and resource paths remain unsupported. Device removal is still possible.
- This is an experimentation build, not a claim of complete compatibility or smooth gameplay.

Earlier test notes packaged with this build recorded about 3–3.4 FPS in the 3D world using the Series S profile on an RTX 4050 Laptop with 16 GB RAM. Those results are historical measurements and are not a benchmark guarantee for every run or this exact package.

## Requirements

- Windows 10/11 x64 and a CPU with AVX2.
- Direct3D 12 GPU supporting Shader Model 6.6 and mesh shaders. The included launcher settings were tested on an RTX 4050 Laptop GPU.
- At least 16 GB of system RAM; the game can require roughly 15–20 GB of system commit. A suitable Windows paging file may be needed.
- A legally obtained, unpacked Xbox Series game folder containing `game_scarlett_master.exe`. The repository does not provide, decrypt, or unpack the game.

## Run

Double-click `PLAY.bat`, or launch from PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\play.ps1 -Game "D:\path\to\game_scarlett_master.exe"
```

The default launcher uses the Series S profile, reduced texture copies, relay mode, and a 1920×1080 display mode; the Series S profile targets approximately 1280×720 internal rendering. Add `-SeriesX` for the higher-memory Series X profile or `-FullTextures` to disable reduced texture copies. The first run can spend several minutes translating and compiling shaders; later runs reuse `runtime\cache`.

`play.ps1` stores the selected game path locally in `game-path.txt` and writes logs/cache/save data under `runtime\`. Those paths are excluded from Git by `.gitignore`.

Controls: an XInput controller is recommended. The keyboard can act as a controller while the game window is focused; Enter maps to A.

## Build contents and source

This repository contains the v6 `victory.exe`, launcher scripts, license, base revision reference, and the source patch applied on top of the base. It is a packaged build, not a complete checkout of the upstream source tree.

- Base: [`jmehru/victory-amd-rx9070`](https://github.com/jmehru/victory-amd-rx9070), branch `rx9070`, commit `aae8d6c4819de26caf2baf57bba803836c308675`.
- Changes on top of that base: [`source/changes-on-top-of-rx9070-aae8d6c.patch`](source/changes-on-top-of-rx9070-aae8d6c.patch).
- License: GPL-3.0-or-later; see [`LICENSE.txt`](LICENSE.txt).

## About the name

`victory-peace` is the repository name for this experimental build. It does not imply endorsement by the game publisher or that the game is already fully playable.
