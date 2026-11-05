local Workspace = game:GetService("Workspace")
local Shared = game.ReplicatedStorage.Shared
local Project = require(Shared.MusicProject)
local Transport = require(Shared.MusicTransport)
local Catalog = require(Shared.SampleCatalog)
local StageQueue = require(script.Parent.StageQueue)
local Performance = require(script.Parent.StreetPerformance)
local Takes = require(script.Parent.PerformanceTakeSession)
local Crate = require(Shared.CrateChallenge)
local ListeningSession = {}
ListeningSession.__index = ListeningSession

function ListeningSession.new(podium, profiles, send, release, nearby, lifecycle)
    local self = setmetatable({
        podium = podium, profiles = profiles, send = send, release = release,
        nearby = nearby, members = {}, revision = 0, results = {},
        lifecycle = lifecycle or {},
    }, ListeningSession)
    self.stage = StageQueue.new(self, podium, profiles, send, release, nearby, lifecycle and lifecycle.clock)
    local street = Instance.new("Part")
    street.Name, street.Size = "QuayStreetBusking", Vector3.new(5, 1.2, 4)
    street.Position = require(Shared.QuayStreetGames).ById.busk.position
    street.Anchored, street.Color, street.Parent = true, Color3.fromRGB(37, 83, 82), Workspace
    self.streetAnchor = street
    local sign = Instance.new("BillboardGui")
    sign.Size, sign.StudsOffset, sign.MaxDistance, sign.Parent =
        UDim2.fromOffset(190, 42), Vector3.new(0, 4, 0), 65, street
    local caption = Instance.new("TextLabel")
    caption.Size, caption.Text, caption.Font, caption.TextSize =
        UDim2.fromScale(1, 1), "STREET SET / YOUR MUSIC", Enum.Font.Code, 15
    caption.BackgroundColor3, caption.TextColor3, caption.Parent =
        Color3.fromRGB(28, 33, 36), Color3.fromRGB(245, 182, 72), sign
    local prompt = Instance.new("ProximityPrompt")
    prompt.ObjectText, prompt.ActionText = "STREET SET / YOUR MUSIC", "Choose a set / listen"
    prompt.MaxActivationDistance, prompt.RequiresLineOfSight, prompt.Parent = 10, false, street
    prompt.Triggered:Connect(function(player)
        self.stage:open(player, street)
    end)
    for _, venue in podium.venues or {} do
        venue.prompt.Triggered:Connect(function(player) self.stage:open(player, venue.anchor) end)
    end
    podium.prompt.Triggered:Connect(function(player)
        local profile = profiles[player]
        if not profile or not profile.ready or not nearby(player, podium.anchor, 11) then
            return
        end
        if os.clock() - (profile.lastListening or 0) < 0.5 then
            return
        end
        profile.lastListening = os.clock()
        if self.owner then
            if self.activeAnchor ~= podium.anchor then
                send(player, "A set is playing at the street podium. Join there by choice.")
            elseif self.prepared.performance then
                self.stage:open(player, podium.anchor)
            elseif self.owner == player then
                self:stop("The listening set has ended.")
            elseif self.members[player] then
                self:leave(player)
            else
                release(player)
                self.members[player] = true
                send(player, "Joined by choice. Mute or leave at any time.")
            end
            return
        end
        self.stage:tick()
        if self.stage.queue[1] then
            send(player, "A prepared set has the next turn. Use the stage board.")
            return
        end
        local prepared, message = self:prepare(player)
        if not prepared then
            send(player, message)
            return
        end
        self:start(player, prepared)
    end)
    return self
end

