-- Private same-server record invitations. Never broadcasts music or writes a guest's source.
local Players = game:GetService("Players")
local Http = game:GetService("HttpService")
local Text = game:GetService("TextService")
local Run = game:GetService("RunService")
local Shared = game.ReplicatedStorage.Shared
local Record = require(Shared.RecordRelease)
local Project = require(Shared.MusicProject)
local Catalog = require(Shared.SampleCatalog)
local Activities = require(Shared.QuayActivities)
local Profiles = require(script.Parent.ProfileStore)
local State = require(script.Parent.WorkspaceState)
local Service = {}
Service.__index = Service
local function now() return workspace:GetServerTimeNow() end
local function person(player) return { userId = player.UserId, name = player.Name } end
local function context(p)
    return { projectId = p.music.project.id, revision = p.music.project.revision,
        generation = p.workspaceGeneration or 0, editVersion = p.editVersion }
end
local function sameContext(p, request)
    if type(request) ~= "table" then return false end
    for key, value in context(p) do if request[key] ~= value then return false end end
    return true
end
local function filterTitle(player, title)
    if type(title) ~= "string" or #title < 1 or #title > 80 then return nil end
    -- Simulated negative Studio IDs cannot use production filtering. Never share
    -- their raw text with another client; the fixed label permits local flow review.
    if Run:IsStudio() and player.UserId <= 0 then return "Studio record" end
    local ok, result = pcall(function()
        return Text:FilterStringAsync(title, player.UserId):GetNonChatStringForBroadcastAsync()
    end)
    return if ok and type(result) == "string" and #result > 0 and #result <= 80 then result else nil
end
function Service.new(profiles, send, persist, owns, busy, workbench)
    return setmetatable({ profiles = profiles, send = send, persist = persist,
        owns = owns, busy = busy, workbench = workbench, invites = {}, sessions = {}, serial = 0 }, Service)
end
function Service:entry(owner, id)
    local p = self.profiles[owner]
    local entry = p and p.ready and not p.loadFailed and p.music.releases[id]
    return entry and entry.record.creator.userId == owner.UserId and entry
end
function Service:ready(player)
    local p = self.profiles[player]
    return function(id) return Catalog.isPlaybackReady(id, p and p.unlocked) end
end
function Service:sessionRecord(session)
    local entry = self:entry(session.owner, session.releaseId)
    return session.temporary or (entry and entry.record), entry
end
function Service:summary(player)
    local p = self.profiles[player]
    local result = { releases = {}, players = {}, context = context(p), lastReleaseId = p.lastRecordRelease }
    for _, id in p.music.releaseOrder do table.insert(result.releases, Record.summary(p.music.releases[id])) end
    if p.station then
        for other, profile in self.profiles do
            if other ~= player and profile.ready then table.insert(result.players, person(other)) end
        end
        table.sort(result.players, function(a, b) return a.userId < b.userId end)
    end
    local invite = self.invites[player]
    if invite and invite.expiresAt > now() then
        local entry = self:entry(invite.owner, invite.releaseId)
        if entry then
            result.invite = Record.summary(entry)
            result.invite.title, result.invite.token = invite.title, invite.token
            result.invite.owner, result.invite.expiresAt = person(invite.owner), invite.expiresAt
            result.invite.storage = self.profiles[invite.owner].saveMode
        end
    end
    local session = self.sessions[player]
    if session then
        local record, entry = self:sessionRecord(session)
        if record then
            result.session = Record.summary(entry or { record = record, allowRemix = false, permissionRevision = 1 })
            result.session.title = session.title
            result.session.token, result.session.playback = session.token, session.playback
            result.session.own = session.owner == player
            result.session.temporary = session.temporary ~= nil
            result.session.remixed = session.remixed == true
            result.session.storage = self.profiles[session.owner] and self.profiles[session.owner].saveMode or "unavailable"
        end
    end
    return result
end
function Service:leave(player)
    self.sessions[player] = nil
