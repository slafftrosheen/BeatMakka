# Needle Quay playable experience — implementation handoff

**30 October 2026. Supplied historical baseline: `8e8b91f6a5472eb6200599e60932e45a8c9ea56b` on `main`.**

This change gives the existing local demo a chapter, optional neighbourhood activities, a musical identity system, a wearable wardrobe and a closed-by-default cosmetic shop. It is source implementation. Roblox Studio playability, device layout, live persistence, final accessory art and commercial acceptance have not been established by this change.

Read the [experience bible](PLAYABLE_EXPERIENCE_BIBLE_2026-10-30.md) for the full story, character motives, pacing and future content. Read [commerce setup](COMMERCE_SETUP.md) before configuring any purchase. The existing deployment instruction in `AGENTS.md` still applies: local/Git work only; no uploads or publishing from the testing account.


## Current musical integration (v3)

The original source snapshot remains intact for provenance. Its A/B/C/D musical slots, Beat Shelf requirements and six compulsory loop mutations are superseded in the integrated runtime sources:

- Q02 reads ready I01 events at four distinct positions in named sequences across all 64 addresses. Q05 compares audible saved sequence content, excluding names, IDs, unused pad edits and muted routes. Q07 requires a successfully saved Song Mode draft containing an owned saved ready sequence.
- Q09 checks only the selected sequence and explicitly selected teaching bar, at relative ticks 0/960/1920/2880. Other bars and unrelated instruments do not affect its answer.
- Q11 selects a successfully saved, ready Finished Song with two musically different sections and a collected sound layered with another part. Q12 pins that immutable ID/revision, plays the complete shared schedule and awards completion only after actual end plus the authored two-second tail. Pauses freeze position; stop/leave cancels incomplete traversal. The former six ideas are presentation cues.
- Optional courtyard sharing, resident FX commissions and companion notebooks use typed saved sequences. A loop is not a Finished Song. Commissions resolve the same finite schedule and no longer read six shelf bundles or only the first bank.
- The first pack remains 64 planned addresses with pending approved audio. Planned samples cannot satisfy new musical readiness, record listening, finished-song or finale checks. Existing earned quest, XP, title, activity and wardrobe history is retained without creating phantom Finished Songs.

The identity ledger remains finite: 210 Listener + 180 Beatmaker + 185 Neighbour = 575 XP. Outdated prerecorded A/B/shelf/finale guidance is retained as source provenance but suppressed at runtime; revised instructional text is shown without generating replacement speech. Discovery nodes and companion hints reference canonical planned D01/D02/D03 IDs and readiness. Core music is free. Commerce remains disabled and no pass/asset was created, uploaded or published.

## 1. What changed

### A chapter around the existing music

**A Place for Every Sound** uses the established Quiet Fade and all existing P1–P4 / Q00–Q12 IDs. An old open-call card leads the player to the Lantern Room. Tori remembers a dock rhythm; Ivo needs permission to finish an imperfect idea; Naya reveals the last blank sleeve was meant for the next gathering; Sana makes room; Mica carries an invitation; Ronan admits he is afraid of opening an empty room. The player finishes with their own successfully saved immutable Finished Song, performed from beginning to its actual end.

`QuayStory` selects dialogue from server-owned quest completion. A new player receives the brief opening journal; it can be closed immediately. The journal shows short dialogue pages and an expandable practical hint. The full task ledger is expandable, and completed entries become memories of the player's contribution. A three-way concert dedication is a persistent expressive choice. It changes the closing text, never rewards or musical requirements. The real Q12 completion prepares the afterglow journal and uses the selected dedication. The journal waits until the player leaves the concert controls before appearing; it does not cover the instrument or performance. Reopening it retains that ending.

The source implements dialogue and the existing personal restoration presentation. It does not add a new cutscene, a physically spawned open-call card, a scripted audience procession or new NPC follower behaviour. Those are clearly identified presentation targets in the bible.

### Four optional activities

