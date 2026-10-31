-- Server Play probe. Reads scene placement, then uses unparented fixtures only.
local Shared = game.ReplicatedStorage.Shared
local Layout = require(Shared.QuayStreetLayout)
local Anchors = require(Shared.QuayGraffitiAnchors)
local Placement = require(game.ServerScriptService.Server.QuayGraffitiPlacement)
local results = {}
local function check(name, callback)
    local ok, detail = xpcall(callback, debug.traceback)
    table.insert(results, { name = name, passed = ok, detail = tostring(detail or "ok") })
end

check("All eight building murals reference rendered mesh panels", function()
    local district = workspace:FindFirstChild("DemoDistrict", true)
    assert(district, "DemoDistrict is not built")
    local street = district:FindFirstChild("StreetLiftup")
    assert(street, "StreetLiftup is not built")
    local count = 0
    for _, row in Layout.graffiti do
        if row.building then
            local mural = street:FindFirstChild(row.id)
            assert(mural, row.id .. " is missing")
            local resolved, reason = Placement.resolve(district, row)
            assert(resolved, row.id .. ": " .. tostring(reason))
            assert(
                mural:GetAttribute("GraffitiAttachment") == "REVIEWED_RENDERED_MESH_PANEL",
                row.id .. " lacks mesh binding"
            )
            assert(
                (mural.Position - resolved.cframe.Position).Magnitude < 0.001,
                row.id .. " position differs"
            )
            assert(
                mural.CFrame.LookVector:Dot(resolved.cframe.LookVector) > 0.99999,
                row.id .. " faces wrong direction"
            )
            assert(math.abs(mural.Size.X - resolved.width) < 0.001, row.id .. " width differs")
            assert(math.abs(mural.Size.Y - resolved.height) < 0.001, row.id .. " height differs")
            assert(mural.RenderedWall.Value == resolved.support, row.id .. " links wrong mesh")
            assert(resolved.support:IsA("MeshPart"))
            assert(resolved.support:IsDescendantOf(district[row.building].Art))
            assert(not mural.StreetArtwork.AlwaysOnTop, row.id .. " bypasses depth test")
            assert(
                not mural.CanCollide and not mural.CanTouch and not mural.CanQuery,
                row.id .. " affects physics"
            )
            count += 1
        end
    end
    assert(count == 8, "Expected eight building murals")
    return "Eight exact mesh bindings; matching transforms/sizes; physical depth test enabled"
end)

check("Placement follows rendered mesh translation, rotation and uniform scale", function()
    local row = Layout.graffiti[2]
    local anchor = Anchors[row.id]
    local fixture = Instance.new("Folder")
    local ok, message = xpcall(function()
        local building = Instance.new("Model")
        building.Name, building.Parent = row.building, fixture
        local art = Instance.new("Model")
        art.Name, art.Parent = "Art", building
        art:SetAttribute("SourceSHA256", anchor.source_sha256)
        local support = Instance.new("MeshPart")
        support.Name, support.Parent = "RenderedSurfaceFixture", art
        support:SetAttribute("SourceMeshSHA256", anchor.mesh_sha256)
        support.Size = Vector3.new(table.unpack(anchor.mesh_size)) * 1.75
        support.CFrame = CFrame.new(-29, 8, 113) * CFrame.Angles(0.1, 1.3, -0.2)
        local resolved, reason = Placement.resolve(fixture, row)
        assert(resolved, reason)
        local surface = support.CFrame:PointToWorldSpace(
            (
                Vector3.new(table.unpack(anchor.center))
                - Vector3.new(table.unpack(anchor.mesh_center))
            ) * 1.75
        )
        local normal = support.CFrame:VectorToWorldSpace(Vector3.new(table.unpack(anchor.normal)))
        local imagePlane = resolved.cframe.Position
            + resolved.cframe.LookVector * Placement.thickness / 2
        assert(
            (imagePlane - (surface + normal * 0.025)).Magnitude < 0.001,
            "Image-plane gap differs from 0.025"
        )
        assert(resolved.cframe.LookVector:Dot(normal) > 0.99999, "Rotated panel normal differs")
        assert(math.abs(resolved.width - anchor.width * 1.75) < 0.001, "Scaled panel width differs")
        assert(
            math.abs(resolved.height - anchor.height * 1.75) < 0.001,
            "Scaled panel height differs"
        )
        art:SetAttribute("SourceSHA256", "changed")
        assert(Placement.resolve(fixture, row) == nil, "Stale source accepted")
        art:SetAttribute("SourceSHA256", anchor.source_sha256)
        support:SetAttribute("SourceMeshSHA256", "changed")
        assert(Placement.resolve(fixture, row) == nil, "Wrong supporting mesh accepted")
        support:SetAttribute("SourceMeshSHA256", anchor.mesh_sha256)
        support.Size *= Vector3.new(1, 1.1, 1)
        assert(Placement.resolve(fixture, row) == nil, "Nonuniform scale accepted")
    end, debug.traceback)
    fixture:Destroy()
    assert(ok, message)
    return "Transformed/scaled image gap is 0.025 studs; stale sources and nonuniform scale fail closed"
end)

local failures = 0
for _, result in results do
    if not result.passed then
        failures += 1
    end
end
return {
    suite = "Rendered mesh graffiti attachment",
    tests = #results,
    failures = failures,
    results = results,
}
