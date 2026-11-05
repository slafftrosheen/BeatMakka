-- Untimed same-crate practice over the ordinary musical workspace/transport.
-- Recognition uses the existing identity award, never votes or a new ledger.
local Http = game:GetService("HttpService")
local Shared = game.ReplicatedStorage.Shared
local Crate = require(Shared.CrateChallenge)
local Project = require(Shared.MusicProject)
local Transport = require(Shared.MusicTransport)
local Catalog = require(Shared.SampleCatalog)
local Profiles = require(script.Parent.ProfileStore)
local State = require(script.Parent.WorkspaceState)
local Service = {}
Service.__index = Service
local AWARD = "activity:same_crate"

local function now()
    return workspace:GetServerTimeNow()
end

local function context(profile)
    return {
        projectId = profile.music.project.id, revision = profile.music.project.revision,
        generation = profile.workspaceGeneration or 0, editVersion = profile.editVersion,
    }
end

local function sameContext(profile, supplied)
    if type(supplied) ~= "table" then return false end
    local expected = context(profile)
    for key, value in expected do if supplied[key] ~= value then return false end end
    for key in supplied do if expected[key] == nil then return false end end
    return true
end

local function exactWorkspace(profile, proof)
    return profile ~= nil and profile.ready == true and proof ~= nil
        and profile.music.project == proof.project
        and sameContext(profile, proof.context)
end

function Service.new(profiles, send, persist, owns, core, present)
    return setmetatable({ profiles = profiles, send = send, persist = persist,
        owns = owns, core = core, present = present,
        sessions = {}, completed = {}, opened = {} }, Service)
end

function Service:previewCurrent(player, session)
    local profile = self.profiles[player]
    if not exactWorkspace(profile, session) or not self.owns(player) then return false end
    local transport = profile.transport
    return transport == session.transport and transport.schedule == session.schedule
        and profile.playing == true and transport.playing == true
        and profile.recording ~= true and transport.recording ~= true
        and transport.loop == false and profile.nextSequence == nil
        and transport.epoch == session.epoch and profile.epoch == session.epoch
        and transport.startedAt == session.startedAt and profile.startedAt == session.startedAt
        and transport.offset == 0 and transport.ref.kind == "song"
        and transport.ref.id == session.draftId
        and transport.schedule.source.id == session.draftId
        and transport.schedule.source.revision == session.draftRevision
        and transport.schedule.source.projectId == session.project.id
        and transport.schedule.source.projectRevision == session.project.revision
        and transport.schedule.completeAt == session.completeAt
end

function Service:stopTracked(player, session)
    local profile = self.profiles[player]
    if profile and session and profile.transport == session.transport then
        self.core.command(player, profile, "Stop", nil, nil, self.persist, self.send)
    end
end

function Service:summary(player)
    local profile = self.profiles[player]
    if not profile or not profile.ready or not profile.music then return nil end
    local review = Crate.review(profile.music.project, profile.unlocked)
    local session = self.sessions[player]
    return {
        schema = 1, promptId = Crate.Id, version = Crate.Version,
        title = Crate.Title, description = Crate.Description,
        bpm = Crate.Bpm, sectionBars = Crate.SectionBars, totalBars = Crate.TotalBars,
        palette = review.palette, review = review, context = context(profile),
        open = self.opened[player] == true,
        previewing = session ~= nil and self:previewCurrent(player, session),
        previewCompleteExact = review.passed and exactWorkspace(profile, self.completed[player]),
        recognized = type(profile.identity) == "table" and type(profile.identity.awards) == "table"
            and profile.identity.awards[AWARD] == true,
        recognitionSaved = profile.saved ~= nil and profile.saved.identity ~= nil
            and profile.saved.identity.awards[AWARD] == true,
        saveMode = profile.saveMode, saving = profile.saving == true,
    }
end

