# v3 copy and canonical contract review

30 October 2026. Local source/static review only; no Studio execution, uploads, provider spend, commit or push by this review.

## Corrections

- First Light pin guidance now requires the saved Finished Song from beginning to end. Optional loop sharing and Ronan/Q12 guidance distinguish saved sequences from the pinned immutable song performance. QuayStory was reviewed and already matched v3.
- The production compiler no longer writes a second positional list of legacy A/B, Shelf or six-phase quest conditions into canonical data. It projects the authored quest dictionaries unchanged, validates required contracts and preserves an existing authored README.
- `--quest-contracts-only` regenerates the quest JSON and register quest section, and refreshes only the existing quest JSON entry's `bytes` and `sha256` in the current integrity index when that index exists. Every other entry and top-level metadata is retained.
- Q06/Q07 canonical geometry anchors and the generator's corresponding visual-anchor phrase now say `sequence and song listening nook`. Runtime catalog regeneration remains owned by the coordinating agent.
- Supersession notices on older high-traffic play/package guides retain the original dated evidence and point readers to the current MPC v3 guide. Obsolete prerecorded Shelf guidance remains source provenance and is already suppressed at runtime.

## Integrity entry receipt

The prior current-index entry was:

```json
{
  "path": "assets/production/needle-quay/quest-world-contracts.json",
  "bytes": 14621,
  "sha256": "fab3016120f1d6224451fdcd74b3a7763b2d1fd796d9ac33734caece098a3d11"
}
```

The refreshed entry is:

```json
{
  "path": "assets/production/needle-quay/quest-world-contracts.json",
  "bytes": 16492,
  "sha256": "be3745da858091de46b0815fb173d0b824c7c7504201a4102ae9e9e8aec5cf1c"
}
```

All other integrity-index fields and entries were compared as parsed JSON and preserved exactly. This scoped refresh does not claim a new full production payload integrity audit.

## Verification

- Pinned StyLua 2.6.0 `--check --syntax Luau` passed for WardrobeCatalog, QuayStory, QuayObjectives and QuayConversations. Selene 0.32.0 reported zero errors, warnings and parse errors.
- Initial isolated narrow and full compiler checks preserved all canonical quest fields, unknown future fields, authored dimensions/IDs and an existing README; repeated outputs were byte-idempotent. Missing canonical completion contracts were rejected before projection changes.
- Final isolated narrow-mode checks included an existing index with additional target-entry metadata: only `bytes`/`sha256` changed. Every other entry and metadata field remained identical, repeated runs were byte-idempotent and an absent index remained absent.
- Actual narrow regeneration preserved source/README hashes, projected all 13 canonical quest dictionaries exactly, and matched the target integrity entry against the file's measured size and SHA-256. No broad production rebuild was run in the checkout.
