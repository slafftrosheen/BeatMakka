-- Run in Studio Server through MCP. Private tables only: no active profile,
-- audio binding, upload, storage request or player progress is changed.
local Shared = game.ReplicatedStorage.Shared
local Server = game.ServerScriptService.Server
local Profiles = require(Server.ProfileStore)
local Workspace = require(Server.MusicWorkspace)
local Finished = require(Shared.FinishedSong)
local Transport = require(Shared.MusicTransport)
local Catalog = require(Shared.SampleCatalog)
local results = {}
local function check(name, action)
    local ok, detail = xpcall(action, debug.traceback)
    table.insert(results, { name = name, passed = ok, detail = tostring(detail or "ok") })
end
local function command(p, action, a, b)
    local ok, problem, detail = Workspace.command(nil, p, action, a, b, function()
        error("Private transport fixture must never persist")
    end, function() end)
    assert(ok, action .. ": " .. tostring(problem))
    return detail
end
local function fresh()
    local p = Profiles.new()
    p.ready = true
    Workspace.sync(p)
    return p
end
local function count(p, pad, trackId)
    local found = 0
    for _, event in p.transport.schedule.events do
        if (not pad or event.pad == pad) and (not trackId or event.trackId == trackId) then
            found += 1
        end
    end
    return found
