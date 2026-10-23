-- Opt-in Client acceptance against real owner-uploaded audio. Muted at SoundGroup.
-- Does not establish audible balance or permissions in a published experience.
return function()
    local Shared = game.ReplicatedStorage.Shared
    local Catalog = require(Shared.SampleCatalog)
    local Ids = require(Shared.ContentIds)
    local Audio = require(game.Players.LocalPlayer.PlayerScripts.Client.AudioEngine)
    local engine = Audio.new("UploadedStyleAudioQA", { musicOnly = true })
    engine.group.Volume = 0
    local ok, result = pcall(function()
        local results, total, submissions = {}, 0, 0
        for _, pack in Catalog.Packs do
            if pack.id == "quay" then
                continue
            end
            local assignments, expected = {}, 0
            for pad = 1, 16 do
                local id = pack.samples[pad].id
                assignments[pad] = id
                if Ids.Audio[id] then
                    expected += 1
                end
            end
            engine:setSelection(assignments)
            local deadline = os.clock() + 20
            local ready = 0
            repeat
                ready = 0
                for _, id in assignments do
                    if engine.banks[id].state == "ready" then
                        ready += 1
                    end
                end
                if ready < expected then
                    task.wait(0.05)
                end
            until ready == expected or os.clock() > deadline
            assert(ready == expected, "Uploaded bank did not become ready: " .. pack.id)
            local banks, voices = 0, 0
            for _, bank in engine.banks do
                banks += 1
                voices += #bank.voices
            end
            assert(banks <= 19 and voices <= 76, "Kit selection exceeded resource bounds")
            for _, id in assignments do
                local bank = engine.banks[id]
                if Ids.Audio[id] then
                    for _ = 1, 6 do
                        assert(engine:play(id), "Ready pad refused rapid strike")
                        submissions += 1
                    end
                    total += 1
                else
                    assert(
                        bank.state == "unconfigured" and not engine:play(id),
                        "Pending upload was reported playable"
                    )
                end
            end
            task.wait(0.05)
            engine:stop()
            for _, bank in engine.banks do
                for _, voice in bank.voices do
                    assert(not voice.IsPlaying, "Stop left a voice playing")
                end
            end
            engine:setMuted(true)
            for _, id in assignments do
                assert(not engine:play(id), "Muted pad played")
            end
            engine:setMuted(false)
            engine.group.Volume = 0
            table.insert(results, { pack = pack.id, ready = ready, pending = 16 - expected })
        end
        assert(total > 0, "No real uploads were exercised")
        engine:destroy()
        assert(
            next(engine.banks) == nil and engine.group.Parent == nil,
            "Teardown retained audio resources"
        )
        return {
            passed = true,
            uploadedPads = total,
            submissions = submissions,
            packs = results,
            muted = true,
        }
    end)
    engine:destroy()
    assert(ok, result)
    return result
end
