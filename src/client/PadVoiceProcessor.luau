local RunService = game:GetService("RunService")
local Settings = require(game.ReplicatedStorage.Shared.PadSound)
local Processor = {}
Processor.__index = Processor
-- Authored budgets, not platform limits. Channels are created only when used.
local CHANNEL_LIMIT = 256
local ENGINE_CHANNEL_LIMIT = 64
local allocatedChannels = 0
-- Pitch, gain, trim and envelopes belong to individual Sound voices. Only DSP
-- values need a separate channel while the previous effect tail remains audible.
local settingKeys = { "delay", "drive", "echo", "reverb", "tone" }

local function identity(route)
    if type(route) == "table" then
        return tostring(route.projectId or "")
            .. ":"
            .. tostring(route.trackId or "")
            .. ":"
            .. tostring(route.programId or "")
            .. ":"
            .. tostring(route.absolutePad or route.pad or "")
    end
    return tostring(route)
end

local function channelKey(route, settings)
    local values = { identity(route) }
    -- Changed effect settings get their own channel while an older tail is audible.
    for _, key in settingKeys do
        table.insert(values, string.format("%.17g", settings[key]))
    end
    return table.concat(values, "|")
end

function Processor.new(master)
    local self = setmetatable({
        master = master,
        channels = {},
        active = {},
        count = 0,
        channelCreations = 0,
        preparations = 0,
        prepareSeconds = 0,
        prepareMaxSeconds = 0,
    }, Processor)
    self.volumeConnection = master:GetPropertyChangedSignal("Volume"):Connect(function()
        for _, channel in self.channels do
            channel.group.Volume = master.Volume
        end
    end)
    self.connection = RunService.Heartbeat:Connect(function()
        local now = os.clock()
        for voice, note in self.active do
            local t, s = now - note.at, note.settings
            if not voice.Parent or not voice.IsPlaying or t >= note.stopAt then
                if voice.Parent then
                    voice:Stop()
                end
                self.active[voice] = nil
            else
                voice.Volume = 0.7 * note.velocity * s.gain * Settings.envelope(s, note.duration, t)
            end
        end
    end)
    return self
end

function Processor:_channel(route, settings)
    local key = channelKey(route, settings)
    local channel = self.channels[key]
    if channel then
        return channel
    end
    if allocatedChannels >= CHANNEL_LIMIT or self.count >= ENGINE_CHANNEL_LIMIT then
        local oldestKey, oldest = nil, math.huge
        local now = os.clock()
        for existingKey, existing in self.channels do
            local busy = false
            for _, note in self.active do
                if note.channel == existing then
                    busy = true
                    break
                end
            end
            if not busy and existing.tailUntil <= now and existing.lastUsed < oldest then
                oldestKey, oldest = existingKey, existing.lastUsed
            end
        end
        if not oldestKey then
            return nil
        end
        channel = self.channels[oldestKey]
        self.channels[oldestKey] = nil
        channel.group:Destroy()
        self.count -= 1
        allocatedChannels -= 1
    end
    local group = Instance.new("SoundGroup")
    group.Name = self.master.Name .. "_Route" .. tostring(self.count + 1)
    group.Volume, group.Parent = self.master.Volume, self.master.Parent
    local echo, reverb, tone, drive
    if settings.echo > 0 then
        echo = Instance.new("EchoSoundEffect")
        echo.Feedback, echo.DryLevel, echo.Delay = 0.28, 0, settings.delay
        echo.WetLevel, echo.Parent = 20 * math.log10(settings.echo), group
    end
    if settings.reverb > 0 then
        reverb = Instance.new("ReverbSoundEffect")
        reverb.DecayTime, reverb.DryLevel = 1.1, 0
        reverb.WetLevel, reverb.Parent = 20 * math.log10(settings.reverb), group
    end
    if math.abs(settings.tone) > 0.01 then
        tone = Instance.new("EqualizerSoundEffect")
        tone.Name = "PadTone"
        tone.LowGain, tone.MidGain, tone.HighGain = -settings.tone * 6, 0, settings.tone * 9
        tone.Parent = group
    end
    if settings.drive > 0 then
        drive = Instance.new("DistortionSoundEffect")
        drive.Name, drive.Level, drive.Parent = "PadDrive", settings.drive, group
    end
    channel = {
        group = group,
        echo = echo,
        reverb = reverb,
        tone = tone,
        drive = drive,
        effects = group:GetChildren(),
        lastUsed = os.clock(),
        tailUntil = 0,
        key = key,
    }
    self.channels[key] = channel
    self.count += 1
    self.channelCreations += 1
    allocatedChannels += 1
    return channel
