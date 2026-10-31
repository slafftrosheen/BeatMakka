local WeightLookup = require(script.Parent.SkinWeightLookup)
-- Local continuous skins and sampled clips from user-supplied GLBs; no asset uploads.
local Assets = game:GetService("AssetService")
local Shared = game:GetService("ReplicatedStorage").Shared
local MeshQueue = require(script.Parent.LocalMeshQueue)
local MutableMesh = require(script.Parent.LocalMutableMesh)
local Skin = {}
Skin.__index = Skin
local function vector(row)
    return Vector3.new(table.unpack(row))
end
local function frame(row)
    return CFrame.new(table.unpack(row))
end

function Skin.new(source, model, surface, cancelled)
    local self = setmetatable({ entries = {}, clips = {}, source = source.suppliedSkin }, Skin)
    local release = MeshQueue.acquire(cancelled)
    if not release then
        return nil, "Companion construction cancelled"
    end
    local imported, editable, pending
    local ok, failure = pcall(function()
        local pbr = require(script.Parent.LocalMaterials).fromContent(surface)
        self.pbr = pbr
        for _, chunk in source.suppliedSkin.parts do
            if cancelled() then
                error("Companion changed during skin creation")
            end
            editable = MutableMesh(chunk.uri, cancelled)
            local center, ids, rest = vector(chunk.center), {}, source.suppliedSkin.rest
            local function addBone(name)
                if ids[name] then
                    return ids[name]
                end
                local parent = source.suppliedSkin.parents[name]
                local props = {
                    Name = name,
                    CFrame = CFrame.new(-center) * frame(rest[name]),
                    Virtual = false,
                }
                if type(parent) == "string" then
                    props.ParentId = addBone(parent)
                end
                ids[name] = editable:AddBone(props)
                return ids[name]
            end
            for _, name in source.suppliedSkin.order do
                addBone(name)
            end
            local lookup = WeightLookup.new(chunk.weights)
            local maxMatchError = 0
            for index, vertex in editable:GetVertices() do
                local row, matchError = lookup(editable:GetPosition(vertex))
                maxMatchError = math.max(maxMatchError, matchError)
                local boneIds, values = {}, {}
                for _, weight in row do
                    table.insert(boneIds, ids[weight[1]])
                    table.insert(values, weight[2])
                end
                editable:SetVertexBones(vertex, boneIds)
                editable:SetVertexBoneWeights(vertex, values)
                if index % 500 == 0 then
                    task.wait()
                end
            end
            local status, content = Assets:CreateDataModelContentAsync(Content.fromObject(editable))
            assert(
                status == Enum.CreateContentResult.Success,
                "Companion skin serialization failed"
            )
            editable:Destroy()
            editable = nil
            pending = Assets:CreateMeshPartAsync(content)
            pending.Name = "SuppliedSkin_" .. chunk.name
            pending:SetAttribute("WeightMatchError", maxMatchError)
            pending.Anchored, pending.CanCollide, pending.CanTouch, pending.CanQuery =
                true, false, false, false
            pending.Size = vector(chunk.size)
            pending.CFrame = CFrame.new(center)
            pending.Transparency = 1
            pending.TextureContent = surface
            if pbr then
                pbr:Clone().Parent = pending
                pending:SetAttribute("LocalPBRBound", true)
            end
            local bones = {}
            local function instanceBone(name)
                if bones[name] then
                    return bones[name]
                end
                local parentName = source.suppliedSkin.parents[name]
                local parent = if type(parentName) == "string"
                    then instanceBone(parentName)
                    else pending
                -- CreateMeshPartAsync may already provide the authored bone hierarchy.
                local existing = pending:FindFirstChild(name, true)
                local bone = if existing and existing:IsA("Bone")
                    then existing
                    else Instance.new("Bone")
                bone.Name = name
                bone.CFrame = if type(parentName) == "string"
                    then frame(rest[parentName]):Inverse() * frame(rest[name])
                    else CFrame.new(-center) * frame(rest[name])
                bone.Parent = parent
                bones[name] = bone
                return bone
            end
            for _, name in source.suppliedSkin.order do
                instanceBone(name)
            end
            if cancelled() then
                error("Companion changed during skin creation")
            end
            pending.Parent = model
            table.insert(self.entries, { part = pending, bones = bones, center = center })
            pending = nil
        end
        for name, module in source.suppliedSkin.clips do
            self.clips[name] = require(Shared:FindFirstChild(module))
        end
    end)
    release()
    if not ok then
        if imported then
            imported:Destroy()
        end
        if editable then
            editable:Destroy()
        end
        if pending then
            pending:Destroy()
        end
        self:destroy()
        return nil, failure
    end
    return self
