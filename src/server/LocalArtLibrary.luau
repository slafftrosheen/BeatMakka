-- Durable local-file mesh import. Authored mesh content lives in the companion package.
local Service = game:GetService("AssetService")
local Storage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Catalog = table.clone(require(ReplicatedStorage.Shared.LocalMeshCatalog))
for _, companion in require(ReplicatedStorage.Shared.CompanionModels) do
    table.insert(Catalog, companion)
end
for _, asset in require(ReplicatedStorage.Shared.QuayDressingCatalog) do
    table.insert(Catalog, asset)
end
for _, asset in require(ReplicatedStorage.Shared.QuayLiftupCatalog) do
    table.insert(Catalog, asset)
end
for _, asset in require(ReplicatedStorage.Shared.QuayArchitectureCatalog) do
    for i = #Catalog, 1, -1 do
        if Catalog[i].id == asset.id then
            table.remove(Catalog, i)
        end
    end
    table.insert(Catalog, asset)
end
local suppliedBuildings = table.clone(require(ReplicatedStorage.Shared.QuayBuildingCatalog))
for _, van in require(ReplicatedStorage.Shared.QuayVanCatalog) do
    table.insert(suppliedBuildings, van)
end
for _, replacement in suppliedBuildings do
    for i = #Catalog, 1, -1 do
        if Catalog[i].id == replacement.id then
            table.remove(Catalog, i)
        end
    end
    table.insert(Catalog, replacement)
end
local Library = {}

