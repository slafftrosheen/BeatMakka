local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Cosmetics = require(Shared.CosmeticCatalog)
local Ids = require(Shared.ContentIds)
local Appearance = {}
Appearance.__index = Appearance

function Appearance.new(createSurface)
    return setmetatable({
        originals = {},
        proxyColors = {},
        templates = {},
        pending = {},
        station = nil,
        destroyed = false,
        -- Asset-ID map properties are PluginSecurity. Normal builds carry
        -- authored templates; an injected factory is only for explicit tests.
        createSurface = createSurface,
    }, Appearance)
end

function Appearance:reset()
    self.status = nil
    for part, backup in self.originals do
        if part.Parent then
            local current = part:FindFirstChildOfClass("SurfaceAppearance")
            if current and current:GetAttribute("TemporaryFinish") then
                current:Destroy()
            end
            if backup.surface then
                backup.surface.Parent = part
            end
            if backup.texture then
                part.TextureContent = backup.texture
            end
            if backup.materialKey then
                part:SetAttribute("LocalMaterialKey", backup.materialKey)
                require(script.Parent.LocalMaterials).bind(part, backup.materialKey)
            end
        elseif backup.surface then
            backup.surface:Destroy()
        end
    end
    for part, color in self.proxyColors do
        if part.Parent then
            part.Color = color
        end
    end
    table.clear(self.originals)
    table.clear(self.proxyColors)
end

function Appearance:template(finish, resolution)
    if
        self.destroyed
        or not Cosmetics.Sets[finish]
        or (resolution ~= 512 and resolution ~= 1024)
    then
        return nil
    end
    local key = finish .. "_" .. tostring(resolution)
    if self.templates[key] then
        return self.templates[key]
    end
    local localLibrary = ReplicatedStorage:FindFirstChild("LocalAppearanceLibrary")
    local localTemplate = localLibrary and localLibrary:FindFirstChild(key)
    if localTemplate then
        return localTemplate
    end
    local library = ReplicatedStorage:FindFirstChild("AppearanceLibrary")
    local prepared = library and library:FindFirstChild(key)
    if
        prepared
        and prepared:IsA("SurfaceAppearance")
        and prepared.ColorMapContent.SourceType ~= Enum.ContentSourceType.None
    then
        return prepared
    end
    local color = Ids.Images["atlas." .. finish .. ".basecolor." .. tostring(resolution)]
    local rough = Ids.Images["atlas.roughness." .. tostring(resolution)]
    local metal = Ids.Images["atlas.metalness." .. tostring(resolution)]
    if
        type(color) == "number"
        and type(rough) == "number"
        and type(metal) == "number"
        and self.createSurface ~= nil
        and not self.pending[key]
    then
        self.pending[key] = "loading"
        task.spawn(function()
            local ok, result = pcall(function()
                return self.createSurface({
                    ColorMap = Content.fromAssetId(color),
                    RoughnessMap = Content.fromAssetId(rough),
                    MetalnessMap = Content.fromAssetId(metal),
                })
            end)
            if self.destroyed then
                if ok then
                    result:Destroy()
                end
                return
            end
            if ok then
                result:SetAttribute("FinishSet", finish)
                self.templates[key] = result
                self.pending[key] = nil
            else
                self.pending[key] = "failed"
            end
            -- Keep a failed key bounded; rebinding content takes a fresh play session.
        end)
    end
    return nil
end

function Appearance:apply(state)
    if self.destroyed then
        return
    end
    if self.station ~= state.station then
        self:reset()
        self.station = state.station
    end
    if not state.station then
        return
    end
    if not Cosmetics.Sets[state.finish] then
        self:reset()
        self.status = "Finish preview unavailable: unknown finish."
        return
    end
    local root = Workspace:FindFirstChild("NeedleQuay")
    if not root then
        return
    end
    for _, model in root:GetChildren() do
        if model:GetAttribute("StationId") == state.station then
            local art = model:FindFirstChild("Art")
            local layout = model:GetAttribute("TextureLayout")
            local resolution = model:GetAttribute("TextureResolution") or 1024
            if
                self.model ~= model
                or self.art ~= art
                or self.layout ~= layout
                or self.resolution ~= resolution
            then
                self:reset()
                self.model, self.art, self.layout, self.resolution = model, art, layout, resolution
            end
            local compatible = layout == Cosmetics.TextureLayout
                and (resolution == 512 or resolution == 1024)
            if compatible and game:GetService("RunService"):IsStudio() then
                local image =
                    require(script.Parent.LocalMaterials).get(state.finish .. "_" .. resolution)
                self.status = if image
                    then "Local finish preview applied."
                    else "Local finish loading…"
                if image and art then
                    local parts = art:GetDescendants()
                    if art:IsA("MeshPart") then
                        table.insert(parts, art)
                    end
                    for _, part in parts do
                        if part:IsA("MeshPart") then
                            if not self.originals[part] then
                                self.originals[part] = {
                                    texture = part.TextureContent,
                                    materialKey = part:GetAttribute("LocalMaterialKey"),
                                }
                            end
                            local key = state.finish .. "_" .. resolution
                            part:SetAttribute("LocalMaterialKey", key)
                            require(script.Parent.LocalMaterials).bind(part, key)
                        end
                    end
                end
                continue
            end
            local template = if compatible then self:template(state.finish, resolution) else nil
            self.status = if not art
                then "Finish preview shown on the temporary device shape."
                elseif
                    not compatible
                then "Finish selected. This device does not support finish previews yet."
                elseif template == nil then (if self.pending[state.finish .. "_" .. tostring(
                        resolution
                    )] == "loading"
                    then "Finish selected. Texture preview is loading."
                    else "Finish selected. Its texture preview is unavailable.")
                else "Finish preview applied to your device."
            for _, object in model:GetDescendants() do
                if object:IsA("BasePart") and object.Name == "ArtProxy" then
                    if self.proxyColors[object] == nil then
                        self.proxyColors[object] = object.Color
                    end
                    object.Color = Cosmetics.Sets[state.finish].primary
                elseif
                    art
                    and (object == art or object:IsDescendantOf(art))
                    and object:IsA("MeshPart")
                    and compatible
                    and template ~= nil
                then
                    local current = object:FindFirstChildOfClass("SurfaceAppearance")
                    if not current or current:GetAttribute("FinishSet") ~= state.finish then
                        if self.originals[object] == nil then
                            self.originals[object] = { surface = current }
                            if current then
                                current.Parent = nil
                            end
                        end
                        if current and current.Parent then
                            current:Destroy()
                        end
                        local nextSurface = template:Clone()
                        nextSurface:SetAttribute("TemporaryFinish", true)
                        nextSurface:SetAttribute("FinishSet", state.finish)
                        nextSurface.Parent = object
                    end
                end
            end
        end
    end
end

function Appearance:destroy()
    if self.destroyed then
        return
    end
    self.destroyed = true
    self:reset()
    for _, template in self.templates do
        template:Destroy()
    end
    table.clear(self.templates)
    table.clear(self.pending)
    self.station = nil
    self.model, self.art = nil, nil
end
return Appearance
