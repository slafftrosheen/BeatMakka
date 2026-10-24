-- Explicit three-client small-concert integration. Never in the game build.
local service = game:GetService("StudioTestService")
local args = service:GetTestArgs()
if type(args) ~= "table" or args.suite ~= "StageAcceptance" then
    return
end
local control = Instance.new("Folder")
control.Name = "DocsQaControl"
for _, name in { "Drive", "Report", "Ready" } do
    local event = Instance.new("RemoteEvent")
    event.Name = name
    event.Parent = control
end
local ready, reports, checks = {}, {}, {}
local phase, sequence, ended = "startup", 0, false
control.Ready.OnServerEvent:Connect(function(p)
    ready[p] = true
end)
control.Report.OnServerEvent:Connect(function(p, n, ok, value)
    reports[n] = { player = p, ok = ok, value = value }
end)
control.Parent = game.ReplicatedStorage
local function finish(result)
    if not ended then
        ended = true
        service:EndTest(result)
    end
end
task.delay(180, function()
    finish({ passed = false, error = "Deadline: " .. phase, checks = checks })
end)
local function waitFor(predicate, seconds)
    local deadline = os.clock() + seconds
    repeat
        if predicate() then
            return
        end
        task.wait(0.05)
    until os.clock() >= deadline
    error("Timeout: " .. phase)
end
local function drive(p, action, a, b)
    sequence += 1
    local n = sequence
    phase = p.Name .. ":" .. action
    control.Drive:FireClient(p, n, action, a, b)
    waitFor(function()
        return reports[n] ~= nil
    end, if action == "StageEvidence" then 18 else 8)
    local r = reports[n]
    assert(r.player == p and r.ok, tostring(r.value))
    return r.value
end
local function check(name, passed)
    assert(passed, name)
    table.insert(checks, name)
end
local function move(p, pos)
    p.Character:PivotTo(CFrame.new(pos))
    p.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
    task.wait(0.3)
