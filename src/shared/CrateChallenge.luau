-- One authored constraint over the current canonical kit, never another pack.
-- These are structural checks, not an artistic-quality or acoustic judgement.
local Catalog = require(script.Parent.SampleCatalog)
local Project = require(script.Parent.MusicProject)
local Sequence = require(script.Parent.MusicSequence)
local Song = require(script.Parent.SongArrangement)
local Transport = require(script.Parent.MusicTransport)
local Crate = {
    Id = "quiet_dock_v1",
    Version = 1,
    Bpm = 174,
    SectionBars = 4,
    TotalBars = 8,
    Title = "A quiet dock wakes up",
    Description = "Make four quiet bars with one or two sounds, then four arrival bars with at least three sounds and more note starts. Use this same six-sound crate. There is no timer or winner.",
    PalettePads = { 1, 5, 9, 17, 33, 58 },
    Modes = { "blank", "steady", "offbeat" },
}

local function address(pad)
    return string.format("%s%02d", string.char(65 + math.floor((pad - 1) / 16)), (pad - 1) % 16 + 1)
end

function Crate.palette(unlocked)
    local result = {}
    for _, pad in Crate.PalettePads do
        local sample = Catalog.List[pad]
        table.insert(result, {
            pad = pad,
            id = sample and sample.id or "",
            label = sample and sample.label or "Missing canonical sound",
            address = address(pad),
            ready = sample ~= nil and Catalog.isPlaybackReady(sample.id, unlocked),
        })
    end
    return result
end

local function nextId(project, prefix)
    project.nextId += 1
    return prefix .. "_" .. tostring(project.nextId)
end

local function notes(project, sequence, trackId, pad, velocity, ticks)
    local events = sequence.trackEvents[trackId]
    for _, tick in ticks do
        table.insert(events, {
            eventId = nextId(project, "event"), tick = tick,
            pad = pad, velocity = velocity,
        })
    end
end

-- Both examples are ordinary editable notes. The steady example uses sparse
-- downbeats before a straight pulse; the offbeat example starts between beats
-- and brings in a syncopated answer. Neither requires copying a demo track.
local function populate(project, quiet, arrival, trackId, mode)
    if mode == "steady" then
        notes(project, quiet, trackId, 58, 52, { 0, 7680 })
        notes(project, quiet, trackId, 9, 45, { 3840, 11520 })
        for bar = 0, 3 do
            local at = bar * Sequence.TicksPerBar
            notes(project, arrival, trackId, 1, 106, { at, at + 1920 })
            notes(project, arrival, trackId, 5, 96, { at + 960, at + 2880 })
            notes(project, arrival, trackId, 9, 66, { at + 480, at + 1440, at + 2400, at + 3360 })
        end
        notes(project, arrival, trackId, 17, 91, { 0, 7680 })
        notes(project, arrival, trackId, 33, 78, { 3840 })
    elseif mode == "offbeat" then
        notes(project, quiet, trackId, 17, 64, { 480, 8160 })
        notes(project, quiet, trackId, 58, 48, { 6240, 13920 })
        for bar = 0, 3 do
            local at = bar * Sequence.TicksPerBar
            notes(project, arrival, trackId, 1, 100, { at + 480, at + 2160, at + 3360 })
            notes(project, arrival, trackId, 5, 88, { at + 1440, at + 3120 })
            notes(project, arrival, trackId, 9, 58, { at + 240, at + 1200, at + 2640 })
        end
        notes(project, arrival, trackId, 17, 86, { 960, 6720, 10560 })
        notes(project, arrival, trackId, 33, 76, { 1920, 9600 })
        notes(project, arrival, trackId, 58, 57, { 7200 })
    end
    Sequence.sort(quiet.trackEvents[trackId])
    Sequence.sort(arrival.trackEvents[trackId])
end

