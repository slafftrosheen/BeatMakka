# Machine-readable project data

`assets.json`, `job_recipes.json`, and `source_registry.json` were bootstrapped from the supplied `Asset_Production_Register.xlsx` on 2026-10-22 because the referenced `data/` files were not included. Canonical IDs and the 74 package rows were preserved. The register remains unchanged. Review generated records against the full project originals before a production batch.

`job_recipes.json` records P1 geometry-first proposals for the 20 candidate assets. Every recipe defaults to `authorized: false` and has no reference path until an approved isolated image is supplied.

`needle-quay-environment.v1.json` is the supplemental Environment Production Register v1.0 from the user's 2026-10-24 source text. It records 13 buildings, four stops, seven NPC identities, 13 proposed quests, 12 material-family mappings and 61 graphic base designs. It does not append or renumber the 74 original package rows or revise the supplied workbook. `NQ-BLD-02` references canonical `H06`; the new 24×18×19 envelope conflicts with H06's 32×16×24 contract and remains unresolved. The blockout uses the canonical envelope. Existing `N00` and `P1`–`P4` IDs remain stable; NQ IDs are supplementary environment references. See `docs/needle-quay/README.md` for artwork, scene and stage status.
