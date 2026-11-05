-- Read-only advice from the same server-owned music, discovery and route state.
-- Hint topics select advice, never a musical object, note, save or reward.
local Quay = require(script.Parent.QuayProgress)
local Objectives = require(script.Parent.QuayObjectives)
local Missions = require(script.Parent.NeighborhoodMissions)
local Discoveries = require(script.Parent.DiscoveryCatalog)
local Hunt = require(script.Parent.SoundHunt)
local Samples = require(script.Parent.SampleCatalog)
local Groove = require(script.Parent.FirstGroove)
local Quest = require(script.Parent.FirstPerformanceQuest)
local Versions = require(script.Parent.SampleVersions)
local Progress = {}
local stopTasks = {
    P1 = { "NQ-Q00", "NQ-Q01", "NQ-Q02" },
    P2 = { "NQ-Q04", "NQ-Q05" },
    P3 = { "NQ-Q06", "NQ-Q07", "NQ-Q08" },
    P4 = { "NQ-Q09", "NQ-Q10" },
    finale = { "NQ-Q11", "NQ-Q12" },
}
local voices = {
    alissia = { first = "Let's listen for what is already here. ", next = "I noticed something: " },
    nikolas = { first = "We can build this one small idea at a time. ", next = "Here's a practical thing to try: " },
}

local function saveState(profile)
    if profile.saving then
        return "A snapshot is saving. Wait for its acknowledgement before relying on that save."
    elseif profile.saveMode == "unavailable" then
        return "Storage is unavailable; these edits are temporary. Your current work stays in the workspace."
    elseif profile.editVersion ~= profile.savedEditVersion then
        return "There are unsaved changes. Save keeps the whole project; I never save it for you."
    elseif not profile.saved then
        return "This project has not been saved yet."
    elseif profile.saveMode == "session" then
        return "The last save lasts for this Studio session only."
    end
    return "The current project has a storage save acknowledgement."
end

local function sourceAdvice(profile, id)
    local definition, source = Discoveries.ById[id], Samples.discoveryFor(id)
    local track = profile.music.project.tracks[profile.trackId]
    local program = track and profile.music.project.programs[track.programId]
    local pad = source and Hunt.pad(program, source.id)
    if not profile.unlocked[id] then
        return definition.label .. " is not collected yet. Use its nearby quay source action when you want to. The instrument remains available."
    elseif not source or not Samples.isPlaybackReady(source.id, profile.unlocked)
        or not Versions.matches(source.id, profile.music.project.sampleVersions) then
        return definition.label .. " is collected, but its audio is unavailable here. Keep using your available sounds; no substitute is chosen by a hint."
    end
    local state = if Samples.isReady(source.id, profile.unlocked) then "Approved audio"
        else "Local preview audio; listening approval is pending"
    return definition.label .. " / " .. (if pad then Hunt.address(pad) else "not assigned on this track")
        .. ". " .. state .. ". "
        .. (if pad then "Audition or add one note in SEQ / Full editor / Sound Hunts. Existing notes stay."
            else "Assign this source in Sounds before adding it. Your existing assignments are never replaced by advice.")
end

local function huntAdvice(profile)
    local mission = Missions.summary(profile)
    if not mission.nextId then
        return "hunt:complete", {
            "Your three sound jobs are already kept. Revisit any source whenever you want.",
            "Try a collected sound in a different named sequence, or copy a variation and change its rhythm.",
            "Sound Hunts keeps readable origins, pad addresses and audition. The optional echo is practice, not a creative completion gate.",
        }
    end
    local index = table.find(Missions.Order, mission.nextId)
    local id = Discoveries.Order[index]
    local job, definition = Missions.Definitions[mission.nextId], Discoveries.ById[id]
    return "hunt:" .. mission.nextId, {
        job.title .. ": " .. definition.origin,
        sourceAdvice(profile, id),
        job.objective .. " Copy Variation keeps the original sequence. Change the copy yourself, then Save. Echo has retry/skip and grants no reward.",
    }, ({ I01 = "P1", I02 = "P2", I03 = "P4" })[id]
