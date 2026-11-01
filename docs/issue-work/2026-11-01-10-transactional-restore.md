# Issue #10 — transactional restore and recovery

Restore now constructs the proposed saved workspace plus a recoverable pre-restore project before mutating the live profile. It validates the full music document and checks the existing serialized save budget. On validation or capacity failure, the current project remains unchanged. On success, stale undo/redo and queued note deltas are cleared so old edits cannot be applied to the restored workspace.

The recovery copy is retained in the existing `recoveryProject` field. No new format or storage service is introduced.

## Local verification required

- Save, edit, restore, then open the recovery project; compare events and sample IDs.
- Verify an oversized recovery candidate fails without changing the live project.
- Verify old undo/redo history cannot mutate the restored project.
- Verify a save after restore and a real hosted rejoin separately.

No Studio/device/hosted acceptance is claimed.
