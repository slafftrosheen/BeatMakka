-- Explicit Studio Client; controlled clocks test logical transitions, not acoustics.
return function()
    local Shared = game.ReplicatedStorage.Shared
    local Protocol = require(Shared.JamProtocol)
    local Pattern = require(Shared.Pattern)
    local Playback = require(game.Players.LocalPlayer.PlayerScripts.Client.JamPlayback)
    local player = Playback.new()
    player.probe.Name = "JamContractTiming"
    player:setMuted(true)
    local ok, result = pcall(function()
        local p = Pattern.new()
        p.assignments[1] = "style.triphop.01"
        p.rows[1][1] = true
        local snapshot = assert(Protocol.capture(p, {}))
        local s = {
            generation = 1,
            revision = 1,
            active = true,
            session = {
                generation = 1,
                revision = 1,
                bpm = 120,
                anchor = 10,
                pack = "triphop",
                pending = {},
                tracks = {
                    ["1"] = { ownerUserId = 101, version = 1, snapshot = snapshot, sinceAt = 10 },
                },
            },
        }
        player:accept(s, 9)
        player:step(10.01)
        assert(
            player.lateDeferrals == 0 and player.tracks[1].absolute == 0,
            "Early preparation deferred"
        )
        local nextState = table.clone(s)
        nextState.revision = 2
        nextState.session = table.clone(s.session)
        nextState.session.pending = { ["1"] = { snapshot = snapshot, version = 2, applyAt = 12 } }
        player:accept(nextState, 11)
        player:step(12.91)
        assert(player.missedSteps == 7, "Boundary stall vanished from report")
        assert(player.tracks[1].absolute == 23, "Catch-up burst or incorrect clock")
        local packets = player.packets
        player:accept(s, 13)
        assert(player.packets == packets and player.revision == 2, "Stale renderer state accepted")
        local late = table.clone(s)
        late.generation = 2
        late.revision = 1
        late.session = table.clone(s.session)
        late.session.generation = 2
        player:accept(late, 14.2)
        player:step(14.2)
        assert(
            player.lateDeferrals == 1 and player.tracks[1].startAfter == 16,
            "Late unknown phrase started mid-bar"
        )
        local count = 0
        for _, bank in player.tracks[1].audio.banks do
            count += 1
            assert(#bank.voices == 2, "Unbounded voices")
        end
        assert(count == 1 and player.tracks[1].audio.group.Volume == 0, "Selection or mute")
        player:setMuted(false)
        assert(math.abs(player.tracks[1].audio.group.Volume - 0.05)<1e-6, "Mute restore lost headroom")
        player:accept({ generation = 2, revision = 2, active = false }, 15)
        assert(player:diagnostics().allocatedVoices == 0, "Leave retained banks")
        return {
            passed = true,
            boundaryStallCounted = true,
            staleIgnored = true,
            latePhraseDeferred = true,
            voiceAndMuteBound = true,
            leaveCleanup = true,
        }
    end)
    player:destroy()
    assert(ok, result)
    return result
end