function Crate.create(id, mode, unlocked)
    if not table.find(Crate.Modes, mode) then
        return nil, "Choose Start blank, Steady arrival or Offbeat arrival."
    end
    for _, item in Crate.palette(unlocked) do
        if item.id == "" then
            return nil, "The crate's canonical " .. item.address .. " identity is missing. No sound was substituted."
        elseif mode ~= "blank" and not item.ready then
            return nil, "This example needs " .. item.address .. " / " .. item.label
                .. ". Start blank while it is unavailable; no replacement sound was chosen."
        end
    end
    local project = Project.new(id, Crate.Title)
    local quiet = project.sequences[project.sequenceOrder[1]]
    local trackId = project.trackOrder[1]
    local program = project.programs[project.tracks[trackId].programId]
    for _, item in Crate.palette(unlocked) do
        if program.pads[tostring(item.pad)].sampleId ~= item.id then
            return nil, "The canonical kit mapping changed at " .. item.address .. ". No alternate kit or replacement sound was selected."
        end
    end
    quiet.name, quiet.bpm, quiet.bars = "Quiet dock", Crate.Bpm, Crate.SectionBars
    quiet.trackEvents[trackId] = {}
    local arrival = Sequence.new(nextId(project, "seq"), "Arrival", Crate.Bpm, Crate.SectionBars)
    arrival.trackEvents[trackId] = {}
    project.sequences[arrival.id] = arrival
    table.insert(project.sequenceOrder, arrival.id)
    local draft = Song.new(nextId(project, "draft"), Crate.Title, Crate.Bpm)
    draft.steps = {
        { stepId = nextId(project, "step"), sequenceId = quiet.id, repeats = 1 },
        { stepId = nextId(project, "step"), sequenceId = arrival.id, repeats = 1 },
    }
    project.drafts[draft.id], project.draftOrder = draft, { draft.id }
    project.defaultBpm = Crate.Bpm
    project.tracks[trackId].name = "Same crate / harbour kit"
    project.challenge = {
        schema = 1, promptId = Crate.Id, version = Crate.Version,
        quietId = quiet.id, arrivalId = arrival.id, draftId = draft.id, mode = mode,
    }
    populate(project, quiet, arrival, trackId, mode)
    local valid, problem = Project.validate(project)
    if not valid then return nil, problem end
    if mode ~= "blank" then
        local review = Crate.review(project, unlocked)
        if not review.passed then return nil, review.hint end
    end
    return project, nil, { sequenceId = quiet.id, trackId = trackId, draftId = draft.id }
end

local function marked(metadata)
    if type(metadata) ~= "table" or metadata.schema ~= 1
        or metadata.promptId ~= Crate.Id or metadata.version ~= Crate.Version
        or not table.find(Crate.Modes, metadata.mode)
        or type(metadata.quietId) ~= "string" or type(metadata.arrivalId) ~= "string"
        or type(metadata.draftId) ~= "string" or metadata.quietId == metadata.arrivalId then
        return false
    end
    local allowed = { schema = true, promptId = true, version = true, mode = true,
        quietId = true, arrivalId = true, draftId = true }
    for key in metadata do if not allowed[key] then return false end end
    return true
end

local function sounding(schedule)
    local samples, starts = {}, {}
    for _, event in schedule and schedule.events or {} do
        if event.velocity > 0 and event.settings.gain > 0 then
            samples[event.sampleId], starts[event.sequenceTick] = true, true
        end
    end
    local sampleCount, startCount = 0, 0
    for _ in samples do sampleCount += 1 end
    for _ in starts do startCount += 1 end
    return sampleCount, startCount
end

