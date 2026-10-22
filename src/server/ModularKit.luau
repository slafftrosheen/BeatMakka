-- Exact reusable geometry. Origins are lower-left/rear floor corners, facing -Z.
-- Window openings are prototype choices; canonical outer envelopes remain fixed.
local Theme = require(game:GetService("ReplicatedStorage").Shared.Theme)
local Assets = require(script.Parent.AssetSpawner)
local Kit = {}
Kit.Sizes = {
    M01 = Vector3.new(8, 12, 1),
    M02 = Vector3.new(4, 12, 1),
    M03 = Vector3.new(1, 12, 1),
    M04 = Vector3.new(8, 12, 1),
    M05 = Vector3.new(8, 12, 1),
    M06 = Vector3.new(6, 10, 0.5),
    M07 = Vector3.new(8, 1, 8),
    M08 = Vector3.new(8, 1, 8),
    M09 = Vector3.new(8, 1, 1),
    M10 = Vector3.new(8, 2, 4),
    M11 = Vector3.new(8, 2, 4),
    M12 = Vector3.new(8, 2, 8),
    M13 = Vector3.new(8, 0.5, 8),
    M14 = Vector3.new(8, 1, 1),
    M15 = Vector3.new(8, 4, 0.5),
    M16 = Vector3.new(8, 3, 1),
    M17 = Vector3.new(8, 8, 1),
    M18 = Vector3.new(8, 10, 0.5),
    P08 = Vector3.new(10, 0.05, 8),
    P09 = Vector3.new(8, 0.2, 0.2),
    P10 = Vector3.new(2, 0.3, 2),
    P15 = Vector3.new(3, 1, 2),
    W03 = Vector3.new(40, 50, 12),
    W04 = Vector3.new(64, 12, 8),
}

