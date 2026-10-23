-- Client-to-server local sampler integration; no cloud writes or audible claims.
return function()
    local Catalog = require(game.ReplicatedStorage.Shared.SampleCatalog)
    local network = game.ReplicatedStorage.MusicNetwork
    local state, received = nil, 0
    local connection = network.State.OnClientEvent:Connect(function(s)
        state = s
        received += 1
    end)
    local function send(action, a, b, predicate)
        local before = received
        network.Command:FireServer(action, a, b)
        local deadline = os.clock() + 4
        repeat
            task.wait()
        until (received > before and (not predicate or predicate(state))) or os.clock() > deadline
        assert(
            received > before and (not predicate or predicate(state)),
            "State timed out: " .. action
        )
    end
    local ok, result = pcall(function()
        send("Hello")
        assert(state.station and state.saveMode == "session", "Claim local test sampler first")
        send("Stop")
        send("ClearPad", 1)
        send("Step", 1, 1)
        local bpm = state.pattern.bpm
        for _, pack in Catalog.Packs do
            local version = state.editVersion
            send("Pack", pack.id, version - 1, function(s)
                return s.notice and s.notice:find("Review the kit")
            end)
            assert(state.editVersion == version, "Stale pack changed working music")
            send("Pack", pack.id, version, function(s)
                return s.editVersion == version + 1
            end)
            for pad = 1, 16 do
                assert(
                    state.pattern.assignments[pad] == pack.samples[pad].id,
                    "Kit assignment incomplete"
                )
            end
            assert(
                state.pattern.rows[1][1] and state.pattern.bpm == bpm,
                "Kit erased notes or changed tempo"
            )
        end
        send("Save", nil, nil, function(s)
            return s.hasSave and not s.saving
        end)
        local version = state.editVersion
        send("Pack", "quay", version, function(s)
            return s.editVersion == version + 1
        end)
        send("Restore", state.editVersion, nil, function(s)
            return s.pattern.assignments[1] == Catalog.Packs[11].samples[1].id
        end)
        assert(state.pattern.rows[1][1], "Style restore lost saved notes")
        return {
            passed = true,
            kitsApplied = 11,
            staleRejected = 11,
            notesAndTempoKept = true,
            sessionRoundTrip = true,
        }
    end)
    connection:Disconnect()
    assert(ok, result)
    return result
end
