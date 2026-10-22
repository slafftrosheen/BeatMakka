local WorldBuilder = require(script.WorldBuilder)
local MusicService = require(script.MusicService)

MusicService.start(WorldBuilder.build())