| Activity | Concrete interaction | Completion authority | First reward |
| --- | --- | --- | --- |
| Nell's memory postcards | Read the café, ferry-office and Lantern Room memories at their building entrances; keep the text in the journal | Server verifies distance to each canonical building and records three bounded IDs | Listener / Neighbour XP, memory pin |
| A pocketful of the quay | Find the existing I01, I02 and I03 virtual sounds | Existing authoritative discovery flags; the activity reconciles automatically | Listener / Beatmaker XP, sound-scout satchel |
| Ivo's pattern bench | Choose the next symbol in three untimed repeating patterns, with optional free hints | Server chooses the puzzle order and validates each answer and distance to Morrow Repairs | Beatmaker XP, pattern patch |
| Your first record sleeve | Preview three motifs and three palettes, then print a cover at Needle Records | Server validates the chosen IDs and distance to the record shop | Beatmaker / Neighbour XP, sleeve-maker bag |

Wrong puzzle answers preserve progress. Replays grant no additional XP. The first-completion flags persist through the existing profile flow. The current short puzzle's round/order is intentionally session-only, so an unfinished attempt restarts after rejoin. The sleeve is a saved design in the journal. Copy kept sleeve to selected song draft is an explicit action; it copies the motif/palette into that draft. Save Draft and a later Finish & Save Song preserve the copied cover in a new immutable musical revision. Changing the sleeve design never finishes music or alters older finished covers. It uses curated graphics and does not accept user text, uploads or a microphone recording.

### Musical RPG identity

Three paths grow together: **Listener, Beatmaker, Neighbour**. The player does not choose an exclusive class. Each path has thresholds **0, 30, 75, 130 XP**. Overall ranks are **New Voice (0), Quay Regular (70), Beat Explorer (180), Neighbourhood Artist (340), Lantern Resident (500)**. The finite demo ledger awards at most **575 XP**. Titles and wardrobe milestones provide the rewards; instrument features and story eligibility are unchanged by rank.

Experience is derived from a whitelist of unique completed quests, discoveries and activities. There is no remote accepting an XP number or arbitrary grant. Q03's optional performance invitation/skip carries no XP, so choosing private play has no progression penalty. Older profiles receive appropriate identity credit from their existing completed milestones without repeating the chapter.

This is a creative progression system, not combat or a music-quality score. No XP multiplier, energy timer, paid skill, musical stat advantage, paid inventory slot or repeatable currency economy has been introduced.

### Wardrobe

The catalog has **16 candidate accessories: two free starter items, eight earned items and six variants in two premium bundles**. Four slots cover headwear, scarves, bags and pins. All three saved looks are free. Players can equip, remove, save/replace a look, reload a look, choose a title, or remove all BeatMakka accessories.

The server validates catalog membership and ownership, then creates only tagged BeatMakka accessories. The player's own Roblox clothing, account accessories, body proportions and account outfit remain intact. Standard R6/R15 head and torso parts are supported; custom rigs without those parts safely receive no candidate accessories. This is not a complete layered-clothing/avatar-editor system.

The My style tab includes a local wardrobe mirror of the player's **currently worn** avatar, with left/right rotation. It rebuilds after appearance changes with a short debounce, has no per-frame animation, and releases its viewport model when the journal is closed. It does not try on or grant unowned premium items.

The visuals are deterministic local Part geometry, using the existing palette. They are **candidates pending fit and art review**, not approved store products. No invented Marketplace asset IDs or paid provider generation are involved. The Windows Assets directory was inventoried for this local integration. No newly sourced external image/model was used by these deterministic UI/accessory changes. The supplied source archive remains preserved under assets/supplied/needle-quay-handoff-v3; final accessory fit and art review remain pending.

### Cosmetic Robux shop

Two permanent bundles are defined: **Harbor Afterglow** and **Workshop Weekend**, each with three guaranteed accessories. The proposed default price is **99 Robux per set**, recorded only in configuration/documentation. Actual shopping UI requests the player's current price from Roblox with `GetProductInfoAsync`.

The server queries `UserOwnsGamePassAsync` on join and after a purchase notification. The wardrobe accepts only the resulting server-verified bundle map. Price failure, ownership failure and unresolved purchase confirmation disable Buy. An explicit ownership retry never opens another purchase prompt. Cancelling retains the current look.

