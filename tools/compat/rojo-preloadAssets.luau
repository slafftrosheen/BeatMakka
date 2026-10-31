-- Local compatibility fix for Rojo 7.7.0; see https://github.com/rojo-rbx/rojo/pull/1344.
local ContentProvider = game:GetService("ContentProvider")

local Packages = script.Parent.Parent.Packages
local Log = require(Packages.Log)

local Assets = require(script.Parent.Assets)

local gatherAssetUrlsRecursive
function gatherAssetUrlsRecursive(currentTable, content, temporarySounds, isSound)
    for key, value in currentTable do
        if typeof(value) == "string" then
            if isSound then
                local sound = Instance.new("Sound")
                sound.SoundId = value
                table.insert(temporarySounds, sound)
                table.insert(content, sound)
            else
                table.insert(content, value)
            end
        elseif typeof(value) == "table" then
            gatherAssetUrlsRecursive(value, content, temporarySounds, isSound or key == "Sounds")
        end
    end
end

local function preloadAssets()
    local content = {}
    local temporarySounds = {}
    gatherAssetUrlsRecursive(Assets, content, temporarySounds, false)

    Log.trace("Preloading assets: {:?}", content)

    coroutine.wrap(function()
        local ok, problem = pcall(function()
            ContentProvider:PreloadAsync(content)
        end)
        for _, sound in temporarySounds do
            sound:Destroy()
        end
        if not ok then
            error(problem, 0)
        end
    end)()
end

return preloadAssets
