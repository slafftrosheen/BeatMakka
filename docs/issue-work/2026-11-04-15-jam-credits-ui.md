# Issue #15 — contributor-credit presentation
Date: 2026-11-04. Base: `99de13887b66e6c246250ef26174eb6e2065e2c0`.

The prior #15 batch creates a new ordinary Sequence and Draft Song with both consenting collaborators recorded as `contributors` metadata. This follow-up makes that attribution visible in the existing music workflow, rather than retaining metadata players cannot find.

- `SongArrangement.summarize` includes a bounded, explicit contributor projection for normal Draft listings, retaining the existing IDs/revisions/repeats/bars/duration fields. It guards optional/legacy malformed contributor shapes.
- `MusicWorkspaceCore.projection` reads contributor metadata from a deliberately finished Song's immutable captured draft project and includes names, roles and IDs in Finished library summaries. No extra finish or save operation is triggered.
- `DeviceSongScreen` identifies both contributors in the existing arrangement overview and keeps the bar/duration summary. The full label is also exposed through its existing accessibility attribute.
- `DeviceLibraryScreen` marks a credited Draft/Finished Song without losing the normal Draft bar count or Finished revision. The selection hint displays the names, even when a compact sleeve card truncates its detail.

This does **not** add a publishing, remix-permission or payout system. It preserves ordinary credit metadata through Project.clone and the current migration/import format. Credit does not imply a public release; finishing and saving remain separate explicit actions. No data-schema change, new UI asset, media generation, Roblox upload or Experience publication.

Source-only review: inspected current Project.summary, Song.summarize, FinishedSong.capture/edit-copy, MusicWorkspace projection and both client screens; anchored edits and GitHub blob/commit read-back. No Luau compilation/lint, tests, build, Studio, device or hosted save/rejoin evidence is claimed.

User-local acceptance: Keep a consented joint copy, open Song Mode, inspect two names; save and reopen the Draft; deliberately Finish and inspect its library sleeve; open an editable Finished copy and verify credit survives; test narrow text and controller focus. Confirm ordinary non-collaborative Songs remain unchanged. Actual delivery is documented by the linked commit and the #15 issue receipt.
