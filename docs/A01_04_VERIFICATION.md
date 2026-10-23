# A01-04 / issue #4 — bounded CC0 source selection

23 October 2026. Continued from `f2e83a9`. The user reviewed the supplied A/B audition and explicitly corrected their response to approve the proposed four sounds. The approval is retained in the package's [selection record](../assets/candidates/audio/quay-found-v1/selection.json).

## Selected source revision

| Canonical ID | Selected Kenney source | Derived duration |
| --- | --- | --- |
| rim | Impact Sounds 1.0 / impactWood_light_000.ogg | 0.262698s |
| metal_hit / I01 | Impact Sounds 1.0 / impactMetal_light_000.ogg | 0.362041s |
| vent_thump / I02 | Impact Sounds 1.0 / impactSoft_heavy_000.ogg | 0.519796s |
| robot_chirp / I03 | Digital Audio 1.0 / pepSound1.ogg | 0.470227s |

Alternatives `impactWood_light_002`, `impactMetal_light_002` and `twoTone1` were not selected. `impactPlate_heavy_000` and `laser1` were excluded by the heavy-plate/laser source categories; these are explicit aesthetic exclusions, not claims that the agent independently heard them. Freesound candidates were not admitted: no need to add another provenance/login route for this bounded set.

[Source-revision registry](../data/audio-source-revisions.json) describes the optional `quay-found-v1` delta over the complete original synthesized library. Original synthesis remains the default/fallback. All canonical IDs, sixteen pads, discovery meanings, tonal sources, UI cues, ambience, 24 original WAVs, upload manifest and fourteen image bindings are preserved. Selecting CC0 source files does not bind an unverified Roblox ID or silently replace a runtime source.

## Rights and original files

Official [Impact Sounds](https://kenney.nl/assets/impact-sounds) and [Digital Audio](https://kenney.nl/assets/digital-audio) pages identify CC0; both actual archives include matching unmodified creator license files. Kenney's [support guidance](https://kenney.nl/support) confirms commercial reuse and optional attribution. [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) permits copying, modification, distribution and performance; [legal code](https://creativecommons.org/publicdomain/zero/1.0/legalcode.en) retains its limitations concerning other rights. No endorsement is implied.

Each of the nine compared sources has an individual author, exact source page/archive/member/version, archive SHA-256, original OGG/hash, derived WAV/hash, included license/hash, dated rights assessment for repository redistribution, Roblox hosting and isolated sampler use, edit record and optional credit. Rights are assessed from the official creator distribution, not independently guaranteed by the agent. Full archive license files are retained; direct retrieval of CC's plain-text legal code returned HTTP403, recorded honestly alongside the official legal-code reference.

Original bytes live in the [closed candidate package](../assets/candidates/audio/quay-found-v1/manifest.json). It contains only the nine named members and licenses; the other pack files were not copied into production. No new dependency or paid tool was installed. `game-dev` is absent, so no claim is made that its vendor-admission command ran.

## Edits and audible comparison

Existing FFmpeg downmixed to mono 44.1kHz float intermediates. The deterministic script removes measured DC, trims below the documented threshold with padding, applies 22-frame onset / 353-frame tail fades, caps gain at +12.04dB, targets −24dBFS RMS with a −9dBFS sample-peak ceiling, then writes PCM16. Actual per-file gains and measurements are in the package; no tuning edits were applied. Peak limiting can leave transient material below the RMS target, so this is not a claim of perceptual loudness matching.

The [self-contained review page](../output/audio-quay-found-v1/index.html) has original/derived comparisons for all nine candidates and separate original/selected full-pattern renders. Both renders use the same 96BPM, two-bar arrangement, same −12.0412dB gain and no UI/ambience. Original peak/RMS: −6.884/−25.157dBFS; selected: −6.788/−26.097dBFS. Each render is eight seconds and has zero clipped PCM samples. These measured balance checks complement the user's listening decision; they do not establish Roblox playback quality.

Browser interaction verified original playback starts, selecting the candidate preview stops the previous one, and Stop all previews stops playback. Actual human listening selection was supplied by the user; audio playback UI state alone was not counted as hearing by the agent. Foreground browser/native automation was stopped when the user needed their PC for work.

## Verification and next step

`python tools/prepare_cc0_audition.py --verify` verifies the complete package roster, all original/derived/license hashes, review artifact hashes, selection/registry agreement, format/duration/clipping constraints, and 29 unchanged canonical source/binding files. Tampered audio bytes and an unexpected package member were both rejected in an isolated work copy; [receipt](evidence/a01-04/integrity.json). Git line-ending normalization initially altered a provider license; byte-preserving attributes corrected it. All 25 package/review hashes were then checked against the actual Git index bytes, including original licenses and generated metadata, so a checkout retains the recorded digests.

The content-selection criteria of #4 are fulfilled. No audio was uploaded by this issue. The approved optional revision remains separate from #5's already-authorized batch of 24 original sources. Admitting selected CC0 replacements to Roblox requires its own explicit source revision and real receipts, moderation, permissions and runtime/listening acceptance. Tripo spend: zero.
