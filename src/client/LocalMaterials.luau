-- Local PBR: shared EditableImage maps and SurfaceAppearance templates.
-- No asset publishing, remote TexturePack IDs or upload API is used.
local Assets = game:GetService("AssetService")
local Storage = game:GetService("ReplicatedStorage")
local ContentMap = require(Storage.Shared.LocalContent)
local Grade = require(script.Parent.ArtbookColorGrade)
local textureUri = require(script.Parent.LocalTextureUri)
local Materials = {}
Materials.__index = Materials
local active
local function constantMap(self, name, red, green, blue)
    if self.images[name] then
        return self.images[name]
    end
    local image = Assets:CreateEditableImage({ Size = Vector2.new(4, 4) })
    assert(image, "PBR map memory unavailable")
    local pixels = buffer.create(64)
    for i = 0, 15 do
        buffer.writeu8(pixels, i * 4, red)
        buffer.writeu8(pixels, i * 4 + 1, green)
        buffer.writeu8(pixels, i * 4 + 2, blue)
        buffer.writeu8(pixels, i * 4 + 3, 255)
    end
    image:WritePixelsBuffer(Vector2.zero, Vector2.new(4, 4), pixels)
    self.images[name] = image
    return image
end
function Materials.get(key)
    return active and active.textures[key]
end
function Materials.surface(key)
    return active and active.surfaces[key]
end
function Materials.fromContent(content)
    if content.SourceType ~= Enum.ContentSourceType.Object or not active then
        return nil
    end
    local surface = Assets:CreateSurfaceAppearanceAsync({
        ColorMap = content,
        NormalMap = Content.fromObject(constantMap(active, "flatNormal", 128, 128, 255)),
        RoughnessMap = Content.fromObject(constantMap(active, "rough230", 230, 230, 230)),
        MetalnessMap = Content.fromObject(constantMap(active, "metal0", 0, 0, 0)),
    })
    surface.AlphaMode = Enum.AlphaMode.Transparency
    surface:SetAttribute("LocalPBRKey", "supplied_character_source_roughness")
    return surface
end
function Materials.bind(part, key)
    local template = Materials.surface(key)
    if not template then
        return false
    end
    local old = part:FindFirstChildOfClass("SurfaceAppearance")
    if old and old:GetAttribute("LocalPBRKey") == key then
        old.Color = part.Color
        return true
    end
    if old then
        old:Destroy()
    end
    local surface = template:Clone()
    surface.Color = part.Color
    surface.Parent = part
    part.TextureContent = Content.none
    part:SetAttribute("LocalPBRBound", true)
    return true
