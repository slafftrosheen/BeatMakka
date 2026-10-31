-- A mirror of the player's currently worn avatar, never an unowned-item preview.
-- Camera-only rotation, no animation loop, and no WorldModel while hidden.
-- Sources checked 2026-10-30:
-- https://create.roblox.com/docs/ui/viewport-frames
-- https://create.roblox.com/docs/reference/engine/classes/WorldModel
-- https://create.roblox.com/docs/reference/engine/classes/Player
local Players = game:GetService("Players")
local Theme = require(game:GetService("ReplicatedStorage").Shared.Theme)
local Gui = require(script.Parent.GuiFactory)
local Preview = {}
Preview.__index = Preview

local MAX_DESCENDANTS = 1000 -- Local preview budget, not a Roblox platform limit.
local DEBOUNCE = 0.15

local function disconnectAll(connections)
    for _, connection in connections do
        connection:Disconnect()
    end
    table.clear(connections)
end

local function visualObject(object)
    return object:IsA("Model")
        or object:IsA("Folder")
        or object:IsA("Accoutrement")
        or object:IsA("BasePart")
        or object:IsA("DataModelMesh")
        or object:IsA("Decal")
        or object:IsA("SurfaceAppearance")
        or object:IsA("Clothing")
        or object:IsA("ShirtGraphic")
        or object:IsA("BodyColors")
        or object:IsA("CharacterMesh")
        or object:IsA("Humanoid")
        or object:IsA("Attachment")
        or object:IsA("WrapLayer")
        or object:IsA("WrapTarget")
        or object:IsA("JointInstance")
        or object:IsA("WeldConstraint")
        or object:IsA("FaceControls")
end

local function appearanceProperties(object)
    if object:IsA("MeshPart") then
        return { "Size", "Color", "Transparency", "Material", "MeshId", "TextureID" }
    elseif object:IsA("BasePart") then
        return { "Size", "Color", "Transparency", "Material" }
    elseif object:IsA("SpecialMesh") then
        return { "MeshId", "TextureId", "Scale", "Offset" }
    elseif object:IsA("Shirt") then
        return { "ShirtTemplate" }
    elseif object:IsA("Pants") then
        return { "PantsTemplate" }
    elseif object:IsA("ShirtGraphic") then
        return { "Graphic" }
    elseif object:IsA("Decal") then
        return { "Texture", "Color3", "Transparency" }
    elseif object:IsA("BodyColors") then
        return {
            "HeadColor3",
            "LeftArmColor3",
            "RightArmColor3",
            "LeftLegColor3",
            "RightLegColor3",
            "TorsoColor3",
        }
    elseif object:IsA("CharacterMesh") then
        return { "BodyPart", "MeshId", "BaseTextureId", "OverlayTextureId" }
    elseif object:IsA("SurfaceAppearance") then
        return { "ColorMap", "NormalMap", "MetalnessMap", "RoughnessMap" }
    end
    return {}
end

local function copyCharacter(character)
    if #character:GetDescendants() > MAX_DESCENDANTS then
        return nil,
            "This avatar is too detailed for the small mirror. Your equipped look is unchanged."
    end
    local originalArchivable = character.Archivable
    local ok, clone = pcall(function()
        character.Archivable = true
        return character:Clone()
    end)
    -- No yield occurs between changing and restoring the source flag.
    character.Archivable = originalArchivable
    if not ok or not clone then
        return nil, "Your avatar is still arriving. Open My style again in a moment."
    end
    clone.Name = "WornAvatarPreview"
    local parts = 0
    for _, object in clone:GetDescendants() do
        if not object:IsDescendantOf(clone) then
            continue
        end
        -- The visual allowlist removes scripts, tools, audio, particles, lights,
        -- interaction objects and UI before the clone receives any parent.
        if object:IsA("Tool") or not visualObject(object) then
            object:Destroy()
        elseif object:IsA("BasePart") then
            object.Anchored = true
            object.CanCollide = false
            object.CanTouch = false
            object.CanQuery = false
            object.CastShadow = false
            object.LocalTransparencyModifier = 0
            parts += 1
        elseif object:IsA("Humanoid") then
            object.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
            object.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
            object.AutoRotate = false
            object.BreakJointsOnDeath = false
        elseif object:IsA("JointInstance") or object:IsA("WeldConstraint") then
            if
                (object.Part0 and not object.Part0:IsDescendantOf(clone))
                or (object.Part1 and not object.Part1:IsDescendantOf(clone))
            then
                object:Destroy()
            end
        end
    end
    if parts == 0 then
        clone:Destroy()
        return nil, "Your avatar is still arriving. Open My style again in a moment."
    end
    clone:PivotTo(CFrame.new())
    return clone
