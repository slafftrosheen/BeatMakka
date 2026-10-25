-- Local native presentation of the authored district. No uploaded content required.
local Shared = game.ReplicatedStorage.Shared
local Theme = require(Shared.Theme)
local Catalog = require(Shared.NeedleQuayCatalog)
local Geometry = require(Shared.NeedleQuayGeometry)
local Characters = require(Shared.NeedleQuayCharacters)
local Assets = require(script.Parent.AssetSpawner)
local Demo = {}
local OFFSET = Vector3.new(450, 0, 0)
local function position(x, y, z)
    return OFFSET + Vector3.new(x, y, z)
end

local function part(parent, name, size, at, color, collide)
    local object =
        Assets.part(parent, name, size, CFrame.new(at), color or Theme.Teal, collide == true)
    object.Material = Enum.Material.SmoothPlastic
    return object
end

local function sign(anchor, text, width)
    local gui = Instance.new("BillboardGui")
    gui.Name = "QuaySign"
    gui.Size = UDim2.fromOffset(width or 220, 60)
    gui.StudsOffset = Vector3.new(0, 3, 0)
    gui.MaxDistance = 8
    gui.Enabled = false -- Physical signs and proximity prompts carry the same names.
    gui.Parent = anchor
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundColor3 = Theme.Ink
    label.BackgroundTransparency = 0.16
    label.TextColor3 = Theme.Cream
    label.TextSize = 17
    label.Font = Theme.Bold
    label.TextWrapped = true
    label.Text = text
    label.Parent = gui
end

local function target(parent, name, at, title, action)
    local anchor = part(parent, name, Vector3.new(2, 2, 2), at, Theme.Teal, false)
    anchor.Transparency = 1
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = action or "Talk / activity"
    prompt.ObjectText = title
    prompt.MaxActivationDistance = 10
    prompt.RequiresLineOfSight = false
    prompt.HoldDuration = 0.3
    prompt.Parent = anchor
    sign(anchor, title)
    return { anchor = anchor, prompt = prompt }
end

