# Needle Quay — consolidated experience scope

This document carries the original experience work into the current music workflow. The aim is a coherent playable first area for young grooveboxers: meet people, notice the harbour, make music, develop a personal style and create a small gathering at the Lantern Room.

The supplied source implements a substantial experience layer. Its musical foundation still uses the old pattern model and requires the replacement in `MPC_WORKFLOW.md`. Distinguish source implementation, design targets and actual runtime acceptance throughout local integration.

## 1. Lore and chapter: A Place for Every Sound

The **Quiet Fade** is the gradual loss of shared creative habits. People became busy, hesitant or discouraged, and the neighbourhood stopped making things together. There is no combat villain or supernatural musical cure. The player's Roamer mobile studio gives them a way to listen, try ideas and make a new invitation.

The chapter connects practical resident concerns with the player's growing musical work. **Naya's blank sleeve is waiting for the next new song**, not a lost recording that must be reconstructed. Ronan worries about opening another empty room. The player's own finished song becomes part of a modest new evening; a large audience, a paid item or a performance rating is not required.

| Resident | Reason to care | Change the story should remember |
|---|---|---|
| Tori, dock master | Wants a usable, welcoming quay while work continues. | Recognises the loading-rail rhythm and offers help with the gathering. |
| Ivo, mechanic | Keeps polishing ideas instead of sharing them. | Accepts an original section and a different variation as worthwhile experiments. |
| Naya, archivist | Protects memories but needs to make room for new ones. | Offers the blank sleeve for the player's developing song. |
| Sana Bell, market coordinator | Wants people to participate comfortably without carrying every arrangement alone. | Makes room for playing, listening and taking a quiet break. |
| Mica, H04 helper | Can relay an invitation but cannot decide what the player wants to say. | Carries the player's invitation after the musical reply. |
| Ronan Wren, venue caretaker | Wants the Lantern Room to matter again. | Opens it for the player's finished song and a new gathering. |
| Nell Fen, café host | Gives neighbours a comfortable place to stop and remember. | Shares memories and provides a low-pressure alternative to the stage. |

Use short, replayable, authored dialogue with before/in-progress/after reactions and server-owned chapter evidence. Keep the player's dedication choice—curiosity, togetherness or beginnings—and the chapter journal. NPCs explain why something matters and respond to what changed; they should not merely dispatch a disconnected list of chores.

Alissia the Sound Collector and Nikolas the Beat Builder remain compatible optional-companion design targets. This archive does not supply newly completed follower AI, final models or voice performances. Keep any valid newer local companion work.

## 2. The musical story arc under Song Mode

| Milestone | Current meaning |
|---|---|
| First discovery / Q02 | Use I01 in the first playable named sequence. A sequence is a reusable musical section. |
| Optional sharing / Q03 | Share a loop if wanted; no public-audience or Finished Song requirement. Skipping remains valid. |
| Variation / Q05 | Save an original and a musically distinct named sequence. No fixed A/B musical slots. |
| Blank sleeve / Q07 | Save a Song Mode draft that begins to arrange sections. It need not be finished yet. |
| Mica's reply / Q09 | Use I03 at the specified quarter-note positions of the chosen teaching bar, as detailed in the MPC contract. |
| Prepare the room / Q11 | Select a successfully saved, ready Finished Song. |
| Gathering / Q12 | Perform its pinned immutable revision from beginning to its actual end, with pauses handled honestly and no skipped intervals counted. |

The old six compulsory loop-mutation phases are superseded. Dramatic cues may accompany the arranged song, but they must not force a player to change the composition six times. Award completion from the actual eligible performance, preserving the existing canonical quest/reward IDs and idempotent grants.

The Flow-produced vocal demo is a sound-pack production reference. It is not the player's song, a quest shortcut or a replacement for their composition. The user may make instrumental music with the eventual pack; vocal pads are creative options.

## 3. Four supplied optional activities

| Activity / stable ID | What is supplied | Preserve during the refactor |
|---|---|---|
| Memory Walk / `memory_walk` | Short memories associated with the café, ferry office and Lantern Room. | Spatial discovery, saved visits, first-time recognition and Nell's connection. |
| Sound Safari / `sound_safari` | Collection of the existing I01/I02/I03 virtual sources. | One discovery ledger; their final pack slots remain D01/D02/D03. |
| Pattern Bench / `pattern_bench` | An untimed visual symbol-sequence puzzle with retries. | Its internal name and puzzle state; this is unrelated to the obsolete musical pattern slots. |
| Sleeve Studio / `sleeve_studio` | Three curated motifs and three palettes for a saved sleeve design. | Saved creative choices and rewards; add explicit cover copying to drafts/new finished revisions under the MPC contract. |

Side activities remain optional and offer different actions: observation, collecting, logic and design. Place them at usable existing counters, benches and notices. Do not claim that a scenic building shell has an accessible interior. Keep non-audio activities useful for players who take a break from music.

The broader bible also describes Patch Table, a dedicated Open Table, Ferry Spotter and expanded Afterglow content. Those are future targets unless they already exist in the user's local work; do not report them as implemented by this archive. Existing concert replay can remain useful without being advertised as a new mini-game.

