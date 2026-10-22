# Roblox Studio GLB import guide

This guide covers the six B11-B20 candidates in [the import queue](evidence/studio-import-queue.md). For all 20 cleaned production assets and current replacement paths, see the [complete surface review](evidence/cleaned-asset-surface-review.md). P12, P14 and I05 have newer solid-geometry repair candidates because the earlier GLBs showed open or broken-looking surfaces; the three originals remain preserved for comparison. The workflow is for local review in a temporary Studio place. It does not upload assets, publish a game, or grant production permissions.

## 1. Prepare a local review place

1. Start Roblox Studio and choose **New > Baseplate**. Do not open the live production place for the first import pass.
2. Use **File > Save to File As** and save a local review place outside the production place, for example `work/studio-review/BeatMakaAssetReview.rbxl`. Keep the review place and any exported evidence out of production publishing.
3. In **View**, show **Explorer**, **Properties**, and **Output**.
4. In Explorer, create a **Folder** under `Workspace` named `AssetReview`. Add an anchored temporary floor and two anchored wall panels: one for the wall-mounted assets and one for the sign. Use neutral gray so the artbook palette is easy to judge.
5. Do not enable collaboration or publish this temporary place.

## 2. Import each candidate locally

Import one model at a time so warnings and settings remain attached to a single asset.

1. Select **File > Import** and choose the candidate `.glb` from the table below. The GLB format is supported by Studio's 3D Importer.
2. In the import preview, orbit the model and inspect every side. Review the hierarchy panel and select each child with a warning to read its specific message.
3. Set the root name to the exact name in the table. Use the project settings below. Roblox's importer defaults `Upload to Roblox` to enabled, so switch it off for this review pass.
4. Click **Import**. In Explorer, move the imported root Model into `Workspace/AssetReview` and position it on the floor or wall panel. Keep all parts anchored during this static review.
5. Save the local place. Repeat for the next candidate.

### Importer settings

| Importer setting | Review value | Why |
|---|---|---|
| Import Only As Model | On | Keep the complete candidate under one root Model. |
| Upload to Roblox | **Off** | Avoid creating inventory assets or asset IDs while still reviewing. |
| Import as Package | Off | Packages are not part of this review stage. |
| Add to Workspace | On | Insert the local model into the temporary review place. |
| Insert Using Scene Position | Off | Arrange the test row manually after import. |
| Set Pivot to Scene Origin | On | The GLB scene origin is the authored contract pivot. |
| Anchored | On | Keep the imported review meshes stationary. This is a temporary review setting; I01's moving sign will need a later hinge setup. |
| World Forward / World Up | Front / Top | Keep the intended front and upright axes; verify in the preview. |
| Scale Unit | Studs | The asset dimensions below are Roblox studs. |
| Merge Meshes | **Off** | Preserve separate named parts and interactive details. |
| Invert Negative Faces | Off | Do not change face winding unless a warning or backface inspection proves it is needed. |
| Object: Use Imported Pivot | On | Preserve authored child-part pivots. |
| Object: Ignore Vertex Colors | Off | Retain any vertex color data if present. |

The Importer can represent GLB content with nested Models and MeshParts. With `Merge Meshes` off, expect a root Model plus child hierarchy; do not delete or merge nested Models just because they are present. Compare their names and count with the mesh count in the table. The source GLBs use palette materials and UVs but no image texture maps, so missing texture-map warnings are not expected. See Roblox's [Importer settings and glTF hierarchy](https://create.roblox.com/docs/studio/importer).

## 3. Candidates and contract dimensions

All dimensions below use Roblox axis order **X (width) × Y (height) × Z (depth)**. The import preview and the local bounding-box check should match within `0.03` studs. Triangle counts are Blender 5.2.2 re-import measurements; Studio may report mesh/primitive counts differently, which should be recorded rather than silently merged.

