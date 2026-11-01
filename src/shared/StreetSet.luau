-- Ephemeral bar timelines built from the normal resolved music schedule.
-- Nothing in this module writes a project, save, reward or audio binding.
local Project = require(script.Parent.MusicProject)
local Sequence = require(script.Parent.MusicSequence)
local Transport = require(script.Parent.MusicTransport)
local Catalog = require(script.Parent.SampleCatalog)
local Set = {
    Lead = 0.35,
    RoleOrder = { "drums", "bass", "hook", "harbour" },
    Labels = { drums = "DRUMS", bass = "BASS", hook = "HOOK", harbour = "HARBOUR" },
    RequestOrder = { "hook", "bass", "harbour" },
    Requests = {
        hook = "Make room for the hook: remove another sounding layer.",
        bass = "Give the bass a full-bar break, then bring it back.",
        harbour = "Feature your harbour sound: leave space around it.",
    },
    BarCounts = { 4, 8, 12, 16, 24 },
    MaxSources = 4,
}

function Set.role(event)
    local sample = Catalog.ById[event.sampleId]
    if sample and (sample.discovery or sample.localDiscovery) then
        return "harbour"
    end
    local bank = sample and sample.bank
    if bank == "A" then
        return "drums"
    elseif bank == "B" then
        return "bass"
    elseif bank == "C" or (bank == "D" and sample.pad <= 8) then
        return "hook"
    end
    return "harbour"
end

function Set.tempo(schedule)
    local bpm = schedule.tempoSchedule[1] and schedule.tempoSchedule[1].bpm
    if not Sequence.integer(bpm, Sequence.MinBpm, Sequence.MaxBpm) then
        return nil
    end
    for _, segment in schedule.tempoSchedule do
        if segment.bpm ~= bpm then
            return nil
        end
    end
    return bpm
end

function Set.source(prepared)
    local schedule = prepared.schedule
    local bpm = Set.tempo(schedule)
    if not bpm then
        return nil, "Spotlights currently need one steady tempo. Practice and Full Song preserve tempo changes."
    end
    local source = {
        ref = Project.clone(prepared.ref), title = prepared.title,
        bpm = bpm, bars = schedule.totalBars, byBar = {}, roles = {},
        localOnly = schedule.localOnly == true,
    }
    if not Sequence.integer(source.bars, 1, Project.Limits.SongBars) then
        return nil, "This source has no supported musical bars."
    end
    for _, event in schedule.events do
        local bar = math.floor(event.tick / Sequence.TicksPerBar) + 1
        source.byBar[bar] = source.byBar[bar] or {}
        local copy = Project.clone(event)
        copy.performanceRole = Set.role(event)
        table.insert(source.byBar[bar], copy)
        source.roles[copy.performanceRole] = true
    end
    return source
end

function Set.length(source)
    local cap = if source.ref.kind == "finished" then math.min(24, source.bars) else 24
    local best, distance = math.min(4, cap), math.huge
    for _, bars in Set.BarCounts do
        if bars <= cap then
            local delta = math.abs(bars * 240 / source.bpm - 30)
            if delta < distance then
                best, distance = bars, delta
            end
        end
    end
    return best
end

-- Queue edits replace only future bars. Prefix events retain exact timestamps,
-- identities and routes, so the existing half-open schedule consumer can continue.
function Set.render(performance, timeline)
    local first = performance.sources[1]
    local secondsPerBar = 240 / performance.bpm
    local schedule = {
        schema = Transport.Schema, source = Project.clone(performance.sourceIdentity),
        title = first.title .. " / Spotlight excerpt", events = {}, sections = {},
        tempoSchedule = {}, duration = performance.bars * secondsPerBar,
        totalBars = performance.bars, expandedEvents = 0, unavailable = {},
        unavailableCount = 0, audioTailSeconds = Transport.AudioTailSeconds,
        localOnly = false,
    }
    local plans, index = {}, 1
    for bar = 1, performance.bars do
        while timeline[index + 1] and timeline[index + 1].bar <= bar do
            index += 1
        end
        local change = timeline[index]
        local source = performance.sources[change.source]
        local sourceBar = (bar - change.originBar) % source.bars + 1
        local at = (bar - 1) * secondsPerBar
        local counts = {}
        for _, event in source.byBar[sourceBar] or {} do
            if not change.mutes[event.performanceRole] then
                if #schedule.events >= Project.Limits.ExpandedEvents then
                    return nil, "Spotlight event budget reached. The current set is unchanged."
                end
                local copy = Project.clone(event)
                local tick = event.tick % Sequence.TicksPerBar
                copy.tick = (bar - 1) * Sequence.TicksPerBar + tick
                copy.at = at + tick * 60 / (performance.bpm * Sequence.PPQ)
                copy.section = bar
                table.insert(schedule.events, copy)
                counts[event.performanceRole] = (counts[event.performanceRole] or 0) + 1
                schedule.localOnly = schedule.localOnly or event.localOnly == true
            end
        end
        plans[bar] = {
            source = change.source, sourceBar = sourceBar, mutes = Project.clone(change.mutes),
            counts = counts, changeBar = change.bar, title = source.title,
        }
        table.insert(schedule.sections, {
            at = at, endAt = at + secondsPerBar, duration = secondsPerBar,
            stepIndex = bar, step = bar, repetition = 1, repeats = 1,
            sequenceId = source.ref.id, name = source.title, bars = 1,
            bpm = performance.bpm, startBar = bar,
            startTick = (bar - 1) * Sequence.TicksPerBar, tempoMap = {},
        })
        table.insert(schedule.tempoSchedule, {
            at = at, endAt = at + secondsPerBar, bpm = performance.bpm, section = bar,
            tick = (bar - 1) * Sequence.TicksPerBar, endTick = bar * Sequence.TicksPerBar,
        })
    end
    schedule.expandedEvents = #schedule.events
    schedule.endAt = schedule.duration
    schedule.completeAt = schedule.duration + schedule.audioTailSeconds
    local bytes, problem = Project.serializedBytes(schedule, 700000)
    if not bytes then
        return nil, problem
    end
    return schedule, plans
end

function Set.active(performance, elapsed)
    local bar = math.clamp(math.floor(math.max(0, elapsed) * performance.bpm / 240) + 1, 1, performance.bars)
    return performance.plans[bar], bar
end

function Set.requests(roles)
    local count = 0
    for _ in roles do
        count += 1
    end
    return {
        hook = roles.hook == true and count >= 2,
        bass = roles.bass == true,
        harbour = roles.harbour == true and count >= 2,
    }
end

-- Structural actions, not music quality. A changed bar must really contain the
-- featured source. Sustained evaluation happens only after this entire bar ends.
function Set.responses(before, after)
    local removed = {}
    for _, role in Set.RoleOrder do
        removed[role] = (before.counts[role] or 0) > 0 and (after.counts[role] or 0) == 0
            and ((not before.mutes[role] and after.mutes[role]) or before.source ~= after.source)
    end
    return {
        hook = (after.counts.hook or 0) > 0 and (removed.drums or removed.bass or removed.harbour),
        bass = (after.counts.bass or 0) > 0 and before.mutes.bass == true and not after.mutes.bass,
        harbour = (after.counts.harbour or 0) > 0 and (removed.drums or removed.bass or removed.hook),
    }
end

return Set
