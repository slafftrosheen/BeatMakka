-- __PAYLOAD__ is replaced by tools/drive_studio.py with our decoded GLB data.
local payload = __PAYLOAD__
local storage = game:GetService("ServerStorage")
local assetService = game:GetService("AssetService")
local library = storage:FindFirstChild("AssetLibrary") or Instance.new("Folder")
library.Name = "AssetLibrary"
library.Parent = storage
local existing = library:FindFirstChild(payload.id)
assert(not existing or (existing:GetAttribute("LocalEditableReview") == true
    and existing:GetAttribute("SourceSHA256") == payload.sha256), "Refusing to overwrite a different library model: " .. payload.id)
local model = Instance.new("Model")
model.Name = payload.id
model:SetAttribute("AssetId", payload.id)
model:SetAttribute("TextureLayout", "FZ_MaterialAtlas_v1")
model:SetAttribute("TextureResolution", payload.resolution)
model:SetAttribute("SourceSHA256", payload.sha256)
model:SetAttribute("LocalEditableReview", true)
local triangles = 0
for _, data in payload.parts do
    local low, high = Vector3.new(table.unpack(data.bounds_min)), Vector3.new(table.unpack(data.bounds_max))
    local center = (low + high) / 2
    local editable = assetService:CreateEditableMesh()
    assert(editable, "EditableMesh memory allocation failed")
    local vertices, normals, uvs = {}, {}, {}
    for i, position in data.positions do
        vertices[i] = editable:AddVertex(Vector3.new(table.unpack(position)) - center)
        normals[i] = editable:AddNormal(Vector3.new(table.unpack(data.normals[i])))
        uvs[i] = editable:AddUV(Vector2.new(table.unpack(data.uvs[i])))
        if i % 500 == 0 then task.wait() end
    end
    for i, face in data.triangles do
        local a, b, c = table.unpack(face)
        local fid = editable:AddTriangle(vertices[a], vertices[b], vertices[c])
        editable:SetFaceNormals(fid, { normals[a], normals[b], normals[c] })
        editable:SetFaceUVs(fid, { uvs[a], uvs[b], uvs[c] })
        if i % 500 == 0 then task.wait() end
    end
    local mesh = assetService:CreateMeshPartAsync(Content.fromObject(editable), {
        CollisionFidelity = Enum.CollisionFidelity.Box,
        RenderFidelity = Enum.RenderFidelity.Automatic,
    })
    mesh.Name = data.name
    mesh.Anchored = true
    mesh.CanCollide = false
    mesh.CanTouch = false
    mesh.CanQuery = false
    mesh.Color = Color3.new(1, 1, 1)
    mesh.Size = high - low
    mesh.CFrame = CFrame.new(center)
    mesh.PivotOffset = CFrame.new(-center)
    local appearances = game:GetService("ReplicatedStorage"):FindFirstChild("AppearanceLibrary")
    local appearance = appearances and appearances:FindFirstChild("quay_" .. tostring(payload.resolution))
    if appearance then appearance:Clone().Parent = mesh end
    mesh.Parent = model
    triangles += #data.triangles
    task.wait()
end
model.WorldPivot = CFrame.identity
if existing then existing:Destroy() end
model.Parent = library
local _, size = model:GetBoundingBox()
return game:GetService("HttpService"):JSONEncode({ id = payload.id, parts = #payload.parts,
    triangles = triangles, size = { size.X, size.Y, size.Z }, sourceHash = payload.sha256,
    stage = "Local EditableMesh review only; no uploaded asset ID" })
