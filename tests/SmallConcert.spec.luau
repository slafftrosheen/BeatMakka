-- Explicit Studio Server contracts, no live cloud or audible claim.
return function()
    local function expect(value, message)
        assert(value, message or debug.traceback("SmallConcert contract failed", 2))
    end
    local Session = require(game.ServerScriptService.Server.ListeningSession)
    local Pattern = require(game.ReplicatedStorage.Shared.Pattern)
    local checks = {}
    local function fixture()
        local trigger = Instance.new("BindableEvent")
        local board = Instance.new("BindableEvent")
        local anchor = Instance.new("Part")
        local profiles, near, notices, releases, players, sent = {}, {}, {}, {}, {}, {}
        for index = 1, 6 do
            local p = { DisplayName = "Artist " .. index }
            players[index] = p
            profiles[p] = { ready = true, unlocked = {}, pattern = Pattern.new() }
            profiles[p].pattern.rows[1][index] = true
            near[p] = true
        end
        local now = 0
        local s = Session.new(
            {
                anchor = anchor,
                prompt = { Triggered = trigger.Event },
                boardPrompt = { Triggered = board.Event },
                label = {},
            },
            profiles,
            function(p, notice)
                notices[p] = notice
                sent[p] = (sent[p] or 0) + 1
            end,
            function(p)
                releases[p] = (releases[p] or 0) + 1
            end,
            function(p)
                return near[p] == true
            end,
            {
                clock = function()
                    return now
                end,
            }
        )
        local function open(p)
            s:openBoard(p)
        end
        return {
            s = s,
            profiles = profiles,
            players = players,
            near = near,
            releases = releases,
            sent = sent,
            open = open,
            clock = function(value)
                now = value
            end,
            clean = function()
                trigger:Destroy()
                board:Destroy()
                anchor:Destroy()
            end,
        }
    end
    local function check(name, run)
        local f = fixture()
        local ok, err = pcall(run, f)
        f.clean()
        expect(ok, name .. ": " .. tostring(err))
        table.insert(checks, name)
    end
    check("preparing owns an immutable snapshot and never opts into audio", function(f)
        local a = f.players[1]
        f.open(a)
        f.s:command(a, "StagePrepare")
        f.profiles[a].pattern.rows[1][1] = false
        expect(f.s.owner == nil and f.s:state(a) == nil)
        expect(f.s:stageState(a).position == 1)
        f.s:command(a, "StageStart")
        expect(f.s:state(a).pattern.rows[1][1])
        expect(not f.profiles[a].pattern.rows[1][1])
    end)
    check("queue is bounded and cannot steal a reservation or stop another set", function(f)
        for _, p in f.players do
            f.open(p)
            f.s:command(p, "StagePrepare")
        end
        expect(#f.s.stage.queue == 4)
        local a, b = f.players[1], f.players[2]
        f.s:command(b, "StageStart")
        expect(f.s.owner == nil)
        f.s:command(a, "StageStart")
        f.s:command(b, "StageStop")
        expect(f.s.owner == a and f.s:state(b) == nil)
        f.s:command(a, "StageStop")
        expect(f.s.owner == nil and f.s:stageState(b).canStart)
        expect(f.s:state(b) == nil, "Next performer was automatically joined")
    end)
    check("joining is opt-in and leaving the board clears only own participation", function(f)
        local a, b = f.players[1], f.players[2]
        f.open(a)
        f.open(b)
        f.s:command(a, "StagePrepare")
        f.s:command(a, "StageStart")
        expect(f.s:state(b) == nil)
        f.s:command(b, "StageJoin")
        expect(f.s:state(b) and not f.s:state(b).hosting)
        f.s:command(b, "StagePrepare")
        f.s:command(b, "StageClose")
        expect(f.s:state(b) == nil and not f.s:stageState(b).open)
        expect(#f.s.stage.queue == 0 and f.s.owner == a)
        expect(f.profiles[b].pattern.rows[1][2])
    end)
    check("idle offer and total request lifetimes expire without starting audio", function(f)
        local a, b = f.players[1], f.players[2]
        f.open(a)
        f.open(b)
        f.s:command(a, "StagePrepare")
        f.s:command(b, "StagePrepare")
        f.clock(31)
        f.s:tick()
        expect(#f.s.stage.queue == 1 and f.s:stageState(b).canStart and f.s.owner == nil)
        f.clock(121)
        f.s:tick()
        expect(#f.s.stage.queue == 0)
    end)
    check("range, departure and malformed requests cannot retain stage rights", function(f)
        local a, b = f.players[1], f.players[2]
        f.open(a)
        f.open(b)
        f.s:command(a, "StagePrepare")
        f.s:command(b, "StagePrepare")
        f.near[a] = false
        f.s:tick()
        expect(f.s:stageState(b).canStart and not f.s:stageState(a).open)
        f.s:depart(b)
        expect(#f.s.stage.queue == 0 and not f.s:stageState(b).open)
        f.s:command(a, "StagePrepare")
        f.s:command(a, "StageStart")
        expect(f.s.owner == nil)
    end)
    check("unassociated close cannot broadcast to waiting players", function(f)
        local a, b = f.players[1], f.players[2]
        f.open(a)
        f.s:command(a, "StagePrepare")
        local before = f.sent[a]
        f.s:command(b, "StageClose")
        expect(f.sent[a] == before, "Idle close amplified a broadcast")
    end)
    check("muted preparations and unopened commands have no stage rights", function(f)
        local a, b = f.players[1], f.players[2]
        f.open(a)
        f.profiles[a].pattern.muted[1] = true
        f.s:command(a, "StagePrepare")
        f.s:command(b, "StagePrepare")
        expect(#f.s.stage.queue == 0 and f.s.owner == nil)
    end)
    return { passed = true, count = #checks, checks = checks, storage = "none; ephemeral session" }
end
