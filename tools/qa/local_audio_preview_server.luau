-- Studio Server probe; private fixtures only, with no active progress/cloud writes.
local Shared = game.ReplicatedStorage.Shared
local Server = game.ServerScriptService.Server
local Catalog = require(Shared.SampleCatalog)
local Transport = require(Shared.MusicTransport)
local Finished = require(Shared.FinishedSong)
local Evidence = require(Shared.QuayMusicEvidence)
local Profiles = require(Server.ProfileStore)
local Workspace = require(Server.MusicWorkspace)
local results = {}
local pads = {}
for pad = 1, 64 do
    table.insert(pads, pad)
end
local function check(name, action)
    local ok, detail = xpcall(action, debug.traceback)
    table.insert(results, { name = name, passed = ok, detail = tostring(detail or "ok") })
end
local function command(p, action, a, b)
    local ok, message, detail = Workspace.command(nil, p, action, a, b, function()
        error("Preview regression must never persist data")
    end, function() end)
    assert(ok, tostring(action) .. ": " .. tostring(message))
    return detail
end
local function fresh()
    local p = Profiles.new()
    p.ready = true
    Workspace.sync(p)
    return p
end
check(
    "64 native local sounds keep approval separate from local gameplay and lesson roles",
    function()
        assert(
            #Catalog.List == 64 and #Catalog.Packs == 0,
            "Written slots changed or pending pack became selectable"
        )
        for _, pad in pads do
            local sample = Catalog.List[pad]
            assert(
                Catalog.isPreviewAvailable(sample.id, {}),
                "Missing personal preview: " .. sample.id
            )
            assert(
                Catalog.isLocallyPlayable(sample.id, {}),
                "Preview cannot be auditioned: " .. sample.id
            )
            assert(
                not Catalog.isReady(sample.id, {}) and not Catalog.isPlayable(sample.id, {}),
                "Preview acquired approved readiness"
            )
            assert(
                not sample.audioApproved and not sample.runtimeAdmitted,
                "Preview acquired admission flags"
            )
            assert(sample.listeningReview == "pending", "Listening review was falsely completed")
        end
        assert(not Catalog.isLocallyPlayable("kick", {}), "Retired identity acquired a preview")
        assert(not Catalog.isLocallyPlayable("missing", {}), "Unknown identity acquired a preview")
        assert(Catalog.List[33].label == "Needle Quay", "C01 does not contain native vocal")
        assert(Catalog.List[49].label == "Lantern Bell D5", "D01 does not contain native bell")
        assert(Catalog.plannedForRole("closed_hat").absolutePad == 9, "Hat role points to a snare")
        assert(Catalog.plannedForRole("pluck") == nil, "Pluck role points to native vocal")
        for _, id in { "I01", "I02", "I03" } do
            assert(
                Catalog.ByDiscoveryId[id] == nil,
                "Unapproved native sample became a discovery binding"
            )
        end
        assert(
            Catalog.sampleForRole("preview_kick") == Catalog.List[1].id,
            "Local pulse lesson is unavailable"
        )
        assert(
            Catalog.sampleForRole("preview_closed_hat") == Catalog.List[9].id,
            "Local texture lesson is unavailable"
        )
        assert(
            Catalog.sampleForRole("preview_pluck") == Catalog.List[49].id,
            "Local pitched bell lesson is unavailable"
        )
        for _, id in { "I01", "I02", "I03" } do
            assert(
                Catalog.LocalDiscoveryById[id] ~= nil,
                "Explicit local role substitute is missing"
            )
        end
        return "64 local sounds and explicit gameplay substitutes; artistic approval and Roblox admission remain pending"
    end
)
check(
    "sequence includes all 64 canonical native events for local creation and public performance",
    function()
        local p = fresh()
        for index, pad in pads do
            command(p, "Step", pad, (index - 1) % 16 + 1)
        end
        command(p, "PlayStart")
        local schedule = p.transport.schedule
        assert(
            schedule.localPreview and #schedule.events == 64,
            "Personal schedule lost one of 64 native previews"
        )
        for _, event in schedule.events do
            assert(event.localPreview and event.ready, "Personal event lost its audition status")
        end
        local public = Transport.resolve(
            p.music.project,
            { kind = "sequence", id = p.sequenceId },
            nil,
            { requireReady = true }
        )
        assert(
            public and public.localOnly and #public.events == 64,
            "Local public resolver lost notes"
        )
        assert(
            Evidence.sequence(p.music.project, p.sequenceId, {}) ~= nil,
            "Local music cannot supply local progression evidence"
        )
        command(p, "Stop")
        return "Personal and public Studio schedules contain all 64 local events without approving source recordings"
    end
)
check("recording snapshot retains newly tapped preview notes and source identity", function()
    local p = fresh()
    command(p, "Record")
    p.transport.startedAt = game.Workspace:GetServerTimeNow() - 0.01
    local id = Catalog.List[2].id
    command(p, "Tap", 2, {
        projectId = p.music.project.id,
        sequenceId = p.sequenceId,
        trackId = p.trackId,
        epoch = p.epoch,
        absolutePad = 2,
        sampleId = id,
        at = game.Workspace:GetServerTimeNow(),
        requestId = "local_preview_record_guard",
    })
    assert(
        #p.transport.schedule.events == 1 and p.transport.schedule.localPreview,
        "Recorded audition was omitted from schedule"
    )
    assert(p.transport.schedule.events[1].sampleId == id, "Recording changed source identity")
    command(p, "Stop")
    return "Recorded A02 remains in the private preview schedule; no save performed"
end)
check("local song draft can finish while explicit approved-only readiness stays strict", function()
    local p = fresh()
    command(p, "Step", 3, 1)
    command(p, "SongNew", {})
    command(p, "SongStepInsert", { sequenceId = p.sequenceId })
    command(p, "SongPlay")
    assert(
        p.transport.schedule.localPreview and #p.transport.schedule.events == 1,
        "Draft audition schedule is empty"
    )
    local project = p.music.project
    local song =
        Finished.capture(project, p.draftId, project.drafts[p.draftId].revision, project.revision, {
            id = "local_song_can_finish",
            requestId = "preview_guard",
            title = "Audition draft",
        })
    assert(
        song and song.localOnly and song.listeningReview == "pending",
        "Local finish was rejected or promoted approval"
    )
    assert(
        not Finished.ready(song, Catalog.isReady),
        "Approved-only query accepted pending sources"
    )
    command(p, "Stop")
    return "Local immutable finish is available; strict approval-only readiness remains false"
end)
check("local Kit creates an independent native program and keeps prior edits", function()
    local p = fresh()
    local oldProgramId = p.music.project.tracks[p.trackId].programId
    command(p, "Assign", 1, Catalog.List[33].id)
    command(p, "PadSound", 1, { key = "pitch", value = 3 })
    command(p, "Kit", Catalog.LocalPack.id)
    local project = p.music.project
    local selected = project.programs[project.tracks[p.trackId].programId]
    assert(selected.id ~= oldProgramId, "Kit load overwrote the previous program")
    assert(
        project.programs[oldProgramId].pads["1"].sampleId == Catalog.List[33].id,
        "Kit load discarded previous assignment"
    )
    assert(
        project.programs[oldProgramId].pads["1"].settings.pitch == 3,
        "Kit load discarded previous sound edit"
    )
    for pad = 1, 64 do
        assert(
            selected.pads[tostring(pad)].sampleId == Catalog.List[pad].id,
            "Native Kit omitted a canonical address"
        )
    end
    command(p, "TrackProgram", { programId = oldProgramId })
    assert(
        p.music.project.tracks[p.trackId].programId == oldProgramId,
        "Previous kit cannot be selected again"
    )
    local before = p.music.project.revision
    local ok = Workspace.command(nil, p, "Kit", "unapproved_unknown_pack", nil, function()
        error("Kit probe must not persist")
    end, function() end)
    assert(not ok and p.music.project.revision == before, "Unknown kit changed the project")
    return "All64 loaded into a new program; prior assignment/FX retained and selectable; unknown roster ID rejected"
end)
local failures = 0
for _, result in results do
    if not result.passed then
        failures += 1
    end
end
return game:GetService("HttpService")
    :JSONEncode({ scope = "studio_private_fixture", failures = failures, results = results })
