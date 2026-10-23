-- Studio Server contract, excluded from game build. No live DataStore.
return function()
    local Shared = game.ReplicatedStorage.Shared
    local Chapter = require(Shared.ChapterConcert)
    local Profiles = require(game.ServerScriptService.Server.ProfileStore)
    local Book = require(Shared.BeatBook)
    local checks, current = {}, "setup"
    local function expect(value)
        assert(value, current)
    end
    local function check(name, run)
        current = name
        run()
        table.insert(checks, name)
    end
    local function prepared()
        local p = Profiles.new()
        p.quest = { accepted = true, completed = true }
        p.unlocked = { I01 = true, I02 = true, I03 = true }
        p.neighborhood = { metal_pulse = true, vent_duet = true, helper_reply = true }
        p.pattern.rows[1][1], p.pattern.rows[13][9] = true, true
        p.pattern.assignments[16] = "robot_chirp"
        p.pattern.rows[16][5] = true
        p.slots[2].rows[2][5] = true
        p.slots[2].assignments[16] = "metal_hit"
        p.slots[2].rows[16][9] = true
        expect(Book.store(p, 1, 0))
        expect(Profiles.save({ UserId = 301 }, p))
        return p
    end
    check("legacy/malformed section ledger is bounded", function()
        expect(Chapter.sanitize(nil).checkpoint == 0)
        expect(Chapter.sanitize({ checkpoint = 0 / 0 }).checkpoint == 0)
        expect(Chapter.sanitize({ completed = true }).checkpoint == 6)
        expect(not Chapter.sanitize({ completed = "true", checkpoint = 999 }).completed)
    end)
    check("court preparation and actual saved music required", function()
        local p = Profiles.new()
        expect(Chapter.start(p, 1, 0) == nil)
        p = prepared()
        p.saved = nil
        expect(Chapter.start(p, 1, 0) == nil)
    end)
    check("full musical sequence accepts chosen parts, never writes working music", function()
        local p = prepared()
        local before = Book.capture(p)
        local session = Chapter.start(p, 1, 0)
        expect(session ~= nil)
        expect(Chapter.act(session, "Rhythm", 1, 0))
        expect(not Chapter.act(session, "Support", 13, 0))
        local t = session.startedAt + session.duration
        expect(Chapter.tick(session, t) == 1)
        expect(Chapter.act(session, "Support", 13, t))
        t = session.startedAt + session.duration
        expect(Chapter.tick(session, t) == 2)
        expect(Chapter.act(session, "Break", nil, t))
        t = session.startedAt + session.duration
        expect(Chapter.tick(session, t) == 3)
        expect(Chapter.act(session, "Return", nil, t))
        t = session.startedAt + session.duration
        expect(Chapter.tick(session, t) == 4)
        expect(not Chapter.act(session, "Switch", 1, t))
        expect(Chapter.act(session, "Switch", 2, t))
        t = session.startedAt + session.duration
        expect(Chapter.tick(session, t) == 5)
        expect(Chapter.act(session, "Feature", 16, t))
        t = session.startedAt + session.duration
        expect(Chapter.tick(session, t) == 6 and session.phase == 6)
        expect(not Chapter.act(session, "Feature", 16, t))
        expect(Book.samePattern(p.pattern, before.slots[1]))
        expect(not p.chapter.completed)
    end)
    check("snapshot ownership, malformed fields and failed save protect earned state", function()
        local p = prepared()
        local session = Chapter.start(p, 1, 0)
        p.saved.shelf[1].slots[1].rows[1][1] = false
        expect(session.slots[1].rows[1][1])
        expect(not Chapter.act(session, "Rhythm", {}, 0))
        expect(not Chapter.act(session, "Owner", 1, 0))
        p.chapter = Chapter.sanitize({ checkpoint = 3 })
        p.editVersion += 1
        p.saveMode = "cloud"
        expect(not Profiles.save({ UserId = 302 }, p, {
            UpdateAsync = function()
                error("offline")
            end,
        }))
        expect(p.chapter.checkpoint == 3 and p.editVersion ~= p.savedEditVersion)
        expect(Profiles.restore(p) and p.chapter.checkpoint == 3)
        expect(p.editVersion ~= p.savedEditVersion)
    end)
    check("completed section round trips and replay cannot revoke it", function()
        local p = prepared()
        p.chapter = Chapter.sanitize({ completed = true })
        p.saveMode = "cloud"
        local data
        expect(Profiles.save({ UserId = 303 }, p, {
            UpdateAsync = function(_, _, transform)
                data = transform(nil)
                return data
            end,
        }))
        local q = Profiles.new()
        q.saveMode = "cloud"
        Profiles.load({ UserId = 303 }, q, {
            GetAsync = function()
                return data
            end,
        })
        expect(q.chapter.completed and q.chapter.checkpoint == 6)
        expect(Chapter.start(q, 1, 0) ~= nil)
        expect(q.quest.completed and q.neighborhood.helper_reply)
    end)
    check("discovery-only dead end is rejected before concert starts", function()
        local p = prepared()
        for _, pattern in p.slots do
            for pad = 1, 16 do
                pattern.rows[pad] = table.create(16, false)
            end
        end
        p.pattern.assignments[1] = "metal_hit"
        p.pattern.rows[1][1] = true
        p.pattern.assignments[2] = "vent_thump"
        p.pattern.rows[2][5] = true
        p.slots[2].assignments[1] = "kick"
        p.slots[2].rows[1][1] = true
        expect(Book.store(p, 1, 1))
        expect(Profiles.save({ UserId = 304 }, p))
        expect(Chapter.start(p, 1, 0) == nil)
    end)
    check(
        "service close commits full loops, distance stop preserves progress, retry is bounded",
        function()
            local trigger = Instance.new("BindableEvent")
            local anchor = Instance.new("Part")
            local p = prepared()
            p.ready = true
            local a, b = { UserId = 305 }, { UserId = 306 }
            local other = prepared()
            other.ready = true
            local profiles = { [a] = p, [b] = other }
            local near = { [a] = true, [b] = false }
            local changed = 0
            local service
            local ok, err = pcall(function()
                service = require(game.ServerScriptService.Server.ConcertService).new(
                    { anchor = anchor, prompt = { Triggered = trigger.Event } },
                    profiles,
                    function() end,
                    function(player)
                        if service then
                            service:stop(player)
                        end
                    end,
                    function(player)
                        return near[player]
                    end,
                    function()
                        changed += 1
                    end
                )
                trigger:Fire(a)
                task.wait()
                service:command(a, "ChapterStart", 1)
                expect(service.sessions[a] ~= nil)
                service:command(b, "ChapterStart", 1)
                expect(service.sessions[b] == nil and other.chapter.checkpoint == 0)
                service:command(a, "ChapterRhythm", 1)
                local session = service.sessions[a]
                session.startedAt = workspace:GetServerTimeNow() - session.duration - 0.1
                service:command(a, "ChapterClose")
                expect(p.chapter.checkpoint == 1 and changed == 1 and service.sessions[a] == nil)
                trigger:Fire(a)
                task.wait()
                service:command(a, "ChapterStart", 1)
                near[a] = false
                service:tick()
                expect(service.sessions[a] == nil and p.chapter.checkpoint == 1)
                near[a] = true
                trigger:Fire(a)
                task.wait()
                service:command(a, "ChapterSave")
                local first = changed
                service:command(a, "ChapterSave")
                expect(changed == first)
            end)
            trigger:Destroy()
            anchor:Destroy()
            if not ok then
                error(err)
            end
        end
    )
    return { passed = true, count = #checks, checks = checks, storage = "injected/session only" }
end
