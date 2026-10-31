-- One half-open schedule consumer for instrument, jam, street and listening.
local Transport = require(game.ReplicatedStorage.Shared.MusicTransport)
local Playback = {}
Playback.__index = Playback
function Playback.new(audio, played)
    return setmetatable({ audio = audio, played = played, last = nil }, Playback)
end
function Playback:accept(packet)
    if not packet or not packet.schedule then
        self:stop()
        return
    end
    local key = tostring(packet.epoch)
        .. ":"
        .. tostring(packet.startedAt)
        .. ":"
        .. tostring(packet.schedule.source and packet.schedule.source.id)
    if key ~= self.key then
        self.audio:stop()
        local offset = math.max(0, packet.offset or packet.offsetSeconds or 0)
        self.last = if type(packet.scheduleChangedAt) == "number"
            then math.max(offset, packet.scheduleChangedAt - packet.startedAt + offset)
            elseif offset > 0 then offset
            else nil
        self.key = key
    elseif
        packet.scheduleRevision ~= self.scheduleRevision
        and type(packet.scheduleChangedAt) == "number"
    then
        -- Sound/mixer and additive edits retain current voices and the cursor.
        -- Newly inserted notes before this edit's instant must not fire late.
        self.last = math.max(
            self.last or 0,
            packet.scheduleChangedAt - packet.startedAt + (packet.offset or 0)
        )
    end
    self.scheduleRevision = packet.scheduleRevision
    self.packet = packet
    self.audio:setSchedule(packet.schedule)
    if packet.playing == false then
        self.audio:stop()
    end
end
function Playback:step(now)
    local packet = self.packet
    if not packet or packet.playing == false then
        return
    end
    local schedule = packet.schedule
    local elapsed = now - packet.startedAt + (packet.offset or packet.offsetSeconds or 0)
    if now < packet.startedAt or elapsed < 0 or schedule.duration <= 0 then
        return
    end
    local from = if self.last then self.last else math.max(0, elapsed - 0.08)
    -- Stalled frames skip stale notes; they never burst old sections on resume.
    from = math.max(from, elapsed - 0.08)
    local finish = elapsed + 0.000001
    if not packet.loop then
        finish = math.min(finish, schedule.duration)
    end
    if self.last and finish <= self.last then
        return
    end
    local firstCycle = if packet.loop then math.floor(from / schedule.duration) else 0
    local lastCycle = if packet.loop then math.floor(finish / schedule.duration) else 0
    for cycle = firstCycle, lastCycle do
        local offset = cycle * schedule.duration
        for _, event in
            Transport.eventsBetween(
                schedule,
                math.max(0, from - offset),
                math.min(schedule.duration, finish - offset)
            )
        do
            if
                self.audio:play(event.sampleId, event.settings, event.route, event.velocity)
                and self.played
            then
                self.played(event)
            end
        end
    end
    self.last = finish
    if not packet.loop and elapsed >= schedule.completeAt then
        self.audio:stop()
    end
end
function Playback:stop()
    if self.packet then
        self.audio:stop()
    end
    self.packet = nil
    self.audio:setSchedule(nil)
    -- Selection belongs to the instrument/listener, independently of a schedule.
    -- Stopping transport must retain the personal pads' preloaded audition voices.
    self.key = nil
    self.scheduleRevision = nil
    self.last = nil
end
return Playback
