-- Opt-in real two-client mission/chapter integration; never in the production build.
local service = game:GetService("StudioTestService")
local args = service:GetTestArgs()
if type(args) ~= "table" or args.suite ~= "NeighborhoodAcceptance" then
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
local sequence, ended, phase = 0, false, "startup"
control.Ready.OnServerEvent:Connect(function(player)
    ready[player] = true
end)
control.Report.OnServerEvent:Connect(function(player, index, ok, value)
    reports[index] = { player = player, ok = ok, value = value }
end)
control.Parent = game.ReplicatedStorage
local function finish(result)
    if not ended then
        ended = true
        service:EndTest(result)
    end
end
task.delay(140, function()
    finish({ passed = false, error = "Deadline: " .. phase, checks = checks })
end)
local function waitFor(predicate, seconds)
    local deadline = os.clock() + seconds
    repeat
        if predicate() then
            return
        end
        task.wait(0.1)
    until os.clock() > deadline
    error("Timeout: " .. phase)
end
local function drive(player, action, a, b)
    phase = player.Name .. ":" .. action
    sequence += 1
    local index = sequence
    control.Drive:FireClient(player, index, action, a, b)
    waitFor(function()
        return reports[index] ~= nil
    end, 7)
    local result = reports[index]
    assert(result.player == player and result.ok, tostring(result.value))
    return result.value
end
local function check(name, passed)
    assert(passed, name)
    table.insert(checks, name)
end
local function move(player, position)
    player.Character:PivotTo(CFrame.new(position))
    player.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
    task.wait(0.3)
end
task.spawn(function()
    local ok, err = pcall(function()
        waitFor(function()
            local count = 0
            for player in ready do
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    count += 1
                end
            end
            return count == 2
        end, 70)
        local players = game.Players:GetPlayers()
        table.sort(players, function(a, b)
            return a.UserId < b.UserId
        end)
        local a, b = players[1], players[2]
        check("two ready independent profiles", drive(a, "Hello").ready and drive(b, "Hello").ready)
        move(b, Vector3.new(42, 5, 11))
        check("unprepared concert start rejected", not drive(b, "ChapterStart", 1).concert.open)
        move(a, Vector3.new(17, 4.2, 17))
        check("Mica request accepted", drive(a, "Prompt", "Mica").quest.accepted)
        for _, spec in
            {
                { "I01", Vector3.new(26, 4, -14) },
                { "I02", Vector3.new(29, 4, 5) },
                { "I03", Vector3.new(20, 4, 16) },
            }
        do
            move(a, spec[2])
            check(
                spec[1] .. " collected by real prompt",
                drive(a, "Prompt", spec[1]).unlocked[spec[1]]
            )
        end
        local station = drive(a, "Hello").room.stationId
        local x = if station == "Station_1" then -8 else 8
        move(a, Vector3.new(x, 6.2, 10))
        check("sampler entry works through its art", drive(a, "Prompt", station).station == station)
        for _, request in
            {
                { "Assign", 1, "metal_hit" },
                { "Step", 1, 1 },
                { "Step", 1, 9 },
                { "Assign", 2, "vent_thump" },
                { "Step", 2, 5 },
                { "Assign", 3, "robot_chirp" },
                { "Step", 3, 7 },
                { "Step", 4, 1 },
                { "Bpm", 180 },
                { "SelectSlot", 2 },
                { "Assign", 3, "robot_chirp" },
                { "Step", 3, 11 },
                { "Step", 4, 1 },
                { "Bpm", 180 },
                { "SelectSlot", 1 },
            }
        do
            drive(a, table.unpack(request))
        end
        check("unsaved notes earn no jobs", drive(a, "Hello").neighborhood.completed == 0)
        check(
            "successful shelf save earns all prepared jobs",
            drive(a, "ShelfStore", 1, 0).neighborhood.completed == 3
        )
        local observer = drive(b, "Hello")
        check(
            "other profile and music stay untouched",
            observer.neighborhood.completed == 0
                and not observer.hasSave
                and not observer.unlocked.I01
        )
        local before = drive(b, "NeighborhoodEvidence")._qa
        local own = drive(a, "NeighborhoodEvidence")._qa
        check(
            "reward colors are personal",
            own.indicators.metal_pulse ~= before.indicators.metal_pulse
        )
        -- Keep the observer out of the performer's approach/camera ray.
        move(b, Vector3.new(35, 4.2, 10))
        drive(a, "Release")
        move(a, Vector3.new(42, 5, 11))
        check("original courtyard session starts solo", drive(a, "Prompt", "I05").listening ~= nil)
        task.wait(2.8)
        check("original Mica quest completes", drive(a, "Hello").quest.completed)
        check(
            "chapter prompt opens and leaves listening",
            drive(a, "Prompt", "Chapter").concert.open
        )
        check(
            "chapter starts from saved owned beat",
            drive(a, "ChapterStart", 1).concert.phase == 0
        )
        drive(a, "ChapterRhythm", 4)
        check("premature musical action rejected", drive(a, "ChapterSupport", 2).concert.phase == 1)
        task.wait(2.3)
        for _, request in
            {
                { "ChapterSupport", 2 },
                { "ChapterBreak" },
                { "ChapterReturn" },
                { "ChapterSwitch", 2 },
                { "ChapterFeature", 3 },
            }
        do
            drive(a, table.unpack(request))
            task.wait(2.3)
        end
        check("six musical phases finish section", drive(a, "Hello").concert.completed)
        observer = drive(b, "NeighborhoodEvidence")
        check(
            "observer gets no chapter progress or crowd",
            not observer.concert.completed and not observer._qa.crowd
        )
        check(
            "observer environment stays unchanged",
            observer._qa.indicators.metal_pulse == before.indicators.metal_pulse
        )
        check(
            "server has no private crowd clones",
            workspace.NeedleQuay:FindFirstChild("PersonalChapterCrowd") == nil
        )
        local ownEvidence = drive(a, "NeighborhoodEvidence")._qa
        check(
            "concert heading has no hub overlay",
            not ownEvidence.hudVisible and ownEvidence.crowd
        )
        drive(a, "ChapterStart", 1)
        move(a, Vector3.new(-8, 6.2, 10))
        task.wait(1.3)
        local stopped = drive(a, "Hello").concert
        check(
            "distance interruption preserves earned completion",
            not stopped.open and stopped.completed and stopped.checkpoint == 6
        )
    end)
    finish({
        passed = ok,
        error = if ok then nil else tostring(err),
        count = #checks,
        checks = checks,
        clients = 2,
        storage = "session only; no cloud or audible claim",
    })
end)
