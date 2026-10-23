-- Opt-in real two-client Studio test. No live DataStore or permanent mesh claim.
local service = game:GetService("StudioTestService")
local args = service:GetTestArgs()
if type(args) ~= "table" or args.suite ~= "FinishAcceptance" then
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
local sequence, ended = 0, false
local phase = "clients becoming ready"
control.Ready.OnServerEvent:Connect(function(player)
    ready[player] = true
end)
control.Report.OnServerEvent:Connect(function(player, n, ok, value)
    reports[n] = { player = player, ok = ok, value = value }
end)
control.Parent = game.ReplicatedStorage
local function finishTest(result)
    if not ended then
        ended = true
        service:EndTest(result)
    end
end
task.delay(110, function()
    finishTest({ passed = false, error = "Finish multiplayer timeout: " .. phase, checks = checks })
end)
local function waitFor(predicate, seconds)
    local deadline = os.clock() + seconds
    repeat
        if predicate() then
            return
        end
        task.wait(0.05)
    until os.clock() > deadline
    local readyNames = {}
    for player in ready do
        table.insert(readyNames, player.Name)
    end
    error("Finish acceptance timed out: " .. phase .. "; ready=" .. table.concat(readyNames, ","))
end
local function drive(player, action, a, b)
    phase = player.Name .. ": " .. action
    sequence += 1
    local n = sequence
    control.Drive:FireClient(player, n, action, a, b)
    waitFor(function()
        return reports[n] ~= nil
    end, if action == "InstallFinishArt" then 20 else 5)
    local report = reports[n]
    assert(report.player == player and report.ok, tostring(report.value))
    return report.value
end
local function check(name, passed)
    assert(passed, name)
    table.insert(checks, name)
end
task.spawn(function()
    local ok, err = pcall(function()
        waitFor(function()
            local count = 0
            for _ in ready do
                count += 1
            end
            return count == 2
        end, 70)
        local players = game.Players:GetPlayers()
        table.sort(players, function(a, b)
            return a.Name < b.Name
        end)
        local a, b = players[1], players[2]
        for i, player in { a, b } do
            waitFor(function()
                return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            end, 5)
            player.Character:PivotTo(CFrame.new(if i == 1 then -8 else 8, 5, -1))
            drive(player, "InstallFinishArt")
            check(
                "player " .. i .. " owns its station",
                drive(player, "Prompt", "Station_" .. i).station == "Station_" .. i
            )
        end
        local ids = require(game.ReplicatedStorage.Shared.ContentIds).Images
        for i, player in { a, b } do
            for _, finish in { "quay", "chalk", "coral", "afterhours" } do
                local state = drive(player, "Finish", finish)
                check("player " .. i .. " selects " .. finish, state.finish == finish)
                local evidence = drive(player, "FinishEvidence")._qa.stations
                local own = evidence["Station_" .. i]
                local other = evidence["Station_" .. (3 - i)]
                check(
                    "player " .. i .. " real maps and controls " .. finish,
                    own.pads == 16
                        and #own.maps > 0
                        and own.maps[1].finish == finish
                        and own.maps[1].color == "rbxassetid://" .. ids["atlas." .. finish .. ".basecolor.512"]
                        and other.pads == 16
                        and other.maps[1].color
                            == "rbxassetid://" .. ids["atlas.quay.basecolor.512"]
                )
            end
        end
        drive(a, "Finish", "coral")
        drive(b, "Finish", "afterhours")
        drive(a, "Save")
        drive(a, "Finish", "chalk", "Station_2")
        check(
            "finish command cannot change other profile",
            drive(b, "Hello").finish == "afterhours"
        )
        local state = drive(a, "Hello")
        local restored = drive(a, "Restore", state.editVersion)
        check(
            "session restore retains saved finish",
            restored.finish == "coral" and restored.saveMode == "session"
        )
        check("restore leaves other profile unchanged", drive(b, "Hello").finish == "afterhours")
        for _, player in { a, b } do
            drive(player, "Release")
            drive(player, "RemoveFinishArt")
        end
    end)
    finishTest({
        passed = ok,
        error = not ok and tostring(err) or nil,
        checks = checks,
        count = #checks,
        clients = 2,
        realUploadedMaps = true,
        storage = "session only",
        geometry = "temporary H01 Client acceptance art",
    })
end)
