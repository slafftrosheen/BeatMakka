# Audio/content readiness continuation

23 October 2026. Based on `main` at `dc898d887e5f147d95e728040a20a035a1e24c08`.

This pass continues the existing first-zone acceptance work. It does not restart B00,
generate more props, overwrite previous evidence, upload audio or meshes, publish the
place, or promote asset stages. Implementation is supplied as an uncommitted patch.
Repository instructions prohibit tests and commits without explicit authorization.

The user subsequently authorized Studio MCP tests, fixes, commit and push of all
pending changes. The [milestone verification](MILESTONE_VERIFICATION.md) records
those follow-on checks and their limits. The original source-only pass described
below did not itself perform that verification or delivery.

## What the current source establishes

The repository already contains the first-zone implementation and dated Studio
verification reports. `docs/RUNTIME_VERIFICATION.md` reports eight contract groups and
16 two-client checks from its earlier authorized run; those are not results from this
pass. Its remaining audio, persistent mesh, live-cloud and physical-device acceptance
items still apply.

`data/content-ids.json` contains 14 image IDs and zero audio IDs. The manifest lists
24 audio entries: 19 playable samples, four interface cues and one ambience loop.
The four unbound optional image sources are not new upload authorization. Existing
image uploads must not be repeated merely because a manifest entry has `asset_id: null`;
that manifest is a source inventory, while `data/content-ids.json` is the binding authority.

## Changes

### Safe incremental content binding

The previous `configure_content.py` generated every runtime section from only its input
file. Consequently an Audio-only file replaced the Images section with an empty table.
The revised command merges into canonical `data/content-ids.json`, preserving omitted
sections and omitted keys. An empty section means no changes, not deletion.

The default invocation is offline validation and prints the proposed delta plus unbound
keys. It performs no network requests and no asset upload:

```powershell
python tools/configure_content.py work/audio-upload-ids.json
```

Only after real upload/permission receipts have been reviewed:

```powershell
python tools/configure_content.py work/audio-upload-ids.json --write
```

An incremental file has the usual `Audio` object containing only known sample keys and
actual integer IDs. Do not use fake IDs to make the UI look ready. A changed existing ID
is rejected unless `--allow-rebind` is explicit. Review the corresponding upload receipt
before using that flag. Booleans, zero, fractional/out-of-range IDs, unknown keys,
non-object inputs and duplicate JSON keys are rejected.

`--write` stages both complete outputs, checks that the originals have not changed while
preparing, then replaces canonical JSON and its generated Luau projection. Each file
replacement is atomic; the pair is NOT a cross-file transaction. Run a single writer.
If the process is interrupted between replacements, regenerate from the preserved
canonical mapping with:

```powershell
python tools/configure_content.py data/content-ids.json --write
```

Do not edit the generated `src/shared/ContentIds.luau` by hand. Keep actual receipts
separately; local ID validation cannot prove ownership, moderation or permissions.

### Audio readiness and resource ownership

`AudioEngine` keeps the existing Sound-based public interface and the existing
Heartbeat transport. There is no claim of sample-accurate scheduling or a new mixer.

Each bank has a distinct `unconfigured`, `invalid`, `loading`, `ready`, `failed` or
`timedOut` state. Preload callbacks record the actual AssetFetchStatus rather than
assuming a successful `pcall` means the sound loaded. A bank becomes ready only when
all its allocated voices report IsLoaded. Late successful loading can recover an
earlier failure/timeout. A 15-second UI deadline is a project policy, not a Roblox
network timeout and not cancellation of the provider's internal fetch.

Music banks allocate four voices before playback; each cue and the ambience allocate
one. Pad hits allocate no clones. The courtyard engine uses music banks only and never
allocates the personal interface cues or waterfront ambience. With all 24 bindings,
this means at most 81 personal Sound objects plus 76 courtyard Sound objects, rather
than an unbounded pool. This is an object-count bound, not a measured memory/FPS result.
An unconfigured ID allocates no Sound object.

