# Needle Quay — A Place for Every Sound

**Playable-experience bible · 30 October 2026 · source baseline `8e8b91f6a5472eb6200599e60932e45a8c9ea56b`**

This document defines the next playable chapter for BeatMakka / Frequency Zero. It preserves Needle Quay, the Roamer, the MK-I, P1–P4, NQ-Q00–NQ-Q12, the existing residents and the six-phase `ChapterConcert`. It is a content and implementation contract, not a claim of Roblox Studio acceptance, live saving, a working commercial release or approved new art. Features marked **target** require the implementation and evidence described below.

### Source implementation scope for this revision

The accompanying local implementation is scoped to authored, progress-aware story scenes; three creative progression paths; four optional activities (`memory_walk`, `sound_safari`, `pattern_bench`, `sleeve_studio`); and an in-experience wardrobe with three outfit slots. Its cosmetic catalog contains **16 candidate accessories: two starter, eight earned and six premium**, across head, neck, back and pin slots. The two permanent cosmetic bundles are **Harbor Afterglow** and **Workshop Weekend**. Purchases remain disabled until real pass configuration and art review are complete. This is source implementation scope, not a claim those paths passed Studio or live commerce acceptance.

The initial accessories are deterministic decorative Parts. Full layered garments, a Tailoring/Patch Table mini-game, new cinematic scenes, moving crowds, a walking companion, account-avatar export and the additional side activities below are later work. Alissia/Nikolas remain the issue #20 design integration target. The full experience described here should guide subsequent batches without turning those targets into false shipped-feature claims.

The source journal uses **Story / Explore / My style / Shop / City** tabs. Story is delivered as a short dialogue page with **Next** and **Read again**, an expandable **How do I do that?** section and an expandable full chapter journal. The selected dedication's closing line is connected to actual NQ-Q12 completion. Descriptions of Tori's chairs, Ivo's lamp, Naya adding a sleeve and Ronan hanging a fresh card are narrative content and scene-presentation targets; this source change does not claim newly animated residents or newly spawned story props.

## 1. The experience we are making

You arrive in a small waterfront neighbourhood with a mobile music studio. People are friendly, busy and a little out of practice at doing things together. The old Lantern Room still has a place for a new performer, but its caretaker does not believe anyone will come. You make a sound of your own, get to know the people who live here, and help them make room for one small evening together.

The player's central question is **“What will my first night at the Lantern Room sound like?”** The answer is made in the instrument, not selected from a dialogue menu. The player is a new neighbour and a musician, not an employee completing a backlog of maintenance jobs. The demo should leave them with a saved beat, a place they know, an appearance they chose, a few friends and a reason to return.

**Chapter title: A Place for Every Sound.** This is a chapter title, not a rename of the game or the city. Resonance City remains the working city name; only N00 Needle Quay is playable. The other ten districts remain visible and labelled as future routes. Existing genre kits are independent of geography and progression.

The intended first complete chapter takes **45–75 minutes**, with optional exploration extending it. These are pacing targets, not measured playtest results. A child should be able to stop after five or ten minutes with one understandable accomplishment. The MK-I must be available before the first chore. A first self-made loop is the target for the first three to five minutes; players who want to explore or simply play music are allowed to do so.

## 2. Lore: what the Quiet Fade actually means

The Quiet Fade is not a monster, a curse, a virus or a secret villain. Across the city, people gradually stopped sharing the small habits that kept places alive: swapping records, teaching a neighbour a rhythm, repairing something together, making room for an audience or showing up when someone tried something new. People still work, laugh and care. They have fewer shared occasions on which to express it.

Needle Quay used to hold an informal gathering at the Lantern Room. Anyone could bring a little music, a drawing, a repaired lamp, a kettle or a story. The evening had no winning act. Over time, shifts changed, equipment wore out and invitations went unanswered. Ronan kept the room safe and eventually stopped putting up the open-call card.

The player does not cure the city. They help organise **one new gathering**, with the residents doing their own share of the work. A restored vent does not emit magical energy; it lets Ivo finish a job and join in. A cleared market aisle gives Sana a practical place to welcome people. The signal console carries a short local invitation. The last musical loop brings these concrete actions together.

### The chapter's recurring object: the unfinished sleeve

An old open-call card is tucked into the Roamer's local welcome folder. It shows a lantern, a blank record sleeve and the handwritten line **“Bring a sound. Leave a little room.”** The card introduces a place to visit, not a countdown or a threat.

