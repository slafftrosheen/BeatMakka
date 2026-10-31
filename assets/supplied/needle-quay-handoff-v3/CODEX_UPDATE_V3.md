# Consolidated change instruction — v3

This is the complete replacement handoff for Needle Quay. Keep valid current local work. If a previous ZIP is already integrated, do not blindly reapply its source patch.

## All current requirements

1. **Build the playable experience around A Place for Every Sound.** Preserve the residents' motives, Roamer, story journal, four supplied optional activities, Listener/Beatmaker/Neighbour progression, earned wardrobe, three saved looks and cosmetic shop implementation. The shop remains disabled until real production setup and separately authorized activation.
2. **A/B/C/D are sound banks only.** Sixteen physical pads address 64 program pads. Bank selection changes input/view, not sequence, kit, transport or sounds already playing.
3. **Replace the four fixed musical patterns with named sequences.** Support tracks, multi-bar record/overdub, velocity, timing controls, edits, duplication, undo and more than four sequences.
4. **Implement real Song Mode.** Arrange stable sequence references and repeat counts; insert, move, duplicate and remove steps; show position, bars and duration; stop at the actual end.
5. **Keep Sequence, Song draft and Finished Song distinct.** Finish & Save Song validates and saves an immutable arrangement and its dependencies. Later sequence, kit, mix or cover edits cannot mutate an existing finished revision.
6. **Keep live Next Sequence, Convert to Sequence and audio export separate.** Queueing is a performance operation. Conversion creates an editable sequence. Saving arrangement data is not rendering an audio file.
7. **Migrate every music consumer and old save safely.** Preserve the four working patterns, six shelf bundles, tempo, maps, notes, mutes and edits as named sequences/imported drafts. Do not infer a song order or auto-finish them. Update the instrument, input, effects, transport, library, saves, jam, listening, stage, quests, canonical/generated data, dialogue and finale.
8. **Use the revised story evidence.** Q07 saves a Song draft; Q11 selects a ready Finished Song; Q12 performs that pinned version to its actual end. Early loop sharing stays optional. Preserve earned progress. Retire the old compulsory six-loop finale mechanics.
9. **Remove every legacy musical test pack from the active game and its generators/installers.** Preserve provenance and unavailable historical references. Keep separately inventoried non-musical UI/ambience and unrelated visual bindings.
10. **Prepare one final first-area pack of exactly 64 one-shots.** A: drums; B: bass; C: melody/harmony; D: harbour and vocals. The original vocal demo must be approved before sound production; actual audio is not supplied here.

## Latest amendment: vocals, still 64 samples

The full song now requires clean original UK MC verses about Needle Quay and a memorable call-and-response hook. Suggested words are “Needle Quay” and “We make waves”; the approved song determines the actual cuts.

| Slot | New planned role | Replaces the earlier planned role |
|---|---|---|
| D13 / 61 | Needle Quay vocal call | Small wave splash |
| D14 / 62 | Vocal response | Lamp switch click |
| D15 / 63 | Short vocal phrase | One-bar uplifter |
| D16 / 64 | Rhythmic vocal hit | One-bar downlifter |

D01/D02/D03 remain the I01/I02/I03 discoveries. All four vocal slots are finite one-shot utterances/hits, not full verses or repeating vocal loops. Exact text, length, pitch and source files remain unapproved. Song effects may still exist in the full mix without occupying a runtime pad.

The planning contract advances to revision 3 while retaining its schema 2 address structure. Sample IDs/addresses remain stable for the proposed slots. Reconcile any pre-v3 local placeholder assignments deliberately; a planning change does not authorize silent changes to saved work.

The documentation example deliberately changes its outro ambience event from D13 to D12 (water drop) so the old splash does not accidentally become a vocal performance. It remains an uninstalled pending-audio draft, not the Flow demo or a Finished Song.

## Authority and status

Read `LOCAL_AGENT_TASK.md`, `EXPERIENCE_SCOPE.md`, `MPC_WORKFLOW.md`, `REMOVE_TEST_PACKS.md` and `FIRST_PACK_SPEC.md`. JSON contracts mirror these requirements. The concise music-agent prompt remains outside the ZIP.

The 102-file source snapshot and seven original merge inputs are unchanged from v1/v2. They contain the original experience implementation, including legacy music code. The whole-game MPC replacement and content retirement are local Codex implementation work, not completed code in this ZIP.

Keep the user's uncommitted work. Do not reset, clean, force-apply, commit, push, upload/publish to Roblox, spend on generation or activate commerce. Follow the actual local project instructions and report implemented behavior separately from pending Studio/audio acceptance.