function Kit.create(parent, id, origin)
    local size = assert(Kit.Sizes[id], "Unknown exact kit ID: " .. id)
    local model = Instance.new("Model")
    model.Name = id
    model:SetAttribute("AssetId", id)
    model:SetAttribute("AuthoredGeometry", true)
    model:SetAttribute("OriginConvention", "LowerLeftRearFloor")
    model.WorldPivot = origin
    model.Parent = parent
    local function box(name, dimensions, center, color, collision)
        return Assets.part(model, name, dimensions, origin * CFrame.new(center), color, collision)
    end
    if id == "M04" then
        box("LeftPost", Vector3.new(1, 12, 1), Vector3.new(0.5, 6, 0.5), Theme.Cream, true)
        box("RightPost", Vector3.new(1, 12, 1), Vector3.new(7.5, 6, 0.5), Theme.Cream, true)
        box("Header", Vector3.new(6, 2, 1), Vector3.new(4, 11, 0.5), Theme.Teal, true)
        model:SetAttribute("Clearance", Vector2.new(6, 10))
    elseif id == "M05" then
        box("Sill", Vector3.new(8, 3, 1), Vector3.new(4, 1.5, 0.5), Theme.Cream, true)
        box("Header", Vector3.new(8, 2, 1), Vector3.new(4, 11, 0.5), Theme.Teal, true)
        for _, x in { 0.25, 7.75 } do
            box("Mullion", Vector3.new(0.5, 7, 1), Vector3.new(x, 6.5, 0.5), Theme.Cream, true)
        end
        model:SetAttribute("OpeningIsProvisional", true)
    elseif id == "M06" then
        model:SetAttribute("OriginConvention", "HingeEdge")
        local leaf = box("DoorLeaf", size, Vector3.new(3, 5, 0), Theme.Teal, false)
        local hinge = Instance.new("Attachment")
        hinge.Name = "Hinge"
        hinge.CFrame = CFrame.new(-3, -5, 0)
        hinge.Parent = leaf
        box("Handle", Vector3.new(0.2, 1, 0.2), Vector3.new(5.2, 5, -0.4), Theme.Amber, false)
    elseif id == "M10" then
        for n = 0, 7 do
            box(
                "AwningStripe",
                Vector3.new(1, 0.25, 4),
                Vector3.new(n + 0.5, 1.875, 2),
                if n % 2 == 0 then Theme.Coral else Theme.Cream,
                false
            )
        end
        box("Valance", Vector3.new(8, 1, 0.2), Vector3.new(4, 1, 0.1), Theme.Coral, false)
        box("Mount", Vector3.new(8, 2, 0.2), Vector3.new(4, 1, 3.9), Theme.Teal, false)
    elseif id == "M11" then
        for n = 1, 3 do
            box(
                "Step",
                Vector3.new(8, n * 2 / 3, 4 / 3),
                Vector3.new(4, n / 3, (n - 0.5) * 4 / 3),
                Theme.Stone,
                true
            )
        end
    elseif id == "M12" then
        local ramp = Instance.new("WedgePart")
        ramp.Name = "Ramp"
        ramp.Size = size
        ramp.CFrame = origin * CFrame.new(size / 2)
        ramp.Anchored = true
        ramp.CanTouch = false
        ramp.Color = Theme.Stone
        ramp.Parent = model
    elseif id == "M15" then
        for _, x in { 0.25, 7.75 } do
            box("Post", Vector3.new(0.5, 4, 0.5), Vector3.new(x, 2, 0.25), Theme.Cream, false)
        end
        for _, y in { 1.2, 3.7 } do
            box("Rail", Vector3.new(8, 0.3, 0.5), Vector3.new(4, y, 0.25), Theme.Walnut, false)
        end
        local barrier = box("CollisionProxy", size, size / 2, Theme.Graphite, true)
        barrier.Transparency = 1
        barrier.CastShadow = false
    elseif id == "M17" then
        local disc =
            box("Vinyl", Vector3.new(0.5, 8, 8), Vector3.new(4, 4, 0.5), Theme.Graphite, false)
        disc.Shape = Enum.PartType.Cylinder
        disc.CFrame = origin * CFrame.new(4, 4, 0.5) * CFrame.Angles(0, math.pi / 2, 0)
        local center = box(
            "SignCenter",
            Vector3.new(0.55, 2.5, 2.5),
            Vector3.new(4, 4, 0.5),
            Theme.Cream,
            false
        )
        center.Shape = Enum.PartType.Cylinder
        center.CFrame = disc.CFrame
        center:SetAttribute("RestorationSign", true)
    elseif id == "M18" then
        for n = 0, 9 do
            box(
                "ShutterSlat",
                Vector3.new(8, 0.95, 0.5),
                Vector3.new(4, n + 0.5, 0.25),
                Theme.FadedTeal,
                false
            )
        end
        model:SetAttribute("ShutterTravel", 10)
    elseif id == "P08" then
        box("Rug", size, size / 2, Theme.Teal, false)
        for _, x in { 0.2, 9.8 } do
            box(
                "WovenBorder",
                Vector3.new(0.2, 0.01, 8),
                Vector3.new(x, 0.055, 4),
                Theme.Cream,
                false
            )
        end
    elseif id == "P09" then
        box("CableRun", size, size / 2, Theme.Graphite, false)
        model:SetAttribute("VariantLengths", "4,8")
    elseif id == "P10" then
        for n = 0, 15 do
            local angle = n * math.pi / 8
            local segment = box(
                "Coil",
                Vector3.new(0.42, 0.3, 0.15),
                Vector3.new(1 + 0.8 * math.cos(angle), 0.15, 1 + 0.8 * math.sin(angle)),
                Theme.Graphite,
                false
            )
            segment.CFrame *= CFrame.Angles(0, -angle - math.pi / 2, 0)
        end
    elseif id == "P15" then
        box("Tray", Vector3.new(3, 0.2, 2), Vector3.new(1.5, 0.1, 1), Theme.Walnut, false)
        box("RepairSpool", Vector3.new(0.6, 0.8, 0.6), Vector3.new(0.7, 0.6, 1), Theme.Cream, false)
        box("ToolCase", Vector3.new(1.2, 0.5, 0.8), Vector3.new(2, 0.45, 1), Theme.Teal, false)
    elseif id == "W03" then
        for n = 0, 7 do
            local h = 18 + (n * 13) % 33
            box(
                "SkylineMass",
                Vector3.new(4, h, 8),
                Vector3.new(n * 5 + 2, h / 2, 6),
                Theme.FadedTeal,
                false
            )
        end
    elseif id == "W04" then
        box("BridgeDeck", Vector3.new(64, 2, 8), Vector3.new(32, 11, 4), Theme.FadedTeal, false)
        for _, x in { 4, 28, 52 } do
            box("Pier", Vector3.new(2, 10, 4), Vector3.new(x, 5, 4), Theme.FadedTeal, false)
        end
    else
        box(
            "Geometry",
            size,
            size / 2,
            if id == "M07" or id == "M08"
                then Theme.Walnut
                elseif id == "M13" or id == "M14" then Theme.Stone
                else Theme.Teal,
            true
        )
    end
    return model
end

return Kit
