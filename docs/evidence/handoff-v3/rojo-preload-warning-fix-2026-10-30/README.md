# Rojo asset-type warning fix and Studio retest

The `rbxassetid://203785492` asset-type warning is resolved in a fresh local Studio session tested through **Roblox Studio MCP** on 30 October 2026. Edit startup and Play output were empty, including after the server regression suite, client setup, UI checks and a complete live Song preview. Game scripts and automatic character loading were enabled throughout the final run.

## Cause and correction

The installed Rojo 7.7.0 plugin included its notification sound in a table of bare asset strings passed to `ContentProvider:PreloadAsync`. Roblox attempted to fetch it as an image. The asset itself is valid audio. This matches the [upstream report](https://github.com/rojo-rbx/rojo/issues/1342) and [proposed upstream correction](https://github.com/rojo-rbx/rojo/pull/1344).

The local compatibility module passes sounds as temporary `Sound` instances with `SoundId` set, retains existing image strings, destroys temporary sounds after success or failure, and preserves propagation of preload failures. It changes no game audio bindings or source files. Rojo remains pinned to 7.7.0.

The first local model rebuild inadvertently renamed the plugin root to `RojoManagedPlugin`. MCP caught the resulting `FindFirstAncestor("Rojo")` startup error before acceptance. The patcher now preserves the required `Rojo` root, restricts input to the checksum-identified original plugin, and verifies all properties and descendants after binary round-trip. The final fresh session had neither that startup error nor the original warning.

## Final evidence

- Original preloader fixture failed: the sound was supplied as a string.
- Both patched preloader cases passed: typed audio, unchanged images, cleanup after success/failure, and preserved failure behavior. These fixtures record requests in memory and fetch no assets.
- **9/9 Studio Server regression checks passed**, covering all four banks/64 addresses, independent settings, delayed recording, more than four sequences, variations/history, arrangement references/tempo/repeats, finite playback/seeking/resume, save/finish boundaries, immutable fixtures, conversion and legacy migration.
- **3/3 Studio Client UI checks passed**: Song position/pause, arrangement order and selected-object fields.
- The actual client/server command path created five sequences and saved a session-only Song draft. Live Song preview showed Intro, Main repeat 1 and Main repeat 2, then stopped after **6.186 seconds** from its scheduled start: 4 seconds of musical arrangement and 2 seconds of tail. This measures state/transport timing.
- MCP console output was empty at fresh Edit startup, after regression/client checks and after live playback.
- Pinned StyLua and Selene passed on the compatibility module and fixture: 0 errors, 0 warnings, 0 parse errors.

Machine-readable results are in `results.json`; plugin checksums and backup information are in `plugin-receipt.json`. Native MCP capture: `mpc-v3-asset-type-warning-fixed`.

Final Studio instance: `f32ad24c-4654-42d3-acf8-d6371d0ed69f`, `NeedleQuay-MPC-v3-AssetTypeFixed.rbxlx`, left open in Play. The local test place is byte-identical to the existing MPC v3 build (SHA-256 `b173519a56fd6ac6ea076df14d0b80b23740dd66416dce621d333f88e0c3b677`). Earlier Studio windows were preserved.

## Reapplying or restoring

Installed local plugin: `C:/Users/slavd/AppData/Local/Roblox/Plugins/RojoManagedPlugin.rbxm`.

Original plugin backup: `C:/Users/slavd/.codex/backups/BeatMaka/rojo-preload-20261030-root-preserved/RojoManagedPlugin.rbxm` (SHA-256 `de8cac278030b37f7d4f7efb931fe68087be0a851a31c33312f592b802a23714`). Final patched SHA-256: `15418f42d9d3f8d5ad805384e0696df5586ebf8ff7ef4f77c578ccb8756443c3`.

`tools/patch_rojo_audio_preload.py` uses the repository's pinned Rojo and Python standard library. Supply `--plugin` and a new `--backup-dir`; it builds and verifies by default. `--install` explicitly replaces the local plugin after verification. It accepts only the known original binary, so running it against an updated or already patched plugin refuses changes. The replacement source is `tools/compat/rojo-preloadAssets.luau`; the repeatable fixture is `tools/qa/rojo_preload_probe.luau`.

To restore, copy the preserved original plugin over the installed file. Newly opened Studio sessions load the file from disk. Reinstalling/updating the Rojo plugin can overwrite this local compatibility fix; reassess the current upstream version before reapplying.

The written bank map and pending musical audio status are unchanged. No uploads, publishing, paid generation, cloud writes, commits or pushes occurred in this fix. The game build/package does not need rebuilding for this developer-plugin-only correction.
