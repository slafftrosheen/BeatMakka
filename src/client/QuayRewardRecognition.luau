-- Personal cosmetic recognition from server-sanitized equipment; no rewards or remote commands.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Rewards = require(game.ReplicatedStorage.Shared.QuayRewards)
local Theme = require(game.ReplicatedStorage.Shared.Theme)
local Gui = require(script.Parent.GuiFactory)
local Icons = require(script.Parent.GameIcons)
local Mix = require(script.Parent.AudioMix)
local Clips = require(game.ReplicatedStorage.Shared.QuayRewardVoiceClips)
local Recognition = {}
Recognition.__index = Recognition
local titleLines = {
    producer = "Our Quay Producer!",
    friend = "Hey, Quay Friend!",
    favorite = "Our block favorite!",
    icon = "The Quay Icon!",
}
local badgeLines = {
    chase = "Quick hands!",
    lantern = "Light keeper!",
    dock = "Thanks for the dock!",
    repair = "Good neighbor!",
    record = "Crate digger!",
    signal = "You lit the quay!",
    echo = "An ear for echoes!",
    pulse = "Pocket rhythm!",
    finale = "Our headliner!",
}
local function busy(state)
    local q = state and state.quay
    return not q
        or not state.ready
        or state.station
        or state.playing
        or state.recording
        or state.listening
        or q.open
        or q.sideActivity
        or (state.concert and state.concert.open)
        or (state.jam and state.jam.open)
end
function Recognition.new(follower, neighbors)
    local self = setmetatable({
        follower = follower,
        neighbors = neighbors,
        enabled = true,
        elapsed = 0,
        nextStreet = os.clock() + 8,
        nextCompanion = os.clock() + 5,
        seen = {},
        companionSeen = {},
        popups = {},
    }, Recognition)
    self.folder = Instance.new("Folder")
    self.folder.Name = "LocalRewardRecognition"
    self.folder.Parent = workspace
    if RunService:IsStudio() then
        task.spawn(function()
            local uris = {}
            for _, clip in Clips do
                table.insert(uris, "rbxasset://needle-quay/reward-voices/" .. clip.file)
            end
            pcall(function()
                game:GetService("ContentProvider"):PreloadAsync(uris)
            end)
        end)
    end
    self.mixConnection = Mix.Changed.Event:Connect(function()
        for _, popup in self.popups do
            popup.label.Visible = Mix.subtitles
            if popup.sound then
                popup.sound.Volume = if Mix.muted then 0 else Mix.voice
            end
        end
        Mix.rewardVoiceActive = self.speaking ~= nil
            and RunService:IsStudio()
            and not Mix.muted
            and Mix.voice > 0
    end)
    self.connection = RunService.Heartbeat:Connect(function(dt)
        self.elapsed += dt
        if self.elapsed < 0.25 then
            return
        end
        self.elapsed = 0
        self:step()
    end)
    return self
end
function Recognition:accept(state)
    self.state = state
end
function Recognition:stopSpeech(anchor)
    if anchor and self.speaking ~= anchor then
        return
    end
    if not self.speaking then
        return
    end
    self.speaking = nil
    self.nextSpeech = os.clock() + 1.5
    Mix.rewardVoiceActive = false
    Mix.Changed:Fire()
end
function Recognition:clear()
    self:stopSpeech()
    self.folder:ClearAllChildren()
    table.clear(self.popups)
    for _, actor in self.neighbors.actors do
        actor.noticeUntil = 0
    end
end
function Recognition:setEffects(enabled)
    self.enabled = enabled
    if not enabled then
        self:clear()
    end
