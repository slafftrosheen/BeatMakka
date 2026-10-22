local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Shared = game:GetService("ReplicatedStorage").Shared
local Theme = require(Shared.Theme)
local Pads = require(Shared.SamplerPadLayout)
local LightingPresets = require(Shared.LightingPresets)
local Assets = require(script.Parent.AssetSpawner)
local Kit = require(script.Parent.ModularKit)
local Details = require(script.Parent.AssetDetails)
local WorldBuilder = {}

local function label(parent, text, offset)
    local gui = Instance.new("BillboardGui")
    gui.Name = "StatusLabel"
    gui.Size = UDim2.fromOffset(260, 52)
    gui.StudsOffset = Vector3.new(0, offset or 3, 0)
    gui.MaxDistance = 42
    gui.AlwaysOnTop = false
    gui.Parent = parent
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.fromScale(1, 1)
    textLabel.BackgroundColor3 = Theme.Ink
    textLabel.BackgroundTransparency = 0.1
    textLabel.TextColor3 = Theme.Cream
    textLabel.TextSize = 15
    textLabel.Font = Theme.Bold
    textLabel.Text = text
    textLabel.TextWrapped = true
    textLabel.Parent = gui
    return textLabel
end

local function prompt(anchor, action, name)
    local p = Instance.new("ProximityPrompt")
    p.ActionText = action
    p.ObjectText = name
    p.MaxActivationDistance = 9
    p.RequiresLineOfSight = true
    p.HoldDuration = 0.2
    p.Parent = anchor
    return p
end