end
function Skin:pose(origin, requested, dt, visible, animated, speed, music)
    local name = if requested == "celebrate" or requested == "wave"
        then "cheer"
        elseif requested == "music_bob" then "dance_03"
        elseif requested == "point" or requested == "think" then "idle"
        elseif self.clips[requested] then requested
        else "idle"
    local clip = self.clips[name] or self.clips.idle
    if not animated then
        name = "idle"
        clip = self.clips.idle
    end
    if self.clip ~= name then
        self.blendFrom, self.blendTime = self.poseFrames, 0
        self.clip, self.time = name, 0
    end
    local rate = if name == "walk"
        then math.clamp((speed or 5) / 5, 0.5, 1.6)
        elseif name == "run" then math.clamp((speed or 14) / 14, 0.7, 1.5)
        else 1
    self.time = (self.time or 0) + dt * rate
    local dancing = music and name:sub(1, 5) == "dance"
    if dancing and clip then
        local beats = require(Shared.BeatExpression).phase(music, workspace:GetServerTimeNow())
        self.time = (beats % 4) / 4 * clip.duration
        local energy = music.intensity or 0.5
        local lift = if music.style == "grit"
            then math.max(0, math.sin(beats * math.pi * 2)) * 0.035 * energy
            else 0
        local sway = if music.style == "space" then math.sin(beats * math.pi) * 0.05 * energy else 0
        origin *= CFrame.new(sway, lift, 0)
    end
    local progress = if clip
        then ((if clip.loop == false
            then math.min(self.time, clip.duration)
            else self.time % clip.duration) / clip.duration) * (#clip.samples - 1)
        else 0
    local index = math.floor(progress) + 1
    -- Sample once for all mesh chunks: seams always receive the identical pose.
    -- Crossfade only at clip boundaries; continual smoothing delays foot plants.
    local gain = (self.source.motionGains and self.source.motionGains[name]) or 1
    if dancing then
        gain *= 0.45 + 0.55 * (music.intensity or 0.5)
    end
    local poses = {}
    self.blendTime = (self.blendTime or 0) + dt
    local alpha = math.clamp(self.blendTime / 0.2, 0, 1)
    alpha = alpha * alpha * (3 - 2 * alpha)
    if clip then
        local a, b = clip.samples[index], clip.samples[math.min(index + 1, #clip.samples)]
        for i, boneName in self.source.order do
            local desired = if animated
                then frame(a[i]):Lerp(frame(b[i]), progress % 1)
                else frame(clip.samples[1][i])
            local neutral = frame(self.clips.idle.samples[1][i])
            desired = neutral:Lerp(desired, gain)
            local previous = self.blendFrom and self.blendFrom[boneName]
            poses[boneName] = if previous and alpha < 1
                then previous:Lerp(desired, alpha)
                else desired
        end
    end
    self.poseFrames = poses
    if alpha >= 1 then
        self.blendFrom = nil
    end
    for _, entry in self.entries do
        entry.part:SetAttribute("WeightRevision", self.source.weightRevision)
        entry.part:SetAttribute("MotionGain", gain)
        entry.part.CFrame = origin * CFrame.new(entry.center)
        entry.part.Transparency = if visible then 0 else 1
        for boneName, transform in poses do
            entry.bones[boneName].Transform = transform
        end
    end
end
function Skin:destroy()
    for _, entry in self.entries do
        entry.part:Destroy()
    end
    table.clear(self.entries)
    if self.pbr then
        self.pbr:Destroy()
        self.pbr = nil
    end
end
return Skin
