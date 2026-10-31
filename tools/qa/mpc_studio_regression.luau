-- Run through Studio MCP execute_luau in the Server DataModel during Play.
-- Fixtures are private Lua tables: this never changes the active content catalog,
-- binds audio, or writes cloud storage. ready=true below tests snapshot semantics only.
local Shared = game.ReplicatedStorage.Shared
local Server = game.ServerScriptService.Server
local Project = require(Shared.MusicProject)
local Migration = require(Shared.LegacyMusicMigration)
local Transport = require(Shared.MusicTransport)
local Finished = require(Shared.FinishedSong)
local Profiles = require(Server.ProfileStore)
local Workspace = require(Server.MusicWorkspace)
local Catalog = require(Shared.SampleCatalog)
local player = game.Players:GetPlayers()[1]
local results = {}
local function check(name, action)
    local ok, result = xpcall(action, debug.traceback)
    table.insert(results, { name = name, passed = ok, detail = tostring(result or "ok") })
end
local function fresh()
    local p = Profiles.new()
    p.ready = true
    Workspace.sync(p)
    return p
end
local function command(p, action, a, b)
    local ok, message, detail = Workspace.command(
        player,
        p,
        action,
        a,
        b,
        function(_, profile, _, override, accepted)
            local saved = Profiles.save(player, profile, nil, override)
            if accepted then
                accepted(saved)
            end
            return saved
        end,
        function() end
    )
    assert(ok, tostring(action) .. ": " .. tostring(message))
    return detail
end
local function resolved(p, ref)
    local schedule, message = Transport.resolve(p.music.project, ref, p.music.finishedSongs, {
        includeUnavailable = true,
    })
    assert(schedule, message)
    return schedule
