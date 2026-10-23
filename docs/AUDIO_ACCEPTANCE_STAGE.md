# Audio readiness and proposed private acceptance stage

23 October 2026. Continuation from `6ed1b00830c2ca243c9d2909261fd9cc9cd7172e`. The user selected audio readiness and acceptance and confirmed that the game currently exists only as a local Studio project.

## Completed local preparation

`tools/prepare_audio_acceptance.py` inspected the existing 24 source WAVs against both authored manifests. It made no network requests, regenerated no sources and changed no content bindings.

- All 24 are mono 44.1-kHz PCM16 and meet the currently documented audio import format, size and duration requirements.
- Actual duration, channel/rate, peak and RMS measurements match the authored source metadata within its rounding tolerance. There are zero full-scale clipped samples.
- Total source size is 2,350,704 bytes. Per-file SHA-256, measurements, proposed names and pending acceptance fields are in [audio-readiness-20261023.json](evidence/audio-readiness-20261023.json).
- The existing fourteen image bindings are preserved. Audio bindings remain empty. Neither file inspection nor a matching hash establishes moderation, permissions, loudness acceptance or successful Roblox playback.
- A separate local audition reel is at `work/audio-readiness/audition.wav`, with a 6.021-dB attenuation applied only to the review copy and a gap between sources. Its chapter times are in the report. Original WAVs are unchanged.
- Rights provenance is recorded as original mathematical synthesis in the project manifest and generator. This records the authored provenance; it is not an independent legal determination.

Reproduce from the repository root:

```powershell
python -B tools/prepare_audio_acceptance.py --output docs/evidence/audio-readiness-20261023.json --audition work/audio-readiness/audition.wav
```

## Named audio batch

19 playable samples: `kick`, `snare`, `closed_hat`, `open_hat`, `clap`, `rim`, `low_tom`, `high_tom`, `shaker`, `tambourine`, `bell`, `pluck`, `bass_c`, `bass_eb`, `bass_g`, `chord`, `metal_hit`, `vent_thump`, `robot_chirp`.

Four cues: `ui_tap`, `ui_collect`, `ui_save`, `ui_error`. One ambience: `waterfront`.

No substitute or invented IDs are proposed. Reconcile any existing uploads before submitting these files. The personal inventory search for `FZ` returned zero Audio results; that query is not a comprehensive proof that the files were never uploaded.

## Connected context and upload route

The intended Studio session remains `FrequencyZero-Complete.rbxlx`. Read-only MCP inspection reported `PlaceId=0`, `GameId=0`, `CreatorId=0`; it has no published experience identity. The inventory tool reported signed-in user ID `11274985967`, with `isPublished=false`. This identifies the current tool context, not approved ownership for a new cloud project.

The refreshed Studio MCP schema exposes image upload, inventory search and insertion, but no audio-upload tool. The official `AssetService:CreateAssetAsync` supported-type list does not provide an Audio route. Do not call the image uploader or the prior mesh/image driver for this batch. Use the official audio importer/Asset Manager or an independently verified authorized Open Cloud route; do not read credentials or create an alternate credential-bearing uploader.

Current official documentation:

- [Audio assets](https://create.roblox.com/docs/audio/assets): supported file formats, under-20-MB/7-minute limits, sample rates up to 48 kHz, private audio and experience usage permissions.
- [Create and publish games and places](https://create.roblox.com/docs/production/publishing/publish-games-and-places): publishing assigns a UniverseID; new games initially restrict access to the creator/editors and appropriate group roles. Public release is a separate action.
- [Assets usage guide](https://create.roblox.com/docs/cloud/guides/usage-assets): Open Cloud audio support. Its monthly quota figures differ from the audio-assets guide, so verify the actual selected route/account quota rather than assuming that all 24 can be submitted at once.
- [AssetService](https://create.roblox.com/docs/reference/engine/classes/AssetService): supported creation types and audio metadata queries. A metadata response alone does not establish experience permission or playback.

## Concrete next action requiring authorization

Proposed destination: a **new private test experience**, `Frequency Zero - Audio Test`, owned by the currently signed-in personal account. Proposed place source: the completed milestone source project at the commit above, built through the repository-pinned Rojo project; it uses the existing geometry proxies until persistent mesh acceptance. It must not overwrite an existing experience or include temporary QA drivers/source backups.

After explicit authorization for that cloud creation and the named 24-file private upload batch:

1. Verify private access and record the real creator, PlaceId and UniverseID. Keep public release disabled.
2. Confirm the supported importer route, remaining quota and any displayed charges before submission. No paid spending, Tripo work or automatic resubmission is included.
3. Upload only missing named files. Persist each real receipt immediately. Stop on unknown outcomes and reconcile before another submission.
4. Record moderation and grant usage only to the intended test experience. Merge actual IDs through `configure_content.py`, preserving image IDs.
5. Through Studio MCP, check metadata and real load results, partial failure/late recovery, repeated hits, stop/mute, listening sessions and teardown. Listen to the result for clipping, balance and ambience transitions. Source-file measurements are not a substitute for this acceptance.

Cloud creation, asset submission, permission grants, listening approval and published playback remain pending. No application tests/builds, upload, publication, commit, push or asset-stage promotion were performed in this local preparation pass.


## Current authorization and staging — 23 October 2026

The user explicitly approved: “Use the signed-in personal Roblox account; private test only, no paid charges”. This satisfies owner/batch authorization for the new private `Frequency Zero - Audio Test` experience and the 24 original sources above. The connected inventory reports user `11274985967`; the signed-in Creator Dashboard showed `CuuteFoxey`. These are observed account contexts, not a published ownership receipt.

[The authorized batch](evidence/a01-05/authorized-original-batch.json) pins all 24 source hashes, zero paid-cost cap and pending receipts. A fresh local inspection still finds 2,350,704 bytes, zero clipped samples, empty audio bindings and fourteen image bindings. The approved four-sound CC0 audition revision from #4 remains a separate candidate revision; it has not silently replaced the authorized original batch.

The user subsequently requested use of Studio MCP while keeping their PC available for work. Foreground browser/native automation is paused. Current Studio MCP provides no audio upload or new-experience publishing route, and no suitable connected background connector was found. No new experience, upload, permission grant, charge or resubmission occurred. Actual PlaceId/UniverseID/receipts remain null. Continue Studio/local checks; cloud submission requires an available supported route that respects this constraint. No renewed owner approval is needed for the approved scope.
