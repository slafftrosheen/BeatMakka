# Playful Quay implementation — 2026-10-29

## Companion animation correction

The previous Studio log recorded `Companion skin memory unavailable` on 2026-10-28 at 21:32:09Z, 21:41:28Z and 21:42:41Z. This was evidence from the previous user-run demo, not a new verification run. The old follower also hid during playback, recording, workshop and concert contexts, and source dance clips were never exported.

LocalMeshQueue now serializes mutable mesh construction across residents and companions. LocalMutableMesh snapshots and destroys fixed imports before allocating mutable topology, deduplicates vertex/UV/normal attributes, and retries allocation with a bound. Supplied skins retain weights and original geometry. Follower skin recovery is bounded to three attempts per selection. Failure still leaves an exact static textured fallback; no new runtime result is claimed.

tools/export_companion_clips.py samples the preserved supplied Blender rigs at 24 Hz. It exports idle, walk, run, cheer, clap and two dances for both characters, plus their available agree/bow gestures. One-shot clips clamp at the end. Walking/running take priority over dancing; authoritative saved/discovery/quest/side-activity transitions trigger short applause/cheers; stale queued reactions expire. Reduced effects uses a sampled idle pose instead of the bind T-pose. Continuous music dancing is presentation only and does not drive the transport clock.

## Guidance and play

QuayWayfinder computes client navigation paths at most every four seconds, with no teleporting or completion authority. A failed path does not draw a misleading straight trail through buildings. Destination highlights are occlusion-aware. Detailed help is opt-in. The objective cue and sampler use short action labels and vector icons.

QuaySideActivities owns Echo Pads and Pulse Club rounds on the server. Range, ready/station state, current round serial, pad values, cooldown and server time constrain commands. Client-supplied success or hit timestamps are never accepted. Completion updates additive `quay.side` fields and the existing persistence mechanism; neither activity gates canonical quests. Pulse Club's 280 ms hit window is designed for a local demo; multiplayer latency fairness is unverified.

QuayBadges derives seven personal keepsakes from authoritative quest/side progress. Reconnecting does not replay historical unlock banners. These are in-game badges, not published BadgeService awards. Eight additional generic residents reuse repository character assets, with six walking routes and two street-game spectators. Distance limits and the existing effects switch govern presentation.

## Hardware UI and sound

HardwareFaceplate consumes the generated enamel texture from bundled local content. DigitalDisplay draws actual seven-segment numerals. GameIcons supplies authored geometry icons. HardwarePadControls connects level/pitch knobs and +/- buttons to the existing PadSound command, with bounded drag dispatch. The original MPC functions remain behind icon tabs. AudioMix separates music, ambience and UI cues without altering saved compositions. Voice production and new ambient recordings are specified in VOICE_AND_SOUND_DIRECTION.md, not represented as shipped audio.

## Delivery boundary

No new dependencies, test suites, Roblox uploads, paid Tripo operations, commits or pushes. Earlier dirty gameplay/art work remains in place. The previous LivingQuay package is retained. New output: output/needle-quay-demo/NeedleQuay-PlayfulQuay.zip. Build/packaging receipts live in docs/evidence/playful-quay. Studio Play, visual layout acceptance, actual deformations, multiplayer, device performance and cloud persistence remain NOT_RUN for this revision.

Rebuild: Blender --factory-startup -b --python tools/export_companion_clips.py; python tools/package_local_demo_content.py; pinned Rokit Rojo build default.project.json to output/needle-quay-demo/NeedleQuay-PlayfulQuay.rbxlx; python tools/package_needle_quay_demo.py --place NeedleQuay-PlayfulQuay.rbxlx --readme docs/needle-quay/PLAYFUL_QUAY_PACKAGE_README.md --evidence-dir docs/evidence/playful-quay. The geometry importer alone does not replace the expanded clip-export step.
