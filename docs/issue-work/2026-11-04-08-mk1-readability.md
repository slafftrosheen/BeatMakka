# Issue #8 — MK-I sample-bank and save-status readability
Date: 2026-11-04. Base: `1855fdc021ee3138c1b0516a86d33b8541afb6a5`.

## Reconciled model
The latest MK-I source already has fixed 16 performance pads, selected pad addresses A01–D16, independent named sequences and a distinct Song screen. This work improves clarity *inside that implementation*, not another UI rewrite. It uses the same W.key/UI text system under every approved hardware material finish. No atlas, material, Lottie, mesh, audio ID or approved cosmetic field changes.

## Code
- `DeviceGrooveboxView` explicitly labels the four **SAMPLE BANK** controls A DRUMS / B BASS / C VOX / D QUAY. Their selected states and accessible names identify banks as *sample addresses*, not four patterns.
- An independent high-contrast `MusicContextRail` now shows current transport (STOPPED/PLAYING/RECORDING), accurate profile save state (SAVING SNAPSHOT, SAVE UNAVAILABLE, UNSAVED CHANGES, NEW/NOT SAVED, SESSION SAVED or SAVED), current sample bank and selected absolute pad, and the selected object kind/name (SEQUENCE vs DRAFT SONG, LIBRARY, SOUND or SETTINGS). A queued next sequence is labelled. Long titles have explicit end truncation for visual containment, but the complete context remains in `AccessibleLabel`.
- The rail follows optimistic bank switching and pad selection immediately, then reconciles normal server acknowledgements. It cannot change notes, track routing, transport, save identity or project state. Machine-readable panel attributes make the visible bank/address/status inspectable without parsing graphics.
- The rail occupies **only** 24 pixels of the editor viewport, after the fixed navigation row, when the editor deck height is at least 240px. For extremely short decks it is hidden rather than squeezing functional sequence controls, while explicit bank labels, pad addresses, song/sequence pages and transport controls remain available. The physical playing deck, hitboxes and bottom transport geometry remain unchanged.
- `DeviceSkin.pad` now makes the source readiness caption visible when the pad is large enough, and reports **READY** only for an available approved source, **LOCAL** for available but unapproved Studio/local content, **PREVIEW** for catalogued preview metadata without current audio readiness, or **NO AUDIO** when neither is available. MUTED is still explicit. Earlier code incorrectly reported READY solely because preview metadata existed; that is removed.
- The pad's ordinary visual label and an explicit accessible description now include exact bank/pad, full sample name and truthful readiness. A tighter caption/status separation avoids their previous overlap at larger target sizes.

## Constraints and non-claims
The same 16 fixed pad hit regions, A–D/64 event identity contract, independent sequences, Song Mode workflow, material atlas bindings and cosmetic isolation are preserved. No new dependencies, CI/tests, paid assets, Roblox uploads or Experience publication.

**Source/static review performed:** inspected `DeviceGrooveboxView`, `DeviceWidgets`, `DeviceSkin`, `HardwareFaceplate`, `DeviceAppearance` and state projection. Anchored edits, no trailing whitespace in inspected blobs, exact changed-file comparison, non-force branch lease and remote read-back will be recorded in the linked commit. No Studio, actual color-contrast measurement, Luau compile/lint, live playback, touch/controller, two-player, human readability or cloud save/rejoin acceptance was run. Do not label this full issue acceptance.

## Local acceptance
1. Under all four approved finishes, with normal and dusk lighting, inspect A–D labels, selected pad, named sequence versus draft Song, next-sequence queue and NEW/UNSAVED/SAVING/SAVED states.
2. Confirm that a missing/unapproved musical sample never reads READY based only on preview metadata. Validate LOCAL vs PREVIEW vs approved READY against actual Studio output and the final #21 palette.
3. Switch banks with a held sample and a live sequence playing; verify notes/transport stay stable and the readout reflects the new bank without a replay restart.
4. Inspect phone portrait, short landscape and controller focus. The rail must not cover navigation or reduce physical pad target sizes; on extremely short editors it intentionally yields space back to controls.
5. Test an unavailable save, a failed save, save/reopen and a retained legacy sequence. Actual server acknowledgement controls the saved status.
6. Reconfirm room/finish owner isolation from #11 and separate hosted/DataStore acceptance (#10) and final audio playback admission (#5/#21).

Keep #8 open for gameplay-distance visual evidence and actual four-finish/device readability.
