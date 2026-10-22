-- Run through Studio MCP against the synced project. No live DataStore/network calls.
return function()
    local shared = game:GetService("ReplicatedStorage").Shared
    local server = game:GetService("ServerScriptService").Server
    local Pattern = require(shared.Pattern)
    local Catalog = require(shared.SampleCatalog)
    local Profiles = require(server.ProfileStore)
    local Listening = require(server.ListeningSession)
    local Kit = require(server.ModularKit)
    local checks = {}
    local currentCheck
    local function expect(value)
        assert(value, "Failed contract: " .. tostring(currentCheck))
    end
    local function check(name, run)
        currentCheck = name
        local ok, err = pcall(run)
        table.insert(
            checks,
            { name = name, passed = ok, error = if ok then nil else tostring(err) }
        )
    end
    check("sixteen independent pad rows and canonical sample assignments", function()
        local p = Pattern.new()
        expect(#p.rows == 16 and #p.assignments == 16 and #p.muted == 16)
        p.rows[1][1] = true
        expect(not p.rows[2][1] and p.assignments[16] == Catalog.List[16].id)
    end)
    check("untrusted pattern sanitization and unlock enforcement", function()
        local p = Pattern.sanitize({
            bpm = 0 / 0,
            rows = { { true, 1, "true" } },
            assignments = { "robot_chirp" },
            muted = {
                true,
            },
        }, {})
        expect(p.bpm == 96 and p.rows[1][1] and not p.rows[1][2] and not p.rows[1][3])
        expect(p.assignments[1] == "kick" and p.muted[1])
        expect(
            Pattern.sanitize({ assignments = { "robot_chirp" } }, { I03 = true }).assignments[1]
                == "robot_chirp"
        )
        for _, raw in { false, 12, "bad" } do
            expect(Pattern.sanitize(raw, {}).bpm == 96)
        end
        expect(not Pattern.integer(math.huge, 60, 180) and not Pattern.integer(60.5, 60, 180))
    end)
    check("transport phase, loop wrap and pre-roll", function()
        local a, s = Pattern.position(120, 100, 100)
        expect(a == 0 and s == 1)
        a, s = Pattern.position(120, 100, 102)
        expect(a == 16 and s == 1)
        a = Pattern.position(120, 100, 99.9)
        expect(a < 0 and Pattern.stepDuration(120) == 0.125)
    end)
    check("session snapshot restores notes/finish and retains new discoveries dirty", function()
        local p = Profiles.new()
        p.saveMode = "session"
        p.ready = true
        p.pattern.rows[1][1] = true
        p.editVersion = 1
        expect(Profiles.save({ UserId = 1 }, p))
        p.pattern.rows[1][1] = false
        p.finish = "coral"
        p.unlocked.I01 = true
        p.editVersion += 1
        expect(Profiles.restore(p))
        expect(p.pattern.rows[1][1] and p.finish == "quay" and p.unlocked.I01)
        expect(p.editVersion ~= p.savedEditVersion)
        expect(p.saved.pattern.rows[1][1] and p.saved.unlocked.I01 == nil)
    end)
    check("failed cloud load cannot overwrite existing data", function()
        local p = Profiles.new()
        p.saveMode = "cloud"
        local storage = {
            GetAsync = function()
                error("offline")
            end,
            UpdateAsync = function()
                error("must not write")
            end,
        }
        Profiles.load({ UserId = 1 }, p, storage)
        expect(p.ready and p.loadFailed and p.saveMode == "unavailable")
        expect(not Profiles.save({ UserId = 1 }, p, storage))
    end)
    check("cloud revision conflict aborts and successful snapshot excludes newer edits", function()
        local p = Profiles.new()
        p.saveMode = "cloud"
        p.ready = true
        p.editVersion = 1
        local storage = {
            UpdateAsync = function(_, _, transform)
                return transform({ schema = 1, revision = 4 })
            end,
        }
        expect(not Profiles.save({ UserId = 1 }, p, storage) and p.saved == nil)
        storage.UpdateAsync = function(_, _, transform)
            local captured = transform(nil)
            p.pattern.rows[2][3] = true
            p.editVersion += 1
            return captured
        end
        expect(Profiles.save({ UserId = 1 }, p, storage))
        expect(p.storageRevision == 1 and p.savedEditVersion == 1 and p.editVersion == 2)
        expect(not p.saved.pattern.rows[2][3] and p.pattern.rows[2][3])
    end)
    check("listening requires audible snapshot, explicit opt-in, proximity and cleanup", function()
        local triggered
        local signal = {
            Connect = function(_, callback)
                triggered = callback
            end,
        }
        local owner = { DisplayName = "Performer" }
        local guest = { DisplayName = "Listener" }
        local outsider = { DisplayName = "Outside" }
        local profiles = {}
        for _, player in { owner, guest, outsider } do
            profiles[player] = Profiles.new()
            profiles[player].ready = true
        end
        local podium = { anchor = {}, prompt = { Triggered = signal }, label = {} }
        local near = { [owner] = true, [guest] = true, [outsider] = false }
        local delivered = {}
        local session = Listening.new(podium, profiles, function(player)
            delivered[player] = true
        end, function() end, function(player)
            return near[player] == true
        end)
        local function trigger(player)
            profiles[player].lastListening = -math.huge
            triggered(player)
        end
        trigger(owner)
        expect(session.owner == nil)
        profiles[owner].pattern.rows[1][1] = true
        profiles[owner].pattern.muted[1] = true
        trigger(owner)
        expect(session.owner == nil)
        profiles[owner].pattern.muted[1] = false
        trigger(owner)
        expect(session.owner == owner and session:state(guest) == nil)
        profiles[owner].pattern.rows[1][1] = false
        expect(session:state(owner).pattern.rows[1][1])
        trigger(outsider)
        expect(session:state(outsider) == nil)
        trigger(guest)
        expect(session:state(guest) and not session:state(guest).hosting)
        session:leave(guest)
        expect(session:state(guest) == nil and session.owner == owner)
        trigger(guest)
        near[owner] = false
        session:tick()
        expect(session.owner == nil and next(session.members) == nil and delivered[guest])
    end)
    check("all 24 exact constructors and clear portal contract", function()
        local folder = Instance.new("Folder")
        local count = 0
        for id in Kit.Sizes do
            local m = Kit.create(folder, id, CFrame.identity)
            expect(m:GetAttribute("AssetId") == id and #m:GetDescendants() > 0)
            if id == "M04" then
                expect(m:GetAttribute("Clearance") == Vector2.new(6, 10))
            end
            count += 1
        end
        expect(count == 24)
        folder:Destroy()
    end)
    local passed = 0
    for _, c in checks do
        if c.passed then
            passed += 1
        end
    end
    return { passed = passed, total = #checks, checks = checks }
end
