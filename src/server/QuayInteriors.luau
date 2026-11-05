-- Walkable room foundations. Exact collision/joins stay deterministic as art is replaced.
local Shared = game.ReplicatedStorage.Shared
local Theme = require(Shared.Theme)
local Catalog = require(Shared.QuayInteriorCatalog)
local Interiors = {}
function Interiors.build(world, scene)
    scene.interiors = {}
    world.listening.venues = {}
    world.listening.anchor:SetAttribute("PerformanceVenue", "Lantern Room")
    local function part(parent, name, size, at, color, collide)
        local p = Instance.new("Part")
        p.Name, p.Size, p.Position = name, size, at
        p.Color, p.Anchored, p.CanCollide = color, true, collide == true
        p.CanTouch, p.CanQuery = false, collide == true
        p.Material, p.Parent = Enum.Material.Wood, parent
        return p
    end
    local function control(parent, name, at, action, objectText)
        local p = part(parent, name, Vector3.new(2, 2, 1), at, Theme.Teal, false)
        local prompt = Instance.new("ProximityPrompt")
        prompt.ActionText, prompt.ObjectText = action, objectText
        prompt.RequiresLineOfSight, prompt.MaxActivationDistance, prompt.Parent = false, 10, p
        return { anchor = p, prompt = prompt }
    end
    for _, id in Catalog.Order do
        local spec = Catalog.ById[id]
        local model = Instance.new("Model")
        model.Name, model.Parent = "Interior_" .. id, world.root
        model:SetAttribute("ArtStage", "CODE_BLOCKOUT_NOT_ART_APPROVED")
        model:SetAttribute("BuildingId", id)
        local center = spec.center
        local setAnchor = world.listening.anchor
        part(model, "Floor", Vector3.new(32, 0.5, 32), center + Vector3.new(0, -0.25, 0), Theme.Walnut, true)
        part(model, "Ceiling", Vector3.new(33, 0.5, 33), center + Vector3.new(0, 15, 0), Theme.Ink, true)
        if id ~= "NQ-BLD-01" then
            for _, side in { -1, 1 } do
                part(model, "SideWall", Vector3.new(0.5, 15, 32), center + Vector3.new(side * 16, 7.5, 0), Theme.Teal, true)
            end
            part(model, "BackWall", Vector3.new(32, 15, 0.5), center + Vector3.new(0, 7.5, 16), Theme.Teal, true)
            part(model, "FrontWall", Vector3.new(32, 15, 0.5), center + Vector3.new(0, 7.5, -16), Theme.Teal, true)
            -- A low, step-free performance rug keeps every control in walking reach.
            part(model, "SetRug", Vector3.new(12, 0.06, 8), spec.stage + Vector3.new(0, -2.94, 0), Theme.Coral, false)
            local venue = control(model, "SetConsole", spec.stage, "Play / listen", spec.title)
            venue.anchor:SetAttribute("PerformanceVenue", spec.title)
            venue.anchor:SetAttribute("GuideIcon", "pads")
            setAnchor = venue.anchor
            table.insert(world.listening.venues, venue)
            local desk = part(model, "SetDesk", Vector3.new(5, 2.2, 1.5), spec.stage + Vector3.new(0, -1.9, 1.4), Theme.Walnut, true)
            for pad = 1, 8 do
                local key = part(model, "ConsolePad", Vector3.new(0.4, 0.08, 0.4), desk.Position + Vector3.new((pad - 4.5) * 0.52, 1.15, 0), Theme.Amber, false)
                key.Material = Enum.Material.Neon
            end
        end
        -- Acoustic back panels, warm coves and a clear center aisle frame the performer.
        for _, dx in { -11, -7, 7, 11 } do
            part(model, "AcousticSlat", Vector3.new(1.5, 8, 0.3), center + Vector3.new(dx, 7, 15.5), Theme.Walnut, false)
        end
        for _, dx in { -13, 13 } do
            local lamp = part(model, "WallLamp", Vector3.new(0.3, 1.4, 2), center + Vector3.new(dx, 10, 4), Theme.Amber, false)
            lamp.Material = Enum.Material.Neon
            lamp:SetAttribute("InteriorMusicLight", true)
            local light = Instance.new("PointLight")
            light.Color, light.Range, light.Brightness, light.Shadows = Theme.Amber, 21, 0.7, false
            light.Parent = lamp
            part(model, "SpeakerCabinet", Vector3.new(2.2, 5, 2), center + Vector3.new(dx, 2.5, 11), Theme.Ink, true)
            for _, y in { 1.6, 3.5 } do
                local speaker = part(model, "SpeakerCone", Vector3.new(0.2, 1.5, 1.5), center + Vector3.new(dx, y, 9.95), Theme.Graphite, false)
                speaker.Shape = Enum.PartType.Cylinder
                speaker.CFrame *= CFrame.Angles(0, math.pi / 2, 0)
            end
        end
        for _, dx in { -10, 10 } do
            part(model, "ListenerBench", Vector3.new(4, 1.5, 2), center + Vector3.new(dx, 0.75, -5), Theme.Walnut, true)
        end
        -- Record wall / repair storage stay against walls, away from the entrance and stage.
        for shelf = 1, 3 do
            local z = -9 + shelf * 5
            part(model, "DisplayShelf", Vector3.new(1.2, 0.2, 3.8), center + Vector3.new(-14.5, 3.8, z), Theme.Walnut, false)
            for record = 1, 4 do
                local cover = part(model, if id == "NQ-BLD-03" then "RepairCase" else "RecordSleeve",
                    Vector3.new(0.2, 1.5, 0.7), center + Vector3.new(-14.5, 4.6, z + (record - 2.5) * 0.8),
                    if record % 2 == 0 then Theme.Coral else Theme.Cream, false)
                cover:SetAttribute("ReplacementSlot", if id == "NQ-BLD-03" then "repair_prop" else "record_sleeve")
            end
        end
        local activity = control(model, "ActivityDesk", center + Vector3.new(-12, 2, -10),
            "Explore", spec.title)
        activity.anchor:SetAttribute("QuayInteraction", "building:" .. id)
        activity.anchor:SetAttribute("GuideIcon", "eye")
        local exit = if id == "NQ-BLD-01" then scene.courtExit
            else control(model, "Exit", center + Vector3.new(0, 2, -14), "Exit", "NEEDLE QUAY")
        exit.anchor.Position = center + Vector3.new(0, 2, -14)
        exit.anchor:SetAttribute("QuayInteraction", "outside_" .. id)
        exit.anchor:SetAttribute("GuideIcon", "door")
        local exterior = scene.buildings[id].anchor
        local door = control(scene.root, "InteriorDoor_" .. id, exterior.Position + Vector3.new(5, 0, -2), "Enter", spec.title)
        door.anchor:SetAttribute("QuayInteraction", "inside_" .. id)
        door.anchor:SetAttribute("GuideIcon", "door")
        for _, target in {
            { setAnchor, "set", "pads", Theme.Amber },
            { activity.anchor, "look", "eye", Theme.FadedTeal },
            { exit.anchor, "exit", "door", Theme.Cream },
        } do
            target[1]:SetAttribute("InteriorGuideKind", target[2])
            target[1]:SetAttribute("GuideIcon", target[3])
            local tile = part(model, "PictureFloor_" .. target[2], Vector3.new(3.5, 0.04, 2.5),
                Vector3.new(target[1].Position.X, if id == "NQ-BLD-01" and target[2] == "set" then 1.04 else 0.04,
                    target[1].Position.Z + (if target[2] == "exit" then 2.8 else -2.8)), Theme.Ink, false)
            tile:SetAttribute("GuideFloor", true)
            tile:SetAttribute("GuideIcon", target[3])
            tile:SetAttribute("InteriorGuideKind", target[2])
        end
        -- Frames distinguish travel from furniture; symbols stay readable without an art texture.
        for _, frame in { { model, exit.anchor.Position, Theme.FadedTeal }, { scene.root, door.anchor.Position, Theme.Amber } } do
            local at = frame[2]
            for _, side in { -1, 1 } do
                part(frame[1], "DoorFrame", Vector3.new(0.25, 5.5, 0.35),
                    Vector3.new(at.X + side * 2.1, 2.75, at.Z + 0.5), frame[3], false)
            end
            part(frame[1], "DoorHeader", Vector3.new(4.5, 0.3, 0.35),
                Vector3.new(at.X, 5.5, at.Z + 0.5), frame[3], false)
        end
        scene.interiors[id] = { model = model, spawn = spec.spawn, exit = exit, door = door,
            set = setAnchor, activity = activity.anchor }
    end
end
return Interiors