function Library.build()
    if not game:GetService("RunService"):IsStudio() then
        return
    end
    local folder = Storage:FindFirstChild("AssetLibrary")
    local companionLibrary = ReplicatedStorage:FindFirstChild("CompanionLibrary")
        or Instance.new("Folder")
    companionLibrary.Name = "CompanionLibrary"
    companionLibrary.Parent = ReplicatedStorage
    ReplicatedStorage:SetAttribute("LocalArtTotal", #Catalog)
    ReplicatedStorage:SetAttribute("LocalArtLoaded", 0)
    for _, asset in Catalog do
        local model = Instance.new("Model")
        model.Name = asset.id
        model.WorldPivot = CFrame.identity
        model:SetAttribute("SourceSHA256", asset.source_sha256)
        model:SetAttribute("SourcePath", asset.source)
        model:SetAttribute("CoordinateBasis", asset.coordinate_basis or "legacy_reflected_v1")
        model:SetAttribute("ArtKind", asset.kind)
        local revised = asset.kind == "supplied_building"
            or asset.kind == "authored_architecture"
            or asset.kind == "supplied_van"
            or asset.kind == "companion"
            or asset.kind == "supplied_dressing"
            or asset.kind == "supplied_liftup"
            or asset.source:find("/refined/", 1, true) ~= nil
            or asset.source:find("/user-adapted/", 1, true) ~= nil
        model:SetAttribute("ArtApproved", not revised)
        model:SetAttribute("LocalFileArt", true)
        model:SetAttribute("ContinuousSkin", revised and asset.kind == "npc")
        if asset.skin then
            model:SetAttribute("LocalCharacterId", asset.id)
        end
        model:SetAttribute(
            "ArtStage",
            if asset.kind == "companion"
                then (if asset.suppliedSkin
                    then "USER_SUPPLIED_LOCAL_ADAPTATION_PENDING_ACCEPTANCE"
                    else "DCC_CANDIDATE_PENDING_ART_REVIEW")
                elseif revised then "LOCAL_ARTBOOK_REVISION_IN_REVIEW"
                else "ART_APPROVED_LOCAL_MESH"
        )
        model:SetAttribute("MeasuredTriangles", asset.triangles)
        if asset.resolution then
            model:SetAttribute("TextureLayout", "FZ_MaterialAtlas_v1")
            model:SetAttribute("TextureResolution", asset.resolution)
        end
        for _, entry in asset.parts do
            local ok, mesh = pcall(function()
                return Service:CreateMeshPartAsync(Content.fromUri(entry.uri), {
                    CollisionFidelity = Enum.CollisionFidelity.Box,
                    RenderFidelity = Enum.RenderFidelity.Precise,
                })
            end)
            if not ok then
                model:Destroy()
                error(
                    "Local Needle Quay mesh missing. Run tools/install_local_demo_content.py for this Studio version. "
                        .. entry.uri
                        .. ": "
                        .. tostring(mesh)
                )
            end
            mesh.Name = if entry.bone ~= "" then entry.bone .. "_" .. entry.name else entry.name
            mesh.Anchored = true
            mesh.CanCollide, mesh.CanTouch, mesh.CanQuery = false, false, false
            mesh.CFrame = CFrame.new(Vector3.new(table.unpack(entry.center)))
            mesh.Color = Color3.new(table.unpack(entry.color))
            mesh.Transparency = entry.transparency or 0
            if entry.name == "Glass" then
                mesh.Material = Enum.Material.Glass
                mesh.Reflectance = 0.12
            elseif entry.name == "Brass" then
                mesh.Material = Enum.Material.Metal
            end
            if entry.surface_family == "light" then
                mesh.Material = if asset.kind == "authored_architecture"
                        or entry.size[2] < 2
                    then Enum.Material.Neon
                    else Enum.Material.SmoothPlastic
            elseif
                entry.surface_family
                and (
                    entry.surface_family:sub(1, 10) == "character_"
                    or entry.surface_family:sub(1, 9) == "supplied_"
                    or entry.surface_family:sub(1, 9) == "authored_"
                )
            then
                mesh:SetAttribute("LocalMaterialKey", entry.surface_family)
            elseif entry.surface_family then
                mesh:SetAttribute("LocalMaterialKey", "env_" .. entry.surface_family)
                if
                    entry.surface_family == "wood"
                    or entry.surface_family == "brick"
                    or entry.surface_family == "stone"
                then
                    mesh.Color = Color3.fromRGB(238, 221, 195)
                end
            end
            mesh:SetAttribute("SourceMeshSHA256", entry.sha256)
            mesh:SetAttribute("MeshTriangleCount", entry.triangles)
            if entry.bone ~= "" then
                mesh:SetAttribute("RigidBone", entry.bone)
                local joint = asset.joints[entry.bone]
                if joint then
                    mesh:SetAttribute("JointPivot", Vector3.new(table.unpack(joint)))
                end
            end
            if asset.resolution then
                mesh:SetAttribute("LocalMaterialKey", "quay_" .. asset.resolution)
            end
            mesh.Parent = model
            task.wait()
        end
        for _, at in asset.lights or {} do
            local anchor = Instance.new("Part")
            anchor.Name = "AuthoredLampAnchor"
            anchor.Size, anchor.CFrame =
                Vector3.one * 0.1, CFrame.new(Vector3.new(table.unpack(at)))
            anchor.Anchored, anchor.Transparency = true, 1
            anchor.CanCollide, anchor.CanTouch, anchor.CanQuery, anchor.CastShadow =
                false, false, false, false
            local light = Instance.new("PointLight")
            light.Color, light.Brightness, light.Range = Color3.fromRGB(255, 193, 122), 1.3, 13
            light.Shadows, light.Parent = true, anchor
            anchor.Parent = model
        end
        if asset.sign then
            local anchor = Instance.new("Part")
            anchor.Name, anchor.Anchored, anchor.Transparency = "AuthoredNameplate", true, 1
            anchor.Size = Vector3.new(asset.sign.size[1], asset.sign.size[2], 0.02)
            anchor.CFrame = CFrame.new(Vector3.new(table.unpack(asset.sign.position)))
            anchor.CanCollide, anchor.CanTouch, anchor.CanQuery, anchor.CastShadow =
                false, false, false, false
            local gui = Instance.new("SurfaceGui")
            gui.Face, gui.SizingMode, gui.PixelsPerStud =
                Enum.NormalId.Front, Enum.SurfaceGuiSizingMode.PixelsPerStud, 90
            gui.LightInfluence, gui.MaxDistance, gui.Parent = 0.6, 150, anchor
            local text = Instance.new("TextLabel")
            text.Size, text.BackgroundTransparency = UDim2.fromScale(1, 1), 1
            text.Font, text.TextColor3 = Enum.Font.GothamBold, Color3.fromRGB(232, 216, 183)
            text.TextScaled, text.Text, text.Parent = true, asset.sign.text, gui
            anchor.Parent = model
        end
        local destination = if asset.kind == "companion" then companionLibrary else folder
        local old = destination:FindFirstChild(asset.id)
        if old then
            old:Destroy()
        end
        model.Parent = destination
        ReplicatedStorage:SetAttribute(
            "LocalArtLoaded",
            ReplicatedStorage:GetAttribute("LocalArtLoaded") + 1
        )
        task.wait()
    end
    folder:SetAttribute("LocalMeshImportComplete", true)
end
return Library
