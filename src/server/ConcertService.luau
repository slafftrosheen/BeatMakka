local Workspace = game:GetService("Workspace")
local Shared = game.ReplicatedStorage.Shared
local Chapter = require(Shared.ChapterConcert)
local Music = require(Shared.QuayMusicEvidence)
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
        serial = 0,
    }, Service)
    podium.prompt.Triggered:Connect(function(player)
        self:open(player)
    end)
    return self
end
function Service:open(player)
    local profile = self.profiles[player]
    if not profile or not profile.ready or not self.nearby(player, self.podium.anchor, 11) then
        return
    end
    if not self.sessions[player] then
        self.release(player)
    end
    self.opened[player] = true
    self.send(player, "Choose your Finished Song. A quiet room is enough for this evening.")
end
function Service:state(player)
    return Chapter.summary(self.profiles[player], self.sessions[player], self.opened[player])
end
function Service:stop(player)
    -- Stop or leave cancels an incomplete traversal. There is no seek or partial certificate.
    self.sessions[player], self.opened[player] = nil, nil
    self.serial += 1
end
function Service:command(player, action, value)
    local profile = self.profiles[player]
    if not profile or not profile.ready then
        return
    end
    if action == "ChapterClose" then
        self:stop(player)
        self.send(
            player,
            "Performance stopped. Start from the beginning next time; earned history stays with you."
        )
        return
    end
    if not self.opened[player] or not self.nearby(player, self.podium.anchor, 32) then
        self:stop(player)
        self.send(player, "Return to the chapter podium to perform.")
        return
    end
    if action == "ChapterSelect" then
        local id = if type(value) == "table" then value.id else value
        local evidence, message = Music.finished(profile, id)
        if not evidence then
            self.send(player, message)
            return
        end
        if
            type(value) == "table"
            and value.revision ~= nil
            and value.revision ~= evidence.revision
        then
            self.send(player, "Choose the current saved immutable revision.")
            return
        end
        profile.selectedFinishedSongId = id
        profile.editVersion += 1
        self.changed(player, profile)
        self.send(player, "Selected the saved Finished Song revision.")
    elseif action == "ChapterStart" then
        local session, message = Chapter.start(profile, value, Workspace:GetServerTimeNow())
        if not session then
            self.send(player, message)
            return
        end
        self.release(player)
        self.serial += 1
        session.epoch = self.serial
        self.sessions[player], self.opened[player] = session, true
        self.send(player, "Ronan: From the beginning to the last sound. This evening is yours.")
    elseif action == "ChapterSave" then
        local now = os.clock()
        if profile.saving or now - (profile.lastSave or -math.huge) < 5 then
            self.send(player, "Please wait a moment between progress-save retries.")
            return
        end
        profile.lastSave = now
        self.changed(player, profile)
    elseif self.sessions[player] and (action == "ChapterPause" or action == "ChapterResume") then
        local session = self.sessions[player]
        local _, message = Chapter.act(session, action:sub(8), nil, Workspace:GetServerTimeNow())
        self.serial += 1
        session.epoch = self.serial
        self.send(player, message)
    end
end
function Service:checkpoint(player, session)
    local profile = self.profiles[player]
    local ended = Chapter.tick(session, Workspace:GetServerTimeNow())
    if ended and not session.awarded then
        session.awarded = true
        profile.chapter = Chapter.sanitize({
            completed = true,
            checkpoint = 6,
            performance = {
                songId = session.id,
                revision = session.revision,
                duration = session.endDuration,
                endedAt = session.endedAt,
                localOnly = session.localOnly,
            },
        })
        profile.editVersion += 1
        self.changed(player, profile)
        self.send(
            player,
            "Your finished song reached its end. The Lantern Room has a new evening to remember."
        )
    elseif not session.lastReport or Workspace:GetServerTimeNow() - session.lastReport >= 1 then
        session.lastReport = Workspace:GetServerTimeNow()
        self.send(player)
    end
end
function Service:tick()
    for player, session in self.sessions do
        local profile = self.profiles[player]
        if not profile or not self.nearby(player, self.podium.anchor, 32) then
            self:stop(player)
            if profile then
                self.send(
                    player,
                    "You left the room. Start a new performance from the beginning when ready."
                )
            end
        else
            self:checkpoint(player, session)
        end
    end
end
return Service
