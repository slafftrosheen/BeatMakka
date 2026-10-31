local WorldBuilder = require(script.WorldBuilder)
local MusicService = require(script.MusicService)

local ok, importError = pcall(require(script.LocalArtLibrary).build)
if not ok then
    game.ReplicatedStorage:SetAttribute("LocalContentError", tostring(importError))
    error(importError)
end
local world = WorldBuilder.build()
require(script.NeedleQuayDemoWorld).build(world)
MusicService.start(world)
