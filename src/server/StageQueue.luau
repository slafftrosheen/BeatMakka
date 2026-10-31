-- Ephemeral rights for one courtyard stage; does not own music or profile progress.
local Project = require(game.ReplicatedStorage.Shared.MusicProject)
local Catalog = require(game.ReplicatedStorage.Shared.SampleCatalog)
local Workspace = game:GetService("Workspace")
local Stage = {}
Stage.__index = Stage
local LIMIT, LIFETIME, OFFER = 4, 120, 30

function Stage.new(session, podium, profiles, send, release, nearby, clock)
    local self = setmetatable({
        session = session,
        podium = podium,
        profiles = profiles,
        send = send,
        release = release,
        nearby = nearby,
        clock = clock or os.clock,
        queue = {},
        opened = {},
    }, Stage)
    if podium.boardPrompt then
        podium.boardPrompt.Triggered:Connect(function(p)
            self:open(p)
        end)
    end
    return self
end

function Stage:updateOffer()
    local head = self.queue[1]
    if self.session.owner or not head then
        self.offered, self.offerAt = nil, nil
    elseif self.offered ~= head.player then
        self.offered, self.offerAt = head.player, self.clock()
    end
end

function Stage:refresh()
    self:updateOffer()
    local recipients = {}
    for p in self.opened do
        recipients[p] = true
    end
    for _, entry in self.queue do
        recipients[entry.player] = true
    end
    for p in recipients do
        self.send(p)
    end
end

function Stage:remove(p)
    local removed = false
    for i = #self.queue, 1, -1 do
        if self.queue[i].player == p then
            table.remove(self.queue, i)
            removed = true
        end
    end
    self:updateOffer()
    return removed
end

function Stage:open(p)
    local profile = self.profiles[p]
    if not profile or not profile.ready or not self.nearby(p, self.podium.anchor, 11) then
        return
    end
    local now = self.clock()
    if profile.lastStageBoard and now - profile.lastStageBoard < 0.5 then
        return
    end
    profile.lastStageBoard = now
    self.release(p)
    self.opened[p] = true
    self.send(
        p,
        "One stage. Prepare your snapshot or choose to listen. Nothing joins automatically."
    )
end

function Stage:state(p)
    local queue, entries, position = {}, {}, nil
    for i, entry in self.queue do
        table.insert(queue, entry.player.DisplayName)
        table.insert(entries, {
            performer = entry.player.DisplayName,
            title = entry.snapshot.title,
            ref = entry.snapshot.ref,
            duration = entry.snapshot.schedule.duration,
            loop = entry.snapshot.loop,
        })
        if entry.player == p then
            position = i
        end
    end
    local available = {}
    local profile = self.profiles[p]
    local project = profile and profile.music and profile.music.project
    if project then
        for _, id in project.sequenceOrder do
            local sequence = project.sequences[id]
            table.insert(available, {
                kind = "sequence",
                id = id,
                revision = sequence.revision,
                title = sequence.name,
                bars = sequence.bars,
                bpm = sequence.bpm,
                loop = true,
            })
        end
        local saved = profile.saved and profile.saved.music
        for _, id in saved and saved.finishedOrder or {} do
            local song = saved.finishedSongs[id]
            table.insert(available, {
                kind = "finished",
                id = id,
                revision = song.revision,
                title = song.title,
                duration = song.duration,
                loop = false,
            })
        end
    end
    return {
        open = self.opened[p] == true,
        performer = self.session.owner and self.session.owner.DisplayName,
        queue = queue,
        entries = entries,
        available = available,
        selectedRef = profile and profile.listeningRef,
        title = self.session.prepared and self.session.prepared.title,
        performanceRef = self.session.prepared and self.session.prepared.ref,
        duration = self.session.prepared and self.session.prepared.duration,
        position = position,
        requesting = position ~= nil,
        canStart = self.session.owner == nil and position == 1,
        hosting = self.session.owner == p,
        listening = self.session.members[p] == true,
        offerRemaining = if self.offerAt
            then math.max(0, math.ceil(OFFER - (self.clock() - self.offerAt)))
            else nil,
        offerEndsAt = if self.offerAt
            then Workspace:GetServerTimeNow() + math.max(0, OFFER - (self.clock() - self.offerAt))
            else nil,
    }
