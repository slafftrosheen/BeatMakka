#!/usr/bin/env python3
"""Apply source-level companion integration against inspected BeatMakka main.
Fails closed on drift. Does not commit, publish, upload, or run game tests.
Usage: python tools/apply_companions.py --repo C:/path/to/BeatMakka --dry-run
       python tools/apply_companions.py --repo C:/path/to/BeatMakka
"""
from pathlib import Path
import argparse
import shutil

PATCHES = {
    "src/server/ProfileStore.luau": [
        ('local Chapter = require(Shared.ChapterConcert)\n', 'local Chapter = require(Shared.ChapterConcert)\nlocal Companions = require(Shared.CompanionCatalog)\n'),
        ('        chapter = Chapter.sanitize(nil),\n', '        chapter = Chapter.sanitize(nil),\n        companion = "none",\n'),
        ('        chapter = Chapter.sanitize(profile.chapter),\n', '        chapter = Chapter.sanitize(profile.chapter),\n        companion = Companions.normalize(profile.companion),\n'),
        ('        profile.chapter = Chapter.sanitize(data.chapter)\n', '        profile.chapter = Chapter.sanitize(data.chapter)\n        profile.companion = Companions.normalize(data.companion)\n'),
    ],
    "src/server/MusicService.luau": [
        ('local ConcertService = require(script.Parent.ConcertService)\n', 'local ConcertService = require(script.Parent.ConcertService)\nlocal Companions = require(ReplicatedStorage.Shared.CompanionCatalog)\nlocal CompanionProgress = require(ReplicatedStorage.Shared.CompanionProgress)\n'),
        ('            neighborhood = Missions.summary(profile),\n', '            neighborhood = Missions.summary(profile),\n            companion = CompanionProgress.summary(profile),\n'),
        ('        if action == "LeaveListening" then\n', '''        if action == "CompanionSelect" then
            local ok, changed = Companions.select(profile, a)
            if not ok then
                send(player, "That companion is unavailable.")
                return
            end
            if changed then
                profile.editVersion += 1
                profile.progressNeedsSave = true
                -- Save selection through the existing revision/async queue.
                drainQuestSave(player, profile)
            end
            send(player, if profile.companion == "none"
                then "Exploring solo. You can invite a companion anytime."
                else Companions.ById[profile.companion].introduction)
            return
        end
        if action == "LeaveListening" then
'''),
    ],
    "src/client/CommandPolicy.luau": [
        ('return action == "Release"\n', 'return action == "Release"\n        or (action == "CompanionSelect" and state ~= nil and state.ready)\n'),
    ],
    "src/client/init.client.luau": [
        ('local GuiFactory = require(script.GuiFactory)\n', 'local GuiFactory = require(script.GuiFactory)\nlocal CompanionView = require(script.CompanionView)\nlocal CompanionFollower = require(script.CompanionFollower)\n'),
        ('})\nconnect(UserInputService.WindowFocusReleased, function()\n', '})\nlocal companionView = CompanionView.new(view.screen, send)\nlocal companionFollower = CompanionFollower.new()\nconnect(UserInputService.WindowFocusReleased, function()\n'),
        ('    feedback:update(state)\n', '    feedback:update(state)\n    companionView:update(state)\n    companionFollower:setSelected(state.companion and state.companion.selected or "none")\n'),
        ('    concertScene:step(effects)\n', '    concertScene:step(effects)\n    companionFollower:step(dt, state)\n'),
        ('    concertScene:destroy()\n', '    concertScene:destroy()\n    companionFollower:destroy()\n'),
    ],
}
NEW = [
    "src/shared/CompanionCatalog.luau",
    "src/shared/CompanionProgress.luau",
    "src/client/CompanionView.luau",
    "src/client/CompanionFollower.luau",
]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--repo', type=Path, required=True)
    parser.add_argument('--dry-run', action='store_true')
    args = parser.parse_args()
    repo = args.repo.resolve()
    bundle = Path(__file__).resolve().parent.parent
    if not (repo / 'AGENTS.md').is_file() or not (repo / 'default.project.json').is_file():
        raise SystemExit('Wrong directory: AGENTS.md and default.project.json required')
    updates = {}
    for relative, operations in PATCHES.items():
        path = repo / relative
        old = path.read_text(encoding='utf-8')
        new = old
        for needle, replacement in operations:
            count = new.count(needle)
            if count != 1:
                raise SystemExit(f'BLOCKED: {relative}: expected exactly one anchor, got {count}: {needle[:70]!r}')
            new = new.replace(needle, replacement, 1)
        if new == old:
            raise SystemExit(f'Unexpected no-op: {relative}')
        updates[path] = new
    for relative in NEW:
        p = repo / relative
        if p.exists():
            raise SystemExit(f'BLOCKED: {relative} already exists; review current implementation')
        updates[p] = (bundle / relative).read_text(encoding='utf-8')
    print(f"Validated {len(updates)} source files against current project: {repo}")
    for p in updates:
        print(('CHECK ' if args.dry_run else 'WRITE ') + p.relative_to(repo).as_posix())
    if args.dry_run:
        print('DRY RUN: no files changed')
        return
    for path, content in updates.items():
        path.parent.mkdir(parents=True, exist_ok=True)
        # Source files are Git-managed. Do not create backup copies inside Rojo directories.
        path.write_text(content, encoding='utf-8', newline='\n')
    print('Source patch applied. Do NOT claim Studio runtime acceptance; follow docs/COMPANION_DEV_HANDOFF_RU.md.')


if __name__ == '__main__':
    main()
