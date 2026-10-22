-- Real two-client integration. Ends itself; no public publishing or live DataStore access.
local service = game:GetService("StudioTestService")
local args = service:GetTestArgs()
if type(args) ~= "table" or args.suite ~= "BeatMakaDocs" then
    return
end
local Players = game:GetService("Players")
local control = Instance.new("Folder")
control.Name = "DocsQaControl"
for _, name in { "Drive", "Report", "Ready" } do
    local event = Instance.new("RemoteEvent")
    event.Name = name
    event.Parent = control
end
control.Parent = game:GetService("ReplicatedStorage")
local ready = {}
local reports = {}
local checks = {}
local index = 0
local ended = false
control.Ready.OnServerEvent:Connect(function(p)
    ready[p] = true
end)
control.Report.OnServerEvent:Connect(function(p, n, ok, value)
    reports[n] = { player = p, ok = ok, value = value }
end)
local function finish(result)
    if ended then
        return
    end
    ended = true
    print("BEATMAKA_MULTIPLAYER_RESULT " .. game.HttpService:JSONEncode(result))
    service:EndTest(result)
end
task.delay(110, function()
    finish({ passed = false, error = "Multiplayer suite exceeded 110 seconds", checks = checks })
end)
local function waitFor(predicate, seconds)
    local deadline = os.clock() + seconds
    repeat
        if predicate() then
            return
        end
        task.wait(0.05)
    until os.clock() > deadline
    local r = {}
    for p in ready do
        table.insert(r, p.Name)
    end
    local players = {}
    for _, p in Players:GetPlayers() do
        table.insert(players, p.Name)
    end
    error(
        "Timed out waiting for multiplayer state; players="
            .. table.concat(players, ",")
            .. "; ready="
            .. table.concat(r, ",")
            .. "; reports="
            .. game.HttpService:JSONEncode(reports)
    )
end
local function expect(name, value)
    assert(value, name)
    table.insert(checks, name)
end
local function drive(player, action, a, b)
    index += 1
    local n = index
    control.Drive:FireClient(player, n, action, a, b)
    waitFor(function()
        return reports[n] ~= nil
    end, 5)
    local report = reports[n]
    assert(report.ok, tostring(report.value))
    assert(report.player == player, "Wrong reporting client")
    return report.value
end
local function move(player, position)
    waitFor(function()
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        return character ~= nil
            and character:FindFirstChild("HumanoidRootPart") ~= nil
            and humanoid ~= nil
            and humanoid.Health > 0
    end, 15)
    player.Character:PivotTo(CFrame.new(position))
    task.wait(0.2)