end
function Service:remove(player)
    self.sessions[player], self.invites[player] = nil, nil
    for recipient, invite in self.invites do
        if invite.owner == player then self.invites[recipient] = nil; self.send(recipient, "The record invitation ended when its author left.") end
    end
    for recipient, session in self.sessions do
        if session.owner == player then self.sessions[recipient] = nil; self.send(recipient, "Record listening ended. Your project and sound setting are unchanged.") end
    end
end
function Service:notify(owner)
    for recipient, invite in self.invites do if invite.owner == owner then self.send(recipient) end end
    for recipient, session in self.sessions do if session.owner == owner then self.send(recipient) end end
end
function Service:play(player, session, full)
    if self.busy(player) then return false, "Stop your current music activity before listening to this record." end
    local record = self:sessionRecord(session)
    if not record then return false, "This release is no longer available in this server." end
    local schedule, problem = Record.resolve(record, Catalog.isPlaybackReady, not full)
    if not schedule then return false, problem end
    schedule.title = session.title
    self.serial += 1
    session.playback = { schedule = schedule, startedAt = now() + 0.25, epoch = self.serial,
        playing = true, loop = false, offset = 0, audition = not full }
    return true, if full then "Playing this exact record in full." else "Short audition / up to 15 seconds. Stop or mute at any time."
end
function Service:write(player, p, music, accepted, notice)
    local version = p.editVersion
    return self.persist(player, p, notice, music, function(ok)
        if ok then
            local unchanged = p.editVersion == version
            accepted()
            p.editVersion += 1
            if unchanged then p.savedEditVersion = p.editVersion end
            self:notify(player)
        end
    end)
