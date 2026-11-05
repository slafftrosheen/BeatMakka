-- Server-owned, ephemeral spotlight control. Source projects are never edited.
local Shared = game:GetService("ReplicatedStorage").Shared
local Project = require(Shared.MusicProject)
local Transport = require(Shared.MusicTransport)
local Catalog = require(Shared.SampleCatalog)
local Set = require(Shared.StreetSet)
local Performance = {}

function Performance.prepare(profile, prepared)
    local source, problem = Set.source(prepared)
    if not source then
        return nil, problem
    end
    local p = {
        sources = { source }, sourceIdentity = Project.clone(prepared.schedule.source),
        bpm = source.bpm, bars = Set.length(source), revision = 1, fulfilled = {},
        evaluated = {}, requestsUsed = {}, requestsCount = 0, timeline = {
            { bar = 1, originBar = 1, source = 1, mutes = {} },
        },
        feedback = "NPC audience / three optional musical requests, not votes.",
    }
    if prepared.ref.kind == "challenge" then
        if prepared.spotlightBars ~= 8 or source.bars ~= 8 then return nil, "This challenge show needs its complete eight-bar draft." end
        p.bars = 8 -- trusted, bounded arrangement; never loop it to fill a longer show
    end
    -- Only compatible variants from this exact current project are pinned.
    -- Finished Songs keep their captured project and do not borrow editor parts.
    if prepared.ref.kind == "sequence" then
        local project = profile.music.project
        for _, id in project.sequenceOrder do
            if #p.sources >= Set.MaxSources then
                break
            end
            if id == prepared.ref.id then
                continue
            end
            local ref = { kind = "sequence", id = id, revision = project.sequences[id].revision }
            local schedule = Transport.resolve(project, ref, nil, {
                requireReady = true,
                ready = function(sampleId)
                    return Catalog.isPlaybackReady(sampleId, profile.unlocked)
                end,
            })
            if schedule and #schedule.events > 0 and Set.tempo(schedule) == p.bpm then
                local variant = Set.source({ ref = ref, title = schedule.title, schedule = schedule })
                table.insert(p.sources, variant)
                if not Project.serializedBytes(p.sources, Project.Limits.MusicBytes) then
                    table.remove(p.sources)
                end
            end
        end
    end
    p.roles = {}
    for _, item in p.sources do
        for role in item.roles do
            p.roles[role] = true
        end
    end
    p.availableRequests = Set.requests(p.roles)
    local schedule, plans = Set.render(p, p.timeline)
    if not schedule then
        return nil, plans
    end
    if #schedule.events == 0 then
        return nil, "The spotlight's opening bars have no audible notes. Choose another source or Practice/Full Song."
    end
    p.schedule, p.plans = schedule, plans
    return p
end

function Performance.start(p, epoch, startedAt)
    p.epoch, p.startedAt = epoch, startedAt
    p.changedAt = startedAt
end

local function install(p, timeline, now)
    local schedule, plans = Set.render(p, timeline)
    if not schedule then
        return false, plans
    end
    p.timeline, p.schedule, p.plans = timeline, schedule, plans
    p.revision += 1
    -- This is the acceptance instant, NOT the future bar boundary. The existing
    -- playback consumer continues unchanged prefix events up to the boundary.
    p.changedAt = now
    return true
end

