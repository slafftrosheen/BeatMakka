-- Studio fixture: pass a factory wrapping the actual preloader body.
-- ContentProvider is replaced with an in-memory recorder; no assets are fetched.
return function(createPreload)
    local results = {}
    for _, failLoad in { false, true } do
        local requests = {}
        local assets = {
            Images = { Nested = { Icon = "rbxassetid://6012985953" } },
            Sounds = { Nested = { Notification = "rbxassetid://203785492" } },
        }
        local provider = {}
        function provider:PreloadAsync(values)
            for _, value in values do
                table.insert(requests, value)
            end
            if failLoad then
                error("Expected fixture failure")
            end
        end
        local preload = createPreload(provider, assets, { trace = function() end })
        local ok, problem = pcall(preload)
        local typed, imageUnchanged, cleaned = false, false, false
        for _, value in requests do
            if typeof(value) == "Instance" and value:IsA("Sound") then
                typed = value.SoundId == assets.Sounds.Nested.Notification
                cleaned = not pcall(function()
                    value.Parent = workspace
                end)
                value:Destroy()
            elseif value == assets.Images.Nested.Icon then
                imageUnchanged = true
            end
        end
        local propagated = if failLoad
            then not ok and tostring(problem):find("Expected fixture failure") ~= nil
            else ok
        table.insert(results, {
            failLoad = failLoad,
            typedSound = typed,
            imageUnchanged = imageUnchanged,
            cleaned = cleaned,
            failureBehaviorPreserved = propagated,
            passed = typed and imageUnchanged and cleaned and propagated,
        })
    end
    return results
end
