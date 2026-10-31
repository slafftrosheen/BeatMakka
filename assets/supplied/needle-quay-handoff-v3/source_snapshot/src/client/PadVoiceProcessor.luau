local RunService = game:GetService("RunService")
local Settings = require(game.ReplicatedStorage.Shared.PadSound)
local Processor = {}
Processor.__index = Processor
function Processor.new(master)
    local self = setmetatable({ master = master, channels = {}, active = {} }, Processor)
    for pad = 1, 16 do
        local group = Instance.new("SoundGroup")
        group.Name = master.Name .. "_Pad" .. pad
        group.Volume, group.Parent = master.Volume, master.Parent
        local echo = Instance.new("EchoSoundEffect")
        echo.Enabled, echo.Feedback, echo.DryLevel = false, 0.28, 0
        echo.Parent = group
        local reverb = Instance.new("ReverbSoundEffect")
        reverb.Enabled, reverb.DecayTime, reverb.DryLevel = false, 1.1, 0
        reverb.Parent = group
        self.channels[pad] = { group = group, echo = echo, reverb = reverb }
    end
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
                voice.Volume = 0.7 * s.gain * Settings.envelope(s, note.duration, t)
            end
        end
    end)
    return self
end
function Processor:prepare(voice, raw, pad)
    self.active[voice] = nil
    if not raw or not self.channels[pad] then
        voice.SoundGroup, voice.PlaybackSpeed, voice.Volume = self.master, 1, 0.7
        voice.PlaybackRegionsEnabled = false
        return
    end
    local s, channel = Settings.sanitize(raw), self.channels[pad]
    channel.group.Volume = self.master.Volume
    channel.echo.Enabled, channel.reverb.Enabled = s.echo > 0, s.reverb > 0
    channel.echo.Delay = s.delay
    channel.echo.WetLevel = if s.echo > 0 then 20 * math.log10(s.echo) else -80
    channel.reverb.WetLevel = if s.reverb > 0 then 20 * math.log10(s.reverb) else -80
    voice.SoundGroup, voice.PlaybackSpeed = channel.group, 2 ^ (s.pitch / 12)
    local start, finish = s.start * voice.TimeLength, s.finish * voice.TimeLength
    voice.PlaybackRegion = NumberRange.new(start, finish)
    voice.PlaybackRegionsEnabled = true
    voice.TimePosition = start
    local duration = math.max(0.001, (finish - start) / voice.PlaybackSpeed)
    local _, stopAt = Settings.timing(s, duration)
    self.active[voice] = { at = os.clock(), settings = s, duration = duration, stopAt = stopAt }
    voice.Volume = if s.attack > 0 then 0 else 0.7 * s.gain
end
function Processor:stop()
    table.clear(self.active)
    for _, channel in self.channels do
        channel.group.Volume = 0
        channel.echo.Enabled, channel.reverb.Enabled = false, false
    end
end
function Processor:destroy()
    self:stop()
    self.connection:Disconnect()
    self.volumeConnection:Disconnect()
    for _, channel in self.channels do
        channel.group:Destroy()
    end
end
return Processor