end

function Preview.new(parent)
    local self = setmetatable({
        visible = false,
        destroyed = false,
        yaw = 0,
        generation = 0,
        connections = {},
        characterConnections = {},
        objectConnections = {},
        watchedObjects = 0,
    }, Preview)
    self.root = Gui.make("Frame", parent, {
        Name = "WardrobeMirror",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 272),
        Visible = false,
    })
    self.viewport = Gui.round(
        Gui.make("ViewportFrame", self.root, {
            Name = "YourWornAvatar",
            Size = UDim2.new(1, 0, 0, 220),
            BackgroundColor3 = Theme.Stone,
            BorderSizePixel = 0,
            Ambient = Color3.fromRGB(190, 184, 172),
            LightColor = Color3.fromRGB(245, 234, 212),
            LightDirection = Vector3.new(-1, -1, -2),
        }),
        8
    )
    self.status = Gui.label(self.root, "Your wardrobe mirror", 14, Theme.Ink)
    self.status.Position = UDim2.fromOffset(12, 12)
    self.status.Size = UDim2.new(1, -24, 0, 56)
    self.status.TextYAlignment = Enum.TextYAlignment.Top
    self.status.ZIndex = 2
    self.left = Gui.button(self.root, "Rotate left", function()
        if self.visible and not self.destroyed then
            self.yaw -= math.pi / 6
            self:_frameCamera()
        end
    end)
    self.right = Gui.button(self.root, "Rotate right", function()
        if self.visible and not self.destroyed then
            self.yaw += math.pi / 6
            self:_frameCamera()
        end
    end)
    self.left.Position, self.left.Size = UDim2.fromOffset(0, 228), UDim2.new(0.5, -4, 0, 44)
    self.right.Position, self.right.Size = UDim2.new(0.5, 4, 0, 228), UDim2.new(0.5, -4, 0, 44)
    table.insert(
        self.connections,
        self.viewport:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            self:_frameCamera()
        end)
    )
    local player = Players.LocalPlayer
    table.insert(
        self.connections,
        player.CharacterAdded:Connect(function(character)
            self:_bindCharacter(character)
            self:refresh()
        end)
    )
    table.insert(
        self.connections,
        player.CharacterRemoving:Connect(function(character)
            if self.character == character then
                self:_bindCharacter(nil)
                self:_cancelRefresh()
                self:_clearWorld()
                self.status.Text = "Your avatar is arriving..."
                self.status.Visible = true
            end
        end)
    )
    -- CharacterAppearanceLoaded is server-only. Replicated appearance arrives
    -- through the character descendants/property observers below on this client.
    table.insert(
        self.connections,
        self.root.Destroying:Connect(function()
            self:destroy(true)
        end)
    )
    self:_bindCharacter(player.Character)
    return self
end

function Preview:_watch(object)
    if
        self.objectConnections[object]
        or self.overBudget
        or self.watchedObjects >= MAX_DESCENDANTS
    then
        return
    end
    local connections = {}
    for _, property in appearanceProperties(object) do
        table.insert(
            connections,
            object:GetPropertyChangedSignal(property):Connect(function()
                self:refresh()
            end)
        )
    end
    if #connections > 0 then
        self.objectConnections[object] = connections
        self.watchedObjects += 1
    end
end

