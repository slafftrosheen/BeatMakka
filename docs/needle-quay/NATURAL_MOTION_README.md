# Needle Quay — Natural Motion

Run Launch-NeedleQuay.cmd to install the local content and open this build. Nothing is published or uploaded by this package. Play saves remain session-only.

## Repaired movement
- Rebuilt the weights for all six resident source rigs, used by 26 street characters. The previous body-region cutoffs assigned some boot vertices to hands and forearms. New continuous anatomical weights keep feet on the leg chain and blend across connected surface vertices.
- Refined the supplied Alissia and Nikolas weights against their original animation poses, with normalized nonnegative weights and at most four influences per vertex. Original GLBs, textures, topology and source animation clips are preserved.
- Added measured motion ranges per character and animation. Companion ranges blend toward their neutral idle pose, preserving a relaxed stance. Strong reactions use a readable clap where an overhead cheer would distort the supplied mesh; dance selection favors the better-supported clip.
- NPC fallback geometry moves as one intact figure while skins load, instead of animating disconnected triangle groups. Loaded NPCs ease between poses. Companion mesh sections share one sampled pose, with short transitions between clips instead of constant smoothing that delayed foot plants.
- Vertex matching now chooses the nearest source vertex within neighboring cells, including correct handling of negative zero at centre seams.

## Checks
- All 26 continuous resident skins loaded in Studio, with no skin errors and zero local material failures. Largest measured resident weight-position error was about 0.0000012 studs.
- Checked 3,536 exported companion animation frames across idle, walk, run, cheer, clap, two dances, agree/bow. For mesh edges longer than 0.015 studs, no checked edge exceeded twice its rest length after repair and motion-range adjustment; the largest was 1.945. This is a deformation diagnostic, not a claim that skin is mathematically rigid or that every intermediate blend is perfect.
- Resident walk, dance, cheer and greeting poses were measured before/after repair. The former extreme foot-to-hand stretching was eliminated in these checks.
- Close-up Studio reviews covered both supplied companions walking, dancing and clapping. The two companion mesh sections agreed at corresponding bones within 0.000044 studs, with finite transforms through walk/run/dance/clap.
- A live street resident reacted to a public beat by dancing and then cheering when it ended. This used presentation-only local cues; it did not award mission progress.
- Source lint and Rojo build passed. Whole-game multiplayer, every navigation route and human art approval remain separate acceptance steps.

Evidence: docs/evidence/needle-quay-skin-repair.
Repaired Blender derivatives and source hashes: assets/production/needle-quay/skin-repair/dcc-provenance.json.

No new dependency installation, paid generation, Roblox publishing, Git commit or push.