end
function Materials.new()
    local self = setmetatable(
        { images = {}, textures = {}, surfaces = {}, connections = {}, dead = false },
        Materials
    )
    active = self
    if not game:GetService("RunService"):IsStudio() then
        return self
    end
    task.spawn(function()
        local definitions = {}
        for _, finish in { "quay", "chalk", "coral", "afterhours" } do
            for _, resolution in { 512, 1024 } do
                local key = finish .. "_" .. resolution
                definitions[key] = {
                    color = ContentMap.Materials[key]
                        or ("rbxasset://needle-quay/materials/" .. key .. ".png"),
                    grade = false,
                    normal = nil,
                    rough = "rbxasset://needle-quay/materials/roughness_" .. resolution .. ".png",
                    metal = "rbxasset://needle-quay/materials/metalness_" .. resolution .. ".png",
                }
            end
        end
        for _, family in { "brick", "plaster", "wood", "stone", "canvas", "metal" } do
            definitions["env_" .. family] = {
                color = ContentMap.Materials["env_" .. family .. "_color"],
                grade = false,
                normal = ContentMap.Materials["env_" .. family .. "_normal"],
                rough = ContentMap.Materials["env_" .. family .. "_rough"],
                metalValue = if family == "metal" then 0.7 else 0,
            }
        end
        for _, character in ContentMap.Characters or {} do
            definitions["character_" .. character] = {
                color = ContentMap.Materials["character_" .. character .. "_color"],
                grade = false,
                normal = ContentMap.Materials["character_" .. character .. "_normal"],
                rough = ContentMap.Materials["character_" .. character .. "_rough"],
            }
        end
        for role, family in
            {
                brick = "brick",
                teal = "plaster",
                faded = "plaster",
                cream = "plaster",
                coral = "plaster",
                wood = "wood",
                stone = "stone",
                iron = "plaster",
                brass = "plaster",
                glass = "plaster",
                leaf = "plaster",
            }
        do
            definitions["authored_" .. role] = {
                color = ContentMap.Materials["env_" .. family .. "_color"],
                grade = false,
                normal = if role == "glass"
                    then nil
                    else ContentMap.Materials["env_" .. family .. "_normal"],
                rough = if role == "glass"
                        or role == "brass"
                        or role == "iron"
                    then nil
                    else ContentMap.Materials["env_" .. family .. "_rough"],
                roughValue = if role == "glass" then 0.22 elseif role == "brass" then 0.38 else 0.65,
                metalValue = if role == "brass" then 0.75 elseif role == "iron" then 0.6 else 0,
            }
        end
        local function constant(name, red, green, blue)
            return constantMap(self, name, red, green, blue)
        end
        local function loadMap(uri)
            uri = textureUri(uri)
            if not self.images[uri] then
                local image = Assets:CreateEditableImageAsync(Content.fromUri(uri))
                assert(image, "PBR map memory unavailable: " .. uri)
                self.images[uri] = image
            end
            return self.images[uri]
        end
        for _, key in ContentMap.UserMaterials or {} do
            definitions[key] = { color = ContentMap.Materials[key .. "_color"], grade = true }
        end
        for _, name in
            {
                "QuayDressingMaterials",
                "QuayBuildingMaterials",
                "QuayVanMaterials",
                "QuayLiftupMaterials",
            }
        do
            for key, uri in require(Storage.Shared[name]) do
                definitions[key] = { color = uri, grade = true }
            end
        end
        local failures = 0
        for key, row in definitions do
            if self.dead then
                return
            end
            local ok, reason = pcall(function()
                local uri = textureUri(row.color)
                local image = self.images[uri]
                if not image then
                    image = Assets:CreateEditableImageAsync(Content.fromUri(uri))
                    assert(image, "Local texture memory unavailable: " .. key)
                    if self.dead then
                        image:Destroy()
                        return
                    end
                    self.images[uri] = image
                    if row.grade then
                        Grade.apply(image, "supplied", function()
                            return self.dead
                        end)
                    end
                end
                self.textures[key] = image
                local rough = math.floor((row.roughValue or 0.9) * 255 + 0.5)
                local metal = math.floor((row.metalValue or 0) * 255 + 0.5)
                local normalImage = if row.normal
                    then loadMap(row.normal)
                    else constant("flatNormal", 128, 128, 255)
                local roughImage = if row.rough
                    then loadMap(row.rough)
                    else constant("rough" .. rough, rough, rough, rough)
                local metalImage = if row.metal
                    then loadMap(row.metal)
                    else constant("metal" .. metal, metal, metal, metal)
                local surface = Assets:CreateSurfaceAppearanceAsync({
                    ColorMap = Content.fromObject(image),
                    NormalMap = Content.fromObject(normalImage),
                    RoughnessMap = Content.fromObject(roughImage),
                    MetalnessMap = Content.fromObject(metalImage),
                })
                surface.Name = "LocalPBR_" .. key
                surface.AlphaMode = Enum.AlphaMode.Transparency
                surface:SetAttribute("LocalPBRKey", key)
                self.surfaces[key] = surface
            end)
            if not ok then
                failures += 1
                warn("Local material " .. key .. ": " .. tostring(reason))
            end
            task.wait()
        end
        if self.dead then
            return
        end
        local function apply(part)
            if self.dead or not part:IsA("MeshPart") then
                return
            end
            local key = part:GetAttribute("LocalMaterialKey")
            local image = key and self.textures[key]
            if image then
                Materials.bind(part, key)
                part:SetAttribute("LocalTextureBound", true)
            end
        end
        local watched = setmetatable({}, { __mode = "k" })
        local function watch(part)
            if not part:IsA("MeshPart") or watched[part] then
                return
            end
            watched[part] = true
            apply(part)
            table.insert(
                self.connections,
                part:GetAttributeChangedSignal("LocalMaterialKey"):Connect(function()
                    apply(part)
                end)
            )
            table.insert(
                self.connections,
                part:GetPropertyChangedSignal("Color"):Connect(function()
                    local surface = part:FindFirstChildOfClass("SurfaceAppearance")
                    if surface and surface:GetAttribute("LocalPBRKey") then
                        surface.Color = part.Color
                    end
                end)
            )
        end
        table.insert(
            self.connections,
            workspace.DescendantAdded:Connect(function(part)
                task.defer(watch, part)
            end)
        )
        for i, part in workspace:GetDescendants() do
            watch(part)
            if i % 400 == 0 then
                task.wait()
            end
        end
        self.ready = true
        self.planes = require(script.Parent.LocalPBRPlanes).new(Materials)
        Storage:SetAttribute("LocalPBRReady", failures == 0)
        Storage:SetAttribute("LocalPBRFailed", failures)
        Storage:SetAttribute("LocalTextureFailures", failures)
        Storage:SetAttribute("LocalPBRLoadComplete", true)
        Storage:SetAttribute(
            "LocalMaterialMode",
            "Local SurfaceAppearance / editable color, normal, roughness and metalness / no uploads"
        )
        Storage:SetAttribute(
            "ArtbookMaterialTreatment",
            "World v2 / Needle Quay Vol.01 / UVs and alpha retained"
        )
    end)
    return self
end
function Materials:destroy()
    self.dead = true
    if self.planes then
        self.planes:destroy()
    end
    for _, connection in self.connections do
        connection:Disconnect()
    end
    for _, image in self.images do
        image:Destroy()
    end
    for _, surface in self.surfaces do
        surface:Destroy()
    end
    if active == self then
        active = nil
    end
end
return Materials
