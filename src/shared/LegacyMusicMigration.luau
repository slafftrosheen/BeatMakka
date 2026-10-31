-- Legacy data is imported as unavailable musical intent, never substituted.
-- Old and new server writers must be drained together before deployment: a
-- schema number alone cannot prevent an already-running old writer overwrite.
local Project = require(script.Parent.MusicProject)
local Sequence = require(script.Parent.MusicSequence)
local PadSound = require(script.Parent.PadSound)
local Migration = { Schema = 1, Id = "legacy_four_patterns_v1" }

local function at(values, index)
    if type(values) ~= "table" then
        return nil
    end
    local value = values[index]
    if value == nil then
        value = values[tostring(index)]
    end
    return value
end

local function supportedArray(values, maximum)
    if values == nil then
        return true
    end
    if type(values) ~= "table" then
        return false
    end
    for key in values do
        local number = if type(key) == "number" then key else tonumber(key)
        if not Sequence.integer(number, 1, maximum) then
            return false
        end
        if type(key) ~= "number" and tostring(number) ~= key then
            return false
        end
    end
    return true
end

local function importPattern(project, raw, index, prefix, version)
    if raw ~= nil and type(raw) ~= "table" then
        return false, "Unsupported legacy pattern."
    end
    raw = raw or {}
    if
        (raw.bpm ~= nil and not Sequence.integer(raw.bpm, 60, 180))
        or not supportedArray(raw.rows, 16)
        or not supportedArray(raw.assignments, 16)
        or not supportedArray(raw.sounds, 16)
        or not supportedArray(raw.muted, 16)
    then
        return false,
            "Legacy pattern exceeds its authored shape; its raw data is preserved read-only."
    end
    local suffix = string.format("%02d", index)
    local programId, trackId, sequenceId =
        prefix .. "_kit_" .. suffix, prefix .. "_track_" .. suffix, prefix .. "_seq_" .. suffix
    local program = Project.program(programId, "Imported kit " .. suffix, nil)
    local track = {
        id = trackId,
        revision = 1,
        name = "Imported part " .. suffix,
        programId = programId,
        mix = { muted = false, solo = false, gain = 1, pan = 0 },
    }
    local sequence = Sequence.new(sequenceId, "Imported " .. suffix, raw.bpm or 96, 1)
    sequence.import = {
        kind = "legacy_pattern",
        migrationId = Migration.Id,
        sourceIndex = index,
        sourceVersion = version,
        legacySlotLabel = ({ "A", "B", "C", "D" })[index],
    }
    sequence.savedRevision = 1
    local events, mutes = {}, {}
    for pad = 1, 16 do
        local assigned = at(raw.assignments, pad)
        if assigned ~= nil and type(assigned) ~= "string" then
            return false, "Unsupported legacy sample reference; raw data retained."
        end
        -- No catalogue lookup is allowed here: retired IDs must remain exact.
        program.pads[tostring(pad)].sampleId = assigned or ""
        local settings = at(raw.sounds, pad)
        if settings ~= nil and type(settings) ~= "table" then
            return false, "Unsupported legacy pad settings; raw data retained."
        end
        local resolved = PadSound.sanitize(settings)
        if settings then
            for key, spec in PadSound.Spec do
                local value = settings[key]
                if
                    value ~= nil
                    and (
                        type(value) ~= "number"
                        or value ~= value
                        or value < spec[1]
                        or value > spec[2]
                    )
                then
                    return false, "Out-of-range legacy playback settings are preserved read-only."
                end
            end
            if
                settings.start
                and settings.finish
                and settings.finish < settings.start + 0.02 - 1e-9
            then
                return false, "Unsupported legacy trim is preserved read-only."
            end
        end
        program.pads[tostring(pad)].settings = resolved
        local muted = at(raw.muted, pad)
        if muted ~= nil and type(muted) ~= "boolean" then
            return false, "Unsupported legacy pad mute; raw data retained."
        end
        if muted == true then
            mutes[tostring(pad)] = true
        end
        local row = at(raw.rows, pad)
        if not supportedArray(row, 16) then
            return false, "Oversized legacy row is preserved read-only."
        end
        for step = 1, 16 do
            local hit = at(row, step)
            if hit ~= nil and type(hit) ~= "boolean" then
                return false, "Unsupported legacy hit; raw data retained."
            end
            if hit == true then
                table.insert(events, {
                    eventId = sequenceId .. "_" .. pad .. "_" .. step,
                    tick = (step - 1) * 240,
                    pad = pad,
                    velocity = 127,
                })
            end
        end
    end
    Sequence.sort(events)
    sequence.trackEvents[trackId], sequence.trackPadMutes[trackId] = events, mutes
    project.programs[programId], project.tracks[trackId], project.sequences[sequenceId] =
        program, track, sequence
    table.insert(project.trackOrder, trackId)
    table.insert(project.sequenceOrder, sequenceId)
    return true
