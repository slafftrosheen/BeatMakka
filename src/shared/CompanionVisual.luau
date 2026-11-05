-- Compact advice only. Full authored hints remain in CompanionProgress.
local Catalog = require(script.Parent.SampleCatalog)
local Hunt = require(script.Parent.SoundHunt)
local Missions = require(script.Parent.NeighborhoodMissions)
local Discovery = require(script.Parent.DiscoveryCatalog)
local Sequence = require(script.Parent.MusicSequence)
local Versions = require(script.Parent.SampleVersions)
local Objectives = require(script.Parent.QuayObjectives)
local Visual = {}
function Visual.project(profile, topic, context)
    local project = profile.music.project
    local cue, detail, current = "TRY ONE SMALL CHANGE", "Your music stays yours.", 2
    local steps = { { "SOUND", "pads" }, { "MAKE", "steps" }, { "KEEP", "save" } }
    if context:sub(1, 5) == "hunt:" then
        local mission = Missions.summary(profile)
        local index = mission.nextId and table.find(Missions.Order, mission.nextId)
        local id = index and Discovery.Order[index]
        local source = id and Hunt.source(id)
        local track = project.tracks[profile.trackId]
        local program = track and project.programs[track.programId]
        local pad = source and Hunt.pad(program, source.id)
        steps = { { "FIND", "route" }, { "MAKE", "pads" }, { "SAVE", "save" } }
        if not id then cue, detail, current = "TRY ANOTHER RHYTHM", "Three sound jobs kept.", 3
        elseif not profile.unlocked[id] then cue, detail, current = "FIND THE SOURCE", Discovery.ById[id].origin, 1
        elseif not source or not Catalog.isPlaybackReady(source.id, profile.unlocked) then
            cue, detail = "AUDIO UNAVAILABLE", "Keep the source identity. Try an available sound."
        elseif not pad then cue, detail = "ASSIGN IN SOUNDS", Discovery.ById[id].label
        elseif not Versions.matches(source.id, project.sampleVersions) then
            cue, detail = "PACK VERSION UNAVAILABLE", "Review this workspace in Crates. Source references are kept."
        else cue, detail = "TRY IT IN YOUR LOOP", Hunt.address(pad) .. " / " .. Catalog.label(source.id) end
    elseif topic == "sequence" then
        local sequence = project.sequences[profile.sequenceId]
        if not sequence then cue, detail, current = "CHOOSE A LOOP", "Open SEQ.", 1
        else
            cue = if Sequence.countEvents(sequence) == 0 then "ADD A NOTE" else "CHANGE ONE HIT"
            detail = "SEQ / " .. sequence.name
            local unavailable, preview = false, false
            for trackId, events in sequence.trackEvents do
                local track = project.tracks[trackId]
                local program = track and project.programs[track.programId]
                for _, event in events do
                    local pad = program and program.pads[tostring(event.pad)]
                    local id = pad and pad.sampleId
                    if not id or not Catalog.isPlaybackReady(id, profile.unlocked) or not Versions.matches(id, project.sampleVersions) then
                        unavailable = true
                    elseif not Catalog.isReady(id, profile.unlocked) then preview = true end
                end
            end
            if unavailable then cue, detail = "CHECK AUDIO", "A stored sound is unavailable. Its identity is kept."
            elseif preview then detail ..= " / LOCAL PREVIEW" end
        end
    elseif topic == "draft" then
        local draft = project.drafts[profile.draftId]
        steps = { { "ADD", "plus" }, { "ORDER", "steps" }, { "SAVE", "save" } }
        if not draft then cue, detail, current = "OPEN SONG", "Choose or create a Draft.", 1
        else cue, detail, current = if #draft.steps == 0 then "ADD A SECTION" else "ORDER YOUR SECTIONS", draft.name, if #draft.steps == 0 then 1 else 2 end
    elseif topic == "finished" then
        local songs = profile.saved and profile.saved.music and profile.saved.music.finishedSongs
        local song = songs and songs[profile.selectedFinishedSongId]
        steps = { { "CHOOSE", "library" }, { "LISTEN", "play" }, { "COPY", "duplicate" } }
        if not song then cue, detail, current = "CHOOSE A SAVED SONG", "Open Crates / Finished.", 1
        else cue, detail = "LISTEN TO THE FULL SONG", song.title or song.name or song.id end
    elseif topic == "playback" then
        steps = { { "LISTEN", "headphones" }, { "STOP", "stop" }, { "EDIT", "steps" } }
        cue = if profile.playing then "LISTEN FOR ONE CHANGE" else "PLAY THIS SNAPSHOT"
        detail, current = profile.transport.schedule.title, 1
    else
        local definition = context:sub(1, 6) == "route:" and Objectives.ById[context:sub(7)]
        steps = { { "GO", "route" }, { "TRY", "pads" }, { "RETURN", "people" } }
        cue, detail, current = if definition then definition.title else "EXPLORE AT YOUR PACE", "Open Story for the current route.", 1
    end
    return { cue = cue, detail = detail, steps = steps, current = current,
        storage = if profile.saving then "SAVING" elseif profile.saveMode == "unavailable" then "TEMPORARY / NO STORAGE"
            elseif profile.editVersion ~= profile.savedEditVersion then "UNSAVED"
            elseif not profile.saved then "NOT SAVED" elseif profile.saveMode == "session" then "SESSION SAVE" else "STORAGE ACKNOWLEDGED" }
end
return Visual
