-- Local Studio ambience, bounded to two overlapping zones. No runtime provider calls.
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Mix = require(script.Parent.AudioMix)
local Soundscape = {}
Soundscape.__index = Soundscape
local zones = {
    { "waterfront", Vector3.new(450, 3, 147), 185, 0.32 },
    { "market", Vector3.new(514, 3, 2), 62, 0.28 },
    { "cafe", Vector3.new(411, 3, 108), 38, 0.3 },
    { "repair", Vector3.new(341, 3, -113), 48, 0.26 },
}
function Soundscape.new()
    local self = setmetatable({ entries = {} }, Soundscape)
    if not RunService:IsStudio() then
        return self
    end
    self.root = Instance.new("Folder")
    self.root.Name = "LocalQuaySoundscape"
    self.root.Parent = workspace
    for index, zone in zones do
        local anchor = Instance.new("Part")
        anchor.Name = zone[1]
        anchor.Size = Vector3.one
        anchor.Position = zone[2]
        anchor.Anchored, anchor.CanCollide, anchor.CanTouch, anchor.CanQuery =
            true, false, false, false
        anchor.Transparency = 1
        anchor.Parent = self.root
        local sound = Instance.new("Sound")
        sound.Name = "AmbientBed"
        sound.SoundId = "rbxasset://needle-quay/ambience/" .. zone[1] .. ".mp3"
        sound.Looped, sound.Volume = true, 0
        sound.RollOffMinDistance = zone[3] * 0.35
        sound.RollOffMaxDistance = zone[3]
        sound.RollOffMode = Enum.RollOffMode.Linear
        sound.Parent = anchor
        table.insert(self.entries, { sound = sound, zone = zone, gain = 0, seed = index * 3.17 })
    end
    self.connection = RunService.Heartbeat:Connect(function(dt)
        self:step(math.min(dt, 0.2))
    end)
    return self
end
function Soundscape:accept(state)
    self.state = state
end
function Soundscape:step(dt)
    local s = self.state
    local character = Players.LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local quiet = not root
        or not s
        or not s.ready
        or Mix.muted
        or s.station
        or s.playing
        or s.recording
        or s.listening
        or (s.jam and s.jam.active)
        or (s.concert and s.concert.playback)
        or (s.quay and s.quay.sideActivity)
    local ranked = {}
    for _, entry in self.entries do
        local zone = entry.zone
        local distance = if root then (root.Position - zone[2]).Magnitude else math.huge
        entry.weight = if quiet then 0 else math.clamp(1 - distance / zone[3], 0, 1)
        table.insert(ranked, entry)
    end
    table.sort(ranked, function(a, b)
        return a.weight > b.weight
    end)
    for index, entry in ranked do
        local target = if index <= 2
            then entry.weight * entry.zone[4] * Mix.ambience * (if Mix.voiceActive
                    or Mix.commissionVoiceActive
                    or Mix.rewardVoiceActive
                then 0.35
                else 1)
            else 0
        entry.gain += (target - entry.gain) * (1 - math.exp(-dt * (if quiet then 12 else 2)))
        entry.sound.Volume = if Mix.muted then 0 else entry.gain
        if target > 0.002 and not entry.sound.IsPlaying then
            entry.sound:Play()
            if entry.sound.IsLoaded and entry.sound.TimeLength > 0 then
                entry.sound.TimePosition = entry.seed % entry.sound.TimeLength
            end
        elseif target == 0 and entry.gain < 0.001 and entry.sound.IsPlaying then
            entry.sound:Stop()
        end
    end
end
function Soundscape:destroy()
    if self.connection then
        self.connection:Disconnect()
    end
    if self.root then
        self.root:Destroy()
    end
end
return Soundscape
