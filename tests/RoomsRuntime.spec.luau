-- Explicit single-client network flow. No private profile hooks or storage injection.
return function()
    local network = game.ReplicatedStorage.MusicNetwork
    local state
    local connection = network.State.OnClientEvent:Connect(function(value)
        state = value
    end)
    local camera = workspace.CurrentCamera
    local beforeCamera, beforeType = camera.CFrame, camera.CameraType
    local checks = {}
    local function check(name, value)
        assert(value, name)
        table.insert(checks, name)
    end
    local function command(action, a, b)
        network.Command:FireServer(action, a, b)
        task.wait(0.3)
        return state
    end
    local function prompt(anchor, role)
        game.ReplicatedStorage.RoomRuntimeMove:InvokeServer(role)
        camera.CameraType = Enum.CameraType.Scriptable
        camera.CFrame = CFrame.lookAt(anchor.Position + Vector3.new(0, 5, -12), anchor.Position)
        task.wait(0.4)
        anchor.ProximityPrompt:InputHoldBegin()
        task.wait(0.35)
        anchor.ProximityPrompt:InputHoldEnd()
        task.wait(0.3)
    end
    local ok, result = pcall(function()
        command("Hello")
        check("loaded profile owns a workshop", state and state.ready and state.room.id ~= nil)
        local bay = workspace.NeedleQuay[state.room.id]
        local other = workspace.NeedleQuay[if state.room.id == "Room_1" then "Room_2" else "Room_1"]
        game.ReplicatedStorage.RoomRuntimeMove:InvokeServer("bay")
        task.wait(0.3)
        for _, finish in { "chalk", "coral", "afterhours", "quay" } do
            local updated = command("Room", "finish", finish)
            check(
                "network selects " .. finish,
                updated.room.choices.finish == finish and bay:GetAttribute("Finish") == finish
            )
            check(
                "other bay stays unchanged for " .. finish,
                other:GetAttribute("Finish") == "quay"
            )
        end
        check(
            "network rejects locked decor",
            command("Room", "decor", "vinyl").room.choices.decor == "none"
        )
        check(
            "native sign selection replicates",
            command("Room", "sign", "beats").room.choices.sign == "beats"
                and bay:GetAttribute("Sign") == "beats"
        )
        local metal
        for _, object in workspace.NeedleQuay:GetChildren() do
            if object:GetAttribute("DiscoveryId") == "I01" then
                metal = object.DiscoveryTarget
            end
        end
        assert(metal, "Metal discovery missing")
        prompt(metal, "metal")
        check("real discovery prompt unlocks vinyl", command("Hello").room.decorUnlocked)
        check("far edit denied", command("Room", "finish", "coral").room.choices.finish == "quay")
        local station
        for _, object in workspace.NeedleQuay:GetChildren() do
            if object:GetAttribute("StationId") == state.room.stationId then
                station = object.Interaction
            end
        end
        assert(station, "Sampler station missing")
        prompt(station, "station")
        check("real instrument prompt claimed", command("Hello").station == state.room.stationId)
        check(
            "unlocked fixed decor appears",
            command("Room", "decor", "vinyl").room.choices.decor == "vinyl"
                and #bay.FixedDecor:GetChildren() == 1
        )
        command("Room", "finish", "coral")
        local saved = command("Save")
        check(
            "real session save acknowledges cosmetics",
            saved.hasSave and not saved.dirty and saved.saveMode == "session"
        )
        command("Room", "finish", "afterhours")
        local restored = command("Restore", state.editVersion)
        check(
            "music restore preserves unsaved room and dirty state",
            restored.room.choices.finish == "afterhours" and restored.dirty
        )
        command("Room", other.Name, "chalk")
        check("foreign target rejected", other:GetAttribute("Finish") == "quay")
        command("Release")
        check(
            "release retains personal workshop",
            state.station == nil and state.room.id == bay.Name
        )
        return {
            passed = true,
            count = #checks,
            checks = checks,
            storage = state.saveMode,
            snapshot = state,
        }
    end)
    command("Release")
    connection:Disconnect()
    camera.CFrame, camera.CameraType = beforeCamera, beforeType
    assert(ok, result)
    return result
end