end

local function sequenceAdvice(profile)
    local project = profile.music.project
    local sequence = project.sequences[profile.sequenceId]
    if not sequence then
        return "sequence:none", {
            "Choose one of your named sequences in SEQ.",
            "A-D choose sample banks. Named sequences are independent musical sections.",
            "Open First Groove for an example or blank loop. Current work is preserved through the normal workspace path.",
        }
    end
    local bank = string.char(64 + math.clamp(profile.bank or 1, 1, 4))
    local starter = Groove.isStarter(sequence)
    local unavailable, preview = false, false
    for trackId, events in sequence.trackEvents do
        local track = project.tracks[trackId]
        local program = track and project.programs[track.programId]
        for _, event in events do
            local definition = program and program.pads[tostring(event.pad)]
            local sampleId = definition and definition.sampleId
            if not sampleId or not Samples.isPlaybackReady(sampleId, profile.unlocked)
                or not Versions.matches(sampleId, project.sampleVersions) then
                unavailable = true
            elseif not Samples.isReady(sampleId, profile.unlocked) then
                preview = true
            end
        end
    end
    local introduction = if starter
        then "First Groove / " .. sequence.name .. ": choose one small change and listen again. This is a loop, not a finished Song."
        else "Selected sequence / " .. sequence.name .. ": your rhythm is your choice."
    local detail = if unavailable then "A note's assigned audio is unavailable here; its sample identity and your work are retained. Choose an available sound yourself."
        elseif preview then "This sequence uses local preview audio; human listening approval is still pending."
        else "Sample bank " .. bank .. " selects sounds, not a sequence. Copy Variation creates a separate sequence; its track kit stays shared."
    return "sequence:" .. project.id .. ":" .. sequence.id, {
        introduction,
        detail .. " Change one note, compare Play/Stop, or use Undo. No quest or companion is required.",
        "Rename this sequence so you can find it. Use Copy Variation before changing a second idea. Song Mode orders your saved sections. " .. saveState(profile),
    }
end

local function draftAdvice(profile)
    local project = profile.music.project
    local draft = project.drafts[profile.draftId]
    if not draft then
        return "draft:none", {
            "No Song Mode draft is selected. Your sequences remain available.",
            "Choose or create a draft in SONG. A draft arranges named sequence references and repeats.",
            "Add a section, choose its repeats and listen to the order. Save Draft keeps development; Finish is your deliberate later choice.",
        }
    end
    return "draft:" .. project.id .. ":" .. draft.id, {
        "Selected Draft Song / " .. draft.name .. ". It is still an editable arrangement.",
        "Review the beginning, development and ending in SONG. Order sequence sections and repeats; A-D are sound banks.",
        "Save Draft keeps the arrangement. Finish deliberately creates a Finished Song revision; a spotlight or captured take does not finish it automatically. " .. saveState(profile),
    }
end

local function finishedAdvice(profile)
    local id = profile.selectedFinishedSongId
    local songs = profile.saved and profile.saved.music and profile.saved.music.finishedSongs
    local song = songs and songs[id]
    if not song then
        return "finished:none", {
            "No successfully saved Finished Song is selected.",
            "Keep developing a Song Mode draft, or select an existing saved Finished Song in CRATES.",
            "Finish is your choice after reviewing the arrangement. Save acknowledgement is required before selecting that finished revision.",
        }
    end
    return "finished:" .. song.id .. ":" .. song.revision, {
        "Selected Finished Song / " .. (song.title or song.name or song.id) .. ". This is its saved revision.",
        "Full Song plays the whole arrangement. Spotlight is a separate short excerpt and never shortens the source Song.",
        "Open an editable copy if you want another version. Optional Spotlight capture creates a new Draft after Keep; the source revision stays intact. " .. saveState(profile),
    }
end

