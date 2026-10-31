# Personal Studio audio preview repair

Six supplied, non-silent WAV candidates are available through a separate personal Studio audition path after the local package is installed. Listening approval and runtime admission remain pending. No generated/replacement audio, retuning, conversion, upload, publication or commit was performed.

Canonical roles remain A drums, B bass, C melody/harmony, D twelve harbour sounds and four vocals. These mappings use canonical role addresses rather than source ZIP ordinals.

| Slot | Native source | Installed content-relative path | SHA-256 |
|---|---|---|---|
| A02 | `assets/production/needle-quay/harbour-pulse-v3/source-pack/NeedleQuay_Pack/Drums/02_Drop_Kick_2.wav` | `preview-audio/nq.harbour.v1.a02.wav` | `d84000a246b903b5ec6e0815c8044f42be3da7bfce1d02813fd76db4f79dc925` |
| A03 | `assets/production/needle-quay/harbour-pulse-v3/source-pack/NeedleQuay_Pack/Drums/05_Main_Backbeat_Snare.wav` | `preview-audio/nq.harbour.v1.a03.wav` | `ec25805af70109a473115081cad8b2f292077d05327e69c6ef7672ab0e6cc180` |
| A07 | `assets/production/needle-quay/harbour-pulse-v3/source-pack/NeedleQuay_Pack/Drums/11_Open_Hat_Splash.wav` | `preview-audio/nq.harbour.v1.a07.wav` | `8908dc914951de8adb3c32f2874e87bb249c962b55fd71ee18d4830ead043056` |
| A15 | `assets/production/needle-quay/harbour-pulse-v3/source-pack/NeedleQuay_Pack/Drums/12_Shaker_Ghost.wav` | `preview-audio/nq.harbour.v1.a15.wav` | `06873d95756ae2f609869d61b28034f43777954fea760ea73a394a49d443ccff` |
| D13 | `assets/production/needle-quay/harbour-pulse-v3/source-pack/NeedleQuay_Pack/MC_Vocals/33__Needle_Quay__.wav` | `preview-audio/nq.harbour.v1.d13.wav` | `8755ffe1f03e6dc5e546e2752c1631e9c29a146df051f0b883595640fb02b030` |
| D14 | `assets/production/needle-quay/harbour-pulse-v3/source-pack/NeedleQuay_Pack/MC_Vocals/34__We_Make_Waves__.wav` | `preview-audio/nq.harbour.v1.d14.wav` | `6580a038c9f74651892b2bb67802497e90812eeb41a887937799d26d88bc9b56` |

All six files retain their native stereo 44.1-kHz PCM16 bytes. `verified_pitch` is null for every preview; these authored slots are unpitched. Source labels and mapping limitations are retained in `data/active-content.json`. A02 is a filename-supported kick-role candidate; the specific punch timbre has not received listening review. D13/D14 filename wording has not been verified by listening or transcription.

Seven supplied files contain only zero PCM samples: 01, 09, 10, 17, 30, 31 and 32. The two closed-hat files also share identical bytes. They remain excluded. Pitched B/C mismatches and discovery I01/I02/I03 stay pending.

`Catalog.isReady`, `Catalog.isPlayable`, semantic role readiness, complete-pack selection, quest musical evidence and Finished Song capture remain approved-only. `Catalog.isPreviewAvailable(id, unlocked)` and `Catalog.isLocallyPlayable(id, unlocked)` expose the separate Studio audition state. Only the personal AudioEngine opts in. Private sequence/draft schedules identify local preview events; public listening/jam/street engines retain strict readiness.

Validation: source guard script, pinned Selene/StyLua, Python compilation, PowerShell parsing and scoped diff checks pass. Exact installed/package WAV checks are deferred to the coordinated root packaging pass. Studio Server/Client probes are provided but have not been run by this implementation agent. Human listening approval remains pending.

Repeat after packaging: `python tools/qa/local_audio_preview.py`. Through Studio MCP after a fresh build/Play session, run `tools/qa/local_audio_preview_server.luau` in Server and `tools/qa/local_audio_preview_client.luau` in Client. The client probe uses disposable engines and audibly starts the six short candidates without editing the active composition.

Pre-change backup: `C:/Users/slavd/.codex/backups/BeatMaka/device-audio-preview-20261030-184149`.
