-- Local prerecorded cues only. No network speech generation or player text.
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Gui = require(script.Parent.GuiFactory)
local Mix = require(script.Parent.AudioMix)
local Theme = require(game.ReplicatedStorage.Shared.Theme)
local Hints = require(game.ReplicatedStorage.Shared.QuayVoiceHints)
local Clips = require(game.ReplicatedStorage.Shared.QuayGuideVoiceClips)
local Recipes = require(game.ReplicatedStorage.Shared.QuayFxRecipes)
local Voice = {}
Voice.__index = Voice
Voice.Cue = Instance.new("BindableEvent")
Voice.Reaction = Instance.new("BindableEvent")
local lines = {
    alissia = { turn = "Your turn!", success = "Nice one!", route = "Over here." },
    nikolas = { turn = "You got this.", success = "That's the groove!", route = "This way." },
}
local function busy(s, cue)
    return Mix.commissionVoiceActive
        or not s
        or not s.ready
        or (s.station and not Hints.Workshop[cue])
        or os.clock() < (Mix.sampleAuditionUntil or 0)
        or s.playing
        or s.recording
        or s.listening
        or (s.quay and (s.quay.open or s.quay.sideActivity) and cue ~= "turn" and cue ~= "success")
        or (s.stage and s.stage.open)
        or (s.jam and s.jam.active)
        or (s.concert and s.concert.playback)
end
function Voice.new(screen)
    local self = setmetatable(
        { last = {}, selected = "none", pendingFx = {}, nextHint = os.clock() + 8 },
        Voice
    )
    self.sound = Instance.new("Sound")
    self.sound.Name = "LocalCompanionVoice"
    self.sound.Parent = SoundService
    if RunService:IsStudio() then
        task.spawn(function()
            local uris = {}
            for key, clip in Clips do
                local cue = key:match("^[^_]+_(.*)$")
                if not Hints.TextOnly[cue] then
                    table.insert(uris, "rbxasset://needle-quay/guide-voices/" .. clip.file)
                end
            end
            pcall(function()
                game:GetService("ContentProvider"):PreloadAsync(uris)
            end)
        end)
    end
    self.subtitle = Gui.label(screen, "", 18, Theme.Cream)
    self.subtitle.AnchorPoint = Vector2.new(0.5, 1)
    self.subtitle.Position = UDim2.new(0.5, 0, 1, -100)
    self.subtitle.Size = UDim2.new(0.8, 0, 0, 42)
    self.subtitle.BackgroundColor3 = Theme.Ink
    self.subtitle.BackgroundTransparency = 0.15
    self.subtitle.TextXAlignment = Enum.TextXAlignment.Center
    self.subtitle.Visible = false
    self.connections = {
        self.sound.Loaded:Connect(function()
            local clip = Clips[self.selected .. "_" .. tostring(self.currentCue)]
            if self.untilTime and clip and not Hints.TextOnly[self.currentCue] then
                self.untilTime = os.clock() + clip.duration + 0.3
            end
        end),
        Voice.Cue.Event:Connect(function(cue)
            if cue == "silence" then
                self:stop()
                self.nextHint = os.clock() + 10
            elseif cue == "tutorial_cancel" then
                if Hints.Tutorial[self.currentCue] then
                    self:stop()
                end
                self.pendingTutorial = nil
            elseif cue == "mission" then
                local hint = Hints.current(self.state)
                if hint then
                    self:play(hint)
                end
            elseif Hints.Tutorial[cue] then
                self.pendingTutorial = { cue = cue, expires = os.clock() + 8 }
                self.nextHint = os.clock() + 30
                if self.untilTime then
                    self:stop()
                end
            else
                self:play(cue)
            end
        end),
        Mix.Changed.Event:Connect(function()
            self.sound.Volume = if Mix.muted then 0 else Mix.voice
            self.subtitle.Visible = self.untilTime ~= nil and Mix.subtitles
        end),
        RunService.Heartbeat:Connect(function()
            if not self.untilTime then
                self:guide()
                return
            end
            if
                busy(self.state, self.currentCue)
                or os.clock() >= self.untilTime
                or (
                    self.contextRound
                    and (
                        not self.state.quay
                        or not self.state.quay.sideActivity
                        or self.state.quay.sideActivity.serial ~= self.contextRound
                    )
                )
            then
                self:stop()
            end
        end),
    }
    return self
end
function Voice:stop()
    self.sound:Stop()
    self.untilTime, self.contextRound, self.currentCue = nil, nil, nil
    self.subtitle.Visible = false
    Mix.voiceActive = false
    Mix.Changed:Fire()
