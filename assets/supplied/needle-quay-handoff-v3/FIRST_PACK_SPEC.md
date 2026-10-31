# First final pack — Needle Quay: Harbour Pulse, planning revision 3

## Decision and production order

Create **one coherent first-area instrument pack with exactly 64 one-shots**, addressed A01–A16, B01–B16, C01–C16 and D01–D16. The physical sampler remains a 4 × 4 pad grid. A/B/C/D exclusively identifies sound banks. Named reusable sequences and Song Mode arrangements are separate musical objects, with no fixed four-pattern model; see `MPC_WORKFLOW.md`.

The first creative deliverable is one original harbour-themed **vocal** drum-and-bass demo song in Google Flow Music. Slaff listens and approves the song and sound palette. Only then does work start on the 64 one-shots, including four vocal cuts. The whole-song preview, vocal/instrumental stems and production sources live outside the runtime sample folder, so they do not become extra playable samples.

Working pack ID: `nq_harbour_01`. Proposed title: **Harbour Pulse**. Proposed song settings: **174 BPM, 4/4, D natural minor**, with A4 = 440 Hz. These are authored starting choices, not measurements of the referenced commercial recording or an approved generated song.

Proposed first song: an **original vocal, 112-bar arrangement**, approximately **2:34.5** at that tempo. Use 8 bars of arrival, 8 bars of build, 32 bars of first drop, 16 bars of spacious breakdown, 8 bars of rebuild, 32 bars of varied second drop and 8 bars of warm outro. The first full drop arrives at approximately 22 seconds. These are composition targets; report the actual result honestly if generation differs.

The music prompt stays outside this ZIP. The user sent the earlier prompt to the music agent; a shorter vocal correction was subsequently supplied, with forwarding/approval not confirmed. This specification lets the local game agent prepare the current integration contract without starting audio generation or assuming that any song or stems already exist.

### Vocal and song direction

Use original, clean UK MC verses about hearing rhythm in everyday harbour sounds and bringing Needle Quay's neighbours together. Give the song a strong call-and-response hook, confident and playful delivery, punchy breaks, deep sub, expressive Reese bass, dock-metal percussion and a memorable bell melody. The requested energy reference is Chase & Status/Bou's “Baddadan”; write an original composition, lyrics and vocal performance. The reference is a direction for energy and rhythm, not source audio for the game.

Suggested hook: **“Needle Quay — we make waves! / From the docks to the decks, let the whole place shake!”** Pronounce Quay as “key.” The words are a proposal for the music agent, not a claim about the approved take. Useful images are the Roamer, working docks, repair shops, blank record sleeves, neighbours making room and the Lantern Room lights. Keep the theme welcoming and age-appropriate. A player need not sing, use a microphone or add vocal samples to complete the game.

Keep available vocal stems for later sampling. A vocal song or a separated vocal stem does not guarantee four clean usable one-shots: select/recreate isolated cuts only after approval and listen for accompaniment bleed, clipped consonants and separation artifacts.

## Game and musical purpose

Needle Quay is BeatMakka's first playable demo area: a warm retrofuture harbour of repair shops, record sleeves, working docks, a helper robot and a small music venue. Young grooveboxers arrive with a Roamer mobile studio, collect local sounds, develop reusable sequences, arrange their own songs and invite the neighbourhood to a new gathering. The Quiet Fade describes a community gradually losing its shared creative habits. Music reconnects people; it is not a magical cure or a combat weapon.

The pack should support that world while sounding like a serious, exciting musical instrument: crisp drum-and-bass drums, rounded sub, controlled Reese movement, warm melodic details and recognisable dock/workshop percussion. Keep enough space that a beginner can combine a kick, snare, bass note and one Quay detail and immediately hear a coherent idea. The demo song demonstrates possibilities; the gameplay must continue to celebrate the player's own beat.

## Four banks, exactly 16 samples each

