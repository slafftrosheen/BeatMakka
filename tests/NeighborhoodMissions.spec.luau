-- Explicit Studio Server contracts. Not part of default build.
return function()
    local Shared = game.ReplicatedStorage.Shared
    local Missions = require(Shared.NeighborhoodMissions)
    local Profiles = require(game.ServerScriptService.Server.ProfileStore)
    local Book = require(Shared.BeatBook)
    local Quest = require(Shared.FirstPerformanceQuest)
    local checks = {}
    local current = "initialization"
    local function expect(value)
        assert(value, current)
    end
    local function check(name, run)
        current = name
        run()
        table.insert(checks, name)
    end
    local function ready()
        local p = Profiles.new()
        p.quest.accepted = true
        p.unlocked = { I01 = true, I02 = true, I03 = true }
        p.pattern.assignments[1] = "metal_hit"
        p.pattern.rows[1][1], p.pattern.rows[1][9] = true, true
        p.pattern.assignments[2] = "vent_thump"
        p.pattern.rows[2][5] = true
        p.pattern.assignments[3] = "robot_chirp"
        p.pattern.rows[3][3] = true
        p.slots[2].assignments[3] = "robot_chirp"
        p.slots[2].rows[3][11] = true
        expect(Book.store(p, 1, 0))
        return p
    end
    check("malformed ledger has no arbitrary claims", function()
        local value = Missions.sanitize({ metal_pulse = 1, vent_duet = "true", helper_reply = {} })
        expect(not value.metal_pulse and not value.vent_duet and not value.helper_reply)
        expect(Missions.summary(Profiles.new()).completed == 0)
    end)
    check("working music and unsaved shelf never award jobs", function()
        local p = ready()
        expect(Missions.summary(p).completed == 0)
        expect(not Missions.summary(p).courtReady)
        expect(Profiles.save({ UserId = 201 }, p))
        expect(Missions.summary(p).completed == 3)
        expect(not Missions.summary(p).courtReady)
        p.quest.completed = true
        expect(Missions.summary(p).courtReady)
    end)
    check("muted and locked sources cannot qualify", function()
        local p = ready()
        p.unlocked.I01 = false
        expect(Profiles.save({ UserId = 202 }, p))
        expect(Missions.summary(p).completed == 0)
        local q = ready()
        q.pattern.muted[1] = true
        expect(Book.store(q, 1, 1))
        expect(Profiles.save({ UserId = 203 }, q))
        expect(Missions.summary(q).completed == 0)
    end)
    check("one rhythm duplicated on pads or tempo changes is not a second variation", function()
        local p = ready()
        p.slots[2].rows[3][11] = false
        p.slots[2].rows[3][3] = true
        p.slots[2].bpm = 120
        expect(Book.store(p, 1, 1))
        expect(Profiles.save({ UserId = 204 }, p))
        expect(
            p.neighborhood.metal_pulse
                and p.neighborhood.vent_duet
                and not p.neighborhood.helper_reply
        )
    end)
    check("failed or conflicted save does not commit rewards", function()
        for _, write in
            {
                function()
                    error("offline")
                end,
                function()
                    return nil
                end,
            }
        do
            local p = ready()
            p.saveMode = "cloud"
            expect(not Profiles.save({ UserId = 205 }, p, { UpdateAsync = write }))
            expect(Missions.summary(p).completed == 0 and p.saved == nil)
        end
    end)
    check("captured save awards only its own notes; later edits stay dirty", function()
        local p = ready()
        p.saveMode = "cloud"
        local data
        local store = {
            UpdateAsync = function(_, _, transform)
                p.pattern.rows[1][1] = false
                p.editVersion += 1
                data = transform(nil)
                return data
            end,
        }
        expect(Profiles.save({ UserId = 206 }, p, store))
        expect(Missions.summary(p).completed == 3 and p.editVersion ~= p.savedEditVersion)
        expect(data.neighborhood.helper_reply and data.slots[1].rows[1][1])
    end)
    check("old profiles default safely and successful storage round trip keeps rewards", function()
        local p = Profiles.new()
        p.saveMode = "cloud"
        Profiles.load({ UserId = 207 }, p, {
            GetAsync = function()
                return { schema = 1 }
            end,
        })
        expect(Missions.summary(p).completed == 0)
        local q = ready()
        q.saveMode = "cloud"
        local data
        expect(Profiles.save({ UserId = 208 }, q, {
            UpdateAsync = function(_, _, transform)
                data = transform(nil)
                return data
            end,
        }))
        local loaded = Profiles.new()
        loaded.saveMode = "cloud"
        Profiles.load({ UserId = 208 }, loaded, {
            GetAsync = function()
                return data
            end,
        })
        expect(Missions.summary(loaded).completed == 3)
    end)
    check(
        "music restore never revokes earned jobs; original Mica rules remain sufficient",
        function()
            local p = ready()
            expect(Profiles.save({ UserId = 209 }, p))
            p.neighborhood = Missions.sanitize(nil)
            expect(Quest.canPerform(p, p.pattern))
            p.neighborhood.metal_pulse = true
            expect(Profiles.restore(p) and p.neighborhood.metal_pulse)
            local q = Profiles.new()
            expect(Profiles.save({ UserId = 210 }, q))
            q.neighborhood.metal_pulse = true
            expect(Profiles.restore(q))
            expect(q.neighborhood.metal_pulse and q.editVersion ~= q.savedEditVersion)
        end
    )
    check("courtyard guidance distinguishes ready and completed chapter", function()
        local p = ready()
        p.neighborhood = { metal_pulse = true, vent_duet = true, helper_reply = true }
        p.quest.completed = true
        expect(Missions.summary(p).objective:find("Chapter concert", 1, true) ~= nil)
        p.chapter.completed = true
        expect(Missions.summary(p).objective:find("restored", 1, true) ~= nil)
        expect(not Missions.summary(p).objective:find("still ahead", 1, true))
    end)
    return { passed = true, count = #checks, checks = checks, storage = "injected/session only" }
end
