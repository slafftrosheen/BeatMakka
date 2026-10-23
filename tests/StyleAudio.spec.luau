-- Explicit Client resource/lifecycle check; uses unconfigured IDs, no cloud audio.
return function()
    local client = game.Players.LocalPlayer.PlayerScripts.Client
    local Catalog = require(game.ReplicatedStorage.Shared.SampleCatalog)
    local Audio = require(client.AudioEngine)
    local engine = Audio.new("StyleAudioQA", { musicOnly = true })
    local ok, result = pcall(function()
        for _, pack in Catalog.Packs do
            local assignments = {}
            for pad = 1, 16 do
                assignments[pad] = pack.samples[pad].id
            end
            engine:setSelection(assignments)
            local count = 0
            for _ in engine.banks do
                count += 1
            end
            assert(count <= 19, "Loading all styles multiplied active banks")
            for _, id in assignments do
                assert(engine.banks[id], "Assigned bank missing")
            end
        end
        local last = Catalog.Packs[#Catalog.Packs].samples[1].id
        local old = engine.banks[last]
        local voice = Instance.new("Sound")
        table.insert(old.voices, voice)
        engine:setSelection({})
        assert(not pcall(function()
            voice.Parent = game.SoundService
        end), "Evicted voice survived")
        engine:_setState(old, "ready")
        assert(old.state ~= "ready", "Late load revived an evicted bank")
        local assignments = {}
        for pad = 1, 16 do
            assignments[pad] = Catalog.Packs[11].samples[pad].id
        end
        engine:setSelection(assignments)
        local replacement = engine.banks[last]
        engine:_setState(old, "ready")
        assert(
            replacement ~= old and replacement.state ~= "ready",
            "Old callback changed a replacement bank"
        )
        engine:destroy()
        engine:setSelection({})
        assert(next(engine.banks) == nil, "Destroyed engine allocated banks")
        return {
            passed = true,
            packs = 11,
            maxMusicBanks = 19,
            eviction = true,
            lateLoadRejected = true,
            teardown = true,
        }
    end)
    engine:destroy()
    assert(ok, result)
    return result
end