local function playbackAdvice(profile)
    local transport = profile.transport
    local ref, schedule = transport.ref, transport.schedule
    local kind = if ref.kind == "song" then "Draft Song"
        elseif ref.kind == "finished" then "Finished Song" else "Sequence"
    return "playback:" .. ref.kind .. ":" .. ref.id .. ":" .. tostring(ref.revision), {
        "Pinned " .. kind .. " playback / " .. schedule.title
            .. (if profile.recording then ". You are recording your own actions."
                elseif profile.playing then ". Listen for one change you want to make."
                elseif (transport.offset or 0) == 0 then ". Playback is stopped at the beginning; Play uses this snapshot."
                else ". Playback is paused; Play resumes this snapshot."),
        "Playback keeps its accepted musical snapshot. A different editor selection is a separate object; choose a Selected guidance topic to inspect it. A-D still choose sound banks.",
        "Stop before starting a fresh snapshot. Copy a variation to preserve your first sequence. "
            .. (if schedule.localOnly or schedule.localPreview then "This playback uses local preview audio; approval remains pending. " else "")
            .. saveState(profile),
    }
end

local function routeAdvice(profile, route)
    if not route then
        local mission = Missions.summary(profile)
        if mission.nextId then
            return huntAdvice(profile)
        end
        local quest = Quest.summary(profile)
        return "legacy:" .. quest.stage, {
            "Mica's courtyard is an optional chapter path. Your instrument stays available.",
            quest.objective,
            "The journal owns the actual chapter requirements. I only explain them; I never perform, save or award anything for you.",
        }
    end
    local q, id = Quay.sanitize(profile.quay), nil
    for _, candidate in stopTasks[profile.companionStop or q.parking] or {} do
        if not q.completed[candidate] then
            id = candidate
            break
        end
    end
    for _, candidate in Objectives.Order do
        local definition = Objectives.ById[candidate]
        if not id and not definition.optional and not q.completed[candidate] then
            id = candidate
        end
    end
    local definition = id and Objectives.ById[id]
    if not definition then
        return "route:complete", {
            "This chapter is complete. What would you like to make next?",
            "Revisit a sound, copy a variation, or develop another Song Mode draft.",
            "The chapter ending keeps your music and earned progress. Alone and either companion retain the same musical choices.",
        }
    end
    return "route:" .. id, {
        definition.title .. ". This route never locks the instrument or your sound-hunt practice.",
        definition.text,
        definition.text .. " The journal shows the actual task. Exact echo notes apply only to an exercise you choose; your personal rhythm is yours.",
    }, definition.stop
end

function Progress.project(profile, route, selected, level, topic)
    level = math.clamp(math.floor(level or 1), 1, 3)
    local id, lines, location
    local requested = topic or "auto"
    if requested == "auto" then
        local ref = profile.transport and profile.transport.ref
        topic = if ref then "playback" else "sequence"
    end
    if topic == "hunt" then
        id, lines, location = huntAdvice(profile)
    elseif topic == "draft" then
        id, lines = draftAdvice(profile)
    elseif topic == "finished" then
        id, lines = finishedAdvice(profile)
    elseif topic == "sequence" then
        id, lines = sequenceAdvice(profile)
    elseif topic == "playback" then
        id, lines = playbackAdvice(profile)
    else
        id, lines, location = routeAdvice(profile, route)
    end
    local voice = voices[selected] or voices.alissia
    local transport = if profile.recording then "RECORDING"
        elseif profile.playing then "PLAYING" else "STOPPED"
    local queued = if profile.nextSequence then " / next sequence queued at a musical boundary" else ""
    local pinned = profile.transport and profile.transport.schedule
    local playback = if pinned then " / pinned playback: " .. pinned.title else ""
    return {
        context = requested .. ":" .. id, level = level, maxLevel = 3, location = location,
        topic = requested,
        text = (if level == 1 then voice.first else voice.next) .. lines[level],
        workspace = transport .. playback .. queued .. ". " .. saveState(profile),
    }
end
return Progress
