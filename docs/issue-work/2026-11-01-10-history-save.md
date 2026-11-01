# Issue #10 — Undo/redo saved-revision reconciliation

Source fix: history restores an older project snapshot while assigning a new project revision. Previously it also restored stale per-sequence and draft `savedRevision` markers, so the UI could claim an outdated save baseline after undo/redo. Existing sequence/draft IDs now inherit the current persisted baseline while their edited revisions remain unchanged. Newly restored IDs retain their own metadata until saved.

No new schema, storage endpoint or cloud claim. Confirm in Studio: edit → save → edit → undo → redo, including multiple sequences and draft Songs; verify dirty indicators and saved revision, then reopen. Hosted rejoin/conflict remains a separate release gate. No tests/builds run in this remote change.
