local Workspace = game:GetService("Workspace")
local Shared = game.ReplicatedStorage.Shared
local Project = require(Shared.MusicProject)
local Transport = require(Shared.MusicTransport)
local Catalog = require(Shared.SampleCatalog)
local StageQueue = require(script.Parent.StageQueue)
local ListeningSession = {}
ListeningSession.__index = ListeningSession

function ListeningSession.new(podium, profiles, send, release, nearby, lifecycle)
    local self = setmetatable({
        podium = podium,
        profiles = profiles,
        send = send,
        release = release,
        nearby = nearby,
        members = {},
        revision = 0,
        lifecycle = lifecycle or {},
    }, ListeningSession)
    self.stage =
        StageQueue.new(self, podium, profiles, send, release, nearby, lifecycle and lifecycle.clock)
    local street = Instance.new("Part")
    street.Name, street.Size = "QuayStreetBusking", Vector3.new(5, 1.2, 4)
    street.Position = require(Shared.QuayStreetGames).ById.busk.position
    street.Anchored, street.Color, street.Parent = true, Color3.fromRGB(37, 83, 82), Workspace
    local sign = Instance.new("BillboardGui")
    sign.Size, sign.StudsOffset, sign.MaxDistance, sign.Parent =
        UDim2.fromOffset(190, 42), Vector3.new(0, 4, 0), 65, street
    local caption = Instance.new("TextLabel")
    caption.Size, caption.Text, caption.Font, caption.TextSize =
        UDim2.fromScale(1, 1), "STREET SET / YOUR MUSIC", Enum.Font.Code, 15
    caption.BackgroundColor3, caption.TextColor3, caption.Parent =
        Color3.fromRGB(28, 33, 36), Color3.fromRGB(245, 182, 72), sign
    local prompt = Instance.new("ProximityPrompt")
    prompt.ObjectText, prompt.ActionText = "STREET SET / YOUR MUSIC", "Share / join / stop"
    prompt.MaxActivationDistance, prompt.RequiresLineOfSight, prompt.Parent = 10, false, street
    local function interact(player, anchor)
        local profile = profiles[player]
        if not profile or not profile.ready or not nearby(player, anchor, 11) then
            return
        end
        if os.clock() - (profile.lastListening or 0) < 0.5 then
            return
        end
        profile.lastListening = os.clock()
        if self.owner then
            if self.activeAnchor ~= anchor then
                send(player, "A set is already playing at the other listening area.")
                return
            end
            if self.owner == player then
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
            send(player, "A prepared set has the next courtyard turn. Use the stage board.")
            return
        end
        local prepared, message = self:prepare(player)
        if not prepared then
            send(player, message)
            return
        end
        self:start(player, prepared, if anchor == podium.anchor then nil else anchor)
    end
    prompt.Triggered:Connect(function(player)
        interact(player, street)
    end)
    podium.prompt.Triggered:Connect(function(player)
        interact(player, podium.anchor)
    end)
    return self
end

-- Prepare uses server-owned data only. Finished Songs must exist in the actual
-- accepted save, and a Sequence remains an explicitly looped preview.
function ListeningSession:prepare(player, requested)
    local profile = self.profiles[player]
    if not profile or not profile.music then
        return nil, "Your music is still loading."
    end
    local project = profile.music.project
    local ref = Project.clone(
        requested
            or profile.listeningRef
            or { kind = "sequence", id = profile.sequenceId or project.sequenceOrder[1] }
    )
    if type(ref) ~= "table" then
        return nil, "Choose a Sequence or saved Finished Song."
    end
    if ref.kind == "Sequence" then
        ref.kind = "sequence"
    end
    if ref.kind == "FinishedSong" then
        ref.kind = "finished"
    end
    if ref.kind ~= "sequence" and ref.kind ~= "finished" then
        return nil, "Sharing supports a Sequence or saved Finished Song."
    end
    local songs = profile.saved and profile.saved.music and profile.saved.music.finishedSongs or {}
    if ref.kind == "finished" then
        local song = songs[ref.id]
        if not song then
            return nil, "Choose a successfully saved Finished Song."
        end
        if ref.revision ~= nil and ref.revision ~= song.revision then
            return nil, "That Finished Song revision changed."
        end
        ref.revision = song.revision
    else
        local sequence = project.sequences[ref.id]
        if not sequence then
            return nil, "Choose a named Sequence."
        end
        if ref.revision ~= nil and ref.revision ~= sequence.revision then
            return nil, "That Sequence changed. Select it again."
        end
        ref.revision = sequence.revision
    end
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
        schema = 1,
        ref = ref,
        schedule = schedule,
        title = schedule.title,
        loop = ref.kind == "sequence",
        duration = schedule.duration,
        localOnly = schedule.localOnly == true,
    }
    local bytes, problem = Project.serializedBytes(prepared, 700000)
    if not bytes then
        return nil, problem
    end
    return prepared
