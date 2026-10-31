# Local Codex task v3 — complete the Needle Quay playable experience

## User instruction and deliverable

Integrate the full Needle Quay experience into the user's local project, remove every old test musical pack, and implement **four sound banks / 64 samples across the whole game**. The user explicitly replaces the old A/B/C/D pattern model with a proper MPC-style workflow: reusable named sequences, Song Mode and a clear finished-song concept.

**Perform the implementation in the actual local code. A plan, documentation-only update, four renamed buttons or a disconnected arranger mockup is not completion.** This archive supplies the original experience source/context plus the consolidated work order; the MPC replacement and test-pack retirement are not already implemented here.

The user sent a separate Flow Music prompt to the music agent. A shorter vocal correction has been supplied to the user, but its forwarding and final song/pack approval have not been reported. The current creative direction requires clean original vocals about Needle Quay. Keep honest pending-audio states and do not start another music-generation task.

## 1. Preserve the actual working copy

Read its current `AGENTS.md` and `CODEX_START_HERE.md`. Record HEAD/branch and inspect staged, unstaged and untracked work. Make a reversible local backup of affected source and metadata before merging, including both tracked diffs and relevant untracked work. Do not expose credentials or upload the backup.

Do not reset, clean, automatically stash/rebase, force-apply, overwrite the snapshot wholesale, or commit the user's changes. A read-only fetch does not justify a dirty-tree pull/merge. Keep unrelated local work intact.

Incoming experience baseline:

`8e8b91f6a5472eb6200599e60932e45a8c9ea56b` — `Collect local Needle Quay and groovebox work`.

The local project may already be ahead. Compare the actual current branch and remote state through read-only inspection/fetch if available; do not claim that this historical snapshot is the latest local source. Preserve useful newer implementations, including bank or Song Mode work begun from earlier handoffs. Integrate into that work rather than rolling it back.

## 2. Merge the original experience implementation selectively

`merge/BASELINE.json` identifies 19 changed/new source and documentation files. Compare:

- Base: `merge/base/<path>` for the five modified existing files.
- Incoming: `source_snapshot/<path>`.
- Local: the real working tree, including uncommitted edits.

The existing files are README, QuayDemoView, MusicService, ProfileStore and QuayDemoService. New incoming files may already exist locally; merge those too. The rest of the 93-file source snapshot supplies context.

The original patch remains exact for review. A successful `git apply --check` does not prove compatibility with newer local behavior. Do not use the user's staged index as a scratch merge area.

Retain **A Place for Every Sound**, side activities, Listener/Beatmaker/Neighbour recognition, earned cosmetics, wardrobe, three outfit presets, avatar mirror, disabled cosmetic shop, Roamer and world relationships. `EXPERIENCE_SCOPE.md` consolidates the supplied implementation and remaining targets. Adapt its musical consumers to the current contract. Keep server-authoritative ownership, profile safeguards and service cleanup.

The playable result should connect the residents' motives to the player's musical choices: discover the Quay, build sections, arrange an original song, invite the neighbourhood and perform it at the Lantern Room. Keep the four implemented side activities useful outside the main route. Preserve the finite first-time progression ledger, free core instrument, earned wardrobe path, in-world appearance feedback and cosmetic-only commerce. Do not reduce this handoff to an isolated sampler refactor.

The original bible/source contain A/B patterns, bundled Beat Shelf entries and a six-loop finale. Those are baseline behaviors to migrate. **`MPC_WORKFLOW.md` overrides them.**

## 3. Implement the MPC workflow as one system

Follow `MPC_WORKFLOW.md` and get as close to its MPC sequence/Song Mode workflow as the real game can support:

- 16 physical pads, four sound banks A–D, 64 absolute pad addresses.
- Sound banks only change pad view/input. Hidden-bank notes continue; delayed input retains its original absolute identity.
- Kits/programs define sounds and pad edits. Tracks are musical parts with stable routing; the 64 pads are not 64 sequencer tracks.
- A named sequence library replaces four fixed pattern slots. Support multi-bar recording, overdub, velocity, timing controls, duplication, edits and undo.
- Next Sequence queues live transitions independently from ordinary editing and bank selection.
- Song Mode arranges stable sequence references and repeat counts into a finite piece with meaningful position, duration and end behavior.
- Save Sequence, Save Draft and Finish & Save Song are distinct operations.
- A Finished Song is a successfully saved immutable musical revision; later source edits and active performances cannot mutate it.
- Convert to Sequence is non-destructive and distinct from audio export. Only expose audio export with a functioning renderer/delivery path.
- One event/transport model serves the instrument, listening, jam, stage and finale. Remove hidden first-16/four-pattern paths.

