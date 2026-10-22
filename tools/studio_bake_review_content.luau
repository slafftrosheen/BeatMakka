-- Freeze locally authored mesh/image data into the current DataModel's content.
-- This creates no inventory asset, publishes no place and returns no asset IDs.
assert(game.PlaceId == 0, "Use the unpublished local review place")
local assetService = game:GetService("AssetService")
local cache = {}
local function bake(content)
    if not content.Object then return content end
    local object = content.Object
    if cache[object] then return cache[object] end
    local result, frozen = assetService:CreateDataModelContentAsync(content)
    assert(result == Enum.CreateContentResult.Success, tostring(result))
    cache[object] = frozen
    return frozen
end
local meshCount, imageCount = 0, 0
for _, model in game:GetService("ServerStorage").AssetLibrary:GetChildren() do
    for _, mesh in model:GetDescendants() do
        if mesh:IsA("MeshPart") and mesh.MeshContent.Object then
            local cf, size, pivot = mesh.CFrame, mesh.Size, mesh.PivotOffset
            local static = assetService:CreateMeshPartAsync(bake(mesh.MeshContent), {
                RenderFidelity = Enum.RenderFidelity.Automatic, CollisionFidelity = Enum.CollisionFidelity.Box,
            })
            mesh:ApplyMesh(static)
            mesh.Size, mesh.CFrame, mesh.PivotOffset = size, cf, pivot
            static:Destroy()
            meshCount += 1
        end
    end
    model:SetAttribute("LocalBakedReview", true)
    task.wait()
end
for _, surface in game:GetService("ReplicatedStorage").AppearanceLibrary:GetChildren() do
    if surface:IsA("SurfaceAppearance") then
        for _, property in { "ColorMapContent", "RoughnessMapContent", "MetalnessMapContent" } do
            surface[property] = bake(surface[property])
            imageCount += 1
        end
        surface:SetAttribute("LocalBakedReview", true)
        surface:SetAttribute("ContentRevision", tostring(os.clock()))
    end
    task.wait()
end
for _, image in game:GetService("ReplicatedStorage").UiImageLibrary:GetChildren() do
    if image:IsA("ImageLabel") then image.ImageContent = bake(image.ImageContent); imageCount += 1 end
end
-- Library mesh appearances must follow the baked shared templates.
for _, model in game:GetService("ServerStorage").AssetLibrary:GetChildren() do
    local template = game:GetService("ReplicatedStorage").AppearanceLibrary:FindFirstChild("quay_" .. tostring(model:GetAttribute("TextureResolution")))
    for _, mesh in model:GetDescendants() do
        if mesh:IsA("MeshPart") and template then
            local old = mesh:FindFirstChildOfClass("SurfaceAppearance")
            if old then old:Destroy() end
            template:Clone().Parent = mesh
        end
    end
end
return game:GetService("HttpService"):JSONEncode({meshesBaked=meshCount,imageMapsBaked=imageCount,
    inventoryUpload=false,productionPublish=false,scope="Local DataModel review"})
