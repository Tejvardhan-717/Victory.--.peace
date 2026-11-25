[README-RTX4050.md](https://github.com/user-attachments/files/35421386/README-RTX4050.md)
# VIctory (rx9070 fork) on an RTX 4050 laptop: what works and what doesn't

These are changes on top of [jmehru/victory-amd-rx9070](https://github.com/jmehru/victory-amd-rx9070) (branch `rx9070`,
commit `aae8d6c`), tested on a single machine with the game's Xbox Series files:

| Part | This machine |
|---|---|
| GPU | NVIDIA RTX 4050 Laptop, 6 GB (DXGI budget 5,152 MB) |
| CPU | Intel i5-13420H |
| RAM | 16 GB |
| OS | Windows 11 |

All numbers below were measured in 90-minute runs on 2026-11-25. Legend: ✅ works · ⚠️ partly / with a trade-off · ❌ not working.

## Summary

| Area | Before our changes | Now |
|---|---|---|
| Starting the game | GPU hang in Series S, watchdog crash at ~2 min | Boots, menus and loading screens at 30 fps ✅ |
| Stability | Game stopped after 7–10 min (object pools ran empty) | 15-minute runs without a crash ✅ |
| World frame rate | ~1 fps (Series X) | ~3–3.5 fps (median 270–320 ms per frame) ⚠️ |
| GPU use | — | ~56–60% busy; it waits for the CPU ❌ |
| Faces and skin | Black faces, speckled skin and clothes | Lit, clean ✅ |
| Sky | Blue squares | Clean ✅ |
| Textures | ~4,000–17,000 waiting (black) | ~800–1,600 waiting; backlog in long sessions ⚠️ |
| Ray-traced light and shadows | Read garbage | Turned off cleanly (rays miss) ⚠️ |
| Sound | — | Works ✅ |

## What we changed

| Change | Where | Setting | Result |
|---|---|---|---|
| Pause the game's stuck-thread watchdog | `apps/victory/src/run.rs` (`hold`) | `VICTORY_HOLD=71B6330:1` | No crash at ~133 s ✅ |
| Enlarge two game object pools to 65,536 entries (code patched in memory only if bytes match) | `run.rs` (`patch`), `victory-loader` (`patch_code`) | `VICTORY_PATCH=5AD8E60:…,5ABB240:…` | No debug-break at +0x5149aec / +0x1fa88e4; 15-min run ✅ |
| AMD-only CPU instructions (MONITORX/MWAITX) patched once instead of trapped every time | `victory-loader/src/console_insn.rs` | always | ~8× fewer emulated instructions ✅ (no frame-time change) |
| Lower-resolution texture copies (skip 1 mip from 512², 2 from 2048²) | `victory-gpu/src/resource.rs`, `texture.rs`, `descriptor/host.rs` | `VICTORY_TEXTURES=reduced` | More textures fit in 6 GB ⚠️ softer detail |
| Texture room up to 96% of the card budget | `resource.rs` (`room_percent`) | `VICTORY_TEXTURE_ROOM_PCT=96` | Waiting textures 4,000–5,000 → 1,000–1,600 ✅ |
| 64-lane visibility pass translated for 32-lane waves | `victory-shader/src/emit/mod.rs` (`wide_named`), `shader_cache.rs` | `VICTORY_WAVE_WIDE_FOR=CS_Visibility_` | NVIDIA no longer refuses it ✅ |
| Every ray-traced ray misses | `victory-shader/src/emit/intersect.rs` | `VICTORY_RT_MISS=1` | Faces lit, no speckle or blue squares, same speed ✅ (no RT shadows) |
| Constants copied on the GPU instead of filled on the CPU | `victory-gpu/src/host.rs`, `draw.rs` | `VICTORY_GPU_CONSTANTS=1` (off) | Debug layer clean, but no gain and blue squares came back once ❌ (left off) |
| Frame-time percentiles, texture-pass timing, fill-wait diagnostics | `host.rs`, `draw.rs` | logs | Measuring ✅ |

Also used from the existing code: `VICTORY_RELAY=2` (CPU/GPU overlap, 450–560 → 367–415 ms),
`VICTORY_CARD_BUFFERS_MIN_MB=1` (big buffer copies on the card, → ~300 ms), `VICTORY_WINDOW_KB=256` +
`VICTORY_WINDOW_TAILS=1` (avoided GPU hangs), `--console series-s` (renders ~1280x720 internally).

## Frame time, step by step

| Setup | Median frame time | fps |
|---|---|---|
| Series X profile | 1,200–2,000 ms | ~0.5–1 |
| Series S profile | 450–560 ms | ~2 |
| + relay | 367–415 ms | ~2.5 |
| + buffer copies on the card | 292–308 ms | ~3.3 |
| + ray miss (current) | 270–320 ms | ~3–3.5 |

## Shaders

| | Count |
|---|---|
| Translated and cached so far | 21,076 (733 MB) + 243 MB of built pipelines ✅ |
| Do not translate (run ~1×/frame each) | 4, incl. `CS_ShadowRenderTiledCascadesAlpha` (f133e35e) ❌ |
| Refused by NVIDIA (need 64-lane waves, groups > 64) | `CS_DefragHeap_ComputeRelocations`, `CS_AlphTransmissionPrefilterMip` ❌ |
| Translates with the wave workaround but draws orange squares | `CS_Tiling_Generate_Opaque` ⚠️ (off) |
| Ray-tracing hit shading / structure builder (left out per frame) | ~390 / ~240 ❌ |

## What is left

| Problem | What we know | Status |
|---|---|---|
| Not playable (~3 fps) | Each frame the game makes ~27,000–31,000 draw calls; recording them costs 300–850 ms of CPU over 5 threads (~32 µs per call), plus ~340 ms kernel time and ~36,000 page faults. The GPU's own work is 70–125 ms. | ❌ next step: profile the per-call cost |
| GPU under-used / fluctuating | The GPU idles while the CPU records and copies (~480 MB of game memory checked per frame). | ❌ |
| Textures late in long sessions | Card fills (other apps shrink the budget); ~6,800 textures waited, oldest 414 frames, in a 25-min session. 7-min runs stay at 4.2/5.15 GB. | ⚠️ close other apps |
| Black blocky patches on some clothes | Seen with and without ray miss | ❌ not diagnosed |
| Ray-traced shadows and reflections | Structure builder does not run on this card | ❌ |
| Low-detail NPCs, glowing eyes | Seen in cutscenes | ❌ not diagnosed |
| RAM | Game holds ~14 GB; free RAM falls under 1 GB | ⚠️ large page file helps |

## How to run

```powershell
powershell -ExecutionPolicy Bypass -File play-gta6-rx9070.ps1
```

Or use the packaged build `dist\VIctory-GTA6-build-v6.zip` (`PLAY.bat`; options `-SeriesX`, `-FullTextures`, `-RayShadows`).
The first start translates shaders and takes several extra minutes on loading screens.

No game files are in this repository. GPL-3.0-or-later, like the base.