end

function ListeningSession:start(player, prepared, anchor)
    if type(prepared) ~= "table" or type(prepared.schedule) ~= "table" then
        return false
    end
    self.release(player)
    self.owner, self.prepared = player, Project.clone(prepared)
    self.activeAnchor = anchor or self.podium.anchor
    self.startedAt = Workspace:GetServerTimeNow() + 0.3
    self.firstLoopEndsAt = self.startedAt + prepared.schedule.duration
    self.firstBarReported = false
    self.performanceEligible = prepared.ref.kind == "sequence"
        and anchor == nil
        and self.lifecycle.eligible ~= nil
        and self.lifecycle.eligible(player, prepared.ref) == true
    self.revision += 1
    self.members[player] = true
    self.podium.prompt.ActionText = "Join / leave listening"
    self.podium.label.Text = (if prepared.loop then "SEQUENCE LOOP / " else "FINISHED SONG / ")
        .. player.DisplayName
    -- Compact musical features for nearby NPCs; no profile/library broadcast.
    local expression = {
        active = true,
        bpm = prepared.schedule.sections[1].bpm,
        startedAt = self.startedAt,
        epoch = self.revision,
        intensity = math.clamp(#prepared.schedule.events / 40, 0, 1),
        steps = table.create(16, 0),
        echo = 0,
        reverb = 0,
        tone = 0,
        drive = 0,
        style = "groove",
    }
    for _, event in prepared.schedule.events do
        expression.steps[math.floor(event.tick % 3840 / 240) + 1] += event.velocity / 127
    end
    local at = self.activeAnchor.Position
    expression.x, expression.y, expression.z = at.X, at.Y, at.Z
    Workspace:SetAttribute("QuayPublicBeat", game:GetService("HttpService"):JSONEncode(expression))
    self.send(
        player,
        if prepared.loop
            then "Sharing a pinned Sequence loop."
            else "Playing your saved Finished Song from beginning to end."
    )
    self.stage:refresh()
    return true
end

function ListeningSession:state(player)
    if not self.owner or not self.members[player] then
        return nil
    end
    return {
        schema = 1,
        ref = self.prepared.ref,
        schedule = self.prepared.schedule,
        title = self.prepared.title,
        startedAt = self.startedAt,
        epoch = self.revision,
        loop = self.prepared.loop,
        offset = 0,
        playing = true,
        performer = self.owner.DisplayName,
        hosting = self.owner == player,
        localOnly = self.prepared.localOnly,
        questPerformance = self.owner == player
            and self.performanceEligible
            and not self.firstBarReported,
        firstLoopEndsAt = self.firstLoopEndsAt,
    }
end

function ListeningSession:reportFirstLoop()
    if
        self.owner
        and not self.firstBarReported
        and Workspace:GetServerTimeNow() >= self.firstLoopEndsAt
        and self.nearby(self.owner, self.activeAnchor or self.podium.anchor, 32)
    then
        self.firstBarReported = true
        if self.performanceEligible and self.lifecycle.performed then
            self.lifecycle.performed(self.owner, self.prepared.ref)
        end
    end
end

function ListeningSession:stop(notice)
    self:reportFirstLoop()
    local members = self.members
    self.members, self.owner, self.prepared, self.performanceEligible = {}, nil, nil, false
    self.revision += 1
    Workspace:SetAttribute("QuayPublicBeat", nil)
    self.podium.prompt.ActionText, self.podium.label.Text =
        "Share selected music", "LISTENING COURT / IDLE"
    for player in members do
        self.send(player, notice)
    end
    self.stage:refresh()
end

function ListeningSession:leave(player)
    if self.owner == player then
        self:stop("The listening set has ended.")
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
    if
        self.owner
        and not self.prepared.loop
        and Workspace:GetServerTimeNow() >= self.startedAt + self.prepared.schedule.completeAt
    then
        self:stop("The Finished Song reached its end.")
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
    else
        self.stage:command(player, action, payload)
    end
end
function ListeningSession:depart(player)
    self.stage:depart(player)
end

return ListeningSession
