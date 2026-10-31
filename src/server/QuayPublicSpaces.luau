-- Deliberate activity courts with ground/tabletop placement, clear aisles and reused supplied art.
local Assets = require(script.Parent.AssetSpawner)
local Theme = require(game.ReplicatedStorage.Shared.Theme)
local Public = {}
local offset = Vector3.new(450, 0, 0)

function Public.build(scene)
    local folder = Instance.new("Folder")
    folder.Name, folder.Parent = "PublicSpaces", scene.root
    folder:SetAttribute("ArtStage", "LOCAL_LAYOUT_PENDING_ACCEPTANCE")
    local function block(name, size, at, color, material)
        local p = Assets.part(folder, name, size, CFrame.new(offset + at), color, false)
        p.Material = material or Enum.Material.SmoothPlastic
        return p
    end
    local function place(id, x, z, floor, yaw, scale)
        local model = Assets.place(
            folder,
            id,
            CFrame.new(offset + Vector3.new(x, floor or 0, z))
                * CFrame.Angles(0, math.rad(yaw or 0), 0),
            Vector3.one,
            Theme.Walnut,
            false
        )
        if scale then
            model:ScaleTo(scale)
        end
        -- Legacy templates have differing pivots; ground their measured art, not a marker.
        local bounds, size = model:GetBoundingBox()
        model:PivotTo(model:GetPivot() + Vector3.new(0, (floor or 0) - (bounds.Y - size.Y / 2), 0))
        model:SetAttribute("LayoutGroup", "PublicSpaces")
        return model
    end
    local function top(model)
        local cf, size = model:GetBoundingBox()
        return cf.Y + size.Y / 2
    end
    local function planter(x, z, scale)
        local pot = place("P11", x, z, 0.17, 0, scale or 1)
        place("P12", x, z, top(pot) - 0.15, 0, (scale or 1) * 0.8)
    end
    local function cable(a, b)
        local delta = b - a
        local p = block(
            "CourtLightCable",
            Vector3.new(0.045, 0.045, delta.Magnitude),
            (a + b) / 2,
            Theme.Graphite
        )
        p.CFrame = CFrame.lookAt(offset + (a + b) / 2, offset + b)
    end
    local function lights(x, z, width)
        for _, dx in { -width / 2, width / 2 } do
            block(
                "CourtLightPost",
                Vector3.new(0.18, 8, 0.18),
                Vector3.new(x + dx, 4, z),
                Theme.Walnut,
                Enum.Material.Wood
            )
        end
        local previous
        for i = 0, 6 do
            local at =
                Vector3.new(x - width / 2 + i * width / 6, 8 - math.sin(i / 6 * math.pi) * 0.7, z)
            if previous then
                cable(previous, at)
            end
            previous = at
            local bulb = block(
                "CourtPractical",
                Vector3.new(0.2, 0.3, 0.2),
                at,
                Theme.Amber,
                Enum.Material.Neon
            )
            local light = Instance.new("PointLight")
            light.Color, light.Range, light.Brightness, light.Shadows = Theme.Amber, 7, 0.3, false
            light.Parent = bulb
        end
    end

    -- Market extension: four compact counters, with a 16-stud central shopping aisle.
    block(
        "MarketCourtPaving",
        Vector3.new(49, 0.16, 49),
        Vector3.new(64, 0.08, 2),
        Theme.Stone,
        Enum.Material.Cobblestone
    )
    for index, row in { { 48, -12 }, { 80, -12 }, { 48, 16 }, { 80, 16 } } do
        local x, z = row[1], row[2]
        local counter = place("NQ-COUNTER-01", x, z, 0.17, 0, 0.9)
        local tabletop = top(counter) + 0.025
        place("NQ-MARKET-TOMATO", x - 2.6, z, tabletop, 0, 0.85)
        place("NQ-MARKET-ORANGE", x, z, tabletop, 0, 0.85)
        place("NQ-MARKET-CRATE", x + 2.6, z, tabletop, 0, 0.85)
        for _, dx in { -4.7, 4.7 } do
            block(
                "StallUpright",
                Vector3.new(0.16, 7.7, 0.16),
                Vector3.new(x + dx, 4, z + 1.4),
                Theme.Walnut,
                Enum.Material.Wood
            )
        end
        for stripe = 0, 5 do
            block(
                "MarketCanvas",
                Vector3.new(1.7, 0.18, 5.6),
                Vector3.new(x - 4.25 + stripe * 1.7, 7.9, z),
                if stripe % 2 == 0 then Theme.Cream else Theme.Coral,
                Enum.Material.Fabric
            )
            block(
                "MarketValance",
                Vector3.new(1.7, 0.65, 0.12),
                Vector3.new(x - 4.25 + stripe * 1.7, 7.55, z - 2.8),
                if stripe % 2 == 0 then Theme.Cream else Theme.Coral,
                Enum.Material.Fabric
            )
        end
        place("NQ-MARKET-CRATE", x - 3, z + 4, 0.17, 8, 0.9)
        if index % 2 == 0 then
            place("NQ-MARKET-CART", x + 4, z + 4, 0.17, 90, 1)
        end
    end
    for _, row in { { 41, -20 }, { 87, -20 }, { 41, 28 }, { 87, 28 } } do
        planter(row[1], row[2], 0.85)
    end
    lights(64, -23, 44)
    lights(64, 30, 44)

    -- Cafe garden: furniture now lives beside the building, outside the road and entry.
    block(
        "CafeGardenPaving",
        Vector3.new(28, 0.16, 30),
        Vector3.new(-39, 0.08, 108),
        Theme.Stone,
        Enum.Material.Slate
    )
    for _, row in { { -45, 101 }, { -31, 101 }, { -45, 113 }, { -31, 113 } } do
        local x, z = row[1], row[2]
        local tableModel = place("NQ-TABLE-01", x, z, 0.17, 0, 1)
        for _, dx in { -3, 3 } do
            place("NQ-CHAIR-01", x + dx, z, 0.17, if dx < 0 then -90 else 90, 1)
        end
        local tabletop = top(tableModel) + 0.02
        place("NQ-CAKE-02", x - 0.6, z, tabletop, 12, 0.7)
        place("NQ-COFFEE-01", x + 0.8, z + 0.4, tabletop, -12, 0.75)
    end
    for _, row in { { -52, 97 }, { -25, 97 }, { -52, 120 }, { -25, 120 } } do
        planter(row[1], row[2], 0.85)
    end
    lights(-39, 121, 27)

    -- Repair work lives alongside Morrow, not across its front door or controls.
    local bench = place("NQ-COUNTER-01", -109, -113, 0, 90, 0.75)
    place("NQ-REPAIR-LAPTOP", -109, -113, top(bench) + 0.02, 90, 1)
    place("NQ-RADIO-01", -109, -110.5, top(bench) + 0.02, 90, 0.55)
    place("NQ-MARKET-CRATE", -108, -119, 0, 0, 1)
    place("NQ-POWER-CABINET", -115, -115, 2, 90, 1.3)
    place("NQ-POWER-CABINET", -115, -112.5, 2, 90, 1)

    -- Waterfront pockets keep a broad continuous promenade and all mooring access open.
    for _, x in { -78, 38, 73, 120 } do
        block(
            "WaterfrontPocket",
            Vector3.new(17, 0.12, 12),
            Vector3.new(x, 0.06, 135),
            Theme.Stone,
            Enum.Material.Slate
        )
        place("NQ-BENCH-01", x - 4, 136, 0.13, 180, 1)
        place("NQ-BENCH-01", x + 4, 136, 0.13, 180, 1)
        planter(x - 7, 131, 0.7)
        planter(x + 7, 131, 0.7)
    end
    -- Trees flank the new market square; none stand in a connecting walk.
    for _, row in { { 48, 43 }, { 80, 43 }, { -37, 37 }, { 115, 25 }, { 145, 25 } } do
        local x, z = row[1], row[2]
        block(
            "PocketTreeBed",
            Vector3.new(7, 0.3, 7),
            Vector3.new(x, 0.15, z),
            Theme.Walnut,
            Enum.Material.Ground
        )
        local tree = place("NQ-SCENERY-TREE", x, z, 0.3, 0, 0.7)
        for _, mesh in tree:GetDescendants() do
            if mesh:IsA("MeshPart") and mesh.Name:find("Leaves") then
                mesh:SetAttribute("QuaySway", 0.008)
            end
        end
    end
end
return Public