end

function Processor:forget(voice)
    self.active[voice] = nil
end

function Processor:prepare(voice, raw, route, velocity)
    local preparedAt = os.clock()
    self:forget(voice)
    -- Sequence events use MIDI velocity 1..127; omitted velocity is full level.
    velocity = if type(velocity) == "number" and velocity == velocity
        then math.clamp(velocity, 1, 127) / 127
        else 1
    if not raw and route == nil then
        voice.SoundGroup, voice.PlaybackSpeed, voice.Volume = self.master, 1, 0.7 * velocity
        voice.PlaybackRegionsEnabled = false
        return true
    end
    local settings = Settings.sanitize(raw)
    local needsEffects = route ~= nil
        and (
            settings.echo > 0
            or settings.reverb > 0
            or math.abs(settings.tone) > 0.01
            or settings.drive > 0
        )
    -- Dry pad hits require no SoundGroup or DSP allocation, including their
    -- first hit. Trim, ADSR, gain and pitch still run independently per voice.
    local channel = if needsEffects then self:_channel(route, settings) else nil
    if needsEffects and not channel then
        return false
    end
    voice.SoundGroup = if channel then channel.group else self.master
    voice.PlaybackSpeed = 2 ^ (settings.pitch / 12)
    local start, finish = settings.start * voice.TimeLength, settings.finish * voice.TimeLength
    voice.PlaybackRegion = NumberRange.new(start, finish)
    voice.PlaybackRegionsEnabled = true
    voice.TimePosition = start
    local duration = math.max(0.001, (finish - start) / voice.PlaybackSpeed)
    local _, stopAt = Settings.timing(settings, duration)
    local now = os.clock()
    if channel then
        channel.group.Volume = self.master.Volume
        for _, effect in channel.effects do
            effect.Enabled = true
        end
        channel.lastUsed = now
        channel.tailUntil = math.max(
            channel.tailUntil,
            now
                + stopAt
                + math.max(
                    if settings.reverb > 0 then 1.1 else 0,
                    if settings.echo > 0 then settings.delay * 5 else 0
                )
        )
    end
    self.active[voice] = {
        at = now,
        settings = settings,
        duration = duration,
        stopAt = stopAt,
        velocity = velocity,
        channel = channel,
    }
    voice.Volume = if settings.attack > 0 then 0 else 0.7 * settings.gain * velocity
    local seconds = os.clock() - preparedAt
    self.preparations += 1
    self.prepareSeconds += seconds
    self.prepareMaxSeconds = math.max(self.prepareMaxSeconds, seconds)
    return true
end

function Processor:stop()
    for voice in self.active do
        if voice.Parent then
            voice:Stop()
        end
    end
    table.clear(self.active)
    for _, channel in self.channels do
        channel.group.Volume = 0
        for _, effect in channel.effects do
            effect.Enabled = false
        end
        channel.tailUntil = 0
    end
end

function Processor:diagnostics()
    return {
        channels = self.count,
        globalChannels = allocatedChannels,
        channelLimit = CHANNEL_LIMIT,
        engineChannelLimit = ENGINE_CHANNEL_LIMIT,
        channelCreations = self.channelCreations,
        preparations = self.preparations,
        prepareMeanMs = self.prepareSeconds * 1000 / math.max(1, self.preparations),
        prepareMaxMs = self.prepareMaxSeconds * 1000,
    }
end

function Processor:releaseChannels()
    -- Called after this engine has released its musical voices. Cue envelopes
    -- use no route channel and remain independent.
    for _, channel in self.channels do
        channel.group:Destroy()
    end
    allocatedChannels -= self.count
    self.count = 0
    table.clear(self.channels)
end

function Processor:destroy()
    self:stop()
    self.connection:Disconnect()
    self.volumeConnection:Disconnect()
    self:releaseChannels()
end
return Processor
