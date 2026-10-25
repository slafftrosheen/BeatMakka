# Needle Quay — local artbook revision, 25 October 2026

The user rejected the earlier final-art result. This revision replaces that delivery status with **LOCAL_ARTBOOK_REVISION_IN_REVIEW**. It does not establish 100% conformity or renewed artistic acceptance.

## Delivered locally

- Thirteen building sources refined with roof trims, repair plates, ladders, framed storefronts, and scalloped awnings. Retail frontage colors use teal, cream and coral; the café uses a solid coral awning.
- User material originals copied from the refreshed OneDrive Assets library with provenance. Derived brick, plaster, wood, stone, canvas and metal maps are packaged locally. Stone and brick paint layers were adapted to the warm board palette. The incorrect vertical UV inversion and missing surface tint were fixed.
- Five supplied repository-root models adapted: camper van, modular city, tavern furniture, MIDI controller and VEF radio. Fifteen templates preserve original-file SHA-256 and measured geometry. Source files remain intact. Other newly supplied models were inventoried, not represented as used.
- Four isolated Tripo character candidates, Tori, Ivo, Naya and Ronan, cleaned and locally rigged. Sana and Nell were authored as local DCC adaptations, with distinct clothing, hair and accessories. Ten human scene instances use continuous locally skinned meshes; Mica retains the canonical robot model.
- Waterfront, docks, lamps, trees, bunting, laundry, shop details, café seating, skyline, bridge and boats. Residents move continuously; boats, foliage and cloth have restrained motion. Existing ambient audio coverage includes the demo district. Repair and restored-light feedback remain connected to quest state.
- Local portable place and companion-content ZIP with 55 unique asset definitions and 699 active checksum-verified companion files, including 184 WAV bindings.

## Evidence and scope

Studio inspection of the dedicated local place reported 55/55 definitions loaded, PBR ready, skin assembly complete and all ten human instances ready. Unique exported source geometry totals 230,191 triangles; this is not the total placed-scene triangle count. Actual Studio captures: [café](../evidence/needle-quay-artbook-pass/cafe.png), [records](../evidence/needle-quay-artbook-pass/records.png), [camper](../evidence/needle-quay-artbook-pass/camper.png).

The pinned Rojo build succeeded. Local content installation checks SHA-256 for every active file. These are focused build/import/visual inspections; no new test suite was added or run. The earlier single-client Q00–Q12 and concert evidence is retained in the historical demo report and was not rerun end-to-end after this art revision. Independent multiplayer, physical-device performance and cloud persistence remain unverified. The local unpublished place uses session saves.

The console still reports the pre-existing content-type mismatch for `rbxassetid://203785492` three times. No new material/skin error was reported. The supplied camper retains substantial source wear; supporting character hair, garments and silhouettes remain candidates for close visual review. Screenshots establish the current appearance, not final approval.

## Spending, provenance and deployment

Tripo used 200 credits: four geometry tasks at 40 and four texture tasks at 10. The final recorded balance is 10, with zero frozen. Per-operation dry runs, passing preflight inputs and real task receipts are under `docs/evidence/needle-quay-artbook-pass/tripo`. Sana and Nell incurred no Tripo cost. No unknown submission was automatically repeated.

No Roblox asset or place uploads and no Experience publication occurred. Runtime skin conversion uses ephemeral local DataModel content. Production sources and active companion files are preserved separately from unrelated in-progress gameplay/Jam changes. No push was requested or performed.

## Rebuild and open

Run the repository-pinned `rojo build default.project.json --output output/needle-quay-demo/NeedleQuay-Artbook-Pass.rbxlx`, then `python tools/package_needle_quay_demo.py`. The package helper copies the tracked launcher and README and packages only files from the active install manifest. Unzip the whole ZIP, run `Launch-NeedleQuay.ps1`, and press Play in Studio. The launcher must be rerun after Studio updates.

The Blender source preparation scripts under `tools/` preserve the authored `.blend` files, original source assets and derived-map provenance. Do not replace historical approval receipts: their hashes describe the earlier snapshot, not this revision.
