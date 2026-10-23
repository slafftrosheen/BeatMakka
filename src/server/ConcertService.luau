local Workspace = game:GetService("Workspace")
local Chapter = require(game.ReplicatedStorage.Shared.ChapterConcert)
local Service = {}
Service.__index = Service

function Service.new(podium, profiles, send, release, nearby, changed)
    local self = setmetatable({
        podium = podium,
        profiles = profiles,
        send = send,
        release = release,
        nearby = nearby,
        changed = changed,
        sessions = {},
        opened = {},
    }, Service)
    podium.prompt.Triggered:Connect(function(player)
        local profile = profiles[player]
        if profile and profile.ready and nearby(player, podium.anchor, 11) then
            if not self.sessions[player] then
                self.release(player)
            end
            self.opened[player] = true
            send(
                player,
                "Your chapter concert is solo-friendly. Your working music stays unchanged."
            )
        end
    end)
    return self
end

function Service:state(player)
    return Chapter.summary(self.profiles[player], self.sessions[player], self.opened[player])
end

function Service:stop(player)
    local session = self.sessions[player]
    if session and self.profiles[player] and self.nearby(player, self.podium.anchor, 32) then
        self:checkpoint(player, session)
    end
    self.sessions[player] = nil
    self.opened[player] = nil
end

function Service:command(player, action, value)
    local profile = self.profiles[player]
    if action == "ChapterClose" then
        self:stop(player)
        self.send(
            player,
            "Set stopped. Earned section progress stays with you; save retries keep it temporary until successful."
        )
        return
    end
    if not self.opened[player] or not self.nearby(player, self.podium.anchor, 32) then
        self:stop(player)
        self.send(player, "Return to the chapter podium to start or continue a set.")
        return
    end
    if action == "ChapterStart" then
        local session, message = Chapter.start(profile, value, Workspace:GetServerTimeNow())
        if not session then
            self.send(player, message)
            return
        end
        self.release(player)
        self.sessions[player] = session
        self.opened[player] = true
        self.send(player, Chapter.Hints[1])
    elseif action == "ChapterSave" then
        local now = os.clock()
        if profile.saving or now - (profile.lastSave or -math.huge) < 5 then
            self.send(player, "Please wait a moment between progress-save retries.")
            return
        end
        profile.lastSave = now
        self.changed(player, profile)
    elseif self.sessions[player] and type(action) == "string" then
        local _, message =
            Chapter.act(self.sessions[player], action:sub(8), value, Workspace:GetServerTimeNow())
        self.send(player, message)
    end
end

function Service:checkpoint(player, session)
    local profile = self.profiles[player]
    local earned = Chapter.tick(session, Workspace:GetServerTimeNow())
    if earned > profile.chapter.checkpoint then
        profile.chapter = Chapter.sanitize({ checkpoint = earned, completed = earned == 6 })
        profile.editVersion += 1
        self.changed(player, profile)
        self.send(
            player,
            if earned == 6
                then "This neighborhood section is complete. More chapters are still ahead."
                else "The neighbors heard your change. Section progress updated."
        )
    elseif session.lastReported ~= session.earned then
        self.send(player)
    end
    session.lastReported = session.earned
end

function Service:tick()
    for player, session in self.sessions do
        local profile = self.profiles[player]
        if not profile or not self.nearby(player, self.podium.anchor, 32) then
            self:stop(player)
            if profile then
                self.send(
                    player,
                    "Set interrupted. Start a new set when ready; earned progress is retained."
                )
            end
        else
            self:checkpoint(player, session)
        end
    end
end

return Service