| Pad | Bank A — Drums | Bank B — Bass | Bank C — Melody and harmony | Bank D — Harbour and vocals |
|---:|---|---|---|---|
| 01 | Deep kick | Rounded sub D2 | Bell-pluck D4 | Quay metal / I01 |
| 02 | Punch kick | Rounded sub E2 | Bell-pluck E4 | Vent thump / I02 |
| 03 | Main snare | Rounded sub F2 | Bell-pluck F4 | Helper chirp / I03 |
| 04 | Tight ghost snare | Rounded sub G2 | Bell-pluck G4 | Bollard tap |
| 05 | Small handclap | Rounded sub A2 | Bell-pluck A4 | Mooring-rope creak |
| 06 | Closed hi-hat | Rounded sub B-flat2 | Bell-pluck B-flat4 | Rope flick |
| 07 | Open hi-hat | Rounded sub C3 | Bell-pluck C5 | Wooden dock knock |
| 08 | Pedal hi-hat | Rounded sub D3 | Bell-pluck D5 | Crate knock |
| 09 | Ride bell | Controlled Reese D2 | Warm keys D minor | Depot latch click |
| 10 | Short ride | Controlled Reese E2 | Warm keys B-flat major | Wrench ring |
| 11 | Short crash | Controlled Reese F2 | Warm keys C major | Ferry bell D4 |
| 12 | Wooden rimshot | Controlled Reese G2 | Warm keys A minor | Water drop |
| 13 | Low tom D | Controlled Reese A2 | Lantern pad D minor | Needle Quay vocal call |
| 14 | Mid tom A | Controlled Reese B-flat2 | Dub organ D minor stab | Vocal response |
| 15 | Short shaker | Controlled Reese C3 | Muted brass D minor stab | Short vocal phrase |
| 16 | Tambourine hit | Controlled Reese D3 | Signal synth D5 accent | Rhythmic vocal hit |

This is a complete proposed role map. Revise deliberately if the approved song calls for a different palette; keep exactly 64 useful entries. Pitch variants serve actual playable scales, not arbitrary duplication to fill a quota. The song does not need to play every note or every foley variation in its mix.

### Four reserved vocal slots

| Address | Role | Provisional text/direction | Planned filename |
|---|---|---|---|
| D13 / 61 | Location call | “Needle Quay!” | `NQ_D13_needle_quay_call.wav` |
| D14 / 62 | Call-and-response reply | “We make waves!” | `NQ_D14_vocal_response.wav` |
| D15 / 63 | Short MC phrase | One concise phrase selected from the approved song; words not fixed | `NQ_D15_short_vocal_phrase.wav` |
| D16 / 64 | Rhythmic vocal hit | One word/syllable or short exclamation selected from the approved song | `NQ_D16_rhythmic_vocal_hit.wav` |

These replace the earlier splash, lamp-click, uplifter and downlifter plans. They are not additional samples: Bank D has twelve harbour sounds plus four vocals, and the complete pack has 64. Production effects may still appear in the full song without occupying a pad. Do not impose the old one-bar riser/fall duration on D15/D16.

This is an unapproved planning revision. The stable planned IDs stay `nq.harbour.v1.d13` through `.d16`, while the manifest explicitly records planning revision 3 and the displaced roles. Inspect any actual local work that used previous placeholders; preserve it and reconcile affected mappings deliberately. Never silently redefine an admitted audio identity or substitute a vocal into an existing player's music. The documentation example is not installed data; its former D13 ambience event is deliberately moved to D12.

### Semantic game bindings

| Game role | Planned slot | Planned sample ID |
|---|---|---|
| I01 metal discovery | D01 | `nq.harbour.v1.d01` |
| I02 vent discovery | D02 | `nq.harbour.v1.d02` |
| I03 robot discovery | D03 | `nq.harbour.v1.d03` |
| Tutorial/listening kick | A01 | `nq.harbour.v1.a01` |
| Tutorial/listening closed hat | A06 | `nq.harbour.v1.a06` |
| Tutorial/listening pluck | C01 | `nq.harbour.v1.c01` |

The existing story keys I01/I02/I03 and their earned unlock flags remain canonical. Their retired audio IDs do not become aliases to these new samples. The full pack contains 64 assets even if three pads retain their discovery unlock gates. Story sounds are not paid purchases.

## A one-shot is one usable event

Each runtime file should be one hit, bass note, melodic note, chord, short foley gesture or finite vocal utterance/hit. No full grooves, drum fills, arpeggiated sequences, bass riffs, verses, repeating vocal grooves or arbitrarily cropped pieces of the stereo song. A short spoken phrase can be a one-shot when it is a single usable triggerable event. Long scene ambience is outside this 64-sample instrument pack.

