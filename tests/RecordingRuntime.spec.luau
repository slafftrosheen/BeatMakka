-- Explicit Client integration against a claimed local sampler; no cloud writes.
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
        error("Recording state timed out")
    end
    local function send(action, a, b)
        network.Command:FireServer(action, a, b)
    end
    local ok, result = pcall(function()
        send("Hello")
        await(function(s)
            return s.ready and s.station ~= nil
        end)
        send("Stop")
        await(function(s)
            return not s.playing
        end)
        for pad = 1, 16 do
            send("ClearPad", pad)
        end
        task.wait(0.2)
        send("Record")
        await(function(s)
            return s.recording
        end)
        local recordingEpoch = state.epoch
        local hitAt = state.startedAt + 0.02
        while workspace:GetServerTimeNow() < hitAt do
            task.wait()
        end
        local event = { at = hitAt, epoch = recordingEpoch }
        for pad = 1, 16 do
            send("Tap", pad, event)
        end
        await(function(s)
            for pad = 1, 16 do
                if not s.pattern.rows[pad][1] then
                    return false
                end
            end
            return true
        end)
        -- Exceed the input burst; transport uses a separate control bucket.
        for _ = 1, 160 do
            send("Tap", 1, event)
        end
        send("Stop")
        await(function(s)
            return not s.recording and not s.playing
        end)
        local editVersion = state.editVersion
        send("Tap", 2, { at = hitAt, epoch = recordingEpoch })
        send("Stop")
        task.wait(0.2)
        assert(not state.playing and not state.recording, "Stop toggled transport")
        assert(state.editVersion == editVersion, "Stopped hit edited pattern")
        return { passed = true, recordedChordPads = 16, floodedHits = 160, stopSurvived = true }
    end)
    connection:Disconnect()
    assert(ok, result)
    return result
end