Tori remembers a dock rhythm. Ivo remembers a break in the music that made everyone laugh and join back in. Naya preserves the sleeves and notes from those evenings. Nell remembers who sat together. Ronan remembers the last night when almost nobody came.

At the midpoint, Naya shows the player the final blank sleeve. It is **not a lost master recording to reconstruct**. It was left empty for whatever the neighbourhood made next. This prevents the plot from reducing the player to copying somebody else's song. The player's own saved beat becomes the next entry. The sleeve is the visual and narrative link between music, exploration, wardrobe patches and the finale.

### Rules for writing this world

- Children are not responsible for the Quiet Fade or for adults' happiness. Residents ask for small, bounded help and take responsibility themselves.
- Silence can be welcome. A pause, a quiet corner and a private practice session are legitimate choices. “Quiet” does not mean “bad”.
- No genre is morally superior, no composition is graded for taste, and no public audience is required.
- The physical world stays grounded: ordinary machines, lamps, radios, paper, fabric and music equipment. A personal restoration state represents a player's chapter, not supernatural power.
- Humour comes from character and everyday mishaps. Nobody mocks a player's timing, reading speed, clothes or ability.
- The shop is a place to choose a look. Spending money is never a plot solution, a friendship test or evidence of being a “real” musician.

## 3. Dramatic structure on the existing route

The existing quest IDs remain the persistence keys. The narrative supplies intention, changing relationships and payoff around their server-validated actions. It must not add a competing quest ledger or grant rewards from dialogue alone.

| Act | Existing route | Dramatic question | What changes | Player-created evidence |
| --- | --- | --- | --- | --- |
| Arrival — A room to begin | NQ-Q00, P1 / Dockside Exchange | “Can I make something here?” | Tori introduces the Roamer and the old open-call card. The player has a home and immediate access to music. | Enter the existing introduction flow; music stays available without completing errands. |
| I — The quay has a rhythm | NQ-Q01–Q03, P1 | “Could an everyday sound become mine?” | Tori recognises a familiar dock sound in a new pattern. A first neighbour expresses interest in the gathering. | Three crates stowed, I01 collected, at least four distinct metal-hit steps; public sharing remains optional. |
| II — Leave room to change | NQ-Q04–Q05, P2 / Repair Alley | “Does my first idea have to be perfect?” | Ivo completes the repair with the player and treats A/B variation as trying two ideas. He agrees to bring his repaired lamp. | Existing repair order; two distinct playable A/B patterns successfully saved through the existing shelf/profile flow. |
| Midpoint — The blank sleeve | NQ-Q06–Q07, P3 / Needle Records | “Am I preserving the past or making something new?” | Naya reveals the sleeve was left blank on purpose. The player is invited to add their own work, not reproduce an old performance. | Existing role matching and successfully saved composition. A sleeve-cover choice is separate optional expression. |
| III — An invitation, not a demand | NQ-Q08–Q10, P3–P4 | “Will anybody want to join?” | Sana makes room for visitors; Mica helps the player send a clear local invitation. There is no guaranteed crowd size or dependence on online players. | Stage cases stowed; I03 call-and-response at 1/5/9/13; local signal restored. |
| IV — Open the door | NQ-Q11, The Lantern Room | “What if the room is quiet again?” | Ronan admits he stopped asking because an empty room hurt. The player chooses what this evening means, without being made responsible for fixing him. | Existing readiness gate and an optional dedication; all dedication choices lead to the same playable concert. |
| Finale — A place for every sound | NQ-Q12 | “What does our new gathering sound like?” | The player performs their own saved music. Residents recognise their small contributions. Ronan puts up a fresh open-call card. | Existing six phases: Rhythm, Support, Break, Return, Switch, Feature. No new musical grading. |
| Afterglow — See you next time | Post-NQ-Q12 | “What will I make next?” | The neighbourhood becomes a familiar creative hangout. The player's first sleeve stays in their own journal. | Optional remix, side activities, wardrobe, repeat performances and a visible future-route teaser. |

### Opening, beat by beat