## 4. RPG identity and rewards

Preserve the nonexclusive **Listener, Beatmaker and Neighbour** paths. Players can advance in all three through exploration, musical development and helping the gathering. No irreversible class choice or musical power stat is needed.

The supplied `QuayIdentity.luau` owns the finite first-time ledger: **210 Listener + 180 Beatmaker + 185 Neighbour = 575 XP**. Keep award IDs, amounts and idempotence during migration. Derive recognition from trusted existing progress and bounded activity records. Replaying an activity must not mint unlimited rewards, and migrated profiles should retain what they earned.

Overall ranks are New Voice at 0 XP, Quay Regular at 70, Beat Explorer at 180, Neighbourhood Artist at 340 and Lantern Resident at 500. Each path has Curious/Practising/Finding your voice/Quay regular levels at 0/30/75/130. The local canonical catalog remains the authority if the user has since tuned it deliberately.

Preserve titles and earned items, including Sound Scout, Beat Builder, Good Neighbour and the chapter's Quay Original title and First Light pin. Q03's optional social invitation is not an XP source. No rewards depend on spending, audience size, friend count, chat volume or ratings.

Core pads, sequencing and musical capability are available without RPG stat gates or purchases. The supplied implementation has no soft-currency wallet, daily streak or paid progression multiplier; do not add one merely to make the demo look more like an RPG.

## 5. Wardrobe and appearance

The supplied catalog contains **16 candidate accessories: two starter, eight earned and six premium**. Its four supported slots are head, neck, back and pin. Preserve inspect/equip/remove, three free outfit presets, the on-demand rotating mirror and reset of BeatMakka accessories.

Keep the base Roblox avatar and unrelated saved appearance. Store canonical owned item IDs, not arbitrary client asset IDs. Equip/ownership is server-authoritative, unavailable assets fail visibly, and lifecycle cleanup must remove only this system's attachments. Roamer/MK-I finish settings remain separate.

The current mirror shows the equipped avatar. A full unowned-item try-on system, final layered clothing, final art approval and account-avatar changes are not completed by this archive. The local completion report must describe the actual visual and persistence stage. Preserve useful newer local wardrobe work rather than reverting to these minimums.

## 6. Cosmetic shop

Keep the source shop and ownership flow for **Harbor Afterglow** and **Workshop Weekend**, each with three guaranteed cosmetic items. The proposed **99 Robux** per bundle is planning data, not a live price. Real enabled offers must obtain the displayed price and purchase flow from the configured platform product rather than trusting a client-provided amount.

Sales remain disabled: production pass IDs and approved asset setup are not supplied. Preserve server-confirmed permanent ownership, clear owned/unavailable states, explicit retry after failed lookups and the native purchase flow when properly configured. Do not infer ownership from a client completion message.

Paid items do not provide pads, musical ability, story completion, XP, better quest scores or friendship. Earned story items remain earned. Preserve `COMMERCE_SETUP.md` as the implementation/configuration guide, subject to current local project instructions. Pass creation, purchase testing, shop activation, uploads and publication are separate work requiring the user's relevant authorization.

## 7. Presentation and world scope

Keep the journal's **Story / Explore / My style / Shop / City** surfaces, short dialogue pages, expandable hints and remembered milestones. The sampler needs progressive teaching and full musical capability: clear sound-bank controls, a named sequence selector, an arrangement view and distinct save states.

Needle Quay is the playable area. Other districts remain clearly unavailable rather than false travel destinations. Preserve the warm established instrument/world design, Roamer identity, canonical IDs, actual source assets and supplied art authority. No new paid or generated visual production is included in this task.

## 8. Supplied implementation and completion boundaries

The original 19-file experience change is listed in `merge/BASELINE.json`:

- Shared story, activities, identity, wardrobe and commerce catalogs.
- Server experience, wardrobe and commerce services plus existing service/profile integration.
- Journal, wardrobe preview and shop panels plus the demo view integration.
- The original bible, implementation notes, commerce setup and README changes.

There are 93 Luau files in the 102-file source snapshot for context, with five exact existing-file bases and the original patch. Treat those as merge inputs; they are not evidence of a local merge or runtime acceptance.

The local agent must integrate the experience, implement the whole-game MPC model, migrate saves/consumers, retire test packs and prepare the pending final-pack interface. It can complete that code while song/sample approval is pending. It must report blocked musical readiness honestly until actual approved audio is available.

Runtime/device/persistence/listening acceptance remains unverified in this handoff. Follow the user's local test restrictions and distinguish actual inspection from running tests or Studio. Preserve staged/unstaged/untracked work, and do not commit, push or publish.

## Source basis

The counts, character relationships, progression and implementation status above come from the supplied `source_snapshot/src/shared/QuayStory.luau`, `QuayActivities.luau`, `QuayIdentity.luau`, `WardrobeCatalog.luau`, `CommerceCatalog.luau` and the three documents in `source_snapshot/docs/needle-quay/`. Musical changes and precedence are defined by this archive's top-level MPC and first-pack contracts.
