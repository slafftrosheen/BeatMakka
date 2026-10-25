# Needle Quay environment production plan

**Goal:** deliver the user's Environment Production Register v1.0, two hero concept sheets, and a separate editable district blockout.

**Spec:** `docs/needle-quay/environment-production-register-v1.0-source.ru.md` (verbatim supplied request). User selected all three deliverables on 2026-10-24. The approved style board remains visual authority.

**Architecture:** a supplemental JSON register preserves all 74 original package IDs and the original workbook. A deterministic Python authoring tool emits a native Roblox model and a dedicated Rojo scene. This is a layout prototype, separate from the existing playable workshop and pending jam edits. Concept artwork is generated with built-in imagegen, never Tripo.

**Implementation choices:** use canonical H06 dimensions for its physical proxy and retain the conflicting smaller concept envelope for review; use existing Theme/atlas palette; keep current district N00 and parking P1–P4 IDs while adding NQ aliases. No profile migration, new mission completion logic, mesh uploads or publishing in this batch.

- [x] Archive supplied source and inventory, reconcile canonical identities and add buildings/stops/NPC/quests/materials/graphics to a supplemental register.
- [x] Generate Lantern Room and Needle Records sheets against the approved board; save prompts, hashes and explicit concept-only acceptance status.
- [x] Author 13 building proxies, four parking anchors, a static van, seven NPC markers, discovery markers and a connected street/pier route in a separate `.rbxmx` model and Rojo project.
- [x] Build the local `.rbxlx` deliverable with the repository-pinned Rojo and open it in Studio when available. Record actual connection/open status separately from runtime acceptance.
- [x] Link all deliverables in the handoff. Preserve user edits. No tests, commits, pushes, Tripo calls, uploads or dependencies.

Layout coordinates, street widths and interior zoning are this batch's blockout proposals, not measured artbook facts. Art approval, DCC cleanup, actual avatar clearances, Studio save/reopen and runtime quest acceptance remain separate gates.
