local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage").Shared
local Project = require(Shared.MusicProject)
local Migration = require(Shared.LegacyMusicMigration)
local Cosmetics = require(Shared.CosmeticCatalog)
local Quest = require(Shared.FirstPerformanceQuest)
local Rooms = require(Shared.RoomCatalog)
local Missions = require(Shared.NeighborhoodMissions)
local Chapter = require(Shared.ChapterConcert)
local Quay = require(Shared.QuayProgress)
local Companions = require(Shared.CompanionCatalog)
local Rewards = require(Shared.QuayRewards)
local Activities = require(Shared.QuayActivities)
local Identity = require(Shared.QuayIdentity)
local WorkspaceState = require(script.Parent.WorkspaceState)

local ProfileStore = { Schema = 3, MaxBytes = 3000000 }
local store
local function cloudStore()
    if not store then
        store = DataStoreService:GetDataStore("FrequencyZero.Patterns.v1")
    end
    return store
end
local function integer(v, lo, hi)
    return type(v) == "number" and v == v and v % 1 == 0 and v >= lo and v <= hi
end
local function supported(data)
    return type(data) == "table"
        and integer(data.schema, 1, ProfileStore.Schema)
        and (data.revision == nil or integer(data.revision, 0, 1e12))
        and Activities.supported(data.experience)
        and Identity.supported(data.identity)
        and (data.schema < 3 or (type(data.music) == "table" and data.music.schema == 1))
end
local function emptyMusic()
    return Migration.new()
end
function ProfileStore.new()
    return {
        music = emptyMusic(),
        quest = Quest.sanitize(nil),
        unlocked = {},
        finish = "quay",
        room = Rooms.sanitize(nil, {}),
        neighborhood = Missions.sanitize(nil),
        chapter = Chapter.sanitize(nil),
        quay = Quay.sanitize(nil),
        companion = Companions.sanitize(nil),
        rewards = Rewards.sanitize(nil, Quay.sanitize(nil)),
        experience = Activities.sanitize(nil),
        identity = Identity.sanitize(nil),
        saved = nil,
        storageRevision = 0,
        saveMode = if RunService:IsStudio() then "session" else "cloud",
        loadFailed = false,
        saving = false,
        ready = false,
        editVersion = 0,
        savedEditVersion = 0,
        workspaceGeneration = 0,
        bank = 1,
        bar = 1,
        velocity = 100,
        fullLevel = false,
        timingCorrect = 240,
        swing = 50,
        metronome = "off",
        countIn = false,
        noteRepeat = false,
        teachingBar = 1,
    }
end
local function capture(profile, overrideMusic, selected)
    local music = Project.clone(overrideMusic or profile.music)
    if type(music) ~= "table" or music.schema ~= 1 then
        return nil, "Unsupported music schema; your work is preserved."
    end
    local valid, problem = Migration.validate(music)
    if not valid then
        return nil, problem
    end
    selected = selected or profile
    local finished = selected.selectedFinishedSongId or profile.selectedFinishedSongId
    local snapshot = {
        schema = ProfileStore.Schema,
        music = music,
        quest = Quest.sanitize(profile.quest),
        unlocked = table.clone(profile.unlocked),
        finish = profile.finish,
        room = Rooms.sanitize(profile.room, profile),
        neighborhood = Missions.sanitize(profile.neighborhood),
        chapter = Chapter.sanitize(profile.chapter),
        quay = Quay.sanitize(profile.quay),
        companion = Companions.sanitize(profile.companion),
        rewards = Rewards.sanitize(profile.rewards, profile.quay),
        experience = Activities.sanitize(profile.experience),
        identity = Identity.sanitize(profile.identity),
        teachingBar = profile.teachingBar or 1,
        sequenceId = if music.project.sequences[selected.sequenceId]
            then selected.sequenceId
            else music.project.sequenceOrder[1],
        trackId = if music.project.tracks[selected.trackId]
            then selected.trackId
            else music.project.trackOrder[1],
        draftId = if music.project.drafts[selected.draftId]
            then selected.draftId
            else music.project.draftOrder[1],
        selectedFinishedSongId = if music.finishedSongs[finished] then finished else nil,
    }
    local ok, json = pcall(HttpService.JSONEncode, HttpService, snapshot)
    if not ok or #json > ProfileStore.MaxBytes then
        return nil,
            "This save exceeds the 3 MB project budget. Your complete workspace remains open; nothing was discarded."
    end
    snapshot.measuredBytes = #json
    return snapshot
