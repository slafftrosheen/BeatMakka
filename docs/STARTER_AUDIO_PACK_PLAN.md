# Starter audio pack and real-world sound collection

Continuation: [A01-04 source selection](A01_04_VERIFICATION.md) now records the user-approved four-file CC0 revision and retained A/B package. [A01-17 capability decision](A01_17_MICROPHONE_CAPABILITY.md) refreshes the microphone research with current official documentation and a non-recording Studio probe. The text below records the earlier research stage; its statements about work not yet performed are historical.

Research/design sketch, 23 October 2026. This is a proposal, not asset admission or runtime acceptance. No packs were downloaded or auditioned, no uploads or cloud experience were created, and no source audio, bindings, dependencies or application code were changed. Existing audio-readiness work remains intact.

## Recommended first version

Keep the existing original synthesized bank as the complete fallback. Curate a small optional **Quay Found Sounds** variation from clearly reusable CC0 sources, rather than replacing the whole library or importing hundreds of unrelated sounds. Choose dry wood, soft metal, breathy percussion and friendly electronic chirps to complement the approved warm workshop/courtyard visual board. These are creative selection targets; sonic fit is not yet verified by listening.

The existing catalog has 16 default samples and three discovery choices assigned to those same physical pads. It does not need 19 physical pads. Preserve every canonical sample ID and the I01/I02/I03 discovery links. A new source revision must be explicit and reversible; do not silently replace an already approved asset ID.

| Existing IDs | Curated requirement |
| --- | --- |
| `kick`, `snare`, `closed_hat`, `open_hat` | Four clean rhythmic anchors; warm short kick, dry snare, distinct soft closed/open hats. |
| `clap`, `rim`, `low_tom`, `high_tom` | Hand/wood character and a clearly related low/high pair. |
| `shaker`, `tambourine` | Light texture with restrained high-frequency energy. |
| `bell`, `pluck` | Short melodic accents compatible with the current C/E-flat/G bass set. |
| `bass_c`, `bass_eb`, `bass_g`, `chord` | Preserve original synthesis initially; consistent tuning and timbre beat arbitrary pack variety. |
| `metal_hit` / I01 | A small quay object hit, distinct from the rim without harsh ringing. |
| `vent_thump` / I02 | Low air/mechanical thump; no alarming industrial blast. |
| `robot_chirp` / I03 | Friendly short electronic reply, no intelligible speech. |

Authoring targets, not Roblox limits: mono PCM16 WAV at 44.1 kHz; usually 0.08–1.5 seconds for percussion and at most three seconds for tonal tails; clean onset, short fades, no DC/clicks/clipped samples. Retain originals separately. Gain-match by listening in the busiest intended pattern, leaving mix headroom; peak normalization alone is not acceptance. No mandatory tempo loops: the existing sequencer runs 60–180 BPM. Record pitch, root and any tuning edit for tonal samples. Keep the four UI cues and waterfront ambience separate from musical-pad choices.

## Concrete candidate sources

