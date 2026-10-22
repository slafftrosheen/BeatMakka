-- Installed only by the MCP test workflow, never included in default.project.json.
local control = game:GetService("ReplicatedStorage"):WaitForChild("DocsQaControl", 80)
if not control then
    return
end
control.Report:FireServer(0, true, "Client started")
local network = game:GetService("ReplicatedStorage"):WaitForChild("MusicNetwork")
local state
network.State.OnClientEvent:Connect(function(s)
    state = s
end)
control.Drive.OnClientEvent:Connect(function(index, action, a, b)
    local ok, result = pcall(function()
        if action == "Prompt" then
            local anchor
            for _, o in workspace.NeedleQuay:GetDescendants() do
                if
                    o:IsA("BasePart")
                    and (
                        o:GetAttribute("StationId") == a
                        or (o.Name == "DiscoveryTarget" and o.Parent:GetAttribute("DiscoveryId") == a)
                        or (a == "I05" and o.Name == "ListeningTarget")
                    )
                then
                    anchor = o
                    break
                end
            end
            assert(anchor, "Missing prompt target " .. tostring(a))
            workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
            workspace.CurrentCamera.CFrame = CFrame.lookAt(
                game.Players.LocalPlayer.Character.HumanoidRootPart.Position + Vector3.new(0, 4, -7),
                anchor.Position
            )
            task.wait(0.2)
            anchor.ProximityPrompt:InputHoldBegin()
            task.wait(0.35)
            anchor.ProximityPrompt:InputHoldEnd()
        elseif action == "LeaveTest" then
            game:GetService("StudioTestService"):LeaveTest()
            return nil
        else
            network.Command:FireServer(action, a, b)
        end
        task.wait(0.25)
        return state
    end)
    control.Report:FireServer(index, ok, if ok then result else tostring(result))
end)
network.Command:FireServer("Hello")
control.Ready:FireServer()