end

function Stage:tick()
    local now, changed = self.clock(), false
    for i = #self.queue, 1, -1 do
        local entry = self.queue[i]
        local profile = self.profiles[entry.player]
        if
            not profile
            or not profile.ready
            or not self.nearby(entry.player, self.podium.anchor, 32)
            or now - entry.createdAt >= LIFETIME
            or (
                not self.session.owner
                and entry.player == self.offered
                and now - self.offerAt >= OFFER
            )
        then
            table.remove(self.queue, i)
            self.send(entry.player, "Your stage request ended. Prepare another set when ready.")
            changed = true
        end
    end
    for p in self.opened do
        if not self.profiles[p] or not self.nearby(p, self.podium.anchor, 32) then
            self.opened[p] = nil
            self.send(p, "Stage board closed. Return to the courtyard to take part.")
            changed = true
        end
    end
    self:updateOffer()
    if changed then
        self:refresh()
    end
end

function Stage:depart(p)
    local associated = self.opened[p] or self.session.members[p]
    self.opened[p] = nil
    local removed = self:remove(p)
    self.session:leave(p)
    if associated or removed then
        self:refresh()
    end
end

function Stage:command(p, action, payload)
    if action == "StageClose" then
        self:depart(p)
        self.send(p, "Left the stage. Your music and earned progress are unchanged.")
        return
    end
    self:tick()
    local profile = self.profiles[p]
    if
        not profile
        or not profile.ready
        or not self.opened[p]
        or not self.nearby(p, self.podium.anchor, 32)
    then
        return
    end
    if action == "StagePrepare" then
        if self.session.owner == p then
            self.send(p, "Stop your current set before preparing another.")
            return
        end
        for _, entry in self.queue do
            if entry.player == p then
                self.send(p, "Your snapshot is already prepared. Cancel before replacing it.")
                return
            end
        end
        if #self.queue >= LIMIT then
            self.send(p, "Four sets are waiting. Try again after a turn opens.")
            return
        end
        local snapshot, message = self.session:prepare(p, payload)
        if not snapshot then
            self.send(p, message)
            return
        end
        profile.listeningRef = Project.clone(snapshot.ref)
        table.insert(self.queue, { player = p, snapshot = snapshot, createdAt = self.clock() })
        self:refresh()
        self.send(
            p,
            "Snapshot prepared. Start when your turn is offered. You have not joined anyone's audio."
        )
    elseif action == "StageCancel" then
        if self:remove(p) then
            self:refresh()
        end
        self.send(p, "Your prepared snapshot was removed.")
    elseif action == "StageStart" then
        local entry = self.queue[1]
        if self.session.owner or not entry or entry.player ~= p then
            self.send(p, "Wait for your own offered turn.")
            return
        end
        for _, event in entry.snapshot.schedule.events do
            if not Catalog.isPlaybackReady(event.sampleId, profile.unlocked) then
                self.send(
                    p,
                    "This prepared set has unavailable audio. Cancel and review it before playing."
                )
                return
            end
        end
        table.remove(self.queue, 1)
        self.session:start(p, entry.snapshot)
    elseif action == "StageJoin" then
        if self.session.owner and not self.session.members[p] then
            self.release(p)
            self.session.members[p] = true
            self.send(p, "Joined voluntarily. Mute or leave at any time.")
        end
    elseif action == "StageStop" then
        if self.session.owner == p then
            self.session:stop("This set ended. Choose to join the next performer when ready.")
        end
    end
end
return Stage