end
task.spawn(function()
    local ok, err = pcall(function()
        waitFor(function()
            local n = 0
            for _ in ready do
                n += 1
            end
            return n == 2
        end, 70)
        local players = Players:GetPlayers()
        table.sort(players, function(a, b)
            return a.Name < b.Name
        end)
        local a, b = players[1], players[2]
        move(a, Vector3.new(-8, 5, -1))
        move(b, Vector3.new(-14, 5, -1))
        expect(
            "first player owns station one",
            drive(a, "Prompt", "Station_1").station == "Station_1"
        )
        local denied = drive(b, "Prompt", "Station_1")
        expect(
            "second player cannot take occupied station",
            denied.station == nil and string.find(denied.notice or "", "occupied") ~= nil
        )
        move(b, Vector3.new(8, 5, -1))
        expect(
            "second station can be independently occupied",
            drive(b, "Prompt", "Station_2").station == "Station_2"
        )
        drive(a, "Step", 1, 1)
        local clean = drive(b, "Hello")
        expect("patterns are personal", not clean.pattern.rows[1][1])
        drive(a, "Save")
        drive(a, "ClearPad", 1)
        expect("session restore returns saved notes", drive(a, "Restore").pattern.rows[1][1])
        drive(a, "Release")
        for _, spec in
            {
                { "I01", Vector3.new(26, 4, -11) },
                { "I02", Vector3.new(29, 3, 4) },
                { "I03", Vector3.new(20, 3, 14) },
            }
        do
            move(a, spec[2])
            drive(a, "Prompt", spec[1])
        end
        local restored = drive(a, "Hello")
        local untouched = drive(b, "Hello")
        expect(
            "discovery and restoration stay personal",
            restored.restoration == 4
                and untouched.restoration == 0
                and untouched.unlocked.I01 ~= true
        )
        move(a, Vector3.new(17, 3, 14))
        expect("Mica accepts the personal quest", drive(a, "Prompt", "Mica").quest.accepted)
        move(a, Vector3.new(-8, 5, -1))
        drive(a, "Prompt", "Station_1")
        drive(a, "SelectSlot", 2)
        drive(a, "Bpm", 140)
        drive(a, "Step", 2, 5)
        local alternate = drive(a, "Hello")
        expect(
            "slot B is independent from A",
            alternate.pattern.bpm == 140 and not alternate.pattern.rows[1][1]
        )
        drive(a, "SelectSlot", 1)
        drive(a, "Bpm", 180)
        drive(a, "Assign", 1, "robot_chirp")
        task.wait(5)
        local shelf = drive(a, "ShelfStore", 1, 0)
        expect(
            "shelf captures both patterns and saves the profile",
            shelf.book.shelf[1].saved and shelf.book.shelf[1].populated == 2
        )
        expect("saved discovery loop advances Mica to performance", shelf.quest.stage == "perform")
        local private = drive(b, "Hello")
        expect(
            "shelf and quest stay personal",
            not private.book.shelf[1].exists and not private.quest.accepted
        )
        drive(a, "Release")
        move(a, Vector3.new(42, 4, 10))
        local short = drive(a, "Prompt", "I05")
        expect(
            "saved loop begins eligible performance",
            short.listening and short.listening.questPerformance
        )
        local stopped = drive(a, "LeaveListening")
        expect(
            "stopping before a full loop earns no completion",
            not stopped.quest.completed and stopped.listening == nil
        )
        task.wait(2)
        expect(
            "cancelled session deadline cannot award quest",
            not drive(a, "Hello").quest.completed
        )
        move(a, Vector3.new(42, 4, 10))
        local host = drive(a, "Prompt", "I05")
        expect("performer shares an audible snapshot", host.listening and host.listening.hosting)
        expect("bystander is not auto-subscribed", drive(b, "Hello").listening == nil)
        task.wait(2)
        local performed = drive(a, "Hello")
        expect(
            "full loop completes and saves without an audience",
            performed.quest.completed and not performed.dirty
        )
        expect("another player's quest is not completed", not drive(b, "Hello").quest.completed)
        drive(b, "Release")
        move(b, Vector3.new(46, 4, 11))
        local listener = drive(b, "Prompt", "I05")
        expect(
            "listener explicitly joins same transport",
            listener.listening
                and not listener.listening.hosting
                and listener.listening.startedAt == host.listening.startedAt
        )
        expect(
            "listening never overwrites personal pattern",
            not listener.pattern.rows[1][1] and listener.listening.pattern.rows[1][1]
        )
        expect("listener can leave without podium", drive(b, "LeaveListening").listening == nil)
        expect("listener leaving does not stop host", drive(a, "Hello").listening.hosting)
        drive(b, "Prompt", "I05")
        move(b, Vector3.new(0, 4, -25))
        task.wait(1.1)
        expect("listener exits on distance", drive(b, "Hello").listening == nil)
        expect("distance cleanup preserves host", drive(a, "Hello").listening.hosting)
        move(b, Vector3.new(46, 4, 11))
        drive(b, "Prompt", "I05")
        a:LoadCharacterAsync()
        task.wait(0.3)
        expect("performer respawn stops all listeners", drive(b, "Hello").listening == nil)
        move(a, Vector3.new(42, 4, 10))
        drive(a, "Prompt", "I05")
        drive(b, "Prompt", "I05")
        index += 1
        control.Drive:FireClient(a, index, "LeaveTest")
        waitFor(function()
            return a.Parent == nil
        end, 10)
        task.wait(0.3)
        expect("performer disconnect stops remaining listener", drive(b, "Hello").listening == nil)
    end)
    finish({
        passed = ok,
        error = if ok then nil else tostring(err),
        diagnostic = if ok
            then nil
            else reports[index] and {
                prompt = reports[index].value._qa,
                quest = reports[index].value.quest,
                listening = reports[index].value.listening,
                notice = reports[index].value.notice,
                station = reports[index].value.station,
            },
        count = #checks,
        checks = checks,
    })
end)