end
ProfileStore.capture = capture
function ProfileStore.load(player, profile, storage)
    if profile.saveMode == "session" and not storage then
        profile.ready = true
        return
    end
    local ok, data = pcall(function()
        return (storage or cloudStore()):GetAsync(tostring(player.UserId))
    end)
    if not ok or (data ~= nil and not supported(data)) then
        profile.loadFailed = true
        profile.saveMode = "unavailable"
    elseif type(data) == "table" then
        local music, problem = Migration.import(data)
        if not music then
            profile.loadFailed = true
            profile.saveMode = "unavailable"
            profile.migrationError = problem
        else
            profile.music = music
            profile.sequenceId = if type(data.sequenceId) == "string"
                    and music.project.sequences[data.sequenceId]
                then data.sequenceId
                else music.project.sequenceOrder[1]
            profile.trackId = if type(data.trackId) == "string"
                    and music.project.tracks[data.trackId]
                then data.trackId
                else music.project.trackOrder[1]
            profile.draftId = if type(data.draftId) == "string"
                    and music.project.drafts[data.draftId]
                then data.draftId
                else music.project.draftOrder[1]
            profile.selectedFinishedSongId = if type(data.selectedFinishedSongId) == "string"
                    and music.finishedSongs[data.selectedFinishedSongId]
                then data.selectedFinishedSongId
                else nil
            for _, id in { "I01", "I02", "I03" } do
                profile.unlocked[id] = type(data.unlocked) == "table" and data.unlocked[id] == true
            end
            profile.quest = Quest.sanitize(data.quest)
            profile.finish = if Cosmetics.Sets[data.finish] then data.finish else "quay"
            profile.storageRevision = data.revision or 0
            profile.quay = Quay.sanitize(data.quay)
            profile.room = Rooms.sanitize(data.room, profile)
            profile.neighborhood = Missions.sanitize(data.neighborhood)
            profile.chapter = Chapter.sanitize(data.chapter)
            profile.companion = Companions.sanitize(data.companion)
            profile.rewards = Rewards.sanitize(data.rewards, profile.quay)
            profile.experience = Activities.sanitize(data.experience)
            profile.identity = Identity.sanitize(data.identity)
            profile.teachingBar = if integer(data.teachingBar, 1, 64) then data.teachingBar else 1
            profile.saved = capture(profile)
            if not profile.saved then
                profile.loadFailed = true
                profile.saveMode = "unavailable"
            end
        end
    end
    profile.ready = true
