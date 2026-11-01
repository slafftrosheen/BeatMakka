-- Read-only scene evidence from the accepted playback schedule, never audio or rewards.
local Sequence = require(script.Parent.MusicSequence)
local Set = require(script.Parent.StreetSet)
local Catalog = require(script.Parent.SampleCatalog)
local Signatures = {}
local cache = setmetatable({}, { __mode = "k" })

local function lastAt(values, position)
    local low, high, found = 1, #values, nil
    while low <= high do
        local middle = math.floor((low + high) / 2)
        if values[middle] <= position then
            found, low = values[middle], middle + 1
        else
            high = middle - 1
        end
    end
    return found
end

local function pulse(values, position, start, duration)
    local at = lastAt(values, position)
    if not at or at < start or position - at >= duration then
        return 0
    end
    return 1 - (position - at) / duration
end

local function idle(reason)
    return {
        active = false, drums = 0, helper = 0, climax = false,
        roleCount = 0, roles = {}, bar = 0,
        caption = reason or "NPC VENUE / space between the notes",
    }
end

function Signatures.compile(schedule)
    if cache[schedule] then
        return cache[schedule]
    end
    local index = { bars = {}, drums = {}, replies = {}, duration = schedule.duration or 0 }
    local segments = schedule.tempoSchedule or {}
    local segmentIndex = 1
    local function secondsAt(tick)
        while segments[segmentIndex + 1] and segments[segmentIndex + 1].tick <= tick do
            segmentIndex += 1
        end
        local segment = segments[segmentIndex]
        if not segment then
            return nil
        end
        return segment.at + (tick - segment.tick) * 60 / (Sequence.PPQ * segment.bpm)
    end
    for bar = 1, schedule.totalBars or 0 do
        local at = secondsAt((bar - 1) * Sequence.TicksPerBar)
        local finish = secondsAt(bar * Sequence.TicksPerBar)
        if not at or not finish then
            break
        end
        index.bars[bar] = { at = at, endAt = finish, roles = {}, roleFirst = {}, count = 0 }
    end
    local lastCall, previousCall, lastDrum, lastReply
    -- MusicTransport and StreetSet both return events in chronological order.
    for _, event in schedule.events or {} do
        local bar = math.floor(event.tick / Sequence.TicksPerBar) + 1
        local frame = index.bars[bar]
        if not frame or event.velocity <= 0 or (event.settings and event.settings.gain or 1) <= 0 then
            continue
        end
        local role = Set.role(event)
        if not frame.roles[role] then
            frame.roles[role], frame.count = true, frame.count + 1
            frame.roleFirst[role] = event.at
        end
        frame.first = frame.first or event.at
        local sample = Catalog.ById[event.sampleId]
        local helper = sample and (sample.discovery == "I03" or sample.localDiscovery == "I03")
        if role == "drums" then
            frame.firstDrum = frame.firstDrum or event.at
            -- Bound visual pulses only. Never remove or reschedule musical hits.
            if not lastDrum or event.at - lastDrum >= 0.32 then
                table.insert(index.drums, event.at)
                lastDrum = event.at
            end
        end
        if helper then
            local previous = index.bars[bar - 1]
            local call = if lastCall == event.at then previousCall else lastCall
            if call and call < event.at and call >= (previous and previous.at or frame.at) then
                frame.firstReply = frame.firstReply or event.at
                if not lastReply or event.at - lastReply >= 0.75 then
                    table.insert(index.replies, event.at)
                    lastReply = event.at
                end
            end
        else
            if lastCall ~= event.at then
                previousCall, lastCall = lastCall, event.at
            end
        end
    end
    local lastClimax = -math.huge
    for bar, frame in index.bars do
        local before = index.bars[bar - 1]
        -- An authored, optional return of layers, not a music-quality score.
        -- Time alone cannot qualify: a lighter preceding bar and real notes are required.
        frame.climax = before ~= nil
            and bar >= math.max(2, math.ceil(#index.bars * 2 / 3))
            and frame.count >= 3 and before.count < frame.count
            and (frame.roles.drums == true or frame.roles.bass == true)
            and (frame.roles.hook == true or frame.roles.harbour == true)
            and bar - lastClimax >= 4
        if frame.climax then
            lastClimax = bar
            frame.climaxAt = frame.first
            for _, at in frame.roleFirst do
                frame.climaxAt = math.max(frame.climaxAt, at)
            end
        end
    end
    cache[schedule] = index
    return index
end

function Signatures.sample(index, elapsed, looped)
    if not index or elapsed < 0 or index.duration <= 0 then
        return idle("NPC VENUE / waiting for the music")
    end
    if not looped and elapsed >= index.duration then
        return idle("NPC VENUE / arrangement ended; sound tails may continue")
    end
    local position = if looped then elapsed % index.duration else elapsed
    local low, high, bar = 1, #index.bars, 0
    while low <= high do
        local middle = math.floor((low + high) / 2)
        if index.bars[middle].at <= position then
            bar, low = middle, middle + 1
        else
            high = middle - 1
        end
    end
    local frame = index.bars[bar]
    if not frame or position >= frame.endAt or not frame.first or position < frame.first then
        return idle()
    end
    local drums = frame.firstDrum ~= nil and position >= frame.firstDrum
    local reply = frame.firstReply ~= nil and position >= frame.firstReply
    local climax = frame.climaxAt ~= nil and position >= frame.climaxAt
    local roles, count = {}, 0
    for role, at in frame.roleFirst do
        if position >= at then
            roles[role], count = true, count + 1
        end
    end
    return {
        active = true, bar = bar, roles = roles, roleCount = count,
        drums = pulse(index.drums, position, frame.at, 0.32),
        helper = pulse(index.replies, position, frame.at, 0.6),
        dockActive = drums, helperActive = reply,
        climax = climax,
        caption = if climax
            then "NPC VENUE / layers return together"
            elseif reply then "NPC MICA / helper answers your phrase"
            elseif drums then "NPC DOCK / percussion drives the glow"
            else "NPC VENUE / listening to your parts",
    }
end

return Signatures
