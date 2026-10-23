-- Explicit Client test: caller supplies real candidate SurfaceAppearances in
-- AppearanceLibrary. Two renderers in one client do not prove multiplayer/rejoin.
return function()
    local Shared = game.ReplicatedStorage.Shared
    local Cosmetics = require(Shared.CosmeticCatalog)
    local Appearance = require(game.Players.LocalPlayer.PlayerScripts.Client.DeviceAppearance)
    local library = game.ReplicatedStorage.AppearanceLibrary
    local root = workspace.NeedleQuay
    local fixtures, renderers, originals = {}, {}, {}
    local function station(id)
        local model = Instance.new("Model")
        model.Name = id
        model:SetAttribute("StationId", id)
        model:SetAttribute("TextureLayout", Cosmetics.TextureLayout)
        model:SetAttribute("TextureResolution", 512)
        local art = Instance.new("Model")
        art.Name = "Art"
        art.Parent = model
        local shell = Instance.new("MeshPart")
        shell.Name = "Shell"
        shell.Parent = art
        local control = Instance.new("MeshPart")
        control.Name = "Control"
        control.Parent = model
        for _, part in { shell, control } do
            local surface = Instance.new("SurfaceAppearance")
            surface.Name = "RetainedOriginal"
            surface.Parent = part
            originals[part] = surface
        end
        model.Parent = root
        table.insert(fixtures, model)
        return model, shell, control
    end
    local ok, result = pcall(function()
        local a, shellA, controlA = station("CandidateQaA")
        local _, shellB, controlB = station("CandidateQaB")
        local first, second = Appearance.new(), Appearance.new()
        table.insert(renderers, first)
        table.insert(renderers, second)
        local size, pivot, frame = shellA.Size, shellA.PivotOffset, shellA.CFrame
        second:apply({ station = "CandidateQaB", finish = "chalk" })
        local otherSurface = shellB:FindFirstChildOfClass("SurfaceAppearance")
        for _, finish in Cosmetics.Order do
            local template = library:FindFirstChild(finish .. "_512")
            assert(
                template and template:GetAttribute("Candidate") == "assets-folder-v1",
                "Real candidate template missing"
            )
            assert(
                template.ColorMapContent.SourceType == Enum.ContentSourceType.Object,
                "Template has no editable color map"
            )
            first:apply({ station = "CandidateQaA", finish = finish })
            local applied = shellA:FindFirstChildOfClass("SurfaceAppearance")
            assert(
                applied and applied:GetAttribute("FinishSet") == finish,
                "Candidate finish was not applied"
            )
            assert(
                applied.ColorMapContent == template.ColorMapContent,
                "Candidate color map was replaced"
            )
            assert(
                applied.RoughnessMapContent == template.RoughnessMapContent,
                "Candidate roughness was replaced"
            )
            assert(
                applied.MetalnessMapContent == template.MetalnessMapContent,
                "Candidate metalness was replaced"
            )
            assert(
                shellB:FindFirstChildOfClass("SurfaceAppearance") == otherSurface,
                "Other station changed"
            )
            assert(
                originals[controlA].Parent == controlA and originals[controlB].Parent == controlB,
                "Control appearance changed"
            )
            assert(
                shellA.Size == size and shellA.PivotOffset == pivot and shellA.CFrame == frame,
                "Geometry changed"
            )
            assert(shellA.CanCollide and shellA.CanTouch and shellA.CanQuery, "Collision changed")
        end
        a:SetAttribute("TextureResolution", 2048)
        first:apply({ station = "CandidateQaA", finish = "quay" })
        assert(originals[shellA].Parent == shellA, "Unsupported resolution was accepted")
        first:destroy()
        second:destroy()
        assert(originals[shellB].Parent == shellB, "Teardown did not restore original surface")
        for _, finish in Cosmetics.Order do
            assert(
                library:FindFirstChild(finish .. "_512"),
                "Renderer destroyed a borrowed candidate template"
            )
        end
        return {
            passed = true,
            finishes = 4,
            realCandidateMaps = true,
            isolatedRenderers = 2,
            controlAndGeometryPreserved = true,
            borrowedTemplatesRetained = true,
            limitation = "Single local client; no published multiplayer or cloud persistence proof",
        }
    end)
    for _, renderer in renderers do
        renderer:destroy()
    end
    for _, model in fixtures do
        model:Destroy()
    end
    assert(ok, result)
    return result
end
