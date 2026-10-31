local Players = game:GetService("Players")
local Shared = game.ReplicatedStorage.Shared
local Catalog = require(Shared.CompanionCatalog)
local Progress = require(Shared.CompanionProgress)
local Journal = require(Shared.CompanionJournal)
local Service = {}
Service.__index = Service
function Service.new(profiles, send, changed, world)
    return setmetatable(
        { profiles = profiles, send = send, changed = changed, world = world, sessions = {} },
        Service
    )
end
function Service:session(player, profile)
    local session = self.sessions[player]
    if not session then
        session = { tokens = 5, at = os.clock(), level = 1, saved = profile.saved, discoveries = 0 }
        for _, id in { "I01", "I02", "I03" } do
            if profile.unlocked[id] then
                session.discoveries += 1
            end
        end
        self.sessions[player] = session
    end
    return session
end
function Service:react(player, kind)
    local profile = self.profiles[player]
    if not profile then
        return
    end
    local s = self:session(player, profile)
    s.serial = (s.serial or 0) + 1
    s.reaction, s.untilAt = kind, os.clock() + 4
end
function Service:summary(player, profile)
    local preference = Catalog.sanitize(profile.companion)
    local s = self:session(player, profile)
    local route = self.world.demo ~= nil and profile.companionRoute ~= "legacy"
    local function project()
        local key
        if route then
            local mask = 0
            for i, id in require(Shared.QuayProgress).Order do
                if profile.quay.completed[id] then
                    mask += 2 ^ (i - 1)
                end
            end
            key = tostring(mask)
                .. ":"
                .. tostring(profile.companionStop or profile.quay.parking)
                .. ":"
                .. preference.selected
                .. ":"
                .. s.level
        end
        if not key or s.projectionKey ~= key then
            s.projection = Progress.project(profile, route, preference.selected, s.level)
            s.projectionKey = key
        end
        return s.projection
    end
    local hint
    if preference.selected ~= "none" then
        hint = project()
        if s.context ~= hint.context then
            s.context, s.level = hint.context, 1
            s.projectionKey = nil
            hint = project()
        end
    end
    if s.saved ~= profile.saved and profile.saved ~= nil then
        self:react(player, "saved")
    end
    s.saved = profile.saved
    local count = 0
    for _, id in { "I01", "I02", "I03" } do
        if profile.unlocked[id] then
            count += 1
        end
    end
    if count > s.discoveries then
        self:react(player, "discovery")
    end
    s.discoveries = count
    -- React to authoritative progression transitions, never to client award requests.
    local completed = {}
    for id, done in profile.quay.completed do
        if done then
            completed[id] = true
        end
    end
    for id, done in profile.quay.side or {} do
        if done then
            completed["side:" .. id] = true
        end
    end
    if s.completed then
        for id in completed do
            if not s.completed[id] then
                self:react(player, "achievement")
                break
            end
        end
    end
    s.completed = completed
    local node = self.world.demo
        and (
            if hint and hint.location == "finale"
                then self.world.demo.finale
                else self.world.demo.stops[hint and hint.location]
        )
    local journal
    if preference.selected ~= "none" then
        local location = if route then profile.companionStop or profile.quay.parking else "legacy"
        local key = preference.selected
            .. ":"
            .. tostring(location)
            .. ":"
            .. tostring(profile.unlocked.I01)
            .. ":"
            .. tostring(profile.unlocked.I02)
            .. ":"
            .. tostring(profile.unlocked.I03)
        if s.journalKey ~= key or s.journalSaved ~= profile.saved then
            s.journal = Journal.project(profile, preference.selected, location)
            s.journalKey, s.journalSaved = key, profile.saved
        end
        journal = s.journal
    end
    return {
        selected = preference.selected,
        hints = preference.hints,
        hint = if preference.selected ~= "none" and preference.hints then hint else nil,
        target = node and node.anchor.Position,
        reaction = if (s.untilAt or 0) > os.clock() then s.reaction else nil,
        reactionSerial = s.serial or 0,
        saveMode = profile.saveMode,
        journal = journal,
    }
end
function Service:command(player, action, value, extra)
    local profile = self.profiles[player]
    if player.Parent ~= Players or not profile or not profile.ready or extra ~= nil then
        return false
    end
    if action ~= "CompanionSelect" and action ~= "CompanionHints" and action ~= "CompanionHint" then
        return false
    end
    if action == "CompanionSelect" and not Catalog.valid(value) then
        return false
    end
    if action == "CompanionHints" and type(value) ~= "boolean" then
        return false
    end
    if action == "CompanionHint" and value ~= nil then
        return false
    end
    local s, now = self:session(player, profile), os.clock()
    s.tokens = math.min(5, s.tokens + (now - s.at) * 1.5)
    s.at = now
    if s.tokens < 1 then
        return false
    end
    s.tokens -= 1
    local preference = Catalog.sanitize(profile.companion)
    local changed = false
    if action == "CompanionSelect" then
        changed = preference.selected ~= value
        preference.selected = value
        s.level = 1
    elseif action == "CompanionHints" then
        changed = preference.hints ~= value
        preference.hints = value
    elseif preference.selected ~= "none" and preference.hints then
        -- Refresh context before escalating; a new task always starts with a gentle hint.
        self:summary(player, profile)
        s.level = math.min(3, s.level + 1)
    end
    if changed then
        profile.companion = preference
        profile.editVersion += 1
        self.changed(player, profile)
    end
    self.send(player)
    return true
end
function Service:remove(player)
    self.sessions[player] = nil
end
return Service