function Preview:_bindCharacter(character)
    disconnectAll(self.characterConnections)
    for _, connections in self.objectConnections do
        disconnectAll(connections)
    end
    table.clear(self.objectConnections)
    self.watchedObjects = 0
    self.overBudget = false
    self.character = character
    if not character then
        return
    end
    local descendants = character:GetDescendants()
    self.overBudget = #descendants > MAX_DESCENDANTS
    if not self.overBudget then
        for _, object in descendants do
            self:_watch(object)
        end
    end
    table.insert(
        self.characterConnections,
        character.DescendantAdded:Connect(function(object)
            self:_watch(object)
            if visualObject(object) then
                self:refresh()
            end
        end)
    )
    table.insert(
        self.characterConnections,
        character.DescendantRemoving:Connect(function(object)
            local connections = self.objectConnections[object]
            if connections then
                disconnectAll(connections)
                self.objectConnections[object] = nil
                self.watchedObjects -= 1
            end
            if visualObject(object) then
                self:refresh()
            end
        end)
    )
end

function Preview:_cancelRefresh()
    self.generation += 1
    if self.pending then
        task.cancel(self.pending)
        self.pending = nil
    end
end

function Preview:_clearWorld()
    self.viewport.CurrentCamera = nil
    if self.world then
        self.world:Destroy()
        self.world = nil
    end
    if self.camera then
        self.camera:Destroy()
        self.camera = nil
    end
    self.bounds = nil
end

function Preview:_frameCamera()
    if self.destroyed or not self.visible or not self.camera or not self.bounds then
        return
    end
    local frameSize = self.viewport.AbsoluteSize
    if frameSize.X < 1 or frameSize.Y < 1 then
        return
    end
    -- Viewport cameras do not inherit the gameplay camera's viewport dimensions.
    local halfVertical = math.rad(self.camera.FieldOfView) / 2
    local halfHorizontal = math.atan(math.tan(halfVertical) * frameSize.X / frameSize.Y)
    local radius = math.max(1, self.bounds.size.Magnitude * 0.5)
    local distance = radius / math.sin(math.min(halfVertical, halfHorizontal)) * 1.08
    local target = self.bounds.center
    local position = target + Vector3.new(math.sin(self.yaw), 0, -math.cos(self.yaw)) * distance
    self.camera.CFrame = CFrame.lookAt(position, target)
    self.camera.Focus = CFrame.new(target)
end

function Preview:_rebuild()
    if self.destroyed or not self.visible then
        return
    end
    local character = Players.LocalPlayer.Character
    self:_clearWorld()
    if not character or not character.Parent then
        self.status.Text = "Your avatar is arriving..."
        self.status.Visible = true
        return
    end
    if self.overBudget and #character:GetDescendants() <= MAX_DESCENDANTS then
        self:_bindCharacter(character)
    end
    local clone, message = copyCharacter(character)
    if not clone then
        self.status.Text = message
        self.status.Visible = true
        return
    end
    self.world = Instance.new("WorldModel")
    self.world.Name = "WardrobeMirrorWorld"
    self.world.Parent = self.viewport
    clone.Parent = self.world
    self.camera = Instance.new("Camera")
    self.camera.Name = "WardrobeMirrorCamera"
    self.camera.CameraType = Enum.CameraType.Scriptable
    self.camera.FieldOfView = 35
    self.camera.Parent = self.viewport
    self.viewport.CurrentCamera = self.camera
    local frame, size = clone:GetBoundingBox()
    self.bounds = { center = frame.Position, size = size }
    self.status.Visible = false
    self:_frameCamera()
end

function Preview:refresh()
    if self.destroyed or not self.visible then
        return
    end
    self:_cancelRefresh()
    local generation = self.generation
    self.pending = task.delay(DEBOUNCE, function()
        self.pending = nil
        if self.destroyed or not self.visible or generation ~= self.generation then
            return
        end
        self:_rebuild()
    end)
end

function Preview:setVisible(visible)
    if self.destroyed or self.visible == (visible == true) then
        return
    end
    self.visible = visible == true
    self.root.Visible = self.visible
    if self.visible then
        self.status.Text = "Your wardrobe mirror is loading..."
        self.status.Visible = true
        if self.character ~= Players.LocalPlayer.Character then
            self:_bindCharacter(Players.LocalPlayer.Character)
        end
        self:refresh()
    else
        self:_cancelRefresh()
        self:_clearWorld()
    end
end

function Preview:destroy(fromRoot)
    if self.destroyed then
        return
    end
    self.destroyed = true
    self:_cancelRefresh()
    disconnectAll(self.connections)
    self:_bindCharacter(nil)
    self:_clearWorld()
    if not fromRoot then
        self.root:Destroy()
    end
end

return Preview
