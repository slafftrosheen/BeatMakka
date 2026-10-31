local Protocol = require(game.ReplicatedStorage.Shared.JamProtocol)
local AudioEngine = require(script.Parent.AudioEngine)
local SchedulePlayback = require(script.Parent.SchedulePlayback)
local Playback = {}
Playback.__index = Playback

local function bounded(list, value)
    table.insert(list, value)
    if #list > 256 then
        table.remove(list, 1)
    end
end

function Playback.new()
    local self = setmetatable({
        generation = -1,
        revision = -1,
        tracks = {},
        packets = 0,
        receivedStates = 0,
        submitted = 0,
        unready = 0,
        lateSkips = 0,
        missedSteps = 0,
        lateness = {},
        tempoLateness = {},
        onsets = {},
        leads = {},
        transitions = 0,
        lateDeferrals = 0,
        announced = {},
        transportAnnounced = {},
    }, Playback)
    for slot = 1, 2 do
        local renderer = {
            audio = AudioEngine.new(
                "JamTrack" .. slot,
                { musicOnly = true, strictSelection = true, jamTrack = true }
            ),
        }
        renderer.playback = SchedulePlayback.new(renderer.audio, function(event)
            self.submitted += 1
            local at = workspace:GetServerTimeNow()
            local packet = renderer.packet
            local phase = (at - packet.startedAt + packet.offset) % packet.schedule.duration
            local late = math.max(0, (phase - event.at) * 1000)
            bounded(self.lateness, late)
            bounded(self.tempoLateness, late)
            if not renderer.reported then
                renderer.reported = true
                bounded(self.onsets, {
                    slot = slot,
                    version = renderer.version,
                    bpm = self.bpm,
                    scheduledAt = at - late / 1000,
                    submittedAt = at,
                })
            end
        end)
        self.tracks[slot] = renderer
    end
    self.probe = Instance.new("BindableFunction")
    self.probe.Name = "JamTiming"
    self.probe.OnInvoke = function()
        return self:diagnostics()
    end
    self.probe.Parent = game.Players.LocalPlayer.PlayerScripts
    return self
end

function Playback:accept(state, now)
    now = now or workspace:GetServerTimeNow()
    self.receivedStates += 1
    if not state or state.schema ~= Protocol.Schema then
        self.session = nil
        for _, renderer in self.tracks do
            renderer.playback:stop()
            renderer.audio:setSelection({})
            renderer.token = nil
        end
        return
    end
    if
        type(state.generation) ~= "number"
        or type(state.revision) ~= "number"
        or state.generation < self.generation
        or (state.generation == self.generation and state.revision <= self.revision)
    then
        return
    end
    self.generation, self.revision = state.generation, state.revision
    self.packets += 1
    self.session = if state.active
            and state.session
            and state.session.schema == Protocol.Schema
        then state.session
        else nil
    local announced, transports = {}, {}
    local function transport(anchor, bpm)
        local key = table.concat({ state.generation, anchor, bpm }, ":")
        transports[key] = self.transportAnnounced[key] or now
    end
    if self.session then
        transport(self.session.anchor, self.session.bpm)
        if self.session.tempo then
            transport(self.session.tempo.applyAt, self.session.tempo.bpm)
            bounded(self.leads, (self.session.tempo.applyAt - now) * 1000)
        end
    end
    for slot = 1, 2 do
        local renderer, assignments, seen = self.tracks[slot], {}, {}
        local function collect(snapshot)
            if not snapshot or snapshot.schema ~= Protocol.Schema then
                return
            end
            for _, event in snapshot.schedule.events do
                if not seen[event.sampleId] then
                    seen[event.sampleId] = true
                    table.insert(assignments, event.sampleId)
                end
            end
        end
        if self.session then
            local track, pending =
                self.session.tracks[tostring(slot)], self.session.pending[tostring(slot)]
            if track then
                collect(track.snapshot)
                local key =
                    table.concat({ state.generation, slot, track.ownerUserId, track.version }, ":")
                announced[key] = self.announced[key] or now
            end
            if pending and track then
                collect(pending.snapshot)
                local key = table.concat(
                    { state.generation, slot, track.ownerUserId, pending.version },
                    ":"
                )
                announced[key] = self.announced[key] or now
                bounded(self.leads, (pending.applyAt - now) * 1000)
            end
        else
            renderer.playback:stop()
            renderer.token = nil
        end
        -- Keep current and queued dependencies warm without indexing by pads.
        renderer.audio:setSelection(assignments)
    end
    self.announced, self.transportAnnounced = announced, transports
