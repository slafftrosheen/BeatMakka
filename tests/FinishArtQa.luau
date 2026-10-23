-- Temporary Client-only H01 art for acceptance. Never part of the game build.
-- Editable art does not establish a permanent mesh import.
return function(payload)
    assert(
        payload.id == "H01"
            and payload.sha256
                == "7f27ff7da218c44e19fba120ab3decda47f4cbd836db0eb38d94d0882dfa15e3",
        "Unexpected H01 source"
    )
    local resources, models, backups = {}, {}, {}
    local function cleanup()
        for _, model in models do
            model:Destroy()
        end
        for _, resource in resources do
            resource:Destroy()
        end
        for model, backup in backups do
            model:SetAttribute("TextureLayout", backup.layout)
            model:SetAttribute("TextureResolution", backup.resolution)
            if backup.proxy then
                backup.proxy.Transparency = backup.transparency
            end
        end
        table.clear(models)
        table.clear(resources)
        table.clear(backups)
    end
    local ok, err = pcall(function()
        for _, station in workspace.NeedleQuay:GetChildren() do
            if not station:GetAttribute("StationId") then
                continue
            end
            assert(not station:FindFirstChild("Art"), "Preserve existing imported art")
            local proxy = station:FindFirstChild("ArtProxy")
            backups[station] = {
                layout = station:GetAttribute("TextureLayout"),
                resolution = station:GetAttribute("TextureResolution"),
                proxy = proxy,
                transparency = proxy and proxy.Transparency,
            }
            local art = Instance.new("Model")
            art.Name = "Art"
            art:SetAttribute("TemporaryAcceptanceArt", true)
            table.insert(models, art)
            for _, data in payload.parts do
                local mesh = game.AssetService:CreateEditableMesh()
                assert(mesh, "Editable mesh allocation failed")
                table.insert(resources, mesh)
                local low, high =
                    Vector3.new(table.unpack(data.bounds_min)),
                    Vector3.new(table.unpack(data.bounds_max))
                local center = (low + high) / 2
                local vertices, normals, uvs = {}, {}, {}
                for i, position in data.positions do
                    vertices[i] = mesh:AddVertex(Vector3.new(table.unpack(position)) - center)
                    normals[i] = mesh:AddNormal(Vector3.new(table.unpack(data.normals[i])))
                    uvs[i] = mesh:AddUV(Vector2.new(table.unpack(data.uvs[i])))
                    if i % 500 == 0 then
                        task.wait()
                    end
                end
                for i, face in data.triangles do
                    local a, b, c = table.unpack(face)
                    local f = mesh:AddTriangle(vertices[a], vertices[b], vertices[c])
                    mesh:SetFaceNormals(f, { normals[a], normals[b], normals[c] })
                    mesh:SetFaceUVs(f, { uvs[a], uvs[b], uvs[c] })
                    if i % 500 == 0 then
                        task.wait()
                    end
                end
                local part = game.AssetService:CreateMeshPartAsync(Content.fromObject(mesh))
                part.Name = data.name
                part.Anchored = true
                part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
                part.Size = high - low
                part.CFrame = station:GetPivot() * CFrame.new(center)
                game.ReplicatedStorage.AppearanceLibrary.quay_512:Clone().Parent = part
                part.Parent = art
            end
            art.Parent = station
            station:SetAttribute("TextureLayout", "FZ_MaterialAtlas_v1")
            station:SetAttribute("TextureResolution", 512)
            if proxy then
                proxy.Transparency = 1
            end
        end
    end)
    if not ok then
        cleanup()
        error(err)
    end
    return cleanup
end
