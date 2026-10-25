-- Explicit Studio Server contract; fake clocks/storage never imply acoustic/cloud proof.
return function()
    local Shared = game.ReplicatedStorage.Shared
    local Protocol = require(Shared.JamProtocol)
    local Service = require(game.ServerScriptService.Server.JamService)
    local Pattern = require(Shared.Pattern)
    local checks = {}
    local function check(name, run)
        local ok, err = pcall(run)
        assert(ok, name .. ": " .. tostring(err))
        table.insert(checks, name)
    end
    local function pattern(step)
        local p = Pattern.new()
        p.assignments[1] = "style.triphop.01"
        p.rows[1][step or 1] = true
        p.bpm = 120
        return p
    end
    check("snapshot owns data and accepts only bounded compatible configured kits", function()
        local p = pattern()
        local s = assert(Protocol.capture(p, {}))
        p.rows[1][1] = false
        assert(s.pattern.rows[1][1] and s.pack == "triphop", "Snapshot alias")
        assert(#s.mask==16 and s.mask[1] and s.mask[16]==false,"Mask must stay dense on the wire")
        p = pattern()
        p.assignments[2] = "style.dance.01"
        p.rows[2][3] = true
        assert(Protocol.capture(p, {}) == nil, "Mixed kit accepted")
        p = pattern()
        p.assignments[1] = "kick"
        assert(Protocol.capture(p, {}) == nil, "Unconfigured original accepted")
        p = pattern()
        for pad = 2, 5 do
            p.assignments[pad] = "style.triphop.0" .. pad
            p.rows[pad][1] = true
        end
        assert(Protocol.capture(p, {}) == nil, "More than four pads accepted")
    end)
    check("boundary scheduling and request freshness are finite and future", function()
        assert(Protocol.boundary(1, 120, 1.2) >= 1.95, "Insufficient lead")
        assert(Protocol.boundary(1, 120, 1.2) == 3, "Not on bar")
        assert(
            Protocol.request({ generation = 2, revision = 4, at = 10 }, 2, 4, 10.2),
            "Fresh rejected"
        )
        assert(
            not Protocol.request({ generation = 2, revision = 3, at = 10 }, 2, 4, 10.2),
            "Stale revision"
        )
        assert(
            not Protocol.request({ generation = 2, revision = 4, at = 0 / 0 }, 2, 4, 10.2),
            "NaN"
        )
        assert(
            not Protocol.request({ generation = 2, revision = 4, at = 9 }, 2, 4, 10.2),
            "Late request"
        )
    end)
    local function fixture()
        local a, b, c =
            { UserId = 101, DisplayName = "A" },
            { UserId = 102, DisplayName = "B" },
            { UserId = 103, DisplayName = "C" }
        local profiles, stations = {}, {}
        for i, p in { a, b, c } do
            profiles[p] = {
                ready = true,
                station = "S" .. i,
                unlocked = {},
                pattern = pattern(i),
                playing = false,
                recording = false,
                epoch = 0,
            }
            stations["S" .. i] = { owner = p, anchor = {} }
        end
        local now, messages, near = 10, 0, true
        local service = Service.new(stations, profiles, function()
            messages += 1
        end, function() end, function()
            return near
        end, {
            now = function()
                return now
            end,
        })
        local function cmd(p, action, value)
            local s = service:state(p)
            service:command(
                p,
                action,
                { generation = s.generation, revision = s.revision, at = now, value = value }
            )
        end
        return {
            s = service,
            a = a,
            b = b,
            c = c,
            profiles = profiles,
            cmd = cmd,
            time = function(v)
                now = v
            end,
            far = function()
                near = false
            end,
            messages = function()
                return messages
            end,
        }
    end
    check("two owners share one timeline without replacing personal data", function()
        local f = fixture()
        f.cmd(f.a, "JamJoin")
        f.cmd(f.b, "JamJoin")
        f.cmd(f.c, "JamJoin")
        local a, b, c = f.s:state(f.a), f.s:state(f.b), f.s:state(f.c)
        assert(a.active and b.active and not c.active, "Cap or join")
        assert(a.session.anchor == b.session.anchor and a.session.bpm == 120, "Clock mismatch")
        assert(f.profiles[f.b].pattern.rows[1][2], "Personal data replaced")
        assert(b.session.pending["2"].applyAt > a.session.anchor, "Join not queued to bar")
    end)
    check("only own track and conductor can propose, pending snapshots stay immutable", function()
        local f = fixture()
        f.cmd(f.a, "JamJoin")
        f.cmd(f.b, "JamJoin")
        f.time(14)
        f.s:tick()
        f.cmd(f.b, "JamTempo", 140)
        assert(f.s:state(f.a).session.tempo == nil, "Guest set tempo")
        f.cmd(f.b, "JamPublish")
        f.profiles[f.b].pattern.rows[1][2] = false
        local s = f.s:state(f.b)
        assert(s.session.pending["2"].snapshot.pattern.rows[1][2], "Pending alias")
        f.s:command(
            f.a,
            "JamPublish",
            { generation = s.generation, revision = s.revision - 1, at = 14 }
        )
        assert(
            f.s:state(f.a).session.pending["1"] == nil,
            "Stale publication changed another track"
        )
    end)
    check("tempo rebases atomically at boundary and late base cannot overwrite it", function()
        local f = fixture()
        f.cmd(f.a, "JamJoin")
        f.time(11)
        f.cmd(f.a, "JamTempo", 150)
        local s = f.s:state(f.a)
        local at = s.session.tempo.applyAt
        f.time(at)
        f.s:tick()
        local nextState = f.s:state(f.a)
        assert(nextState.session.bpm == 150 and nextState.session.anchor == at, "Tempo rebase")
        f.s:command(
            f.a,
            "JamTempo",
            { generation = s.generation, revision = s.revision, at = at, value = 60 }
        )
        assert(f.s:state(f.a).session.tempo == nil, "Stale tempo accepted")
    end)
    check(
        "departure transfers conductor without resetting survivor or accepting old generation",
        function()
            local f = fixture()
            f.cmd(f.a, "JamJoin")
            f.cmd(f.b, "JamJoin")
            f.time(14)
            f.s:tick()
            local before = f.s:state(f.b)
            f.s:leave(f.a)
            local after = f.s:state(f.b)
            assert(
                after.conductor and after.session.anchor == before.session.anchor,
                "Survivor reset"
            )
            f.s:leave(f.b)
            f.cmd(f.a, "JamJoin")
            f.s:command(
                f.a,
                "JamPublish",
                { generation = before.generation, revision = before.revision, at = 14 }
            )
            assert(f.s:state(f.a).session.pending["1"] == nil, "Old generation resurrected")
        end
    )
    check("closed commands do not broadcast and station loss removes rights", function()
        local f = fixture()
        local n = f.messages()
        f.s:leave(f.c)
        assert(f.messages() == n, "No-op leave fanout")
        f.cmd(f.a, "JamJoin")
        f.far()
        f.s:tick()
        assert(not f.s:state(f.a).active, "Lost station retained jam")
    end)
    return { passed = true, count = #checks, checks = checks }
end