end

function Playback:step(now)
    local session = self.session
    if not session then
        return
    end
    local bpm, anchor, tracks = Protocol.resolve(session, now)
    if not bpm then
        return
    end
    if self.bpm ~= bpm then
        self.tempoLateness = {}
    end
    self.bpm, self.anchor = bpm, anchor
    for slot = 1, 2 do
        local renderer, track = self.tracks[slot], tracks[slot]
        if not track or not track.snapshot then
            renderer.playback:stop()
            renderer.token = nil
            continue
        end
        local token = table.concat(
            { session.generation, track.ownerUserId, track.version, anchor, bpm, track.sinceAt },
            ":"
        )
        if renderer.token ~= token then
            local schedule = Protocol.schedule(track.snapshot, bpm)
            if not schedule then
                renderer.playback:stop()
                self.unready += 1
                continue
            end
            local trackKey =
                table.concat({ session.generation, slot, track.ownerUserId, track.version }, ":")
            local transportKey = table.concat({ session.generation, anchor, bpm }, ":")
            local prepared = math.max(
                self.announced[trackKey] or now,
                self.transportAnnounced[transportKey] or now
            )
            local startAfter = math.max(anchor, track.sinceAt)
            if prepared > startAfter - 0.25 then
                startAfter = Protocol.boundary(anchor, bpm, now)
                self.lateDeferrals += 1
            end
            local offset = (
                (track.phaseTick or 0) * 60 / (bpm * 960) + math.max(0, startAfter - track.sinceAt)
            ) % schedule.duration
            renderer.token, renderer.reported, renderer.version = token, false, track.version
            renderer.packet = {
                schedule = schedule,
                startedAt = startAfter,
                offset = offset,
                epoch = token,
                loop = true,
                playing = true,
            }
            renderer.playback:accept(renderer.packet)
            self.transitions += 1
        end
        renderer.playback:step(now)
    end
end

function Playback:setMuted(muted)
    for _, renderer in self.tracks do
        renderer.audio:setMuted(muted)
    end
end

local function stats(values)
    local copy = table.clone(values)
    table.sort(copy)
    return {
        n = #copy,
        min = copy[1],
        max = copy[#copy],
        p50 = copy[math.max(1, math.ceil(#copy * 0.5))],
        p95 = copy[math.max(1, math.ceil(#copy * 0.95))],
    }
end

function Playback:diagnostics()
    local voices, playing, ready = 0, 0, 0
    for _, renderer in self.tracks do
        for _, bank in renderer.audio.banks do
            if bank.state == "ready" then
                ready += 1
            end
            for _, voice in bank.voices do
                voices += 1
                if voice.IsPlaying then
                    playing += 1
                end
            end
        end
    end
    return {
        schema = Protocol.Schema,
        generation = self.generation,
        revision = self.revision,
        active = self.session ~= nil,
        bpm = self.bpm,
        anchor = self.anchor,
        packets = self.packets,
        receivedStates = self.receivedStates,
        submitted = self.submitted,
        unready = self.unready,
        lateSkips = self.lateSkips,
        missedSteps = self.missedSteps,
        latenessMs = stats(self.lateness),
        currentTempoLatenessMs = stats(self.tempoLateness),
        arrivalLeadMs = stats(self.leads),
        transitions = self.transitions,
        lateDeferrals = self.lateDeferrals,
        allocatedVoices = voices,
        playingVoices = playing,
        readyBanks = ready,
        muted = self.tracks[1].audio.muted,
        onsets = table.clone(self.onsets),
    }
end

function Playback:destroy()
    for _, renderer in self.tracks do
        renderer.playback:stop()
        renderer.audio:destroy()
    end
    self.probe:Destroy()
    self.session = nil
end

return Playback