-- Only server-owned Sequence data and accepted Finished Songs are resolved.
function ListeningSession:prepare(player, requested)
    local profile = self.profiles[player]
    if not profile or not profile.music then
        return nil, "Your music is still loading."
    end
    local project = profile.music.project
    local ref = Project.clone(requested or profile.listeningRef
        or { kind = "sequence", id = profile.sequenceId or project.sequenceOrder[1] })
    if type(ref) ~= "table" then
        return nil, "Choose a Sequence or saved Finished Song."
    end
    if ref.kind == "challenge" then
        local review = Crate.review(project, profile.unlocked)
        if not review.present or not review.passed or ref.id ~= review.draftId
            or ref.revision ~= review.ref.revision or ref.capture == true then
            return nil, review.hint or "Review this challenge draft before preparing a short show. Take capture is not needed."
        end
        local schedule, problem = Transport.resolve(project, review.ref, nil, {
            requireReady = true, ready = function(id) return Catalog.isPlaybackReady(id, profile.unlocked) end,
        })
        if not schedule then return nil, problem end
        -- Shared names are fixed authored text. Personal draft titles stay private.
        schedule.title = "Same Crate / A quiet dock wakes up"
        for index, section in schedule.sections do section.name = if index == 1 then "Quiet dock" else "Arrival" end
        local prepared = { schema = 1, ref = { kind = "challenge", id = review.draftId,
            revision = review.ref.revision }, schedule = schedule, title = schedule.title,
            loop = false, duration = schedule.duration, mode = "spotlight", capture = false,
            spotlightBars = Crate.TotalBars, localOnly = schedule.localOnly == true }
        local performance, message = Performance.prepare(profile, prepared)
        if not performance then return nil, message end
        prepared.performance, prepared.schedule, prepared.duration = performance, performance.schedule, performance.schedule.duration
        return prepared
    end
    local mode, capture = ref.mode, ref.capture
    ref.mode, ref.capture = nil, nil
    if capture ~= nil and type(capture) ~= "boolean" then
        return nil, "Choose Capture ON or OFF before preparing."
    end
    if ref.kind == "Sequence" then
        ref.kind = "sequence"
    elseif ref.kind == "FinishedSong" then
        ref.kind = "finished"
    end
    if ref.kind ~= "sequence" and ref.kind ~= "finished" then
        return nil, "Sharing supports a Sequence or saved Finished Song."
    end
    mode = mode or (if ref.kind == "sequence" then "practice" else "full")
    if mode ~= "spotlight" and mode ~= (if ref.kind == "sequence" then "practice" else "full") then
        return nil, "Choose Spotlight, Practice loop, or Full Song for this source."
    end
    if capture and mode ~= "spotlight" then
        return nil, "Editable take capture is available for Spotlight only. Practice and Full Song are unchanged."
    end
    local songs = profile.saved and profile.saved.music and profile.saved.music.finishedSongs or {}
    local object = if ref.kind == "finished" then songs[ref.id] else project.sequences[ref.id]
    if not object then
        return nil, "Choose an existing Sequence or successfully saved Finished Song."
    end
    if ref.revision ~= nil and ref.revision ~= object.revision then
        return nil, "That musical revision changed. Select it again."
    end
    ref.revision = object.revision
    local schedule, message = Transport.resolve(project, ref, songs, {
        requireReady = true,
        ready = function(id)
            return Catalog.isPlaybackReady(id, profile.unlocked)
        end,
    })
    if not schedule then
        return nil, message
    end
    if #schedule.events == 0 then
        return nil, "Add an available audible note before sharing."
    end
    local prepared = {
        schema = 1, ref = ref, schedule = schedule, title = schedule.title,
        loop = ref.kind == "sequence", duration = schedule.duration,
        localOnly = schedule.localOnly == true, mode = mode, capture = capture == true,
    }
    if mode == "spotlight" then
        local performance, problem = Performance.prepare(profile, prepared)
        if not performance then
            return nil, problem
        end
        if capture then
            local armed, captureProblem = Takes.arm(profile, performance,
                if ref.kind == "finished" then object.project else project,
                if ref.kind == "finished" then object.draftId else nil)
            if not armed then return nil, captureProblem end
        end
        prepared.performance = performance
        prepared.schedule = performance.schedule
        prepared.loop, prepared.duration = false, performance.schedule.duration
        prepared.localOnly = performance.schedule.localOnly == true
    else
        local bytes, problem = Project.serializedBytes(prepared, 700000)
        if not bytes then
            return nil, problem
        end
    end
    return prepared
end

function ListeningSession:ready(prepared, profile)
    if prepared.capture and profile.performanceTake then return false end
    local function sourceReady(events)
        for _, event in events do
            if not Catalog.isPlaybackReady(event.sampleId, profile.unlocked) then
                return false
            end
        end
        return true
    end
    if not sourceReady(prepared.schedule.events) then
        return false
    end
    for _, source in prepared.performance and prepared.performance.sources or {} do
        for _, events in source.byBar do
            if not sourceReady(events) then
                return false
            end
        end
    end
    return true
end