**Sales are disabled.** Pass IDs, production universe and creator bindings are absent; asset approval is false. A developer must supply valid approved bindings and explicitly enable sales in the authorized production environment. Studio cannot sell these sets. No passes have been created and no live purchases were made. Developer products and receipt-based consumables are deliberately outside this slice.

## 2. Source map

| File | Responsibility |
| --- | --- |
| `src/shared/QuayStory.luau` | Read-only lore, NPC motives, chapter selection, context dialogue, milestone memories and dedication endings |
| `src/shared/QuayActivities.luau` | Four activity contracts, canonical memory locations, cover options, bounded sanitization and automatic evidence reconciliation |
| `src/shared/QuayIdentity.luau` | Unique award ledger, XP/ranks/titles, earned ownership, equipped IDs and three saved looks |
| `src/shared/WardrobeCatalog.luau` | Stable cosmetic IDs, slots, acquisition rules and candidate geometry/style definitions |
| `src/shared/CommerceCatalog.luau` | Permanent bundles and explicit closed production configuration |
| `src/server/QuayExperienceService.luau` | Server-validated activities and identity commands, summaries and existing save-queue integration |
| `src/server/WardrobeService.luau` | Bounded candidate accessory application, respawn and cleanup |
| `src/server/CommerceService.luau` | Server ownership queries, stale-response protection, bounded retries and entitlement snapshots |
| `src/client/QuayExperiencePanel.luau` | Explore and My style sections, puzzle input, sleeve designer, progression and wardrobe controls |
| `src/client/QuayWardrobePreview.luau` | Local current-avatar mirror, bounded visual clone, camera rotation and visibility cleanup |
| `src/client/QuayShopPanel.luau` | Dynamic product price, explicit native prompt, cancellation and ownership retry presentation |
| `src/client/QuayDemoView.luau` | Integrates Story / Explore / My style / Shop / City into the existing journal; short dialogue, hints and dedication |
| `src/server/QuayDemoService.luau` | Character-led quest responses and dedication-aware afterglow on actual Q12 completion |
| `src/server/MusicService.luau` | Service wiring, profile-ready and rate-limited `Life*` command dispatch, authoritative state and lifecycle |
| `src/server/ProfileStore.luau` | Additive identity/experience persistence, subordinate future-version guards and restore dirty tracking |

The existing Rojo `src/shared`, `src/server` and `src/client` mappings discover the new modules. No new runtime package, CI workflow, audio binding, place, binary art asset or external service is introduced.

## 3. Runtime and persistence contract

The existing schema-2 profile gains two additive fields:

```luau
experience = {
    version = 1,
    memories = { cafe = false, ferry = false, lantern = false },
    activities = { memory_walk = false, sound_safari = false,
        pattern_bench = false, sleeve_studio = false },
    dedication = "together",
    sleeve = { motif = "waves", palette = "teal" },
}
identity = {
    version = 1,
    awards = {},
    equipped = {},
    outfits = { false, false, false },
    title = "new_voice",
}
```

Legacy profiles without these fields receive safe defaults. Unknown future subfield versions cause load/save refusal instead of silent truncation. Outfit slots use a dense array, without sparse-array serialization loss. Purchased ownership is never persisted as an editable profile entitlement.

Activity and wardrobe changes use `QuayDemoService`'s existing delayed save queue and `ProfileStore` revision check. Restoring old musical slots preserves newer activity, title, wardrobe and dedication state; those differences keep the profile dirty. A failed cloud load continues to protect the existing saved work by disabling writes. Studio remains session-only, exactly as before.

Deploy the updated profile reader/writer together. Older servers do not preserve these new fields when they create old-format snapshots. Any future live rollout needs server version isolation or a migration plan before mixing old and new writers. The current change does not claim cross-server session locking or live DataStore acceptance.

The `Life*` commands are handled before the station-only music controls. They still require a ready server profile, the existing command token budget, and a local action cooldown. Spatial activities also check the correct building and a live character on the server. Equipment commands accept stable catalog IDs, never arbitrary instances or asset IDs. Client hiding or disabling a button is presentation; the server remains the authority.

## 4. Local use

