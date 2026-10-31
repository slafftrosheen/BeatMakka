# Needle Quay — Playful Quay

Extract the complete ZIP and double-click **Launch-NeedleQuay.cmd**. It installs local content and opens NeedleQuay-Wardrobe.rbxlx visibly in Studio. Press Play. No Roblox uploads or system execution-policy changes.

- Select Alissia or Nikolas in Companions. They follow into music sessions, dance during playback, and react to saved music and completed activities. Original source dance/cheer/clap clips drive the supplied skins. Local mesh construction is serialized to address the memory-allocation failure recorded in the previous demo; bounded retries handle temporary failures.
- Route guidance starts enabled. Follow amber breadcrumbs and the destination beacon. A failed navigation path leaves only the destination beacon. Use **?** for detailed help; journal instructions are optional.
- **Echo Pads** is near the market approach (world 476, 2, 32). Watch/listen, then repeat the four lit pads. **Pulse Club** is by the waterfront (528, 2, 121). Two count-in beats, then hit four pulses. Mouse, touch, 1–4 and gamepad face buttons are supported. You can replay either activity. Rewards are optional in-game keepsakes, not Roblox platform badges.
- The badge collection tracks seven milestones and shows short completion banners. Six more walkers and two street-game spectators reuse existing local character art.
- The sampler uses cream enamel artwork, charcoal pads, seven-segment tempo digits, vector icons, pad playback lights and live level/pitch knobs on wide layouts. Drag knobs vertically, use the wheel, or use +/- controls. Existing sample editing, FX, recording and saved beats remain accessible.
- Settings separates music, ambience, cue and voice volume, with an independent subtitles toggle. Six short ElevenLabs voice clips are bundled locally. Companions encourage your turn in Echo Pads, celebrate new achievements, and speak when you explicitly choose a journal route. Cues have a 30-second cooldown and stop during recording/performance or when their context ends. Waterfront ambience ducks under speech; player music is untouched.

This is a local implementation candidate. Build/package generation is separate from Studio Play acceptance. No test suite, Studio Play run, device performance measurement or cloud-persistence verification was performed for this revision. Source geometry still exceeds the earlier authored companion triangle targets. Static textured fallbacks remain if the local mesh/image APIs cannot create a skin.


Visual guide additions: Steps and the required sound receive amber outlines during music objectives. Steps shows suggested positions for Quay metal and the exact Helper chirp reply; coral outlines identify extra chirp hits. Beats guidance shows the A/B, Shelf and Save sequence. These hints never modify your music or grant progress. The Quay map includes Echo Pads and Pulse Club route buttons; walking guidance returns to the main objective when a street game starts.


Street-life pass: four original 20-second ElevenLabs ambience beds cover the waterfront, market, cafe garden and repair workshop. The two nearest audible zones blend gradually, use positional falloff, respect Ambience/global mute, duck under companion speech and fade out for music-making and street games. Six additional residents join the existing eight: cafe conversation pair, market browsers, repair worker and promenade walker. Walking speeds and pauses vary, and nearby generic residents occasionally greet you. Decorative residents do not block player movement. No new Studio play-through or listening acceptance has been performed.


Interactive streets: Light Chase near the cafe approach challenges you to catch four lit pads before they time out. Lantern Lock on the waterfront asks you to stop a moving light inside an amber window four times. Both have server-owned timing, replay, map routes and local keepsakes. The badge panel now scrolls.

Street Set near the market (509, 0.6, 53): make an audible beat in the Roamer, then use Share / join / stop at the marked platform. It shares a snapshot using the existing opt-in listening system. Nearby generic residents pause, face the performer and move at the actual BPM; after at least four seconds of music they cheer briefly when it ends. Two additional spectators stand near the platform. Audio is still opt-in for other players. Only one courtyard/street public set can run at a time. Street sets do not bypass authored courtyard quest acceptance. Leaving the 32-stud performance area stops the set.

This revision was built and packaged; no Studio play-through, multiplayer latency test or persistence acceptance was performed.


Celebration pass: server-confirmed quest awards and all successful street-game rounds send one-way finish events to clients. Nearby residents within 38 studs cheer; observers within 90 studs see short local halo/confetti feedback. Companion cheers/claps also play on repeat wins. Original voice cues retain their cooldown and recording/performance suppression. Replays show ENCORE without awarding a duplicate keepsake. Visual bursts are rate-limited and cleaned up within 2.1 seconds; Effects OFF clears them immediately.

The keepsake collection displays earned cosmetic titles: Quay Friend at 3, Block Favorite at 6, Quay Icon at 9. Titles derive from saved keepsake progress, without currency, platform badges or uploads. A newly crossed threshold gets a title-unlock banner; loading existing progress does not replay unlocks.

Build/package creation succeeded. This celebration revision has not been verified in Studio or multiplayer.



## Usable rewards
Open WARDROBE beside the keepsake counter. Choose TITLES, PINS, CHARMS or ROAMER. Equip any earned item; choose NO TITLE / PIN / CHARM / ACCENT to remove it. Locked items show one short activity hint. These are cosmetic rewards, with no paid currency or platform badge dependency.

- Titles: QUAY FRIEND (3 keepsakes), BLOCK FAVORITE (6), QUAY ICON (9).
- Pins: all nine earned keepsake icons can be displayed above your character, alongside your chosen title. Other players receive the server-owned equipment attributes.
- Companion charms: floating Echo Disc (Echo Pads), Lantern Charm (Lantern Lock), Headliner Star (Lantern Room finale). The chosen charm follows either companion and hides when the companion hides. Original models and textures remain intact.
- Roamer accents: Coral Running Lights (clear the dock), Neighbor Teal Lights (3 keepsakes), Amber Encore Lights (6). Non-colliding accent strips travel with your van. Existing workshop finishes stay available.

Equipment is server-validated against earned progress, included in profile snapshots, and automatically queued for saving. Restoring a music pattern preserves equipped rewards. Older profiles start unequipped. Studio saves are session-only: restarting Play does not preserve unlocks or equipment. No assets or place were uploaded, and no remote persistence was exercised.

Implementation and package build only; this wardrobe revision still needs a Studio play-through for visual fit, input, respawn, multiplayer presentation and save acceptance. No test suite was added or run.