-- Reuse the existing nearby-NPC music field; no new reaction or reward engine.
function ListeningSession:publishExpression()
    if not self.owner then
        return
    end
    local performance = self.prepared.performance
    local schedule = if performance then performance.schedule else self.prepared.schedule
    local expression = {
        active = true, bpm = schedule.sections[1].bpm, startedAt = self.startedAt,
        epoch = self.revision, intensity = 0, steps = table.create(16, 0),
        echo = 0, reverb = 0, tone = 0, drive = 0, style = "groove",
    }
    local at = self.activeAnchor.Position
    expression.x, expression.y, expression.z = at.X, at.Y, at.Z
    if performance then
        -- A compact presentation timeline is published ahead of the boundary.
        -- The existing music field selects its current frame locally; server
        -- tick frequency and each listener's audio mute do not drive animation.
        expression.barSeconds = 240 / performance.bpm
        expression.expiresAt = self.startedAt + schedule.duration
        expression.frames = {}
        for bar = 1, performance.bars do
            expression.frames[bar] = { active = false, intensity = 0, steps = table.create(16, 0) }
        end
        for _, event in schedule.events do
            local bar = math.floor(event.tick / 3840) + 1
            local frame = expression.frames[bar]
            local weight = event.velocity / 127 * math.min(event.settings.gain or 1, 1.5)
            frame.active = true
            frame.intensity += weight / 12
            frame.steps[math.floor(event.tick % 3840 / 240) + 1] += weight
        end
        for _, frame in expression.frames do
            frame.intensity = math.clamp(frame.intensity, 0, 1)
        end
    else
        for _, event in schedule.events do
            expression.steps[math.floor(event.tick % 3840 / 240) + 1] += event.velocity / 127
        end
        expression.intensity = math.clamp(#schedule.events / 40, 0, 1)
    end
    Workspace:SetAttribute("QuayPublicBeat", game:GetService("HttpService"):JSONEncode(expression))
end

function ListeningSession:start(player, prepared, anchor)
    if self.owner or type(prepared) ~= "table" or type(prepared.schedule) ~= "table" then
        return false
    end
    self.release(player)
    self.owner, self.prepared = player, Project.clone(prepared)
    self.activeAnchor = anchor or self.podium.anchor
    self.startedAt = Workspace:GetServerTimeNow() + 0.3
    self.firstLoopEndsAt = self.startedAt + prepared.schedule.duration
    self.firstBarReported = false
    self.performanceEligible = not prepared.performance and prepared.ref.kind == "sequence"
        and anchor == nil and self.lifecycle.eligible ~= nil
        and self.lifecycle.eligible(player, prepared.ref) == true
    self.revision += 1
    self.members[player] = true
    self.results[player] = nil
    if self.prepared.performance then
        Performance.start(self.prepared.performance, self.revision, self.startedAt)
    end
    self.podium.prompt.ActionText = "Join / leave listening"
    self.podium.label.Text = (if prepared.mode == "spotlight" then "SPOTLIGHT / "
        elseif prepared.loop then "PRACTICE LOOP / " else "FULL SONG / ") .. player.DisplayName
    self:publishExpression()
    self.send(player, if prepared.mode == "spotlight"
        then "Spotlight excerpt started. NPC requests are optional; your source music stays unchanged."
        elseif prepared.loop then "Sharing a pinned Practice loop. Stop whenever you choose."
        else "Playing your saved Full Song from beginning to end.")
    self.stage:refresh()
    return true
end

function ListeningSession:performanceState(player)
    local p = self.prepared and self.prepared.performance
    if not p or not self.members[player] then
        return nil
    end
    local summary = Performance.summary(p, player, self.owner, Workspace:GetServerTimeNow())
    summary.capturing = player == self.owner and p.captureProject ~= nil
    return summary
end

function ListeningSession:state(player)
    if not self.owner or not self.members[player] then
        return nil
    end
    local performance = self.prepared.performance
    local schedule = if performance then performance.schedule else self.prepared.schedule
    return {
        schema = 1, ref = self.prepared.ref, schedule = schedule,
        title = self.prepared.title, startedAt = self.startedAt, epoch = self.revision,
        loop = self.prepared.loop, offset = 0, playing = true,
        performer = self.owner.DisplayName, hosting = self.owner == player,
        localOnly = schedule.localOnly == true, mode = self.prepared.mode,
        scheduleRevision = performance and performance.revision,
        scheduleChangedAt = performance and performance.changedAt,
        futureOnly = performance ~= nil,
        performance = self:performanceState(player),
        questPerformance = self.owner == player and self.performanceEligible and not self.firstBarReported,
        firstLoopEndsAt = self.firstLoopEndsAt,
    }
end

function ListeningSession:reportFirstLoop()
    if self.owner and not self.firstBarReported
        and Workspace:GetServerTimeNow() >= self.firstLoopEndsAt
        and self.nearby(self.owner, self.activeAnchor or self.podium.anchor, 32) then
        self.firstBarReported = true
        if self.performanceEligible and self.lifecycle.performed then
            self.lifecycle.performed(self.owner, self.prepared.ref)
        end
    end
end

function ListeningSession:stop(notice)
    self:reportFirstLoop()
    local performance = self.prepared and self.prepared.performance
    local performer, captureNotice = self.owner, nil
    if self.owner and performance then
        local now = Workspace:GetServerTimeNow()
        Performance.tick(performance, now)
        self.results[self.owner] = Performance.result(performance, now >= self.startedAt + performance.schedule.completeAt)
        local profile = self.profiles[self.owner]
        if profile then
            captureNotice = Takes.retain(profile, performance, now)
            self.results[self.owner].captureNotice = captureNotice
        end
    end
    local members = self.members
    self.members, self.owner, self.prepared, self.performanceEligible = {}, nil, nil, false
    self.revision += 1
    Workspace:SetAttribute("QuayPublicBeat", nil)
    self.podium.prompt.ActionText, self.podium.label.Text = "Share selected music", "LISTENING COURT / IDLE"
    for player in members do
        self.send(player, if player == performer and captureNotice then captureNotice else notice)
    end
    self.stage:refresh()
end

function ListeningSession:leave(player)
    if self.owner == player then
        self:stop("The listening set has ended. Source music and saved progress are unchanged.")
    elseif self.members[player] then
        self.members[player] = nil
        self.send(player, "Left listening. Your project is unchanged.")
    end
end

function ListeningSession:tick()
    if self.owner and not self.nearby(self.owner, self.activeAnchor or self.podium.anchor, 32) then
        self:stop("The performer left the listening area. The set has ended.")
        return
    end
    for player in table.clone(self.members) do
        if not self.nearby(player, self.activeAnchor or self.podium.anchor, 32) then
            self:leave(player)
        end
    end
    self:reportFirstLoop()
    if self.owner then
        local now = Workspace:GetServerTimeNow()
        local performance = self.prepared.performance
        if performance then
            local changed = Performance.tick(performance, now)
            if changed then
                for player in self.members do
                    self.send(player)
                end
            end
        end
        local schedule = if performance then performance.schedule else self.prepared.schedule
        if not self.prepared.loop and now >= self.startedAt + schedule.completeAt then
            self:stop(if performance
                then "Spotlight finished. Prepare it again or return to your instrument to make a variation."
                else "The Full Song reached its end.")
        end
    end
    for player in self.results do
        if not self.profiles[player] then
            self.results[player] = nil
        end
    end
    self.stage:tick()
end

function ListeningSession:openBoard(player)
    self.stage:open(player)
end
function ListeningSession:stageState(player)
    return self.stage:state(player)
end
function ListeningSession:command(player, action, payload)
    if action == "ListeningSelect" then
        local prepared, message = self:prepare(player, payload)
        if not prepared then
            self.send(player, message)
            return
        end
        self.profiles[player].listeningRef = prepared.ref
        self.send(player, "Selected " .. prepared.title .. " for the next listening set.")
    elseif action == "ListeningLeave" then
        self:leave(player)
    elseif action == "StageLayer" or action == "StageSequence" or action == "StageTransitionCancel"
        or action == "StageAudienceRequest" or action == "StageRequestAccept" or action == "StageRequestIgnore" then
        local performance = self.prepared and self.prepared.performance
        if not performance or not self.members[player]
            or not self.nearby(player, self.activeAnchor, 32) then
            self.send(player, "Join this spotlight voluntarily before sending a performance request.")
            return
        end
        local ok, message = Performance.command(performance, player, self.owner, action, payload, Workspace:GetServerTimeNow())
        if ok then
            self:publishExpression()
            for member in self.members do
                self.send(member, if member == player then message else nil)
            end
        else
            self.send(player, message)
        end
    else
        return self.stage:command(player, action, payload)
    end
end
function ListeningSession:depart(player)
    self.stage:depart(player)
end

return ListeningSession
