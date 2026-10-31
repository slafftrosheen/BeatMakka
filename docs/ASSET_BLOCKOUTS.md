# First asset blockout contracts

These are deterministic, reversible blockout conventions derived from the supplied production atlas. They do not represent art approval or finished meshes.

## H01 sampler

- Outer housing bounds: 6 x 1.25 x 4 studs, bottom-center pivot, controls face -Z.
- Exactly 16 logical pads, in a 4 x 4 grid. `Pad_01` is the far/top-left element; `Pad_16` is near/bottom-right when viewed from above with the front at -Z.
- `src/shared/SamplerPadLayout.luau` defines non-colliding pad target bounds and centers. The 0.72-stud pad face with 0.13-stud gaps is a provisional layout inside the authored housing envelope; it does not lock screen size or final visual proportions.
- Keep the screen plane, labels, and user interface separate from generated housing geometry. No labels are baked into the mesh.

## H05 street lamp

- Overall target bounds: 2.5 x 12 x 3 studs, floor-center pivot.
- Candidate cap 900 faces; full asset cap 1,100 triangles.
- The bulb/emissive insert and Roblox light attachment remain separate. This repository has not generated or authored the final lamp mesh.

## Storefront window/awning corner

- M05 display-window bay: 8 x 12 x 1 studs.
- M03 corner post: 1 x 12 x 1 studs.
- M10 awning: 8 x 2 x 4 studs.
- Use lower-left/rear-corner bay origins, local +X across the 8-stud width, +Y up, and the storefront front toward -Z. Repeat bays on an 8-stud cadence within the 4-stud planning grid.
- `tools/reference/ArchitectureGrid.luau` computes the corner-post center and a flush awning center from those interfaces. This offline reference is excluded from the replicated game. Exact window-opening dimensions are absent from the source documents and remain unset.
