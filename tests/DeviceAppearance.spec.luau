-- Explicit Client-only cosmetic isolation. Uses local fixture meshes, no uploads.
return function()
    local player = game.Players.LocalPlayer
    local Appearance = require(player.PlayerScripts.Client.DeviceAppearance)
    local Cosmetics = require(game.ReplicatedStorage.Shared.CosmeticCatalog)
    local root = workspace.NeedleQuay
    local fixtures = Instance.new("Model")
    fixtures.Name = "FinishQa"
    fixtures:SetAttribute("StationId", "FinishQa")
    fixtures:SetAttribute("TextureLayout", Cosmetics.TextureLayout)
    fixtures:SetAttribute("TextureResolution", 512)
    local art = Instance.new("Model")
    art.Name = "Art"
    art.Parent = fixtures
    local shell = Instance.new("MeshPart")
    shell.Name = "Shell"
    shell.Anchored = true
    shell.Parent = art
    local original = Instance.new("SurfaceAppearance")
    original.Name = "OriginalShell"
    original.Parent = shell
    local control = Instance.new("MeshPart")
    control.Name = "FunctionalPad"
    control.Anchored = true
    control.Parent = fixtures
    local controlSurface = Instance.new("SurfaceAppearance")
    controlSurface.Name = "ReadableControl"
    controlSurface.Parent = control
    local other = fixtures:Clone()
    other.Name = "FinishQaOther"
    other:SetAttribute("StationId", "FinishQaOther")
    fixtures.Parent = root
    other.Parent = root
    local appearance = Appearance.new()
    local template = Instance.new("SurfaceAppearance")
    appearance.template = function()
        return template
    end
    local size, cf, pivot = shell.Size, shell.CFrame, shell.PivotOffset
    local ok, result = pcall(function()
        for _, finish in Cosmetics.Order do
            appearance:apply({ station = "FinishQa", finish = finish })
            assert(
                shell:FindFirstChildOfClass("SurfaceAppearance"):GetAttribute("FinishSet") == finish,
                "Selected finish did not reach the shell"
            )
            assert(
                controlSurface.Parent == control,
                "Cosmetics replaced a functional control surface outside Art"
            )
            assert(
                not other.Art.Shell
                    :FindFirstChildOfClass("SurfaceAppearance")
                    :GetAttribute("TemporaryFinish"),
                "Another station was recolored"
            )
            assert(
                shell.Size == size and shell.CFrame == cf and shell.PivotOffset == pivot,
                "Finish changed geometry"
            )
            assert(
                shell.CanCollide and shell.CanQuery and shell.CanTouch,
                "Finish changed collision flags"
            )
        end
        fixtures:SetAttribute("TextureResolution", 2048)
        appearance:apply({ station = "FinishQa", finish = "chalk" })
        assert(original.Parent == shell, "Unsupported resolution retained a swapped surface")
        fixtures:SetAttribute("TextureResolution", 512)
        fixtures:SetAttribute("TextureLayout", "DifferentLayout")
        appearance:apply({ station = "FinishQa", finish = "chalk" })
        assert(original.Parent == shell, "Incompatible UV layout received an atlas")
        fixtures:SetAttribute("TextureLayout", Cosmetics.TextureLayout)
        appearance:apply({ station = "FinishQa", finish = "chalk" })
        appearance:apply({ station = nil, finish = "quay" })
        assert(original.Parent == shell, "Reset did not restore the original appearance instance")
        appearance:apply({ station = "FinishQa", finish = "coral" })
        appearance:destroy()
        assert(
            original.Parent == shell and appearance.destroyed,
            "Teardown did not restore originals"
        )
        appearance:destroy()
        appearance:apply({ station = "FinishQa", finish = "chalk" })
        assert(original.Parent == shell, "Destroyed renderer applied a finish")
        return {
            passed = true,
            finishes = 4,
            controlsUntouched = true,
            otherStationUntouched = true,
            geometryPreserved = true,
            resetAndDestroy = true,
        }
    end)
    if appearance.destroy then
        appearance:destroy()
    else
        appearance:reset()
    end
    template:Destroy()
    fixtures:Destroy()
    other:Destroy()
    assert(ok, result)
    return result
end