Use `SongFinish`; the existing `Finish` action is cosmetic. Retain separate editor/storage/object revisions and transport epochs.

## 4. Migrate old music without changing it

Preserve the four working patterns and every one of the six four-pattern shelf bundles. They may have independent BPM, assignments, mutes and edits. Import them as named sequences and isolated draft projects/archives, retaining exact sound identities as unavailable where retired.

Do not infer a song order from A/B/C/D slots, merge different legacy pad maps into one mapping, or turn imported shelves/old concert progress into Finished Songs. Preserve recoverable preimages and new post-migration work. Migration must be idempotent; older writers must not truncate the new schema.

Keep discoveries, quest history, XP, titles, wardrobe and unrelated appearance presets. Capacity limits reject operations clearly; they do not discard music.

## 5. Update the complete playable experience

Use the revised Q00–Q12 mapping and dependency list in the current contract:

- Q02 teaches a first sequence; Q05 saves an original and a distinct variation.
- Q07 introduces a saved Song Mode draft, without forcing a finished song prematurely.
- Q11 selects a valid saved Finished Song; Q12 performs that revision from beginning to actual end.
- Optional loop-sharing remains a loop activity, with no finished-song or public-audience requirement.
- The six old concert phases become presentation/optional cues, not six compulsory loop mutations.
- Update canonical data, generated catalogs, dialogue, journals, instrument help, library, stage/listening UI and current docs together.
- Sleeve Studio attaches a copy of a cover deliberately; it cannot finish music or alter all previous song covers.

The player creates and performs their own song. The Flow-produced demonstration is a pack-production reference, not an automatically completed player song.

## 6. Retire test packs and prepare final content

Execute `REMOVE_TEST_PACKS.md`. Retire the ten style packs, original generic Quay musical audio and additional unapproved local test packs from every active route and packaging source. Preserve archival provenance and unavailable saved references. Do not remove unrelated world materials, image bindings or separately inventoried UI/ambience audio.

Use `FIRST_PACK_SPEC.md` and `FIRST_PACK_64_SLOTS.json` for the proposed 64-sound map. I01/I02/I03 stay canonical, planned at D01/D02/D03. Bank D is now Harbour and vocals: D01–D12 harbour sounds, D13 Needle Quay call, D14 response, D15 short vocal phrase and D16 rhythmic vocal hit. These replace the old D13–D16 effects; do not append four extra samples or move the discovery IDs.

The song is an original vocal drum-and-bass demo, proposed at 174 BPM in D minor, about 2:35, with clean UK MC verses and a Needle Quay call-and-response hook. Exact words, cuts, timing and pitch await the approved song. Full vocal stems stay in production sources outside the 64 runtime files. Do not retain old one-bar-riser duration assumptions for the new vocal slots.

If local work already assigned or bound the previous D13–D16 placeholders, preserve a recoverable preimage and flag those mappings for deliberate reconciliation; do not silently replace a player's planned splash/riser with a vocal. The new planning revision is not sample approval or an automatic save migration.

No old sound is relabelled as final. Until approved audio arrives, draft editing may work while readiness honestly reports pending content. The user approves the demo before the 64 one-shots are produced; admit real samples only with actual metadata, provenance and approval. Missing audio must not block the rest of the authorized implementation work.

Planned slots are not loaded audio and cannot satisfy a new Finished Song or performance-readiness check.

## 7. Cadence and completion report

Work in coherent batches: model/migration; commands/transport; instrument/Song Mode/library; world/quest/finale; content cleanup; consistency pass. Follow pinned tools and test restrictions. Do not add/run test suites unless the user separately requests verification. Distinguish actual static checks from pending Studio/device/listening acceptance.

Report code changed, local edits preserved, retired samples, migration behavior, new save semantics, all consumers updated and real remaining gaps. Address the completion criteria in `MPC_WORKFLOW.md` with honest evidence/status. Include the experience, wardrobe/shop and vocal-pack integration status. Do not claim runtime success from documentation or static review.

No commits, pushes, Roblox uploads/publication, paid generation, pass creation or shop activation are authorized. Complete unrelated authorized work before asking about a genuine specific conflict; routine implementation choices do not require repeated permission.