1. Spawn beside the player's Roamer at P1. Mica says: **“Your studio is ready. Want to hear what this place sounds like?”** Show two equally legitimate directions: **Make a beat** and **Meet the quay**. Neither is a purchase prompt.
2. The welcome card can be inspected in one short panel. “Bring a sound. Leave a little room.” is the hook; the city history can wait.
3. Tori notices the sampler and offers the metal sound. Their task language explains why the crates are in the way: “We used to leave this corner clear for music. Let's make a little room.”
4. The instrument flow uses the current MK-I help. Story dialogue does not interrupt pad input. Technical requirements live in an expandable **How do I do that?** hint.
5. After the successful check, Tori responds to what the player actually did: “That's our old loading rail. I never heard it like that.” A visual invitation marker records interest in the gathering. It is not a popularity counter.

### Midpoint scene: the blank sleeve

**Naya:** “People keep asking me for the last song they played in the Lantern Room.”

**Player choices:** “Did you find it?” / “Could we make a new one?”

**Naya:** “There wasn't one last song. Everyone brought a little piece. This sleeve was for the next evening.”

She turns the blank sleeve over. There is room for the player's current saved beat. Choosing a curious response or a confident one changes her acknowledgement; it does not change XP or gate the story.

**Naya:** “Save yours. I would rather remember what you made than ask you to copy what we did.”

The optional Sleeve Studio becomes meaningful here. Its first design is free. Players can also leave the sleeve plain; an unpainted sleeve still holds music.

### Late scene: Ronan at the door

Ronan is introduced earlier through a short greeting if the player visits the venue. He should not appear only at the end as a locked quest dispenser.

**Before the route is ready:** “The room is safe. I just haven't put up a new invitation in a while. If you are curious, ask Naya about that blank sleeve.”

**When ready:** “I kept thinking the next evening had to be as good as the old ones. Then I stopped asking anyone.”

**Player choices:**

- **“Let's hear what happens.”** — curiosity.
- **“We can make room for everyone.”** — togetherness.
- **“It can be a new beginning.”** — a fresh start.

**Ronan:** “A small evening is enough. You can stop or practise again whenever you want.”

The choice becomes the concert dedication and a line on the player's journal sleeve. It gives the player authorship over the occasion, not a hidden best ending. A default dedication is allowed when the player skips dialogue. Existing `ChapterConcert` eligibility remains authoritative.

### The six-phase payoff

The player keeps full control of their saved arrangement. Short captions and resident reactions connect each phase to an earlier relationship; they never force the composition to sound like a prewritten song.

| Existing phase | Story meaning | Resident reaction target |
| --- | --- | --- |
| Rhythm | Start with one idea. | Tori recognises that an ordinary working sound can be part of music. |
| Support | Let another part join. | Sana welcomes the listeners; NPC fallback makes an empty server complete. |
| Break | Leaving space is allowed. | Ronan relaxes. A pause does not mean the evening has failed. |
| Return | People can come back. | Nell lifts a mug; Ivo's repaired lamp is on. |
| Switch | An idea can change. | Ivo recognises the A/B variation; Naya opens the new sleeve. |
| Feature | The player's discoveries belong in their own music. | Mica responds visually to the collected-sound feature; the stage does not become a score screen. |

Finishing the full server-clock loop completes the existing chapter. The player receives a remembered moment, the earned **First Light pin** (`lantern_pin`) and access to the selectable **Quay Original** title (`quay_original`). The progression catalog owns those grants; this narrative module does not award them. The dedication closing line is displayed by the implementation after actual completion. The epilogue's physical presentation remains a target: Ronan puts up a fresh open-call card; Naya adds the sleeve; the player can keep playing or leave immediately.

## 4. Residents who have lives and relationships

NPC dialogue needs a reason for asking, a personal reaction and at least one post-task change. Every principal character gets a before / in-progress / after state. Use authored text selected by server-owned progress, not generative dialogue or client-supplied completion flags.

