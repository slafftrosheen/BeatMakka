# Pack-native 64-slot local kit

The user explicitly superseded the previous written-map choice: “also change mapping to the one which came with pack, so all 64 samples are playable”. Canonical sample IDs and absolute addresses stay stable; native WAV numeric prefixes now determine bank/pad order.

| Bank | Source ordinals | Native content |
|---|---|---|
| A | 01–16 | Drums |
| B | 17–32 | Bass |
| C | 33–48 | MC vocals |
| D | 49–64 | Harbour FX and melodics |

The earlier written contract, six-preview authority and pending bindings are archived under `assets/archive/written-audio-map-v3-2026-10-30/`. The superseding decision and archived-contract hash are in `assets/production/needle-quay/harbour-pulse-v3/pack-native-decision.json`.

All64 local candidates contain nonzero PCM, have distinct hashes and contain no clipped PCM16 samples. Of them, 56 retain the supplied native WAV bytes. The same seven silent files are present in both repository and original Downloads archives; no recoverable counterpart was found. Their original all-zero WAVs and ZIP remain unchanged.

| Slot | Repair | Source ordinal |
|---|---|---|
| A01 | Deterministic decaying main kick | 01 |
| A09 | Deterministic closed DnB hat 1 | 09 |
| A10 | Distinct deterministic closed DnB hat 2 | 10 |
| B01 | Authored D1 sub with bounded harmonics | 17 |
| B14 | Authored D2 detuned Reese stab | 30 |
| B15 | Authored low D2-to-D1 sub glide | 31 |
| B16 | Authored sustained D1 bass tail | 32 |
| A15 | Level-only original metal hit normalization to −12 dBFS | 15 |

These are explicit local DSP substitutes and a gain derivative, not recovered performances from the supplied song. They are deterministic PCM16 stereo files at 44.1 kHz. No vocals were synthesized, retuned or replaced. Repair formulas, seeds, measured PCM metadata, original/output hashes and the counterpart audit are retained in `local-dsp-repairs/manifest.json` and `tools/prepare_pack_native_audio.py`.

Technical local readiness is separate from human approval: all64 are personal Studio previews with `audio_approved:false`, `runtime_admitted:false` and `listening_review:pending`. No provider call, spending, upload or publication occurred. Public listening/jam, semantic approvals, quest musical evidence and Finished Song capture retain their approved-only gates.

`Catalog.BankLabels` provides the native bank labels. `Catalog.LocalPacks`/`LocalPackById` provide the complete local kit with `technicalLocalReady`, `localOnly` and `localSelectable`; approved `Catalog.Packs` remains empty. The personal engine uses `isLocallyPlayable`, while `isReady`/`isPlayable` remain approval-gated.

Discovery IDs I01/I02/I03 are preserved in separate pending-role metadata. I01 has an unapproved native A15 metal candidate. No exact vent-pulse or helper/radio-reply counterpart was supplied for I02/I03. D01 is now the native Lantern Bell D5 and is not presented as dock metal. Native kit pads have no discovery lock, so all64 can be auditioned locally. Closed-hat aliases move to A09; no pluck alias points at C01 vocals.

Repeatable source QA passes ten guards, including exact order, preserved IDs, nonzero/unique/unclipped PCM, deterministic repair reproduction, amplitude-only normalization and negative approval/admission/ordinal/address/hash/duplicate/incomplete/silent-source checks. Pinned Selene/StyLua, Python compilation and scoped diff checks pass.

Root coordinates packaging and Studio MCP. After packaging, run `python tools/qa/local_audio_preview.py` for all64 exact payload hashes/URI checks. Run `tools/qa/local_audio_preview_server.luau` and `tools/qa/local_audio_preview_client.luau` in their respective Play contexts. The client probe checks64 voices, actual playback starts, public-engine exclusion, mute/stop, and that transport stop retains visible audition selection. Human listening approval remains pending.