end
function Service:command(player, action, request)
    local p = self.profiles[player]
    request = if type(request) == "table" then request else {}
    if action == "RecordDecline" then
        local invite = self.invites[player]
        if not invite or request.token ~= invite.token then return false, "That invitation already ended." end
        self.invites[player] = nil
        return true, "Invitation declined. Your work and audio are unchanged."
    elseif action == "RecordLeave" then
        local session = self.sessions[player]
        if session and request.token == session.token then self:leave(player) end
        return true, "Record closed. Your work and sound setting are unchanged."
    elseif action == "RecordAccept" then
        local invite = self.invites[player]
        if not invite or request.token ~= invite.token or invite.expiresAt <= now() then return false, "That invitation expired." end
        local entry = self:entry(invite.owner, invite.releaseId)
        if not entry or self.sessions[player] then return false, "Close your current record before accepting another." end
        local session = { token = invite.token, owner = invite.owner, releaseId = invite.releaseId, title = invite.title }
        local ok, problem = self:play(player, session, false)
        if not ok then return false, problem end
        self.sessions[player], self.invites[player] = session, nil
        return true, problem
    elseif action == "RecordStop" or action == "RecordPlay" or action == "RecordRemix" or action == "RecordWorkbench" then
        local session = self.sessions[player]
        if not session or request.token ~= session.token then return false, "Review the current record first." end
        if action == "RecordStop" then session.playback = nil; return true, "Record stopped." end
        if action == "RecordPlay" then return self:play(player, session, request.full == true) end
        if action == "RecordWorkbench" then
            local ok, problem = self.workbench(player)
            if ok then session.playback = nil end
            return ok, problem
        end
        local record, entry = self:sessionRecord(session)
        if session.owner == player or session.remixed or not entry or not entry.allowRemix then
            return false, "Remix is not permitted for this release, or this session already created its copy."
        end
        if not self.owns(player) or p.saving or not sameContext(p, request.context) then
            return false, "Open your own workbench and review the current workspace before creating a remix."
        end
        local project, problem, selected = Record.remix(record, person(player), "remix_" .. Http:GenerateGUID(false), self:ready(player), session.title)
        if not project then return false, problem end
        local music = Project.clone(p.music)
        local preserved, preserveProblem = State.preserve(music, p.music.project)
        if not preserved then return false, preserveProblem end
        music.project = project
        local captured, budgetProblem = Profiles.capture(p, music, selected)
        if not captured then return false, budgetProblem end
        -- No yields since permission/context checks. Source and old workspace are intact.
        State.activate(p, music, selected)
        session.remixed, session.playback = true, nil
        return true, "Separate credited remix opened / NOT SAVED. Your previous workspace is retained in Imports. Save explicitly; it remains a "
            .. (if record.type == "Pattern/Loop" then "Pattern/Loop." else "Draft Song, until you deliberately Finish it.")
    end
    if not self.owns(player) then return false, "Open your own Beat Shelf at a workbench first." end
    if action == "RecordCover" then
        if p.saving or not sameContext(p, request.context) or type(request.cover) ~= "table"
            or not Activities.validSleeve(request.cover.motif, request.cover.palette) then
            return false, "Review this item's current revision and authored sleeve before keeping it."
        end
        local source, object = Record.source(p.music, request.ref)
        if not source then return false, object end
        if request.ref.kind == "finished" then return false, "A Finished Song's sleeve is immutable. Choose a new sleeve for a release copy." end
        local candidate, problem = Project.apply(source, if request.ref.kind == "sequence" then "SequenceCover" else "SongCover",
            { sequenceId = object.id, draftId = object.id, cover = Record.cover(request.cover) })
        if not candidate then return false, problem end
        local music = Project.clone(p.music)
        music.project = candidate
        local captured, budgetProblem = Profiles.capture(p, music)
        if not captured then return false, budgetProblem end
        local history = table.clone(p.musicUndo or {})
        table.insert(history, p.music.project)
        if #history > Project.Limits.History then table.remove(history, 1) end
        p.music.project, p.musicUndo, p.musicRedo = candidate, history, {}
        p.recordHistoryEpoch, p.noteDeltas = nil, {}
        p.editVersion += 1
        return true, "Personal sleeve applied / UNSAVED. Continue and Save explicitly. Undo restores the previous sleeve."
    elseif action == "RecordPreview" then
        if self.sessions[player] then return false, "Close your current record first." end
        local source, object = Record.source(p.music, request.ref)
        if not source then return false, object end
        local record, problem = Record.capture(p.music, request.ref, {
            id = "preview_" .. Http:GenerateGUID(false), requestId = Http:GenerateGUID(false),
            title = object.title or object.name, creator = person(player), createdAt = os.time() }, self:ready(player))
        if not record then return false, problem end
        local session = { temporary = record, owner = player, token = Http:GenerateGUID(false), title = record.title }
        local ok, message = self:play(player, session, false)
        if not ok then return false, message end
        self.sessions[player] = session
        return true, message
    elseif action == "RecordRelease" then
        if p.saving or p.recordFiltering then return false, "Wait for the current save or title check." end
        if type(request.requestId) ~= "string" or not request.requestId:match("^[%w_%-]+$") or #request.requestId > 80 then
            return false, "Release needs a stable request identity."
        end
        if p.music.releaseRequests[request.requestId] then return true, "That release copy was already saved." end
        if #p.music.releaseOrder >= Record.Limit then return false, "The eight-release budget is full; source music is retained." end
        if type(request.allowRemix) ~= "boolean" or not sameContext(p, request.context) then return false, "Review this exact shelf revision and permission first." end
        if request.cover ~= nil and (type(request.cover) ~= "table"
            or not Activities.validSleeve(request.cover.motif, request.cover.palette)) then return false, "Choose an authored sleeve." end
        local source, object = Record.source(p.music, request.ref)
        if not source then return false, object end
        local origin, expected = p.music, context(p)
        p.recordFiltering = true
        local title = filterTitle(player, object.title or object.name)
        p.recordFiltering = nil
        if not title then return false, "Shared title could not be filtered. No release was created." end
        if self.profiles[player] ~= p or p.music ~= origin or p.saving or not self.owns(player) or not sameContext(p, expected) then
            return false, "Workspace changed during title filtering. Review and release again."
        end
        local record, problem = Record.capture(p.music, request.ref, {
            id = "release_" .. Http:GenerateGUID(false), requestId = request.requestId,
            title = title, creator = person(player), createdAt = os.time(), cover = request.cover }, self:ready(player))
        if not record then return false, problem end
        local entry = { id = record.id, record = record, allowRemix = request.allowRemix, permissionRevision = 1 }
        local music = Project.clone(p.music)
        music.releases[entry.id] = entry
        table.insert(music.releaseOrder, entry.id)
        music.releaseRequests[request.requestId] = entry.id
        local captured, message = Profiles.capture(p, music)
        if not captured then return false, message end
        local started = self:write(player, p, music, function()
            p.music.releases[entry.id] = entry
            table.insert(p.music.releaseOrder, entry.id)
            p.music.releaseRequests[request.requestId] = entry.id
            p.lastRecordRelease = entry.id
        end, if p.saveMode == "session" then "Release copy saved for this Studio session only. Open RELEASES to invite."
            else "Release copy saved. Open RELEASES to invite a listener.")
        return started, if started then nil else "A save is already in progress."
    elseif action == "RecordPermission" then
        local entry = self:entry(player, request.id)
        if not entry or p.saving or entry.permissionRevision ~= request.permissionRevision
            or type(request.allowRemix) ~= "boolean" then return false, "Review the current release permission before changing it." end
        if entry.allowRemix == request.allowRemix then return true, "Permission is already set." end
        if entry.permissionRevision >= 1e12 then return false, "Permission revision limit reached." end
        local music = Project.clone(p.music)
        local changed = music.releases[entry.id]
        changed.allowRemix, changed.permissionRevision = request.allowRemix, entry.permissionRevision + 1
        local started = self:write(player, p, music, function() p.music.releases[entry.id] = changed end,
            "Future remix permission saved. Copies already created keep their music and credits."
                .. (if p.saveMode == "session" then " Studio session only." else ""))
        return started, if started then nil else "A save is already in progress."
    elseif action == "RecordInvite" then
        local entry = self:entry(player, request.id)
        local target = type(request.userId) == "number" and request.userId % 1 == 0
            and math.abs(request.userId) <= 1e12 and Players:GetPlayerByUserId(request.userId)
        if not entry or entry.permissionRevision ~= request.permissionRevision or not target or target == player
            or not self.profiles[target] or not self.profiles[target].ready or self.sessions[target] then return false, "Choose a current same-server player who has no record open." end
        if now() - (p.lastRecordInvite or -math.huge) < 3 or self.invites[target] then return false, "Wait for the pending invitation to end before sending another." end
        if p.recordFiltering then return false, "Wait for the current title check." end
        p.lastRecordInvite, p.recordFiltering = now(), true
        local title = filterTitle(player, entry.record.title)
        p.recordFiltering = nil
        if not title then return false, "The saved title could not be filtered. No invitation was sent." end
        if self:entry(player, request.id) ~= entry or not self.owns(player)
            or self.profiles[target] == nil or self.invites[target] then return false, "The release or recipient changed; invite again." end
        self.invites[target] = { owner = player, releaseId = entry.id, title = title,
            token = Http:GenerateGUID(false), expiresAt = now() + 45 }
        self.send(target, "Record invitation / accept to audition or decline without changing your work.")
        return true, "Invitation sent for this exact saved release. No audio starts until accepted."
    elseif action == "RecordAudition" then
        local entry = self:entry(player, request.id)
        if not entry or self.sessions[player] then return false, "Choose a release and close any current record first." end
        local session = { owner = player, releaseId = entry.id, title = entry.record.title, token = Http:GenerateGUID(false) }
        local ok, problem = self:play(player, session, false)
        if not ok then return false, problem end
        self.sessions[player] = session
        return true, problem
    end
    return false, "Unsupported record command."
end
function Service:tick()
    for player, invite in self.invites do
        if now() >= invite.expiresAt or not self:entry(invite.owner, invite.releaseId) then
            self.invites[player] = nil; self.send(player, "Record invitation expired. Your work is unchanged.")
        end
    end
    for player, session in self.sessions do
        if session.playback and now() >= session.playback.startedAt + session.playback.schedule.completeAt then
            session.playback = nil; self.send(player, "Record playback ended. Replay, make a permitted copy, or close.")
        end
    end
end
return Service
