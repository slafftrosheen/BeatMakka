# Needle Quay — Remix Polish

Run Launch-NeedleQuay.cmd to install local content and open this demo. Nothing is published. Play saves remain session-only.

## Changes
- Increased runtime color texture detail: 768px companion atlases, 512px buildings, vintage vans, resident characters and UI, 384px other color maps; supporting material maps 192px. Original source images and UVs are preserved. These are larger source-derived runtime copies, not invented AI detail.
- Street skins and skeleton offsets now follow each actor's authored scale. Movement updates every rendered frame with smoother turns. Companions use stable follow positions, grounded height checks, movement hysteresis and speed-adjusted walk/run playback.
- Groovebox Leave returns beside the parked Roamer. The legacy workshop island is hidden while outside on the quay; its interior remains available when entering the van.
- Added per-pad warm/bright EQ and drive, dry audition and tempo-synced echo controls in the FX pane. Pads stay visible on the left while scrolling the sound controls on the right.
- Added Sunset Dock Remix and Grit in the Gears requests after the respective original requests. Their review checks the requested tone/drive. Completing six requests unlocks QUAY REMIXER. Existing local voice cues are reused.

## Verification and limits
- Studio Play: higher-detail materials reported zero local material failures; both supplied companions and portraits loaded. All 26 resident skins reported their correct scale.
- Actual Leave button click closed the panel and returned to the quay at 280, 3.21, 78. The old promenade was hidden outside and visible inside.
- Warm tone -0.4 produced +2.4dB lows / -3.6dB highs; drive applied 0.25. The FX pane was inspected with the persistent pad bank visible. New remix rule checks reject missing tone/drive and accept matching beats.
- Motion evidence records companion idle-turn drift and movement clip. The motion fixes address scale, cadence and following; they do not certify every deformation in the supplied approximate character weights. Full multiplayer and every mission branch remain unverified.
- Studio can emit TexturePack permission warnings from local SurfaceAppearance processing. No asset-upload or publishing operation was requested; local material readiness was verified separately.

No new dependencies, paid generation, Git commit or push.
