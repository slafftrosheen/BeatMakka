-- Opt-in Studio Server probe. Run through Studio MCP after syncing source.
-- Uses production commands, catalog readiness and the real session save path.
-- Owns isolated profiles/podiums; never changes a live player's music or uploads.
-- This verifies server lifecycles, not acoustic output or human listening approval.
return function()
    assert(game:GetService("RunService"):IsStudio(), "Local probe requires Studio")
    local Shared = game.ReplicatedStorage.Shared
    local Server = game.ServerScriptService.Server
    local Catalog = require(Shared.SampleCatalog)
    local Project = require(Shared.MusicProject)
    local Transport = require(Shared.MusicTransport)
    local Finished = require(Shared.FinishedSong)
    local Evidence = require(Shared.QuayMusicEvidence)
    local Jam = require(Shared.JamProtocol)
    local Quay = require(Shared.QuayProgress)
    local Profiles = require(Server.ProfileStore)
    local Editor = require(Server.MusicWorkspace)
    local Listening = require(Server.ListeningSession)
    local Concert = require(Server.ConcertService)
    local checks, cleanup, notices = {}, {}, {}
    local previousPublicBeat = game.Workspace:GetAttribute("QuayPublicBeat")
    local player = { UserId = -308, Name = "LocalFinishProbe", DisplayName = "LOCAL FINISH QA" }
    local listener =
        { UserId = -309, Name = "LocalListenerProbe", DisplayName = "LOCAL LISTENER QA" }
    local profile = Profiles.new()
    profile.ready, profile.unlocked = true, { I01 = true, I02 = true, I03 = true }
    assert(profile.saveMode == "session", "Probe must never use cloud storage")
    local profiles = { [player] = profile, [listener] = Profiles.new() }
    profiles[listener].ready = true
    local function expect(condition, message)
        assert(condition, message)
    end
    local function check(name, run)
        run()
        table.insert(checks, name)
    end
    local function send(_, notice)
        if notice then
            table.insert(notices, notice)
        end
    end
    local rejectSave, saves = false, 0
    local function persist(owner, p, _, override, accepted)
        local ok, message
        if rejectSave then
            ok, message = false, "Deliberately rejected local save"
        else
            ok, message = Profiles.save(owner, p, nil, override)
            saves += if ok then 1 else 0
        end
        if accepted then
            accepted(ok)
        end
        send(owner, message)
        return ok
    end
    local function command(action, a, b)
        local ok, message = Editor.command(player, profile, action, a, b, persist, send)
        expect(ok, action .. ": " .. tostring(message))
        return message
    end
    local function podium(name)
        local anchor = Instance.new("Part")
        anchor.Name, anchor.Anchored = name, true
        anchor.Position, anchor.Parent = Vector3.new(0, -1000, 0), game.Workspace
        table.insert(cleanup, anchor)
        local prompt, label = Instance.new("ProximityPrompt"), Instance.new("TextLabel")
        prompt.Parent, label.Parent = anchor, anchor
        return { anchor = anchor, prompt = prompt, label = label }
    end
    local session, concert
    local result
    local ok, problem = xpcall(function()
        check("all 64 local bindings playable without catalog admission", function()
            expect(#Catalog.List == 64, "Expected the current 64-pad kit")
            for _, sample in Catalog.List do
                expect(Catalog.isPlaybackReady(sample.id, profile.unlocked), sample.id)
                expect(not Catalog.isReady(sample.id), "Local playback must not promote admission")
                expect(not sample.audioApproved and not sample.runtimeAdmitted, "Approval changed")
            end
            expect(not Catalog.isPlaybackReady("missing_sample"), "Unknown sound became playable")
            local discovered = Catalog.discoveryFor("I01")
            expect(discovered ~= nil, "Discovery role I01 is missing")
            expect(
                Catalog.ByDiscoveryId.I01 == nil,
                "Local substitute acquired formal discovery approval"
            )
            expect(discovered.localDiscovery == "I01", "Local role substitute is not explicit")
            expect(
                Catalog.isPlaybackReady(discovered.id, {}),
                "Free local kit acquired a story lock"
            )
        end)

        local discovery = Catalog.discoveryFor("I01").absolutePad
        local ordinary
        for _, sample in Catalog.List do
            if not sample.discovery then
                ordinary = sample.absolutePad
                break
            end
        end
        expect(ordinary, "Expected an ordinary pad for layered music")
        Editor.sync(profile)
        local first = profile.sequenceId
        command("SequenceRename", { name = "Local Intro" })
        command("SequenceLength", { bars = 1 })
        command("Bpm", 180)
        command("EventPut", { pad = ordinary, tick = 0, velocity = 100 })
        command("EventPut", { pad = discovery, tick = 960, velocity = 90 })
        command("SaveSequence")
        command("SequenceNew", { name = "Local Variation", bars = 1, bpm = 180 })
        local second = profile.sequenceId
        command("EventPut", { pad = ordinary, tick = 480, velocity = 110 })
        command("EventPut", { pad = discovery, tick = 1920, velocity = 90 })
        command("SaveSequence")
        command("SongNew", { name = "Local Finished Performance", bpm = 180 })
        command("SongStepInsert", { sequenceId = first, repeats = 1 })
        command("SongStepInsert", { sequenceId = second, repeats = 1 })
        command("SongTempo", { tempoMode = "song", bpm = 180 })
        local request = {
            requestId = "local_probe_finish",
            projectRevision = profile.music.project.revision,
            draftRevision = profile.music.project.drafts[profile.draftId].revision,
        }
        check("failed save never advertises a finished revision", function()
            rejectSave = true
            command("SongFinish", request)
            expect(#profile.music.finishedOrder == 0, "Failed finish entered live library")
            expect(#profile.saved.music.finishedOrder == 0, "Failed finish entered saved library")
            expect(profile.selectedFinishedSongId == nil, "Failed finish was selected")
            rejectSave = false
        end)
        local songId, savedSong
        check("real SongFinish saves immutable local revision and deduplicates retries", function()
            command("SongFinish", request)
            expect(#profile.music.finishedOrder == 1, "Finish was not accepted")
            songId = profile.selectedFinishedSongId
            savedSong = profile.saved.music.finishedSongs[songId]
            expect(savedSong and savedSong.localOnly, "Local-only provenance was lost")
            expect(savedSong.listeningReview == "pending", "Listening approval was invented")
            local available, reason, schedule = Finished.ready(savedSong)
            expect(available, reason)
            expect(#schedule.events == 4 and #schedule.sections == 2, "Incomplete saved schedule")
            expect(schedule.localOnly and schedule.localPreview, "Local schedule scope was lost")
            command("SongFinish", request)
            expect(#profile.music.finishedOrder == 1, "Retry created duplicate Finished Song")
            command("FinishedSelect", songId)
            expect(Profiles.save(player, profile), "Selected revision did not save locally")
            expect(profile.saved.selectedFinishedSongId == songId, "Selection was not captured")
        end)
        check("finished private playback starts pauses resumes and reaches finite end", function()
            command("FinishedPlay")
            expect(profile.playing and not profile.transport.loop, "Finished Song was looped")
            expect(#profile.transport.schedule.events == 4, "Local notes were silently filtered")
            command("Play")
            expect(not profile.playing, "Pause did not stop private transport")
            local frozen = profile.transport.offset
            task.wait(0.05)
            expect(profile.transport.offset == frozen, "Paused transport moved")
            command("Play")
            expect(profile.playing, "Resume did not restart the pinned song")
            -- End boundary is deterministic; acoustic playback is probed on the client.
            profile.transport.startedAt = game.Workspace:GetServerTimeNow()
                - profile.transport.schedule.completeAt
                - 0.01
            expect(Editor.tick(profile) and not profile.playing, "Finished Song did not end")
            command("Stop")
        end)
        check("later editor changes cannot mutate saved playback or musical evidence", function()
            command("SequenceSelect", first)
            command("SequenceClear")
            expect(Finished.ready(savedSong), "Saved song depended on the mutable editor")
            local evidence, reason = Evidence.finished(profile, songId)
            expect(evidence and evidence.localOnly, reason)
            expect(#evidence.schedule.events == 4, "Saved evidence changed after clear")
            local jam, jamProblem = Jam.capture(savedSong.project, first, profile.unlocked, 180)
            expect(jam and jam.schedule.localOnly, jamProblem)
            expect(Jam.schedule(jam, 180) ~= nil, "Local jam reschedule failed")
            local missing = Project.clone(savedSong.project)
            local track = missing.tracks[missing.trackOrder[1]]
            missing.programs[track.programId].pads[tostring(ordinary)].sampleId = ""
            expect(
                Transport.resolve(
                    missing,
                    { kind = "song", id = savedSong.draftId },
                    nil,
                    { requireReady = true }
                ) == nil,
                "Missing binding was accepted for finishing"
            )
        end)
        check(
            "actual local discovery rhythms and three record lessons unlock musical route evidence",
            function()
                local metal, vent, reply =
                    Catalog.discoveryFor("I01"),
                    Catalog.discoveryFor("I02"),
                    Catalog.discoveryFor("I03")
                expect(
                    metal and vent and reply,
                    "One of the explicit local gameplay sources is missing"
                )
                expect(
                    metal.address == "A15" and vent.address == "D10" and reply.address == "D04",
                    "Local role source mapping drifted"
                )
                expect(
                    Catalog.sampleForRole("preview_kick") == Catalog.List[1].id,
                    "Pulse lesson is unavailable"
                )
                expect(
                    Catalog.sampleForRole("preview_closed_hat") == Catalog.List[9].id,
                    "Texture lesson is unavailable"
                )
                expect(
                    Catalog.sampleForRole("preview_pluck") == Catalog.List[49].id,
                    "Pitched bell lesson is unavailable"
                )
                command("SequenceSelect", first)
                for _, tick in { 0, 960, 1920, 2880 } do
                    command("EventPut", { pad = metal.absolutePad, tick = tick, velocity = 100 })
                    command("EventPut", { pad = reply.absolutePad, tick = tick, velocity = 90 })
                end
                command("EventPut", { pad = vent.absolutePad, tick = 480, velocity = 80 })
                command("SaveSequence")
                command("SaveDraft")
                local evidence = Quay.evidence(profile)
                expect(
                    evidence.metal and evidence.metalSteps == 4,
                    "Local dock rhythm does not count"
                )
                expect(evidence.reply, "Local helper bell quarter-note reply does not count")
                expect(
                    evidence.saved and evidence.variation and evidence.draft and evidence.finished,
                    "Local saved arrangement cannot satisfy the music route"
                )
                expect(
                    #Evidence.finished(profile, songId).schedule.events == 4,
                    "Local lessons changed the saved performance"
                )
            end
        )

        local court = podium("LocalFinishProbeCourt")
        local beforeStreet = {}
        for _, item in game.Workspace:GetChildren() do
            beforeStreet[item] = true
        end
        session = Listening.new(court, profiles, send, function() end, function()
            return true
        end)
        -- ListeningSession creates its own street anchor; retain it for cleanup.
        for _, item in game.Workspace:GetChildren() do
            if item.Name == "QuayStreetBusking" and not beforeStreet[item] then
                table.insert(cleanup, item)
            end
        end
        local ref = { kind = "finished", id = songId, revision = 1 }
        check(
            "local listening selection and stage preparation use accepted saved revision",
            function()
                session:command(player, "ListeningSelect", ref)
                expect(profile.listeningRef.id == songId, "Listening selection failed")
                session:openBoard(player)
                session:command(player, "StagePrepare", ref)
                expect(#session.stage.queue == 1 and not session.owner, "Prepare started audio")
                expect(session.stage.queue[1].snapshot.localOnly, "Prepared set lost local scope")
                session:command(player, "StageCancel")
                expect(
                    #session.stage.queue == 0 and not session.owner,
                    "Cancel left a prepared set"
                )
                session:command(player, "StagePrepare", ref)
                session:command(player, "StageStart")
                expect(session.owner == player, "Local stage readiness recheck rejected the song")
                expect(#session:state(player).schedule.events == 4, "Public notes were filtered")
                expect(not session.members[listener], "Listener was joined without consent")
                session.stage.opened[listener] = true
                session:command(listener, "StageJoin")
                expect(session.members[listener], "Voluntary local listening failed")
                session:command(listener, "ListeningLeave")
                expect(
                    not session.members[listener] and session.owner == player,
                    "Leave stopped owner"
                )
                session.startedAt = game.Workspace:GetServerTimeNow()
                    - session.prepared.schedule.completeAt
                    - 0.01
                session.firstLoopEndsAt = session.startedAt + session.prepared.schedule.duration
                session:tick()
                expect(not session.owner and not session:state(player), "Public song did not end")
                expect(
                    game.Workspace:GetAttribute("QuayPublicBeat") == nil,
                    "Public beat stayed active"
                )
            end
        )
        check("local stage stop cancels audio without deleting saved music", function()
            session:command(player, "StagePrepare", ref)
            session:command(player, "StageStart")
            expect(session.owner == player, "Second local set failed")
            session:command(player, "StageStop")
            expect(
                not session.owner and profile.saved.music.finishedSongs[songId],
                "Stop lost song"
            )
        end)

        local room = podium("LocalFinishProbeConcert")
        concert = Concert.new(room, profiles, send, function()
            session:depart(player)
            Editor.stop(profile, true)
        end, function()
            return true
        end, function(owner, p)
            expect(Profiles.save(owner, p), "Local performance progress save failed")
        end)
        -- Route completion is a separate gameplay gate. This probe supplies its
        -- prerequisite ledger rather than granting completion from audio readiness.
        profile.quay = Quay.sanitize(nil)
        for _, id in Quay.Order do
            profile.quay.completed[id] = true
        end
        check(
            "actual concert selection start pause resume cancel and completion stay local",
            function()
                concert:open(player)
                concert:command(player, "ChapterSelect", ref)
                concert:command(player, "ChapterStart", ref)
                local active = concert.sessions[player]
                expect(active and active.localOnly, "Local concert did not start")
                concert:command(player, "ChapterPause")
                expect(active.paused, "Concert did not pause")
                local frozen = active.position
                task.wait(0.05)
                concert:tick()
                expect(
                    active.position == frozen and not profile.chapter.completed,
                    "Pause advanced progress"
                )
                concert:command(player, "ChapterResume")
                expect(not active.paused, "Concert did not resume")
                concert:command(player, "ChapterClose")
                expect(
                    not concert.sessions[player] and not profile.chapter.completed,
                    "Cancel awarded progress"
                )
                concert:open(player)
                concert:command(player, "ChapterStart", ref)
                active = concert.sessions[player]
                expect(active and active.position == 0, "Restart did not begin at zero")
                active.lastAt = game.Workspace:GetServerTimeNow() - active.endDuration - 0.01
                concert:tick()
                expect(active.ended and profile.chapter.completed, "Local concert never completed")
                expect(profile.chapter.performance.localOnly, "Performance scope was promoted")
                expect(
                    profile.saved.chapter.performance.localOnly,
                    "Saved history lost local scope"
                )
                expect(
                    concert:state(player).localOnly,
                    "Concert client projection lost local scope"
                )
                for _, sample in Catalog.List do
                    expect(not Catalog.isReady(sample.id), "Performance promoted catalog approval")
                end
            end
        )
        result = {
            status = "PASS",
            checks = checks,
            saveMode = profile.saveMode,
            acceptedSessionSaves = saves,
            finishedSongId = songId,
            events = 4,
            sections = 2,
            duration = savedSong.duration,
            localOnly = true,
            catalogAdmissionChanged = false,
            timingMode = "deterministic_end_boundary_with_real_pause_wait",
            acousticOutput = "NOT_CHECKED_BY_SERVER_PROBE",
            notices = notices,
        }
    end, debug.traceback)
    if session and session.owner then
        session:stop("Local probe complete")
    end
    if concert then
        concert:stop(player)
    end
    for _, item in cleanup do
        item:Destroy()
    end
    game.Workspace:SetAttribute("QuayPublicBeat", previousPublicBeat)
    assert(ok, problem)
    return result
end