function Performance.command(p, player, owner, action, packet, now)
    if type(packet) ~= "table" or packet.schema ~= 1 or packet.epoch ~= p.epoch
        or packet.revision ~= p.revision then
        return false, "The set changed. Review the current controls and try again."
    end
    if now >= p.startedAt + p.schedule.duration then
        return false, "This spotlight has reached its ending. Prepare another set to keep playing."
    end
    if action == "StageAudienceRequest" then
        if player == owner or p.requestsUsed[player.UserId] then
            return false, "Each opted-in listener may send one request per set."
        end
        local kind = packet.kind
        if not p.availableRequests[kind] or p.fulfilled[kind] then
            return false, "That request needs different sounding parts, or is already complete."
        end
        if p.suggestion or p.requestsCount >= 4 or now < (p.nextRequestAt or 0) then
            return false, "Another request is pending. The performer keeps control."
        end
        p.requestsUsed[player.UserId] = true
        p.requestsCount += 1
        p.nextRequestAt = now + 8
        p.suggestion = { kind = kind, name = player.DisplayName }
        p.revision += 1
        return true, "Request offered. The performer may accept or ignore it."
    end
    if player ~= owner then
        return false, "Only the performer can change this set."
    end
    if action == "StageRequestAccept" or action == "StageRequestIgnore" then
        if not p.suggestion then
            return false, "There is no pending audience request."
        end
        p.focusRequest = if action == "StageRequestAccept" then p.suggestion.kind else nil
        p.suggestion = nil
        p.revision += 1
        return true, if p.focusRequest then "Request accepted. Choose the musical change yourself." else "Request declined; the music is unchanged."
    end
    if action == "StageTransitionCancel" then
        if not p.pending or now >= p.pending.at - Set.Lead then
            return false, "The change is committed or too close to its boundary to cancel."
        end
        local timeline = Project.clone(p.timeline)
        table.remove(timeline)
        local ok, message = install(p, timeline, now)
        if ok then
            p.pending = nil
        end
        return ok, message or "Queued change cancelled before commitment."
    end
    if action ~= "StageLayer" and action ~= "StageSequence" then
        return false, "Unsupported performance action."
    end
    if p.pending then
        return false, "Let the queued change land, or cancel it before its cutoff."
    end
    local elapsed = math.max(0, now - p.startedAt)
    local barSeconds = 240 / p.bpm
    local bar = math.ceil((elapsed + Set.Lead) / barSeconds) + 1
    if bar > p.bars then
        return false, "No complete bar remains for another change. Let the set finish."
    end
    local previous = p.timeline[#p.timeline]
    local change = Project.clone(previous)
    change.bar = bar
    if action == "StageLayer" then
        if not p.roles[packet.role] or type(packet.muted) ~= "boolean" then
            return false, "Choose an available musical layer."
        end
        if (change.mutes[packet.role] == true) == packet.muted then
            return false, "That layer is already in the requested state."
        end
        change.mutes[packet.role] = packet.muted
    else
        local index = packet.source
        if type(index) ~= "number" or index % 1 ~= 0 or not p.sources[index] then
            return false, "Choose one of this set's pinned sequence variations."
        end
        if index == change.source then
            return false, "That sequence is already playing."
        end
        change.source, change.originBar = index, bar
    end
    local timeline = Project.clone(p.timeline)
    table.insert(timeline, change)
    local ok, message = install(p, timeline, now)
    if not ok then
        return false, message
    end
    p.pending = {
        at = p.startedAt + (bar - 1) * barSeconds, bar = bar,
        source = change.source, mutes = Project.clone(change.mutes),
    }
    return true, "Change queued for bar " .. bar .. ". Existing notes and saves are unchanged."
end

function Performance.tick(p, now)
    local changed = false
    if p.pending and now >= p.pending.at then
        p.pending = nil
        p.revision += 1
        changed = true
    end
    local completedBars = math.min(p.bars, math.floor(math.max(0, now - p.startedAt) * p.bpm / 240))
    for _, change in p.timeline do
        local bar = change.bar
        if bar > 1 and bar <= completedBars and not p.evaluated[bar] then
            p.evaluated[bar] = true
            local responses = Set.responses(p.plans[bar - 1], p.plans[bar])
            for _, kind in Set.RequestOrder do
                if responses[kind] and not p.fulfilled[kind] then
                    p.fulfilled[kind] = true
                    p.feedback = "NPC response: " .. ({
                        hook = "the hook has space now.",
                        bass = "the bass returned after its break.",
                        harbour = "your harbour sound is featured.",
                    })[kind]
                    p.revision += 1
                    changed = true
                end
            end
        end
    end
    return changed
end

function Performance.summary(p, player, owner, now)
    local current, bar = Set.active(p, now - p.startedAt)
    local sources = {}
    for index, source in p.sources do
        table.insert(sources, { index = index, title = source.title, ref = source.ref })
    end
    return {
        epoch = p.epoch, revision = p.revision, startedAt = p.startedAt,
        endsAt = p.startedAt + p.schedule.duration, bars = p.bars, bpm = p.bpm,
        duration = p.schedule.duration, currentBar = bar, current = current,
        pending = p.pending, sources = sources, roles = p.roles,
        fulfilled = p.fulfilled, availableRequests = p.availableRequests,
        suggestion = p.suggestion, focusRequest = p.focusRequest, feedback = p.feedback,
        canRequest = player ~= owner and not p.requestsUsed[player.UserId]
            and p.requestsCount < 4 and p.suggestion == nil and now >= (p.nextRequestAt or 0),
        localOnly = p.schedule.localOnly == true,
    }
end

function Performance.result(p, completed)
    local count = 0
    for _ in p.fulfilled do
        count += 1
    end
    return {
        completed = completed, title = p.sources[1].title, bars = p.bars,
        duration = p.schedule.duration, fulfilled = Project.clone(p.fulfilled),
        count = count, localOnly = p.schedule.localOnly == true,
    }
end

return Performance