end
local Book = require(game.ReplicatedStorage.Shared.BeatBook)
task.spawn(function()
    local ok, err = pcall(function()
        waitFor(function()
            local count = 0
            for p in ready do
                if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    count += 1
                end
            end
            return count == 3
        end, 75)
        local owners, c = {}, nil
        for _, p in game.Players:GetPlayers() do
            local s = drive(p, "Hello")
            if s.room.stationId then
                table.insert(owners, { p = p, station = s.room.stationId })
            else
                c = p
            end
        end
        check("two performers and an independent listener ready", #owners == 2 and c ~= nil)
        local a, b = owners[1].p, owners[2].p
        local listenerBefore = drive(c, "Hello")
        for i, spec in owners do
            local x = if spec.station == "Station_1" then -8 else 8
            move(spec.p, Vector3.new(x, 6.2, 10))
            check(
                "performer " .. i .. " claims only own instrument",
                drive(spec.p, "Prompt", spec.station).station == spec.station
            )
            drive(spec.p, "Assign", 1, "style.pop.01")
            drive(spec.p, "Step", 1, if i == 1 then 1 else 9)
            drive(spec.p, "Bpm", 180)
        end
        local aBefore, bBefore = drive(a, "Hello").pattern, drive(b, "Hello").pattern
        move(a, Vector3.new(38, 5, 11))
        move(b, Vector3.new(42, 5, 8))
        move(c, Vector3.new(46, 5, 11))
        for _, p in { a, b, c } do
            local opened = drive(p, "Prompt", "StageBoard")
            local detail =
                game.HttpService:JSONEncode({ diagnostic = opened._qa, notice = opened.notice })
            check(p.Name .. " opens stage board: " .. detail, opened.stage.open)
        end
        check(
            "first preparation reserves without audio",
            drive(a, "StagePrepare").stage.canStart and drive(a, "Hello").listening == nil
        )
        check(
            "second preparation waits without audio",
            drive(b, "StagePrepare").stage.position == 2 and drive(b, "Hello").listening == nil
        )
        check("other prepared player cannot steal turn", drive(b, "StageStart").listening == nil)
        local legacy = drive(c, "Prompt", "I05")
        check(
            "legacy share respects reservation",
            legacy.listening == nil
                and legacy.notice
                and legacy.notice:find("prepared set", 1, true) ~= nil
        )
        check("offered performer explicitly starts", drive(a, "StageStart").listening.hosting)
        check("listener is not automatically subscribed", drive(c, "Hello").listening == nil)
        local joined = drive(c, "StageJoin")
        check(
            "listener explicitly joins copied pattern",
            joined.listening
                and not joined.listening.hosting
                and Book.samePattern(joined.listening.pattern, aBefore)
        )
        check(
            "listener project remains independent",
            Book.samePattern(joined.pattern, listenerBefore.pattern)
                and joined.neighborhood.completed == listenerBefore.neighborhood.completed
                and joined.quest.completed == listenerBefore.quest.completed
                and not joined.hasSave
        )
        local sound = drive(a, "StageEvidence")._qa
        check(
            "configured style sample loads and plays on performer",
            sound.playingObserved and next(sound.voices) ~= nil
        )
        local listenerSound = drive(c, "StageEvidence")._qa
        check(
            "configured sample loads and plays on opted-in listener: "
                .. game.HttpService:JSONEncode(listenerSound),
            listenerSound.playingObserved
        )
        drive(c, "LocalMuteProbe")
        check(
            "local listener mix does not alter performer volume",
            drive(a, "StageEvidence")._qa.volume == sound.volume
        )
        drive(b, "StageStop")
        check("non-owner cannot end another set", drive(a, "Hello").listening.hosting)
        check(
            "board has explicit role and no compact overlap",
            drive(a, "StageEvidence")._qa.boardVisible
                and not drive(a, "StageEvidence")._qa.compactVisible
        )
        drive(c, "StageClose")
        check(
            "leaving clears only listener",
            drive(c, "Hello").listening == nil and drive(a, "Hello").listening.hosting
        )
        drive(a, "StageStop")
        local offered = drive(b, "Hello")
        check(
            "next offer does not automatically start or carry audience",
            offered.stage.canStart
                and offered.listening == nil
                and drive(c, "Hello").listening == nil
        )
        check(
            "second performer explicitly starts own unchanged music",
            drive(b, "StageStart").listening.hosting
                and Book.samePattern(drive(b, "Hello").pattern, bBefore)
        )
        drive(a, "StageJoin")
        b.Character.Humanoid.Health = 0
        task.wait(1.5)
        check(
            "performer death clears every listener",
            drive(a, "Hello").listening == nil and drive(b, "Hello").listening == nil
        )
        check(
            "death preserves personal music",
            Book.samePattern(drive(b, "Hello").pattern, bBefore)
        )
        drive(a, "StagePrepare")
        phase = "real 30-second idle offer expiry"
        task.wait(31.2)
        check(
            "expired idle offer grants nobody audio or rights",
            not drive(a, "Hello").stage.requesting and drive(a, "Hello").listening == nil
        )
        drive(a, "StagePrepare")
        drive(a, "StageStart")
        drive(c, "Prompt", "StageBoard")
        drive(c, "StageJoin")
        sequence += 1
        control.Drive:FireClient(a, sequence, "LeaveTest")
        phase = "performer disconnect"
        waitFor(function()
            return a.Parent ~= game.Players
        end, 8)
        check(
            "disconnect clears remaining listener without replacing project",
            drive(c, "Hello").listening == nil
                and Book.samePattern(drive(c, "Hello").pattern, listenerBefore.pattern)
        )
        drive(c, "StageClose")
    end)
    finish({
        passed = ok,
        error = if ok then nil else tostring(err),
        checks = checks,
        count = #checks,
        clients = 3,
        storage = "session only",
        audio = "configured style sample engine playback; not acoustic latency/balance acceptance",
    })
end)