end

local function importBundle(bundle, id, label, version)
    if type(bundle) ~= "table" then
        return nil, "Unsupported legacy bundle."
    end
    local slots = bundle.slots
    if not supportedArray(slots, 4) then
        return nil, "Oversized legacy bundle preserved read-only."
    end
    local project = Project.new(id, label)
    project.programs, project.tracks, project.trackOrder, project.sequences, project.sequenceOrder =
        {}, {}, {}, {}, {}
    project.nextId = 100
    project.import = { kind = "legacy_bundle", migrationId = Migration.Id, version = version }
    for index = 1, 4 do
        local raw = at(slots, index)
        if index == 1 and slots == nil then
            raw = bundle.pattern
        end
        local ok, message = importPattern(project, raw, index, id, version)
        if not ok then
            return nil, message
        end
    end
    local valid, message = Project.validate(project)
    if not valid then
        return nil, message
    end
    return project
end

function Migration.new()
    return {
        schema = Migration.Schema,
        project = Project.new(),
        archives = {},
        archiveOrder = {},
        finishedSongs = {},
        finishedOrder = {},
        finishRequests = {},
    }
end

function Migration.validate(music)
    if type(music) ~= "table" or music.schema ~= Migration.Schema then
        return false, "Unsupported future music schema. Saving is disabled to preserve it."
    end
    local valid, message = Project.validate(music.project)
    if not valid then
        return false, message
    end
    if
        type(music.archives) ~= "table"
        or type(music.archiveOrder) ~= "table"
        or type(music.finishedSongs) ~= "table"
        or type(music.finishedOrder) ~= "table"
        or type(music.finishRequests) ~= "table"
    then
        return false, "Invalid music library index; original data retained."
    end
    local seen, count = {}, 0
    for index, id in music.archiveOrder do
        local archive = music.archives[id]
        if
            not Sequence.integer(index, 1, #music.archiveOrder)
            or type(id) ~= "string"
            or seen[id]
            or type(archive) ~= "table"
            or archive.id ~= id
        then
            return false, "Invalid legacy archive index."
        end
        seen[id] = true
        if archive.project then
            local ok, archiveMessage = Project.validate(archive.project)
            if not ok then
                return false, archiveMessage
            end
        end
    end
    for id in music.archives do
        count += 1
        if not seen[id] then
            return false, "Unindexed legacy archive."
        end
    end
    if count ~= #music.archiveOrder or count > Project.Limits.Archives + 1 then
        return false, "Legacy archive budget exceeded; originals retained."
    end
    seen, count = {}, 0
    for index, id in music.finishedOrder do
        local song = music.finishedSongs[id]
        if
            not Sequence.integer(index, 1, #music.finishedOrder)
            or type(id) ~= "string"
            or seen[id]
            or type(song) ~= "table"
            or song.id ~= id
            or song.schema ~= 1
            or song.revision ~= 1
            or type(song.title) ~= "string"
            or type(song.draftId) ~= "string"
            or not Sequence.integer(song.dependencyRevision, 1, 1e12)
        then
            return false, "Invalid Finished Song index or revision."
        end
        seen[id] = true
        local ok, songMessage = Project.validate(song.project)
        if not ok then
            return false, songMessage
        end
        if not song.project.drafts[song.draftId] then
            return false, "Finished Song dependencies are incomplete."
        end
    end
    for id in music.finishedSongs do
        count += 1
        if not seen[id] then
            return false, "Unindexed Finished Song."
        end
    end
    if count ~= #music.finishedOrder or count > Project.Limits.FinishedSongs then
        return false, "Finished Song library budget exceeded; nothing was discarded."
    end
    local requests = 0
    for requestId, request in music.finishRequests do
        requests += 1
        if
            type(requestId) ~= "string"
            or #requestId > 96
            or type(request) ~= "table"
            or type(request.songId) ~= "string"
            or not music.finishedSongs[request.songId]
        then
            return false, "Invalid finish-request receipt."
        end
    end
    if requests > Project.Limits.FinishedSongs then
        return false, "Finish-request budget exceeded."
    end
    local bytes, byteMessage = Project.serializedBytes(music, Project.Limits.MusicBytes)
    if not bytes then
        return false, byteMessage
    end
    return true
end

-- Existing explicit music versions are never reimported or sanitized. This is
-- idempotent even after a player has edited imported sequences.
function Migration.import(raw)
    if raw == nil then
        return Migration.new()
    end
    if type(raw) ~= "table" then
        return nil, "Unsupported profile data; original save must be retained."
    end
    if raw.music ~= nil then
        local valid, message = Migration.validate(raw.music)
        if not valid then
            return nil, message
        end
        return Project.clone(raw.music)
    end
    if raw.schema == Migration.Schema and raw.project ~= nil then
        local valid, message = Migration.validate(raw)
        if not valid then
            return nil, message
        end
        return Project.clone(raw)
    end
    if raw.schema ~= nil and raw.schema ~= 1 and raw.schema ~= 2 then
        return nil, "Unsupported future profile schema; no migration or save was attempted."
    end
    local music = Migration.new()
    music.migration = { id = Migration.Id, sourceSchema = raw.schema or 0, complete = true }
    music.legacyPreimage = Project.clone(raw)
    local working, message =
        importBundle(raw, "legacy_working", "Imported working music", raw.revision or 0)
    if working then
        music.project = working
    else
        local id = "legacy_working_readonly"
        music.archives[id] = {
            id = id,
            name = "Original working music",
            kind = "legacy",
            readOnly = true,
            reason = message,
            preimage = Project.clone({
                slots = raw.slots,
                pattern = raw.pattern,
                activeSlot = raw.activeSlot,
            }),
        }
        table.insert(music.archiveOrder, id)
    end
    if raw.shelf ~= nil and type(raw.shelf) ~= "table" then
        return nil, "Unsupported legacy shelf; original profile is retained."
    end
    -- Do not drop non-standard extra entries: preserve them read-only as part of
    -- the complete preimage rather than pretending this migration understood it.
    if not supportedArray(raw.shelf, 6) then
        return nil, "Oversized legacy shelf; original profile is retained read-only."
    end
    for index = 1, 6 do
        local bundle = at(raw.shelf, index)
        if bundle ~= nil and bundle ~= false then
            local id = string.format("legacy_shelf_%02d", index)
            local archive = {
                id = id,
                name = string.format("Imported shelf %02d", index),
                kind = "legacy",
                sourceIndex = index,
                version = type(bundle) == "table" and bundle.version or 0,
                preimage = Project.clone(bundle),
                readOnly = true,
            }
            local imported, reason = importBundle(bundle, id, archive.name, archive.version)
            archive.project, archive.reason = imported, reason
            archive.readOnly = imported == nil
            music.archives[id] = archive
            table.insert(music.archiveOrder, id)
        end
    end
    local valid, validationMessage = Migration.validate(music)
    if not valid then
        return nil, validationMessage
    end
    return music
end

Migration.capture = Project.clone
return Migration