function Service:command(player, action, request)
    local profile = self.profiles[player]
    if not profile or not profile.ready or not profile.music then
        return false, "Wait for your musical workspace to load."
    end
    request = if type(request) == "table" then request else {}
    if action == "ChallengeClose" then
        self.opened[player] = nil
        return true, "Challenge guide closed. Your work and playback are unchanged."
    elseif action == "ChallengeStop" then
        local session = self.sessions[player]
        self.sessions[player] = nil
        if session then
            self.completed[player] = nil
            self:stopTracked(player, session)
        end
        return true, "Challenge preview stopped. You can edit and try again without a timer."
    end
    if action ~= "ChallengeStart" and action ~= "ChallengeReview"
        and action ~= "ChallengePreview" and action ~= "ChallengePresent" then
        return false, "Unsupported challenge action."
    end
    if not self.owns(player) then
        return false, "Open your own instrument to work on this crate."
    end
    if not sameContext(profile, request.context) then
        return false, "Your workspace changed. Review this exact revision before continuing the challenge."
    end
    self.opened[player] = true
    if action == "ChallengeStart" then
        if profile.saving then return false, "Wait for the current save before starting another preserved attempt." end
        local candidate, problem, selection = Crate.create("crate_" .. Http:GenerateGUID(false), request.mode, profile.unlocked)
        if not candidate then return false, problem end
        local proposed = Project.clone(profile.music)
        local current = profile.music.project
        -- Save acknowledgements do not make factory music personal work. A
        -- renamed/edited empty workspace still receives an exact archive copy.
        if not State.same(current, Project.new()) then
            local preserved, preserveProblem = State.preserve(proposed, current)
            if not preserved then return false, preserveProblem end
        end
        proposed.project = candidate
        local captured, captureProblem = Profiles.capture(profile, proposed, selection)
        if not captured then return false, captureProblem end
        -- No yields: readiness, original preservation and full profile budgets
        -- have all passed before the single workspace activation point.
        State.activate(profile, proposed, selection)
        profile.bank = 1
        self.sessions[player], self.completed[player] = nil, nil
        self.core.sync(profile)
        return true, "Quiet dock and Arrival opened as ordinary sections and an eight-bar Draft Song / NOT SAVED. Edit freely, preview its ending, then Save explicitly. Previous work is in Imports."
    end

    local review = Crate.review(profile.music.project, profile.unlocked)
    if action == "ChallengeReview" then return true, review.hint end
    if not review.ref then return false, review.hint end
    if action == "ChallengePresent" then
        if not review.passed then return false, review.hint end
        if type(self.present) ~= "function" then return false, "The short presentation is not available here. Solo practice still works." end
        local ok, message = self.present(player, Project.clone(review.ref))
        if ok then
            local session = self.sessions[player]
            self.sessions[player] = nil
            self:stopTracked(player, session)
        end
        return ok, message
    end

    local previous = self.sessions[player]
    if previous and self:previewCurrent(player, previous) then
        return false, "The current preview is already running. Let it reach its ending, or Stop before another attempt."
    end
    -- An unfinished draft can be heard as practice, but cannot earn recognition.
    -- Missing sounding sources/version pins refuse playback before selection.
    local resolved, problem = Transport.resolve(profile.music.project, review.ref, nil, {
        requireReady = true,
        ready = function(id) return Catalog.isPlaybackReady(id, profile.unlocked) end,
    })
    if not resolved then return false, problem end
    local selected, selectProblem = self.core.command(player, profile, "SongSelect", review.draftId, nil, self.persist, self.send)
    if not selected then return false, selectProblem end
    local played, playProblem = self.core.command(player, profile, "SongPlay", nil, nil, self.persist, self.send)
    if not played then return false, playProblem end
    local transport = profile.transport
    if not transport or transport.loop or transport.offset ~= 0
        or transport.ref.kind ~= "song" or transport.ref.id ~= review.draftId then
        return false, "A full Draft Song preview could not be started. Your music remains editable."
    end
    self.completed[player] = nil
    self.sessions[player] = {
        project = profile.music.project, context = context(profile),
        transport = transport, schedule = transport.schedule,
        epoch = transport.epoch, startedAt = transport.startedAt,
        draftId = review.draftId, draftRevision = review.ref.revision,
        completeAt = transport.schedule.completeAt,
        eligible = review.passed, lastPosition = 0,
    }
    return true, if review.passed
        then "Previewing the complete eight-bar Draft Song from its beginning. Let its final tail end. Stop or edit at any time; a partial preview earns no recognition."
        else "Playing this draft as untimed practice. " .. review.hint
end

-- MusicService calls this before Core.tick, while a naturally ending nonloop
-- transport still reports playing. A delayed timer alone cannot complete it:
-- the exact unchanged project and continuously owned transport must survive.
function Service:tick()
    local at = now()
    for player, proof in self.completed do
        if not exactWorkspace(self.profiles[player], proof) then self.completed[player] = nil end
    end
    for player, session in self.sessions do
        local profile = self.profiles[player]
        if not self:previewCurrent(player, session) then
            self.sessions[player], self.completed[player] = nil, nil
            self:stopTracked(player, session)
            if profile and profile.ready then
                self.send(player, "This preview changed or stopped before its complete ending. Start a fresh preview of the current draft when ready.")
            end
            continue
        end
        local position = math.max(0, at - session.startedAt)
        if position < session.lastPosition then
            self.sessions[player], self.completed[player] = nil, nil
            self:stopTracked(player, session)
            self.send(player, "The preview position changed. Start again from the beginning when ready.")
            continue
        end
        session.lastPosition = position
        if position >= session.completeAt then
            self.sessions[player] = nil
            local review = Crate.review(profile.music.project, profile.unlocked)
            if not session.eligible or not review.passed then
                self.send(player, "Practice preview reached its ending. " .. review.hint)
                continue
            end
            local recognized = profile.identity.awards[AWARD] == true
            if not recognized then
                profile.identity.awards[AWARD] = true
                profile.editVersion += 1
            end
            self.completed[player] = { project = profile.music.project, context = context(profile) }
            self.send(player, if recognized
                then "This exact Draft Song reached its ending and meets the prompt. Its one-time participation recognition was already earned; there is no score or winner."
                else "Your quiet dock reached its arrival and complete ending. One-time participation recognition earned / UNSAVED until you Save. Your work is still a Draft Song until you explicitly Finish it.")
        end
    end
end

function Service:remove(player)
    local session = self.sessions[player]
    self.sessions[player], self.completed[player], self.opened[player] = nil, nil, nil
    self:stopTracked(player, session)
end

return Service
