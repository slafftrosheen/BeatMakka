# Needle Quay — persistent pads and local asset repair

Open this package with Launch-NeedleQuay.cmd, then start a fresh local Play session. The launcher installs and verifies the asset pack into the selected Studio version before opening the place. Nothing is uploaded or published.

The groovebox keeps all sixteen pads visible and playable while browsing Steps, Sounds, Beats and Settings. Landscape uses two equal body panes: pads on the left, selected controls on the right. Narrow portrait screens stack the two panes. The cream chassis, amber display and digital lettering remain; transport buttons now have drawn play, record and stop icons. Keyboard, touch and mouse pad handlers share the persistent bank.

The running Studio had updated to version-7aaa6838d36c4448 without the local building asset directory. All 868 content files have now been installed and SHA-256 verified there. A new Play session is required to rerun the asset loaders after failed loads.

Material failures are isolated per material and no longer abort all texture application. Supplied surface templates now carry the LocalPBR marker, preventing their descendant listener from repeatedly replacing its own clones. Texture loading no longer waits up to sixty seconds for unrelated character skin construction. A failed companion texture leaves the geometry/animation available with an explicitly reported texture fallback.

Buildings retain their authored body/plinth collision proxies. Decorative meshes belonging to authored proxy models no longer block interaction rays with their large box bounds. The scenery pass preserves authored collision decisions rather than turning cables, foliage, trim and awnings into new obstacles. Shadows and existing solid collision remain enabled. Seven supplied storefronts remain exterior shells: this change does not add walk-in interiors behind modeled doors. Existing interaction and interior-transition routes are retained.

Verification: focused pinned Selene checks passed with zero errors/warnings/parse errors; pinned Rojo built the place; all installed local content checksums passed. Runtime traversal, interaction completion, visible companions, rendered textures and responsive UI appearance remain NOT VERIFIED. Both the chat connector and a fresh current-version official StudioMCP returned an empty studios list, including after the user toggled the Studio setting. Do not classify these assets as runtime-verified until an actual Play inspection succeeds.

No commit, push, upload or publishing was performed.
