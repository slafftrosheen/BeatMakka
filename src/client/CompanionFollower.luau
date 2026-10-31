local Expression = require(game.ReplicatedStorage.Shared.BeatExpression)
local MusicField = require(script.Parent.QuayMusicField)
local textureUri = require(script.Parent.LocalTextureUri)
local Charm = require(script.Parent.QuayCompanionCharm)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Storage = game:GetService("ReplicatedStorage")
local Assets = game:GetService("AssetService")
local Shared = Storage.Shared
local Catalog = require(Shared.CompanionCatalog)
local Models = require(Shared.CompanionModels)
local Animation = require(script.Parent.CompanionAnimation)
local SuppliedSkin = require(script.Parent.SuppliedCompanionSkin)
local Follower = {}
Follower.__index = Follower
local byId = {}
for _, source in Models do
    byId[source.id] = source
end
local function vector(row)
    return Vector3.new(table.unpack(row))
end
local function blocked(state)
    return not state or not state.ready
end
function Follower.new()
    local self = setmetatable(
        { enabled = true, selected = "none", generation = 0, elapsed = 0, parts = {}, dead = false },
        Follower
    )
    self.raycast = RaycastParams.new()
    self.raycast.FilterType = Enum.RaycastFilterType.Exclude
    self.raycast.RespectCanCollide = true
    self.connection = RunService.RenderStepped:Connect(function(dt)
        self.elapsed += dt
        local step = math.min(self.elapsed, 0.15)
        self.elapsed = 0
        self:step(step)
    end)
    return self
end
function Follower:clear()
    Charm.clear(self)
    self.generation += 1
    if self.skin then
        self.skin:destroy()
        self.skin = nil
    end
    if self.model then
        self.model:Destroy()
        self.model = nil
    end
    if self.image then
        self.image:Destroy()
        self.image = nil
    end
    table.clear(self.parts)
    self.position = nil
    self.followTarget, self.lastPlayerPosition, self.moving = nil, nil, false
    self.root = nil
    self.loading = false
    self.shown = nil
    self.facing = nil
    self.retryAt = 0
    self.skinAttempts, self.skinRetryAt, self.skinLoading = 0, 0, false
    self.pendingPoint, self.pendingReaction = false, false
    self.gesture, self.reactionSerial = nil, nil
end
function Follower:accept(state)
    self.state = state
    self.musicExpression = Expression.fromState(state)
    local selection = state.companion and state.companion.selected or "none"
    if not Catalog.valid(selection) then
        selection = "none"
    end
    if selection ~= self.selected then
        self:clear()
        self.selected = selection
    end
    local companion = state.companion
    if companion then
        if companion.reactionSerial ~= self.reactionSerial then
            local firstSnapshot = self.reactionSerial == nil
            self.reactionSerial = companion.reactionSerial
            self.reaction = companion.reaction
            self.pendingReaction = not firstSnapshot and companion.reaction ~= nil
            self.reactionDeadline = os.clock() + 8
        end
        local hint = companion.hint
        local gesture = hint and (hint.context .. ":" .. hint.level)
        if gesture ~= self.gesture then
            self.gesture = gesture
            self.pendingPoint = hint ~= nil and hint.level > 1
            self.pointUntil = 0
        end
    end
end
function Follower:celebrate(serial)
    if self.selected == "none" then
        return
    end
    self.pendingReaction = true
    self.reaction = if serial % 2 == 0 then "encore" else "achievement"
    self.reactionDeadline = os.clock() + 8