end
check("schedule lookup preserves half-open bounds and seeks past elapsed notes", function()
    local source = {}
    for index = 1, 65536 do
        source[index] = { at = math.floor((index - 1) / 2), eventId = tostring(index) }
    end
    local found = Transport.eventsBetween({ events = source }, 32766, 32767)
    assert(
        #found == 2 and found[1] == source[65533] and found[2] == source[65534],
        "Boundary mismatch"
    )
    assert(
        #Transport.eventsBetween({ events = source }, 32768, 32769) == 0,
        "Past-end lookup returned notes"
    )
    assert(
        #Transport.eventsBetween({ events = source }, 100, 100) == 0,
        "Empty window returned notes"
    )
    assert(#Transport.eventsBetween({ events = {} }, 0, 1) == 0, "Empty schedule returned notes")
    return "65,536 sorted events retain duplicate-time and exclusive-end semantics"
end)
check("live add, toggle removal and event removal replace the personal schedule", function()
    local p = fresh()
    command(p, "Step", 1, 1)
    command(p, "PlayStart")
    local anchor, epoch = p.transport.startedAt, p.epoch
    command(p, "Step", 17, 2)
    assert(count(p) == 2 and count(p, 17) == 1, "Live step was not scheduled")
    assert(
        p.epoch == epoch and p.transport.epoch == epoch,
        "Adding a note cancelled existing tails"
    )
    assert(
        (p.transport.scheduleRevision or 0) > 0,
        "Live note did not advance the schedule revision"
    )
    assert(p.transport.startedAt == anchor, "Live edit restarted the loop")
    assert(type(p.transport.scheduleChangedAt) == "number", "Missing consumption floor")
    command(p, "Step", 17, 2)
    assert(count(p, 17) == 0, "Toggled-off note stayed in the schedule")
    assert(p.epoch > epoch, "Removing a note did not cancel the old voices/input epoch")
    local eventId = p.music.project.sequences[p.sequenceId].trackEvents[p.trackId][1].eventId
    command(p, "EventRemove", { eventId = eventId })
    assert(count(p) == 0 and p.playing, "Removed note stayed audible or stopped the loop")
    command(p, "EventPut", { pad = 33, tick = 960, velocity = 91 })
    assert(count(p, 33) == 1, "New event did not enter the active schedule")
    return "Live additions preserve tails; erasure cancels voices at the existing loop anchor"
end)
check(
    "live knobs, source, mixer and kit edits update future triggers without restarting",
    function()
        local p = fresh()
        command(p, "Step", 1, 1)
        command(p, "PlayStart")
        local anchor, epoch, active = p.transport.startedAt, p.epoch, p.sequenceId
        local firstTrack, originalProgram = p.trackId, p.music.project.tracks[p.trackId].programId
        command(p, "PadSound", 1, { key = "pitch", value = 7 })
        command(p, "PadSound", 1, { key = "echo", value = 0.3 })
        assert(
            p.transport.schedule.events[1].settings.pitch == 7
                and p.transport.schedule.events[1].settings.echo == 0.3,
            "Knob edits remained pinned in the live schedule"
        )
        command(p, "Assign", 1, Catalog.List[17].id)
        assert(
            p.transport.schedule.events[1].sampleId == Catalog.List[17].id,
            "Source edit stayed pinned"
        )
        command(p, "TrackMix", { mix = { gain = 0.5, pan = -0.4 } })
        local event = p.transport.schedule.events[1]
        assert(event.settings.gain == 0.5 and event.mix.pan == -0.4, "Mixer edits stayed pinned")
        command(p, "TrackMute", { muted = true })
        assert(count(p) == 0, "Muted track still schedules future triggers")
        command(p, "TrackMute", { muted = false })
        assert(count(p) == 1, "Unmuted track did not return to the live schedule")
        command(p, "TrackNew", { name = "Silent solo bus" })
        command(p, "TrackSolo", { solo = true })
        assert(count(p) == 0, "Soloing a silent track did not suppress other tracks")
        command(p, "TrackSolo", { solo = false })
        command(p, "TrackSelect", firstTrack)
        command(p, "ProgramDuplicate")
        assert(
            p.transport.schedule.events[1].programId ~= originalProgram,
            "Kit copy did not reroute playback"
        )
        command(p, "TrackProgram", { programId = originalProgram })
        assert(
            p.transport.schedule.events[1].programId == originalProgram,
            "Kit routing stayed pinned"
        )
        command(p, "Kit", Catalog.LocalPack.id)
        assert(
            p.transport.schedule.events[1].sampleId == Catalog.List[1].id,
            "Kit load stayed pinned"
        )
        command(p, "SequenceNew", { name = "Independent editor selection" })
        command(p, "PadSound", 1, { key = "reverb", value = 0.4 })
        assert(
            p.transport.ref.id == active and p.transport.schedule.events[1].settings.reverb == 0.4,
            "Shared instrument edit replaced the playing sequence or failed to update it"
        )
        assert(
            p.epoch == epoch and p.transport.startedAt == anchor,
            "Sound edits restarted/cancelled the loop"
        )
        assert(
            (p.transport.scheduleRevision or 0) >= 10,
            "Sound edits did not publish schedule revisions"
        )
        return "Future triggers receive current FX, source and mixer; existing voices retain their tails"
    end
)
check(
    "pad clear, legacy track clear and explicit whole-sequence clear retain their scope",
    function()
        local p = fresh()
        local firstTrack = p.trackId
        command(p, "Step", 1, 1)
        command(p, "Step", 2, 2)
        command(p, "TrackNew", { name = "Second track" })
        local secondTrack = p.trackId
        command(p, "Step", 1, 3)
        command(p, "PlayStart")
        command(p, "TrackSelect", firstTrack)
        command(p, "ClearPad", 1)
        assert(count(p, 1, firstTrack) == 0, "Cleared lane kept playing")
        assert(count(p, 2, firstTrack) == 1, "Lane clear removed a different pad")
        assert(count(p, 1, secondTrack) == 1, "Lane clear removed another track")
        command(p, "SequenceClear", {})
        assert(count(p, nil, firstTrack) == 0, "Track clear kept its notes")
        assert(count(p, nil, secondTrack) == 1, "Legacy track clear erased another track")
        command(p, "SequenceClear", { scope = "sequence" })
        assert(count(p) == 0, "Whole-sequence clear kept another track audible")
        for _, events in p.music.project.sequences[p.sequenceId].trackEvents do
            assert(#events == 0, "Whole-sequence source was not cleared")
        end
        return "Pad, track and whole-sequence erasure match their visible controls"
    end
)
check("deleting a playing or paused sequence invalidates its resume snapshot", function()
    for _, paused in { false, true } do
        local p = fresh()
        command(p, "Step", 1, 1)
        local deleted = p.sequenceId
        command(p, "PlayStart")
        if paused then
            command(p, "Play")
        end
        command(p, "SequenceNew", { name = "Surviving sequence" })
        local survivor, epoch = p.sequenceId, p.epoch
        command(p, "SequenceDelete", { sequenceId = deleted })
        assert(not p.playing and not p.recording and p.transport == nil, "Deleted loop survived")
        assert(p.epoch > epoch and p.nextSequence == nil, "Deletion failed to cancel old playback")
        command(p, "Play")
        assert(
            p.transport.ref.id == survivor and count(p) == 0,
            "Play resumed the deleted snapshot"
        )
    end
    return "Neither active nor paused deleted music can restart"
end)
check("deleting a queued sequence cancels the queue without stopping the current loop", function()
    local p = fresh()
    command(p, "PlayStart")
    local active = p.transport.ref.id
    command(p, "SequenceNew", {})
    command(p, "NextSequence", p.sequenceId)
    assert(p.nextSequence ~= nil, "Fixture did not queue a sequence")
    command(p, "SequenceDelete", {})
    assert(
        p.nextSequence == nil and p.playing,
        "Deleted queued sequence survived or stopped playback"
    )
    assert(p.transport.ref.id == active, "Queue cancellation replaced the playing sequence")
end)
check(
    "recording clear removes pinned notes, rejects old taps and prevents delayed resurrection",
    function()
        local p = fresh()
        command(p, "Step", 1, 1)
        command(p, "Step", 2, 2)
        command(p, "Record")
        p.transport.startedAt = workspace:GetServerTimeNow() - 0.01
        local epoch = p.epoch
        local stale = {
            projectId = p.music.project.id,
            sequenceId = p.sequenceId,
            trackId = p.trackId,
            epoch = epoch,
            absolutePad = 17,
            requestId = "transport_lifetime_old",
            at = workspace:GetServerTimeNow(),
        }
        p.noteDeltas = { { event = { eventId = "old_delayed_note" } } }
        command(p, "PadSound", 17, { key = "pitch", value = 7 })
        command(p, "ClearPad", 1)
        assert(
            p.recording and p.transport.recording and p.epoch > epoch,
            "Recording edit lost state"
        )
        assert(#p.noteDeltas == 0, "Full edit retained a delayed pre-clear note delta")
        assert(
            not Workspace.command(nil, p, "Tap", 17, stale, function() end, function() end),
            "Pre-clear input was accepted after cancellation"
        )
        stale.epoch = p.epoch
        stale.requestId = "transport_lifetime_current"
        stale.at = workspace:GetServerTimeNow()
        local detail = command(p, "Tap", 17, stale)
        assert(detail.transportEpoch == p.epoch, "Delta lost its recording epoch")
        assert(count(p, 1) == 0 and count(p, 17) == 1, "New tap resurrected a cleared pinned note")
        local pinned = p.transport.recordProject
        local program = pinned.programs[pinned.tracks[p.trackId].programId]
        assert(
            program.pads["17"].settings.pitch == 0,
            "Recording lost its pinned instrument settings"
        )
        command(p, "TrackNew", { name = "Live overdub edit track" })
        command(p, "Step", 33, 3)
        assert(count(p, 33, p.trackId) == 1, "New track could not join the recorded sequence")
        local schedule = p.transport.schedule
        command(p, "PadSound", 33, { key = "echo", value = 0.3 })
        command(p, "TrackMix", { mix = { gain = 0.5 } })
        assert(
            p.transport.schedule == schedule,
            "Recording sound dependencies stopped being pinned"
        )
        command(p, "Record")
        command(p, "PadSound", 33, { key = "echo", value = 0.4 })
        for _, event in p.transport.schedule.events do
            if event.pad == 33 and event.trackId == p.trackId then
                assert(
                    event.settings.echo == 0.4 and event.settings.gain == 0.5,
                    "Stopping recording did not restore live sound/mixer editing"
                )
            end
        end
        return "Clear survives subsequent overdub; old input and pending deltas cannot restore it"
    end
)
check("undo and redo update the live loop instead of keeping stale notes", function()
    local p = fresh()
    command(p, "PlayStart")
    command(p, "Step", 1, 1)
    assert(count(p) == 1, "Step fixture did not enter live playback")
    command(p, "Undo")
    assert(count(p) == 0 and p.playing, "Undo left the removed note playing")
    command(p, "Redo")
    assert(count(p) == 1 and p.playing, "Redo did not restore live playback")
end)
check("song and Finished Song performances retain immutable captured notes", function()
    local p = fresh()
    command(p, "Step", 1, 1)
    command(p, "SongNew", {})
    command(p, "SongStepInsert", { sequenceId = p.sequenceId })
    local project = p.music.project
    local song, problem = Finished.capture(
        project,
        p.draftId,
        project.drafts[p.draftId].revision,
        project.revision,
        { id = "lifetime_finished", requestId = "private_lifetime", title = "Private fixture" },
        function()
            return true
        end
    )
    assert(song, problem)
    command(p, "SongPlay")
    local schedule, epoch = p.transport.schedule, p.epoch
    command(p, "PadSound", 1, { key = "echo", value = 0.3 })
    assert(p.transport.schedule == schedule, "Knob edit mutated the immutable song performance")
    command(p, "SequenceClear", { scope = "sequence" })
    assert(p.transport.schedule == schedule and count(p) == 1, "Editor clear mutated song playback")
    assert(p.epoch == epoch, "Editor clear cancelled the immutable song performance")
    p.music.finishedSongs[song.id] = song
    table.insert(p.music.finishedOrder, song.id)
    p.selectedFinishedSongId = song.id
    command(p, "FinishedPlay")
    schedule, epoch = p.transport.schedule, p.epoch
    command(p, "Step", 2, 2)
    command(p, "SequenceClear", { scope = "sequence" })
    assert(
        p.transport.schedule == schedule and count(p) == 1,
        "Editor changed Finished Song playback"
    )
    assert(p.epoch == epoch, "Editor clear cancelled the Finished Song performance")
    assert(
        #song.project.sequences[p.sequenceId].trackEvents[p.trackId] == 1,
        "Finished Song source snapshot was mutated"
    )
    return "Editing remains independent of immutable song/performance and saved-revision snapshots"
end)
local passed = 0
for _, result in results do
    passed += if result.passed then 1 else 0
end
return { passed = passed, failed = #results - passed, checks = results }
