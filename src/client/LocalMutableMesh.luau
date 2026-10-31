-- Snapshot and release the fixed import BEFORE reserving mutable topology memory.
local Assets = game:GetService("AssetService")
return function(uri, cancelled)
    local imported, editable
    local ok, result = pcall(function()
        imported = Assets:CreateEditableMeshAsync(Content.fromUri(uri))
        assert(imported, "Local mesh import memory unavailable")
        local points, uvs, normals, faces = {}, {}, {}, {}
        for _, id in imported:GetVertices() do
            points[id] = imported:GetPosition(id)
        end
        for _, id in imported:GetUVs() do
            uvs[id] = imported:GetUV(id)
        end
        for _, id in imported:GetNormals() do
            normals[id] = imported:GetNormal(id)
        end
        for index, id in imported:GetFaces() do
            local corners = {}
            for _, vertex in imported:GetFaceVertices(id) do
                table.insert(
                    corners,
                    {
                        vertex,
                        imported:GetVertexFaceUV(vertex, id),
                        imported:GetVertexFaceNormal(vertex, id),
                    }
                )
            end
            faces[index] = corners
        end
        imported:Destroy()
        imported = nil
        for _ = 1, 8 do
            if cancelled() then
                error("Mesh construction cancelled")
            end
            editable = Assets:CreateEditableMesh()
            if editable then
                break
            end
            task.wait(0.25)
        end
        assert(editable, "Local mutable mesh memory unavailable after import release")
        local vertices, textureIds, normalIds = {}, {}, {}
        local uniquePoints, uniqueUvs, uniqueNormals = {}, {}, {}
        for id, p in points do
            local k = string.format("%.7g:%.7g:%.7g", p.X, p.Y, p.Z)
            uniquePoints[k] = uniquePoints[k] or editable:AddVertex(p)
            vertices[id] = uniquePoints[k]
        end
        for id, p in uvs do
            local k = string.format("%.7g:%.7g", p.X, p.Y)
            uniqueUvs[k] = uniqueUvs[k] or editable:AddUV(p)
            textureIds[id] = uniqueUvs[k]
        end
        for id, p in normals do
            local k = string.format("%.7g:%.7g:%.7g", p.X, p.Y, p.Z)
            uniqueNormals[k] = uniqueNormals[k] or editable:AddNormal(p)
            normalIds[id] = uniqueNormals[k]
        end
        for i, corners in faces do
            local face = editable:AddTriangle(
                vertices[corners[1][1]],
                vertices[corners[2][1]],
                vertices[corners[3][1]]
            )
            for _, c in corners do
                editable:SetVertexFaceUV(vertices[c[1]], face, textureIds[c[2]])
                editable:SetVertexFaceNormal(vertices[c[1]], face, normalIds[c[3]])
            end
            if i % 500 == 0 then
                if cancelled() then
                    error("Mesh construction cancelled")
                end
                task.wait()
            end
        end
        return editable
    end)
    if not ok then
        if imported then
            imported:Destroy()
        end
        if editable then
            editable:Destroy()
        end
        error(result)
    end
    return result
end
