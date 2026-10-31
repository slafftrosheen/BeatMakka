-- Artbook environment assembly. Canonical buildings, parking and quest anchors stay put.
local Lighting = game:GetService("Lighting")
local Shared = game.ReplicatedStorage.Shared
local Theme = require(Shared.Theme)
local Geometry = require(Shared.NeedleQuayGeometry)
local Supplied = require(Shared.QuayBuildingLayout)
local Authored = {}
for _, asset in require(Shared.QuayArchitectureCatalog) do
    Authored[asset.id] = true
end
local Assets = require(script.Parent.AssetSpawner)
local World = {}
local OFFSET = Vector3.new(450, 0, 0)
local rng = Random.new(1948)

local function block(parent, name, size, position, color, material, collide)
    local p = Assets.part(parent, name, size, CFrame.new(position), color, collide == true)
    p.Material = material or Enum.Material.SmoothPlastic
    return p
end
local function tile(p, family, scale, face)
    local texture = Instance.new("Texture")
    texture.Name = "AuthoredSurface"
    texture:SetAttribute("LocalMaterialKey", "env_" .. family)
    texture.Texture = require(Shared.LocalContent).Materials["env_" .. family .. "_color"]
    texture.StudsPerTileU, texture.StudsPerTileV = scale, scale
    texture.Face = face or Enum.NormalId.Top
    -- The color map already contains the stone palette; multiplying it by the
    -- base stone again crushed the paving into brown and hid the joints.
    texture.Color3 = if family == "stone" then Color3.fromRGB(255, 247, 232) else p.Color
    texture.Transparency = if family == "stone" then 0.28 else 0.12
    texture.Parent = p
end
local function beam(parent, name, a, b, width, color, material)
    local p = block(
        parent,
        name,
        Vector3.new(width, width, (b - a).Magnitude),
        (a + b) / 2,
        color,
        material
    )
    p.CFrame = CFrame.lookAt((a + b) / 2, b)
    return p
end
local function bulb(parent, position, brightness, range)
    local p = block(
        parent,
        "AmberPractical",
        Vector3.new(0.32, 0.42, 0.32),
        position,
        Theme.Amber,
        Enum.Material.Neon
    )
    p.Shape = Enum.PartType.Ball
    local light = Instance.new("PointLight")
    light.Color = Color3.fromRGB(255, 193, 122)
    light.Brightness, light.Range = brightness, range
    light.Shadows = true
    light.Parent = p
    p:SetAttribute("QuayRestoration", true)
    p:SetAttribute("PracticalBrightness", brightness)
    return p
