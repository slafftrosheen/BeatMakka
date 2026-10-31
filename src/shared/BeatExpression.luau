-- Musical features come only from audible notes; this never changes the audio clock.
local Sound = require(script.Parent.PadSound)
local Transport = require(script.Parent.MusicTransport)
local Expression = {}
function Expression.describe(pattern, startedAt, epoch)
    local out = {
        bpm = pattern.bpm,
        startedAt = startedAt,
        epoch = epoch,
        intensity = 0,
        echo = 0,
        reverb = 0,
        drive = 0,
        tone = 0,
        steps = table.create(16, 0),
    }
    local weight = 0
    for pad, row in pattern.rows do
        local settings = Sound.sanitize(pattern.sounds and pattern.sounds[pad])
        if not pattern.muted[pad] and settings.gain > 0 then
            for step, on in row do
                if on then
                    local gain = math.min(settings.gain, 1.5)
                    weight += gain
                    out.steps[step] += gain
                    for _, key in { "echo", "reverb", "drive", "tone" } do
                        out[key] += settings[key] * gain
                    end
                end
            end
        end
    end
    out.active = weight > 0
    out.intensity = math.clamp(weight / 40, 0, 1)
    if weight > 0 then
        for _, key in { "echo", "reverb", "drive", "tone" } do
            out[key] /= weight
        end
    end
    out.style = if out.drive >= 0.16
        then "grit"
        elseif out.echo >= 0.22 or out.reverb >= 0.2 then "space"
        elseif out.tone <= -0.25 then "warm"
        elseif out.tone >= 0.25 then "bright"
        else "groove"
    return out
end
function Expression.phase(expression, now)
    local clock = expression.clock
    if clock and clock.timeline.duration > 0 then
        local elapsed = math.max(0, now - clock.startedAt + (clock.offset or 0))
        local cycles = if clock.loop then math.floor(elapsed / clock.timeline.duration) else 0
        local position = if clock.loop then elapsed % clock.timeline.duration else elapsed
        local cursor = Transport.cursor(clock.timeline, position)
        expression.bpm = cursor.bpm or expression.bpm
        return cycles * clock.timeline.totalBars * 4
            + (cursor.tick or clock.timeline.totalBars * 3840) / 960
    end
    return math.max(0, now - expression.startedAt) * expression.bpm / 60
end

function Expression.change(previous, current)
    if not previous or not current or not previous.active or not current.active then
        return nil
    end
    if previous.style ~= current.style then
        return current.style
    end
    if math.abs(previous.bpm - current.bpm) >= 12 then
        return "tempo"
    end
    if math.abs(previous.intensity - current.intensity) >= 0.2 then
        return "energy"
    end
    return nil
end
function Expression.describeSchedule(schedule, startedAt, epoch, offset, looped)
    if not schedule then
        return nil
    end
    local elapsed = math.max(0, workspace:GetServerTimeNow() - startedAt + (offset or 0))
    local cursor = Transport.cursor(
        schedule,
        if looped and schedule.duration > 0 then elapsed % schedule.duration else elapsed
    )
    local pattern = {
        bpm = cursor.bpm or (schedule.sections[1] and schedule.sections[1].bpm) or 96,
        rows = {},
        sounds = {},
        muted = {},
    }
    -- Presentation derives from the already resolved audible events. It owns no transport.
    for index, event in schedule.events do
        if event.section ~= cursor.section then
            continue
        end
        local row = table.create(16, false)
        row[math.floor((event.tick or 0) / 240) % 16 + 1] = true
        pattern.rows[index] = row
        pattern.sounds[index] = event.settings
    end
    local out = Expression.describe(pattern, startedAt - (offset or 0), epoch)
    out.active = #schedule.events > 0
    out.clock = {
        timeline = {
            sections = schedule.sections,
            tempoSchedule = schedule.tempoSchedule,
            duration = schedule.duration,
            totalBars = schedule.totalBars,
        },
        startedAt = startedAt,
        offset = offset or 0,
        loop = looped == true,
    }
    return out
end
function Expression.fromState(state)
    if not state then
        return nil
    end
    if state.jam and state.jam.active and state.jam.session then
        local bpm, anchor, tracks = require(script.Parent.JamProtocol).resolve(
            state.jam.session,
            workspace:GetServerTimeNow()
        )
        local best
        for _, track in tracks do
            local snapshot = track.snapshot
            if snapshot and snapshot.schedule then
                local protocol = require(script.Parent.JamProtocol)
                local currentSchedule = protocol.schedule(snapshot, bpm)
                if not currentSchedule then
                    continue
                end
                local offset = (track.phaseTick or 0) * 60 / (bpm * 960)
                local value = Expression.describeSchedule(
                    currentSchedule,
                    track.sinceAt or anchor,
                    track.version,
                    offset,
                    true
                )
                value.bpm = bpm
                if not best or value.intensity > best.intensity then
                    best = value
                end
            end
        end
        return best
    end
    local session = state.concert and state.concert.playback or state.listening
    if session and session.schedule then
        return Expression.describeSchedule(
            session.schedule,
            session.startedAt,
            session.epoch,
            session.offset,
            session.loop
        )
    end
    local t = state.music and state.music.transport
    if state.playing and t then
        return Expression.describeSchedule(t.schedule, t.startedAt, t.epoch, t.offset, t.loop)
    end
    return nil
end
return Expression