end
function Recognition:popup(position, item, words, follow, clipKey)
    local clip = Clips[clipKey]
    local duration = if clip then clip.duration + 0.35 else 3
    words = if clip then clip.text else words
    local anchor = Instance.new("Part")
    anchor.Name = "RewardNoticed"
    anchor.Anchored = true
    anchor.CanCollide, anchor.CanTouch, anchor.CanQuery = false, false, false
    anchor.Transparency = 1
    anchor.Size = Vector3.one
    anchor.Position = position
    anchor.Parent = self.folder
    local board = Gui.make("BillboardGui", anchor, {
        Adornee = anchor,
        Size = UDim2.fromOffset(180, 62),
        MaxDistance = 35,
        AlwaysOnTop = false,
    })
    local icon = Icons.make(board, item.icon, item.color or Theme.Amber, 30)
    icon.Position = UDim2.new(0.5, -15, 0, 0)
    local label = Gui.label(board, words, 12, Theme.Cream)
    label.Position, label.Size = UDim2.fromOffset(0, 34), UDim2.new(1, 0, 0, 26)
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextStrokeTransparency = 0.2
    label.Visible = Mix.subtitles
    local popup =
        { anchor = anchor, untilTime = os.clock() + duration, follow = follow, label = label }
    local sound
    self.speaking = anchor
    if clip and RunService:IsStudio() then
        sound = Instance.new("Sound")
        sound.Name = "RewardVoice"
        sound.SoundId = "rbxasset://needle-quay/reward-voices/" .. clip.file
        sound.Volume = if Mix.muted then 0 else Mix.voice
        sound.RollOffMode = Enum.RollOffMode.InverseTapered
        sound.RollOffMinDistance, sound.RollOffMaxDistance = 8, 32
        sound.Parent = anchor
        if not sound.IsLoaded then
            popup.untilTime += 4
            sound.Loaded:Connect(function()
                if anchor.Parent then
                    popup.untilTime = os.clock() + duration
                end
            end)
        end
        sound.Ended:Connect(function()
            self:stopSpeech(anchor)
        end)
        sound:Play()
    end
    Mix.rewardVoiceActive = sound ~= nil and not Mix.muted and Mix.voice > 0
    Mix.Changed:Fire()
    popup.sound = sound
    table.insert(self.popups, popup)
