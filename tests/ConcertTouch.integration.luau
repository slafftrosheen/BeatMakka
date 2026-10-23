-- Studio Client integration: run near ChapterTarget in the phone simulator.
-- Opens/closes the real server encounter; does not grant eligibility or progress.
return function()
    local player = game.Players.LocalPlayer
    local network = game.ReplicatedStorage.MusicNetwork
    local state
    local connection = network.State.OnClientEvent:Connect(function(value)
        state = value
    end)
    local function waitFor(predicate)
        local deadline = os.clock() + 3
        repeat
            if predicate() then
                return
            end
            task.wait(0.1)
        until os.clock() >= deadline
        error("Concert touch integration timed out")
    end
    local ok, result = pcall(function()
        local touch = assert(player.PlayerGui:FindFirstChild("TouchGui"), "Enable phone simulation")
        local previous = touch.Enabled
        local prompt = workspace.NeedleQuay.I05.ChapterTarget.ProximityPrompt
        prompt:InputHoldBegin()
        task.wait(0.4)
        prompt:InputHoldEnd()
        waitFor(function()
            return state and state.concert.open
        end)
        assert(not touch.Enabled, "Movement controls cover the concert footer")
        assert(not player.PlayerGui.FrequencyZero.HubHud.Visible, "Hub overlaps chapter")
        -- Roblox may attempt to restore its controls after a device/UI update.
        touch.Enabled = true
        task.wait()
        assert(not touch.Enabled, "Movement controls reappeared during the concert")
        network.Command:FireServer("ChapterClose")
        waitFor(function()
            return state and not state.concert.open
        end)
        assert(touch.Enabled == previous, "Movement control setting was not restored")
        return { passed = true, hiddenWhileOpen = true, restoredAfterClose = true }
    end)
    connection:Disconnect()
    assert(ok, result)
    return result
end
