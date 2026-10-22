# Courtyard listening milestone

Follow-up: the subsequent authorized test/fix batch synchronized the complete source build and exercised runtime flows. Current results and limitations are in [runtime verification](RUNTIME_VERIFICATION.md); the original batch notes below describe its earlier source-only delivery.

Implemented locally on 22 October 2026, continuing the workshop milestone. Scope: I05 podium interaction, U03 listening status and W01 access ramp. No provider work, uploads, publishing, dependencies, commits or tests are included.

## Source decisions

- Visual Artbook v0.2 page 5 and Production Atlas v0.2 page 14 specify a 12 x 8 stage within a 28 x 24 courtyard. The existing graybox stage is preserved; a six-stud-wide access ramp now reaches its one-stud-high deck.
- The register's W01 build contract still says 24 x 1 x 20. `data/assets.json` preserves that authored contract and records the newer PDF prototype direction separately. Court clearance and final placement remain unreviewed; this is not a locked floor plan or asset acceptance.
- I05 uses the existing canonical master or the existing identified proxy path. No generated replacement or new asset ID is needed. Its contract requires readable join/listen and mute/leave without returning to the podium.

## Player flow

1. Make a loop at either workshop sampler. Enable at least one step on an unmuted pad.
2. Leave the station and approach the podium on the courtyard stage. Use **Share your loop**. The server copies and sanitizes the current pattern and starts a server-time transport. This is a fixed snapshot; it does not overwrite anyone's personal pattern or save.
3. Other players use **Join / leave listening** at the podium to opt in. Walk-by players receive no listening pattern and hear no courtyard bank.
4. The top listening panel shows the performer, BPM, audio availability and **Leave listening** or **Stop sharing**. The existing **Sound** control mutes both personal and listening playback. Leaving works anywhere, without a station or another podium interaction.
5. Sharing ends when the performer stops, respawns, disconnects, occupies a sampler, or leaves the explicit 32-stud podium range. Other listeners leave individually on the same lifecycle/range conditions. Position/life checks run on the server once a second; a proximity prompt alone is insufficient authorization.
6. Once sharing ends, the podium returns to idle and remaining listeners stop their voices. A new performer must explicitly start a new snapshot. There is no queue or automatic joining.

Local clients schedule the received snapshot against `Workspace:GetServerTimeNow()` using the same sixteen-step duration as the sampler. Missed ticks are skipped instead of replayed in a burst. A separate audio bank lets leaving listening stop courtyard voices without changing personal patterns. The current sound IDs remain unconfigured, so this source implementation does not establish audible playback or measured synchronization.

## Tool connection and delivery

- Studio MCP discovery returned the named `BeatMakaAssetReview.rbxl` instance in Edit mode, plus an unnamed second instance. A read-only hierarchy query found the expected Server, Client, Shared, AppearanceLibrary and UiImageLibrary roots in the named place.
- Official Workspace API documentation was refreshed through Studio MCP for `GetServerTimeNow`: https://create.roblox.com/docs/reference/engine/classes/Workspace.md. This supplies an approximate shared clock, not sample-accurate audio timing evidence.
- Repository fetch found HEAD equal to origin/main at `dff5dbc78dd0f3d4ffe30f552798b8788da25619` before changes. Pre-existing uncommitted workshop work was preserved.
- Root-resolved Rokit tools report Rokit 1.2.0, Rojo 7.7.0 and StyLua 2.6.0. No tool installation was needed.
- Source delivery is the local files and `work/FrequencyZero-Listening.rbxlx`. The connected review place was inspected only; it has not received this source batch. Open the new local place or use the existing Rojo workflow to sync it.

## Pending acceptance

No tests or Play sessions were run for this batch, following AGENTS.md. Two-player opt-in, stop/disconnect/range behavior, touch/keyboard/gamepad operation, banner text fit, ramp traversal, streaming behavior and audible timing remain unverified. Audio uploads/permissions, native persistent mesh imports, atlas art approval and cloud saves remain open from the workshop milestone. No asset stage was promoted.
