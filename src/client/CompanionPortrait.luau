local textureUri = require(script.Parent.LocalTextureUri)
-- A static local character card. No frame loop, uploaded portraits or retained hidden atlas.
local Storage = game:GetService("ReplicatedStorage")
local Assets = game:GetService("AssetService")
local Catalog = require(Storage.Shared.CompanionCatalog)
local Models = require(Storage.Shared.CompanionModels)
local Theme = require(Storage.Shared.Theme)
local Gui = require(script.Parent.GuiFactory)
local Portrait = {}
Portrait.__index = Portrait
local sources = {}
for _, source in Models do
    sources[source.id] = source
end
function Portrait.new(parent)
    local frame = Gui.round(
        Gui.make("ViewportFrame", parent, {
            Name = "CharacterPortrait",
            Position = UDim2.fromOffset(6, 6),
            Size = UDim2.fromOffset(144, 164),
            BackgroundColor3 = Theme.FadedTeal,
            BorderSizePixel = 0,
            Ambient = Color3.fromRGB(190, 185, 170),
            LightColor = Color3.fromRGB(255, 238, 203),
            LightDirection = Vector3.new(-1, -1, -3),
        }),
        10
    )
    local world = Gui.make("WorldModel", frame, {})
    local camera = Gui.make("Camera", frame, { FieldOfView = 30 })
    frame.CurrentCamera = camera
    return setmetatable({ frame = frame, world = world, camera = camera, generation = 0 }, Portrait)
end
function Portrait:clear()
    self.generation += 1
    self.world:ClearAllChildren()
    if self.image then
        self.image:Destroy()
        self.image = nil
    end
end
function Portrait:set(id, visible)
    local key = if visible and id ~= "none" then id else "none"
    if key == self.selected then
        return
    end
    self.selected = key
    self:clear()
    self.frame.Visible = key ~= "none"
    if key == "none" then
        return
    end
    local definition = Catalog.ById[key]
    local source = definition and sources[definition.asset]
    if not source then
        return
    end
    local generation = self.generation
    task.spawn(function()
        local model, image
        local ok, reason = pcall(function()
            local library = Storage:WaitForChild("CompanionLibrary", 30)
            local template = library and library:WaitForChild(source.id, 30)
            assert(template, "Local character card unavailable")
            model = template:Clone()
            image = Assets:CreateEditableImageAsync(Content.fromUri(textureUri(source.atlas)))
            assert(image, "Character card atlas unavailable")
            for _, part in model:GetDescendants() do
                if part:IsA("BasePart") then
                    part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery =
                        true, false, false, false
                    part.Transparency = 0
                    for _, old in part:GetChildren() do
                        if old:IsA("SurfaceAppearance") then
                            old:Destroy()
                        end
                    end
                    if part:IsA("MeshPart") then
                        part.TextureContent = Content.fromObject(image)
                    end
                end
            end
            if self.dead or generation ~= self.generation then
                model:Destroy()
                image:Destroy()
                return
            end
            self.image = image
            model.Parent = self.world
            local h = definition.height
            local target = Vector3.new(0, h * 0.73, 0)
            self.camera.CFrame = CFrame.lookAt(target + Vector3.new(0.6, 0.05, -5), target)
        end)
        if not ok then
            if model then
                model:Destroy()
            end
            if image then
                image:Destroy()
            end
            if not self.dead and generation == self.generation then
                warn("Companion card: " .. tostring(reason))
            end
        end
    end)
end
function Portrait:destroy()
    self.dead = true
    self:clear()
    self.frame:Destroy()
end
return Portrait
