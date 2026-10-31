# Remove every legacy test musical pack and prepare four real sound banks

Revision 3: apply this content-retirement work together with `MPC_WORKFLOW.md`. That document supersedes v1's fixed-pattern/64-lane-per-pattern proposal. The source snapshot records the earlier implementation, not an implemented Song Mode. Audit the real local code first; uncommitted work may already solve part of the migration.

## 1. Audited baseline and intended result

The supplied source currently exposes **179 musical IDs in 11 selectable kits**: the original Quay set has 16 default sounds and three discoveries; ten style starter kits add 160 sounds. The style IDs are `style.<pack>.<01..16>` for `triphop`, `dance`, `grunge`, `hardtrance`, `hiphop`, `industrial`, `pop`, `reggae`, `techno`, and `trance`.

The original musical IDs are `kick`, `snare`, `closed_hat`, `open_hat`, `clap`, `rim`, `low_tom`, `high_tom`, `shaker`, `tambourine`, `bell`, `pluck`, `bass_c`, `bass_eb`, `bass_g`, `chord`, `metal_hit`, `vent_thump`, and `robot_chirp`.

`LocalContent.Audio` has 184 local bindings: those 179 musical sounds plus `ui_tap`, `ui_collect`, `ui_save`, `ui_error`, and `waterfront`. The current cloud-content projection has 100 audio IDs belonging to old style samples and 14 image bindings. These are observed baseline counts, not assumptions about the user's newer local work.

**Result required now:** zero legacy musical test packs in the active game, no new substitute test kit, preserved player compositions, and an honest pending-audio four-bank instrument with named sequences and Song Mode. **Result after approval:** one first-area pack containing exactly 64 approved one-shots. The three discovery sounds belong within those 64, not in a 65th–67th bonus set. The four planned vocal cuts also belong within the same 64, at D13–D16; they replace the four earlier effect roles rather than adding another pack. Keep full vocal stems and the demo song outside the active instrument folder.

Removing a pack from a menu alone is insufficient. Its sound data must also be excluded from active defaults, assignment, playback, preview, preloading and distributable content.

## 2. Prevent silent loss of saved music before deleting IDs

`src/shared/Pattern.luau` currently initializes 16 default assignments from `Catalog.List`, then accepts saved assignments only when `Catalog.isUnlocked()` recognizes them. Deleting an ID therefore silently turns an old beat's existing notes into another sound on load. `BeatBook.sanitizeSlots`, `BeatBook.sanitizeShelf`, `BeatBook.capture` and `ProfileStore` propagate that substitution.

Implement a separation between the following concepts:

| State | Saved-data behavior | Runtime behavior |
|---|---|---|
| Approved active sample | Preserve stable ID and edits | May assign/play when permitted and actually bound |
| Known retired sample | Preserve exact ID, notes and edits | Unavailable label; silent; not selectable or preloaded |
| Empty lane | Preserve an explicit empty value | Silent, safe to display/edit |
| Unknown or unsupported saved reference | Preserve bounded opaque data in a quarantine/legacy record without interpreting it | No assignment or playback permission; explain that the sound is unavailable |

Do not allow arbitrary client strings to create valid catalog records. A server-side `Assign` operation accepts only active, permitted sample IDs. Historical read paths have different responsibilities from new write/assignment paths. For a legacy pattern the current version cannot safely represent, preserve it as read-only data rather than sanitizing it destructively. Validate sizes and primitive types while retaining a recovery copy of supported old music.

Preserve the four legacy working patterns and all six four-pattern Beat Shelf entries through the current sequence/import migration. Keep every original BPM, note, mute, pad edit and shelf version, together with discoveries, quests, chapter history, side activities, identity and wardrobe. These imports are not Finished Songs. Never wipe a DataStore or create a new empty profile as a migration shortcut. No retired sample may silently alias to a final-pack sound. Replacing a sound in an old beat is an explicit user edit.

## 3. Sound banks, sequences and Song Mode

Follow `MPC_WORKFLOW.md` for the replacement model. The old four A/B/C/D pattern slots are being retired as an active editing model. A/B/C/D now names sound banks exclusively. Keep 16 physical controls and resolve each press to one of 64 absolute program-pad addresses.

A Program owns sample assignments and pad sound settings. Tracks are musical parts with stable routing to those sounds. Named Sequences contain timed track events and their own musical length/tempo. Song Mode arranges stable sequence references with repeat counts. Finish & Save Song creates a separate immutable saved arrangement revision.

