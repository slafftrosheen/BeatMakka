-- Opt-in three-client ownership/visitor test, excluded from default build.
local service = game:GetService("StudioTestService")
local args = service:GetTestArgs()
if type(args) ~= "table" or args.suite ~= "RoomAcceptance" then
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
control.Ready.OnServerEvent:Connect(function(player)
    ready[player] = true
end)
control.Report.OnServerEvent:Connect(function(player, n, ok, value)
    reports[n] = { player = player, ok = ok, value = value }
end)
control.Parent = game.ReplicatedStorage
local function finish(result)
    if not ended then
        ended = true
        service:EndTest(result)
    end
end
task.delay(120, function()
    finish({ passed = false, error = "Room acceptance deadline: " .. phase, checks = checks })
end)
local function waitFor(predicate, seconds)
    local deadline = os.clock() + seconds
    repeat
        if predicate() then
            return
        end
        task.wait(0.05)
    until os.clock() > deadline
    local names = {}
    for player in ready do
        table.insert(names, player.Name)
    end
    error(
        "Room acceptance timeout: "
            .. phase
            .. ";players="
            .. #game.Players:GetPlayers()
            .. ";ready="
            .. table.concat(names, ",")
            .. ";reports="
            .. game.HttpService:JSONEncode(reports)
    )
end
local function drive(player, action, a, b)
    phase = player.Name .. ":" .. action
    sequence += 1
    local n = sequence
    control.Drive:FireClient(player, n, action, a, b)
    waitFor(function()
        return reports[n] ~= nil
    end, 6)
    local r = reports[n]
    assert(r.player == player and r.ok, tostring(r.value))
    return r.value
end
local function check(name, passed)
    assert(passed, name)
    table.insert(checks, name)
end
local function move(player, position)
    player.Character:PivotTo(CFrame.new(position))
    task.wait(0.15)
