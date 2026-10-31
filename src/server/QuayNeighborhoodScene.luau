-- Local scene dressing uses existing, provenance-tracked meshes. No new uploads.
local Theme = require(game.ReplicatedStorage.Shared.Theme)
local Assets = require(script.Parent.AssetSpawner)
local Scene = {}
local names = {
    P1 = "DOCKSIDE EXCHANGE",
    P2 = "REPAIR ALLEY",
    P3 = "VINYL MARKET",
    P4 = "BREAKWATER STEPS",
    finale = "THE LANTERN ROOM",
}
function Scene.build(scene)
    local folder = Instance.new("Folder")
    folder.Name, folder.Parent = "NeighborhoodDetails", scene.root
    folder:SetAttribute("ArtStage", "LOCAL_ENVIRONMENT_ACTIVITY_CANDIDATE")
    local function part(name, size, cf, color)
        return Assets.part(folder, name, size, cf, color, false)
    end
    for _, id in { "P1", "P2", "P3", "P4", "finale" } do
        local node = if id == "finale" then scene.finale else scene.stops[id]
        local at = node.anchor.Position + Vector3.new(9, 1.8, -3)
        local rotation = CFrame.Angles(0, if id == "finale" then 0 else math.pi, 0)
        local board = part(
            "CommunityBoard_" .. id,
            Vector3.new(5, 2.5, 0.22),
            CFrame.new(at) * rotation,
            Theme.Walnut
        )
        board:SetAttribute("QuayNoticeStop", id)
        local gui = Instance.new("SurfaceGui")
        gui.Name, gui.Face, gui.SizingMode, gui.PixelsPerStud =
            "NeighborhoodNotice", Enum.NormalId.Front, Enum.SurfaceGuiSizingMode.PixelsPerStud, 70
        gui.LightInfluence, gui.Parent = 0.2, board
        local backing = Instance.new("Frame")
        backing.Size, backing.BackgroundColor3, backing.BorderSizePixel, backing.Parent =
            UDim2.fromScale(1, 1), Theme.Cream, 0, gui
        local header = Instance.new("TextLabel")
        header.BackgroundTransparency, header.Size, header.Position =
            1, UDim2.fromScale(0.94, 0.25), UDim2.fromScale(0.03, 0.02)
        header.Text, header.Font, header.TextSize, header.TextColor3 =
            names[id], Theme.Bold, 22, Theme.Teal
        header.Parent = backing
        local status = Instance.new("TextLabel")
        status.Name, status.BackgroundTransparency, status.Size, status.Position =
            "Status", 1, UDim2.fromScale(0.94, 0.68), UDim2.fromScale(0.03, 0.29)
        status.Text, status.TextWrapped, status.Font, status.TextSize, status.TextColor3 =
            "MAKING ROOM\nEvery small idea belongs", true, Theme.Font, 26, Theme.Ink
        status.Parent = gui
        for _, dx in { -1.8, 1.8 } do
            local stand = part(
                "NoticeboardLeg",
                Vector3.new(0.16, 3.1, 0.16),
                CFrame.new(at + Vector3.new(dx, -2.5, 0)),
                Theme.Walnut
            )
            stand.Material = Enum.Material.Wood
        end
        Assets.place(
            folder,
            "NQ-BENCH-01",
            CFrame.new(at + Vector3.new(5, -3.8, 0)) * rotation,
            Vector3.new(5.5, 2.6, 2.1),
            Theme.Walnut,
            false
        )
        Assets.place(
            folder,
            "P11",
            CFrame.new(at + Vector3.new(-3.5, -3.4, 0)),
            Vector3.new(1.4, 1.4, 1.4),
            Theme.Coral,
            false
        )
        Assets.place(
            folder,
            "P12",
            CFrame.new(at + Vector3.new(-3.5, -2.3, 0)),
            Vector3.new(2, 2.7, 2),
            Theme.FadedTeal,
            false
        )
    end
    -- A real market listening nook, beside the existing cases rather than in its aisle.
    local stage = scene.buildings["NQ-BLD-04"].anchor.Position + Vector3.new(0, 5, -8)
    for _, dx in { -11, 11 } do
        part(
            "MarketLightPost",
            Vector3.new(0.18, 6, 0.18),
            CFrame.new(stage + Vector3.new(dx, -2, 0)),
            Theme.Walnut
        )
    end
    for index = 0, 8 do
        local offset = Vector3.new(-11 + index * 2.75, -math.sin(index / 8 * math.pi) * 0.55, 0)
        local bulb = part(
            "MarketListeningLight",
            Vector3.new(0.22, 0.32, 0.22),
            CFrame.new(stage + offset),
            Theme.Amber
        )
        bulb:SetAttribute("QuayRestoration", true)
        bulb:SetAttribute("QuayRestorationStop", "P3")
        bulb:SetAttribute("PracticalBrightness", 0.3)
        local light = Instance.new("PointLight")
        light.Color, light.Range, light.Brightness, light.Shadows, light.Parent =
            Theme.Amber, 8, 0.15, false, bulb
        if index < 8 then
            local nextOffset = Vector3.new(
                -11 + (index + 1) * 2.75,
                -math.sin((index + 1) / 8 * math.pi) * 0.55,
                0
            )
            local a, b = stage + offset, stage + nextOffset
            part(
                "FestoonCable",
                Vector3.new(0.04, 0.04, (b - a).Magnitude),
                CFrame.lookAt((a + b) / 2, b),
                Theme.Graphite
            )
        end
    end
    -- Local restoration tags are projections; they do not edit any shared server light.
    for _, object in scene.root:GetDescendants() do
        if
            object:IsA("BasePart")
            and object:GetAttribute("QuayRestoration")
            and not object:GetAttribute("QuayRestorationStop")
        then
            local selected, distance
            for _, id in { "P1", "P2", "P3", "P4", "finale" } do
                local node = if id == "finale" then scene.finale else scene.stops[id]
                local delta = (Vector2.new(object.Position.X, object.Position.Z) - Vector2.new(
                    node.anchor.Position.X,
                    node.anchor.Position.Z
                )).Magnitude
                if not distance or delta < distance then
                    selected, distance = id, delta
                end
            end
            object:SetAttribute("QuayRestorationStop", selected)
        end
    end
end
return Scene