| Candidate | Verified primary-source rights/context | Proposed use and remaining check |
| --- | --- | --- |
| [Kenney Impact Sounds](https://kenney.nl/assets/impact-sounds) | Official page lists 130 files and Creative Commons CC0. | First audition pool for wood/metal/percussion. Archive contents, source filenames and exact sonic fit remain uninspected. |
| [Kenney Digital Audio](https://kenney.nl/assets/digital-audio) | Official page lists 60 files and CC0. | Small audition pool for a gentle helper chirp; reject loud laser/weapon-like character. No specific file selected. |
| [deadrobotmusic: Drum One Shots – Percussion](https://freesound.org/people/deadrobotmusic/packs/36319/) | Author's pack labels its listed foley one-shots CC0. The individual [Foley Perc 27](https://freesound.org/people/deadrobotmusic/sounds/651988/) page explicitly shows CC0, 0.197 seconds, stereo 44.1-kHz 32-bit WAV. | Concrete short foley audition candidate. Check each selected file's own license and original-recording provenance; pack tags alone are insufficient. Download requires login through the normal service, with no credentials in chat. Conversion/downmix needs listening approval. |

Kenney confirms commercial reuse and optional attribution in its [official support guidance](https://kenney.nl/support). Use a plain creator credit, not the Kenney logo. [CC0](https://creativecommons.org/publicdomain/zero/1.0/) permits copying, modification, distribution and commercial performance, but does not clear third-party privacy, publicity or trademark rights or guarantee provenance. Keep credits and license receipts even where attribution is optional.

Freesound is a user-uploaded collection with mixed licenses, not a site-wide CC0 library. Its [official FAQ](https://freesound.org/help/faq/) distinguishes CC0, attribution and noncommercial licenses and warns that uploads may contain infringing material. For this starter pass admit only individually documented CC0, original non-vocal sounds. Exclude unclear provenance, identifiable speech, broadcast/music leakage and recordings of sample-ROM instruments without suitable rights.

Do not equate **free/royalty-free** with permission to redistribute isolated sampler sounds. [99Sounds' license](https://99sounds.org/license/) allows games and modification but restricts standalone redistribution and certain sound-app uses; [SampleRadar](https://www.musicradar.com/news/tech/free-music-samples-royalty-free-loops-hits-and-multis-to-download-sampleradar) allows music use while prohibiting redistribution. Our user-playable sampler and Roblox-hosted source assets require a clearer fit. Exclude these from automatic admission unless the rights holder explicitly clears this use. They are not approved substitutes.

## License and admission record

Before any selected file enters the project, record: canonical game ID; creator; original file and page URL; exact license/version and dated receipt; source SHA-256; evidence of original creation; original format; edits/downmix/tuning/gain; derived SHA-256; optional credit; and selection/acceptance status. Store the included license alongside retained originals. Repository redistribution, Roblox hosting and player performance are distinct uses to check. Any ambiguous file stays excluded.

Later, an authorized private upload batch must retain actual owner/asset/experience IDs, moderation status and experience permissions. Do not overwrite the existing fourteen image bindings or invent audio IDs. A license check, successful upload or metadata response does not establish successful playback or audible quality. See [audio acceptance stage](AUDIO_ACCEPTANCE_STAGE.md) and [Roblox audio assets](https://create.roblox.com/docs/audio/assets) for the pending hosted acceptance route.

## Can children record real-world sounds inside Roblox?

**Do not schedule this as an available microphone-recording feature.** The current official [AudioRecorder reference](https://create.roblox.com/docs/reference/engine/classes/AudioRecorder) states that the API is in development and unavailable. It describes bounded 60-second stream recordings and temporary playback content, and explicitly says `AudioDeviceInput` cannot be recorded. This is not evidence of an export, permanent asset upload or cross-session persistence route.

[Voice Chat](https://create.roblox.com/docs/chat/voice-chat) supports live communication for eligible verified 13+ users. [AudioDeviceInput](https://create.roblox.com/docs/reference/engine/classes/AudioDeviceInput) is the microphone stream used by that system. Neither live voice access nor routing effects grant microphone capture into saved sampler assets. Voice eligibility also excludes the younger children central to this idea. Recheck official availability, age restrictions and API capabilities before any future prototype; do not work around platform restrictions with an external recorder service.

The immediately feasible creative version is **world sound discovery**: a virtual recorder selects our curated, licensed environmental sounds at authored game objects, then the player brings those sounds to the existing pads. It must be clearly presented as collecting game sounds, not capturing a real microphone. A later creator-produced pack can use adult-authored original kitchen, courtyard, workshop and rain recordings, reviewed and imported through the normal developer pipeline. No child recording collection or external submission portal is proposed here.

If platform support eventually enables the real microphone concept, separately design explicit start/stop/review/delete controls, a short local preview, retention and deletion rules, age/guardian requirements, rights clearance and moderation before sharing. Private preview must be assessed separately from persistence and multiplayer playback; saving bytes or an asset ID must not silently publish a child's recording. These are unresolved product requirements, not implemented controls.

## Staged next steps

1. **Current research stage:** agree the sound character and retain the complete original bank. This document is the only deliverable of this research task.
2. **Curated audition stage:** choose only a handful of CC0 candidates from the sources above; retrieve through their normal download flow, retain licenses/hashes, audition and compare against existing sounds. Select exact named files before proposing any upload batch.
3. **Private Roblox acceptance:** after explicit cloud/upload authorization, reconcile prior assets, use the supported importer, record permissions/moderation, bind real IDs and verify loading, rapid retriggers, full-loop balance, mute/stop, ambience transitions and courtyard listening. Human listening remains necessary.
4. **Original thematic packs:** record a coherent adult-authored set; preserve source sessions and rights; admit one reviewed pack at a time without changing canonical discovery meanings.
5. **Player microphone research:** revisit only after official support materially changes. The playable world-discovery loop does not depend on it.

Unresolved: exact pack files and sound quality; per-file provenance and archive licenses; final sound selection; private experience owner/identity and upload authorization; moderation/permissions and runtime listening; supported future recording/persistence APIs. No paid provider operation, upload, publication, test/build, commit, push or acceptance-stage promotion was performed.
