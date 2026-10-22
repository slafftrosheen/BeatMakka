-- Run in Edit on the authorized local BeatMakaAssetReview place.
assert(game.PlaceId == 0, "This helper targets the unpublished local review place only")
local storage = game:GetService("ServerStorage")
local backup = storage:FindFirstChild("InitialReviewScene") or Instance.new("Folder")
backup.Name = "InitialReviewScene"
backup.Parent = storage
for _, name in { "Baseplate", "SpawnLocation" } do
    local object = workspace:FindFirstChild(name)
    if object then object.Parent = backup end
end
workspace.StreamingEnabled = true
-- Fresh clones prevent Edit-mode require caches from rebuilding an older source.
local modules = Instance.new("Folder")
modules.Name = "WorkshopBuildModules"
modules.Parent = storage
for _, child in game:GetService("ServerScriptService").Server:GetChildren() do
    if child:IsA("ModuleScript") then child:Clone().Parent = modules end
end
local ok, world = pcall(function() return require(modules.WorldBuilder).build() end)
modules:Destroy()
assert(ok, world)
local meshParts, solidProxies, shadows = 0, 0, 0
for _, object in world.root:GetDescendants() do
    if object:IsA("MeshPart") then meshParts += 1 end
    if object:IsA("BasePart") and object.CanCollide then solidProxies += 1 end
    if object:IsA("Light") and object.Shadows then shadows += 1 end
end
workspace.CurrentCamera.CFrame = CFrame.lookAt(Vector3.new(45, 32, -50), Vector3.new(8, 4, 0))
return game:GetService("HttpService"):JSONEncode({
    stations = 2, discoveries = 3, placedMeshParts = meshParts, colliders = solidProxies,
    shadowLights = shadows, localReview = true, published = false,
})
