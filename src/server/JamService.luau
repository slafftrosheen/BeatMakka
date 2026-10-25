local Shared = game.ReplicatedStorage.Shared
local Protocol = require(Shared.JamProtocol)
local Pattern = require(Shared.Pattern)
local Service = {}
Service.__index = Service

function Service.new(stations, profiles, send, departOther, nearby, options)
    return setmetatable({
        stations = stations,
        profiles = profiles,
        send = send,
        departOther = departOther,
        nearby = nearby,
        now = (options and options.now) or function()
            return workspace:GetServerTimeNow()
        end,
        generation = 0,
        revision = 0,
        members = {},
        panels = {},
    }, Service)
end

function Service:owns(player)
    local p = self.profiles[player]
    local s = p and self.stations[p.station]
    return p and p.ready and s and s.owner == player and self.nearby(player, s.anchor, 15)
end

function Service:state(player)
    return {
        generation = self.generation,
        revision = self.revision,
        open = self.panels[player] == true,
        active = self.members[player] ~= nil,
        role = self.members[player],
        conductor = self.conductor == player,
        session = if self.members[player] then self.session else nil,
    }
end

function Service:changed(extra, notice)
    self.revision += 1
    if self.session then
        self.session.revision = self.revision
    end
    for player in self.members do
        self.send(player, if player == extra then notice else nil)
    end
    if extra and not self.members[extra] then
        self.send(extra, notice)
    end
end

function Service:leave(player)
    local slot = self.members[player]
    local open = self.panels[player]
    self.panels[player] = nil
    if not slot then
        if open then
            self.send(player)
        end
        return
    end
    self.members[player] = nil
    self.session.tracks[tostring(slot)], self.session.pending[tostring(slot)] = nil, nil
    if self.conductor == player then
        self.conductor = next(self.members)
    end
    if not self.conductor then
        self.session = nil
    end
    -- Tempo is shared, so a conductor handoff preserves an accepted tempo change.
    self:changed(player, "Left the jam. Your own pattern is unchanged.")
end

function Service:command(player, action, packet)
    if action == "JamLeave" then
        self:leave(player)
        return
    end
    if action == "JamHide" then
        self.panels[player] = nil
        self.send(player)
        return
    end
    if not self:owns(player) then
        self:leave(player)
        self.send(player, "Claim your own nearby sampler to use the jam.")
        return
    end
    if action == "JamOpen" then
        self.panels[player] = true
        self.send(player)
        return
    end
    if action ~= "JamJoin" and action ~= "JamPublish" and action ~= "JamTempo" then
        return
    end
    self:tick()
    if not Protocol.request(packet, self.generation, self.revision, self.now()) then
        self.send(player, "The jam changed or this request arrived late. Review it and try again.")
        return
    end
    local profile, slot = self.profiles[player], self.members[player]
    if action == "JamTempo" then
        local session = self.session
        if not slot or self.conductor ~= player then
            self.send(player, "Only the conductor can change shared tempo.")
            return
        end
        if session.tempo or next(session.pending) then
            self.send(player, "Wait for queued changes before changing tempo.")
            return
        end
        if not Pattern.integer(packet.value, 60, 180) then
            self.send(player, "Tempo must be 60–180 BPM.")
            return
        end
        session.tempo = {
            bpm = packet.value,
            applyAt = Protocol.boundary(session.anchor, session.bpm, self.now()),
        }
        self:changed(player, "Shared tempo queued for the next available bar.")
        return
    end
    if action == "JamJoin" and slot then
        self.send(player, "You already own a jam track.")
        return
    end
    if action == "JamPublish" and not slot then
        self.send(player, "Join the jam first.")
        return
    end
    if self.session and (self.session.tempo or (slot and self.session.pending[tostring(slot)])) then
        self.send(player, "Wait for your queued change before publishing again.")
        return
    end
    local snapshot, err =
        Protocol.capture(profile.pattern, profile.unlocked, self.session and self.session.pack)
    if not snapshot then
        self.send(player, err)
        return
    end
    if action == "JamJoin" then
        if
            self.members
            and self.session
            and self.session.tracks["1"]
            and self.session.tracks["2"]
        then
            self.send(player, "Both jam tracks are occupied.")
            return
        end
        -- Leave listening/chapter before allocating the jam role; never release
        -- this player's owned sampler or replace their editable profile pattern.
        self.departOther(player)
        if not self.session then
            self.generation += 1
            self.session = {
                generation = self.generation,
                revision = self.revision,
                bpm = profile.pattern.bpm,
                anchor = self.now() + Protocol.Lead,
                pack = snapshot.pack,
                tracks = {},
                pending = {},
            }
            self.conductor = player
        end
        slot = if self.session.tracks["1"] then 2 else 1
        self.members[player] = slot
        local first = next(self.session.tracks) == nil
        self.session.tracks[tostring(slot)] = {
            ownerUserId = player.UserId,
            name = player.DisplayName,
            version = if first then 1 else 0,
            snapshot = if first then snapshot else nil,
            sinceAt = self.session.anchor,
        }
        if not first then
            self.session.pending[tostring(slot)] = {
                snapshot = snapshot,
                version = 1,
                applyAt = Protocol.boundary(self.session.anchor, self.session.bpm, self.now()),
            }
        end
        profile.playing, profile.recording = false, false
        profile.epoch += 1
        self.panels[player] = true
        self:changed(player, "Joined. Edit your sampler, then publish a copy at a bar boundary.")
    else
        local track = self.session.tracks[tostring(slot)]
        self.session.pending[tostring(slot)] = {
            snapshot = snapshot,
            version = track.version + 1,
            applyAt = Protocol.boundary(self.session.anchor, self.session.bpm, self.now()),
        }
        self:changed(player, "Your pattern copy is queued; the other track stays unchanged.")
    end
end

function Service:tick()
    -- Copy the keys: leave mutates membership during lifecycle cleanup.
    for player in table.clone(self.members) do
        if not self:owns(player) then
            self:leave(player)
        end
    end
    local s = self.session
    if not s then
        return
    end
    local now, changed = self.now(), false
    for slot, pending in s.pending do
        if now >= pending.applyAt then
            local t = s.tracks[tostring(slot)]
            t.snapshot, t.version, t.sinceAt = pending.snapshot, pending.version, pending.applyAt
            s.pending[tostring(slot)] = nil
            changed = true
        end
    end
    if s.tempo and now >= s.tempo.applyAt then
        s.anchor, s.bpm = s.tempo.applyAt, s.tempo.bpm
        s.tempo = nil
        changed = true
    end
    if changed then
        self:changed()
    end
end

return Service
