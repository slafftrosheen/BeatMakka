-- Installed only by the MCP test workflow, never included in default.project.json.
local control = game:GetService("ReplicatedStorage"):WaitForChild("DocsQaControl", 80)
if not control then
    return
end
control.Report:FireServer(0, true, "Client started")
local network = game:GetService("ReplicatedStorage"):WaitForChild("MusicNetwork")
local state
local finishArtCleanup
local visiblePrompts = {}
local promptService = game:GetService("ProximityPromptService")
promptService.PromptShown:Connect(function(prompt)
    visiblePrompts[prompt] = true
end)
promptService.PromptHidden:Connect(function(prompt)
    visiblePrompts[prompt] = nil
end)
network.State.OnClientEvent:Connect(function(s)
    state = s
end)
control.Drive.OnClientEvent:Connect(function(index, action, a, b)
    local ok, result = pcall(function()
        local diagnostic
        if action == "Prompt" then
            local anchor
            for _, o in workspace.NeedleQuay:GetDescendants() do
                if
                    o:IsA("BasePart")
                    and (
                        o:GetAttribute("StationId") == a
                        or (o.Name == "DiscoveryTarget" and o.Parent:GetAttribute("DiscoveryId") == a)
                        or (a == "I05" and o.Name == "ListeningTarget")
                        or (a == "Mica" and o.Name == "MicaTalkTarget")
                        or (a == "Chapter" and o.Name == "ChapterTarget")
                        or (a == "StageBoard" and o.Name == "StageBoardTarget")
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
            local deadline = os.clock() + 2
            while not visiblePrompts[anchor.ProximityPrompt] and os.clock() < deadline do
                task.wait(0.05)
            end
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = { game.Players.LocalPlayer.Character }
            local camera = workspace.CurrentCamera
            local hit = workspace:Raycast(
                camera.CFrame.Position,
                anchor.Position - camera.CFrame.Position,
                params
            )
            diagnostic = {
                target = a,
                distance = (
                    game.Players.LocalPlayer.Character.HumanoidRootPart.Position - anchor.Position
                ).Magnitude,
                hit = hit and hit.Instance:GetFullName(),
                enabled = anchor.ProximityPrompt.Enabled,
                shown = visiblePrompts[anchor.ProximityPrompt] == true,
            }
            anchor.ProximityPrompt:InputHoldBegin()
            task.wait(0.35)
            anchor.ProximityPrompt:InputHoldEnd()
        elseif action == "InstallFinishArt" then
            assert(not finishArtCleanup, "Finish art already installed")
            finishArtCleanup =
                require(script.Parent.FinishArtQa)(require(script.Parent.FinishArtData))
        elseif action == "RemoveFinishArt" then
            if finishArtCleanup then
                finishArtCleanup()
                finishArtCleanup = nil
            end
        elseif action == "FinishEvidence" then
            diagnostic = { stations = {} }
            for _, model in workspace.NeedleQuay:GetChildren() do
                local id = model:GetAttribute("StationId")
                if not id then
                    continue
                end
                local info = { pads = 0, maps = {} }
                for _, object in model:GetDescendants() do
                    if object:IsA("BasePart") and object:GetAttribute("PadId") then
                        info.pads += 1
                    elseif object:IsA("SurfaceAppearance") then
                        table.insert(info.maps, {
                            finish = object:GetAttribute("FinishSet"),
                            color = object.ColorMapContent.Uri,
                        })
                    end
                end
                diagnostic.stations[id] = info
            end
        elseif action == "NeighborhoodEvidence" then
            local root = workspace.NeedleQuay
            diagnostic =
                { indicators = {}, crowd = root:FindFirstChild("PersonalChapterCrowd") ~= nil }
            for _, part in root:GetDescendants() do
                if part:IsA("BasePart") and part:GetAttribute("NeighborhoodMissionId") then
                    diagnostic.indicators[part:GetAttribute("NeighborhoodMissionId")] =
                        part.Color:ToHex()
                end
            end
            diagnostic.hudVisible = game.Players.LocalPlayer.PlayerGui.FrequencyZero.HubHud.Visible
        elseif action == "RoomEvidence" then
            diagnostic = { rooms = {}, pads = 0 }
            for _, model in workspace.NeedleQuay:GetChildren() do
                if model:GetAttribute("PersonalWorkshop") then
                    diagnostic.rooms[model.Name] = {
                        owner = model:GetAttribute("OwnerUserId"),
                        finish = model:GetAttribute("Finish"),
                        sign = model:GetAttribute("Sign"),
                        decor = model:GetAttribute("Decor"),
                        crates = #model.FixedDecor:GetChildren(),
                        label = model.SignMount.WorkshopSign.OwnerSign.Text,
                    }
                end
                for _, part in model:GetDescendants() do
                    if part:IsA("BasePart") and part:GetAttribute("PadId") then
                        diagnostic.pads += 1
                    end
                end
            end
        elseif action == "LeaveTest" then
            if finishArtCleanup then
                finishArtCleanup()
            end
            game:GetService("StudioTestService"):LeaveTest()
            return nil
        else
            network.Command:FireServer(action, a, b)
        end
        task.wait(0.25)
        if state then
            state._qa = diagnostic
        end
        return state
    end)
    control.Report:FireServer(index, ok, if ok then result else tostring(result))
end)
network.Command:FireServer("Hello")
control.Ready:FireServer()
