local Shared = game.ReplicatedStorage.Shared
local Protocol = require(Shared.JamProtocol)
local Pattern = require(Shared.Pattern)
local AudioEngine = require(script.Parent.AudioEngine)
local Playback = {}
Playback.__index = Playback

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
        self.tracks[slot] = {
            audio = AudioEngine.new(
                "JamTrack" .. slot,
                { musicOnly = true, strictSelection = true, jamTrack = true }
            ),
            absolute = -1,
        }
    end
    -- Read-only, content-free instrumentation for Studio acceptance and support.
    -- It exposes no musical patterns, profile data, control, or test override.
    self.probe = Instance.new("BindableFunction")
    self.probe.Name = "JamTiming"
    self.probe.OnInvoke = function()
        return self:diagnostics()
    end
    self.probe.Parent = game.Players.LocalPlayer.PlayerScripts
    return self
end

local function appendBounded(list, value)
    table.insert(list, value)
    if #list > 256 then
        table.remove(list, 1)
    end
end

function Playback:accept(state, now)
    self.receivedStates += 1
    if not state then
        return
    end
    if
        state.generation < self.generation
        or (state.generation == self.generation and state.revision <= self.revision)
    then
        return
    end
    self.generation, self.revision = state.generation, state.revision
    self.packets += 1
    self.session = if state.active then state.session else nil
    local announced, transports = {}, {}
    local function announce(key)
        announced[key] = self.announced[key] or now
    end
    local function transport(anchor, bpm)
        local key = table.concat({ state.generation, anchor, bpm }, ":")
        transports[key] = self.transportAnnounced[key] or now
    end
    if self.session then
        transport(self.session.anchor, self.session.bpm)
        if self.session.tempo then
            transport(self.session.tempo.applyAt, self.session.tempo.bpm)
        end
    end
    for slot = 1, 2 do
        local renderer = self.tracks[slot]
        local assignments, mask, seen, count = {}, {}, {}, 0
        local function collect(snapshot)
            if not snapshot then
                return
            end
            for pad, enabled in snapshot.mask do
                if not enabled then
                    continue
                end
                local id = snapshot.pattern.assignments[pad]
                if not seen[id] then
                    count += 1
                    seen[id] = true
                    assignments[count] = id
                    mask[count] = true
                end
            end
        end
        if self.session then
            local track, pending =
                self.session.tracks[tostring(slot)], self.session.pending[tostring(slot)]
            if track then
                collect(track.snapshot)
                if track.snapshot then
                    announce(
                        table.concat(
                            { state.generation, slot, track.ownerUserId, track.version },
                            ":"
                        )
                    )
                end
            end
            if pending then
                collect(pending.snapshot)
                announce(
                    table.concat(
                        { state.generation, slot, track.ownerUserId, pending.version },
                        ":"
                    )
                )
                appendBounded(self.leads, (pending.applyAt - now) * 1000)
            end
            if self.session.tempo then
                appendBounded(self.leads, (self.session.tempo.applyAt - now) * 1000)
            end
        else
            renderer.audio:stop()
            renderer.token = nil
            renderer.absolute = -1
        end
        renderer.audio:setSelection(assignments, mask)
    end
    self.announced, self.transportAnnounced = announced, transports
end

function Playback:step(now)
    local session = self.session
    if not session then
        return
    end
    local bpm, anchor, tracks = Protocol.resolve(session, now)
    if self.bpm ~= bpm then
        self.tempoLateness = {}
    end
    self.bpm, self.anchor = bpm, anchor
    for slot = 1, 2 do
        local renderer, track = self.tracks[slot], tracks[slot]
        local snapshot = track and track.snapshot
        if not snapshot or now < track.sinceAt then
            renderer.audio:stop()
            renderer.token = nil
            renderer.absolute = -1
            continue
        end
        local token =
            table.concat({ session.generation, track.ownerUserId, track.version, anchor, bpm }, ":")
        local absolute, step = Pattern.position(bpm, anchor, now)
        if absolute < 0 then
            continue
        end
        if renderer.token ~= token then
            renderer.audio:stop()
            renderer.token = token
            renderer.reported = false
            local trackKey =
                table.concat({ session.generation, slot, track.ownerUserId, track.version }, ":")
            local transportKey = table.concat({ session.generation, anchor, bpm }, ":")
            local prepared = math.max(
                self.announced[trackKey] or now,
                self.transportAnnounced[transportKey] or now
            )
            renderer.startAfter = math.max(anchor, track.sinceAt)
            if prepared > renderer.startAfter - 0.25 then
                -- An unknown late revision stays silent until a fresh whole bar.
                -- Never jump into a phrase or move the other owner's clock.
                renderer.startAfter = Protocol.boundary(anchor, bpm, now)
                self.lateDeferrals += 1
            end
            renderer.absolute = math.floor(
                (renderer.startAfter - anchor) / Pattern.stepDuration(bpm) + 1e-6
            ) - 1
            self.transitions += 1
        end
        if now < renderer.startAfter then
            continue
        end
        if absolute <= renderer.absolute then
            continue
        end
        self.missedSteps += math.max(0, absolute - renderer.absolute - 1)
        renderer.absolute = absolute
        local late = now - anchor - absolute * Pattern.stepDuration(bpm)
        for pad, enabled in snapshot.mask do
            if not enabled then
                continue
            end
            if snapshot.pattern.rows[pad][step] then
                if late >= math.min(0.08, Pattern.stepDuration(bpm) * 0.8) then
                    self.lateSkips += 1
                elseif
                    renderer.audio:play(
                        snapshot.pattern.assignments[pad],
                        snapshot.pattern.sounds and snapshot.pattern.sounds[pad],
                        pad
                    )
                then
                    self.submitted += 1
                    local scheduled = anchor + absolute * Pattern.stepDuration(bpm)
                    local submittedAt = workspace:GetServerTimeNow()
                    appendBounded(self.lateness, (submittedAt - scheduled) * 1000)
                    appendBounded(self.tempoLateness, (submittedAt - scheduled) * 1000)
                    if not renderer.reported then
                        renderer.reported = true
                        appendBounded(self.onsets, {
                            slot = slot,
                            version = track.version,
                            bpm = bpm,
                            scheduledAt = scheduled,
                            submittedAt = submittedAt,
                        })
                    end
                elseif not renderer.audio.muted then
                    self.unready += 1
                end
            end
        end
    end
end

function Playback:setMuted(muted)
    for _, track in self.tracks do
        track.audio:setMuted(muted)
    end
end

local function stats(values)
    local a = table.clone(values)
    table.sort(a)
    return {
        n = #a,
        min = a[1],
        p50 = a[math.max(1, math.ceil(#a * 0.5))],
        p95 = a[math.max(1, math.ceil(#a * 0.95))],
        max = a[#a],
    }
end

function Playback:diagnostics()
    local onsets = {}
    for _, onset in self.onsets do
        table.insert(onsets, table.clone(onset))
    end
    local voices, playing, ready = 0, 0, 0
    for _, track in self.tracks do
        for _, bank in track.audio.banks do
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
        musicPeakBound = 0.56,
        onsets = onsets,
    }
end

function Playback:destroy()
    for _, track in self.tracks do
        track.audio:destroy()
    end
    self.probe:Destroy()
    self.session = nil
end

return Playback
