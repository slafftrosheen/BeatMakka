# Issue #10 — complete workspace-transition and history transaction batch

Base: `25e9b1bd5b53358cf70f31394228f02ea9e4ce66`. Scope: the existing personal-music workflow in #10; supports #6 without introducing another save format, beginner engine, storage service or asset dependency.

## Design and implementation

The earlier fixes covered individual paths. This batch makes saved restoration, recovery opening and finished-song editing use the same workspace boundary, while keeping the existing music model, transport resolver and persistence backend.

The shared `WorkspaceState` module has four responsibilities:

- `same(a, b)` compares the complete stored musical structure, ignoring only `savedRevision` acknowledgements. Revision numbers, stable IDs, events, sample references, mixes and all other values still compare exactly.
- `preserve(music, project, exchangeId)` preserves an exact project version, not the first archive with a matching project ID. Unchanged versions can reuse an existing snapshot. Opening an editable workspace archive may exchange that slot with the current workspace, so normal navigation does not continually consume archive capacity. Read-only migration sources are never overwritten. New versions receive unique archive IDs under the existing migration limit.
- `activate(profile, music, selected)` is the no-yield commit point after validation/capacity checks. It resolves selection, stops playback and recording, clears the old transport and queued sequence, disables held-note repeat, invalidates old recording epochs, clears pending notes/deduplication/history, and increments the in-memory workspace generation and edit version.
- `history(current, source)` materializes Undo/Redo as a new validated revision. Project, sequence, draft, track and program revisions advance beyond both snapshots; the ID allocator never rewinds. This avoids a later different edit reusing the revision of a save still in flight. History restores are new unsaved revisions even when musical content resembles an earlier saved version.

## Connected command paths

`MusicWorkspace` now owns the Restore command through its existing `handles`/`command` dispatch. A stale confirmation returns an explicit message without stopping playback. A rejected restore no longer falls through to the older service-level unconditional Stop behavior.

FinishedOpen, ArchiveOpen, RecoveryOpen and Restore reject workspace replacement while a save is pending. Ordinary editing during a pending save remains available. All successful replacement paths validate the proposed complete document before committing. Failure preserves live music, recovery data and edit history.

FinishedOpen no longer writes history before its capacity gate. The editable copy is opened with the old transport/history invalidated, while the immutable finished revision stays in the library.

RecoveryOpen preserves the current workspace, opens the retained copy, and consumes the recovery slot only in the validated candidate. A subsequent Restore is therefore possible. Saving alone does not discard recovery data; the explanatory message now says so.

Restore reinstates the saved sequence/track/draft selection when it is still valid. Current earned progress and finished songs remain in the music library. `ProfileStore.capture` accepts an optional selection argument so size/validation checks describe the selection that activation will actually install.

Archive projection follows `archiveOrder` rather than unordered map iteration. Delayed title-filter results compare the originating project object, preventing a result from applying to a different workspace that happens to have the same numeric revision.

## Save acknowledgement

`ProfileStore` is now the sole writer of save acknowledgements for SaveProject/SaveSequence/SaveDraft. The redundant command callback that compared only item IDs and revisions has been removed.

An acknowledgement checks workspace generation, exact musical contents and routing dependencies before marking a sequence or draft saved. Undo/Redo during storage I/O cannot make a different revision look saved.

When an override captured earlier no longer matches the current music document, the saved edit version is the in-memory dirty sentinel `-1`, not the current edit version. The saved snapshot is retained, but newer live work remains visibly dirty until a fresh save. This value is not persisted and does not change the storage schema.

Conflict messages no longer advise leaving/rejoining while unsaved work exists. Existing revision-based UpdateAsync protection remains in place; conflicts do not overwrite storage.

## Compatibility and boundaries

Profile schema stays 3; music schema stays 1. Existing DataStore name, sample identities, A–D banks, independent sequences, Song arrangements, progression and asset bindings are unchanged. `workspaceGeneration` is runtime state/projection metadata, not another storage schema. Existing project/archive/byte limits are reused. No new dependencies, test suites, CI workflows, Roblox uploads or publishing are included.

This batch implements the described code paths. It does not establish complete #10 acceptance, hosted save durability, device input quality, acoustic timing, or novice First Groove usability.

## Verification status

Source-level review and GitHub diff/branch read-back are the verification boundary for this remote batch. No test suite, Luau linter, Roblox Studio build, device test, or live DataStore operation was run. The execution environment has no project-pinned Rokit/StyLua/Selene binaries; no substitute toolchain was installed. Runtime outcomes below remain unobserved, not reported as passes.

## Local acceptance scenarios — no additional implementation requested

1. Save a multi-bank sequence and draft Song, change the chosen sequence, then Restore. Confirm the saved selection and exact events return while the pre-restore project is retained.
2. Open that recovery, then Restore again. Confirm the recovery slot is consumed only after opening and both musical versions remain available.
3. Play/record or enable Note Repeat, then open a finished-song edit copy or an archive. Confirm the old transport, repeats, queued sequence, recording requests and Undo/Redo do not affect the new workspace.
4. Create two different versions with the same project ID. Navigate among editable archives and confirm no unrelated version or read-only migrated source is overwritten. At the archive limit, exchanging an editable slot should still work; an additional retained version should fail without mutation.
5. Delay an isolated save, then Undo, make a different edit, and Redo where applicable. Confirm project/item revisions and nextId never rewind, and only the captured version is acknowledged.
6. Attempt Restore with an outdated editVersion and attempt all workspace replacements during a pending save. Confirm rejection is explicit and existing playback/music stays intact.
7. Fill the recovery/project byte budget and attempt each replacement. Confirm the entire operation is rejected rather than partially clearing history, removing recovery, or changing selection.
8. In an authorized isolated hosted environment only, verify actual exit/rejoin, conflicts and uncertain write outcomes. The current no-publish/no-production-profile policy is unchanged.