end
function Follower:create()
    if
        self.loading
        or self.model
        or self.selected == "none"
        or os.clock() < (self.retryAt or 0)
    then
        return
    end
    self.loading = true
    local generation = self.generation
    local source = byId[Catalog.ById[self.selected].asset]
    task.spawn(function()
        local model, image, skin
        local ok, reason = pcall(function()
            local library = Storage:WaitForChild("CompanionLibrary", 120)
            local template = library and library:WaitForChild(source.id, 30)
            assert(template, "Local companion model is unavailable")
            model = template:Clone()
            model.Name = "LocalCompanion_" .. Players.LocalPlayer.UserId
            -- A failed atlas must not remove the companion's geometry and animation.
            local surface
            local textured, textureFailure = pcall(function()
                image = Assets:CreateEditableImageAsync(Content.fromUri(textureUri(source.atlas)))
                assert(image, "Local companion atlas memory unavailable")
                surface = Content.fromObject(image)
            end)
            if not textured then
                surface = Content.none
                model:SetAttribute("LocalTextureError", tostring(textureFailure))
                warn("Companion texture fallback: " .. tostring(textureFailure))
            end
            local parts = {}
            local pbr = require(script.Parent.LocalMaterials).fromContent(surface)
            for _, part in model:GetDescendants() do
                if part:IsA("BasePart") then
                    part.Anchored = true
                    part.CanCollide = false
                    part.CanTouch = false
                    part.CanQuery = false
                    part.Transparency = 1
                    part.CastShadow = true
                    for _, old in part:GetChildren() do
                        if old:IsA("SurfaceAppearance") then
                            old:Destroy()
                        end
                    end
                    if part:IsA("MeshPart") then
                        part.TextureContent = surface
                        if pbr then
                            pbr:Clone().Parent = part
                            part:SetAttribute("LocalPBRBound", true)
                        end
                    end
                    table.insert(parts, {
                        part = part,
                        bone = part:GetAttribute("RigidBone"),
                        center = part.Position,
                    })
                end
            end
            if pbr then
                pbr:Destroy()
            end
            if source.suppliedSkin then
                local failure
                skin, failure = SuppliedSkin.new(source, model, surface, function()
                    return self.dead or generation ~= self.generation
                end)
                if not skin and not self.dead and generation == self.generation then
                    self.skinAttempts, self.skinRetryAt = 1, os.clock() + 5
                    warn("Supplied companion skin: " .. tostring(failure))
                end
            end
            if self.dead or generation ~= self.generation then
                model:Destroy()
                if image then
                    image:Destroy()
                end
                return
            end
            self.model, self.image, self.parts, self.source, self.skin =
                model, image, parts, source, skin
            self.status = "LOCAL_DCC_CANDIDATE"
            model:SetAttribute("OwnerUserId", Players.LocalPlayer.UserId)
            model.Parent = workspace
        end)
        if not ok then
            if skin then
                skin:destroy()
            end
            if model then
                model:Destroy()
            end
            if image then
                image:Destroy()
            end
            if not self.dead and generation == self.generation then
                self.status = "MODEL_UNAVAILABLE"
                self.retryAt = os.clock() + 30
                warn("Companion model: " .. tostring(reason))
            end
        end
        if generation == self.generation then
            self.loading = false
        end
    end)
end
function Follower:visible(value)
    if self.shown == value then
        return
    end
    self.shown = value
    if self.charm then
        self.charm.Transparency = if value then 0 else 1
        self.charm.BillboardGui.Enabled = value
    end
    for _, entry in self.parts do
        entry.part.Transparency = if value and not self.skin then 0 else 1
    end
    if self.skin then
        for _, entry in self.skin.entries do
            entry.part.Transparency = if value then 0 else 1
        end
    end
end
function Follower:retrySkin()
    if
        self.skin
        or self.skinLoading
        or not self.source.suppliedSkin
        or (self.skinAttempts or 0) >= 3
        or os.clock() < (self.skinRetryAt or 0)
    then
        return
    end
    local surface = self.parts[1] and self.parts[1].part.TextureContent
    if not surface then
        return
    end
    local generation = self.generation
    self.skinLoading = true
    self.skinAttempts = (self.skinAttempts or 0) + 1
    task.spawn(function()
        local skin, reason = SuppliedSkin.new(self.source, self.model, surface, function()
            return self.dead or generation ~= self.generation
        end)
        if self.dead or generation ~= self.generation then
            if skin then
                skin:destroy()
            end
            return
        end
        self.skinLoading = false
        if skin then
            self.skin = skin
            self.shown = nil
            self:visible(self.position ~= nil)
        else
            self.skinRetryAt = os.clock() + 8
            warn("Companion skin recovery: " .. tostring(reason))
        end
    end)