Use the existing project-pinned toolchain on the development workstation. Sync the source with Rojo and retain the current permitted local content installation. A fresh build is necessary: the older packaged `.rbxlx` does not acquire these source changes merely because it exists in `output`.

```powershell
rojo build default.project.json --output work/NeedleQuay-Experience.rbxlx
rojo serve default.project.json
```

The existing local geometry/audio installation requirements remain in [the local demo guide](LOCAL_DEMO_2026-10-25.md). That guide contains historical acceptance claims and is not evidence for this new source revision. Current art revision status remains separate.

Suggested first walkthrough: open the journal's Story tab; visit Tori or enter the Roamer; follow the existing chapter; take a café/ferry memory detour; try Ivo's bench; print a sleeve at Needle Records; wear an earned item and keep a look; choose a dedication before the Lantern Room finale; revisit the journal afterward. The Shop tab should say the sets are being prepared and expose no live purchase.

## 5. Validation and release boundary

The local integration preserves newer uncommitted world, companion, neighbourhood and dialogue systems while adding the supplied experience modules. The repository-pinned **StyLua 2.6.0** parsed and formatted the experience/quest/finale Luau with `--syntax Luau --verify`. This is a static parse/format check, not Roblox execution or an independent runtime review.

No test suite was added or run, consistent with this repository's `AGENTS.md` instruction for unrequested tests. Studio/device execution was not requested and was not performed. No live DataStore, audible music, two-player route, wearable fit, mobile/gamepad layout or purchase acceptance is claimed.

Before calling this a playable release, perform the following targeted acceptance in an authorized environment:

1. Fresh profile: play the complete existing Q00–Q12 route and observe chapter selection, Naya's midpoint and the selected closing dedication. The instrument must remain usable from arrival.
2. Returning profile: load existing completed milestones, verify one-time identity credit, change a look, restore old music, and confirm that new activity/identity data survives.
3. Side activities: walk to each actual anchor; reject remote completion from elsewhere; finish all four; replay without duplicated awards; recover from wrong puzzle answers and cancelled exploration.
4. Wardrobe: standard R6/R15, respawn, three looks, removal and entitlement outage; verify avatar accessories are retained and candidate items fit without blocking controls.
5. UI: narrow phone portrait, landscape, desktop and gamepad. Check the journal's Story / Explore / My style / Shop / City tabs plus the preserved Quay life and People surfaces, scrolling, focus, dialogue/hints and exit from finite Finished Song performance.
6. Save failure/rejoin: perform actual authorized persistence checks; do not convert a Studio session save into a claim of cloud storage.
7. Commercial release, separately: accepted final visuals, correct production owner/universe, approved passes, regional price display, native cancellation, ownership restoration and closed configuration failure states.

## 6. Deliberate remaining scope

- Newer local Alissia/Nikolas companion work is preserved; its notebook observations now read saved named sequences across all banks. This experience integration does not establish a new follower runtime acceptance.
- The wardrobe provides accessories, titles and saved looks. Final garment meshes, layered clothing, global avatar export and premium try-on are later work.
- The side-content slate deliberately stops at four activities. Café serving, ferry spotting, a recurring community set and additional craft tables are future content, not hidden claims of implementation.
- Fresh signs, neighbour attendance choreography, phase-specific camera work and other afterglow scenery are presentation work awaiting the existing art process.
- All other districts remain closed in this demo. No city-wide progression or genre lock was added.

## Sources

- [Synced source commit](https://github.com/slafftrosheen/BeatMakka/commit/8e8b91f6a5472eb6200599e60932e45a8c9ea56b)
- [Existing world atlas](../WORLD_ATLAS_2026-10-24.md), [environment register](ENVIRONMENT_REGISTER.md), [companion issue #20](https://github.com/slafftrosheen/BeatMakka/issues/20)
- [Roblox passes](https://create.roblox.com/docs/production/monetization/passes), [regional pricing](https://create.roblox.com/docs/production/monetization/regional-pricing), [MarketplaceService](https://create.roblox.com/docs/reference/engine/classes/MarketplaceService), references supplied with the original handoff; not revalidated as live commerce acceptance
