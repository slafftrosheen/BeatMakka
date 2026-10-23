-- Explicit local-session integration. No published DataStore writes.
return function()
    local network = game.ReplicatedStorage.MusicNetwork
    local state
    local received = 0
    local connection = network.State.OnClientEvent:Connect(function(value)
        state = value
        received += 1
    end)
    local function send(action, a, b, predicate)
        local before = received
        network.Command:FireServer(action, a, b)
        local deadline = os.clock() + 4
        repeat
            task.wait()
        until (received > before and (not predicate or predicate(state))) or os.clock() >= deadline
        assert(
            received > before and (not predicate or predicate(state)),
            "Restore state timed out: " .. action
        )
        return state
    end
    local ok, result = pcall(function()
        send("Hello")
        assert(
            state.station and state.saveMode == "session",
            "Requires claimed local session sampler"
        )
        send("Stop")
        send("ClearPad", 1)
        send("Step", 1, 1)
        send("Save", nil, nil, function(s)
            return s.hasSave and not s.saving
        end)
        assert(state.hasSave and not state.saving, "Session save failed")
        local reviewed = state.editVersion
        send("ClearPad", 1)
        local edited = state.editVersion
        send("Restore", reviewed, nil, function(s)
            return s.editVersion == edited and string.find(s.notice or "", "Slots changed")
        end)
        assert(
            state.editVersion == edited and not state.pattern.rows[1][1],
            "Stale restore erased edits"
        )
        send("Restore", nil, nil, function(s)
            return s.editVersion == edited and string.find(s.notice or "", "Slots changed")
        end)
        assert(
            state.editVersion == edited and not state.pattern.rows[1][1],
            "Unconfirmed restore erased edits"
        )
        send("Restore", edited, nil, function(s)
            return s.pattern.rows[1][1] and s.editVersion > edited
        end)
        assert(state.pattern.rows[1][1], "Confirmed restore did not recover saved beat")
        return {
            passed = true,
            staleRejected = true,
            missingVersionRejected = true,
            savedBeatRestored = true,
        }
    end)
    connection:Disconnect()
    assert(ok, result)
    return result
end
