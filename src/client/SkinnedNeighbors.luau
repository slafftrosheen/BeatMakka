local WeightLookup = require(script.Parent.SkinWeightLookup)
local MeshQueue = require(script.Parent.LocalMeshQueue)
local MutableMesh = require(script.Parent.LocalMutableMesh)
-- Local continuous character surfaces, using the preserved Blender skin weights.
local Assets = game:GetService("AssetService")
local Storage = game:GetService("ReplicatedStorage")
local Catalog = require(Storage.Shared.LocalMeshCatalog)
local ResidentStyle = require(Storage.Shared.QuayResidentStyle)
local Skins = {}
Skins.__index = Skins
local function vector(row)
    return Vector3.new(table.unpack(row))
end

function Skins.new()
    local self = setmetatable({ entries = {}, dead = false }, Skins)
    task.spawn(function()
        local actors = workspace
            :WaitForChild("NeedleQuay")
            :WaitForChild("DemoDistrict")
            :WaitForChild("Neighbors")
        local sources = {}
        for _, asset in Catalog do
            if asset.skin then
                sources[asset.id] = asset
            end
        end
        for _, actor in actors:GetChildren() do
            local source = sources[actor:GetAttribute("LocalCharacterId")]
            if source and not self.dead then
                local release = MeshQueue.acquire(function()
                    return self.dead
                end)
                if not release then
                    break
                end
                local editable, part, imported
                local ok, failure = pcall(function()
                    local skin = source.skin
                    editable = MutableMesh(skin.uri, function()
                        return self.dead
                    end)
                    local center, boneIds = vector(skin.center), {}
                    local function addBone(name)
                        if boneIds[name] then
                            return boneIds[name]
                        end
                        local parent = skin.parents[name]
                        local properties = {
                            Name = name,
                            CFrame = CFrame.new(vector(source.joints[name]) - center),
                            Virtual = false,
                        }
                        if type(parent) == "string" then
                            properties.ParentId = addBone(parent)
                        end
                        boneIds[name] = editable:AddBone(properties)
                        return boneIds[name]
                    end
                    for name in source.joints do
                        addBone(name)
                    end
                    local lookup = WeightLookup.new(skin.weights)
                    local maxMatchError = 0
                    local vertexColors, colorIds = {}, {}
                    for i, vertex in editable:GetVertices() do
                        local row, matchError = lookup(editable:GetPosition(vertex))
                        maxMatchError = math.max(maxMatchError, matchError)
                        local ids, values = {}, {}
                        for _, weight in row do
                            table.insert(ids, boneIds[weight[1]])
                            table.insert(values, weight[2])
                        end
                        editable:SetVertexBones(vertex, ids)
                        editable:SetVertexBoneWeights(vertex, values)
                        if actor:GetAttribute("GenericResident") then
                            local tint = ResidentStyle.vertexColor(
                                actor,
                                row,
                                editable:GetPosition(vertex).Y + center.Y
                            )
                            local key = tint:ToHex()
                            colorIds[key] = colorIds[key] or editable:AddColor(tint, 1)
                            vertexColors[vertex] = colorIds[key]
                        end
                        if i % 500 == 0 then
                            task.wait()
                        end
                    end
                    if actor:GetAttribute("GenericResident") then
                        for i, face in editable:GetFaces() do
                            local colors = {}
                            for _, vertex in editable:GetFaceVertices(face) do
                                table.insert(colors, vertexColors[vertex])
                            end
                            editable:SetFaceColors(face, colors)
                            if i % 1000 == 0 then
                                task.wait()
                            end
                        end
                    end
                    -- Mutable meshes reserve maximum topology capacity. Freeze a compact
                    -- copy after weights are authored so every resident can fit in memory.
                    local status, content =
                        Assets:CreateDataModelContentAsync(Content.fromObject(editable))
                    assert(
                        status == Enum.CreateContentResult.Success,
                        "Local character content serialization failed"
                    )
                    editable:Destroy()
                    editable = nil
                    -- Ephemeral content belongs only to this local DataModel; this is not an asset upload.
                    part = Assets:CreateMeshPartAsync(content)
                    part.Name = "LocalSkinnedBody"
                    part:SetAttribute("WeightMatchError", maxMatchError)
                    part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch =
                        true, false, false, false
                    local scale = actor:GetScale()
                    part.Size = vector(skin.size) * scale
                    part.CFrame = actor:GetPivot() * CFrame.new(center * scale)
                    part.Color = Color3.new(1, 1, 1)
                    part:SetAttribute("SkinCenter", center * scale)
                    part:SetAttribute("AuthoredScale", scale)
                    for action, gain in skin.motionGains or {} do
                        part:SetAttribute("Motion_" .. action, gain)
                    end
                    part:SetAttribute("WeightRevision", skin.weightRevision)
                    part:SetAttribute(
                        "LocalMaterialKey",
                        "character_" .. source.id:match("NQ%-NPC%-(.+)"):lower()
                    )
                    local bones = {}
                    local function instanceBone(name)
                        if bones[name] then
                            return bones[name]
                        end
                        local parentName = skin.parents[name]
                        local parent = if type(parentName) == "string"
                            then instanceBone(parentName)
                            else part
                        local bone = part:FindFirstChild(name, true) or Instance.new("Bone")
                        bone.Name = name
                        local at = vector(source.joints[name])
                        bone.CFrame = CFrame.new(
                            (
                                at
                                - (
                                    if parent:IsA("Bone")
                                        then vector(source.joints[parentName])
                                        else center
                                )
                            ) * scale
                        )
                        bone.Parent = parent
                        bones[name] = bone
                        return bone
                    end
                    for name in source.joints do
                        instanceBone(name)
                    end
                    if self.dead then
                        error("Character appearance disposed")
                    end
                    -- Keep the durable file meshes available as a fallback; only hide after success.
                    local hidden = {}
                    for _, old in actor:GetDescendants() do
                        if old:IsA("MeshPart") then
                            old.LocalTransparencyModifier = 1
                            table.insert(hidden, old)
                        end
                    end
                    part.Parent = actor
                    actor:SetAttribute("LocalSkinnedReady", true)
                    table.insert(
                        self.entries,
                        { actor = actor, part = part, editable = editable, hidden = hidden }
                    )
                end)
                release()
                if not ok then
                    if imported then
                        imported:Destroy()
                    end
                    if part then
                        part:Destroy()
                    end
                    if editable then
                        editable:Destroy()
                    end
                    actor:SetAttribute("LocalSkinError", tostring(failure))
                    warn("Local character skin: " .. tostring(failure))
                end
            end
        end
        Storage:SetAttribute("LocalSkinsBuilt", true)
    end)
    return self
end
function Skins:destroy()
    self.dead = true
    for _, entry in self.entries do
        entry.actor:SetAttribute("LocalSkinnedReady", nil)
        for _, part in entry.hidden do
            if part.Parent then
                part.LocalTransparencyModifier = 0
            end
        end
        entry.part:Destroy()
        if entry.editable then
            entry.editable:Destroy()
        end
    end
end
return Skins
