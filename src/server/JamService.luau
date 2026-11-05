-- Two independent musical owners, one bounded timeline. All invitations and
-- handovers are server-authoritative, ephemeral, and require explicit consent.
local Shared = game.ReplicatedStorage.Shared
local Protocol = require(Shared.JamProtocol)
local Sequence = require(Shared.MusicSequence)
local Project = require(Shared.MusicProject)
local Copy = require(Shared.JamCollaboration)
local CopySession = require(script.Parent.JamCopySession)
local Http = game:GetService("HttpService")
local Service = {}
Service.__index = Service
local INVITE_SECONDS, OFFER_SECONDS, INVITE_COOLDOWN = 24, 20, 4

function Service.new(stations, profiles, send, departOther, nearby, options)
    return setmetatable({
        stations = stations, profiles = profiles, send = send,
        departOther = departOther, nearby = nearby,
        now = (options and options.now) or function()
            return workspace:GetServerTimeNow()
        end,
        generation = 0, revision = 0, members = {}, panels = {},
        invitations = {}, preferences = {}, nextInviteAt = {},
    }, Service)
end

function Service:owns(player)
    local profile = self.profiles[player]
    local station = profile and self.stations[profile.station]
    return profile and profile.ready and station
        and station.owner == player and self.nearby(player, station.anchor, 15)
end

function Service:other(player)
    for member in self.members do
        if member ~= player then return member end
    end
    return nil
end

function Service:musicContext(player, role)
    local profile = self.profiles[player]
    local project = profile and profile.music.project
    if not project then return nil end
    return Protocol.context(project, profile.sequenceId or project.sequenceOrder[1], role,
        profile.unlocked, self.session and self.session.bpm)
end

function Service:state(player)
    local now = self.now()
    local invitation = self.invitations[player]
    if invitation and invitation.expiresAt <= now then
        invitation = nil
    end
    local candidates = {}
    if self.session and self.conductor == player and self:owns(player)
        and not self:other(player) then
        for other in self.profiles do
            if other ~= player and not self.members[other] and self:owns(other) then
                table.insert(candidates, {
                    userId = other.UserId, name = other.DisplayName,
                    station = self.profiles[other].station,
                    context = self:musicContext(other, Protocol.opposite(self.session.tracks[tostring(self.members[player])].role)),
                })
            end
        end
        table.sort(candidates, function(a, b)
            return a.name == b.name and a.userId < b.userId or a.name < b.name
        end)
    end
    return {
        schema = Protocol.Schema, generation = self.generation, revision = self.revision,
        open = self.panels[player] == true, active = self.members[player] ~= nil,
        hasSession = self.session ~= nil,
        role = self.members[player] and self.session and
            self.session.tracks[tostring(self.members[player])].role or nil,
        preferredRole = self.preferences[player] or "rhythm",
        sourceContext = self:musicContext(player, if self.members[player] and self.session
            then self.session.tracks[tostring(self.members[player])].role else self.preferences[player] or "rhythm"),
        swapContext = self:musicContext(player, if self.members[player] and self.session
            then Protocol.opposite(self.session.tracks[tostring(self.members[player])].role) else "hook"),
        conductor = self.conductor == player,
        session = if self.members[player] then self.session else nil,
        invitation = if invitation then {
            from = invitation.from.DisplayName, fromUserId = invitation.from.UserId,
            generation = invitation.generation, expiresAt = invitation.expiresAt,
            suggestedRole = invitation.role,
            sharedContext = self.session and self.session.tracks[tostring(self.members[invitation.from])]
                and self.session.tracks[tostring(self.members[invitation.from])].snapshot
                and self.session.tracks[tostring(self.members[invitation.from])].snapshot.context,
        } else nil,
        candidates = candidates,
        copyPending = CopySession.summary(self.profiles[player]),
    }
end

function Service:changed(extra, notice)
    self.revision += 1
    if self.session then self.session.revision = self.revision end
    for player in self.members do
        self.send(player, if player == extra then notice else nil)
    end
    if extra and not self.members[extra] then self.send(extra, notice) end
end