end
-- overrideMusic is a fully captured finish candidate. It is written first and
-- admitted to the live library by the caller only after this backend accepts it.
function ProfileStore.save(player, profile, storage, overrideMusic)
    if profile.loadFailed then
        return false, "Load or migration failed. Saving is disabled to protect existing work."
    end
    if profile.saving then
        return false, "A save is already in progress."
    end
    local snapshot, problem = capture(profile, overrideMusic)
    if not snapshot then
        return false, problem
    end
    local generation = profile.workspaceGeneration or 0
    -- A caller may have captured an override before dispatching its save task.
    -- Never assign today's edit version to a different, older music document.
    -- -1 is an in-memory dirty sentinel, not a persisted revision/schema change.
    local capturedVersion = if WorkspaceState.same(profile.music, snapshot.music)
        then profile.editVersion
        else -1
    for _, sequence in snapshot.music.project.sequences do
        sequence.savedRevision = sequence.revision
    end
    for _, draft in snapshot.music.project.drafts do
        draft.savedRevision = draft.revision
    end
    local function markAccepted()
        local current = profile.music.project
        local written = snapshot.music.project
        if current.id ~= written.id or (profile.workspaceGeneration or 0) ~= generation then
            return
        end
        -- Numeric revisions alone are insufficient after loading an older branch.
        -- A musical dependency edit also keeps its sequence/song visibly dirty.
        local sameRouting = WorkspaceState.same(current.programs, written.programs)
            and WorkspaceState.same(current.tracks, written.tracks)
            and WorkspaceState.same(current.trackOrder, written.trackOrder)
        if not sameRouting then
            return
        end
        local sameSequences = WorkspaceState.same(current.sequences, written.sequences)
        for id, sequence in written.sequences do
            if WorkspaceState.same(current.sequences[id], sequence) then
                current.sequences[id].savedRevision = sequence.revision
            end
        end
        if sameSequences then
            for id, draft in written.drafts do
                if WorkspaceState.same(current.drafts[id], draft) then
                    current.drafts[id].savedRevision = draft.revision
                end
            end
        end
    end
    snapshot.neighborhood = Missions.awarded(snapshot)
    local expected = profile.storageRevision
    if expected >= 1e12 then
        return false, "Storage revision limit reached; workspace retained."
    end
    snapshot.revision = if profile.saveMode == "session" and not storage
        then expected
        else expected + 1
    -- Measure the actual final root, including earned mission flags, revision and
    -- the measurement field itself. No yield occurs between capture and this gate.
    snapshot.measuredBytes = 0
    for _ = 1, 3 do
        local encodedOk, encoded = pcall(HttpService.JSONEncode, HttpService, snapshot)
        if not encodedOk or #encoded > ProfileStore.MaxBytes then
            return false,
                "This complete save exceeds the 3 MB budget. Existing saved work is unchanged."
        end
        if snapshot.measuredBytes == #encoded then
            break
        end
        snapshot.measuredBytes = #encoded
    end
    profile.saving = true
    if profile.saveMode == "session" and not storage then
        markAccepted()
        profile.saved = snapshot
        profile.savedEditVersion = capturedVersion
        profile.saving = false
        profile.neighborhood = Missions.merge(profile.neighborhood, snapshot.neighborhood)
        return true, "Saved for this Studio session only.", snapshot
    end
    local ok, saved = pcall(function()
        return (storage or cloudStore()):UpdateAsync(tostring(player.UserId), function(previous)
            if
                previous ~= nil
                and (not supported(previous) or (previous.revision or 0) ~= expected)
            then
                return nil
            end
            if previous == nil and expected ~= 0 then
                return nil
            end
            return snapshot
        end)
    end)
    profile.saving = false
    if not ok then
        return false,
            "Save could not reach storage. Your complete draft is still open; retry when ready."
    end
    if saved == nil then
        return false,
            "A newer or unsupported save exists. This workspace was not written; keep it open to preserve unsaved work."
    end
    markAccepted()
    profile.saved = snapshot
    profile.savedEditVersion = capturedVersion
    profile.storageRevision = snapshot.revision
    profile.neighborhood = Missions.merge(profile.neighborhood, snapshot.neighborhood)
    return true, "Project, sequences, drafts and progress saved.", snapshot
end
function ProfileStore.restore(profile)
    if profile.saving then
        return false, "Wait for the current save before restoring."
    end
    if not profile.saved or not profile.saved.music then
        return false, "No saved project to restore."
    end
    -- Recovery retains post-save material and never rolls back earned history or
    -- immutable songs. A second recovery is refused rather than losing its preimage.
    if profile.music.recoveryProject then
        return false,
            "Open the retained recovery workspace before restoring again. Saving alone does not discard it."
    end
    -- Stage recovery and the saved project together. If the combined snapshot
    -- exceeds the storage budget, leave the live workspace and transport untouched.
    local proposed = Project.clone(profile.music)
    proposed.recoveryProject = Project.clone(profile.music.project)
    proposed.project = Project.clone(profile.saved.music.project)
    local snapshot, captureProblem = capture(profile, proposed, profile.saved)
    if not snapshot then
        return false, captureProblem
    end
    WorkspaceState.activate(profile, proposed, profile.saved)
    return true,
        "Saved project restored. The previous workspace is retained for recovery; earned progress and finished songs stay with you."
end
return ProfileStore