end
function Voice:play(cue)
    if self.selected ~= "alissia" and self.selected ~= "nikolas" then
        return false
    end
    local words = lines[self.selected]
    local revisedText = Hints.copy(cue, self.state)
    local clip = if Hints.TextOnly[cue] then nil else Clips[self.selected .. "_" .. tostring(cue)]
    local text = revisedText or (clip and clip.text) or (words and words[cue])
    if not text or busy(self.state, cue) or self.untilTime or Mix.rewardVoiceActive then
        return false
    end
    local discovery = cue == "fx_echo"
        or cue == "fx_vent"
        or cue == "fx_lantern"
        or cue == "fx_signal"
    if
        ((clip or revisedText) and not discovery or cue == "route")
        and self.state.companion.hints == false
    then
        return false
    end
    if cue == "route" and self.state.companion.hints == false then
        return
    end
    local key = self.selected .. ":" .. cue
    if os.clock() - (self.last[key] or -100) < 30 then
        return
    end
    self.last[key] = os.clock()
    self.currentCue = cue
    self.untilTime = os.clock()
        + (
            if clip
                then clip.duration + 0.3
                elseif revisedText then math.clamp(#revisedText / 18, 4, 12)
                else 2
        )
    local round = self.state.quay and self.state.quay.sideActivity
    self.contextRound = if cue == "turn" and round then round.serial else nil
    self.subtitle.Text = (if self.selected == "alissia" then "Alissia: " else "Nikolas: ") .. text
    self.subtitle.Visible = Mix.subtitles
    self.sound.Volume = if Mix.muted then 0 else Mix.voice
    -- Local content is intentionally restricted to Studio, never a cloud asset binding.
    if RunService:IsStudio() and not revisedText then
        self.sound.SoundId = if clip
            then "rbxasset://needle-quay/guide-voices/" .. clip.file
            else "rbxasset://needle-quay/voices/" .. key:gsub(":", "_") .. ".wav"
        if clip and not self.sound.IsLoaded then
            self.untilTime += 4
        end
        self.sound:Play()
    end
    Mix.voiceActive = RunService:IsStudio() and not revisedText and not Mix.muted and Mix.voice > 0
    Mix.Changed:Fire()
    self.nextHint = os.clock() + 25
    if discovery then
        Voice.Reaction:Fire()
    end
    return true
end
function Voice:guide()
    local now = os.clock()
    if self.pendingTutorial then
        local pending = self.pendingTutorial
        if now > pending.expires or self:play(pending.cue) then
            self.pendingTutorial = nil
        end
        return
    end
    if #self.pendingFx > 0 then
        local pending = self.pendingFx[1]
        if now > pending.expires or (now >= pending.at and self:play(pending.cue)) then
            table.remove(self.pendingFx, 1)
        end
        return
    end
    if now < self.nextHint or self.hintSpoken then
        return
    end
    local cue = Hints.current(self.state)
    if cue and self:play(cue) then
        self.hintSpoken = true
    end
end
function Voice:accept(state)
    self.state = state
    local companion = state.companion or {}
    local _, hintKey = Hints.current(state)
    if hintKey ~= self.hintKey then
        if
            self.currentCue
            and not Hints.Tutorial[self.currentCue]
            and self.currentCue:sub(1, 3) ~= "fx_"
        then
            self:stop()
        end
        self.hintKey = hintKey
        self.hintSpoken = false
        self.nextHint = os.clock() + 8
    end
    if state.ready and state.quay then
        local earned = {}
        for _, item in Recipes.List do
            earned[item.id] = Recipes.earned(state.quay.progress, item)
            if self.fxSeen and earned[item.id] and not self.fxSeen[item.id] then
                table.insert(self.pendingFx, {
                    cue = Hints.Discoveries[item.id],
                    at = os.clock() + 4,
                    expires = os.clock() + 90,
                })
            end
        end
        self.fxSeen = earned
    end
    if self.selected ~= companion.selected then
        self:stop()
        self.selected = companion.selected or "none"
        self.pendingTutorial = nil
        self.serial = companion.reactionSerial
        return
    end
    local previous = self.serial
    self.serial = companion.reactionSerial
    if previous ~= nil and previous ~= self.serial and companion.reaction == "achievement" then
        self:play("success")
    end
end
function Voice:destroy()
    self:stop()
    for _, connection in self.connections do
        connection:Disconnect()
    end
    self.sound:Destroy()
    self.subtitle:Destroy()
end
return Voice
