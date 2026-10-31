# BeatMakka / Frequency Zero — Alissia & Nikolas Companions v1.0

**Repo inspected:** https://github.com/slafftrosheen/BeatMakka at `main@a4a309bdb5b8db90ddad4ddb6f07a7f61d74a29c` (2026-10-25). This is a source-compatible **candidate** package, **not applied, committed or runtime-tested** in the user's repository.

**Open:** `BeatMakka_Companions_Artbook_RU.pdf` for the visual/narrative book; `docs/COMPANION_ARTBOOK_RU.md` for complete art direction/lore; `docs/COMPANION_DEV_HANDOFF_RU.md` for exact Codex instructions and acceptance; `data/companion-production.v1.json` for IDs/budgets/status; `src/` for four Luau modules; `tools/apply_companions.py` for safe source integration.

The source patch adds an optional Alissia/Nikolas/Alone selection, server-derived contextual mission hints and a client-only temporary follower; it does **not** add new sample unlocks, rewards, genuine final NPC meshes, microphones, social chat, Tripo spend or Roblox uploads. Companion choice is a schema-2-compatible optional save field through the existing server profile pipeline.

## Integrate without committing

1. Update a clean local BeatMakka checkout and check `AGENTS.md`, current `main` and the source diff against this bundle.
2. `python bundle/tools/apply_companions.py --repo C:/your/BeatMakka --dry-run`; then apply if all anchors match.
3. Place copies of `docs/COMPANION_ARTBOOK_RU.md`, `docs/COMPANION_DEV_HANDOFF_RU.md`, `data/companion-production.v1.json` and the two candidate images under a reviewed local production path. Do not include user source photographs.
4. Use the pinned `stylua`, `selene`, and `rojo build` from the root, followed by approved Studio/mobile tests before claiming integration complete.
5. No push/publishing is performed by this delivery; repo policy requires explicit permission.

See handoff for details, known blockers, and verification matrix.
