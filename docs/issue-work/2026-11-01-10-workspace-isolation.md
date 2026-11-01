# Issue #10 — Archive/recovery workspace isolation

Opening an archive or recovery workspace now stops and invalidates the previous transport, clears undo/redo stacks, pending note deltas and recording history epoch, then synchronizes the newly selected project. Previously an old transport reference and old history could survive the workspace replacement, allowing subsequent undo or note updates to address the wrong project.

The existing archive preservation and size gate are retained. No new storage format or cloud API.

Local Studio verification: start recording, open an archive/recovery workspace, confirm transport is stopped and the old sequence cannot be modified by undo/redo or delayed notes; verify the previous workspace is still available in the library. Hosted rejoin is not verified here.
