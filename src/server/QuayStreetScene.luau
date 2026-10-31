local Shared = game.ReplicatedStorage.Shared
local Theme = require(Shared.Theme)
local Layout = require(Shared.QuayStreetLayout)
local GraffitiPlacement = require(script.Parent.QuayGraffitiPlacement)
local Assets = require(script.Parent.AssetSpawner)
local Scene = {}
local offset = Vector3.new(450, 0, 0)

function Scene.build(scene)
    local root = Instance.new("Folder")
    root.Name, root.Parent = "StreetLiftup", scene.root
    root:SetAttribute("ArtStage", "LOCAL_LAYOUT_PENDING_ACCEPTANCE")
    local function part(name, size, at, color, material, collision)
        local p = Assets.part(root, name, size, CFrame.new(offset + at), color, collision)
        p.Material = material or Enum.Material.SmoothPlastic
        return p
    end
    local function graphic(id, cf, width, height, backed, worldSpace)
        local p = part(
            id,
            Vector3.new(width, height, GraffitiPlacement.thickness),
            Vector3.zero,
            Theme.Stone
        )
        p.CFrame = if worldSpace then cf else CFrame.new(offset) * cf
        p.Transparency = if backed then 0 else 1
        p.CastShadow, p.CanQuery = false, false
        local gui = Instance.new("SurfaceGui")
        gui.Name, gui.Face, gui.AlwaysOnTop = "StreetArtwork", Enum.NormalId.Front, false
        gui.SizingMode, gui.PixelsPerStud, gui.LightInfluence =
            Enum.SurfaceGuiSizingMode.PixelsPerStud, 60, 1
        gui.MaxDistance = 140
        gui.Parent = p
        local image = Instance.new("ImageLabel")
        image.BackgroundTransparency, image.Size = 1, UDim2.fromScale(1, 1)
        image.Image = "rbxasset://needle-quay/graphics/" .. id .. ".png"
        image:SetAttribute("QuayGraphicUri", image.Image)
        image.Parent = gui
        return p
    end
    local function sign(p, text)
        local gui = Instance.new("SurfaceGui")
        gui.Face, gui.AlwaysOnTop, gui.PixelsPerStud = Enum.NormalId.Front, false, 45
        gui.SizingMode, gui.Parent = Enum.SurfaceGuiSizingMode.PixelsPerStud, p
        local label = Instance.new("TextLabel")
        label.Size, label.BackgroundTransparency = UDim2.fromScale(1, 1), 1
        label.Font, label.TextScaled, label.TextColor3, label.Text =
            Enum.Font.GothamBold, true, Theme.Cream, text
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft, padding.PaddingRight = UDim.new(0, 12), UDim.new(0, 12)
        padding.Parent, label.Parent = label, gui
    end
    local function planter(at)
        Assets.place(
            root,
            "P11",
            CFrame.new(offset + at),
            Vector3.new(1.5, 2, 1.5),
            Theme.Coral,
            false
        )
        Assets.place(
            root,
            "P12",
            CFrame.new(offset + at + Vector3.new(0, 1.2, 0)),
            Vector3.new(2, 2, 2),
            Theme.FadedTeal,
            false
        )
    end
    local catalog = {}
    for _, asset in require(Shared.QuayLiftupCatalog) do
        catalog[asset.id] = asset
    end
    for _, row in Layout.buildings do
        local size = Vector3.new(table.unpack(catalog[row.id].dimensions))
        local cf = CFrame.new(offset + row.at) * CFrame.Angles(0, math.rad(row.yaw), 0)
        local model = Assets.place(root, row.id, cf, size, Theme.Cream, size)
        model:SetAttribute("AuthoredCollision", true)
        model:SetAttribute("ScenicBuilding", true)
        -- The supplied shop art carries baked shop words. A separate editable
        -- signplate supplies the neighborhood name and leaves localization native.
        local nameplate =
            part("LocalShopSign", Vector3.new(size.X * 0.92, 2, 0.16), Vector3.zero, Theme.Teal)
        nameplate.CFrame = cf * CFrame.new(0, size.Y * 0.79, -size.Z / 2 - 0.12)
        sign(nameplate, row.label)
        for _, side in { -1, 1 } do
            planter(
                row.at + (cf.Rotation * Vector3.new(side * (size.X / 2 + 1.8), 0, -size.Z / 2 + 1))
            )
        end
        local pavement = part(
            "ShopThreshold",
            Vector3.new(size.X + 4, 0.18, 4),
            Vector3.zero,
            Theme.Stone,
            Enum.Material.Slate
        )
        pavement.CFrame = cf * CFrame.new(0, 0.1, -size.Z / 2 - 2)
    end
    -- A low, staggered back street makes the neighborhood read beyond the shops.
    part(
        "BackstreetFoundation",
        Vector3.new(440, 2, 44),
        Vector3.new(0, -1, -169),
        Theme.Stone,
        Enum.Material.Concrete,
        true
    )
    local architecture = require(Shared.QuayArchitectureCatalog)
    local authored = {}
    for _, record in architecture do
        authored[record.id] = record
    end
    for index, x in { -185, -148, -106, -62, -18, 28, 75, 121, 168, 205 } do
        local id = string.format("NQ-FACADE-%02d", (index - 1) % 3 + 1)
        local dims = authored[id].dimensions
        local model = Assets.place(
            root,
            id,
            CFrame.new(offset + Vector3.new(x, 0, -168)) * CFrame.Angles(0, math.pi, 0),
            Vector3.new(dims[1], dims[3], dims[2]),
            Theme.Cream,
            Vector3.new(dims[1], dims[3], dims[2])
        )
        model:SetAttribute("AuthoredFacade", true)
    end
    -- Dock murals sit on low stone screens instead of floating over the water.
    local graffitiCount = 0
    for _, row in Layout.graffiti do
        local cf, width, height = nil, row.width, row.height
        local placement
        if row.building then
            local reason
            placement, reason = GraffitiPlacement.resolve(scene.root, row)
            if placement then
                cf, width, height = placement.cframe, placement.width, placement.height
            else
                warn("Graffiti " .. row.id .. " skipped: " .. tostring(reason))
            end
        else
            local wall = part(
                "MuralStoneScreen",
                Vector3.new(width + 2, height + 1, 0.5),
                row.at + Vector3.new(0, 0, 0.3),
                Theme.Stone,
                Enum.Material.Concrete,
                true
            )
            wall:SetAttribute("SupplementalScenery", true)
            cf = CFrame.new(row.at) * CFrame.Angles(0, math.rad(row.yaw), 0)
        end
        if cf and width > 0 then
            local art = graphic(row.id, cf, width, height, false, placement ~= nil)
            graffitiCount += 1
            if placement then
                art:SetAttribute("GraffitiAttachment", "REVIEWED_RENDERED_MESH_PANEL")
                art:SetAttribute("GraffitiBuilding", row.building)
                art:SetAttribute("GraffitiWall", row.wall)
                art:SetAttribute("SupportingMeshSHA256", placement.source.mesh_sha256)
                art:SetAttribute("SurfaceGap", GraffitiPlacement.surfaceGap)
                local support = Instance.new("ObjectValue")
                support.Name, support.Value, support.Parent = "RenderedWall", placement.support, art
            end
        end
    end
    -- Traffic uses presentation-only meshes; collision never pushes a player.
    local traffic = Instance.new("Folder")
    traffic.Name, traffic.Parent = "Traffic", root
    for index, row in Layout.traffic do
        local cf = CFrame.new(offset + Vector3.new(row.x, 0.12, row.z))
            * CFrame.Angles(0, -row.direction * math.pi / 2, 0)
        local vehicle = Assets.place(traffic, row.id, cf, Vector3.new(5, 4, 12), Theme.Teal, false)
        vehicle.Name = "PassingVehicle" .. index
        vehicle:SetAttribute("TrafficDirection", row.direction)
        vehicle:SetAttribute("TrafficSpeed", row.speed)
        vehicle:SetAttribute("TrafficLane", row.z)
        vehicle:SetAttribute("TrafficStartX", row.x)
        vehicle:SetAttribute("PresentationTraffic", true)
    end
    for _, z in { -65, 65 } do
        for x = -208, 208, 16 do
            part(
                "RoadCenterDash",
                Vector3.new(6, 0.025, 0.22),
                Vector3.new(x, 0.18, z),
                Theme.Cream
            )
        end
        for _, x in { -95, 0, 95 } do
            for stripe = -3, 3 do
                part(
                    "PedestrianCrossing",
                    Vector3.new(1, 0.028, 25),
                    Vector3.new(x + stripe * 1.6, 0.19, z),
                    Theme.Cream
                )
            end
        end
    end
    local stop =
        part("QuayShuttleSign", Vector3.new(5, 2.4, 0.2), Vector3.new(-47, 6.5, 83), Theme.Teal)
    sign(stop, "QUAY SHUTTLE")
    part(
        "ShuttlePole",
        Vector3.new(0.25, 5.5, 0.25),
        Vector3.new(-47, 2.75, 83),
        Theme.Graphite,
        Enum.Material.Metal
    )
    Assets.place(
        root,
        "P03",
        CFrame.new(offset + Vector3.new(-42, 0, 86)),
        Vector3.new(6, 3, 2),
        Theme.Walnut,
        false
    )
    graphic("POST-07", CFrame.new(186, 4.5, 35), 3, 4.5, true)
    graphic("POST-03", CFrame.new(-112, 5, -87), 3, 4.5, true)
    root:SetAttribute("GraffitiCount", graffitiCount)
    root:SetAttribute("ExpectedGraffitiCount", #Layout.graffiti)
end

return Scene
