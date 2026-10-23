-- Client check of the authored real-ID library shipped by default.project.json.
return function()
    local storage = game.ReplicatedStorage
    local library = storage:FindFirstChild("AppearanceLibrary")
    assert(library, "Fresh build is missing the authored material library")
    local Appearance = require(game.Players.LocalPlayer.PlayerScripts.Client.DeviceAppearance)
    local ids = require(storage.Shared.ContentIds).Images
    local renderer = Appearance.new()
    local ok, result = pcall(function()
        local count = 0
        for _, finish in { "quay", "chalk", "coral", "afterhours" } do
            for _, size in { 512, 1024 } do
                local template = renderer:template(finish, size)
                assert(
                    template == library:FindFirstChild(finish .. "_" .. size),
                    "Authored template was not reused"
                )
                for property, key in
                    {
                        ColorMapContent = "atlas." .. finish .. ".basecolor." .. size,
                        RoughnessMapContent = "atlas.roughness." .. size,
                        MetalnessMapContent = "atlas.metalness." .. size,
                    }
                do
                    assert(
                        template[property].Uri == "rbxassetid://" .. ids[key],
                        "Wrong real map: " .. key
                    )
                end
                count += 1
            end
        end
        -- A missing authored library must not call the editable-image-only API
        -- with asset URIs, or require runtime PluginSecurity writes.
        library.Parent = nil
        local missing = Appearance.new()
        local value = missing:template("quay", 512)
        local pending = next(missing.pending)
        missing:destroy()
        library.Parent = storage
        assert(
            value == nil and pending == nil,
            "Missing library attempted unsupported runtime creation"
        )
        renderer:destroy()
        assert(#library:GetChildren() == 8, "Teardown destroyed borrowed templates")
        return {
            passed = true,
            authoredTemplates = count,
            realIds = true,
            noUnsupportedFallback = true,
        }
    end)
    renderer:destroy()
    if library.Parent == nil then
        library.Parent = storage
    end
    assert(ok, result)
    return result
end