end
function Recognition:step()
    local now = os.clock()
    if
        not self.enabled
        or busy(self.state)
        or Mix.voiceActive
        or Mix.commissionVoiceActive
        or self.neighbors.music
        or os.clock() < (Mix.sampleAuditionUntil or 0)
    then
        self:clear()
        return
    end
    for i = #self.popups, 1, -1 do
        local popup = self.popups[i]
        local position = popup.follow()
        if now >= popup.untilTime or not position then
            self:stopSpeech(popup.anchor)
            popup.anchor:Destroy()
            table.remove(self.popups, i)
        else
            popup.anchor.Position = position
        end
    end
    local root = Players.LocalPlayer.Character
        and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local humanoid = Players.LocalPlayer.Character
        and Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid or humanoid.Health <= 0 then
        self:clear()
        return
    end
    if self.speaking or now < (self.nextSpeech or 0) then
        return
    end
    local q = self.state.quay
    local equipment = q.rewards or {}
    local candidates = {}
    for _, category in Rewards.Categories do
        local item = Rewards.find(category, equipment[category])
        local target = root.Position
        if category == "roamer" then
            target = q.waypoints and q.waypoints.enter
        end
        if category == "companion" then
            target = self.follower.shown and self.follower.position or nil
        end
        if item and target and (target - root.Position).Magnitude < 24 then
            table.insert(candidates, {
                category = category,
                item = item,
                target = target,
                key = category .. ":" .. item.id,
            })
        end
    end
    -- Least recently noticed items get their turn; toggling equipment cannot reset cooldowns.
    table.sort(candidates, function(a, b)
        return (self.seen[a.key] or -1000) < (self.seen[b.key] or -1000)
    end)
    if now >= self.nextStreet and self.neighbors.enabled and not self.neighbors.music then
        for _, candidate in candidates do
            if now - (self.seen[candidate.key] or -1000) < 90 then
                continue
            end
            local chosen, nearest = nil, 18
            for model, actor in self.neighbors.actors do
                local at = (actor.current or actor.origin).Position
                local distance = (at - root.Position).Magnitude
                if
                    model.Parent
                    and model:GetAttribute("GenericResident")
                    and actor.active
                    and not actor.dancing
                    and now >= (actor.cheerUntil or 0)
                    and now >= (actor.nextRewardNotice or 0)
                    and distance < nearest
                    and (at - candidate.target).Magnitude < 26
                then
                    local params = RaycastParams.new()
                    params.FilterType = Enum.RaycastFilterType.Exclude
                    params.FilterDescendantsInstances = {
                        Players.LocalPlayer.Character,
                        model,
                        self.folder,
                        self.follower.model or self.folder,
                    }
                    if
                        not workspace:Raycast(
                            at + Vector3.new(0, 3, 0),
                            root.Position - (at + Vector3.new(0, 3, 0)),
                            params
                        )
                    then
                        chosen, nearest = actor, distance
                    end
                end
            end
            if chosen then
                chosen.noticeUntil = now + 3
                chosen.noticeKind = candidate.category
                chosen.noticeTarget = candidate.target
                chosen.nextRewardNotice = now + 75
                chosen.greetingUntil = 0
                self.seen[candidate.key] = now
                self.nextStreet = now + 18
                local words = if candidate.category == "title"
                    then titleLines[candidate.item.id]
                    elseif candidate.category == "badge" then badgeLines[candidate.item.id]
                    elseif candidate.category == "roamer" then "Love those lights!"
                    else "Nice companion charm!"
                local voice = chosen.model:GetAttribute("RewardVoice") or "street_roger"
                local cue = if candidate.category == "title"
                        or candidate.category == "badge"
                    then candidate.category .. "_" .. candidate.item.id
                    else candidate.category
                self:popup(
                    (chosen.current or chosen.origin).Position + Vector3.new(0, 5, 0),
                    candidate.item,
                    words,
                    function()
                        return chosen.model.Parent
                                and (chosen.current or chosen.origin).Position + Vector3.new(
                                    0,
                                    5,
                                    0
                                )
                            or nil
                    end,
                    voice .. "_" .. cue
                )
                return
            end
        end
    end
    local follower = self.follower
    if
        now < self.nextCompanion
        or not follower.shown
        or not follower.position
        or not follower.enabled
        or self.neighbors.music
        or follower.pendingReaction
        or now < (follower.reactionUntil or 0)
        or now < (follower.pointUntil or 0)
    then
        return
    end
    -- Let the gesture finish before the companion starts walking again.
    if humanoid.MoveDirection.Magnitude > 0.1 then
        return
    end
    for _, candidate in candidates do
        if now - (self.companionSeen[candidate.key] or -1000) < 120 then
            continue
        end
        self.companionSeen[candidate.key] = now
        self.nextCompanion = now + 30
        follower:celebrate(
            if candidate.category == "title" and candidate.item.id == "icon" then 1 else 2
        )
        local words = if candidate.category == "title"
            then "That title suits you!"
            elseif candidate.category == "badge" then "You earned that pin!"
            elseif candidate.category == "roamer" then "Our Roamer looks good!"
            else "Love my new charm!"
        if follower.selected == "nikolas" then
            words = if candidate.category == "title"
                then "Looking like a headliner!"
                elseif candidate.category == "badge" then "That's a keeper!"
                elseif candidate.category == "roamer" then "Now that's our ride!"
                else "A little extra style!"
        end
        self:popup(follower.position + Vector3.new(0, 5.6, 0), candidate.item, words, function()
            return follower.shown
                    and follower.position
                    and follower.position + Vector3.new(0, 5.6, 0)
                or nil
        end, follower.selected .. "_" .. candidate.category)
        break
    end
end
function Recognition:destroy()
    self.connection:Disconnect()
    self.mixConnection:Disconnect()
    self:clear()
    self.folder:Destroy()
end
return Recognition
