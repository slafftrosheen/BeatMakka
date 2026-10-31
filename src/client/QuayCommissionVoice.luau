-- Prerecorded local resident speech. No player text, provider calls or asset uploads.
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Clips = require(game.ReplicatedStorage.Shared.QuayCommissionVoiceClips)
local Mix = require(script.Parent.AudioMix)
local Companion = require(script.Parent.CompanionVoice)
local Gui = require(script.Parent.GuiFactory)
local Theme = require(game.ReplicatedStorage.Shared.Theme)
local Voice = {}
Voice.__index = Voice
function Voice.new(screen)
    local self = setmetatable({}, Voice)
    self.anchor = Instance.new("Part")
    self.anchor.Name = "LocalCommissionSpeaker"
    self.anchor.Anchored, self.anchor.CanCollide, self.anchor.CanTouch, self.anchor.CanQuery =
        true, false, false, false
    self.anchor.Transparency = 1
    self.anchor.Parent = workspace
    self.sound = Instance.new("Sound")
    self.sound.Name = "ResidentRequestVoice"
    self.sound.RollOffMinDistance, self.sound.RollOffMaxDistance = 8, 32
    self.sound.Parent = self.anchor
    self.subtitle = Gui.label(screen, "", 17, Theme.Cream)
    self.subtitle.Name = "ResidentSpeech"
    self.subtitle.AnchorPoint = Vector2.new(0.5, 1)
    self.subtitle.Position = UDim2.new(0.5, 0, 1, -102)
    self.subtitle.Size = UDim2.new(0.85, 0, 0, 76)
    self.subtitle.BackgroundColor3 = Theme.Ink
    self.subtitle.BackgroundTransparency = 0.12
    self.subtitle.TextXAlignment = Enum.TextXAlignment.Center
    self.subtitle.ZIndex = 40
    self.subtitle.Visible = false
    Gui.round(self.subtitle, 10)
    local remote = game.ReplicatedStorage.MusicNetwork:WaitForChild("QuayCommissionSpeech", 10)
    self.connections = {
        Mix.Changed.Event:Connect(function()
            self.sound.Volume = if Mix.muted then 0 else Mix.voice
            self.subtitle.Visible = self.current ~= nil and Mix.subtitles
        end),
        self.sound.Ended:Connect(function()
            self:stop()
        end),
        self.sound.Loaded:Connect(function()
            if self.current and self.current.cue ~= "save" then
                self.untilTime = os.clock() + Clips[self.current.key].duration + 0.4
            end
        end),
        RunService.Heartbeat:Connect(function()
            self:step()
        end),
    }
    if remote then
        table.insert(
            self.connections,
            remote.OnClientEvent:Connect(function(event)
                if not Clips[event.key] then
                    return
                end
                self:stop()
                -- Reserve speech immediately so the same finish event cannot start companion speech.
                self.pending = { event = event, expires = os.clock() + 12 }
                Companion.Cue:Fire("silence")
                Mix.commissionVoiceActive = true
                Mix.Changed:Fire()
            end)
        )
    end
    if RunService:IsStudio() then
        task.spawn(function()
            local uris = {}
            for key, clip in Clips do
                if key:sub(-5) ~= "_save" then
                    table.insert(uris, "rbxasset://needle-quay/commission-voices/" .. clip.file)
                end
            end
            pcall(function()
                game:GetService("ContentProvider"):PreloadAsync(uris)
            end)
        end)
    end
    return self
end
function Voice:stop()
    self.sound:Stop()
    self.current, self.pending, self.untilTime = nil, nil, nil
    self.subtitle.Visible = false
    Mix.commissionVoiceActive = false
    Mix.Changed:Fire()
end
function Voice:accept(state)
    self.state = state
end
function Voice:step()
    local event = self.current or (self.pending and self.pending.event)
    if not event then
        return
    end
    local s = self.state
    local character = Players.LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if
        not s
        or not s.ready
        or not root
        or (root.Position - event.position).Magnitude > 28
        or s.station
        or s.playing
        or s.recording
        or s.listening
        or (s.jam and s.jam.active)
        or (s.concert and s.concert.playback)
        or (event.cue == "brief" and (not s.quay or s.quay.open ~= event.host))
    then
        self:stop()
        return
    end
    if self.current then
        if os.clock() >= self.untilTime or os.clock() < (Mix.sampleAuditionUntil or 0) then
            self:stop()
        end
        return
    end
    if os.clock() > self.pending.expires then
        self:stop()
        return
    end
    if Mix.rewardVoiceActive or os.clock() < (Mix.sampleAuditionUntil or 0) then
        return
    end
    local clip = Clips[event.key]
    self.pending, self.current = nil, event
    self.anchor.Position = event.position
    self.subtitle.Text = event.name
        .. ": "
        .. (
            if event.cue == "save"
                then "Save Sequence and wait for confirmation. Bring that named saved version back to me."
                else clip.text
        )
    self.subtitle.Visible = Mix.subtitles
    self.sound.Volume = if Mix.muted then 0 else Mix.voice
    self.untilTime = os.clock() + (if event.cue == "save" then 6 else clip.duration + 0.4)
    if RunService:IsStudio() and event.cue ~= "save" then
        self.sound.SoundId = "rbxasset://needle-quay/commission-voices/" .. clip.file
        if not self.sound.IsLoaded then
            self.untilTime += 4
        end
        self.sound:Play()
    end
end
function Voice:destroy()
    self:stop()
    for _, connection in self.connections do
        connection:Disconnect()
    end
    self.anchor:Destroy()
    self.subtitle:Destroy()
end
return Voice
