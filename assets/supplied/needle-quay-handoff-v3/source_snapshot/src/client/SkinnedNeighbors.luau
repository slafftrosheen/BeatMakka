-- Local continuous character surfaces, using the preserved Blender skin weights.
local Assets = game:GetService("AssetService")
local Storage = game:GetService("ReplicatedStorage")
local Catalog = require(Storage.Shared.LocalMeshCatalog)
local Skins = {}
Skins.__index = Skins
local function vector(row)
    return Vector3.new(table.unpack(row))
end
local function key(v)
    return string.format(
        "%d:%d:%d",
        math.floor(v.X * 1000 + 0.5),
        math.floor(v.Y * 1000 + 0.5),
        math.floor(v.Z * 1000 + 0.5)
    )
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
                local editable, part, imported
                local ok, failure = pcall(function()
                    local skin = source.skin
                    imported = Assets:CreateEditableMeshAsync(Content.fromUri(skin.uri))
                    editable = Assets:CreateEditableMesh()
                    assert(editable, "Local character mesh memory exhausted")
                    -- Imported local files are fixed-size even with FixedSize=false.
                    -- Copy exact attributes into a mutable mesh before adding skin bones.
                    local vertices, uvs, normals = {}, {}, {}
                    local uniquePositions, uniqueUvs, uniqueNormals = {}, {}, {}
                    for _, id in imported:GetVertices() do
                        local value = imported:GetPosition(id)
                        local lookup = string.format("%.7g:%.7g:%.7g", value.X, value.Y, value.Z)
                        uniquePositions[lookup] = uniquePositions[lookup]
                            or editable:AddVertex(value)
                        vertices[id] = uniquePositions[lookup]
                    end
                    for _, id in imported:GetUVs() do
                        local value = imported:GetUV(id)
                        local lookup = string.format("%.7g:%.7g", value.X, value.Y)
                        uniqueUvs[lookup] = uniqueUvs[lookup] or editable:AddUV(value)
                        uvs[id] = uniqueUvs[lookup]
                    end
                    for _, id in imported:GetNormals() do
                        local value = imported:GetNormal(id)
                        local lookup = string.format("%.7g:%.7g:%.7g", value.X, value.Y, value.Z)
                        uniqueNormals[lookup] = uniqueNormals[lookup] or editable:AddNormal(value)
                        normals[id] = uniqueNormals[lookup]
                    end
                    for i, face in imported:GetFaces() do
                        local original = imported:GetFaceVertices(face)
                        local added = editable:AddTriangle(
                            vertices[original[1]],
                            vertices[original[2]],
                            vertices[original[3]]
                        )
                        for _, vertex in original do
                            editable:SetVertexFaceUV(
                                vertices[vertex],
                                added,
                                uvs[imported:GetVertexFaceUV(vertex, face)]
                            )
                            editable:SetVertexFaceNormal(
                                vertices[vertex],
                                added,
                                normals[imported:GetVertexFaceNormal(vertex, face)]
                            )
                        end
                        if i % 500 == 0 then
                            task.wait()
                        end
                    end
                    imported:Destroy()
                    imported = nil
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
                    local weights = {}
                    for _, row in skin.weights do
                        weights[key(vector(row[1]))] = row[2]
                    end
                    for i, vertex in editable:GetVertices() do
                        local position = editable:GetPosition(vertex)
                        local row = weights[key(position)]
                        if not row then
                            local closest, distance
                            for _, candidate in skin.weights do
                                local delta = (vector(candidate[1]) - position).Magnitude
                                if not distance or delta < distance then
                                    closest, distance = candidate[2], delta
                                end
                            end
                            assert(
                                distance and distance < 0.002,
                                "Local character weight position mismatch"
                            )
                            row = closest
                        end
                        local ids, values = {}, {}
                        for _, weight in row do
                            table.insert(ids, boneIds[weight[1]])
                            table.insert(values, weight[2])
                        end
                        editable:SetVertexBones(vertex, ids)
                        editable:SetVertexBoneWeights(vertex, values)
                        if i % 500 == 0 then
                            task.wait()
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
                    part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch =
                        true, false, false, false
                    part.Size = vector(skin.size)
                    part.CFrame = actor:GetPivot() * CFrame.new(center)
                    part.Color = Color3.new(1, 1, 1)
                    part:SetAttribute("SkinCenter", center)
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
                        local bone = Instance.new("Bone")
                        bone.Name = name
                        local at = vector(source.joints[name])
                        bone.CFrame = CFrame.new(
                            at
                                - (
                                    if parent:IsA("Bone")
                                        then vector(source.joints[parentName])
                                        else center
                                )
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
