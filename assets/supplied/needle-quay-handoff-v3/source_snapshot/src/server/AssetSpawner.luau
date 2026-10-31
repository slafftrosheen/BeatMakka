local ServerStorage = game:GetService("ServerStorage")
local Theme = require(game:GetService("ReplicatedStorage").Shared.Theme)
local AssetSpawner = {}

function AssetSpawner.part(parent, name, size, cf, color, collide)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = cf
    part.Color = color
    part.Material = Enum.Material.SmoothPlastic
    part.Anchored = true
    part.CanCollide = collide == true
    part.CanTouch = false
    part.CanQuery = collide == true
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = parent
    return part
end

function AssetSpawner.place(parent, id, pivot, size, color, collision)
    local library = ServerStorage:FindFirstChild("AssetLibrary")
    local source = library and library:FindFirstChild(id)
    -- Editable review content can disappear when Studio copies Edit into Play.
    if source then
        local parts = source:GetDescendants()
        if source:IsA("MeshPart") then
            table.insert(parts, source)
        end
        for _, object in parts do
            if
                object:IsA("MeshPart")
                and object.MeshContent.SourceType == Enum.ContentSourceType.None
            then
                source = nil
                break
            end
        end
    end
    local model = Instance.new("Model")
    model.Name = id
    model:SetAttribute("AssetId", id)
    model.WorldPivot = pivot
    model.Parent = parent
    if source and (source:IsA("Model") or source:IsA("BasePart")) then
        model:SetAttribute("TextureLayout", source:GetAttribute("TextureLayout"))
        model:SetAttribute("TextureResolution", source:GetAttribute("TextureResolution"))
        local art = source:Clone()
        art.Name = "Art"
        art.Parent = model
        art:PivotTo(pivot)
        local parts = art:GetDescendants()
        if art:IsA("BasePart") then
            table.insert(parts, art)
        end
        for _, object in parts do
            if object:IsA("BasePart") then
                object.Anchored = true
                object.CanCollide = false
                object.CanTouch = false
                object.CanQuery = false
            end
        end
        model:SetAttribute("UsesImportedArt", true)
    else
        local proxy = AssetSpawner.part(
            model,
            "ArtProxy",
            size,
            pivot * CFrame.new(0, size.Y / 2, 0),
            color or Theme.Teal,
            false
        )
        proxy:SetAttribute("Placeholder", true)
        model:SetAttribute("UsesImportedArt", false)
    end
    if collision then
        local proxy = AssetSpawner.part(
            model,
            "CollisionProxy",
            collision,
            pivot * CFrame.new(0, collision.Y / 2, 0),
            Theme.Graphite,
            true
        )
        proxy.Transparency = 1
        proxy.CastShadow = false
    end
    return model
end
return AssetSpawner
