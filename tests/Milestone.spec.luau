-- Run through Studio MCP. Storage is injected; no live cloud writes.
return function()
    local shared = game:GetService("ReplicatedStorage").Shared
    local Book = require(shared.BeatBook)
    local Quest = require(shared.FirstPerformanceQuest)
    local Profiles = require(game.ServerScriptService.Server.ProfileStore)
    local Pattern = require(shared.Pattern)
    local checks = {}
    local function check(name, run)
        local ok, err = pcall(run)
        table.insert(
            checks,
            { name = name, passed = ok, error = if ok then nil else tostring(err) }
        )
    end
    local function expect(value, message)
        assert(value, message or "Contract not met")
    end
    local player = { UserId = 123 }
    local function profile()
        local p = Profiles.new()
        p.ready = true
        p.saveMode = "session"
        return p
    end
    check("four slots retain independent notes, assignments, mutes and BPM", function()
        local p = profile()
        for index = 1, 4 do
            expect(Book.select(p, index))
            p.pattern.bpm = 60 + index * 20
            p.pattern.rows[index][index] = true
            p.pattern.muted[index] = index == 2
            p.pattern.assignments[index] = "kick"
        end
        for index = 1, 4 do
            expect(Book.select(p, index))
            expect(p.pattern.bpm == 60 + index * 20)
            expect(p.pattern.rows[index][index] and not p.pattern.rows[index % 4 + 1][index])
            expect(p.pattern.muted[index] == (index == 2))
        end
        expect(not Book.select(p, 0) and not Book.select(p, 5))
    end)
    check("shelf snapshots all slots and rejects stale overwrite/load commands", function()
        local p = profile()
        p.pattern.rows[1][1] = true
        Book.select(p, 4)
        p.pattern.bpm = 180
        p.pattern.rows[4][16] = true
        expect(Book.store(p, 1, 0))
        p.pattern.rows[4][16] = false
        expect(p.shelf[1].slots[4].rows[4][16], "Shelf aliases working slots")
        expect(not Book.store(p, 1, 0) and not Book.load(p, 1, 0))
        expect(Book.load(p, 1, 1))
        expect(p.activeSlot == 4 and p.pattern.bpm == 180 and p.pattern.rows[4][16])
        p.pattern.rows[4][16] = false
        expect(p.shelf[1].slots[4].rows[4][16], "Loading aliases shelf data")
        expect(Book.store(p, 1, 1) and p.shelf[1].version == 2)
    end)
    check("six shelf positions are bounded and require an unmuted note", function()
        local p = profile()
        expect(not Book.store(p, 1, 0))
        p.pattern.rows[1][1] = true
        p.pattern.muted[1] = true
        expect(not Book.store(p, 1, 0))
        p.pattern.muted[1] = false
        for index = 1, 6 do
            expect(Book.store(p, index, 0))
        end
        expect(not Book.store(p, 7, 0) and not Book.store(p, 0, 0))
        expect(not Book.store(p, 1, 0 / 0) and not Book.load(p, 1, math.huge))
        expect(#p.shelf == 6 and #Book.summary(p).shelf == 6)
    end)
    check(
        "legacy schema migrates into A and upgrades without changing namespace revision",
        function()
            local legacy = Pattern.new()
            legacy.rows[3][9] = true
            legacy.bpm = 140
            local data = {
                schema = 1,
                revision = 7,
                pattern = legacy,
                unlocked = { I03 = true },
                finish = "chalk",
            }
            local storage = {
                GetAsync = function()
                    return data
                end,
                UpdateAsync = function(_, _, transform)
                    data = transform(data)
                    return data
                end,
            }
            local p = profile()
            p.saveMode = "cloud"
            Profiles.load(player, p, storage)
            expect(p.activeSlot == 1 and p.pattern.rows[3][9] and p.pattern.bpm == 140)
            expect(not Book.hasPlayableNotes(p.slots[2]) and p.shelf[1] == false and p.unlocked.I03)
            expect(Profiles.save(player, p, storage))
            expect(data.schema == 2 and data.revision == 8 and data.slots[1].rows[3][9])
            local restored = profile()
            restored.saveMode = "cloud"
            Profiles.load(player, restored, storage)
            expect(restored.pattern.rows[3][9] and restored.storageRevision == 8)
        end
    )
    check("future schemas and corrupt revisions cannot be overwritten", function()
        for _, data in
            { { schema = 3 }, { schema = 2, revision = -1 }, { schema = 2, revision = "7" } }
        do
            local writes = 0
            local storage = {
                GetAsync = function()
                    return data
                end,
                UpdateAsync = function()
                    writes += 1
                end,
            }
            local p = profile()
            p.saveMode = "cloud"
            Profiles.load(player, p, storage)
            expect(p.loadFailed and not Profiles.save(player, p, storage) and writes == 0)
        end
    end)
    check(
        "failed shelf write retains dirty work, later save round-trips every position and quest",
        function()
            local p = profile()
            p.saveMode = "cloud"
            p.pattern.rows[1][1] = true
            p.quest.accepted = true
            p.unlocked.I01 = true
            for index = 1, 6 do
                expect(Book.store(p, index, 0))
            end
            p.editVersion = 1
            local data
            local storage = {
                UpdateAsync = function()
                    error("offline")
                end,
            }
            expect(not Profiles.save(player, p, storage))
            expect(p.shelf[6] and p.saved == nil and p.editVersion ~= p.savedEditVersion)
            storage.UpdateAsync = function(_, _, transform)
                data = transform(data)
                return data
            end
            storage.GetAsync = function()
                return data
            end
            expect(Profiles.save(player, p, storage))
            local restored = profile()
            restored.saveMode = "cloud"
            Profiles.load(player, restored, storage)
            expect(
                restored.quest.accepted
                    and restored.unlocked.I01
                    and restored.shelf[6].slots[1].rows[1][1]
            )
            expect(Book.summary(restored).shelf[6].saved)
        end
    )
    check("restore retains new shelf, discovery and quest progress as dirty", function()
        local p = profile()
        p.pattern.rows[1][1] = true
        expect(Profiles.save(player, p))
        p.pattern.rows[1][1] = false
        p.pattern.rows[2][2] = true
        expect(Book.store(p, 2, 0))
        p.unlocked.I01 = true
        p.quest.accepted = true
        p.quest.completed = true
        p.editVersion += 1
        expect(Profiles.restore(p))
        expect(p.pattern.rows[1][1] and not p.pattern.rows[2][2])
        expect(p.shelf[2].slots[1].rows[2][2] and p.quest.completed and p.unlocked.I01)
        expect(p.editVersion ~= p.savedEditVersion)
    end)
    check(
        "quest requires acceptance, all discoveries and the exact successfully saved quay loop",
        function()
            local p = profile()
            p.unlocked = { I01 = true, I02 = true, I03 = true }
            p.pattern.assignments[1] = "robot_chirp"
            p.pattern.rows[1][1] = true
            expect(Book.store(p, 1, 0))
            expect(not Quest.canPerform(p, p.pattern))
            p.quest.accepted = true
            expect(not Quest.canPerform(p, p.pattern), "Unsaved in-memory shelf qualified")
            expect(Profiles.save(player, p))
            expect(Quest.canPerform(p, p.pattern))
            p.pattern.bpm = 180
            expect(not Quest.canPerform(p, p.pattern), "Changed pattern qualified")
            expect(Book.load(p, 1, 1))
            expect(Quest.canPerform(p, p.pattern))
            p.pattern.muted[1] = true
            expect(not Quest.canPerform(p, p.pattern))
            p.pattern.muted[1] = false
            p.unlocked.I02 = false
            expect(not Quest.canPerform(p, p.pattern))
            p.unlocked.I02 = true
            p.quest.completed = true
            expect(not Quest.canPerform(p, p.pattern) and Quest.summary(p).stage == "complete")
        end
    )
    local passed = 0
    for _, result in checks do
        if result.passed then
            passed += 1
        end
    end
    return { passed = passed, total = #checks, checks = checks }
end
