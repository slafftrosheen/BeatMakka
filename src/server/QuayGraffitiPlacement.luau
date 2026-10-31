-- Bind reviewed panels to their rendered mesh, never its collision/bounding box.
local Anchors = require(game.ReplicatedStorage.Shared.QuayGraffitiAnchors)
local Placement = { thickness = 0.035, surfaceGap = 0.025 }

function Placement.resolve(sceneRoot, row)
    local anchor = Anchors[row.id]
    if
        not anchor
        or anchor.building ~= row.building
        or anchor.wall ~= row.wall
        or anchor.width ~= row.width
        or anchor.height ~= row.height
    then
        return nil, "Missing or mismatched reviewed wall panel"
    end
    local building = sceneRoot:FindFirstChild(row.building)
    local art = building and building:FindFirstChild("Art")
    if not art or art:GetAttribute("SourceSHA256") ~= anchor.source_sha256 then
        return nil, "Rendered building source does not match reviewed wall panel"
    end
    local support
    for _, mesh in art:GetDescendants() do
        if mesh:IsA("MeshPart") and mesh:GetAttribute("SourceMeshSHA256") == anchor.mesh_sha256 then
            support = mesh
            break
        end
    end
    if not support then
        return nil, "Reviewed supporting mesh is unavailable"
    end
    local scale = support.Size / Vector3.new(table.unpack(anchor.mesh_size))
    if math.max(scale.X, scale.Y, scale.Z) - math.min(scale.X, scale.Y, scale.Z) > 0.005 then
        return nil, "Nonuniform mesh scale requires wall-panel review"
    end
    local localPosition = Vector3.new(table.unpack(anchor.center))
        - Vector3.new(table.unpack(anchor.mesh_center))
    local position = support.CFrame:PointToWorldSpace(localPosition * scale)
    local normal = support.CFrame:VectorToWorldSpace(Vector3.new(table.unpack(anchor.normal))).Unit
    -- SurfaceGui.Front lies half a carrier thickness in front of its center.
    -- The visible artwork is exactly 0.025 world studs outside the mesh plane.
    local carrierPosition = position + normal * (Placement.surfaceGap - Placement.thickness / 2)
    return {
        cframe = CFrame.lookAt(carrierPosition, carrierPosition + normal, support.CFrame.UpVector),
        width = anchor.width * scale.X,
        height = anchor.height * scale.Y,
        support = support,
        source = anchor,
    }
end

return Placement