end
task.spawn(function()
    local ok, err = pcall(function()
        waitFor(function()
            local n = 0
            for _ in ready do
                n += 1
            end
            return n == 3
        end, 75)
        local owners, visitor = {}, nil
        for _, player in game.Players:GetPlayers() do
            local s = drive(player, "Hello")
            if s.room.id then
                table.insert(owners, { player = player, state = s })
            else
                visitor = player
            end
        end
        check("two owners and one visitor", #owners == 2 and visitor ~= nil)
        local a, b = owners[1].player, owners[2].player
        local aid, bid = owners[1].state.room.id, owners[2].state.room.id
        local root = workspace.NeedleQuay
        local protected = {}
        for _, object in root:GetDescendants() do
            local ancestor = object
            local cosmetic = false
            while ancestor and ancestor ~= root do
                cosmetic = cosmetic or ancestor:GetAttribute("PersonalWorkshop") == true
                ancestor = ancestor.Parent
            end
            if object:IsA("BasePart") and not cosmetic then
                protected[object] =
                    { object.CFrame, object.Size, object.CanCollide, object.CanQuery }
            end
        end
        move(a, root[aid].SignMount.Position + Vector3.new(0, -3, -9))
        local locked = drive(a, "Room", "decor", "vinyl")
        check(
            "locked decor cannot be selected",
            locked.room.choices.decor == "none" and not locked.room.decorUnlocked
        )
        local edited = drive(a, "Room", "finish", "coral")
        check("owner selects room finish", edited.room.choices.finish == "coral")
        edited = drive(a, "Room", "sign", "beats")
        check("owner selects fixed sign", edited.room.choices.sign == "beats")
        drive(a, "Room", bid, "afterhours")
        drive(a, "Room", { owner = b.UserId }, "afterhours")
        check(
            "foreign target and malformed field cannot edit another room",
            drive(b, "Hello").room.choices.finish == "quay"
                and root[bid]:GetAttribute("Finish") == "quay"
        )
        move(visitor, root[aid].SignMount.Position + Vector3.new(0, -3, -9))
        check(
            "visitor cannot edit any room",
            drive(visitor, "Room", "finish", "chalk").room.id == nil
                and root[aid]:GetAttribute("Finish") == "coral"
        )
        for _, observer in { b, visitor } do
            local evidence = drive(observer, "RoomEvidence")._qa
            check(
                observer.Name .. " sees owner choices and native sign",
                evidence.rooms[aid].finish == "coral"
                    and evidence.rooms[aid].sign == "beats"
                    and string.find(evidence.rooms[aid].label, a.DisplayName, 1, true) ~= nil
                    and evidence.pads == 32
            )
        end
        move(a, Vector3.new(26, 4, -14))
        drive(a, "Prompt", "I01")
        check("discovery unlocks decor independently", drive(a, "Hello").room.decorUnlocked == true)
        check(
            "far-away cosmetic request rejected",
            drive(a, "Room", "finish", "chalk").room.choices.finish == "coral"
        )
        move(a, root[aid].SignMount.Position + Vector3.new(0, -3, -9))
        local decorated = drive(a, "Room", "decor", "vinyl")
        check("unlocked decor selected", decorated.room.choices.decor == "vinyl")
        local e = drive(visitor, "RoomEvidence")._qa.rooms[aid]
        check("visitor sees one bounded crate", e.decor == "vinyl" and e.crates == 1)
        move(visitor, Vector3.new(0, 4, -20))
        move(a, Vector3.new(root[aid].SignMount.Position.X, 5, -1))
        local occupied = drive(a, "Prompt", owners[1].state.room.stationId)
        assert(
            occupied.station == owners[1].state.room.stationId,
            "Station claim failed: " .. game.HttpService:JSONEncode(occupied)
        )
        check(
            "owner claims instrument before saving",
            occupied.station == owners[1].state.room.stationId
        )
        local saved = drive(a, "Save")
        check(
            "profile save reports session limitation",
            saved.hasSave and saved.saveMode == "session" and not saved.dirty
        )
        drive(a, "Room", "finish", "afterhours")
        local current = drive(a, "Hello")
        local restored = drive(a, "Restore", current.editVersion)
        check(
            "music restore keeps unsaved workshop dirty",
            restored.room.choices.finish == "afterhours" and restored.dirty
        )
        drive(a, "Release")
        check("instrument release retains workshop ownership", drive(a, "Hello").room.id == aid)
        a.Character.Humanoid.Health = 0
        task.wait(0.5)
        check("death retains workshop ownership", drive(a, "Hello").room.id == aid)
        local protectedCount = 0
        for object, before in protected do
            assert(
                object.Parent ~= nil
                    and object.CFrame == before[1]
                    and object.Size == before[2]
                    and object.CanCollide == before[3]
                    and object.CanQuery == before[4],
                "Protected geometry changed: " .. object:GetFullName()
            )
            protectedCount += 1
        end
        check(
            "all " .. protectedCount .. " functional/navigation parts unchanged",
            protectedCount > 32
        )
        sequence += 1
        control.Drive:FireClient(a, sequence, "LeaveTest")
        phase = "visitor assignment after owner disconnect"
        waitFor(function()
            return root[aid]:GetAttribute("OwnerUserId") == visitor.UserId
        end, 8)
        local assigned = drive(visitor, "Hello")
        check(
            "disconnect assigns cleared bay to visitor",
            assigned.room.id == aid
                and assigned.room.choices.finish == "quay"
                and root[aid]:GetAttribute("Decor") == "none"
        )
        check("other owner's bay preserved", drive(b, "Hello").room.id == bid)
        return protectedCount
    end)
    finish({
        passed = ok,
        error = not ok and tostring(err) or nil,
        count = #checks,
        checks = checks,
        clients = 3,
        storage = "session only",
        art = "deterministic placeholders; permanent import pending",
    })
end)
