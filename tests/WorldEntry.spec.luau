-- Explicit Studio world smoke check; uses the running world, not an isolated unit fixture.
return function()
    local root = assert(workspace:FindFirstChild("NeedleQuay"), "World not initialized")
    local stations = 0
    for _, object in root:GetDescendants() do
        if object:IsA("ProximityPrompt") and object.Parent.Name == "Interaction" then
            stations += 1
            assert(not object.RequiresLineOfSight, "Sampler art occludes entry prompt")
            assert(object.MaxActivationDistance <= 11, "Sampler prompt proximity widened")
        end
    end
    assert(stations == 2, "Expected two sampler entries")
    local chapter = root.I05.ChapterTarget.ProximityPrompt
    assert(not chapter.RequiresLineOfSight, "Podium art occludes chapter entry")
    assert(chapter.MaxActivationDistance <= 11, "Chapter prompt proximity widened")
    return { passed = true, samplerEntries = stations, chapterEntry = true }
end
