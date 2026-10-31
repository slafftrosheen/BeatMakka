-- Musical evidence uses the shared resolver and successfully saved objects.
-- Names, IDs, silent pads and unavailable planning metadata never count as variation.
-- Studio-local technical playback counts for local progression only; it never
-- changes the catalog's admission or pending human listening-review flags.
local Catalog = require(script.Parent.SampleCatalog)
local Transport = require(script.Parent.MusicTransport)
local Evidence = {}

local function ready(id, unlocked)
    return Catalog.isPlaybackReady(id, unlocked or {})
end

local function canonical(value)
    if type(value) ~= "table" then
        return tostring(value)
    end
    local keys, result = {}, {}
    for key in value do
        table.insert(keys, key)
    end
    table.sort(keys, function(a, b)
        return tostring(a) < tostring(b)
    end)
    for _, key in keys do
        table.insert(result, tostring(key) .. "=" .. canonical(value[key]))
    end
    return "{" .. table.concat(result, ";") .. "}"
end

function Evidence.resolve(project, reference, finished, unlocked)
    if type(project) ~= "table" then
        return nil, "Save a named sequence before returning."
    end
    return Transport.resolve(project, reference, finished, {
        requireReady = true,
        ready = function(id)
            return ready(id, unlocked)
        end,
    })
end

function Evidence.sequence(project, id, unlocked)
    local sequence = project and project.sequences and project.sequences[id]
    if not sequence then
        return nil
    end
    local schedule = Evidence.resolve(project, { kind = "sequence", id = id }, nil, unlocked)
    if not schedule or #schedule.events == 0 then
        return nil
    end
    local notes, positions, parts = {}, {}, {}
    local hasDiscovery, ordinary = false, false
    for _, event in schedule.events do
        local sample = Catalog.ById[event.sampleId]
        local settings = event.settings or {}
        -- Resolver rejects unavailable samples and filters muted routes.
        if (settings.gain or 1) <= 0 or event.velocity <= 0 then
            continue
        end
        local discovery = sample and (sample.discovery or sample.localDiscovery)
        if discovery then
            positions[discovery] = positions[discovery] or {}
            positions[discovery][event.tick] = true
            hasDiscovery = true
        else
            ordinary = true
        end
        parts[tostring(event.trackId) .. ":" .. tostring(event.pad)] = true
        table.insert(
            notes,
            canonical({
                at = event.at,
                sampleId = event.sampleId,
                velocity = event.velocity,
                settings = settings,
                pan = event.pan,
            })
        )
    end
    if #notes == 0 then
        return nil
    end
    table.sort(notes)
    local count = 0
    for _ in parts do
        count += 1
    end
    return {
        id = id,
        sequence = sequence,
        schedule = schedule,
        positions = positions,
        signature = table.concat(notes, "|"),
        layered = hasDiscovery and count >= 2,
        discovery = hasDiscovery,
        ordinary = ordinary,
        parts = count,
        localOnly = schedule.localOnly == true,
    }
end

function Evidence.savedSequences(profile)
    local music = profile.saved and profile.saved.music
    local project = music and music.project
    local result = {}
    if not project then
        return result, nil
    end
    for _, id in project.sequenceOrder or {} do
        local sequence = project.sequences[id]
        if
            sequence
            and (sequence.savedRevision or 0) > 0
            and sequence.savedRevision == sequence.revision
        then
            local evidence = Evidence.sequence(project, id, profile.unlocked)
            if evidence then
                table.insert(result, evidence)
            end
        end
    end
    return result, project
end

function Evidence.finished(profile, id)
    local music = profile.saved and profile.saved.music
    local song = music and music.finishedSongs and music.finishedSongs[id]
    if not song then
        return nil, "Choose a Finished Song that was successfully saved."
    end
    local live = profile.music and profile.music.finishedSongs and profile.music.finishedSongs[id]
    if not live or live.revision ~= song.revision then
        return nil, "Wait for the Finished Song save confirmation."
    end
    local schedule, message = Evidence.resolve(music.project, {
        kind = "finished",
        id = id,
        revision = song.revision,
    }, music.finishedSongs, profile.unlocked)
    if not schedule then
        return nil, message
    end
    local project = song.project
    local distinct, layered, count = {}, false, 0
    for _, section in schedule.sections do
        local sectionEvidence = Evidence.sequence(project, section.sequenceId, profile.unlocked)
        if sectionEvidence then
            distinct[sectionEvidence.signature] = true
            layered = layered
                or sectionEvidence.layered
                or (schedule.localOnly == true and sectionEvidence.parts >= 2)
        end
    end
    for _ in distinct do
        count += 1
    end
    if count < 2 or not layered then
        return nil,
            if schedule.localOnly
                then "Finish an ordered song with two musically different sections and at least two audible parts in one section."
                else "Finish an ordered song with two musically different sections and a collected sound layered with another part."
    end
    if schedule.duration <= 0 or #schedule.events == 0 then
        return nil, "This song has no playable musical duration."
    end
    return {
        song = song,
        schedule = schedule,
        id = song.id,
        revision = song.revision,
        localOnly = schedule.localOnly == true,
    }
end

return Evidence