| ID | Import name | GLB | X × Y × Z (studs) | Pivot contract | Expected MeshParts | Focus |
|---|---|---|---:|---|---:|---|
| P12 | `P12_BroadLeafPlantCluster` | `assets/cleaned/P12/P12_solid_repair_candidate.glb` | 3 × 4 × 3 | Floor-center | 15 | Check the closed, thin leaf volumes from front and back. Keep leaves non-colliding. |
| P13 | `P13_WallLampCore` | `assets/cleaned/P13/P13_art_repair_candidate.glb` | 1.5 × 2 × 1.5 | Rear-center wall mount | 6 | Verify the wall plate is against the wall and the shade/light core points into the room. This model has no Roblox light source attached. |
| P14 | `P14_UtilityJunctionBox` | `assets/cleaned/P14/P14_solid_repair_candidate.glb` | 2 × 3 × 1 | Rear-center wall mount | 8 | Check the closed beveled cabinet, socket recess and separate amber status insert. Confirm the front is visible after mounting. |
| I01 | `I01_MetalStrikeSign` | `assets/cleaned/I01/I01_art_repair_candidate.glb` | 3 × 2 × 0.3 | Upper hinge / rear-center | 7 | Verify the fixed mount and swinging sign body remain separate and that the pivot sits on the upper hinge. Keep a later gameplay hit target as a separate query-only proxy. |
| I04 | `I04_ResonatorJunction` | `assets/cleaned/I04/I04_art_repair_candidate.glb` | 3 × 4 × 1.5 | Rear-center wall mount | 14 | Check all four indicator lenses and the separate tuning dial. The mesh materials show the visual states; runtime state logic is not included. |
| I05 | `I05_ListeningPodium` | `assets/cleaned/I05/I05_solid_repair_candidate.glb` | 3 × 4 × 2 | Floor-center | 11 | Check the closed plinth, cabinet, control deck and top/front controls for gaps. Use a simple body collision proxy later. |

The importer can append `_Node` when a glTF node and mesh share the same name. Treat this as an importer naming adjustment, not a geometry error. If the expected MeshPart count differs, expand Explorer and confirm all authored parts survived before changing the import settings.

## 4. Check dimensions and pivot in Studio

1. Select one root Model under `Workspace/AssetReview`.
2. In the Importer preview, confirm **Scale Unit = Studs** and compare its dimensions with the table.
3. For a second check, open **View > Command Bar**. Rename the imported root Model exactly as in the table and put it directly under `Workspace/AssetReview`. Run this snippet for one model at a time, changing `modelName`, `expectedSize`, and `pivotKind`:

```lua
local folder = workspace:FindFirstChild("AssetReview")
assert(folder, "Create Workspace/AssetReview first")

local modelName = "P12_BroadLeafPlantCluster"
local expectedSize = Vector3.new(3, 4, 3)
local pivotKind = "floor-center" -- wall-rear or upper-hinge for the other assets
local tolerance = 0.03

local model = folder:FindFirstChild(modelName)
assert(model and model:IsA("Model"), "Imported root Model not found")

local boxFrame, actualSize = model:GetBoundingBox()
local pivotInBox = boxFrame:PointToObjectSpace(model:GetPivot().Position)
local sizeOK = math.abs(actualSize.X - expectedSize.X) <= tolerance
    and math.abs(actualSize.Y - expectedSize.Y) <= tolerance
    and math.abs(actualSize.Z - expectedSize.Z) <= tolerance

local pivotOK
if pivotKind == "floor-center" then
    pivotOK = math.abs(pivotInBox.X) <= tolerance
        and math.abs(pivotInBox.Y + actualSize.Y / 2) <= tolerance
        and math.abs(pivotInBox.Z) <= tolerance
elseif pivotKind == "wall-rear" then
    pivotOK = math.abs(pivotInBox.X) <= tolerance
        and math.abs(pivotInBox.Y) <= tolerance
        and math.abs(math.abs(pivotInBox.Z) - actualSize.Z / 2) <= tolerance
elseif pivotKind == "upper-hinge" then
    pivotOK = math.abs(pivotInBox.X) <= tolerance
        and math.abs(pivotInBox.Y - actualSize.Y / 2) <= tolerance
        and math.abs(math.abs(pivotInBox.Z) - actualSize.Z / 2) <= tolerance
end

local meshParts = 0
for _, item in model:GetDescendants() do
    if item:IsA("MeshPart") then meshParts += 1 end
end

print(string.format(
    "%s size=(%.3f, %.3f, %.3f) pivotInBounds=(%.3f, %.3f, %.3f) MeshParts=%d sizeOK=%s pivotOK=%s",
    model.Name, actualSize.X, actualSize.Y, actualSize.Z,
    pivotInBox.X, pivotInBox.Y, pivotInBox.Z, meshParts,
    tostring(sizeOK), tostring(pivotOK)
))
```

Use `pivotKind = "floor-center"` for P12 and I05, `pivotKind = "wall-rear"` for P13, P14 and I04, and `pivotKind = "upper-hinge"` for I01. For wall-mounted assets and I01, the check allows either depth-axis sign because the mount's front/back sign depends on the imported forward-axis convention; visually confirm that the pivot lies on the back/mount plane, and that I01's pivot is at the top hinge. `Model:GetBoundingBox()` returns the model's oriented bounding frame and size; `Model:GetPivot()` returns its current world pivot. See the [Model API](https://create.roblox.com/docs/reference/engine/classes/Model).