end
check("64 bank addresses and edits remain independent during playback", function()
    local p = fresh()
    for index, pad in { 1, 17, 33, 49 } do
        command(p, "Bank", index)
        command(p, "Step", pad, index)
        command(p, "PadSound", pad, { key = "pitch", value = index })
    end
    local seq = p.music.project.sequences[p.sequenceId]
    assert(#seq.trackEvents[p.trackId] == 4, "Expected: #seq.trackEvents[p.trackId] == 4")
    for index, pad in { 1, 17, 33, 49 } do
        assert(
            p.music.project.programs[p.music.project.tracks[p.trackId].programId].pads[tostring(pad)].settings.pitch
                == index,
            "Expected: p.music.project.programs[p.music.project.tracks[p.trackId].programId].pads[tostring(pad)].settings.pitch == index"
        )
    end
    command(p, "PlayStart")
    local epoch, anchor, sequence = p.epoch, p.startedAt, p.sequenceId
    command(p, "Bank", 1)
    assert(
        p.epoch == epoch and p.startedAt == anchor and p.sequenceId == sequence and p.playing,
        "Expected: p.epoch == epoch and p.startedAt == anchor and p.sequenceId == sequence and p.playing"
    )
    local schedule = resolved(p, { kind = "sequence", id = p.sequenceId })
    assert(#schedule.events == 4, "Expected: #schedule.events == 4")
    return "A01/B01/C01/D01 events and settings retained; bank switch preserved epoch and anchor"
end)
check("fifth sequence, independent variation, multibar edits and undo/redo", function()
    local p = fresh()
    command(p, "Step", 33, 3)
    local original = p.sequenceId
    command(p, "SequenceDuplicate", { name = "Variation" })
    local variation = p.sequenceId
    command(p, "Step", 49, 5)
    assert(
        #p.music.project.sequences[original].trackEvents[p.trackId] == 1,
        "Expected: #p.music.project.sequences[original].trackEvents[p.trackId] == 1"
    )
    assert(
        #p.music.project.sequences[variation].trackEvents[p.trackId] == 2,
        "Expected: #p.music.project.sequences[variation].trackEvents[p.trackId] == 2"
    )
    for index = 3, 5 do
        command(p, "SequenceNew", { name = "Section " .. index, bars = 2 })
    end
    assert(#p.music.project.sequenceOrder == 5, "Expected: #p.music.project.sequenceOrder == 5")
    command(p, "Bar", 2)
    command(p, "Step", 17, 16)
    local seq = p.music.project.sequences[p.sequenceId]
    assert(
        seq.trackEvents[p.trackId][1].tick == 7440,
        "Expected: seq.trackEvents[p.trackId][1].tick == 7440"
    )
    command(p, "Undo")
    assert(
        #(p.music.project.sequences[p.sequenceId].trackEvents[p.trackId] or {}) == 0,
        "Expected: #(p.music.project.sequences[p.sequenceId].trackEvents[p.trackId] or {}) == 0"
    )
    command(p, "Redo")
    assert(
        #p.music.project.sequences[p.sequenceId].trackEvents[p.trackId] == 1,
        "Expected: #p.music.project.sequences[p.sequenceId].trackEvents[p.trackId] == 1"
    )
    return "Five sequences; tick 7440 retained on bar two; variation and history independent"
end)
check("delayed recording preserves absolute identity and pinned dependencies", function()
    local p = fresh()
    command(p, "TimingCorrect", 0)
    command(p, "Velocity", 73)
    command(p, "Record")
    task.wait(0.18)
    local t = p.transport
    local sequenceId, trackId, epoch = p.sequenceId, p.trackId, p.epoch
    command(p, "Bank", 2)
    local input = {
        projectId = p.music.project.id,
        sequenceId = sequenceId,
        trackId = trackId,
        epoch = epoch,
        absolutePad = 17,
        requestId = "qa-note-1",
        at = workspace:GetServerTimeNow(),
    }
    command(p, "Bank", 4)
    local detail = command(p, "Tap", 17, input)
    assert(
        detail.event.pad == 17 and detail.event.velocity == 73,
        "Expected: detail.event.pad == 17 and detail.event.velocity == 73"
    )
    assert(
        t.recordProject.sequences[sequenceId].trackEvents[trackId][1].eventId
            == detail.event.eventId,
        "Expected: t.recordProject.sequences[sequenceId].trackEvents[trackId][1].eventId == detail.event.eventId"
    )
    local duplicate = Workspace.command(player, p, "Tap", 17, input, function() end, function() end)
    assert(not duplicate, "Expected: not duplicate")
    command(p, "SequenceNew", { name = "Editor change consumes an ID" })
    command(p, "PadSound", 17, { key = "pitch", value = 7 })
    input.requestId = "qa-note-2"
    input.at = workspace:GetServerTimeNow()
    local added = command(p, "Tap", 17, input)
    local pinned = t.recordProject
    local program = pinned.programs[pinned.tracks[trackId].programId]
    assert(
        program.pads["17"].settings.pitch == 0,
        'Expected: program.pads["17"].settings.pitch == 0'
    )
    local found = false
    for _, event in pinned.sequences[sequenceId].trackEvents[trackId] do
        found = found or event.eventId == added.event.eventId
    end
    assert(found, "Recorded event IDs diverged")
    input.requestId = "qa-stale"
    input.epoch = epoch - 1
    assert(
        not Workspace.command(player, p, "Tap", 17, input, function() end, function() end),
        'Expected: not Workspace.command(player, p, "Tap", 17, input, function() end, function() end)'
    )
    return "Delayed B01 stayed B01 after bank D; velocity, request dedupe, stale epoch and pinned kit verified"
end)
local function songFixture()
    local p = fresh()
    command(p, "SequenceRename", { name = "Intro" })
    command(p, "SequenceLength", { bars = 1 })
    command(p, "Bpm", 120)
    command(p, "Step", 1, 1)
    local intro = p.sequenceId
    command(p, "SequenceNew", { name = "Main", bars = 2, bpm = 60 })
    command(p, "Step", 33, 5)
    local main = p.sequenceId
    command(p, "SongNew", { name = "QA Song" })
    command(p, "SongStepInsert", { sequenceId = intro, repeats = 1 })
    command(p, "SongStepInsert", { sequenceId = main, repeats = 1 })
    return p, intro, main
end
check("Song Mode repeat edits preserve references and real tempo duration", function()
    local p, intro, main = songFixture()
    local draft = p.music.project.drafts[p.draftId]
    local mainStep = draft.steps[2].stepId
    command(p, "SequenceSelect", intro)
    command(p, "SongStepUpdate", { stepId = mainStep, repeats = 2 })
    draft = p.music.project.drafts[p.draftId]
    assert(
        draft.steps[2].sequenceId == main and draft.steps[2].repeats == 2,
        "Expected: draft.steps[2].sequenceId == main and draft.steps[2].repeats == 2"
    )
    local sequenceTempo = resolved(p, { kind = "song", id = p.draftId })
    assert(
        sequenceTempo.totalBars == 5 and math.abs(sequenceTempo.duration - 18) < 1e-6,
        "Expected: sequenceTempo.totalBars == 5 and math.abs(sequenceTempo.duration - 18) < 1e-6"
    )
    command(p, "SongTempo", { tempoMode = "song", bpm = 120 })
    local songTempo = resolved(p, { kind = "song", id = p.draftId })
    assert(
        math.abs(songTempo.duration - 10) < 1e-6,
        "Expected: math.abs(songTempo.duration - 10) < 1e-6"
    )
    command(p, "SongStepDuplicate", { stepId = mainStep, index = 3 })
    command(p, "SongStepMove", { stepId = mainStep, index = 1 })
    command(p, "Undo")
    assert(
        p.music.project.drafts[p.draftId].steps[2].stepId == mainStep,
        "Expected: p.music.project.drafts[p.draftId].steps[2].stepId == mainStep"
    )
    return "5 bars; 18 seconds at sequence tempos, 10 seconds at Song 120 BPM; step references stable"
end)
check("Song playback seeks by step, pins edits, ends and clears old queue", function()
    local p, intro, main = songFixture()
    command(p, "SongTempo", { tempoMode = "song", bpm = 180 })
    local draft = p.music.project.drafts[p.draftId]
    command(p, "SongStepUpdate", { stepId = draft.steps[1].stepId, repeats = 2 })
    command(p, "SequenceSelect", intro)
    command(p, "PlayStart")
    command(p, "NextSequence", main)
    command(p, "Stop")
    assert(p.nextSequence == nil, "Expected: p.nextSequence == nil")
    command(p, "SongPlay")
    assert(
        not p.transport.loop and p.nextSequence == nil,
        "Expected: not p.transport.loop and p.nextSequence == nil"
    )
    local duration = p.transport.schedule.duration
    command(p, "SequenceTempo", { bpm = 90 })
    assert(
        p.transport.schedule.duration == duration,
        "Expected: p.transport.schedule.duration == duration"
    )
    command(p, "SongSeek", 2)
    assert(
        math.abs(p.transport.offset - 8 / 3) < 1e-6,
        "Audition selected a repeat rather than the selected song step"
    )
    p.transport.startedAt = workspace:GetServerTimeNow() - p.transport.schedule.completeAt - 1
    assert(Workspace.tick(p) and not p.playing, "Expected: Workspace.tick(p) and not p.playing")
    return "Finite end and two-second tail; step audition and snapshot isolation verified"
end)
check("Play resumes the paused song instead of the selected sequence", function()
    local p = songFixture()
    command(p, "SongPlay")
    task.wait(0.2)
    command(p, "Play")
    local kind, id, offset = p.transport.ref.kind, p.transport.ref.id, p.transport.offset
    assert(kind == "song" and not p.playing, 'Expected: kind == "song" and not p.playing')
    command(p, "Play")
    assert(
        p.transport.ref.kind == kind and p.transport.ref.id == id,
        "Resume replaced the paused song with the editor sequence"
    )
    assert(p.transport.offset == offset and p.playing, "Resume lost the paused cursor")
    return "Paused song reference, snapshot and cursor retained across Play"
end)
check("saved revisions, failed storage, pending finish and immutable fixture capture", function()
    local p = songFixture()
    local ok, message = Profiles.save(player, p)
    assert(ok, message)
    for _, seq in p.music.project.sequences do
        assert(seq.savedRevision == seq.revision, "Expected: seq.savedRevision == seq.revision")
    end
    for _, draft in p.music.project.drafts do
        assert(
            draft.savedRevision == draft.revision,
            "Expected: draft.savedRevision == draft.revision"
        )
    end
    local saved = p.saved
    command(p, "Step", 49, 7)
    local fail = Profiles.save(player, p, {
        UpdateAsync = function()
            error("qa injected storage outage")
        end,
    })
    assert(
        not fail and p.saved == saved and not p.saving,
        "Expected: not fail and p.saved == saved and not p.saving"
    )
    local before = #p.music.finishedOrder
    local draft = p.music.project.drafts[p.draftId]
    local accepted = Workspace.command(
        player,
        p,
        "SongFinish",
        {
            requestId = "qa-pending",
            projectRevision = p.music.project.revision,
            draftRevision = draft.revision,
        },
        nil,
        function()
            error("pending content must not reach storage")
        end,
        function() end
    )
    assert(
        not accepted and #p.music.finishedOrder == before,
        "Expected: not accepted and #p.music.finishedOrder == before"
    )
    local snapshot, problem = Finished.capture(
        p.music.project,
        p.draftId,
        draft.revision,
        p.music.project.revision,
        { id = "qa-fixture-song", requestId = "qa-synthetic-readiness" },
        function()
            return true
        end
    )
    assert(snapshot, problem)
    local old = snapshot.project.sequences[p.sequenceId].bpm
    command(p, "Bpm", 174)
    assert(
        snapshot.project.sequences[p.sequenceId].bpm == old,
        "Expected: snapshot.project.sequences[p.sequenceId].bpm == old"
    )
    assert(
        not Catalog.isReady("nq.harbour.v1.a01"),
        'Expected: not Catalog.isReady("nq.harbour.v1.a01")'
    )
    return "Session save accepted, outage retained previous save; pending finish refused; synthetic snapshot stayed immutable"
end)
check("conversion retains arrangement and refuses multi-tempo flattening", function()
    local p = songFixture()
    local count = #p.music.project.sequenceOrder
    local refused = Workspace.command(
        player,
        p,
        "SongConvert",
        {},
        nil,
        function() end,
        function() end
    )
    assert(
        not refused and #p.music.project.sequenceOrder == count,
        "Expected: not refused and #p.music.project.sequenceOrder == count"
    )
    command(p, "SongTempo", { tempoMode = "song", bpm = 120 })
    local original = Project.clone(p.music.project.drafts[p.draftId])
    command(p, "SongConvert", {})
    assert(
        #p.music.project.sequenceOrder == count + 1
            and p.music.project.sequences[p.sequenceId].bars == 3,
        "Expected: #p.music.project.sequenceOrder == count + 1 and p.music.project.sequences[p.sequenceId].bars == 3"
    )
    assert(
        #p.music.project.drafts[p.draftId].steps == #original.steps,
        "Expected: #p.music.project.drafts[p.draftId].steps == #original.steps"
    )
    return "Single-tempo conversion created a 3-bar editable sequence; mixed-tempo source refused without truncation"
end)
check("four working patterns and all six shelf bundles survive migration", function()
    local function pattern(bpm, id)
        local value = { bpm = bpm, rows = {}, assignments = {}, sounds = {}, muted = {} }
        for pad = 1, 16 do
            value.rows[pad] = table.create(16, false)
            value.assignments[pad] = id
            value.muted[pad] = pad == 2
        end
        value.rows[1][1] = true
        value.rows[2][5] = true
        return value
    end
    local raw = { schema = 2, activeSlot = 3, slots = {}, shelf = {} }
    for slot = 1, 4 do
        raw.slots[slot] = pattern(90 + slot, "kick")
    end
    for shelf = 1, 6 do
        raw.shelf[shelf] = { version = shelf, activeSlot = 2, slots = {} }
        for slot = 1, 4 do
            raw.shelf[shelf].slots[slot] = pattern(100 + shelf + slot, "style.techno.01")
        end
    end
    local music, problem = Migration.import(raw)
    assert(music, problem)
    assert(
        #music.project.sequenceOrder == 4 and #music.archiveOrder == 6 and #music.finishedOrder == 0,
        "Expected: #music.project.sequenceOrder == 4 and #music.archiveOrder == 6 and #music.finishedOrder == 0"
    )
    for _, id in music.archiveOrder do
        local archive = music.archives[id]
        assert(
            #archive.project.sequenceOrder == 4 and archive.preimage ~= nil,
            "Expected: #archive.project.sequenceOrder == 4 and archive.preimage ~= nil"
        )
        local seq = archive.project.sequences[archive.project.sequenceOrder[1]]
        local track = archive.project.trackOrder[1]
        assert(
            #seq.trackEvents[track] == 2 and seq.trackPadMutes[track]["2"] == true,
            'Expected: #seq.trackEvents[track] == 2 and seq.trackPadMutes[track]["2"] == true'
        )
    end
    local retry = Migration.import({ schema = 3, music = music })
    assert(
        retry and #retry.archiveOrder == 6 and #retry.project.sequenceOrder == 4,
        "Expected: retry and #retry.archiveOrder == 6 and #retry.project.sequenceOrder == 4"
    )
    return "4 working + 24 shelf sequences; muted notes, retired identities, tempos and raw preimages retained; retry idempotent"
end)
local failures = 0
for _, result in results do
    if not result.passed then
        failures += 1
    end
end
return {
    suite = "MPC Studio regression",
    tests = #results,
    failures = failures,
    results = results,
    audio = "Pending; synthetic readiness only used for isolated snapshot fixture",
    cloudWrites = 0,
}
