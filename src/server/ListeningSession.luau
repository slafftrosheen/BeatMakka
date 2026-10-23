local Workspace = game:GetService("Workspace")
local Pattern = require(game:GetService("ReplicatedStorage").Shared.Pattern)
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
    podium.prompt.Triggered:Connect(function(player)
        local profile = profiles[player]
        if not profile or not profile.ready or not nearby(player, podium.anchor, 11) then
            return
        end
        local now = os.clock()
        if profile.lastListening and now - profile.lastListening < 0.5 then
            return
        end
        profile.lastListening = now
        if self.owner == player then
            self:stop("The listening session has ended.")
        elseif self.owner then
            if self.members[player] then
                self:leave(player)
            else
                release(player)
                self.members[player] = true
                send(player, "Joined the courtyard loop. Mute or leave at any time.")
            end
        else
            self.stage:tick()
            if self.stage.queue[1] then
                self.stage:open(player)
                send(player, "A prepared set has the next turn. Use the stage board when offered.")
                return
            end
            local snapshot = Pattern.sanitize(profile.pattern, profile.unlocked)
            local audible = false
            for pad, row in snapshot.rows do
                if not snapshot.muted[pad] then
                    for _, enabled in row do
                        audible = audible or enabled
                    end
                end
            end
            if not audible then
                send(player, "Make a loop with an unmuted step at a workshop sampler first.")
                return
            end
            self:start(player, snapshot)
        end
    end)
    return self
end

function ListeningSession:start(player, snapshot)
    self.release(player)
    self.owner = player
    self.pattern = snapshot
    self.startedAt = Workspace:GetServerTimeNow() + 0.3
    self.firstLoopEndsAt = self.startedAt + Pattern.Steps * Pattern.stepDuration(snapshot.bpm)
    self.firstBarReported = false
    self.performanceEligible = self.lifecycle.eligible ~= nil
        and self.lifecycle.eligible(player, snapshot) == true
    self.revision += 1
    local revision = self.revision
    task.delay(self.firstLoopEndsAt - Workspace:GetServerTimeNow(), function()
        if self.owner == player and self.revision == revision then
            self:reportFirstLoop()
        end
    end)
    self.members[player] = true
    self.podium.prompt.ActionText = "Join / leave listening"
    self.podium.label.Text = "LIVE LOOP / " .. player.DisplayName
    self.send(player, "Sharing a snapshot of your loop. Stop sharing from the listening controls.")
    self.stage:refresh()
end

function ListeningSession:state(player)
    if not self.owner or not self.members[player] then
        return nil
    end
    return {
        pattern = self.pattern,
        startedAt = self.startedAt,
        epoch = self.revision,
        performer = self.owner.DisplayName,
        hosting = self.owner == player,
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
        and self.nearby(self.owner, self.podium.anchor, 32)
    then
        self.firstBarReported = true
        if self.performanceEligible and self.lifecycle.performed then
            self.lifecycle.performed(self.owner, self.pattern)
        end
    end
end

function ListeningSession:stop(notice)
    self:reportFirstLoop()
    local members = self.members
    self.members = {}
    self.owner = nil
    self.pattern = nil
    self.performanceEligible = false
    self.podium.prompt.ActionText = "Share your loop"
    self.podium.label.Text = "LISTENING COURT / IDLE"
    for player in members do
        self.send(player, notice)
    end
    self.stage:refresh()
end

function ListeningSession:leave(player)
    if self.owner == player then
        self:stop("The listening session has ended.")
    elseif self.members[player] then
        self.members[player] = nil
        self.send(player, "Left listening. Your own pattern is unchanged.")
    end
end

function ListeningSession:tick()
    if self.owner and not self.nearby(self.owner, self.podium.anchor, 32) then
        self:stop("The performer left the courtyard. Listening has ended.")
        return
    end
    for player in self.members do
        if not self.nearby(player, self.podium.anchor, 32) then
            self:leave(player)
        end
    end
    self.stage:tick()
    self:reportFirstLoop()
end

function ListeningSession:openBoard(p)
    self.stage:open(p)
end
function ListeningSession:stageState(p)
    return self.stage:state(p)
end
function ListeningSession:command(p, action)
    self.stage:command(p, action)
end
function ListeningSession:depart(p)
    self.stage:depart(p)
end

return ListeningSession