Do not treat the 64 pad addresses as 64 sequencer tracks. Do not preserve a hidden four-sequence limit. Do not use a bank switch to replace samples, change the selected sequence, clear notes, restart transport or dispose of voices still used by the song.

Migrate each old one-bar pattern into a named sequence, with its exact 16-pad mapping occupying bank A of an isolated legacy Program and B/C/D empty. Preserve different programs/tempos for different old patterns. Preserve every shelf bundle as its own imported draft project/archive, without inferring a song order or creating Finished Songs. See the current contract for idempotence, immutable snapshots, writer guards and recovery requirements.

The final pack's slot metadata is a content contract. Planned slot records do not make audio ready. Empty drafts can be edited/saved, but new musical achievements, finished-song admission and public performance require actual approved playable content.

## 4. Exact source dependency map

Paths below are relative to the project root. Search for local equivalents if the local agent has already reorganized them.

| Concern | Files | Required action |
|---|---|---|
| Active catalog | `src/shared/SampleCatalog.luau`, `StylePacks.luau` | Retire all eleven old kits and their audio from the active roster. Add a planned final-pack contract with no playable bindings. Keep archival references distinct. |
| Projects, sequences and songs | `src/shared/Pattern.luau`, `BeatBook.luau`; `src/server/ProfileStore.luau` | Replace the fixed model with named sequences, Song Mode drafts and immutable Finished Songs; preserve all old working/shelf material, independent mappings/tempos and version guards. |
| Physical input | `src/shared/SamplerPadLayout.luau`; `src/client/PadInput.luau`, `init.client.luau` | Keep 16 pads. Remove keyboard layout dependence on the first 16 samples. Capture physical pad plus bank as an absolute program-pad address. |
| Server commands | `src/server/MusicService.luau` | Validate project/sequence/track/program/pad identities for recording and edits; use typed song actions, including SongFinish. Retire the old Pack overwrite action. Bank selection must never call it. |
| Instrument UI | `src/client/WorkshopView.luau`, `SampleEditor.luau`, `BeatBookView.luau`, `init.client.luau` | Separate sound banks from the named sequence selector and Song Mode. Replace the fixed pattern/shelf UI, remove old pack options, and display unbound/retired sounds safely. |
| Playback | `src/client/AudioEngine.luau`, `init.client.luau`, `JamPlayback.luau` | Play all required track events and absolute pads through the shared sequence/song transport. Remove old default-ID fallbacks and preload actual approved audio needed by the arrangement or audition. |
| Pad editing and FX | `src/client/PadVoiceProcessor.luau` | Track/program/pad identity must isolate A01 from B01/C01/D01 and distinguish different tracks. Current 16 pad channels cannot simply be reused. |
| Shared music | `src/shared/JamProtocol.luau`; `src/client/JamPlayback.luau`; `src/server/JamService.luau`; `src/server/ListeningSession.luau`; `src/server/StageQueue.luau` | Audit all 16-lane assumptions and packet bounds. Replace old fully-uploaded-style-kit checks with explicit final-pack/readiness rules. |
| Finale | `src/shared/ChapterConcert.luau`; `src/client/ConcertView.luau`; `src/server/ConcertService.luau` | Play a pinned Finished Song from beginning to actual end. Replace the old shelf selection and six-loop completion; all banks use real admitted sound. |
| Story discoveries | `src/shared/DiscoveryCatalog.luau`, `QuayProgress.luau`, `NeighborhoodMissions.luau`, `FirstPerformanceQuest.luau`; `src/server/WorldBuilder.luau`, `QuayDemoService.luau` | Preserve I01/I02/I03 and earned flags, route semantic roles to approved replacements later, and prevent silent musical completion. |

An empty catalog currently crashes `Pattern.new`, keyboard handling, `AudioEngine` and parts of `WorkshopView`/`SampleEditor`. Fix those assumptions before removing the roster. In particular, handle `Catalog.Packs[1] == nil`, modulo by `#Catalog.Packs == 0`, absent labels and `Catalog.List[pad] == nil`.

### Audio resource budget

The current engine allocates four voices per selected musical sample. Multiplying that by 64 creates 256 personal musical voices before jam/listening/ambience. Implement bounded shared/lazy active allocation across every bank, with explicit voice stealing/choke behavior and retained tails. Loading only the viewed bank is not a valid solution because recorded events in other banks must still sound. Document the actual budget chosen; no budget here is claimed as a Roblox platform limit.

## 5. Preserve the chapter while replacing its audio

