# Current audio reconciliation and deferred research scope — 5 November 2026

The [offline receipt](../evidence/audio-readiness-2026-11-05-current.json) accounts for the current local Needle Quay kit. It does not establish a final listening-approved pack, current Roblox permissions, audible runtime playback or release readiness. The historical 24-source inspection and original-batch authorization remain preserved for their dated scope. `tools/prepare_audio_acceptance.py` now sees the five retained sources in its input manifest; it is not the current 64-sample reconciliation tool.

## Issue #5: local preparation

`tools/prepare_current_audio_readiness.py` follows `data/active-content.json`, its canonical 64-slot plan, current JSON/runtime/local bindings, the local install manifest and recorded historical audio receipts. It uses the existing source/provenance validators and measures actual PCM frames, rate, channel count, bit depth, duration, peak/RMS, clipping, bytes and SHA-256. Stereo is measured as stereo. It compares authored metadata and exact packaged bytes without changing either.

| Inventory | Actual local result |
| --- | --- |
| Musical identities | 64, canonical A01–D16, `nq_harbour_01` / `pack-native-2026-10-30` |
| Musical source state | 64 technical local previews; zero musical admissions; listening approval pending |
| Separately retained Audio sources | Four UI cues and `waterfront` ambience |
| Other packaged audio | 114 separate ambience/voice payloads, inventoried in an appendix and excluded from the 64 musical identities and five Audio bindings |
| Current remote Audio bindings | Zero; fourteen image bindings preserved |
| Matching known historical upload hashes | Zero among the two explicitly indexed local receipt sources; this does not prove an upload never occurred |
| Current 69 source WAVs | 11,111,504 bytes; no clipped PCM samples; source/local-package metadata and hashes consistent |
| Intended destination | Owner, PlaceId and UniverseId unrecorded; deployment and submission unauthorized |

Each of the 69 rows identifies its actual source/hash, local binding path, packaged copy, recorded remote ID, any matching historical upload candidate and pending reconciliation. The tool marks an upload's genuinely missing status **unknown until authorized inventory reconciliation**. It never interprets an absent local receipt as an instruction to upload, restores retired test audio, assigns IDs, approves a source, or changes asset stages.

To produce a fresh receipt from the repository root:

```sh
python -B tools/prepare_current_audio_readiness.py --output work/audio-readiness/current-inventory.json
```

The output path must be inside `work/` or `docs/evidence/` and must not already exist. Without `--output`, the tool prints the inventory. A successful exit means local inventory consistency only. The report always keeps hosted acceptance separate.

Before any future authorized submission, select the intended owner/destination and final reviewed source version. Reconcile that owner's existing inventory, actual receipts and unknown outcomes against these exact hashes; identify reusable IDs and genuinely missing files, then verify current moderation and intended-experience usage permissions. Refresh the supported route and authorization at that time. The current no-upload/no-publish policy remains in force.

## Readiness behavior and remaining acceptance

At the audited `aa6cb5f` baseline, `AudioEngine` implements per-allocated-bank loading, ready, failure and timeout states, a 15-second local deadline, late `IsLoaded` recovery, bounded preallocated voices, stop/mute handling, disposed-bank guards and teardown. Playback refuses unavailable sounds and supplies no substitute.

That baseline has one source gap: `setSelection`, `setSchedule` and `_syncMusic` filter unavailable identities before allocation, while `status` counts only allocated banks. A mixed selection can therefore appear fully ready when missing requested samples have no bank. Requested identities and explicit missing/invalid/unapproved reasons must be retained separately from allocated voices. This report does not alter `AudioEngine` or claim that source gap has been verified fixed.

Actual final-pack listening, starts/tails, balance, several distinct arrangements, phone-speaker usefulness and discovery-recording equivalence remain content/human acceptance. Intended-experience ownership, usage permissions, mixed-access/late-ready audible playback, rapid hits, stop/mute and teardown remain hosted/client observations. Metadata consistency establishes none of those outcomes. A current source subset used for a discovery or challenge must preserve identity and explicitly label any local substitute; it cannot grant approval or become a duplicated pack.

## Current code contracts and deferred issues

| Issue | Current code/preparation coverage | Outstanding boundary |
| --- | --- | --- |
| #5 | Current 64-plus-five offline reconciliation is supplied here; source/local-package/known-receipt inventory is concrete. Runtime already handles allocated-bank failures and recovery. | Final approved content is pending. Requested-but-unavailable identity reporting needs the source fix above. Hosted permission and audible playback evidence require a future authorized destination. |
| #7 | `SampleCatalog` exposes canonical 64 identities in four 16-pad banks. `MusicProject` preserves ordinary project/program data; `SampleVersions` pins copied/released music by pack ID and mapping revision; `MusicTransport` rejects mismatched/missing versions. Retired IDs remain recoverable labels, not selectable packs. | Explicitly deferred: no named next pack, observed musical need or acceptance exists. Integrate a new version only after those are selected; do not build or generate speculative packs. The current catalog intentionally loads one plan. |
| #16 | Jam protocol schema 3 provides Rhythm and Hook/Texture roles, two tracks, a 0.75-second scheduling lead, 2,048-event and 350,000-byte snapshot budgets, explicit invitations/acceptance, bar-boundary transitions and survivor/departure handling. `JamPlayback`/`JamTiming` expose voice counts, arrival leads, local submission lateness, transitions and late deferrals. | Explicitly deferred: no observed demand, named three-person experiment or comparable device/network/memory/mix observations. Keep the supported admission cap at two. Declared `Voices=16` is a protocol constant, not evidence of measured rendering performance or a global voice allocation guarantee. |
| #18 | The normal instrument maps 16 physical keyboard keys through `SamplerPadLayout`, with bank selection resolving to absolute 1–64 pads. `PadInput` retains the input token's original absolute pad until release; focus/text focus, ownership-route changes, stop and teardown clear held input through existing paths. | Explicitly deferred: no named controller, desktop OS, bridge/version or hardware experiment. Keyboard mapping proves no MIDI, velocity, USB, Bluetooth or iPad compatibility. Recheck official capabilities only when a concrete permitted experiment is activated. No bridge/dependency installation is implied. |
| #1 | Execution/phase ownership is defined by the current issue brief; completed foundations and independent local/hosted gates remain distinct. This report provides #5 local preparation without claiming whole-issue closure. | An execution index is not another gameplay system. Track actual phase results; historical approvals do not supersede current deployment policy. |
| #24 | Existing sampler/transport, first-groove, stage/jam, save and local timing probes provide the implementation/inspection surfaces for the roadmap. No telemetry service is required. | First audible choice, replay/save/reopen, show end, voluntary variation/social actions, novice timing and later return require actual observation. Distinguish prompted actions and Sound:Play submission from voluntary engagement and acoustic onset. No enjoyment, retention or profitability result is implied by code coverage. |

Only the offline inventory generation was run for this work. No gameplay test suite, build, Studio session, target-device run, human listening session, network request, paid call, upload, publish, asset approval, binding/source mutation or commit was performed.