function WorldBuilder.build()
    local storage = game:GetService("ServerStorage")
    local oldKit = storage:FindFirstChild("ExactModuleLibrary")
    if oldKit then
        oldKit:Destroy()
    end
    local library = Instance.new("Folder")
    library.Name = "ExactModuleLibrary"
    library.Parent = storage
    for id in Kit.Sizes do
        Kit.create(library, id, CFrame.identity)
    end
    local existing = Workspace:FindFirstChild("NeedleQuay")
    if existing then
        existing:Destroy()
    end
    local root = Instance.new("Folder")
    root.Name = "NeedleQuay"
    root.Parent = Workspace
    local part = Assets.part
    for property, value in LightingPresets.dusk do
        Lighting[property] = value
    end
    part(root, "Promenade", Vector3.new(112, 2, 80), CFrame.new(20, -1, 0), Theme.Stone, true)
    local kitFolder = Instance.new("Folder")
    kitFolder.Name = "ExactModules"
    kitFolder:SetAttribute("AssetId", "H06")
    kitFolder.Parent = root
    for _, x in { -16, -8, 0, 8 } do
        Kit.create(kitFolder, "M01", CFrame.new(x, 2, 11.5))
        for _, z in { -12, -4, 4 } do
            Kit.create(kitFolder, "M07", CFrame.new(x, 1, z))
            local roof = Kit.create(kitFolder, "M08", CFrame.new(x, 14, z))
            roof:SetAttribute("CameraRoof", true)
        end
        Kit.create(kitFolder, "M09", CFrame.new(x, 14, -12.5))
        Kit.create(kitFolder, "M16", CFrame.new(x, 13, 11.5))
        Kit.create(kitFolder, "M10", CFrame.new(x, 10.5, -16))
    end
    for _, x in { -15.5, 16.5 } do
        for _, z in { -12, -4, 4 } do
            Kit.create(kitFolder, "M01", CFrame.new(x, 2, z) * CFrame.Angles(0, -math.pi / 2, 0))
        end
    end
    for _, x in { -16, 12 } do
        Kit.create(kitFolder, "M02", CFrame.new(x, 2, -12.5))
    end
    for _, x in { -12, 4 } do
        Kit.create(kitFolder, "M05", CFrame.new(x, 2, -12.5))
    end
    Kit.create(kitFolder, "M04", CFrame.new(-4, 2, -12.5))
    Kit.create(kitFolder, "M03", CFrame.new(-16.5, 2, -12.5))
    Kit.create(kitFolder, "M03", CFrame.new(15.5, 2, -12.5))
    Kit.create(kitFolder, "M17", CFrame.new(-20, 7, -13.5))
    local door = Kit.create(kitFolder, "M06", CFrame.new(-3, 2, -12))
    door:PivotTo(CFrame.new(-3, 2, -12) * CFrame.Angles(0, -math.pi / 2, 0))
    local shutter = Kit.create(kitFolder, "M18", CFrame.new(4, 4, -11.5))
    shutter:SetAttribute("ParkedOpen", true)
    shutter:PivotTo(CFrame.new(4, 14, -11.5))
    Kit.create(kitFolder, "M12", CFrame.new(-4, 0, -20))
    Kit.create(kitFolder, "M11", CFrame.new(-12, 0, -16))
    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "Arrival"
    spawn.Size = Vector3.new(6, 0.2, 6)
    spawn.CFrame = CFrame.new(0, 0.1, -25)
    spawn.Transparency = 1
    spawn.Anchored = true
    spawn.Neutral = true
    spawn.Duration = 0
    spawn.Parent = root
    part(root, "Water", Vector3.new(150, 1, 35), CFrame.new(20, -2, -58), Theme.FadedTeal, false)
    part(
        root,
        "WaterfrontBackstop",
        Vector3.new(112, 4, 0.5),
        CFrame.new(20, 2, -39),
        Theme.Walnut,
        true
    )
    for x = -32, 72, 8 do
        Kit.create(kitFolder, "M15", CFrame.new(x, 0, -39))
        Kit.create(kitFolder, "M14", CFrame.new(x, 0, -38.5))
        Kit.create(kitFolder, "M13", CFrame.new(x, -0.5, -32))
    end
    local stations = {}
    for index, x in { -8, 8 } do
        Assets.place(
            root,
            "P01",
            CFrame.new(x, 2, 5),
            Vector3.new(8, 3.5, 4),
            Theme.Walnut,
            Vector3.new(8, 3.4, 4)
        )
        local housing = CFrame.new(x, 5.5, 5)
        local sampler = Assets.place(root, "H01", housing, Vector3.new(6, 1.25, 4), Theme.Teal)
        Pads.createTargets(sampler, housing)
        local display = part(
            sampler,
            "DisplayPlane",
            Vector3.new(1.4, 0.06, 0.95),
            housing * CFrame.new(1.8, 1.31, 0.7),
            Theme.Graphite,
            false
        )
        local displayGui = Instance.new("SurfaceGui")
        displayGui.Face = Enum.NormalId.Top
        displayGui.CanvasSize = Vector2.new(256, 168)
        displayGui.Parent = display
        local displayText = Instance.new("TextLabel")
        displayText.Size = UDim2.fromScale(1, 1)
        displayText.BackgroundColor3 = Theme.Graphite
        displayText.TextColor3 = Theme.Cream
        displayText.Font = Theme.Bold
        displayText.TextSize = 28
        displayText.Text = "MK-I\nREADY"
        displayText.Parent = displayGui
        for _, controlX in { 1.4, 2.2 } do
            local knob = part(
                sampler,
                "KnobInterface",
                Vector3.new(0.18, 0.5, 0.5),
                housing * CFrame.new(controlX, 1.39, -0.7) * CFrame.Angles(0, 0, math.pi / 2),
                Theme.Graphite,
                false
            )
            knob.Shape = Enum.PartType.Cylinder
        end
        local anchor = part(
            sampler,
            "Interaction",
            Vector3.new(6, 2, 4),
            CFrame.new(x, 6, 5),
            Theme.Teal,
            false
        )
        anchor.Transparency = 1
        local id = "Station_" .. index
        sampler:SetAttribute("StationId", id)
        anchor:SetAttribute("StationId", id)
        stations[id] = {
            anchor = anchor,
            prompt = prompt(anchor, "Make music", "MK-I sampler"),
            label = label(anchor, "MK-I  /  READY", 2),
            screen = displayText,
        }
    end
    -- Approved reusable masters dress the exact shell without owning navigation.
    for _, x in { -13, 13 } do
        Assets.place(root, "H02", CFrame.new(x, 2, 9), Vector3.new(4, 8, 3), Theme.Teal)
        Assets.place(
            root,
            "P02",
            CFrame.new(x * 0.62, 2, -0.5),
            Vector3.new(2.5, 3, 2.5),
            Theme.Walnut
        )
        Assets.place(root, "P11", CFrame.new(x * 1.48, 0, -14), Vector3.new(2, 2.5, 2), Theme.Cream)
        Assets.place(
            root,
            "P12",
            CFrame.new(x * 1.48, 2.1, -14),
            Vector3.new(3, 4, 3),
            Theme.FadedTeal
        )
        Assets.place(root, "P13", CFrame.new(x, 10, 11), Vector3.new(1.5, 2, 1.5), Theme.Cream)
    end
    Assets.place(root, "H03", CFrame.new(-13, 2, -6), Vector3.new(3, 2.5, 3), Theme.Walnut)
    Assets.place(
        root,
        "P04",
        CFrame.new(12, 2, -6),
        Vector3.new(5, 3.5, 3),
        Theme.Walnut,
        Vector3.new(5, 3.4, 3)
    )
    Assets.place(
        root,
        "P14",
        CFrame.new(15, 7, 7) * CFrame.Angles(0, -math.pi / 2, 0),
        Vector3.new(2, 3, 1),
        Theme.Teal
    )
    Assets.place(root, "P05", CFrame.new(-8, 10, 11), Vector3.new(6, 0.7, 1.5), Theme.Walnut)
    Assets.place(root, "P07", CFrame.new(-8, 10.7, 10.8), Vector3.new(2, 1.5, 0.8), Theme.Teal)
    for _, x in { -22, 38 } do
        Assets.place(
            root,
            "H05",
            CFrame.new(x, 0, -24),
            Vector3.new(2.5, 12, 3),
            Theme.Teal,
            Vector3.new(0.6, 10, 0.6)
        )
    end
    local nodes = {}
    local specs = {
        { "I01", "metal_hit", "Quay metal", "I01", Vector3.new(26, 2, -8), Vector3.new(3, 2, 0.3) },
        { "I02", "vent_thump", "Vent thump", "P16", Vector3.new(29, 0, 8), Vector3.new(3, 3, 2) },
        {
            "I03",
            "robot_chirp",
            "Helper chirp",
            "H04",
            Vector3.new(20, 0, 18),
            Vector3.new(3.5, 4, 3),
        },
    }
    for _, spec in specs do
        local id, sampleId, name, artId, position, size = table.unpack(spec)
        local model = Assets.place(root, artId, CFrame.new(position), size, Theme.FadedTeal)
        model:SetAttribute("DiscoveryId", id)
        local anchor = part(
            model,
            "DiscoveryTarget",
            Vector3.new(3, 3, 3),
            CFrame.new(position + Vector3.new(0, 2, 0)),
            Theme.Cream,
            false
        )
        anchor.Transparency = 1
        nodes[id] = {
            anchor = anchor,
            prompt = prompt(anchor, "Preview / collect", name),
            sampleId = sampleId,
        }
        label(anchor, name, 2.5)
    end
    local resonator =
        Assets.place(root, "I04", CFrame.new(0, 8, 11), Vector3.new(3, 4, 1.5), Theme.Cream)
    resonator:SetAttribute("PersonalRestoration", true)
    for index = 1, 4 do
        local light = part(
            resonator,
            "State_" .. index,
            Vector3.new(0.4, 0.4, 0.2),
            CFrame.new(-1.2 + (index - 1) * 0.8, 8.2, 10),
            Theme.Graphite,
            false
        )
        light:SetAttribute("RestorationIndicator", index)
    end
    for _, x in { -12, 12 } do
        local lamp = part(
            root,
            "WorkshopLamp",
            Vector3.new(1, 0.4, 1),
            CFrame.new(x, 11, 7),
            Theme.Cream,
            false
        )
        local light = Instance.new("PointLight")
        light.Color = Theme.Amber
        light.Brightness = 1
        light.Range = 18
        light.Shadows = true
        light.Parent = lamp
        lamp:SetAttribute("PersonalLamp", true)
    end
    local dustAnchor =
        part(root, "AmbientDust", Vector3.new(12, 0.1, 12), CFrame.new(0, 9, 0), Theme.Cream, false)
    dustAnchor.Transparency = 1
    local dust = Instance.new("ParticleEmitter")
    dust.Name = "F04_Dust"
    dust.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    dust.Rate = 2
    dust.Lifetime = NumberRange.new(3, 5)
    dust.Speed = NumberRange.new(0.1, 0.2)
    dust.Size = NumberSequence.new(0.035)
    dust.Transparency = NumberSequence.new(0.8)
    dust.Color = ColorSequence.new(Theme.Cream)
    dust.LightEmission = 0
    dust:SetAttribute("AmbientAccent", true)
    dust.Parent = dustAnchor
    -- v0.2 atlas page 14: 12 x 8 stage within a 28 x 24 court.
    part(root, "W01_Stage", Vector3.new(12, 1, 8), CFrame.new(42, 0.5, 15), Theme.Walnut, true)
    local stageRamp = Instance.new("WedgePart")
    stageRamp.Name = "W01_AccessRamp"
    stageRamp.Size = Vector3.new(6, 1, 4)
    stageRamp.CFrame = CFrame.new(42, 0.5, 9)
    stageRamp.Anchored = true
    stageRamp.Color = Theme.Stone
    stageRamp.Parent = root
    local podium = Assets.place(
        root,
        "I05",
        CFrame.new(42, 1, 15),
        Vector3.new(3, 4, 2),
        Theme.Teal,
        Vector3.new(3, 4, 2)
    )
    local listeningAnchor = part(
        podium,
        "ListeningTarget",
        Vector3.new(3, 3, 3),
        CFrame.new(42, 4, 14),
        Theme.Cream,
        false
    )
    listeningAnchor.Transparency = 1
    listeningAnchor:SetAttribute("AssetId", "I05")
    local listening = {
        anchor = listeningAnchor,
        prompt = prompt(listeningAnchor, "Share your loop", "Opt-in listening / 32-stud range"),
        label = label(listeningAnchor, "LISTENING COURT / IDLE", 3),
    }
    local court = part(
        root,
        "ListeningCourt",
        Vector3.new(28, 0.08, 24),
        CFrame.new(42, 0.04, 8),
        Theme.Stone,
        false
    )
    court:SetAttribute("AssetId", "W01")
    Kit.create(kitFolder, "P08", CFrame.new(-5, 2.01, -4))
    Kit.create(kitFolder, "P09", CFrame.new(-12, 2.05, 10))
    Kit.create(kitFolder, "P10", CFrame.new(10, 2.02, 10))
    Kit.create(kitFolder, "P15", CFrame.new(-14, 5.5, 5))
    Assets.place(
        root,
        "P06",
        CFrame.new(-12, 2, -8),
        Vector3.new(3, 3, 3),
        Theme.Walnut,
        Vector3.new(3, 3, 3)
    )
    local backdrop = Instance.new("Folder")
    backdrop.Name = "Backdrop"
    backdrop.Parent = root
    Kit.create(backdrop, "W03", CFrame.new(-20, -5, -100))
    Kit.create(backdrop, "W04", CFrame.new(8, 8, -84))
    -- Unmarked promenade edges are bounded. These are independent of decorative art.
    for _, spec in
        {
            { Vector3.new(1, 8, 80), CFrame.new(-36, 4, 0) },
            { Vector3.new(1, 8, 80), CFrame.new(76, 4, 0) },
            { Vector3.new(112, 8, 1), CFrame.new(20, 4, 40) },
        }
    do
        local boundary = part(root, "NavigationBoundary", spec[1], spec[2], Theme.Graphite, true)
        boundary.Transparency = 1
        boundary.CastShadow = false
    end
    for _, model in root:GetChildren() do
        if model:IsA("Model") and model:GetAttribute("AssetId") then
            Details.attach(model, model:GetAttribute("AssetId"), model:GetPivot())
        end
    end
    Assets.place(
        root,
        "P03",
        CFrame.new(42, 0, -1),
        Vector3.new(7, 3.5, 2.5),
        Theme.Walnut,
        Vector3.new(7, 1.8, 2.5)
    )
    local helper = nodes.I03.anchor.Parent
    local talkAnchor = part(
        helper,
        "MicaTalkTarget",
        Vector3.new(1, 2, 1),
        CFrame.new(17, 2.5, 18),
        Theme.Cream,
        false
    )
    talkAnchor.Transparency = 1
    talkAnchor:SetAttribute("QuestId", "first_courtyard_set")
    local talkPrompt = prompt(talkAnchor, "Talk to Mica", "Mica / quay caretaker")
    talkPrompt.KeyboardKeyCode = Enum.KeyCode.F
    talkPrompt.GamepadKeyCode = Enum.KeyCode.ButtonY
    talkPrompt.MaxActivationDistance = 7
    label(talkAnchor, "MICA / QUAY CARETAKER", 2.5)
    return {
        root = root,
        stations = stations,
        discoveries = nodes,
        listening = listening,
        quest = { anchor = talkAnchor, prompt = talkPrompt },
    }
end
return WorldBuilder
