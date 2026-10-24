# WORLD ATLAS v1 — Resonance City / BeatMakka
**24 October 2026. Design proposal; not a playable-world release.**

## Authority and names
The current repository README names the experience **Frequency Zero**; **BeatMakka** remains the project/product name. **Resonance City** is a working name for the city, not a renamed existing game. **Needle Quay** is the canonical first neighborhood and approved visual setting. “Old Harbor” is a narrative description only.

## Narrative
“The Quiet Fade”: over generations the city stopped learning together, making things together, visiting cultural spaces and listening to one another. This is not the children's fault and is not a morality play about laziness. A player finds a real music instrument, helps neighbors restore meaningful places, performs music made from collected in-world sounds and teaches the community to connect again. There is no villain to destroy; the chapter antagonists are weary citizens and neglected locations.

## World-layout principle
Whole city is visible on the opening map. Only **N00 Needle Quay** can be entered for quest progression. The other ten district silhouettes are visible with textual **LOCKED** labels, not an opaque mystery screen. District discovery is personal; clearing one player's quest never flips another player's status. Public stages and voluntary listeners are shared. Genre selection is independent of map locks.

## Music source truth
Actual source inventory is **ten genre starter kits** of 16 pads = **160** processed style WAVs, plus the **one original 16-pad kit**; eleven **kits**, not eleven styles. Genres verified against actual directories:
`triphop`, `dance`, `grunge`, `hardtrance`, `hiphop`, `industrial`, `pop`, `reggae`, `techno`, `trance`.
In the 24 Oct source audit, 100 style IDs were bound (six complete kits + four Pop), 60 were pending, and 24 original WAVs were staged but without uploaded IDs. Real audio permissions, original-discovery playback and cloud rejoin remain distinct outstanding gates. The ten source genre archives had no verified publisher license document; user-supplied freeware statement is recorded but does not clear public-redistribution rights.

## District master list
| Number / ID | District | Audio kit | Identity / learning |
|---|---|---|---|
| 01 / `N00` | Needle Quay | Original Quay | Порт, мастерская, винил, фургон; первый курс музыки. Первый бит, звук среды, ответственность. |
| 02 / `N01` | Gritline Yard | Grunge | Гаражи, кирпич и репетиционные помещения. Динамика и выразительность. |
| 03 / `N02` | Brassworks | Industrial | Мастерские, музей механизмов и ритмический завод. Периодичность и логика. |
| 04 / `N03` | Aurora Steps | Hard Trance | Палубы и высокие открытые площадки. Темп, фразировка и наращивание интенсивности. |
| 05 / `N04` | Skyglass Junction | Trance | Надземный терминал и стеклянные навесы. Слои, длинные фразы и переходы. |
| 06 / `N05` | Murmur Canal | Trip Hop | Туманные каналы и дождевые мостики. Пауза, текстуры и внимательное слушание. |
| 07 / `N06` | Blockbeat Lane | Hip Hop | Открытые дворы и виниловые киоски. Ритмическая речь и творческий диалог. |
| 08 / `N07` | Motorgrid | Techno | Ритмичные фонари и городская энергосеть. Алгоритмы, циклы и вариации. |
| 09 / `N08` | Loopline Square | Dance | Круглая сцена и общественная танцевальная площадь. Синхронизация и команда. |
| 10 / `N09` | Lantern Mile | Pop | Афиши, театры и кафе. Мелодия, форма и хук. |
| 11 / `N10` | Sunbay Strand | Reggae | Тёплое побережье и деревянные мостки. Оффбит и исторический контекст ямайского регги. |

## Approved visual grammar
Continue the user-approved `assets/references/needle-quay-approved-style-board.png` with **teal paint / cream enamel / restrained amber / dusty coral / worn walnut wood**, friendly softly beveled forms, curved lamps, vinyl bins and pedestrian waterfront streets. Reference MK-I design tokens:
`paper #F5EEDC`, `cream #E8D8B7`, `ink #162322`, `teal #2F5C58`, `faded #6F9186`, `amber #F3B65F`, `coral #CA7453`, `walnut #79513B`.
Future districts differ by street function, silhouettes, architectural landmarks and secondary accent; they must continue using the same modular kit, shader language and physical proportions. No neon-magenta cyberpunk re-theme.

## Needle Quay / first district
Four authored **performance parking nodes**, not arbitrary simulated vehicle slots:
- **P1 Rusty Workshop** — mechanism sequencing, Mica, metal sound `I01`; build on `metal_pulse`.
- **P2 Vinyl Corner** — H03 vinyl crate, Preview → Assign, story/listening task.
- **P3 Harbor Market** — stage preparation, responsibility and cooperation with **mandatory NPC solo fallback**.
- **P4 Echo Pier** — virtual environmental recorder with `I02`, `I03` and existing water *ambience*; do not call the ambience an assignable sample without an asset.
- **The Lighthouse Club** — final chapter art target, building on the **already implemented six-phase courtyard ChapterConcert**, not a claim that the Lighthouse geometry exists.

**The Roamer** is the working name for a personalized mobile van/studio/home. Existing workshop owner/visitor controls and MK-I/Beat Shelf should be reused inside it. Demo parking travel is an authored safe transition with server verification, not multiplayer vehicle physics.

## Educational design contract
Responsibility happens through concert setup; logic through ordered repairs; language through rhythm, listening and phrases; audio physics through virtual curated sound sources; social skills through listening and opt-in collaboration. Never grade whether a child's composition is “good”, demand other players, or gate the basic instrument behind chores. Keep all actual mic-recording claims out: Roblox's AudioRecorder is not released and `AudioDeviceInput` recording is unsupported per current docs.

## Status and handoff
This file and `data/world-districts.v1.json` are **new proposals**. They do not rename existing assets, migrate profile schema, build districts, bind audio, or grant game release acceptance. The accompanying **World Artbook PDF, master map/locked map SVG+PNG, and full development plan** are available as a separate user-delivered artifact bundle; they are not falsely marked as committed binary assets here.

Authoritative baseline documents: `01_Visual_Artbook.pdf`, `02_Production_Atlas.pdf`, `Asset_Production_Register.xlsx`, `output/artbook-alpha01/BeatMakka_MK-I_Artbook_Alpha01_RU.pdf`, `docs/STYLE_STARTER_PACKS.md` and `docs/PENDING_VERIFICATION_2026-10-24.md`. Review them before implementing any new 3D production.
