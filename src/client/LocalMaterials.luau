-- Local PBR uses EditableImages on each client: raw local SurfaceAppearance URIs
-- are not supported by the renderer. Retain image lifetimes while templates exist.
local Assets = game:GetService("AssetService")
local Storage = game:GetService("ReplicatedStorage")
local LocalContent = require(Storage.Shared.LocalContent)
local Materials = {}
Materials.__index = Materials

function Materials.new()
    local self =
        setmetatable({ images = {}, connections = {}, ready = false, dead = false }, Materials)
    if not game:GetService("RunService"):IsStudio() then
        return self
    end
    task.spawn(function()
        local ok, failure = pcall(function()
            local deadline = os.clock() + 60
            while
                not Storage:GetAttribute("LocalSkinsBuilt")
                and not self.dead
                and os.clock() < deadline
            do
                task.wait(0.1)
            end
            if self.dead then
                return
            end
            local folder = Instance.new("Folder")
            folder.Name = "LocalAppearanceLibrary"
            self.folder = folder
            folder.Parent = Storage
            local function image(name)
                local uri = LocalContent.Materials[name]
                    or ("rbxasset://needle-quay/materials/" .. name .. ".png")
                if self.images[uri] then
                    return self.images[uri]
                end
                local result = Assets:CreateEditableImageAsync(Content.fromUri(uri))
                assert(result, "Local image memory exhausted: " .. name)
                if self.dead then
                    result:Destroy()
                    error("Local materials shut down")
                end
                self.images[uri] = result
                return result
            end
            for _, resolution in { 512, 1024 } do
                -- Only quay is bound in this local district; avoid allocating three unused atlases.
                for _, finish in { "quay" } do
                    local surface = Assets:CreateSurfaceAppearanceAsync({
                        ColorMap = Content.fromObject(image(finish .. "_" .. resolution)),
                        RoughnessMap = Content.fromObject(image("roughness_512")),
                        MetalnessMap = Content.fromObject(image("metalness_512")),
                    })
                    surface.Name = finish .. "_" .. resolution
                    surface:SetAttribute("LocalPBR", true)
                    surface.Parent = folder
                end
            end
            for _, family in { "brick", "plaster", "wood", "stone", "canvas", "metal" } do
                local prefix = "env_" .. family
                local surface = Assets:CreateSurfaceAppearanceAsync({
                    ColorMap = Content.fromObject(image(prefix .. "_color")),
                    NormalMap = Content.fromObject(image(prefix .. "_normal")),
                    RoughnessMap = Content.fromObject(image(prefix .. "_rough")),
                })
                surface.Name = prefix
                surface:SetAttribute("LocalPBR", true)
                surface.Parent = folder
            end
            for _, character in LocalContent.Characters or {} do
                local prefix = "character_" .. character
                local surface = Assets:CreateSurfaceAppearanceAsync({
                    ColorMap = Content.fromObject(image(prefix .. "_color")),
                    NormalMap = Content.fromObject(image(prefix .. "_normal")),
                    RoughnessMap = Content.fromObject(image(prefix .. "_rough")),
                })
                surface.Name = prefix
                surface:SetAttribute("LocalPBR", true)
                surface.Parent = folder
            end
            for _, key in LocalContent.UserMaterials or {} do
                local surface = Assets:CreateSurfaceAppearanceAsync({
                    ColorMap = Content.fromObject(image(key .. "_color")),
                    RoughnessMap = Content.fromObject(image("env_plaster_rough")),
                })
                surface.Name = key
                surface:SetAttribute("LocalPBR", true)
                surface.Parent = folder
            end
            self.ready = true
            local function apply(surface)
                if surface:IsA("MeshPart") and surface:GetAttribute("LocalMaterialKey") then
                    if not surface:FindFirstChildOfClass("SurfaceAppearance") then
                        local template =
                            folder:FindFirstChild(surface:GetAttribute("LocalMaterialKey"))
                        if template then
                            local clone = template:Clone()
                            clone.Color = surface.Color
                            clone.Parent = surface
                        end
                    end
                    return
                end
                if
                    self.dead
                    or not surface:IsA("SurfaceAppearance")
                    or surface:GetAttribute("LocalPBR")
                then
                    return
                end
                local parent = surface.Parent
                if not parent or not parent:IsA("MeshPart") then
                    return
                end
                local template = folder:FindFirstChild(surface.Name)
                if template then
                    local clone = template:Clone()
                    surface:Destroy()
                    clone.Parent = parent
                end
            end
            table.insert(
                self.connections,
                workspace.DescendantAdded:Connect(function(object)
                    if object:IsA("SurfaceAppearance") or object:IsA("MeshPart") then
                        task.defer(apply, object)
                    end
                end)
            )
            for _, object in workspace:GetDescendants() do
                apply(object)
            end
            Storage:SetAttribute("LocalPBRReady", true)
        end)
        if not ok and not self.dead then
            Storage:SetAttribute("LocalPBRError", tostring(failure))
            warn("Local Needle Quay materials: " .. tostring(failure))
        end
    end)
    return self
end

function Materials:destroy()
    self.dead = true
    for _, connection in self.connections do
        connection:Disconnect()
    end
    if self.folder then
        self.folder:Destroy()
    end
    for _, object in self.images do
        object:Destroy()
    end
end
return Materials