end
function Follower:step(dt)
    if self.dead or self.selected == "none" then
        return
    end
    local character = Players.LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if
        blocked(self.state)
        or not root
        or not humanoid
        or humanoid.Health <= 0
        or not workspace:FindFirstChild("NeedleQuay")
    then
        self:visible(false)
        self.position = nil
        return
    end
    self:create()
    if not self.model then
        return
    end
    self:retrySkin()
    if self.root ~= root then
        self.root = root
        self.position = nil
        self.raycast.FilterDescendantsInstances = { character, self.model }
    end
    local desired = root.Position - root.CFrame.RightVector * 3 - root.CFrame.LookVector * 3.5
    -- Turning in place must not send the companion orbiting around the player.
    if
        self.followTarget
        and self.lastPlayerPosition
        and (root.Position - self.lastPlayerPosition).Magnitude < 0.15
    then
        desired = self.followTarget
    else
        self.followTarget, self.lastPlayerPosition = desired, root.Position
    end
    local params = self.raycast
    local wall = workspace:Raycast(root.Position, (desired - root.Position), params)
    if wall then
        desired = root.Position + root.CFrame.RightVector * 3 - root.CFrame.LookVector * 2
    end
    local ground = workspace:Raycast(
        Vector3.new(desired.X, root.Position.Y + 2, desired.Z),
        Vector3.new(0, -16, 0),
        params
    )
    local groundActor = ground and ground.Instance:FindFirstAncestorOfClass("Model")
    if
        not ground
        or ground.Normal.Y < 0.5
        or math.abs(ground.Position.Y - root.Position.Y) > 5
        or ground.Position.Y > root.Position.Y - 0.5
        or (groundActor and groundActor:FindFirstChildOfClass("Humanoid"))
    then
        self:visible(false)
        self.position = nil
        return
    end
    desired = Vector3.new(desired.X, ground.Position.Y + 0.04, desired.Z)
    local previous = self.position
    if not previous or (previous - desired).Magnitude > 18 then
        self.position = desired
    else
        self.position = previous:Lerp(desired, 1 - math.exp(-dt * 7))
    end
    self:visible(true)
    local delta = if previous then self.position - previous else Vector3.zero
    local speed = Vector3.new(delta.X, 0, delta.Z).Magnitude / dt
    self.moving = if self.moving then speed > 0.3 else speed > 1.0
    local direction = if speed > 0.4
        then Vector3.new(delta.X, 0, delta.Z)
        else Vector3.new(
            root.Position.X - self.position.X,
            0,
            root.Position.Z - self.position.Z
        )
    local music = (
        if self.state.jam and self.state.jam.active
            then Expression.fromState(self.state)
            else self.musicExpression
    ) or MusicField.nearest(root.Position, 48)
    local change = Expression.change(self.lastHeardMusic, music)
    if change and os.clock() > (self.nextMusicReaction or 0) and not self.pendingReaction then
        self.pendingReaction, self.reaction = true, "music_" .. change
        self.reactionDeadline, self.nextMusicReaction = os.clock() + 3, os.clock() + 7
        self.model:SetAttribute("MusicReaction", change)
    end
    self.lastHeardMusic = music
    local musical = music
        and music.active ~= false
        and workspace:GetServerTimeNow() >= music.startedAt
    local companion = self.state.companion
    -- Start short gestures after closing the journal, so reading doesn't consume them.
    if self.pendingReaction and os.clock() > (self.reactionDeadline or 0) then
        self.pendingReaction = false
    end
    if self.enabled and self.pendingReaction and speed < 0.4 then
        self.pendingReaction = false
        self.reactionClip = if self.reaction == "saved"
                or self.reaction == "restore"
                or self.reaction == "encore"
            then "clap"
            else "cheer"
        if self.reaction and self.reaction:sub(1, 6) == "music_" then
            self.reactionClip = if self.reaction == "music_space"
                    or self.reaction == "music_warm"
                then (if self.selected == "alissia" then "agree" else "bow")
                else "clap"
        end
        -- Prefer a full readable clap to an overhead gesture outside this mesh's range.
        local gains = self.skin and self.skin.source.motionGains
        if self.reactionClip == "cheer" and gains and (gains.cheer or 1) < 0.4 then
            self.reactionClip = "clap"
        end
        local sourceClip = self.skin and self.skin.clips[self.reactionClip]
        local duration = if sourceClip then sourceClip.duration else 3
        if self.reaction and self.reaction:sub(1, 6) == "music_" then
            duration = math.min(duration, 2.5)
        end
        self.reactionUntil = os.clock() + duration
        if self.skin then
            self.skin.clip = nil
        end
    end
    if self.enabled and self.pendingPoint then
        self.pendingPoint, self.pointUntil = false, os.clock() + 3
    end
    self.running = self.moving and (if self.running then speed > 10 else speed > 14)
    local clip = if self.running
        then "run"
        elseif self.moving then "walk"
        elseif self.selected == "alissia" then "idle_listen"
        else "idle"
    if self.enabled then
        if speed < 0.4 and os.clock() < (self.reactionUntil or 0) and self.reaction then
            clip = self.reactionClip or "cheer"
        elseif speed < 0.4 and musical then
            clip = if self.selected == "alissia" then "dance_03" else "dance_06"
            local gains = self.skin and self.skin.source.motionGains
            if gains and (gains[clip] or 1) < 0.45 then
                clip = "dance_06"
            end
        elseif
            speed < 0.4
            and os.clock() < (self.pointUntil or 0)
            and companion
            and typeof(companion.target) == "Vector3"
        then
            clip = "point"
            direction = Vector3.new(
                companion.target.X - self.position.X,
                0,
                companion.target.Z - self.position.Z
            )
        end
    end
    if direction.Magnitude < 0.001 then
        direction = Vector3.new(0, 0, -1)
    end
    local facing = CFrame.lookAt(self.position, self.position + direction)
    self.facing = if not self.facing or not previous
        then facing
        else CFrame.new(self.position) * self.facing.Rotation:Lerp(
            facing.Rotation,
            1 - math.exp(-dt * 9)
        )
    Charm.update(self)
    if self.skin then
        self.skin:pose(
            self.facing,
            clip,
            dt,
            true,
            self.enabled,
            speed,
            if musical then music else nil
        )
        self.model:SetAttribute("MusicStyle", if musical then music.style else nil)
        self.model:SetAttribute("MusicIntensity", if musical then music.intensity else nil)
        self.model:SetAttribute(
            "MusicBeat",
            if musical then Expression.phase(music, workspace:GetServerTimeNow()) else nil
        )
        self.model:SetAttribute("PresentationClip", clip)
        self.model:SetAttribute("SuppliedSkinReady", true)
        return
    end
    local posed = {}
    local function pose(name)
        if posed[name] then
            return posed[name]
        end
        local joint = vector(self.source.joints[name])
        local parent = self.source.parents[name]
        local rotation = if self.enabled
            then Animation.rotation(name, clip, os.clock())
            else CFrame.identity
        posed[name] = if parent
            then pose(parent) * CFrame.new(joint - vector(self.source.joints[parent])) * rotation
            else CFrame.new(joint) * rotation
        return posed[name]
    end
    for _, entry in self.parts do
        entry.part.CFrame = self.facing
            * pose(entry.bone)
            * CFrame.new(entry.center - vector(self.source.joints[entry.bone]))
    end
    self.model:SetAttribute("PresentationClip", clip)
end
function Follower:destroy()
    self.dead = true
    self.connection:Disconnect()
    self:clear()
end
return Follower