function Service:dropInvites(player)
    for target, invitation in self.invitations do
        if target == player or invitation.from == player then
            self.invitations[target] = nil
            if target ~= player then
                self.send(target, "That jam invitation is no longer available.")
            end
        end
    end
end

function Service:leave(player)
    local slot = self.members[player]
    local wasOpen = self.panels[player]
    self.panels[player], self.preferences[player] = nil, nil
    self:dropInvites(player)
    if not slot then
        if wasOpen then self.send(player) end
        return
    end
    self.members[player] = nil
    local session = self.session
    if session then
        session.leadOffer, session.tempoOffer, session.roleOffer, session.copyOffer =
            nil, nil, nil, nil
        session.contextOffer = nil
        if self.conductor == player then self.conductor = self:other(player) end
        if self.conductor then
            -- A departed player's voice ends at the next shared bar, not halfway
            -- through an accepted phrase. It no longer owns or controls that seat.
            session.pending[tostring(slot)] = {
                remove = true,
                applyAt = Protocol.boundary(session.anchor, session.bpm, self.now()),
            }
        else
            self.session = nil
        end
    end
    self:changed(player, "Left the duet. Your project and saved music are unchanged.")
end

local function source(profile)
    local project = profile.music and profile.music.project
    local sequenceId = project and (profile.sequenceId or project.sequenceOrder[1])
    return project, sequenceId
end

function Service:makeSnapshot(player, role)
    local profile = self.profiles[player]
    local project, sequenceId = source(profile)
    local bpm = if self.session then self.session.bpm
        else project and project.sequences[sequenceId] and project.sequences[sequenceId].bpm
    return Protocol.capture(project, sequenceId, profile.unlocked, bpm, role,
        { userId = player.UserId, name = player.Name })
end

function Service:tempoAt(session, bpm)
    session.tempo = {
        bpm = bpm,
        applyAt = Protocol.boundary(session.anchor, session.bpm, self.now()),
        phaseTicks = {},
    }
    for key, part in session.tracks do
        if part.snapshot and not part.departing then
            session.tempo.phaseTicks[key] = (
                (part.phaseTick or 0)
                + math.max(0, session.tempo.applyAt - part.sinceAt)
                    * session.bpm * 960 / 60
            ) % (part.snapshot.bars * 3840)
        end
    end
end

