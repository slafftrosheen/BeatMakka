# Approved finishes applied

23 October 2026. The user approved **assets-folder-v1** and requested use of these finishes, further Studio MCP checks and a push. Issue #8 remains open for permanent native mesh import/reopen and actual cloud rejoin. [Original approved visual review](../output/materials-assets-folder-v1/index.html), [application evidence](evidence/a01-07-application/) and [hashed evidence index](evidence/a01-07-application/evidence-index.json).

## Production and provenance

The exact candidate snapshot and retained user TIFF sources remain unchanged. [Approval](evidence/a01-07-application/approval.json) pins the reviewed commit, candidate manifest hash, review metadata, user statement and previous bindings for rollback. Candidate flags remain the historical pre-approval snapshot; subsequent acceptance is recorded separately.

Ten changed PNG maps are now production inputs: eight color maps and two roughness maps at the authored 512/1024 sizes. Both metalness maps are pixel-identical and were reused. Four palette IDs, FZ_MaterialAtlas_v1, sixteen roles and all geometry remain unchanged. `assets/production/materials/revision.json` identifies the active revision and hashes. Production provenance records distinguish the supplied alpha-derived maps from original generated audio/graphics.

Studio MCP uploaded each changed map once. All ten uploads belong to personal account **CuuteFoxey / 11274985967**, confirmed through MarketplaceService asset metadata. [Named upload batch and IDs](evidence/a01-07-application/upload-batch.json), [owner checks](evidence/a01-07-application/studio-owner-info.json). No paid charges. The existing metalness and UI IDs are retained; all 100 audio bindings and 24 original audio keys are preserved. No audio upload was attempted.

## Fresh-build runtime correction

The old fallback used `CreateSurfaceAppearanceAsync` with asset-ID Content values when a prepared Studio library was missing. Reproduction failed with `ColorMap value should be an EditableImage Content`. Official API documentation confirms that this factory accepts editable images; setting asset map properties directly also requires PluginSecurity.

Normal runtime now borrows authored templates instead of attempting unsupported runtime creation. Eight real-ID SurfaceAppearance templates are serialized in `assets/runtime/AppearanceLibrary.rbxmx` and included by `default.project.json`. Rojo's built place contains all eight surfaces and all twenty-four correct map references. [Build check](evidence/a01-07-application/rojo-template-verification.json). Injected factories remain available for explicit lifecycle tests. A missing library produces an honest unavailable preview and no forbidden creation attempt. This build inspection is not a native Studio close/reopen test.

`tools/apply_approved_finishes.py --bake --verify` verifies production bytes against the approved snapshot, baked templates, preserved audio and unchanged image IDs. The old all-content generator refuses to overwrite an active approved material revision; the guard and idempotent template bake were checked without changing any production maps ([result](evidence/a01-07-application/generator-guard.json)). Verification of the frozen candidate checks generator inputs from the pinned reviewed Git commit, so later tool/binding updates do not invalidate or silently regenerate approved pixels.

## Studio acceptance

- All fourteen current images returned fetch Success. A parented temporary ScreenGui verified **14/14 IsLoaded** and was removed. An initial unparented ImageLabel probe returned fetch Success but IsLoaded false; it did not establish GUI readiness and was replaced with the parented check. [Fetch and runtime checks](evidence/a01-07-application/studio-real-ids.json), [render-loaded result](evidence/a01-07-application/studio-images-render-loaded.json).
- The authored-library check verifies eight templates and exact real Color/Roughness/Metalness URIs, borrowed-template retention and no unsupported fallback. Existing finish isolation and async lifecycle groups pass.
- **Two actual Studio clients passed 21 checks**: each claimed its own station, selected all four finishes, saw the exact uploaded color map on the H01 test art and retained sixteen controls. The other station and other profile remained unchanged. Save/Restore retained the saved finish in **session storage**. [Two-client result](evidence/a01-07-application/studio-two-client.json).
- That two-client test used exact source H01 geometry constructed temporarily on each Client: 2,088 triangles per housing, independent controls/collision and the uploaded maps. This is actual multi-client rendering behavior with temporary geometry, not permanent mesh-import evidence. The first harness exceeded the ModuleScript Source limit; geometry JSON was split into three StringValues. Initial startup/mesh waits were too short; phase diagnostics and bounded waits matching existing Studio multiplayer tests resolved the harness timeout. No uploads were retried.
- Full-workshop neutral and dusk views were inspected with the actual controls and native display. The floating station label originally covered upper pads from the approach camera. Its offset was raised from two to four studs without changing the device or controls. The before/after captures and targeted check show all sixteen world pads on-screen, with query/collision flags intact. All four finishes were verified and captured under workshop dusk lighting. [Executed readability assertions](evidence/a01-07-application/readability-check.luau), [Control check](evidence/a01-07-application/studio-controls-readability.json), [clear dusk view](evidence/a01-07-application/gameplay-dusk-clear.jpg), [four-finish workshop comparison](evidence/a01-07-application/workshop-finishes.jpg).
- Pinned Selene/StyLua/Rojo, six offline binding safety tests and the existing eight Contracts plus eight Milestone groups pass ([fresh Studio regression result](evidence/a01-07-application/studio-regressions.json)). Independent read-only review found no actionable issues.

Testing used Studio MCP only. Temporary art, explicit QA scripts, result holders, GUI probes and editable resources were removed; Client lighting/UI were restored and Studio returned to Edit. No desktop input or foreground browser control was used. The approved image templates remain installed in Edit and in the repository build.

## Outstanding checks

The local review place still has PlaceId=0 and GameId=0. The new private test experience required by #5 has not been created, so there is no truthful cloud-save/rejoin result. Studio profiles deliberately use session storage. No production DataStore or API-services setting was changed.

No permanent H01 mesh upload is available. The prior confirmed CreateAssetAsync attempt reported that asset creation was unavailable; the current MCP surface exposes image upload but no native local-mesh importer or private-experience publisher. Editable H01 geometry and serialized image templates do not prove a permanent mesh survives native save/reopen. These remain blockers under the user's no-desktop-takeover constraint. Do not close #8 until both persistent-import and cloud-rejoin acceptance are directly established.

## Reproduce and roll back

```powershell
python -B tools/build_assets_folder_finishes.py --verify
python -B tools/apply_approved_finishes.py --bake --verify
python -B tools/prepare_finish_acceptance.py
python -B tools/prepare_finish_acceptance.py --cleanup
```

Generated QA scripts run only through Studio MCP in the named datamodel and are excluded from the default build. Launch the two-client suite through StudioTestService with `{suite="FinishAcceptance"}`; use its bounded asynchronous result holder rather than treating an MCP timeout as a pass. Keep the server-side deadline and cleanup path enabled.

Rollback maps are retained in Git commit `40fcc4cfb54adffafd76f6776660d4a720969116`. The approval record retains previous image IDs. A rollback must restore matching production bytes, merge the explicitly reviewed prior image IDs with `configure_content.py --allow-rebind --write`, regenerate the eight templates, and preserve current audio bindings. It does not require deleting or re-uploading any existing asset.