| Character | Wants / hesitation | Relationship to others | Change during this chapter | Voice |
| --- | --- | --- | --- | --- |
| **Tori**, dock master | Wants a usable, welcoming quay. Thinks music might get in the way of work. | Keeps Ivo supplied; remembers carrying chairs for Ronan. | Hears the player's loading-rail beat and offers to bring chairs again. | Practical, short sentences, warm dry humour. “Three crates. Then this corner is yours to try.” |
| **Ivo**, mechanic | Wants to repair things perfectly; keeps postponing showing unfinished musical ideas. | Tori trusts his work. Naya has kept an old sleeve of his experiments. | Sees the player keep two different versions and agrees to bring an imperfect but working lamp. | Curious and eager; concrete comparisons, no lecture. “Version A works. Version B asks another question.” |
| **Naya**, archivist | Wants memories preserved, but fears preserving them so carefully that nothing new is added. | Knows Ronan's disappointment; trades stories with Nell. | Gives the player the empty sleeve and makes space on the archive shelf. | Thoughtful, inviting. Asks what the player noticed before explaining. |
| **Sana Bell**, market coordinator | Wants everyone comfortable and enough room for different needs. Carries too many arrangements herself. | Asks Tori for chairs and Nell for a quiet table; trusts Naya with the music corner. | Accepts practical help, reserves a quiet edge and invites people without insisting they perform. | Clear, lively and welcoming. “You can play, listen or take a breather.” |
| **Mica**, canonical H04 helper | Wants a clear reply. It can relay a signal, but cannot decide what the player wants to say. | Knows the neighbourhood route; links the two companions to resident activities. | Carries the player's chosen invitation and learns that a response can sound different from a prompt. | Concise, curious and gently literal. Never claims to record a live microphone. |
| **Ronan Wren**, venue caretaker | Wants the room to matter again. Avoids another disappointing empty evening. | Naya keeps the sleeves; Nell kept him company after the last gathering. | Opens the room for a small new evening and starts inviting people again. | Patient, spare and honest. Tired does not mean hostile. |
| **Nell Fen**, café host | Wants people to have somewhere comfortable to stop, talk or simply sit. | Remembers stories that formal archives miss; connects Sana's event to everyday neighbourliness. | Collects a new postcard after the concert. Her café is the low-pressure alternative to the stage. | Warm, observant, never emotionally coercive. “You can tell me about it, or just sit a minute.” |

### Alissia and Nikolas

Keep the issue #20 characters as optional companions: **Alissia, the Sound Collector**, and **Nikolas, the Beat Builder**. A player may choose either one or Alone. Both may appear in a short story scene, while one active walking follower is sufficient for the initial implementation. Choosing a companion never changes payouts, available genres, quest eligibility or access to the shop.

Alissia notices the different versions of a remembered event. Nikolas wants to turn every new idea into a pattern immediately. Their friendly disagreement reinforces the chapter theme: listening and trying are both useful. Neither solves the player's musical requirement, edits a pattern, claims a sample or completes a quest on the player's behalf.

- P1: Alissia notices the loading rail; Nikolas offers an optional explanation of four distinct sequencer steps.
- P2: Nikolas likes changing the second pattern; Alissia notices how the pause makes the first sound clearer.
- P3: Alissia asks why the sleeve is blank; Nikolas asks whether their new version can go in it.
- P4: both understand that an invitation can be answered later; they do not pressure a player to join a public performance.
- Finale: a short reaction follows a server-confirmed phase, never precedes or awards it.

This document does not add, upload or approve new companion models, use real voices, reproduce private family photographs or claim that issue #20 is completed.

## 5. Side activities: a neighbourhood beyond the main route

Optional activities need different verbs and different rewards. At least one must be available before finishing P1 and at least one must remain satisfying without sound. Each opens with a visible estimate such as **A short stop** or **Make something at your own pace**; do not show a false measured duration. The story continues regardless of completion.