function Service:command(player, action, packet)
    if action == "JamLeave" then self:leave(player); return end
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
    -- A personal retained copy remains actionable after the other player's
    -- session continues or ends. Its private ID + full workspace context are
    -- authoritative; unrelated jam revisions cannot invalidate Keep/Discard.
    if action == "JamCopyKeep" or action == "JamCopyDiscard" then
        local now = self.now()
        if type(packet) ~= "table"
            or not Protocol.request(packet, packet.generation, packet.revision, now) then
            self.send(player, "This copy request arrived late. Review and confirm again.")
            return
        end
        if self.members[player] then
            self.send(player, "Leave the active duet first; the private joint copy stays available.")
            return
        end
        local ok, notice = CopySession.manage(self.profiles[player], action, packet.value)
        self.send(player, notice)
        return
    end
    self:tick()
    local now = self.now()
    if not Protocol.request(packet, self.generation, self.revision, now) then
        self.send(player, "The jam changed or this request arrived late. Review and retry.")
        return
    end
    local profile, slot, session = self.profiles[player], self.members[player], self.session
    local value = packet.value
    if table.find({ "JamJoin", "JamAccept", "JamPublish", "JamSwapOffer", "JamSwapAccept" }, action) then
        local role = if slot and session then session.tracks[tostring(slot)].role else self.preferences[player] or "rhythm"
        if action == "JamSwapOffer" or action == "JamSwapAccept" then role = Protocol.opposite(role) end
        local declared, contextProblem = self:musicContext(player, role)
        if not declared or type(value) ~= "table" or value.contextToken ~= declared.token then
            self.send(player, contextProblem or "Review and acknowledge the current tuning and pitch offsets before sharing this part.")
            return
        end
    end
    if action == "JamContextAccept" or action == "JamContextDecline" then
        local offer = session and session.contextOffer
        if not slot or not offer or offer.to ~= player.UserId or offer.expiresAt <= now then
            self.send(player, "That tuning-context proposal ended."); return
        end
        session.contextOffer = nil
        if action == "JamContextAccept" then
            local track = session.tracks[offer.slot]
            if not track or track.version ~= offer.version or next(session.pending) or session.tempo then
                self:changed(player, "The duet changed. Ask for a fresh context proposal."); return
            end
            session.pending[offer.slot] = { snapshot = offer.snapshot, role = track.role,
                version = track.version + 1, applyAt = Protocol.boundary(session.anchor, session.bpm, now) }
        end
        self:changed(player, if action == "JamContextAccept" then "Tuning context accepted. The exact part joins next bar; no retuning."
            else "Context proposal declined. Both accepted parts stay unchanged.")
        return
    end
    if action == "JamCopyOffer" then
        local partner = self:other(player)
        if not slot or not partner or session.copyOffer or next(session.pending)
            or session.tempo or session.tempoOffer or session.roleOffer or session.contextOffer
            or session.leadPending or profile.jamCopyTake or self.profiles[partner].jamCopyTake then
            self.send(player, "Both settled players need a free temporary-copy slot. Keep or discard an older copy first.")
            return
        end
        session.copyOffer = {
            from = player.UserId, to = partner.UserId,
            expiresAt = now + OFFER_SECONDS,
            versions = {
                ["1"] = session.tracks["1"].version,
                ["2"] = session.tracks["2"].version,
            },
            bpm = session.bpm,
        }
        self:changed(player,
            "Offered a credited joint phrase snapshot. Your partner must accept; neither project is changed.")
        return
    end
    if action == "JamCopyAccept" or action == "JamCopyDecline" then
        local offer = session and session.copyOffer
        if not slot or not offer or offer.to ~= player.UserId or offer.expiresAt <= now then
            self.send(player, "That joint-copy offer is no longer available.")
            return
        end
        session.copyOffer = nil
        if action == "JamCopyDecline" then
            self:changed(player, "Joint copy declined. Both musical projects remain unchanged.")
            return
        end
        if next(session.pending) or session.tempo or offer.bpm ~= session.bpm
            or session.tracks["1"].version ~= offer.versions["1"]
            or session.tracks["2"].version ~= offer.versions["2"] then
            self:changed(player, "The music changed after the offer. Request a fresh joint copy.")
            return
        end
        local take, problem = Copy.capture(session, now, "jam_" .. Http:GenerateGUID(false))
        if not take then
            self:changed(player, problem)
            return
        end
        local partner = self:other(player)
        if not partner or profile.jamCopyTake or self.profiles[partner].jamCopyTake then
            self:changed(player, "A participant left or already holds a temporary copy.")
            return
        end
        profile.jamCopyTake = Project.clone(take)
        self.profiles[partner].jamCopyTake = Project.clone(take)
        self:changed(player, "Both credits captured as a TEMPORARY phrase. Leave the jam, then Keep as Draft and Save.")
        self.send(partner,
            "Your mutually accepted phrase is temporary. Leave the jam and Keep as Draft; no save was made.")
        return
    end
    if action == "JamRole" then
        if slot then
            self.send(player, "The active part is pinned. Ask for a role exchange instead.")
        elseif not Protocol.roleValid(value) then
            self.send(player, "Choose Rhythm or Hook / Texture.")
        else
            self.preferences[player] = value
            self:changed(player, "Selected " .. Protocol.RoleLabels[value] .. " for your next join.")
        end
        return
    end
    if action == "JamJoin" then
        if slot or session then
            self.send(player, "Join an existing duet by accepting its invitation, not by taking a seat.")
            return
        end
        local role = self.preferences[player] or "rhythm"
        local snapshot, problem = self:makeSnapshot(player, role)
        if not snapshot then self.send(player, problem); return end
        self.departOther(player)
        self.generation += 1
        session = {
            schema = Protocol.Schema, generation = self.generation,
            revision = self.revision, bpm = snapshot.schedule.sections[1].bpm,
            anchor = now + Protocol.Lead, tracks = {}, pending = {},
        }
        self.session, self.conductor, self.members[player] = session, player, 1
        session.tracks["1"] = {
            ownerUserId = player.UserId, name = player.DisplayName,
            role = role, version = 1, snapshot = snapshot, sinceAt = session.anchor,
        }
        profile.playing, profile.recording = false, false
        profile.epoch += 1
        self.panels[player] = true
        self:changed(player, "Solo jam started. Invite a nearby musician for the other role.")
        return
    end
    if action == "JamInvite" then
        if not slot or player ~= self.conductor or self:other(player) then
            self.send(player, "Only a solo conductor can invite a second musician.")
            return
        end
        if now < (self.nextInviteAt[player] or 0) then
            self.send(player, "Invitation cooldown is active.")
            return
        end
        if type(value) ~= "table" or type(value.userId) ~= "number" or value.userId % 1 ~= 0 or math.abs(value.userId) > 1e15 then
            self.send(player, "Choose a nearby station owner.")
            return
        end
        local target
        for other in self.profiles do
            if other.UserId == value.userId then target = other; break end
        end
        if not target or target == player or self.members[target] or not self:owns(target) then
            self.send(player, "The invited musician is no longer available at their sampler.")
            return
        end
        local emptySlot = if session.tracks["1"] or session.pending["1"] then "2" else "1"
        if session.pending[emptySlot] or session.tracks[emptySlot] then
            self.send(player, "The other seat is occupied or releasing at the next bar.")
            return
        end
        local role = Protocol.opposite(session.tracks[tostring(slot)].role)
        local declared = self:musicContext(target, role)
        if not declared or value.contextToken ~= declared.token then
            self.send(player, "The invited part changed. Review its tuning context and invite again."); return
        end
        self.invitations[target] = {
            from = player, generation = self.generation,
            expiresAt = now + INVITE_SECONDS, role = role, seat = emptySlot,
            sourceToken = declared.token,
        }
        self.preferences[target] = role
        self.nextInviteAt[player] = now + INVITE_COOLDOWN
        self.panels[target] = true
        self:changed(player, "Invited " .. target.DisplayName .. " to play " .. Protocol.RoleLabels[role] .. ".")
        self.send(target, player.DisplayName .. " invited you to a two-person jam. Accept or decline.")
        return
    end
    if action == "JamDecline" then
        local invitation = self.invitations[player]
        if invitation then
            self.invitations[player] = nil
            self:changed(player, "Invitation declined. Your music is unchanged.")
            self.send(invitation.from, player.DisplayName .. " declined the jam invitation.")
        end
        return
    end
    if action == "JamAccept" then
        local invitation = self.invitations[player]
        if slot or not invitation or invitation.expiresAt <= now
            or invitation.generation ~= self.generation or not session
            or invitation.from ~= self.conductor or self:other(invitation.from)
            or session.tracks[invitation.seat] or session.pending[invitation.seat] then
            self.invitations[player] = nil
            self.send(player, "This invitation expired or the jam changed. Ask for another.")
            return
        end
        local host = session.tracks[tostring(self.members[invitation.from])]
        local role = self.preferences[player] or invitation.role
        if not Protocol.roleValid(role) or host.role == role then
            self.send(player, "That role is occupied. Choose the other contribution.")
            return
        end
        local snapshot, problem = self:makeSnapshot(player, role)
        if not snapshot then self.send(player, problem); return end
        if snapshot.context.token ~= invitation.sourceToken then
            self.send(player, "Your contribution changed after its context was invited. Ask for a fresh invitation."); return
        end
        self.departOther(player)
        self.members[player], self.invitations[player] = tonumber(invitation.seat), nil
        session.tracks[invitation.seat] = {
            ownerUserId = player.UserId, name = player.DisplayName,
            role = role, version = 0, snapshot = nil, sinceAt = session.anchor,
        }
        session.pending[invitation.seat] = {
            snapshot = snapshot, role = role, version = 1,
            applyAt = Protocol.boundary(session.anchor, session.bpm, now),
        }
        profile.playing, profile.recording = false, false
        profile.epoch += 1
        self.panels[player] = true
        -- Other outstanding invitations cannot claim an already-filled seat.
        self:dropInvites(invitation.from)
        self:changed(player, "Accepted. Your " .. Protocol.RoleLabels[role] .. " joins at the next bar.")
        return
    end
    if action == "JamTempo" then
        if not slot or player ~= self.conductor then
            self.send(player, "Only the current conductor can propose tempo.")
            return
        end
        if not Sequence.integer(value, 60, 180) or session.tempo
            or session.tempoOffer or next(session.pending) or session.roleOffer
            or session.leadPending or session.contextOffer then
            self.send(player, "Choose 60–180 BPM after the pending change settles.")
            return
        end
        if session.bpm == value then
            self.send(player, "The shared tempo is already at that value.")
            return
        end
        local guest = self:other(player)
        if guest then
            session.tempoOffer = { bpm = value, to = guest.UserId, expiresAt = now + OFFER_SECONDS }
            self:changed(player, "Tempo proposal sent. The other musician must accept.")
        else
            self:tempoAt(session, value)
            self:changed(player, "Solo tempo change queued for the next bar.")
        end
        return
    end
    if action == "JamTempoAccept" or action == "JamTempoDecline" then
        local offer = session and session.tempoOffer
        if not slot or not offer or offer.to ~= player.UserId or offer.expiresAt <= now then
            self.send(player, "That tempo proposal is no longer available.")
            return
        end
        session.tempoOffer = nil
        if action == "JamTempoAccept" then
            if session.tempo or next(session.pending) then
                self.send(player, "A musical transition intervened. Ask for tempo again.")
                return
            end
            self:tempoAt(session, offer.bpm)
        end
        self:changed(player, if action == "JamTempoAccept"
            then "Accepted. Shared tempo will change at the next bar, without editing sources."
            else "Tempo proposal declined. Current music is unchanged.")
        return
    end
    if action == "JamLeadOffer" then
        local other = self:other(player)
        if not slot or self.conductor ~= player or not other
            or session.leadOffer or session.leadPending then
            self.send(player, "Both active musicians are needed for an unqueued handover.")
            return
        end
        session.leadOffer = { to = other.UserId, expiresAt = now + OFFER_SECONDS }
        self:changed(player, "Offered the conductor's baton. Your partner can accept or decline.")
        return
    end
    if action == "JamLeadAccept" or action == "JamLeadDecline" then
        local offer = session and session.leadOffer
        if not slot or not offer or offer.to ~= player.UserId or offer.expiresAt <= now then
            self.send(player, "The lead handover offer expired.")
            return
        end
        session.leadOffer = nil
        if action == "JamLeadAccept" then
            session.leadPending = {
                to = player.UserId,
                at = Protocol.boundary(session.anchor, session.bpm, now),
            }
        end
        self:changed(player, if action == "JamLeadAccept"
            then "Accepted. The shared baton changes hands at the next bar."
            else "Lead handover declined; the conductor remains unchanged.")
        return
    end
    if action == "JamSwapOffer" then
        local other = self:other(player)
        if not slot or not other or session.roleOffer or next(session.pending)
            or session.tempo or session.tempoOffer or session.leadPending or session.contextOffer then
            self.send(player, "Both parts must be settled before exchanging roles.")
            return
        end
        local theirSlot = self.members[other]
        local mine, theirs = session.tracks[tostring(slot)], session.tracks[tostring(theirSlot)]
        local myCopy, myProblem = self:makeSnapshot(player, theirs.role)
        if not myCopy then self.send(player, myProblem); return end
        local theirCopy, theirProblem = self:makeSnapshot(other, mine.role)
        if not theirCopy then self.send(player, theirProblem); return end
        session.roleOffer = {
            from = player.UserId, to = other.UserId,
            expiresAt = now + OFFER_SECONDS,
            snapshots = { [tostring(slot)] = myCopy, [tostring(theirSlot)] = theirCopy },
            roles = { [tostring(slot)] = theirs.role, [tostring(theirSlot)] = mine.role },
        }
        self:changed(player, "Proposed exchanging musical roles. Your partner must accept.")
        return
    end
    if action == "JamSwapAccept" or action == "JamSwapDecline" then
        local offer = session and session.roleOffer
        if not slot or not offer or offer.to ~= player.UserId or offer.expiresAt <= now then
            self.send(player, "That role exchange is no longer available.")
            return
        end
        session.roleOffer = nil
        if action == "JamSwapAccept" then
            if offer.snapshots[tostring(slot)].context.token ~= value.contextToken then
                self:changed(player, "Your source changed after the role offer. Request a fresh exchange."); return
            end
            if next(session.pending) or session.tempo then
                self.send(player, "A musical transition intervened. Request a new role exchange.")
                return
            end
            local at = Protocol.boundary(session.anchor, session.bpm, now)
            for key, snapshot in offer.snapshots do
                local track = session.tracks[key]
                session.pending[key] = {
                    snapshot = snapshot, role = offer.roles[key],
                    version = track.version + 1, applyAt = at,
                }
            end
        end
        self:changed(player, if action == "JamSwapAccept"
            then "Both musical roles exchange at the same bar. Source projects remain yours."
            else "Role exchange declined; both parts remain unchanged.")
        return
    end
    if action == "JamPublish" then
        if not slot or session.pending[tostring(slot)] or session.tempo or session.roleOffer or session.contextOffer then
            self.send(player, "Join first and let your pending part/tempo change finish.")
            return
        end
        local track = session.tracks[tostring(slot)]
        local snapshot, problem = self:makeSnapshot(player, track.role)
        if not snapshot then self.send(player, problem); return end
        local partner = self:other(player)
        if partner and track.snapshot and snapshot.context.signature ~= track.snapshot.context.signature then
            session.contextOffer = { from = player.UserId, to = partner.UserId, slot = tostring(slot),
                snapshot = snapshot, version = track.version, expiresAt = now + OFFER_SECONDS }
            self:changed(player, "Your tuning/pitch context changed. Your partner must acknowledge it before this part is queued.")
            return
        end
        session.pending[tostring(slot)] = {
            snapshot = snapshot, role = track.role, version = track.version + 1,
            applyAt = Protocol.boundary(session.anchor, session.bpm, now),
        }
        self:changed(player, "Your " .. Protocol.RoleLabels[track.role]
            .. " Sequence copy is queued for the next shared bar.")
        return
    end
    self.send(player, "Unsupported jam action; neither project changed.")
