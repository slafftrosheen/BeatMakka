-- Local two-triangle surfaces give tiled paving the same PBR maps as meshes.
-- Existing parts keep collision; UV density follows the authored Texture scale.
local Assets = game:GetService("AssetService")
local MeshQueue = require(script.Parent.LocalMeshQueue)
local Planes = {}
Planes.__index = Planes

function Planes.new(materials)
    local self =
        setmetatable({ cache = {}, bound = {}, pending = {}, seen = {}, dead = false }, Planes)
    local function bind(texture)
        local parent = texture.Parent
        local key = texture:GetAttribute("LocalMaterialKey")
        if not parent or not parent:IsA("BasePart") or not materials.surface(key) then
            return
        end
        local w, d = parent.Size.X, parent.Size.Z
        local u, v = w / texture.StudsPerTileU, d / texture.StudsPerTileV
        local cacheKey = string.format("%.4f:%.4f:%.4f:%.4f", w, d, u, v)
        local cached = self.cache[cacheKey]
        if not cached then
            local mesh = Assets:CreateEditableMesh()
            assert(mesh, "Local paving mesh memory unavailable")
            local points = {
                Vector3.new(-w / 2, 0, -d / 2),
                Vector3.new(-w / 2, 0, d / 2),
                Vector3.new(w / 2, 0, d / 2),
                Vector3.new(w / 2, 0, -d / 2),
            }
            local coords = { Vector2.zero, Vector2.new(0, v), Vector2.new(u, v), Vector2.new(u, 0) }
            local vertices, uvs = {}, {}
            for index, point in points do
                vertices[index] = mesh:AddVertex(point)
                uvs[index] = mesh:AddUV(coords[index])
            end
            local normal = mesh:AddNormal(Vector3.yAxis)
            for _, corners in { { 1, 2, 3 }, { 1, 3, 4 } } do
                local face = mesh:AddTriangle(
                    vertices[corners[1]],
                    vertices[corners[2]],
                    vertices[corners[3]]
                )
                mesh:SetFaceUVs(face, { uvs[corners[1]], uvs[corners[2]], uvs[corners[3]] })
                mesh:SetFaceNormals(face, { normal, normal, normal })
            end
            local ok, template = pcall(function()
                -- Release mutable capacity before displaying this static plane.
                local status, content = Assets:CreateDataModelContentAsync(Content.fromObject(mesh))
                assert(
                    status == Enum.CreateContentResult.Success,
                    "Local paving serialization failed"
                )
                mesh:Destroy()
                mesh = nil
                return Assets:CreateMeshPartAsync(
                    content,
                    { CollisionFidelity = Enum.CollisionFidelity.Box }
                )
            end)
            if not ok then
                if mesh then
                    mesh:Destroy()
                end
                error(template)
            end
            cached = { template = template }
            self.cache[cacheKey] = cached
        end
        if self.dead or not parent.Parent then
            return
        end
        local plane = cached.template:Clone()
        plane.Name, plane.Anchored = "LocalPBRSurface", true
        plane.CanCollide, plane.CanTouch, plane.CanQuery, plane.CastShadow =
            false, false, false, false
        plane.Color = texture.Color3
        plane.CFrame = parent.CFrame * CFrame.new(0, parent.Size.Y / 2 + 0.014, 0)
        plane:SetAttribute("LocalMaterialKey", key)
        materials.bind(plane, key)
        plane.Parent = parent
        self.bound[texture] = { plane = plane, transparency = texture.Transparency }
        texture.Transparency = 1
        game.ReplicatedStorage:SetAttribute(
            "LocalPBRPlaneCount",
            (game.ReplicatedStorage:GetAttribute("LocalPBRPlaneCount") or 0) + 1
        )
    end
    local function enqueue(texture)
        if
            self.dead
            or not texture:IsA("Texture")
            or texture.Name ~= "AuthoredSurface"
            or texture.Face ~= Enum.NormalId.Top
            or self.seen[texture]
        then
            return
        end
        self.seen[texture] = true
        table.insert(self.pending, texture)
        if self.running then
            return
        end
        self.running = true
        task.spawn(function()
            while not self.dead and #self.pending > 0 do
                local release = MeshQueue.acquire(function()
                    return self.dead
                end)
                if not release then
                    break
                end
                local ok, reason = pcall(bind, table.remove(self.pending, 1))
                release()
                if not ok then
                    game.ReplicatedStorage:SetAttribute(
                        "LocalPBRPlaneFailures",
                        (game.ReplicatedStorage:GetAttribute("LocalPBRPlaneFailures") or 0) + 1
                    )
                    warn("Local PBR paving: " .. tostring(reason))
                end
                task.wait()
            end
            self.running = false
        end)
    end
    self.connection = workspace.DescendantAdded:Connect(enqueue)
    for _, object in workspace:GetDescendants() do
        enqueue(object)
    end
    return self
end

function Planes:destroy()
    self.dead = true
    self.connection:Disconnect()
    for texture, entry in self.bound do
        entry.plane:Destroy()
        if texture.Parent then
            texture.Transparency = entry.transparency
        end
    end
    for _, entry in self.cache do
        entry.template:Destroy()
    end
end
return Planes