The following is the **full demo target**, not a statement that all eight activities exist in this source change. The four source activities in this revision are Memory Walk (`memory_walk`, Nell's postcard fiction), Sound Safari (`sound_safari`), Pattern Bench (`pattern_bench`) and Sleeve Studio (`sleeve_studio`). Patch Table, Open Table as a dedicated new activity, Ferry Spotter and expanded Afterglow content are later targets. Existing concert replay remains usable without constituting a newly implemented mini-game.

| Activity target | Place / character | Player does | Reason to return | Reward and completion contract |
| --- | --- | --- | --- | --- |
| **Memory Postcards / Memory Walk** | Warm Current Café / Nell | Inspect the café, ferry office and Lantern Room. Selecting from multiple postcard memories is a later target. | Reread the short neighbourhood scenes; later story variants can add depth. | First visits are server checked; earned memory pin. No real camera or media upload. |
| **Sound Safari** | P1, P2, P4 / Mica; Alissia in the later companion layer | Collect the existing I01/I02/I03 virtual sources. An expanded comparison toy is a later target. | Try the sounds in a different pattern or kit. | Existing discovery ownership is reused. No second sample unlock ledger and no new unlicensed audio. |
| **Pattern Bench** | Morrow Repairs / Ivo or Nikolas | Solve a small three-to-five-step visual mechanical sequence with unlimited retries; variations change the sequence, not the required speed. | A compact logic toy between music sessions. | Server-held challenge and bounded inputs; first-clear recognition. Repeated attempts cannot mint unlimited currency. |
| **Patch Table** | Tidewash Laundry / community craft station | Combine a curated patch, border and palette on a garment or bag, then try it in the wardrobe preview. | Change identity for the next set. | First starter patch is free. Owned asset IDs only; preview does not equip, purchase or modify the account avatar. |
| **Sleeve Studio** | Needle Records / Naya | Choose one of three curated motifs and three palettes and keep the sleeve in the journal. Per-beat cover assignments and movable layouts are later targets. | Change the journal sleeve as the player's musical identity changes. | User composition remains untouched. Motif and palette IDs are allowlisted; free starter choices. No public free-text or uploaded image requirement. |
| **Open Table** | Harbor Market Hall / Sana | Trade a brief call-and-response with an NPC, or opt into a supported player session. | New arrangements, friends or quiet practice. | NPC route always complete. Players' consent, mute and leave controls survive the activity; no payout tied to votes. |
| **Ferry Spotter** | North Slip Ferry Office / Tori | Follow a short, accessible observation route and identify three landmark silhouettes from prepared cards. | Notice an overlooked corner; collect a postcard variant. | Server proximity and known landmark IDs, no precision jump, falling penalty or speed requirement. |
| **Afterglow Sets** | The Lantern Room / Ronan | Replay an owned saved set with a different dedication, outfit or arrangement. | The core music tool remains the content generator. | Existing concert/session authority. First-chapter reward is idempotent; later sets need not pay to be worthwhile. |

Side activities should be distributed around already-authored buildings. Most of those buildings are scenic shells: use exterior benches, notices and counters until a real interior exists. A map icon is not evidence of an accessible interior. Do not make laundry an unpaid chore, the café a hunger meter or fishing a random-item shop in order to populate the map.

### Minimum playable slice

The smallest credible implementation pairs the story layer with **three distinct optional loops**: a spatial observation activity, a short logic activity and a creative appearance/cover choice. Existing sound discovery and repeated concerts add replay depth but should not be advertised as three entirely new mini-games. If only part of this target is implemented, call it out in the runtime handoff.

## 6. RPG system: identity through doing

The RPG layer expresses what a young grooveboxer has tried and learned. It must not make the sampler weak at level one or turn music into a combat-stat spreadsheet.

Use three parallel creative interests:

- **Listener:** exploration, noticing sounds and learning neighbours' stories.
- **Beatmaker:** composing, trying variations, saving music and creative customisation.
- **Neighbour:** practical collaboration, an invitation and completing a set at one's own pace.

Players can progress in all three. There is no irreversible class choice, respec cost or stat build that makes a composition better. A profile may display a favourite interest as a title, but that does not lock mechanics. Do not award social progress from chat volume, friend count, spending, ratings or the number of people in an audience.

### Rank and reward contract

The progression catalog is the single authority for names, thresholds, earned cosmetics and any earned currency. Story text describes a milestone; it does not calculate or grant it. Derive first-completion recognition from server-owned existing quest/discovery/concert flags plus a bounded optional-activity ledger. This allows older profiles to receive the correct recognition without replaying the chapter.

The implemented rank thresholds come from `src/shared/QuayIdentity.luau`:

| Overall rank | Total XP threshold |
| --- | ---: |
| New Voice | 0 |
| Quay Regular | 70 |
| Beat Explorer | 180 |
| Neighbourhood Artist | 340 |
| Lantern Resident | 500 |

Each of Listener, Beatmaker and Neighbour has four levels: **Curious** at 0 XP, **Practising** at 30, **Finding your voice** at 75 and **Quay regular** at 130. The current finite ledger contains **575 total available XP**: 210 Listener, 180 Beatmaker and 185 Neighbour. Quest/discovery/activity source IDs can contribute once. This is a designed finite recognition system, not an endless grind or a timed streak. Rank never changes chapter eligibility or sampler capability.

Selectable titles are **New Voice** from the start, **Sound Scout** at 75 Listener XP, **Beat Builder** at 75 Beatmaker XP, **Good Neighbour** at 75 Neighbour XP and **Quay Original** after NQ-Q12. Completing or skipping the optional dockside public-performance invitation (Q03) earns no XP; its choice is not musical evidence. The catalog is authoritative if thresholds are tuned later.

Rewards should be concrete: a patch, a profile title, a sleeve template, a van pennant, an outfit accent, a memory postcard or a new neighbour reaction. Story-only earned items should remain earned; do not sell an indistinguishable copy that undermines the accomplishment. Paid items can have equally attractive but distinct designs.

Do not multiply music damage, audio fidelity, number of core pads, access to genres or correctness checks by level. Do not sell story skips, paid friendship, double story XP or completion of a musical lesson. The basic instrument remains capable from the first minute.

The source implementation uses deterministic unlocks and has **no soft-currency wallet**. If a wallet is added later, it should be earned from defined first-time activities and spent on a clearly priced cosmetic catalog. No exchange rate to Robux, paid random reward, maintenance cost or daily streak loss is required for this demo. Add a wallet only when it creates a better player choice than direct rewards.

## 7. Wardrobe and personal space

The complete wardrobe target is an identity loop: **discover a look → preview it → understand its source → equip it → see it in the world → save it**. A grid of locked icons alone does not satisfy it. The initial source slice supports inspect, owned-item equip/remove, a rotating mirror of the currently worn avatar, three saved looks and a reset of BeatMakka accessories. A reversible avatar try-on preview for unowned products and final layered outfits remains a later target unless separately added and evidenced in the implementation handoff.

Keep the existing Roblox avatar as the player's base. BeatMakka items are in-experience cosmetics with clear slots and compatibility rules. Where final accessory assets do not yet exist, a title, badge, patch or locally authored decorative attachment can establish the flow; label the visual stage honestly. Do not replace faces, skin colour, body shape or all existing accessories to make a new jacket fit.

**Current slots:** headwear (`head`), scarves (`neck`), bags (`back`) and pins (`pin`). There are 16 candidate items: two starter, eight earned and six premium. Three numbered outfit slots are free. Outer garments, named presets and additional stage accents are later targets. Only expose slots the implementation actually supports. Show **Owned**, **Earn at…**, **Available for Robux** and **Unavailable** distinctly. A future **Try on** action is reversible; current **Wear** changes the saved in-experience loadout. **Remove all BeatMakka accessories** removes only this system's decorative attachments and leaves the base Roblox avatar intact.

Wardrobe locations: a full mirror in the Roamer and a community Patch Table near Tidewash Laundry. A compact wardrobe button in the journal can be available without forcing travel. Existing MK-I finish and Roamer customisation remain separate cosmetic surfaces; do not overwrite their saved settings with avatar cosmetics.

Wardrobe changes should survive a normal respawn and rejoin after the persistence route is verified. Missing or moderated assets produce a clear unavailable state and a harmless fallback. A failed preview must not erase the player's base appearance. Save only canonical item IDs and equipped slots, not raw client-provided asset IDs or arbitrary `HumanoidDescription` data.

## 8. The Robux shop belongs in the world

**Shop fiction:** the **Quay Outfitters** counter inside the Harbor Market experience, using an existing exterior market counter until a real interior is available. Sana handles the community event, not pressure selling. The same catalog can be opened from the wardrobe. No new building is required to start.

The demo's configured design is two permanent cosmetic looks. Both are disabled candidate bundles, not live products:

| Bundle / ID | Guaranteed included items | Proposed base price |
| --- | --- | ---: |
| Harbor Afterglow / `harbor_afterglow` | Afterglow headphones, scarf and enamel pin | 99 Robux |
| Workshop Weekend / `workshop_weekend` | Weekend headphones, record bag and maker patch | 99 Robux |

These prices are planning values in `CommerceCatalog`, not storefront prices or a claim of uploaded passes. The commerce configuration owns real product IDs, final art approval, designated experience/account matching, deliverable item IDs and availability. Optional decorative Roamer/MK-I looks or full clothing sets are later catalog work.

The shop explains **Use in BeatMakka** for in-experience items. It does not imply a purchase grants an avatar Marketplace item usable across Roblox. It shows the exact included items, how they look on the current avatar, an accurate platform-provided price and ownership state before opening Roblox's purchase prompt.

No offer appears in the opening sequence, a mistake hint, a save-error dialog or the middle of a concert. No countdown, paid random box, fake discount, guilt line or “your friends have this” pressure is part of the design. A visible close action returns to the previous state. Owned bundles are marked owned; a purchase is never needed to continue.

For permanent cosmetic bundles, the intended initial route is passes, with purchase completion independently confirmed by the server. Runtime prices must be requested from Roblox; base-price proposals in design discussions are not valid hardcoded UI prices. Developer products, subscriptions, paid random items and trading are outside this demo's commercial slice. The implementation handoff must cite the current official Roblox references and keep commerce disabled until the owner configures real allowed products for the intended experience.

An earnable outfit should look deliberately designed and be attainable during the chapter. The paid looks can offer more choice. They must not provide the only coherent outfit, the only accessible text contrast or the only way to express a favoured music genre.

## 9. UI and moment-to-moment presentation

The district journal is the player's memory, not a wall of task instructions. Its primary view answers three questions: **Where am I in the story? What can I try now? What have I made?** The source UI uses five named tabs: **Story**, **Explore**, **My style**, **Shop** and **City**. Preserve direct access to the instrument and current music controls.

Story cards show a short chapter line, the current resident, a concrete next step and **How?** for technical help. The old Q numbers stay in data and debugging, not normal child-facing prose. Completed cards replace orders with a memory: “Tori heard the loading rail in your beat,” not thirteen identical ticks.

Dialogue is skippable and replayable from the journal. Most exchanges have two to four short pages, one idea per page. Input never auto-advances while the player is reading. Essential progress information remains available as text and iconography; sound is helpful but not the only signal. No timer punishes slow reading. Touch, keyboard and controller paths should reach close, back and the next choice.

Story scenes should use existing NPC positions, simple framing and state-selected dialogue before adding expensive cinematic tooling. If a scene has not been built, show an honest journal conversation rather than claiming an animated cutscene. New cloth, paper and lamp colour accents must follow the existing teal/cream/amber/coral/walnut palette.

The map distinguishes main route, optional activities, home, wardrobe and shop. Shop markers should not dominate story markers. Locked future districts show a short thematic hint, but no fake release date or button that pretends to travel. The finale should offer **Keep playing**, **Visit the quay** and **Leave for now**, all without pressure.

## 10. Implementation and persistence boundaries

### Existing sources to extend

| Existing component | Existing authority | Intended addition |
| --- | --- | --- |
| `QuayProgress.luau` | NQ-Q00–Q12 completion and music evidence | Keep its quest keys and checks. Read them to choose story state and backfill earned recognition. |
| `QuayDemoService.luau` | Proximity, route interactions, parking, checks and awards | Select the correct authored scene after a validated interaction; issue only server-confirmed activity changes. |
| `QuayDemoView.luau` | Map, journal, existing route prompts | Story/side-activity/profile presentation, understandable status and explicit hint access. |
| `MusicService.luau` | Command boundary and player-state projection | Validate bounded new action names/IDs and include sanitised progression/wardrobe projections. |
| `ProfileStore.luau` | Profile load/save/revision behaviour | Add compatible bounded fields. Never reinitialise music because a wardrobe or story field is absent. |
| `BeatBook.luau` / `ChapterConcert.luau` | Saved compositions and six-phase set | Reuse musical evidence; narrative decoration must not alter notes, requirements or timing. |
| `RoomService.luau` / existing finishes | Personal workshop ownership and appearance | Keep van/instrument customisation separate from avatar wardrobe. |
| `QuayStory.luau` | New authored content only | Canon, milestone memories, scenes and dedication labels. No reward mutation or storage side effects. |
| `QuayActivities.luau` / `QuayExperienceService.luau` | New bounded optional-activity data and server action handling | Four optional activities, allowlisted sleeve/dedication choices and memory state. Story descriptions do not duplicate their executable contracts. |
| `QuayIdentity.luau` | New server-authored finite award ledger | Derive three paths, ranks, titles and earned item eligibility from unique authoritative sources. |
| `WardrobeCatalog.luau` / `WardrobeService.luau` | New candidate item catalog and appearance application | Sixteen decorative candidate accessories, validated equip/remove and respawn refresh. |
| `CommerceCatalog.luau` / `CommerceService.luau` | New disabled product configuration and server ownership boundary | Two permanent cosmetic bundles; no client-granted entitlements or pretend live products. |

### Required implementation properties

- An old profile with finished Q steps receives the corresponding story state. Reading a story card must not mint a reward or clear a step.
- A repeatable side activity has a server-known start, bounded input and completion rule. A generic client `completeActivity` request is insufficient.
- Story choice stores an allowlisted ID, not unfiltered prose. Its result is cosmetic/narrative only, and a default exists.
- Every earned reward has one stable source ID. Failed save/retry, rejoin or replay cannot grant it twice.
- Shop ownership is checked against Roblox on the server; local saved ownership is not a substitute for the source entitlement. Failures remain unavailable or pending, never “owned”.
- Preview is local and reversible. The server validates equip requests against its allowed catalog and ownership/achievement state.
- The experience is complete on an empty server. Existing player collaboration can enrich it, but NPC fallbacks keep story and side loops usable.
- Restoration remains personal. One advanced player's chapter cannot complete a newcomer's story or clear their interaction targets.

### Scope that remains separate

This chapter does not authorize new Roblox uploads/publishing, paid provider jobs or a new account setup. The source repository's user deployment policy remains in force. The first district art revision remains subject to its own review; adding a story does not retroactively approve it. Do not infer live persistence, mobile/controller usability, public audio licensing or entitlement delivery from static source inspection.

## 11. Acceptance: when this becomes a playable experience

Use a small authored walkthrough and one uncoached young-player review when the user authorizes runtime verification. This is a future acceptance checklist, not a report that tests were executed in this change.

1. A fresh player understands they have a studio and can make music before clearing crates. They can identify the Lantern Room as a goal without reading the entire lore bible.
2. Tori, Ivo, Naya, Sana, Mica, Ronan and Nell have distinct reasons to interact. At least three react differently after the player's progress.
3. The player encounters the blank-sleeve reveal and Ronan's hesitation, then hears/reads a payoff connected to their own saved music. A skipped scene can be revisited.
4. Every existing Q step still completes from its actual server check. Q03 remains optional. The six-phase concert remains complete with NPCs and no human audience.
5. Three optional loops use different verbs and can be left without losing existing music. Their completion and rewards survive authorized save/rejoin checks; repeating a reward source does not duplicate it.
6. The player can earn, inspect, preview, equip and remove at least one coherent cosmetic choice. Respawn restores the intended in-experience loadout without erasing the base avatar.
7. A configured shop shows platform prices and exact contents, hides or disables unavailable offers, handles cancel/error/already-owned states, and delivers only after server confirmation. With no configured products it remains a clearly unavailable preview catalog; the chapter is still complete.
8. A returning or migrated profile sees the correct chapter, progression and existing music. Failed loading or a future schema never silently resets it.
9. The journal, choices and shop can be closed on touch/controller; reduced-effects and sound-independent guidance remain usable. No purchase prompt interrupts music input.
10. After the finale the player has a saved beat, a remembered story moment, an earned identity item and visible optional things to do. The map does not claim that the other ten districts are playable.

## 12. Source ledger

The baseline is the repository commit printed at the top. These are source relationships, not claims that every older acceptance statement is current:

- `docs/WORLD_ATLAS_2026-10-24.md`: Quiet Fade, city/district distinction, personal progress, genre independence and the grounded art palette.
- `docs/needle-quay/environment-production-register-v1.0-source.ru.md`: building names, resident roles, P1–P4 and NQ-Q00–Q12.
- `data/needle-quay-demo.v1.json`: current local-art revision status and runtime source list.
- `docs/needle-quay/LOCAL_DEMO_2026-10-25.md`: historical single-client gameplay route and explicit acceptance limitations; its top-level supersession notice matters.
- `src/shared/QuayProgress.luau`, `src/server/QuayDemoService.luau`, `src/shared/ChapterConcert.luau`: actual current quest evidence and finale mechanics. These supersede older specification-only status strings embedded in the generated catalog.
- [Companion issue #20](https://github.com/slafftrosheen/BeatMakka/issues/20): Alissia/Nikolas roles, one optional active follower, no automated player creation and original private-reference boundaries.
- `AGENTS.md`: user deployment policy, no default provider spend and requested development workflow.

New dialogue, the blank-sleeve plot, dedication choices, optional-activity designs and identity arc are authored proposals in this revision. Preserve canonical IDs while iterating on their presentation.