If size or pivot fails, stop and record the measured values. Do not compensate by scaling or moving individual child MeshParts in Studio. Correct the source GLB or import-axis settings, regenerate the candidate, and repeat the checks.

## 5. Review hierarchy, materials, and visual fit

For each root Model:

1. Expand it in Explorer. Confirm all expected MeshParts are present and named. Do not use **Merge Meshes** to hide missing or confusing parts.
2. Select every MeshPart and check **Size**, **Position**, **Anchored**, **CanCollide**, **CanTouch**, **CanQuery**, and appearance in Properties. Material/color values should read as the workshop palette, not default gray. These files do not include image textures.
3. Compare front, side, rear, top, and underside views against the supplied asset reference in `references/production/`. Check for holes, flipped faces, hidden/floating details, clipping, or detached parts.
4. For P12, inspect the thin closed leaves from both sides. These are solid volumes and should not depend on double-sided rendering to hide missing geometry.
5. For P13, add no `PointLight` or `SurfaceLight` during mesh-import review. A real Roblox light and its brightness/range are a later scene-integration task.
6. For I01, confirm the fixed bracket and sign body are separate before setting up a hinge. Keep the mesh static during this import pass.
7. For I04, verify four independently named indicator parts and a separate dial. For I05, verify the top insert and front status pieces have no visible gap from their supports.

## 6. Set up collision only after the visual import passes

Do not use every decorative mesh as its own physical collision surface. Follow `data/assets.json`:

- **P12:** leaves have no collision. If the cluster needs a blocker, use one simple invisible proxy for the whole plant.
- **P13 / P14:** use a simple proxy only if the prop needs to block movement; leave trim, shade, socket and status details non-colliding.
- **I01:** use a separate query-only hit target; do not make the detailed sign mesh the gameplay target. Add the hinge only in the later moving-part implementation.
- **I04:** one query proxy for interaction; indicator lenses and dial remain non-colliding.
- **I05:** use a simple body proxy; controls/status details remain non-colliding.

When a MeshPart must collide, use **CollisionFidelity = Box** for simple non-interactive props or **Hull** when a broad shape matters. Avoid **PreciseConvexDecomposition** for decorative detail. Roblox documents collision-fidelity choices and their increasing performance cost in [Collisions](https://create.roblox.com/docs/workspace/collisions). Use the viewport's collision-fidelity visualization to inspect the resulting shape. Keep `CanQuery` enabled only on parts/proxies that gameplay must raycast or select.

## 7. Save evidence and record results

For each imported candidate, create `assets/studio-evidence/<ID>/` and save:

- `01-import-preview.png` — importer preview with settings visible.
- `02-explorer-properties.png` — expanded hierarchy and root/part properties.
- `03-front-and-side.png` — viewport screenshots showing the reference-facing side and profile.
- `04-collision.png` — collision visualization, if a proxy/collision shape was configured.
- `import-result.json` — status, Studio version/date, source GLB path, measured size, pivot offset, MeshPart count, warning summary, collision choices, and evidence filenames.

Update `docs/evidence/studio-import-queue.md` from `NOT_IMPORTED` to `IMPORTED_REVIEW_PASS` only when the checks are complete. If any check fails, record `IMPORTED_REVIEW_FAIL` plus the exact issue and leave the candidate in `assets/cleaned/`. Do not overwrite the DCC source or raw Tripo GLB.

After the six local imports pass, run a separate review in the actual game place and play-test the relevant interactions. Studio import alone does not prove runtime behavior. Do not enable `Upload to Roblox`, create production asset IDs, change ownership/permissions, publish, or move files into `assets/approved/` until those steps have their own authorization and evidence. Imported assets are private by default, and Roblox moderation can delay availability; see [Roblox asset permissions and moderation](https://create.roblox.com/docs/projects/assets).

## Official references

- [Roblox Studio Importer](https://create.roblox.com/docs/studio/importer) — supported `.glb`/`.gltf` files, hierarchy, preview, import settings, warnings, and queue.
- [Roblox Model API](https://create.roblox.com/docs/reference/engine/classes/Model) — `GetBoundingBox()` and `GetPivot()` used by the local size/pivot snippet.
- [Roblox collision guidance](https://create.roblox.com/docs/workspace/collisions) — collision fidelity and visualization.
- [Roblox assets, privacy, and moderation](https://create.roblox.com/docs/projects/assets) — private-by-default asset permissions and moderation status.

Documentation checked 2026-10-22.
