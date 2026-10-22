local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetService = game:GetService("AssetService")
local Shared = ReplicatedStorage.Shared
local Cosmetics = require(Shared.CosmeticCatalog)
local Ids = require(Shared.ContentIds)
local Appearance = {}
Appearance.__index = Appearance

function Appearance.new()
    return setmetatable(
        { originals = {}, proxyColors = {}, templates = {}, pending = {}, station = nil },
        Appearance
    )
end

function Appearance:reset()
    for part, backup in self.originals do
        if part.Parent then
            local current = part:FindFirstChildOfClass("SurfaceAppearance")
            if current and current:GetAttribute("TemporaryFinish") then
                current:Destroy()
            end
            if backup.surface then
                backup.surface.Parent = part
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
    local key = finish .. "_" .. tostring(resolution)
    if self.templates[key] then
        return self.templates[key]
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
        and not self.pending[key]
    then
        self.pending[key] = true
        task.spawn(function()
            local ok, result = pcall(function()
                return AssetService:CreateSurfaceAppearanceAsync({
                    ColorMap = Content.fromAssetId(color),
                    RoughnessMap = Content.fromAssetId(rough),
                    MetalnessMap = Content.fromAssetId(metal),
                })
            end)
            if ok then
                result:SetAttribute("FinishSet", finish)
                self.templates[key] = result
            end
            -- Keep a failed key bounded; rebinding content takes a fresh play session.
        end)
    end
    return nil
end

function Appearance:apply(state)
    if self.station ~= state.station then
        self:reset()
        self.station = state.station
    end
    if not state.station then
        return
    end
    local root = Workspace:FindFirstChild("NeedleQuay")
    if not root then
        return
    end
    for _, model in root:GetChildren() do
        if model:GetAttribute("StationId") == state.station then
            local art = model:FindFirstChild("Art")
            local compatible = model:GetAttribute("TextureLayout") == Cosmetics.TextureLayout
            local resolution = model:GetAttribute("TextureResolution") or 1024
            local template = if compatible then self:template(state.finish, resolution) else nil
            self.status = if not art
                then "Finish preview shown on the temporary device shape."
                elseif
                    not compatible
                then "Finish saved. This device does not support finish previews yet."
                elseif template == nil then "Finish saved. Its texture preview is unavailable."
                else "Shared device finish applied."
            for _, object in model:GetDescendants() do
                if object:IsA("BasePart") and object.Name == "ArtProxy" then
                    if self.proxyColors[object] == nil then
                        self.proxyColors[object] = object.Color
                    end
                    object.Color = Cosmetics.Sets[state.finish].primary
                elseif art and object:IsA("MeshPart") and compatible and template ~= nil then
                    local current = object:FindFirstChildOfClass("SurfaceAppearance")
                    if not current or current:GetAttribute("FinishSet") ~= state.finish then
                        if self.originals[object] == nil then
                            self.originals[object] =
                                { surface = if current then current:Clone() else nil }
                        end
                        if current then
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
return Appearance