A stereo song or broad drum/bass stem does not by itself provide 64 clean isolated instrument files. Preserve real source renders where available. If the music platform supplies only a mix or broad stems, use those to approve the identity, then separately render, recreate or generate clean isolated notes and hits in that approved palette. Inspect separation artifacts and overlapping instruments; do not hide them by calling a mixed fragment a clean sample.

No source-session, MIDI, dry multitrack or exporter capability should be claimed unless it actually exists. Use the native available files honestly. Keep an approval record identifying the exact song version and the actual sample versions, not just a title.

## Proposed technical delivery targets

These are project authoring targets, not Roblox platform limits or claims about Flow Music's export formats.

- **Runtime:** exactly 64 mono PCM WAV files, preferably 44.1 kHz / 16-bit for the first compact mobile-friendly pack. Keep the highest native production sources separately. Converting a file to higher resolution does not restore detail; never describe it as a higher-quality source.
- **Pitch:** D natural minor uses D, E, F, G, A, B-flat and C. Record actual root note, octave and MIDI number for pitched one-shots; list chord tones. Use null for an unpitched source. Proposed pitch is separate from measured or verified pitch.
- **Tom tuning:** A13 and A14 reserve pitch classes D and A; their exact octaves remain a sound-design choice until production and must be recorded honestly at admission.
- **Bass:** start with D2–D3 sub and Reese notes; give the sub restrained upper harmonics so its identity does not rely only on deep bass. Keep low end effectively mono and the two timbres level-matched by role. Avoid baked whole-song sidechain pumping.
- **Length:** percussion commonly 0.1–0.8 seconds; bass 0.4–1.2 seconds; melodic notes 0.5–1.8 seconds; chords/pad gestures up to approximately 2.5 seconds. Vocal cuts should be short, clearly articulated single utterances with enough tail to sound natural; choose their exact length from the approved performance. These are editing targets, not evidence of files already produced.
- **Vocals:** preserve complete consonants and intelligibility; provide an isolated take with no unintended backing-music bleed. Spoken/MC cuts have no assumed melodic pitch. Record a verified pitch only when an actual pitched vocal requires one. Do not invent a fixed choke group: decide from the intended overlap and implement it truthfully.
- **Edges:** trim unintended leading silence without damaging the transient; use suitable end fades to prevent clicks. Preserve intentional reverse/riser attacks and tails.
- **Mixing:** retain dynamics and useful headroom. Match perceived level by role; do not peak-normalize every tiny hat and large kick to the same loudness. Avoid long baked stereo reverbs, clipping and excessive harshness. Song reverb and arrangement processing can live in the demo mix rather than every one-shot.
- **Choke hints:** closed/open/pedal hats share a proposed hat choke group; bass notes share a proposed mono-bass group. These are metadata intentions until the engine implements and demonstrates them. Never claim unsupported behavior.
- **Naming:** `NQ_A01_deep_kick.wav` through the planned A01–D16 names. Store exactly one chosen render per slot in the runtime folder; alternates and source masters stay elsewhere.

## Manifest and admission

`FIRST_PACK_64_SLOTS.json` schema 2, **planning revision 3**, defines all addresses, proposed IDs, labels, roles, planned pitches and discovery keys. Its `absolute_pad` value means a program-pad address from 1 to 64, not a sequencer-track number. It intentionally sets actual file paths, hashes, durations, verified pitches and Roblox audio IDs to null, with `audio_approved = false`. Proposed hook words are not an approved lyric transcript.

When real samples are delivered, create a versioned admission manifest containing actual file path, byte count, SHA-256, sample rate, channels, PCM bit depth, duration, measured/verified pitch, authored level guidance, source song/session provenance, and approval identity/date. Derive runtime labels/waveforms from that same admitted set. Resolve every physical bank/pad to one stable sample ID.

The proposed slot contract alone must never make a pack selectable, make a quest ready, or imply a Roblox upload. Approval of a song is permission to proceed to sound production; it is not automatic approval of all generated samples, shop changes or publication. Local integration and later deployment remain distinct stages.