end

function Service:tick()
    for player in table.clone(self.members) do
        if not self:owns(player) then self:leave(player) end
    end
    local now = self.now()
    for player, invitation in self.invitations do
        if invitation.expiresAt <= now or invitation.generation ~= self.generation
            or not self.members[invitation.from] or not self:owns(player) then
            self.invitations[player] = nil
            self.send(player, "The jam invitation expired or its owner left.")
        end
    end
    local session = self.session
    if not session then return end
    local changed = false
    for _, kind in { "tempoOffer", "leadOffer", "roleOffer", "copyOffer", "contextOffer" } do
        local offer = session[kind]
        if offer and offer.expiresAt <= now then
            session[kind] = nil
            changed = true
        end
    end
    for slot, pending in session.pending do
        if now >= pending.applyAt then
            local track = session.tracks[slot]
            if pending.remove then
                session.tracks[slot] = nil
            elseif track then
                track.snapshot, track.version, track.sinceAt =
                    pending.snapshot, pending.version, pending.applyAt
                track.phaseTick = 0
                track.role = pending.role or track.role
            end
            session.pending[slot] = nil
            changed = true
        end
    end
    if session.tempo and now >= session.tempo.applyAt then
        for key, part in session.tracks do
            part.phaseTick = session.tempo.phaseTicks[key] or 0
            part.sinceAt = session.tempo.applyAt
        end
        session.anchor, session.bpm = session.tempo.applyAt, session.tempo.bpm
        session.tempo = nil
        changed = true
    end
    if session.leadPending and now >= session.leadPending.at then
        for player in self.members do
            if player.UserId == session.leadPending.to then
                self.conductor = player
                break
            end
        end
        session.leadPending = nil
        changed = true
    end
    if changed then self:changed() end
end

return Service