end
local function image(parent, name, at, width, height, file)
    local backing = block(parent, name, Vector3.new(width, height, 0.06), at, Theme.Cream)
    local gui = Instance.new("SurfaceGui")
    gui.Face = Enum.NormalId.Front
    gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    gui.PixelsPerStud = 80
    gui.LightInfluence = 0.7
    gui.Parent = backing
    local label = Instance.new("ImageLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.Image = "rbxasset://needle-quay/graphics/" .. file .. ".png"
    label:SetAttribute("QuayGraphicUri", label.Image)
    label.Parent = gui
    return backing
end

function World.build(scene)
    local root = scene.root
    local art = Instance.new("Folder")
    art.Name = "LivingQuay"
    art.Parent = root
    Lighting.ClockTime = 17.65
    Lighting.Brightness = 2.2
    Lighting.ExposureCompensation = 0
    Lighting.Ambient = Color3.fromRGB(72, 72, 89)
    Lighting.OutdoorAmbient = Color3.fromRGB(112, 116, 136)
    Lighting.ColorShift_Top = Color3.new()
    Lighting.GlobalShadows = true
    Lighting.ShadowSoftness = 0.3
    Lighting.EnvironmentDiffuseScale = 0.8
    Lighting.EnvironmentSpecularScale = 0.8
    local skyMaps = require(Shared.LocalContent).Sky
    if skyMaps and skyMaps.rt then
        local sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky")
        sky.Name = "QuaySunset"
        sky.SkyboxRt, sky.SkyboxLf = skyMaps.rt, skyMaps.lf
        sky.SkyboxFt, sky.SkyboxBk = skyMaps.ft, skyMaps.bk
        sky.SkyboxUp, sky.SkyboxDn = skyMaps.up, skyMaps.dn
        sky.StarCount = 0
        sky.SkyboxOrientation = Vector3.new(0, 180, 0)
        sky.SunAngularSize = 8
        sky.Parent = Lighting
    end
    for _, name in { "QuayHaze", "QuayGrade", "QuayBloom", "QuaySun" } do
        local old = Lighting:FindFirstChild(name)
        if old then
            old:Destroy()
        end
    end
    local atmosphere = Instance.new("Atmosphere")
    atmosphere.Name = "QuayHaze"
    atmosphere.Density, atmosphere.Offset = 0.18, 0.1
    atmosphere.Color = Color3.fromRGB(211, 211, 221)
    atmosphere.Decay = Color3.fromRGB(136, 140, 163)
    atmosphere.Haze, atmosphere.Glare = 0.6, 0.02
    atmosphere.Parent = Lighting
    local grade = Instance.new("ColorCorrectionEffect")
    grade.Name = "QuayGrade"
    grade.TintColor = Color3.fromRGB(255, 252, 248)
    grade.Contrast, grade.Saturation = 0.04, -0.12
    grade.Parent = Lighting
    local bloom = Instance.new("BloomEffect")
    bloom.Name = "QuayBloom"
    bloom.Intensity, bloom.Size, bloom.Threshold = 0.22, 24, 1.3
    bloom.Parent = Lighting
    local sun = Instance.new("SunRaysEffect")
    sun.Name = "QuaySun"
    sun.Intensity, sun.Spread = 0.045, 0.65
    sun.Parent = Lighting
    local terrain = workspace.Terrain
    terrain.WaterColor = Color3.fromRGB(51, 96, 100)
    terrain.WaterReflectance, terrain.WaterTransparency = 0.45, 0.35
    terrain.WaterWaveSize, terrain.WaterWaveSpeed = 0.22, 7
    terrain:FillBlock(CFrame.new(450, -9, 300), Vector3.new(1100, 12, 300), Enum.Material.Water)
    -- Broad cloud shapes are authored into the artbook panorama. A second
    -- procedural cloud layer obscures that silhouette and changes its palette.
    local clouds = terrain:FindFirstChild("QuayClouds")
    if clouds then
        clouds:Destroy()
    end
    local foundation = root:FindFirstChild("QuayFoundation")
    foundation.Color = Color3.fromRGB(183, 162, 137)
    foundation.Material = Enum.Material.Cobblestone
    tile(foundation, "stone", 12)
    local water = root:FindFirstChild("HarborWater")
    if water then
        water.Transparency = 1
    end
    for _, p in root:GetChildren() do
        if p:IsA("BasePart") and p.Name == "BoundaryRail" then
            p.Transparency = 1
        end
        if p:IsA("BasePart") and (p.Name == "PedestrianWay" or p.Name == "ConnectingWalk") then
            p.Color = Color3.fromRGB(198, 185, 163)
            p.Material = Enum.Material.Cobblestone
            tile(p, "stone", 9)
        end
        if p:IsA("BasePart") and p.Name == "PavingJoint" then
            p.Transparency = 1
        end
        if
            p:IsA("BasePart") and (p:GetAttribute("ParkingId") or p:GetAttribute("DemoSecondBay"))
        then
            p.Color = Color3.fromRGB(198, 185, 163)
            p.Material = Enum.Material.Cobblestone
            tile(p, "stone", 9)
        end
    end
    -- Streets read as connected public space, with raised kerbs and separate pavements.
    for _, z in { -65, 65 } do
        for _, side in { -1, 1 } do
            local walk = block(
                art,
                "StonePavement",
                Vector3.new(430, 0.24, 7),
                OFFSET + Vector3.new(0, 0.15, z + side * 18.5),
                Color3.fromRGB(202, 183, 152),
                Enum.Material.Slate
            )
            tile(walk, "stone", 8)
            for x = -208, 208, 8 do
                local curb = block(
                    art,
                    "JointedKerbstone",
                    Vector3.new(7.8, 0.45, 0.7),
                    OFFSET + Vector3.new(x, 0.24, z + side * 15),
                    Theme.Stone,
                    Enum.Material.Concrete
                )
                curb.Color = Theme.Stone:Lerp(Theme.Cream, rng:NextNumber(0, 0.15))
            end
        end
        task.wait()
    end
    -- Dock wall, stepped promenade and individual bollards frame the real water.
    for x = -216, 216, 12 do
        block(
            art,
            "QuayWallBlock",
            Vector3.new(11.8, 6, 5),
            OFFSET + Vector3.new(x, -2.7, 149),
            Theme.Stone,
            Enum.Material.Slate
        )
        local cap = block(
            art,
            "QuayCoping",
            Vector3.new(11.9, 0.6, 5.4),
            OFFSET + Vector3.new(x, 0.35, 149),
            Theme.Cream,
            Enum.Material.Concrete
        )
        tile(cap, "stone", 8)
        if x % 24 == 0 then
            block(
                art,
                "RailPier",
                Vector3.new(1.3, 3.4, 1.3),
                OFFSET + Vector3.new(x, 1.9, 148),
                Theme.Stone,
                Enum.Material.Slate
            )
            for _, y in { 1.6, 2.9 } do
                beam(
                    art,
                    "HarborRailing",
                    OFFSET + Vector3.new(x, y, 148),
                    OFFSET + Vector3.new(x + 24, y, 148),
                    0.18,
                    Theme.Graphite,
                    Enum.Material.Metal
                )
            end
        end
    end
    for _, x in { -165, -120, 100 } do
        for z = 154, 192, 4 do
            local plank = block(
                art,
                "DockBoard",
                Vector3.new(14, 0.55, 3.8),
                OFFSET + Vector3.new(x, -0.6, z),
                Theme.Walnut,
                Enum.Material.WoodPlanks
            )
            tile(plank, "wood", 8)
        end
        for _, dx in { -6, 6 } do
            for _, z in { 156, 174, 192 } do
                local post = block(
                    art,
                    "MooringPost",
                    Vector3.new(1.25, 7, 1.25),
                    OFFSET + Vector3.new(x + dx, -2, z),
                    Theme.Walnut,
                    Enum.Material.Wood
                )
                for _, y in { -0.1, 0.25 } do
                    block(
                        art,
                        "MooringCollar",
                        Vector3.new(1.4, 0.12, 1.4),
                        Vector3.new(post.Position.X, y, post.Position.Z),
                        Theme.Graphite,
                        Enum.Material.Metal
                    )
                end
            end
        end
    end
    for index = 1, 20 do
        local x = -220 + index * 22
        if math.abs(x + 165) > 12 and math.abs(x + 120) > 12 and math.abs(x - 100) > 12 then
            Assets.place(
                art,
                string.format("NQ-ROCK-%02d", 1 + index % 3),
                CFrame.new(OFFSET + Vector3.new(x, -4, 155 + index % 3))
                    * CFrame.Angles(0, index * 1.2, 0),
                Vector3.one,
                Theme.Stone,
                false
            )
        end
    end
    -- Buildings keep their envelopes; the frontages gain usable thresholds and stories.
    for index, spec in Geometry do
        if Supplied[spec.id] then
            continue
        end
        local x, z = spec.center[1], spec.center[2]
        local w, d, h = table.unpack(spec.dimensions)
        local front = z - d / 2
        local terrace = block(
            art,
            "ShopThreshold",
            Vector3.new(w + 5, 0.32, 8),
            OFFSET + Vector3.new(x, 0.18, front - 3),
            Theme.Stone,
            Enum.Material.Concrete
        )
        tile(terrace, "stone", 8)
        -- These DCC assets already carry their own windows, signs, lamps and
        -- roof equipment. Generic facade dressing intersects the authored art.
        if Authored[spec.id] then
            continue
        end
        for _, side in { -1, 1 } do
            local lightPosition = OFFSET + Vector3.new(x + side * (w / 2 - 2), 8, front - 0.8)
            bulb(art, lightPosition, 1.8, 17)
            if spec.id ~= "NQ-BLD-04" and spec.id ~= "NQ-BLD-05" then
                local glass = block(
                    art,
                    "WarmShopWindow",
                    Vector3.new(w / 5 - 0.15, 4.8, 0.08),
                    OFFSET + Vector3.new(x + side * w / 3, 6.3, front - 0.64),
                    Color3.fromRGB(231, 180, 113),
                    Enum.Material.Glass
                )
                glass.Transparency = 0.2
                local glow = block(
                    art,
                    "WarmWindowInterior",
                    glass.Size,
                    glass.Position + Vector3.new(0, 0, 0.03),
                    Color3.fromRGB(148, 99, 54),
                    Enum.Material.Neon
                )
                local wash = Instance.new("SurfaceLight")
                wash.Face = Enum.NormalId.Front
                wash.Color = Color3.fromRGB(255, 191, 117)
                wash.Brightness, wash.Range, wash.Angle = 0.3, 7, 110
                wash.Parent = glow
                for row = 1, 2 do
                    block(
                        art,
                        "WindowDisplayShelf",
                        Vector3.new(w / 5 - 0.3, 0.1, 0.13),
                        glass.Position + Vector3.new(0, row * 1.5 - 2.1, -0.09),
                        Theme.Walnut,
                        Enum.Material.Wood
                    )
                    for item = 1, 3 do
                        block(
                            art,
                            "WindowDisplaySleeve",
                            Vector3.new(0.65, 0.85, 0.05),
                            glass.Position + Vector3.new((item - 2) * 0.85, row * 1.5 - 1.65, -0.07),
                            if item == 1
                                then Theme.Coral
                                elseif item == 2 then Theme.Cream
                                else Theme.Teal
                        )
                    end
                end
                block(
                    art,
                    "WindowTransom",
                    Vector3.new(w / 5, 0.18, 0.15),
                    glass.Position + Vector3.new(0, 0.6, -0.08),
                    Theme.Walnut,
                    Enum.Material.Wood
                )
                block(
                    art,
                    "WindowMullion",
                    Vector3.new(0.18, 5, 0.15),
                    glass.Position + Vector3.new(0, 0, -0.08),
                    Theme.Walnut,
                    Enum.Material.Wood
                )
            end
        end
        local posterId = string.format("POST-%02d", 1 + (index - 1) % 7)
        image(
            art,
            "CommunityPoster",
            OFFSET + Vector3.new(x + w * 0.38, 3.3, front - 0.52),
            1.6,
            2.3,
            posterId
        )
        -- Roof hardware is functional-scale: caps, drain pipes and two repair plates.
        for _, side in { -1, 1 } do
            beam(
                art,
                "RainPipe",
                OFFSET + Vector3.new(x + side * (w / 2 + 0.15), 0.8, z + d * 0.25),
                OFFSET + Vector3.new(x + side * (w / 2 + 0.15), h - 0.8, z + d * 0.25),
                0.32,
                Theme.Graphite,
                Enum.Material.Metal
            )
        end
        local vent = block(
            art,
            "RoofVentCap",
            Vector3.new(2.8, 1, 2),
            OFFSET + Vector3.new(x - w * 0.2, h + 0.4, z + d * 0.2),
            Theme.Graphite,
            Enum.Material.Metal
        )
        for j = 1, 4 do
            block(
                art,
                "VentLouvre",
                Vector3.new(2.9, 0.1, 0.12),
                vent.Position + Vector3.new(0, -0.4 + j * 0.18, -1.04),
                Theme.Walnut,
                Enum.Material.Metal
            )
        end
        task.wait()
    end
    -- Dense, authored record-shop vignette from the approved board.
    for _, spec in { Geometry[2], Geometry[6] } do
        if Supplied[spec.id] then
            continue
        end
        local x, z = spec.center[1], spec.center[2]
        local w, d, h = table.unpack(spec.dimensions)
        for _, side in { -1, 1 } do
            for tier = 0, 4 do
                local vine = Assets.place(
                    art,
                    "P12",
                    CFrame.new(
                        OFFSET
                            + Vector3.new(
                                x + side * (w / 2 - 0.7) + math.sin(tier * 1.7) * 0.3,
                                h - 1 - tier * 1.2,
                                z - d / 2 - 0.45
                            )
                    ) * CFrame.Angles(0, tier, math.pi),
                    Vector3.new(1, 1, 1),
                    Theme.Teal,
                    false
                )
                vine:ScaleTo(0.28 + (tier % 2) * 0.07)
            end
        end
    end
    local shop = Geometry[2]
    local sx, sz = shop.center[1], shop.center[2] - shop.dimensions[2] / 2
    if not Supplied[shop.id] then
        for _, dx in { -11, 10 } do
            Assets.place(
                art,
                "H03",
                CFrame.new(OFFSET + Vector3.new(sx + dx, 0.35, sz - 3.8)),
                Vector3.new(4, 3, 2),
                Theme.Walnut,
                false
            )
            for sleeve = 1, 7 do
                local cover = block(
                    art,
                    "CrateRecordSleeve",
                    Vector3.new(2.25, 2.25, 0.065),
                    OFFSET
                        + Vector3.new(sx + dx, 2.6 + (sleeve % 3) * 0.08, sz - 4.5 + sleeve * 0.2),
                    if sleeve % 3 == 0
                        then Theme.Teal
                        elseif sleeve % 3 == 1 then Theme.Coral
                        else Theme.Cream
                )
                cover.CFrame *= CFrame.Angles(math.rad(-6), 0, math.rad((sleeve % 3 - 1) * 3))
                if sleeve == 1 then
                    local disc = block(
                        art,
                        "SleeveVinylGraphic",
                        Vector3.new(0.025, 1.3, 1.3),
                        cover.Position,
                        Theme.Graphite
                    )
                    disc.Shape = Enum.PartType.Cylinder
                    disc.CFrame = cover.CFrame
                        * CFrame.new(0, 0.1, -0.05)
                        * CFrame.Angles(0, math.pi / 2, 0)
                    local label = block(
                        art,
                        "VinylCenterLabel",
                        Vector3.new(0.03, 0.38, 0.38),
                        cover.Position,
                        Theme.Cream
                    )
                    label.Shape = Enum.PartType.Cylinder
                    label.CFrame = disc.CFrame * CFrame.new(-0.02, 0, 0)
                end
            end
            Assets.place(
                art,
                "P02",
                CFrame.new(
                    OFFSET + Vector3.new(sx + (if dx > 0 then 6 else dx + 3), 0.35, sz - 4.5)
                ),
                Vector3.new(2, 3, 2),
                Theme.Walnut,
                false
            )
        end
        Assets.place(
            art,
            "H02",
            CFrame.new(OFFSET + Vector3.new(sx + 13, 0.35, sz - 2.7)),
            Vector3.new(4, 8, 3),
            Theme.Teal,
            false
        )
        local rug = block(
            art,
            "ListeningRug",
            Vector3.new(8, 0.04, 5),
            OFFSET + Vector3.new(sx, 0.37, sz - 4),
            Theme.Coral,
            Enum.Material.Fabric
        )
        tile(rug, "canvas", 5)
        -- A legible public shop entrance and a warm, furnished sales floor.
        local doorFront = OFFSET + Vector3.new(sx, 0, sz - 0.55)
        for _, side in { -1, 1 } do
            block(
                art,
                "EntryJamb",
                Vector3.new(0.45, 8, 0.55),
                doorFront + Vector3.new(side * 4, 4, 0),
                Theme.Walnut,
                Enum.Material.Wood
            )
            local hinge = CFrame.new(doorFront + Vector3.new(side * 3.8, 0, 0))
                * CFrame.Angles(0, math.rad(side * 68), 0)
            local leaf = block(
                art,
                "OpenShopDoor",
                Vector3.new(3.5, 7.5, 0.22),
                Vector3.zero,
                Theme.Walnut,
                Enum.Material.Wood
            )
            leaf.CFrame = hinge * CFrame.new(-side * 1.75, 3.75, 0)
            local pane = block(
                art,
                "DoorGlass",
                Vector3.new(2.8, 3.6, 0.05),
                Vector3.zero,
                Theme.Cream,
                Enum.Material.Glass
            )
            pane.CFrame = hinge * CFrame.new(-side * 1.75, 5, 0.14)
            pane.Transparency = 0.4
        end
        block(
            art,
            "EntryHeader",
            Vector3.new(8.5, 0.5, 0.65),
            doorFront + Vector3.new(0, 7.9, 0),
            Theme.Walnut,
            Enum.Material.Wood
        )
        local floor = block(
            art,
            "RecordShopFloor",
            Vector3.new(28, 0.12, 12),
            OFFSET + Vector3.new(sx, 0.4, 0),
            Theme.Walnut,
            Enum.Material.WoodPlanks
        )
        tile(floor, "wood", 7)
        for _, dx in { -10, 10 } do
            for _, depth in { -2, 4 } do
                Assets.place(
                    art,
                    "P04",
                    CFrame.new(OFFSET + Vector3.new(sx + dx, 0.5, depth)),
                    Vector3.new(4, 3, 2),
                    Theme.Walnut,
                    false
                )
            end
        end
        for _, dx in { -7, 0, 7 } do
            Assets.place(
                art,
                "H03",
                CFrame.new(OFFSET + Vector3.new(sx + dx, 0.5, 5)),
                Vector3.new(4, 3, 2),
                Theme.Walnut,
                false
            )
        end
        bulb(art, OFFSET + Vector3.new(sx, 7, 1), 2.5, 20)
        image(art, "ShopPoster", OFFSET + Vector3.new(sx, 5, 6.8), 2.8, 3.8, "POST-02")
    end
    if not Supplied["NQ-BLD-03"] then
        local fan = Instance.new("Model")
        fan.Name = "MorrowFanRotor"
        fan.WorldPivot = CFrame.new(OFFSET + Vector3.new(-121, 6, -117.9))
        local center = fan:GetPivot()
        for i = 0, 3 do
            local blade = block(
                fan,
                "FanBlade",
                Vector3.new(0.55, 1.4, 0.12),
                Vector3.zero,
                Theme.Graphite,
                Enum.Material.Metal
            )
            blade.CFrame = center * CFrame.Angles(0, 0, i * math.pi / 2) * CFrame.new(0, 0.65, 0)
        end
        local hub = block(
            fan,
            "FanHub",
            Vector3.new(0.5, 0.5, 0.25),
            center.Position,
            Theme.Cream,
            Enum.Material.Metal
        )
        hub.Shape = Enum.PartType.Ball
        fan:SetAttribute("QuayFan", true)
        fan.Parent = art
    end
    if not Supplied["NQ-BLD-06"] then
        -- Cafe seating and market frontage are authored in QuayPublicSpaces.
        for i = 1, 4 do
            Assets.place(
                art,
                "NQ-COFFEE-01",
                CFrame.new(OFFSET + Vector3.new(-60 + i * 0.75, 3.5, 81)),
                Vector3.one,
                Theme.Cream,
                false
            )
        end
        block(
            art,
            "CafeServingLedge",
            Vector3.new(3.9, 0.25, 1.1),
            OFFSET + Vector3.new(-58.125, 3.36, 81),
            Theme.Walnut,
            Enum.Material.Wood
        )
        for _, x in { -59.6, -56.65 } do
            block(
                art,
                "CafeLedgeSupport",
                Vector3.new(0.18, 3.2, 0.18),
                OFFSET + Vector3.new(x, 1.72, 81),
                Theme.Teal,
                Enum.Material.Metal
            )
        end
    end
    for _, spec in { Geometry[2], Geometry[3], Geometry[6], Geometry[9] } do
        if Supplied[spec.id] then
            continue
        end
        Assets.place(
            art,
            "NQ-UTILITY-01",
            CFrame.new(
                OFFSET
                    + Vector3.new(
                        spec.center[1] + spec.dimensions[1] / 2 - 2,
                        2.2,
                        spec.center[2] - spec.dimensions[2] / 2 - 0.3
                    )
            ),
            Vector3.one,
            Theme.Teal,
            false
        )
    end
    if not Supplied[shop.id] then
        Assets.place(
            art,
            "NQ-VINYL-01",
            CFrame.new(OFFSET + Vector3.new(sx + 8, 3.35, sz + 3)),
            Vector3.one,
            Theme.Graphite,
            false
        )
    end
    -- Greenery clusters soften the industrial silhouettes without random tiny clutter.
    for _, position in
        {
            Vector3.new(-205, 0, 110),
            Vector3.new(-100, 0, 110),
            Vector3.new(-35, 0, 115),
            Vector3.new(88, 0, 110),
            Vector3.new(195, 0, 110),
            Vector3.new(-205, 0, -130),
            Vector3.new(-20, 0, -125),
            Vector3.new(108, 0, -130),
        }
    do
        local base = OFFSET + position
        block(
            art,
            "TreeBed",
            Vector3.new(10, 0.7, 9),
            base + Vector3.new(0, 0.35, 0),
            Theme.Walnut,
            Enum.Material.Ground
        )
        local tree = Assets.place(
            art,
            "NQ-SCENERY-TREE",
            CFrame.new(base),
            Vector3.new(14, 15, 12),
            Theme.Teal,
            false
        )
        for _, leaf in tree:GetDescendants() do
            if leaf:IsA("MeshPart") and leaf.Name:find("Leaves") then
                leaf:SetAttribute("QuaySway", 0.008)
            end
        end
    end
    Assets.place(
        art,
        "NQ-COUNTER-01",
        CFrame.new(402, 0, 98),
        Vector3.new(9, 3.3, 3),
        Theme.Walnut,
        false
    )
    Assets.place(
        art,
        "NQ-SHELF-01",
        CFrame.new(402, 0, 94),
        Vector3.new(4, 4.6, 1.4),
        Theme.Walnut,
        false
    )
    Assets.place(
        art,
        "NQ-BENCH-01",
        CFrame.new(430, 0, 135),
        Vector3.new(5, 2.2, 1.8),
        Theme.Walnut,
        false
    )
    Assets.place(
        art,
        "NQ-TABLE-01",
        CFrame.new(630, 0, 78),
        Vector3.new(3.6, 2.7, 3.6),
        Theme.Walnut,
        false
    )
    Assets.place(
        art,
        "NQ-RADIO-01",
        CFrame.new(630, 2.7, 78),
        Vector3.new(3.4, 2.2, 2.2),
        Theme.Teal,
        false
    )
    Assets.place(
        art,
        "NQ-COUNTER-01",
        CFrame.new(400, 0, 5),
        Vector3.new(9, 3.3, 3),
        Theme.Walnut,
        false
    )
    Assets.place(
        art,
        "NQ-MIDI-01",
        CFrame.new(400, 3.3, 5),
        Vector3.new(4.7, 0.44, 1.7),
        Theme.Walnut,
        false
    )
    -- Laundry and festival cords are restrained environmental motion, not quest gates.
    for _, z in { -25, 24 } do
        for i = 0, 8 do
            local a = OFFSET + Vector3.new(-78 + i * 12, 12 - math.sin(i / 8 * math.pi) * 2, z)
            local b = OFFSET
                + Vector3.new(-78 + (i + 1) * 12, 12 - math.sin((i + 1) / 8 * math.pi) * 2, z)
            beam(art, "FestoonCable", a, b, 0.045, Theme.Graphite)
            bulb(art, a, 0.5, 7)
            if i % 2 == 0 then
                local flag = block(
                    art,
                    "CanvasBunting",
                    Vector3.new(2, 2.6, 0.05),
                    a - Vector3.new(0, 1.5, 0),
                    if i % 4 == 0 then Theme.Coral else Theme.Cream,
                    Enum.Material.Fabric
                )
                flag:SetAttribute("QuaySway", 0.08)
            end
        end
    end
    -- Drying line sits on the laundry roof, clear of its sign and shop window.
    for _, x in { 136, 153 } do
        beam(
            art,
            "LaundryRoofPost",
            OFFSET + Vector3.new(x, 12.5, -104),
            OFFSET + Vector3.new(x, 16.5, -104),
            0.12,
            Theme.Graphite
        )
    end
    beam(
        art,
        "LaundryRoofLine",
        OFFSET + Vector3.new(136, 16.5, -104),
        OFFSET + Vector3.new(153, 16.5, -104),
        0.045,
        Theme.Graphite
    )
    for i = 1, 6 do
        local cloth = block(
            art,
            "LaundryCloth",
            Vector3.new(1.6, 2.4, 0.05),
            OFFSET + Vector3.new(136 + i * 2.4, 15.2, -104),
            if i % 2 == 0 then Theme.Cream else Theme.FadedTeal,
            Enum.Material.Fabric
        )
        cloth:SetAttribute("QuaySway", 0.06)
    end
    -- Layered city silhouettes and elevated transit, matching the board's horizon.
    for layer = 1, 2 do
        for i = 1, 19 do
            local x = -330 + i * 35 + rng:NextNumber(-8, 8)
            local height = rng:NextNumber(28, 72) + (layer - 1) * 18
            local at = OFFSET + Vector3.new(x, height / 2 - 3, 350 + (layer - 1) * 95)
            local color = if layer == 1
                then Color3.fromRGB(117, 113, 127)
                else Color3.fromRGB(148, 133, 145)
            local floorCount = math.max(2, math.floor(height / 12))
            for floor = 0, floorCount - 1 do
                local id = string.format(
                    "NQ-CITY-%02d",
                    if floor == 0 then 5 + i % 2 else 2 + (i + layer) % 3
                )
                local module = Assets.place(
                    art,
                    id,
                    CFrame.new(at.X, floor * 12 + 1, at.Z),
                    Vector3.new(24, 12, 13),
                    color,
                    false
                )
                for _, mesh in module:GetDescendants() do
                    if mesh:IsA("MeshPart") then
                        mesh.Color = Color3.fromRGB(184, 190, 198)
                    end
                end
            end
            Assets.place(
                art,
                "NQ-CITY-07",
                CFrame.new(at.X, floorCount * 12 + 1, at.Z),
                Vector3.new(24, 3, 13),
                color,
                false
            )
            for y = 6, height - 4, 12 do
                for _, side in { -1, 1 } do
                    if rng:NextNumber() > 0.45 then
                        local window = block(
                            art,
                            "DistantWindow",
                            Vector3.new(0.8, 1.8, 0.05),
                            at + Vector3.new(side * 5, y - height / 2, -6.6),
                            Theme.Amber,
                            Enum.Material.Neon
                        )
                        window.Transparency = 0.15
                    end
                end
            end
        end
        task.wait()
    end
    block(
        art,
        "DistantQuay",
        Vector3.new(840, 8, 240),
        OFFSET + Vector3.new(0, -3, 430),
        Color3.fromRGB(119, 112, 122),
        Enum.Material.Slate
    )
    block(
        art,
        "ElevatedTransit",
        Vector3.new(720, 2.2, 13),
        OFFSET + Vector3.new(0, 23, 300),
        Color3.fromRGB(100, 103, 112),
        Enum.Material.Concrete
    )
    for x = -340, 340, 44 do
        block(
            art,
            "TransitPier",
            Vector3.new(3, 24, 5),
            OFFSET + Vector3.new(x, 11, 300),
            Color3.fromRGB(111, 111, 117),
            Enum.Material.Concrete
        )
    end
    for _, x in { -90, 45, 160 } do
        local boat = Instance.new("Model")
        boat.Name = "HarborBoat"
        boat.WorldPivot = CFrame.new(OFFSET + Vector3.new(x, -1.5, 210))
        boat.Parent = art
        local at = boat:GetPivot().Position
        block(boat, "Hull", Vector3.new(7, 2, 17), at, Theme.Teal, Enum.Material.Wood)
        block(
            boat,
            "CreamGunwale",
            Vector3.new(7.3, 0.3, 17.3),
            at + Vector3.new(0, 1, 0),
            Theme.Cream,
            Enum.Material.Wood
        )
        block(
            boat,
            "Deck",
            Vector3.new(6, 0.2, 15),
            at + Vector3.new(0, 1.2, 0),
            Theme.Walnut,
            Enum.Material.WoodPlanks
        )
        block(
            boat,
            "Cabin",
            Vector3.new(5, 4, 6),
            at + Vector3.new(0, 3, 1),
            Theme.Cream,
            Enum.Material.Wood
        )
        block(
            boat,
            "CabinGlass",
            Vector3.new(4, 1.6, 0.1),
            at + Vector3.new(0, 3.5, -2.06),
            Theme.Teal,
            Enum.Material.Glass
        )
        block(boat, "Roof", Vector3.new(5.6, 0.4, 6.6), at + Vector3.new(0, 5.2, 1), Theme.Coral)
        beam(
            boat,
            "Mast",
            at + Vector3.new(0, 2, 5),
            at + Vector3.new(0, 14, 5),
            0.16,
            Theme.Graphite,
            Enum.Material.Metal
        )
        boat:SetAttribute("QuayBoat", true)
    end
    for index, row in
        {
            { "NQ-NPC-TORI", Vector3.new(-160, 0, 118) },
            { "NQ-NPC-NAYA", Vector3.new(64, 0, 2) },
            { "NQ-NPC-NELL", Vector3.new(-45, 0, 126) },
            { "NQ-NPC-IVO", Vector3.new(-110, 0, -99) },
        }
    do
        local actor = game.ServerStorage.AssetLibrary[row[1]]:Clone()
        actor.Name = "QuayResident" .. index
        actor:ScaleTo(0.92 + index * 0.025)
        actor:PivotTo(CFrame.new(OFFSET + row[2]))
        actor:SetAttribute("AmbientWalk", 18)
        local routes = {
            { { -12, 0, 0 }, { 12, 0, 0 }, { 12, 0, 7 }, { -12, 0, 7 } },
            { { 0, 0, -28 }, { 0, 0, 30 }, { 4, 0, 30 }, { 4, 0, -28 } },
            { { 0, 0, 0 }, { 24, 0, 0 }, { 24, 0, 6 }, { 0, 0, 6 } },
            { { 0, 0, -10 }, { 6, 0, -10 }, { 6, 0, 10 }, { 0, 0, 10 } },
        }
        actor:SetAttribute("AmbientRoute", game:GetService("HttpService"):JSONEncode(routes[index]))
        actor:SetAttribute("AmbientPhase", index * 2)
        actor.Parent = root.Neighbors
    end
    scene.atmosphere = art
end
return World
