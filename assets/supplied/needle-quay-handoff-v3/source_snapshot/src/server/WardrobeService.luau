-- Local, deterministic candidate accessories. Only our tagged objects are changed;
-- the player's avatar, clothing, scale, accessories and account outfit stay intact.
local Shared = game:GetService("ReplicatedStorage").Shared
local Catalog = require(Shared.WardrobeCatalog)
local Identity = require(Shared.QuayIdentity)
local Theme = require(Shared.Theme)
local Service = {}
Service.__index = Service

local function clearCharacter(character)
    if character then
        for _, child in character:GetChildren() do
            if child:GetAttribute("BeatMakkaWardrobe") == true then
                child:Destroy()
            end
        end
    end
end

local function basePart(character, name)
    local body = character:FindFirstChild(name)
    return if body and body:IsA("BasePart") then body else nil
end

local function accessory(parent, definition, body)
    local model = Instance.new("Model")
    model.Name = definition.id
    model:SetAttribute("WardrobeItemId", definition.id)
    model:SetAttribute("ArtStatus", "LOCAL_CANDIDATE")
    model.Parent = parent
    local width = math.clamp(body.Size.X, 0.5, 6)
    local height = math.clamp(body.Size.Y, 0.5, 6)
    local depth = math.clamp(body.Size.Z, 0.5, 6)
    local color, trim = definition.color, definition.trim

    local function piece(name, size, offset, tint, material, shape)
        local part = Instance.new("Part")
        part.Name = name
        part.Size = size
        part.Color = tint
        part.Material = material or Enum.Material.SmoothPlastic
        part.Shape = shape or Enum.PartType.Block
        part.Anchored = false
        part.CanCollide = false
        part.CanTouch = false
        part.CanQuery = false
        part.Massless = true
        part.CastShadow = false
        part.TopSurface = Enum.SurfaceType.Smooth
        part.BottomSurface = Enum.SurfaceType.Smooth
        part.CFrame = body.CFrame * offset
        part.Parent = model
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = body
        weld.Part1 = part
        weld.Parent = part
        return part
    end

    if definition.shape == "headphones" then
        local cup = math.clamp(height * 0.48, 0.28, 0.9)
        local thickness = math.clamp(width * 0.10, 0.12, 0.3)
        for _, side in { -1, 1 } do
            local x = side * (width * 0.5 + thickness * 0.5)
            piece("Cushion", Vector3.new(thickness, cup, cup), CFrame.new(x, 0, 0), trim)
            piece(
                "Cup",
                Vector3.new(thickness, cup * 0.82, cup * 0.82),
                CFrame.new(x + side * thickness * 0.7, 0, 0),
                color
            )
            piece(
                "BandSide",
                Vector3.new(thickness * 0.5, height * 0.55, depth * 0.23),
                CFrame.new(x, height * 0.27, 0),
                color
            )
        end
        piece(
            "BandTop",
            Vector3.new(width + thickness * 1.5, thickness * 0.55, depth * 0.23),
            CFrame.new(0, height * 0.55, 0),
            color
        )
    elseif definition.shape == "scarf" then
        local y = height * 0.44
        piece(
            "CollarFront",
            Vector3.new(width * 0.66, height * 0.17, 0.12),
            CFrame.new(0, y, -depth * 0.5 - 0.06),
            color,
            Enum.Material.Fabric
        )
        piece(
            "Fold",
            Vector3.new(width * 0.18, height * 0.53, 0.13),
            CFrame.new(width * 0.17, height * 0.21, -depth * 0.5 - 0.13),
            color,
            Enum.Material.Fabric
        )
        piece(
            "Stitch",
            Vector3.new(width * 0.18, height * 0.04, 0.02),
            CFrame.new(width * 0.17, -height * 0.02, -depth * 0.5 - 0.21),
            trim,
            Enum.Material.Fabric
        )
    elseif definition.shape == "satchel" then
        local bagDepth = math.clamp(depth * 0.4, 0.25, 0.65)
        local z = depth * 0.5 + bagDepth * 0.5
        piece(
            "CanvasBody",
            Vector3.new(width * 0.66, height * 0.65, bagDepth),
            CFrame.new(0, -height * 0.08, z),
            color,
            Enum.Material.Fabric
        )
        piece(
            "Flap",
            Vector3.new(width * 0.68, height * 0.23, 0.1),
            CFrame.new(0, height * 0.11, z + bagDepth * 0.5),
            trim,
            Enum.Material.Fabric
        )
        piece(
            "Clasp",
            Vector3.new(width * 0.09, height * 0.13, 0.05),
            CFrame.new(0, height * 0.04, z + bagDepth * 0.5 + 0.08),
            Theme.Amber,
            Enum.Material.Metal
        )
        for _, side in { -1, 1 } do
            piece(
                "ShoulderStrap",
                Vector3.new(width * 0.065, height * 0.78, 0.08),
                CFrame.new(side * width * 0.26, height * 0.05, -depth * 0.5 - 0.05),
                trim,
                Enum.Material.Fabric
            )
        end
    else
        local edge = math.clamp(width * 0.15, 0.18, 0.42)
        local at = CFrame.new(-width * 0.25, height * 0.22, -depth * 0.5 - 0.09)
        if definition.shape == "record" then
            piece(
                "Record",
                Vector3.new(0.07, edge, edge),
                at * CFrame.Angles(0, math.pi / 2, 0),
                color,
                Enum.Material.Metal,
                Enum.PartType.Cylinder
            )
            piece(
                "RecordLabel",
                Vector3.new(0.02, edge * 0.35, edge * 0.35),
                at * CFrame.new(0, 0, -0.05) * CFrame.Angles(0, math.pi / 2, 0),
                trim,
                Enum.Material.Metal,
                Enum.PartType.Cylinder
            )
        else
            piece("Backing", Vector3.new(edge, edge * 1.15, 0.06), at, trim)
            piece(
                "Face",
                Vector3.new(edge * 0.7, edge * 0.78, 0.03),
                at * CFrame.new(0, 0, -0.05),
                color
            )
            if definition.shape == "lantern" then
                piece(
                    "LanternHandle",
                    Vector3.new(edge * 0.40, edge * 0.20, 0.04),
                    at * CFrame.new(0, edge * 0.68, 0),
                    trim,
                    Enum.Material.Metal
                )
            end
        end
    end
