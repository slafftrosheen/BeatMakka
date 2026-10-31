local Shared = game.ReplicatedStorage.Shared
local Catalog = require(Shared.QuayBeatCommissions)
local Recipes = require(Shared.QuayFxRecipes)
local Evidence = require(Shared.QuayMusicEvidence)
local Workspace = game:GetService("Workspace")
local Service = {}
Service.__index = Service
function Service.new(owner)
    local remote = Instance.new("RemoteEvent")
    remote.Name = "QuayCommissionPlayback"
    remote.Parent = game.ReplicatedStorage.MusicNetwork
    local speech = Instance.new("RemoteEvent")
    speech.Name = "QuayCommissionSpeech"
    speech.Parent = remote.Parent
    return setmetatable({
        owner = owner,
        remote = remote,
        speech = speech,
        pending = {},
        results = {},
        last = {},
        spoken = {},
        serial = 0,
    }, Service)
end
function Service:say(player, item, cue)
    local key = (item.voice or item.id) .. "_" .. cue
    local previous = self.spoken[player]
    if previous and previous.key == key and os.clock() - previous.at < 12 then
        return
    end
    self.spoken[player] = { key = key, at = os.clock() }
    self.speech:FireClient(player, {
        key = key,
        host = item.host,
        name = item.name,
        cue = cue,
        position = self.owner.scene.stops[item.host].anchor.Position + Vector3.new(0, 3, 0),
    })
end
function Service:summary(player, profile)
    local q = profile.quay
    local item = Catalog.find(q.commission)
    local result = {
        active = q.commission,
        completed = q.commissions or {},
        busy = self.pending[player] ~= nil,
        feedback = self.results[player],
        sequences = {},
    }
    if item then
        for _, evidence in Evidence.savedSequences(profile) do
            table.insert(result.sequences, {
                id = evidence.id,
                title = evidence.sequence.name,
                revision = evidence.sequence.revision,
                review = Catalog.review(q, item, evidence),
            })
        end
    end
    return result
end
function Service:command(player, profile, action, value)
    if self.pending[player] then
        return
    end
    if action ~= "QuayCommissionBrief" and os.clock() - (self.last[player] or -10) < 1 then
        return
    end
    if action ~= "QuayCommissionBrief" then
        self.last[player] = os.clock()
    end
    local owner = self.owner
    if profile.playing or profile.recording or profile.station then
        owner.send(player, "Leave your studio and meet the host to play this request.")
        return
    end
    if action == "QuayCommissionCancel" then
        profile.quay.commission = nil
        self.results[player] = nil
        owner:changed(player, profile)
        owner.send(player)
        return
    end
    local item = Catalog.find(
        if action == "QuayCommissionAccept" or action == "QuayCommissionBrief"
            then value
            else profile.quay.commission
    )
    local node = item and owner.scene.stops[item.host]
    if not node or not owner.nearby(player, node.anchor, 15) then
        owner.send(player, "Meet the request's host to accept or play your beat.")
        return
    end
    if action == "QuayCommissionBrief" then
        self:say(player, item, "brief")
        return
    end
    if not Catalog.available(profile.quay, item) then
        owner.send(
            player,
            if item.prerequisite and not profile.quay.commissions[item.prerequisite]
                then "Finish the first request from this host to unlock the remix."
                else Recipes.find(item.fx).hint
        )
        return
    end
    if action == "QuayCommissionAccept" then
        profile.quay.commission = item.id
        self.results[player] = nil
        owner:changed(player, profile)
        owner.send(player, item.name .. ": Let's hear your take!")
        self:say(player, item, "brief")
    elseif action == "QuayCommissionSubmit" then
        local id = if type(value) == "table" then value.id else value
        if type(id) ~= "string" then
            return
        end
        local evidence = Catalog.saved(profile, id)
        if
            evidence
            and type(value) == "table"
            and value.revision ~= nil
            and value.revision ~= evidence.sequence.revision
        then
            owner.send(
                player,
                "That saved sequence revision changed. Choose it again before submitting."
            )
            return
        end
        local review = Catalog.review(profile.quay, item, evidence)
        if not evidence then
            self.results[player] = review.hint
            self:say(player, item, "save")
            owner.send(player)
            return
        end
        local token = {}
        self.pending[player] = token
        self.serial += 1
        local schedule = evidence.schedule
        local startsAt = Workspace:GetServerTimeNow() + 8
        self.results[player] = "Listening to sequence / " .. evidence.sequence.name
        self.remote:FireClient(player, {
            kind = "sequence",
            id = id,
            revision = evidence.sequence.revision,
            title = evidence.sequence.name,
            schedule = schedule,
            startedAt = startsAt,
            epoch = self.serial,
            loop = false,
            playing = true,
        })
        owner.send(player)
        task.delay(8 + schedule.completeAt, function()
            if self.pending[player] ~= token or owner.profiles[player] ~= profile then
                return
            end
            self.pending[player] = nil
            if not owner.nearby(player, node.anchor, 20) then
                self.results[player] = "Come back so we can finish listening together."
            elseif review.passed then
                local first = not profile.quay.commissions[item.id]
                profile.quay.commissions[item.id] = true
                profile.quay.commission = nil
                self.results[player] = item.name .. ": " .. item.thanks
                owner:changed(player, profile)
                self:say(player, item, "success")
                owner:celebrate(player, "commission_" .. item.id, first)
            else
                self.results[player] = item.name .. ": " .. review.hint
                self:say(player, item, review.cue)
            end
            owner.send(player)
        end)
    end
end
function Service:remove(player)
    self.spoken[player] = nil
    self.pending[player], self.results[player], self.last[player] = nil, nil, nil
end
return Service
