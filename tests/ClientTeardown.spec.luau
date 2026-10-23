-- Run last in a local Client session: intentionally destroys the game client script.
return function()
    local network = game.ReplicatedStorage.MusicNetwork
    local state
    local connection = network.State.OnClientEvent:Connect(function(value)
        state = value
    end)
    local function await(predicate)
        local deadline = os.clock() + 3
        repeat
            if state and predicate(state) then
                return
            end
            task.wait()
        until os.clock() >= deadline
        error("Teardown state timed out")
    end
    local ok, result = pcall(function()
        network.Command:FireServer("Hello")
        await(function(s)
            return s.station ~= nil
        end)
        network.Command:FireServer("Record")
        await(function(s)
            return s.recording
        end)
        game.Players.LocalPlayer.PlayerScripts.Client:Destroy()
        await(function(s)
            return not s.playing and not s.recording and s.station == nil
        end)
        assert(
            game.Players.LocalPlayer.PlayerGui:FindFirstChild("FrequencyZero") == nil,
            "UI survived teardown"
        )
        return { passed = true, stopped = true, released = true, uiDestroyed = true }
    end)
    connection:Disconnect()
    assert(ok, result)
    return result
end