The existing narrative roles are `metal_hit` → I01, `vent_thump` → I02, and `robot_chirp` → I03. The new proposed slots are D01, D02 and D03 with stable new sample IDs. Keep I01/I02/I03 as the progression keys. Old sample IDs stay retired references; bind the discovery definitions to the new IDs only after those files are approved.

Naya's listening interaction also refers directly to `kick`, `closed_hat`, and `pluck`; `AudioEngine` preloads them as world previews. Replace these with semantic role lookups. Proposed final roles: A01 kick, A06 closed hat, C01 pluck. Do not point them to nonexistent audio and report success.

`Book.hasPlayableNotes()` currently checks unmuted steps, not audio readiness. Add a separate readiness condition for musical performances, listening challenges and quest evidence. Keep old completed milestones completed. During the audio gap, a new musical action should explain that the harbour sounds are being prepared. Do not add test sounds back just to make the gate pass.

The final pack contains 64 assets; three of them can retain the existing earned discovery gates. “Complete pack” means all audio is produced and mapped, not that progression ownership must be erased.

## 6. Remove bindings and prevent regeneration

| Layer | Paths and actions |
|---|---|
| Canonical binding data | `data/content-ids.json`, `data/content-ids.example.json`, `data/style-upload-manifest.json`, `data/audio-source-revisions.json`; retire musical records deliberately while preserving image/unrelated records. |
| Runtime projections | `src/shared/ContentIds.luau`, `LocalContent.luau`, `SampleWaveforms.luau`; no active old sample binding or waveform entry should imply availability. |
| Source manifests | `assets/production/upload-manifest.json`, `assets/production/audio/manifest.json`, `assets/candidates/audio/style-starters-v1/manifest.json`, `assets/candidates/audio/quay-found-v1/manifest.json`; mark historical music as archival and exclude it from the active content graph. |
| Local payload | `assets/local-demo/content/needle-quay/audio/`, `assets/local-demo/install-manifest.json`, `assets/local-demo/content-provenance.json`; rebuild the active package from the explicit allowlist, preserving the five separately inventoried cue/ambience assets as appropriate. |
| Installed Studio payload | Audit the installer namespace and old manifest before removing generated legacy copies. Do not recursively delete a shared Roblox content directory or unrelated local audio. |

Change the source of generation, not only generated output:

- `tools/project_style_packs.py` recreates the old style module and upload manifest from the old candidate manifest.
- `tools/package_local_demo_content.py` currently copies all 24 original audio files and all 160 style samples unconditionally, then regenerates `LocalContent.luau`.
- `tools/build_sample_waveforms.py` reads audio from the install manifest.
- `tools/configure_content.py` unions old production and style upload manifests. Its merge behavior retains existing IDs; supplying an empty Audio object does not purge them.
- `tools/package_needle_quay_demo.py`, `tools/install_local_demo_content.py` and `tools/Launch-NeedleQuay.ps1` must consume the active manifest and must not reinstall an old packaged audio payload.

Introduce one explicit active-content authority used by runtime projections and packaging. Before approval it can contain approved interface/ambience assets and zero active musical samples. After approval it can admit the single final pack. Historical source WAVs, source archives, receipts, manifests and audition tools may remain outside the active graph for provenance and recovery. Keeping an archive is compatible with removing every test pack from the game.

## 7. Completion criteria to record

These are future acceptance criteria, not a claim that tests were run. Follow the local repository's test restrictions.

- No retired musical kit appears or plays through browsing, hotkeys, discoveries, ambient previews, jam, concert, saved beats or packaging.
- An empty musical library opens safely and does not substitute test sounds.
- A/B/C/D are exclusively sound banks. Named sequences have no four-slot ceiling, and Song Mode is separate. Recorded bank A material continues while viewing bank B.
- Every old pattern and shelf bundle preserves its musical intent as imported sequences/draft archives, without substitution, truncation or automatic Finished Song creation.
- A multi-track, multi-sequence Song Mode draft and its Finished Song survive save/load with order, repeats, timing, kit settings and immutable versions intact.
- Pad FX on A01 do not affect B01; remote messages validate project/track/absolute-pad identity and reject inactive IDs.
- Already-earned discovery and story progress survives retirement. New musical achievements require real permitted audio.
- The final content admission requires 64 real approved WAVs, unique bank/pad addresses, measured metadata and explicit discovery-role bindings. Null/planned slots never count as content.
- No old generation or launch path silently restores the retired packs.
