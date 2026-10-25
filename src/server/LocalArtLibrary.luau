-- Durable local-file mesh import. Authored mesh content lives in the companion package.
local Service = game:GetService("AssetService")
local Storage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Catalog = require(ReplicatedStorage.Shared.LocalMeshCatalog)
local Library = {}

function Library.build()
    if not game:GetService("RunService"):IsStudio() then
        return
    end
    local folder = Storage:FindFirstChild("AssetLibrary")
    ReplicatedStorage:SetAttribute("LocalArtTotal", #Catalog)
    ReplicatedStorage:SetAttribute("LocalArtLoaded", 0)
    for _, asset in Catalog do
        local model = Instance.new("Model")
        model.Name = asset.id
        model.WorldPivot = CFrame.identity
        model:SetAttribute("SourceSHA256", asset.source_sha256)
        model:SetAttribute("SourcePath", asset.source)
        local revised = asset.source:find("/refined/", 1, true) ~= nil
            or asset.source:find("/user-adapted/", 1, true) ~= nil
        model:SetAttribute("ArtApproved", not revised)
        model:SetAttribute("LocalFileArt", true)
        model:SetAttribute("ContinuousSkin", revised and asset.kind == "npc")
        if asset.skin then
            model:SetAttribute("LocalCharacterId", asset.id)
        end
        model:SetAttribute(
            "ArtStage",
            if revised then "LOCAL_ARTBOOK_REVISION_IN_REVIEW" else "ART_APPROVED_LOCAL_MESH"
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
            if entry.surface_family == "light" then
                mesh.Material = if entry.size[2] < 2
                    then Enum.Material.Neon
                    else Enum.Material.SmoothPlastic
            elseif
                entry.surface_family
                and (
                    entry.surface_family:sub(1, 10) == "character_"
                    or entry.surface_family:sub(1, 9) == "supplied_"
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
        local old = folder:FindFirstChild(asset.id)
        if old then
            old:Destroy()
        end
        model.Parent = folder
        ReplicatedStorage:SetAttribute(
            "LocalArtLoaded",
            ReplicatedStorage:GetAttribute("LocalArtLoaded") + 1
        )
        task.wait()
    end
    folder:SetAttribute("LocalMeshImportComplete", true)
end
return Library