end

function Service.new(profiles, getEntitlements)
    return setmetatable({
        profiles = profiles,
        getEntitlements = getEntitlements or function()
            return {}
        end,
        bindings = {},
        appearances = {},
    }, Service)
end

function Service:refresh(player)
    local profile = self.profiles[player]
    local character = player.Character
    if not profile or not profile.ready or not character then
        return false
    end
    local head = basePart(character, "Head")
    local torso = basePart(character, "UpperTorso") or basePart(character, "Torso")
    if not head or not torso then
        return false
    end
    local look = Identity.summary(profile, self.getEntitlements(player)).equipped
    local ids = {}
    for _, slot in Catalog.Slots do
        table.insert(ids, look[slot] or "-")
    end
    local signature = table.concat(ids, ":")
    local previous = self.appearances[player]
    if
        previous
        and previous.character == character
        and previous.signature == signature
        and previous.folder.Parent == character
    then
        return false
    end
    clearCharacter(character)
    local folder = Instance.new("Folder")
    folder.Name = "BeatMakkaWardrobe"
    folder:SetAttribute("BeatMakkaWardrobe", true)
    folder.Parent = character
    for _, slot in Catalog.Slots do
        local id = look[slot]
        if id then
            accessory(folder, Catalog.Items[id], if slot == "head" then head else torso)
        end
    end
    self.appearances[player] = {
        character = character,
        signature = signature,
        folder = folder,
    }
    return true
end

function Service:bind(player)
    self:remove(player)
    local binding = {}
    self.bindings[player] = binding
    local function refreshCharacter(character)
        task.spawn(function()
            if not character:FindFirstChildOfClass("Humanoid") then
                character:WaitForChild("Humanoid", 10)
            end
            if self.bindings[player] == binding and player.Character == character then
                self.appearances[player] = nil
                self:refresh(player)
            end
        end)
    end
    binding.added = player.CharacterAdded:Connect(refreshCharacter)
    binding.loaded = player.CharacterAppearanceLoaded:Connect(refreshCharacter)
    if player.Character then
        refreshCharacter(player.Character)
    end
end

function Service:remove(player)
    local binding = self.bindings[player]
    if binding then
        for _, connection in binding do
            connection:Disconnect()
        end
    end
    self.bindings[player] = nil
    local appearance = self.appearances[player]
    if appearance then
        clearCharacter(appearance.character)
    end
    self.appearances[player] = nil
end

return Service