Partial readiness is allowed: loaded banks can play while other banks fail, and pattern
editing/saving remains usable without audio. The visible status counts the 19 playable
samples; `AudioEngine:diagnostics()` also exposes cue/ambience states for local inspection.
Muted status is explicit. Missing/malformed IDs and asset fetch failures never create
auto-upload or provider retry work.

Ambient intent survives mute/unmute and late loading. Entering a sampler or courtyard
session stops ambience immediately instead of waiting for the next periodic update.
Client teardown disconnects owned event subscriptions and keyboard binding, restores
touch controls, and disposes both sound engines. A disposed engine ignores late preload
callbacks. Roblox's underlying fetch itself is not claimed to be cancelled.

### Visual source restored

`assets/references/needle-quay-approved-style-board.png` is the original selected chat
attachment, copied byte-for-byte. Its adjacent JSON records origin, dimensions and
SHA-256. This supersedes only the historical missing-board note; it does not approve
current atlas/rig quality or any individual mesh. The collage is not a Tripo input.

Keep the teal/cream/amber/coral/wood direction, exact 4 x 4 pad controls, independently
constructed interfaces and existing game-optimized geometry/texture budgets. Do not
replace the original board with a generated approximation.

## Current official documentation consulted

- Roblox ContentProvider: https://create.roblox.com/docs/reference/engine/classes/ContentProvider
  PreloadAsync reports final status through its callback; an asset failure need not
  raise an exception. Only targeted sound instances are preloaded here.
- Roblox Sound: https://create.roblox.com/docs/reference/engine/classes/Sound
  Playback remains guarded by IsLoaded; no indefinite Loaded:Wait is introduced.
- Roblox AssetFetchStatus: https://create.roblox.com/docs/reference/engine/enums/AssetFetchStatus
  Failure and TimedOut are distinct outcomes.
- Tripo P1: https://developers.tripo3d.ai/en/models/p1
  The consulted page lists `P1-20260311` as stable, with explicit face limits and no
  support for `quad`, `smart_low_poly`, `generate_parts` or `geometry_quality`.

These are dated public documentation observations, NOT a refreshed connected-tool
schema, account inspection, dry-run quote or spend authorization. This pass changes no
Tripo recipe or gate. Before any future billable batch, follow `AGENTS.md` and refresh
both official docs and the actual connected schema; preserve verified pinned versions
and per-asset caps. Do not automatically upgrade model or CLI versions.

## Remaining acceptance: NOT RUN in this pass

Before release, obtain explicit verification authorization and use the existing
repository-pinned tools and Studio workflow. No new test suite is supplied.

1. On a disposable mapping copy, confirm incremental Audio binding retains all 14
   images, repeat application is idempotent, and unintended ID replacement is refused.
   Exercise malformed/duplicate keys and filesystem failure recovery before relying on
   the writer. Do not alter live IDs with synthetic values.
2. In the intended experience, use an explicitly approved audio-upload batch and record
   asset type, owner, moderation and experience permissions for every resulting ID.
   Resume known submissions from their receipts; do not blindly reupload.
3. Exercise zero bindings, cue-only bindings, a mixed loaded/denied bank, a slow load,
   late successful recovery, fast repeated pad hits, Stop, mute/unmute, listening exit
   and script teardown while loading. Verify real sound and loudness by listening.
4. Recheck portrait/landscape wrapping of the longer load-state summary, keyboard,
   gamepad and physical touch behavior; earlier UI captures do not cover these changes.
5. Re-run the existing contract/two-client checks only when authorized. Measure real
   device timing, FPS and memory; source object limits are not performance evidence.
6. Continue persistent native mesh imports, atlas/rig art review and live-cloud
   persistence separately. None is resolved by this patch or by local preload success.

## Verification boundary

Source snapshots were compared to their GitHub blob hashes. Python syntax and patch
integrity can be checked without invoking gameplay or the configured upload pipeline.
No application test, Studio session, source build, Tripo job, upload or publish is
claimed for this continuation. See the delivered `VERIFICATION.json` for the checks
actually performed while packaging, not for runtime acceptance.
