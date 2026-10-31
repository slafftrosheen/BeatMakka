-- Functional targets are authored independently of candidate shells and collision.
local Theme = require(game:GetService("ReplicatedStorage").Shared.Theme)
local Assets = require(script.Parent.AssetSpawner)
local Details = {}

function Details.attach(model, id, pivot)
    local function part(name, size, position, color)
        return Assets.part(model, name, size, pivot * CFrame.new(position), color, false)
    end
    local function socket(parent, name, cf)
        local attachment = Instance.new("Attachment")
        attachment.Name = name
        attachment.CFrame = cf or CFrame.identity
        attachment.Parent = parent
        return attachment
    end
    local function target(object, role)
        object:SetAttribute("MotionRole", role)
        return object
    end
    if id == "H02" then
        socket(
            part("StackingSocket", Vector3.one * 0.05, Vector3.new(0, 8, 0), Theme.Teal),
            "StackTop"
        )
        if not model:GetAttribute("UsesImportedArt") then
            model.ArtProxy:Destroy()
            part("SpeakerCabinet", Vector3.new(4, 8, 3), Vector3.new(0, 4, 0), Theme.Teal)
            local cone = target(
                part(
                    "Woofer",
                    Vector3.new(0.15, 2.7, 2.7),
                    Vector3.new(0, 2.5, -1.55),
                    Theme.Graphite
                ),
                "SpeakerCone"
            )
            cone.Shape = Enum.PartType.Cylinder
            cone.CFrame *= CFrame.Angles(0, math.pi / 2, 0)
            part("Horn", Vector3.new(2.8, 1.6, 0.18), Vector3.new(0, 6, -1.55), Theme.Graphite)
        end
    elseif id == "H04" then
        if not model:GetAttribute("UsesImportedArt") then
            model.ArtProxy:Destroy()
            part("RobotBody", Vector3.new(2, 1.8, 1.6), Vector3.new(0, 1.8, 0), Theme.Teal)
            local head = Instance.new("Model")
            head.Name = "Head"
            head.WorldPivot = pivot * CFrame.new(0, 2.8, 0)
            head.Parent = model
            target(head, "RobotHead")
            local shell =
                part("HeadShell", Vector3.new(2.4, 1.15, 1.8), Vector3.new(0, 3.3, 0), Theme.Cream)
            shell.Parent = head
            for _, x in { -0.55, 0.55 } do
                local face = part(
                    "FaceBar",
                    Vector3.new(0.6, 0.15, 0.08),
                    Vector3.new(x, 3.35, -0.94),
                    Theme.Graphite
                )
                face.Parent = head
            end
            for index, x in { -1.35, 1.35 } do
                local arm = Instance.new("Model")
                arm.Name = if index == 1 then "LeftArm" else "RightArm"
                arm.WorldPivot = pivot * CFrame.new(x, 2.5, 0)
                arm.Parent = model
                target(arm, arm.Name)
                local limb = part(
                    "Arm",
                    Vector3.new(0.6, 1.5, 0.6),
                    Vector3.new(x, 1.85, 0),
                    Theme.FadedTeal
                )
                limb.Parent = arm
                socket(limb, "CarrySocket", CFrame.new(0, -0.75, 0))
                local wheel = target(
                    part(
                        "Wheel",
                        Vector3.new(0.35, 1, 1.4),
                        Vector3.new(x, 0.55, 0),
                        Theme.Graphite
                    ),
                    "RobotWheel"
                )
                wheel.Shape = Enum.PartType.Cylinder
            end
            model:SetAttribute("UsesAuthoredRigProxy", true)
        end
        local anchor = part("ChirpSocket", Vector3.one * 0.05, Vector3.new(0, 3, -1), Theme.Cream)
        anchor.Transparency = 1
        socket(anchor, "DiscoveryAudio")
    elseif id == "H05" or id == "P13" then
        local position = if id == "H05" then Vector3.new(0, 10.8, -0.5) else Vector3.new(0, 1, -0.2)
        local bulb = part("EmissiveInsert", Vector3.new(0.45, 0.5, 0.45), position, Theme.Cream)
        socket(bulb, "LightAttachment")
        local glass = part("GlassTarget", Vector3.new(0.7, 0.8, 0.7), position, Theme.Cream)
        glass.Transparency = 0.75
        glass.CastShadow = false
        local light = Instance.new("PointLight")
        light.Name = "PracticalLight"
        light.Color = Theme.Amber
        light.Brightness = 0.8
        light.Range = 12
        light.Shadows = false
        light.Parent = bulb
        bulb:SetAttribute("PersonalLamp", true)
    elseif id == "H03" then
        local insert =
            part("RecordInsert", Vector3.new(2.2, 1.6, 0.18), Vector3.new(0, 2, -0.3), Theme.Coral)
        socket(insert, "SleeveArtwork")
    elseif id == "P04" then
        local insert =
            part("BrowseSocket", Vector3.new(3, 1.2, 0.08), Vector3.new(0, 2.7, -1.55), Theme.Coral)
        socket(insert, "SleeveArtwork")
    elseif id == "P11" then
        local anchor =
            part("FoliageTarget", Vector3.one * 0.05, Vector3.new(0, 2.5, 0), Theme.Cream)
        anchor.Transparency = 1
        socket(anchor, "FoliageSocket")
    elseif id == "P14" then
        part("StatusInsert", Vector3.new(0.3, 0.3, 0.08), Vector3.new(0.5, 1.5, -0.55), Theme.Amber)
    end
    -- Imported articulated targets are explicit. Never animate the fused shell as a head.
    for _, object in model:GetDescendants() do
        if object.Name == "Head" then
            target(object, "RobotHead")
        elseif object.Name == "LeftArm" or object.Name == "RightArm" then
            target(object, object.Name)
        elseif object.Name == "Woofer" then
            target(object, "SpeakerCone")
        end
    end
end

return Details