function Demo.build(world)
    local root = Instance.new("Folder")
    root.Name = "DemoDistrict"
    root.Parent = world.root
    local scene = { root = root, stops = {}, actions = {}, buildings = {}, vans = {} }
    part(root, "QuayFoundation", Vector3.new(440, 2, 300), position(0, -1, 0), Theme.Stone, true)
    local sea = part(
        root,
        "HarborWater",
        Vector3.new(540, 1, 80),
        position(0, -2, 192),
        Theme.FadedTeal,
        false
    )
    sea.Material = Enum.Material.Glass
    sea.Transparency = 0.3
    for _, z in { -65, 65 } do
        part(
            root,
            "PedestrianWay",
            Vector3.new(420, 0.08, 30),
            position(0, 0.04, z),
            Theme.Walnut,
            false
        )
        for x = -200, 200, 16 do
            part(
                root,
                "PavingJoint",
                Vector3.new(0.12, 0.1, 28),
                position(x, 0.08, z),
                Theme.Stone,
                false
            )
        end
    end
    for _, x in { -190, -95, 0, 95, 190 } do
        part(
            root,
            "ConnectingWalk",
            Vector3.new(12, 0.08, 270),
            position(x, 0.06, 0),
            Theme.Stone,
            false
        )
    end
    for _, spec in Geometry do
        local accessible = spec.id == "NQ-BLD-01"
            or spec.id == "NQ-BLD-02"
            or spec.id == "NQ-BLD-04"
        local model = Instance.new("Model")
        model.Name = spec.id
        model:SetAttribute("SourcePath", spec.source)
        model:SetAttribute("SourceSHA256", spec.sha256)
        model:SetAttribute("ArtStage", "LOCAL_ARTBOOK_REVISION_IN_REVIEW")
        for _, entry in spec.parts do
            local p = position(
                spec.center[1] + entry.position[1],
                entry.position[2],
                spec.center[2] + entry.position[3]
            )
            local size = Vector3.new(table.unpack(entry.size))
            local object =
                part(model, entry.name, size, p, Color3.new(table.unpack(entry.color)), false)
            if accessible then
                local structural = entry.name == "Floor"
                    or entry.name:find("Wall")
                    or entry.name:find("FrontWing")
                    or entry.name:find("Header")
                    or entry.name:find("Counter")
                    or entry.name:find("Stage_")
                    or entry.name:find("Column")
                    or entry.name:find("PerformancePlatform")
                object.CanCollide = structural ~= nil and structural ~= false
                object.CanQuery = object.CanCollide
                if entry.name:find("Roof_Remove") then
                    object.Transparency = 0.65
                end
            end
            if entry.name:find("Amber") or entry.name:find("Bulb") then
                object.Material = Enum.Material.Neon
            end
            if entry.name:find("Bulb") then
                object.Shape = Enum.PartType.Ball
            end
            -- These source bounds are collision only; visible art is the exact mesh below.
            object.Transparency = 1
            object.CastShadow = false
            object:SetAttribute("CollisionOnly", true)
            if entry.name:match("^NQ%-SGN%-%d+$") then
                local surface = Instance.new("SurfaceGui")
                surface.Name = "AuthoredSignGraphic"
                surface.Face = Enum.NormalId.Front
                surface.CanvasSize = Vector2.new(1024, 384)
                surface.LightInfluence = 0.3
                surface.Parent = object
                local graphic = Instance.new("ImageLabel")
                graphic.Size = UDim2.fromScale(1, 1)
                graphic.BackgroundTransparency = 1
                graphic.Image = "rbxasset://needle-quay/graphics/" .. entry.name .. ".png"
                graphic.ScaleType = Enum.ScaleType.Fit
                graphic.Parent = surface
            end
            if spec.id == "NQ-BLD-02" then
                object.CFrame -= Vector3.new(16, 0, 8)
            end
        end
        local template = game.ServerStorage.AssetLibrary:FindFirstChild(spec.id)
        assert(template, "Missing accepted local building: " .. spec.id)
        local art = template:Clone()
        art.Name = "Art"
        art:PivotTo(CFrame.new(position(spec.center[1], 0, spec.center[2])))
        art.Parent = model
        -- Deterministic exterior collision independent of decorative source topology.
        local w, d, h = table.unpack(spec.dimensions)
        local collision = part(
            model,
            "ScenicShellCollision",
            Vector3.new(w, h, d),
            position(spec.center[1], h / 2, spec.center[2]),
            Theme.Ink,
            true
        )
        collision.Transparency = 1
        collision.CastShadow = false
        collision.CanCollide = not accessible
        collision.CanQuery = not accessible
        local entrance = position(spec.center[1], 2, spec.center[2] - d / 2 - 4)
        local marker = target(model, "Entrance", entrance, spec.name, "Visit")
        scene.buildings[spec.id] = marker
        model.Parent = root
        task.wait()
    end
    for _, stop in Catalog.stops do
        local id = stop.existing_parking_id
        local x, z = table.unpack(stop.center_xz_studs)
        local pad = part(
            root,
            id .. "Parking",
            Vector3.new(28, 0.12, 18),
            position(x, 0.12, z),
            Theme.FadedTeal,
            false
        )
        pad:SetAttribute("ParkingId", id)
        local visitorPad = part(
            root,
            id .. "SecondBay",
            Vector3.new(28, 0.12, 18),
            position(x + 32, 0.12, z),
            Theme.FadedTeal,
            false
        )
        visitorPad:SetAttribute("DemoSecondBay", true)
        for _, edge in { -14, 14 } do
            part(
                root,
                "ParkingStripe",
                Vector3.new(0.25, 0.14, 18),
                position(x + edge, 0.16, z),
                Theme.Cream,
                false
            )
        end
        local node = target(root, id, position(x, 2, z - 15), stop.name .. " / " .. stop.npcs[1])
        node.position = position(x, 3, z + 13)
        node.center = position(x, 0, z)
        scene.stops[id] = node
        node.anchor:SetAttribute("QuayInteraction", id)
    end
    -- Boundary rails remain collidable even when visual dressing is hidden locally.
    for _, z in { -149, 149 } do
        part(root, "BoundaryRail", Vector3.new(440, 4, 0.5), position(0, 2, z), Theme.Walnut, true)
    end
    for _, x in { -219, 219 } do
        part(root, "BoundaryRail", Vector3.new(0.5, 4, 300), position(x, 2, 0), Theme.Walnut, true)
    end
    for x = -204, 204, 24 do
        for _, z in { -44, 84 } do
            local post = part(
                root,
                "QuayLamp",
                Vector3.new(0.5, 10, 0.5),
                position(x, 5, z),
                Theme.Graphite,
                true
            )
            local arm = part(
                root,
                "LampArm",
                Vector3.new(2, 0.4, 0.4),
                post.Position + Vector3.new(0.8, 4.8, 0),
                Theme.Graphite,
                false
            )
            local glass = part(
                root,
                "Lantern",
                Vector3.new(1, 1.5, 1),
                post.Position + Vector3.new(1.5, 4, 0),
                Theme.Amber,
                false
            )
            local light = Instance.new("PointLight")
            light.Color = Theme.Amber
            light.Brightness = 0.65
            light.Range = 18
            light.Parent = glass
            glass.Material = Enum.Material.Neon
            glass:SetAttribute("QuayRestoration", true)
            post.Transparency = 1
            arm.Transparency = 1
            post.CastShadow = false
            arm.CastShadow = false
            Assets.place(
                root,
                "H05",
                CFrame.new(position(x, 0, z)),
                Vector3.new(3, 10, 3),
                Theme.Graphite,
                false
            )
        end
    end
    for _, spec in Geometry do
        local width, depth = spec.dimensions[1], spec.dimensions[2]
        for _, side in { -1, 1 } do
            local at =
                position(spec.center[1] + side * (width / 2 + 3), 0, spec.center[2] - depth / 2 - 2)
            Assets.place(root, "P11", CFrame.new(at), Vector3.new(2, 2, 2), Theme.Coral, false)
            Assets.place(
                root,
                "P12",
                CFrame.new(at + Vector3.new(0, 1.4, 0)),
                Vector3.new(3, 4, 3),
                Theme.Teal,
                false
            )
        end
        if spec.id ~= "NQ-BLD-04" then
            local at = position(spec.center[1] - width / 2 + 4, 0, spec.center[2] - depth / 2 - 4)
            Assets.place(root, "P03", CFrame.new(at), Vector3.new(5, 3, 2), Theme.Walnut, false)
        end
    end
    for i = 1, 3 do
        scene.actions["dock" .. i] = target(
            root,
            "DockCrate" .. i,
            scene.stops.P1.center + Vector3.new(-8 + i * 4, 1, -24),
            "Dock crate " .. i,
            "Stow safely"
        )
        scene.actions["dock" .. i].anchor:SetAttribute("QuayPersonalTarget", "dock" .. i)
        scene.actions["repair" .. i] = target(
            root,
            "VentControl" .. i,
            scene.buildings["NQ-BLD-03"].anchor.Position + Vector3.new(-8 + i * 4, 0, -3),
            ({ "1 / Isolate power", "2 / Clear intake", "3 / Restore power" })[i],
            "Repair"
        )
        scene.actions["market" .. i] = target(
            root,
            "StageCase" .. i,
            scene.buildings["NQ-BLD-04"].anchor.Position + Vector3.new(-8 + i * 4, -1, -4),
            "Stage case " .. i,
            "Clear performance nook"
        )
        scene.actions["market" .. i].anchor:SetAttribute("QuayPersonalTarget", "market" .. i)
        for _, kind in { "dock", "market" } do
            local node = scene.actions[kind .. i]
            local crate = Assets.place(
                root,
                "P06",
                CFrame.new(node.anchor.Position - Vector3.new(0, 1, 0)),
                Vector3.new(2, 2, 2),
                Theme.Walnut,
                false
            )
            for _, mesh in crate:GetDescendants() do
                if mesh:IsA("BasePart") then
                    mesh:SetAttribute("QuayPersonalTarget", kind .. i)
                end
            end
        end
        local control = scene.actions["repair" .. i]
        Assets.place(
            root,
            "P14",
            CFrame.new(control.anchor.Position - Vector3.new(0, 1, 0)),
            Vector3.new(2, 2, 1),
            Theme.Teal,
            false
        )
    end
    scene.actions.radio = target(
        root,
        "RadioConsole",
        scene.stops.P4.center + Vector3.new(0, 2, -24),
        "Mica / signal console",
        "Restore signal"
    )
    scene.actions.radio.anchor:SetAttribute("QuayRadio", true)
    scene.finale = scene.buildings["NQ-BLD-01"]
    scene.finale.prompt.ActionText = "Ronan / prepare concert"
    scene.finale.anchor:SetAttribute("QuayInteraction", "finale")
    for id, node in scene.actions do
        node.anchor:SetAttribute("QuayInteraction", id)
    end
    -- The existing instrument/court remains an instanced-interior presentation.
    scene.exit = target(
        world.root,
        "ReturnToQuay",
        Vector3.new(0, 2, -25),
        "Needle Quay",
        "Return to The Roamer"
    )
    scene.courtExit = target(
        world.root,
        "ReturnFromLantern",
        Vector3.new(42, 2, 27),
        "The Lantern Room / exit",
        "Return to district"
    )
    scene.exit.anchor:SetAttribute("QuayInteraction", "return")
    scene.courtExit.anchor:SetAttribute("QuayInteraction", "return")
    local arrival = world.root:FindFirstChild("Arrival")
    if arrival then
        arrival.CFrame = CFrame.new(scene.stops.P1.position - Vector3.new(0, 2.9, 0))
    end
    -- One visible Roamer for each existing owned workshop, parked in separate lanes.
    for index = 1, 2 do
        local model = Instance.new("Model")
        model.Name = "Roamer" .. index
        model:SetAttribute("AssetId", "LOOPVAN-01")
        local base = Vector3.new(0, 0, 0)
        part(
            model,
            "Chassis",
            Vector3.new(22, 1, 9),
            base + Vector3.new(0, 2, 0),
            Theme.Graphite,
            true
        )
        local body = part(
            model,
            "Body",
            Vector3.new(19, 6, 9),
            base + Vector3.new(-1.5, 5.5, 0),
            Theme.Teal,
            true
        )
        body:SetAttribute("VanTint", true)
        part(
            model,
            "CreamRoof",
            Vector3.new(20, 0.6, 9.4),
            base + Vector3.new(-1, 8.8, 0),
            Theme.Cream,
            true
        )
        part(model, "Cab", Vector3.new(3, 5, 9), base + Vector3.new(9.5, 4.5, 0), Theme.Cream, true)
        part(
            model,
            "Windshield",
            Vector3.new(0.12, 2.6, 7),
            Vector3.new(11.05, 6, 0),
            Theme.Graphite,
            false
        )
        for _, x in { -7, 7 } do
            for _, z in { -4.5, 4.5 } do
                local wheel = part(
                    model,
                    "Wheel",
                    Vector3.new(0.8, 3, 3),
                    Vector3.new(x, 1.5, z),
                    Theme.Graphite,
                    false
                )
                wheel.Shape = Enum.PartType.Cylinder
                wheel.CFrame *= CFrame.Angles(0, math.pi / 2, 0)
            end
        end
        for _, z in { -4.55, 4.55 } do
            part(
                model,
                "SideWindow",
                Vector3.new(7, 2, 0.12),
                Vector3.new(2, 6.5, z),
                Theme.Graphite,
                false
            )
            part(
                model,
                "CoralStripe",
                Vector3.new(19, 0.4, 0.12),
                Vector3.new(-1.5, 3.6, z),
                Theme.Coral,
                false
            )
        end
        for _, collisionPart in model:GetChildren() do
            if collisionPart:IsA("BasePart") then
                collisionPart.Transparency = 1
                collisionPart.CastShadow = false
                collisionPart:SetAttribute("CollisionOnly", true)
            end
        end
        local vanArt = game.ServerStorage.AssetLibrary:FindFirstChild("LOOPVAN-01")
        assert(vanArt, "Missing local Roamer art")
        local visual = vanArt:Clone()
        visual.Name = "Art"
        for _, mesh in visual:GetDescendants() do
            if mesh:IsA("MeshPart") and mesh.Name == "Teal" then
                mesh:SetAttribute("VanTint", true)
            end
        end
        visual.Parent = model
        model:SetAttribute("ArtStage", visual:GetAttribute("ArtStage"))
        local door = target(
            model,
            "StudioDoor",
            Vector3.new(-6, 3, 5),
            "THE ROAMER / AVAILABLE",
            "Enter your studio"
        )
        door.anchor:SetAttribute("QuayInteraction", "enter")
        model.PrimaryPart = body
        model.Parent = root
        local respawn = Instance.new("SpawnLocation")
        respawn.Name = "RoamerRespawn" .. index
        respawn.Size = Vector3.new(6, 0.2, 6)
        respawn.Anchored = true
        respawn.Transparency = 1
        respawn.CanCollide = false
        respawn.Neutral = true
        respawn.Duration = 0
        respawn.Enabled = false
        respawn.Parent = root
        scene.vans[index] = { model = model, door = door, index = index, spawn = respawn }
        local destination = scene.stops.P1.center + Vector3.new((index - 1) * 32, 0, 0)
        model:PivotTo(CFrame.new(destination + Vector3.new(-1.5, 5.5, 0)))
    end
    local actors = Instance.new("Folder")
    actors.Name = "Neighbors"
    actors.Parent = root
    local placements = {
        Tori = scene.stops.P1.anchor.Position + Vector3.new(4, -2, 0),
        Ivo = scene.buildings["NQ-BLD-03"].anchor.Position + Vector3.new(5, -2, 0),
        Naya = scene.buildings["NQ-BLD-02"].anchor.Position + Vector3.new(-5, -2, 0),
        ["Sana Bell"] = scene.buildings["NQ-BLD-04"].anchor.Position + Vector3.new(5, -2, 0),
        ["Ronan Wren"] = scene.finale.anchor.Position + Vector3.new(5, -2, 0),
        ["Nell Fen"] = scene.buildings["NQ-BLD-06"].anchor.Position + Vector3.new(4, -2, 0),
    }
    for _, source in Characters do
        local id = source.source:match("([^/]+)%.blend$")
        local template = game.ServerStorage.AssetLibrary:FindFirstChild(id)
        assert(template, "Missing accepted local NPC: " .. tostring(id))
        local model = template:Clone()
        model.Name = source.name
        model:SetAttribute("SourcePath", template:GetAttribute("SourcePath") or source.source)
        model:SetAttribute("SourceSHA256", template:GetAttribute("SourceSHA256") or source.sha256)
        model:PivotTo(CFrame.new(placements[source.name]))
        model.Parent = actors
    end
    local mica = world.discoveries.I03.anchor.Parent:Clone()
    mica.Name = "Mica"
    mica:SetAttribute("DiscoveryId", nil)
    for _, item in mica:GetDescendants() do
        if item:IsA("ProximityPrompt") or item:IsA("BillboardGui") then
            item:Destroy()
        end
    end
    mica:PivotTo(CFrame.new(scene.stops.P4.center + Vector3.new(4, 0, -15)))
    mica.Parent = actors
    -- Interior presentation reuses the actual existing concert and sound controls.
    local hall = Instance.new("Model")
    hall.Name = "LanternRoomInterior"
    hall.Parent = world.root
    for _, x in { 26, 58 } do
        part(
            hall,
            "WalnutWall",
            Vector3.new(0.6, 14, 32),
            Vector3.new(x, 7, 10),
            Theme.Walnut,
            true
        )
    end
    part(hall, "BackWall", Vector3.new(32, 14, 0.6), Vector3.new(42, 7, 26.5), Theme.Teal, true)
    for _, x in { 30, 54 } do
        part(hall, "EntryWall", Vector3.new(8, 14, 0.6), Vector3.new(x, 7, -6), Theme.Teal, true)
    end
    for _, x in { 30, 38, 46, 54 } do
        local light = part(
            hall,
            "AmberWallLight",
            Vector3.new(1, 2, 0.5),
            Vector3.new(x, 9, 26),
            Theme.Amber,
            false
        )
        light.Material = Enum.Material.Neon
    end
    local marquee = part(
        hall,
        "LanternMarquee",
        Vector3.new(20, 3, 0.3),
        Vector3.new(42, 11, -6),
        Theme.Cream,
        false
    )
    sign(marquee, "THE LANTERN ROOM / YOUR SIX-PART SET", 300)
    require(script.Parent.QuayAtmosphere).build(scene)
    world.demo = scene
    return scene
end
return Demo