function Crate.review(project, unlocked)
    local result = { present = type(project) == "table" and project.challenge ~= nil,
        passed = true, checks = {}, hint = nil, palette = Crate.palette(unlocked),
        duration = 0, totalBars = 0, localOnly = false }
    local function check(ok, label, fix)
        table.insert(result.checks, { ok = ok == true, label = label, fix = if ok then "" else fix })
        if not ok then
            result.passed = false
            result.hint = result.hint or fix
        end
    end
    local metadata = type(project) == "table" and project.challenge
    check(marked(metadata), "This is the quiet-dock challenge", "Start this challenge to create its two ordinary sections and Draft Song. Existing work is preserved first.")
    if not marked(metadata) then return result end
    local called, valid, problem = pcall(Project.validate, project, true)
    check(called and valid, "The musical project is readable", problem or "Restore a valid musical workspace before checking the prompt.")
    if not called or not valid then return result end
    result.quietId, result.arrivalId, result.draftId = metadata.quietId, metadata.arrivalId, metadata.draftId
    local quiet, arrival, draft = project.sequences[metadata.quietId], project.sequences[metadata.arrivalId], project.drafts[metadata.draftId]
    local sectionsExist = quiet ~= nil and arrival ~= nil and draft ~= nil
    check(sectionsExist, "Quiet dock and Arrival have their Draft Song", "Restore the challenge's Quiet dock and Arrival sections and its Draft Song, or start another preserved attempt.")
    if not sectionsExist then return result end
    result.ref = { kind = "song", id = draft.id, revision = draft.revision }
    local summary = Song.summarize(project, draft)
    if summary then result.duration, result.totalBars = summary.duration, summary.totalBars end
    check(quiet.bars == Crate.SectionBars and arrival.bars == Crate.SectionBars,
        "Two sections, four bars each", "Set both Quiet dock and Arrival to four bars.")
    local stable = project.defaultBpm == Crate.Bpm and quiet.bpm == Crate.Bpm and arrival.bpm == Crate.Bpm
        and draft.bpm == Crate.Bpm and next(quiet.tempoMap) == nil and next(arrival.tempoMap) == nil
    check(stable, "One steady 174 BPM tempo", "Use 174 BPM for both sections and the Draft Song, with no tempo-map changes.")
    local arranged = #draft.steps == 2 and draft.steps[1].sequenceId == quiet.id
        and draft.steps[1].repeats == 1 and draft.steps[2].sequenceId == arrival.id
        and draft.steps[2].repeats == 1
    check(arranged and result.totalBars == Crate.TotalBars, "Quiet dock, then Arrival, once each",
        "Arrange Quiet dock once followed by Arrival once. The intentional ending is after eight bars.")
    local allowed, palettePresent = {}, true
    for _, item in result.palette do
        if item.id == "" then palettePresent = false else allowed[item.id] = true end
    end
    local paletteOnly, outside = palettePresent, nil
    for _, section in { quiet, arrival } do
        for trackId, events in section.trackEvents do
            local track = project.tracks[trackId]
            local program = project.programs[track.programId]
            for _, event in events do
                local id = program.pads[tostring(event.pad)].sampleId
                if not allowed[id] then
                    paletteOnly, outside = false, outside or Catalog.label(id)
                end
            end
        end
    end
    check(paletteOnly, "Every authored note uses the same six sounds",
        if outside then "Remove or reassign " .. outside .. " notes in these two sections, including muted notes. Use only the six displayed sounds."
        else "The canonical six-sound crate is unavailable. No replacement pack was chosen.")
    local options = { requireReady = true, ready = function(id) return Catalog.isPlaybackReady(id, unlocked) end }
    local quietSchedule, quietProblem = Transport.resolve(project, { kind = "sequence", id = quiet.id, revision = quiet.revision }, nil, options)
    local arrivalSchedule, arrivalProblem = Transport.resolve(project, { kind = "sequence", id = arrival.id, revision = arrival.revision }, nil, options)
    local songSchedule, songProblem = Transport.resolve(project, result.ref, nil, options)
    check(quietSchedule ~= nil and arrivalSchedule ~= nil and songSchedule ~= nil,
        "Every sounding note has available, matching audio",
        quietProblem or arrivalProblem or songProblem or "Choose available versions of the crate sounds. Missing audio is never replaced.")
    result.localOnly = (songSchedule and songSchedule.localOnly == true)
        or (quietSchedule and quietSchedule.localOnly == true)
        or (arrivalSchedule and arrivalSchedule.localOnly == true) or false
    local quietSamples, quietStarts = sounding(quietSchedule)
    local arrivalSamples, arrivalStarts = sounding(arrivalSchedule)
    result.quietSamples, result.quietOnsets = quietSamples, quietStarts
    result.arrivalSamples, result.arrivalOnsets = arrivalSamples, arrivalStarts
    check(quietStarts > 0 and arrivalStarts > 0, "Both sections contain sounding notes",
        "Add and unmute notes in each section. Track and pad gain must be above zero.")
    check(quietSamples >= 1 and quietSamples <= 2, "Quiet dock uses one or two sounding sounds",
        "Leave one or two different sounds audible in Quiet dock. Keep room for the arrival.")
    check(arrivalSamples >= 3, "Arrival brings in at least three sounding sounds",
        "Bring in at least three different crate sounds in Arrival; unmute their tracks and pads.")
    check(arrivalStarts > quietStarts, "Arrival has more note starts than Quiet dock",
        "Add more distinct note-start positions in Arrival than Quiet dock. Stacking notes at one position still counts as one start.")
    result.hint = result.hint or "These concrete prompt checks pass. Play the Draft Song from its beginning through its ending; your musical style is your choice."
    return result
end

return Crate
