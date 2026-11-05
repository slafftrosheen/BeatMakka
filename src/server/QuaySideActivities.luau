-- Optional server-owned street games. No client-supplied completion or timing claims.
local Theme = require(game.ReplicatedStorage.Shared.Theme)
local Games = require(game.ReplicatedStorage.Shared.QuayStreetGames)
local Fair = require(game.ReplicatedStorage.Shared.QuayFair)
local Service = {}
Service.__index = Service
function Service.new(owner)
    local self =
        setmetatable({ owner = owner, nodes = {}, rounds = {}, shops = {}, last = {}, serial = 0 }, Service)
    self.prizeNode = require(script.Parent.QuayFairScene).build(owner.scene.root)
    self.prizeNode.ProximityPrompt.Triggered:Connect(function(player) self:openShop(player) end)
    for _, id in Games.Order do
        local gameInfo = Games.ById[id]
        local row = { id, gameInfo.title, gameInfo.position }
        local node = Instance.new("Part")
        node.Name, node.Size, node.Position =
            "StreetGame_" .. row[1], Vector3.new(5, 3.8, 2.4), row[3]
        node.Anchored, node.Color, node.Material = true, Theme.Teal, Enum.Material.Metal
        node.Parent = owner.scene.root
        node:SetAttribute("StreetActivity", row[1])
        node:SetAttribute("GuideIcon", gameInfo.icon)
        local gui = Instance.new("BillboardGui")
        gui.Size, gui.StudsOffset, gui.MaxDistance, gui.AlwaysOnTop =
            UDim2.fromOffset(150, 44), Vector3.new(0, 4, 0), 75, false
        gui.Parent = node
        local label = Instance.new("TextLabel")
        label.Size, label.BackgroundColor3, label.TextColor3 =
            UDim2.fromScale(1, 1), Theme.Ink, Theme.Amber
        label.Font, label.TextSize, label.Text = Enum.Font.Code, 17, row[2]
        label.Parent = gui
        for i = 1, 4 do
            local pad = Instance.new("Part")
            pad.Name, pad.Size = "Pad" .. i, Vector3.new(0.9, 0.12, 1.4)
            pad.Position = node.Position + Vector3.new((i - 2.5) * 1.1, 1.96, 0)
            pad.Anchored, pad.CanCollide, pad.Material = true, false, Enum.Material.Neon
            pad.Color = ({ Theme.Coral, Theme.Amber, Theme.FadedTeal, Theme.Cream })[i]
            pad.Parent = node
        end
        local prompt = Instance.new("ProximityPrompt")
        prompt.ActionText, prompt.ObjectText, prompt.MaxActivationDistance = "Play", row[2], 10
        prompt.RequiresLineOfSight = false
        prompt.Parent = node
        prompt.Triggered:Connect(function(player)
            self:start(player, row[1])
        end)
        self.nodes[row[1]] = node
    end
    return self
end
function Service:available(player, id)
    local p = self.owner.profiles[player]
    return p
        and p.ready
        and not p.station
        and not p.playing
        and not p.recording
        and self.nodes[id]
        and self.owner.nearby(player, self.nodes[id], 13)
end
function Service:start(player, id)
    if not self:available(player, id) or os.clock() - (self.last[player] or 0) < 0.3 then
        return
    end
    self.last[player] = os.clock()
    self.shops[player] = nil
    self.owner.opened[player], self.owner.conversations[player] = nil, nil
    self.serial += 1
    local sequence = {}
    for i = 1, 4 do
        sequence[i] = Random.new(self.serial * 47 + i * 193):NextInteger(1, 4)
    end
    local now = workspace:GetServerTimeNow()
    self.rounds[player] = {
        id = id,
        serial = self.serial,
        sequence = sequence,
        index = 1,
        score = 0,
        start = now + 1,
        response = now + 3.6,
        expires = now + (if Fair.isGame(id) then Fair.DemoSeconds else 28),
        status = if Fair.isGame(id) then "ready" else "playing",
        targetAt = now + (if id == "bells" then Random.new(self.serial):NextNumber(1.2, 2.5) else 1),
    }
    self.owner.send(player)
end
function Service:summary(player)
    local round = self.rounds[player]
    if
        round
        and (not self:available(player, round.id) or workspace:GetServerTimeNow() > round.expires)
    then
        self.rounds[player] = nil
        return nil
    end
    return round
end
function Service:atPrizes(player)
    local p = self.owner.profiles[player]
    return p and p.ready and not p.station and self.owner.nearby(player, self.prizeNode, 13)
end
function Service:openShop(player)
    if not self:atPrizes(player) then return end
    self.rounds[player] = nil
    self.shops[player] = true
    self.owner.opened[player], self.owner.conversations[player] = nil, nil
    self.owner.send(player)
end
function Service:shopSummary(player)
    if self.shops[player] and not self:atPrizes(player) then self.shops[player] = nil end
    return self.shops[player] == true
end
function Service:command(player, action, value)
    if action == "QuaySidePrizes" then self:openShop(player); return end
    if action == "QuaySideClaim" then
        local p = self.owner.profiles[player]
        local prize = type(value) == "string" and Fair.find(value)
        if not prize or not self:shopSummary(player) or not self:atPrizes(player) then return end
        if os.clock() - (self.last[player] or 0) < 0.3 then return end
        self.last[player] = os.clock()
        local fair = Fair.summary(p.quay.fair)
        if fair.prizes[prize.id] then self.owner.send(player, "Already kept."); return end
        if fair.balance < prize.cost then self.owner.send(player, "Earn more fair coins first."); return end
        p.quay.fair = Fair.sanitize(p.quay.fair)
        p.quay.fair.prizes[prize.id] = true
        self.owner:changed(player, p)
        self.owner.send(player, prize.label .. " kept. Equip it in Style.")
        return
    end
    if action == "QuaySideClose" then
        self.rounds[player], self.shops[player] = nil, nil
        self.owner.send(player)
        return
    end
    local round = self:summary(player)
    if not round then
        return
    end
    if action == "QuaySideBegin" then
        if not Fair.isGame(round.id) or round.status ~= "ready" or value ~= round.serial then return end
        if os.clock() - (self.last[player] or 0) < 0.09 then return end
        self.last[player] = os.clock()
        local now = workspace:GetServerTimeNow()
        round.status, round.start, round.expires = "playing", now + 1, now + Fair.RoundSeconds
        round.targetAt = now + (if round.id == "bells" then Random.new(round.serial):NextNumber(1.2, 2.5) else 1)
        self.owner.send(player)
        return
    end
    if action == "QuaySideRetry" then
        self:start(player, round.id)
        return
    end
    if
        action ~= "QuaySideTap"
        or type(value) ~= "table"
        or value.serial ~= round.serial
        or type(value.pad) ~= "number"
        or value.pad % 1 ~= 0
        or value.pad < 1
        or value.pad > 4
        or round.status ~= "playing"
    then
        return
    end
    local now = workspace:GetServerTimeNow()
    if os.clock() - (self.last[player] or 0) < 0.09 then
        return
    end
    self.last[player] = os.clock()
    if round.id == "targets" or round.id == "bells" then
        if now < round.targetAt then return end
        local window = Fair.Windows[round.id]
        if now > round.targetAt + window or value.pad ~= round.sequence[round.index] then
            round.status = "retry"
        else
            round.index += 1
            round.score += 1
            round.targetAt = now + (if round.id == "bells"
                then Random.new(round.serial * 47 + round.index):NextNumber(0.8, 2) else 0.55)
        end
    elseif round.id == "rings" then
        if now < round.targetAt or value.pad ~= 1 then return end
        local phase = ((now - round.targetAt) % Fair.RingPeriod) / Fair.RingPeriod
        if phase >= Fair.RingLow and phase <= Fair.RingHigh then
            round.index += 1
            round.score += 1
            round.targetAt = now + 0.65
        else
            round.status = "retry"
        end
    elseif round.id == "echo" then
        if now < round.response then
            return
        end
        if value.pad ~= round.sequence[round.index] then
            round.status = "retry"
        else
            round.index += 1
            round.score += 1
        end
    elseif round.id == "chase" then
        if now < round.targetAt then
            return
        end
        if now > round.targetAt + 2.2 or value.pad ~= round.sequence[round.index] then
            round.status = "retry"
        else
            round.index += 1
            round.score += 1
            round.targetAt = now + 0.45
        end
    elseif round.id == "lantern" then
        if now < round.targetAt or value.pad ~= 1 then
            return
        end
        -- The cursor and hit window both use server time; no submitted timestamp.
        local phase = ((now - round.targetAt) % 1.8) / 1.8
        if phase >= 0.38 and phase <= 0.62 then
            round.index += 1
            round.score += 1
            round.targetAt = now + 0.55
        else
            round.status = "retry"
        end
    else
        -- Four pulses, 100 BPM. Clock measured here; client cannot forge hit times.
        local target = round.start + (round.index + 1) * 0.6
        if now < target - 0.28 then
            return
        end
        if math.abs(now - target) > 0.28 then
            round.status = "retry"
        else
            round.index += 1
            round.score += 1
        end
    end
    if round.score == 4 then
        round.status = "complete"
        local p = self.owner.profiles[player]
        local first = not p.quay.side[round.id]
        if not p.quay.side[round.id] then
            p.quay.side[round.id] = true
            self.owner:changed(player, p)
        end
        round.expires = now + 60
        if Fair.isGame(round.id) then
            p.quay.fair = Fair.sanitize(p.quay.fair)
            local count = p.quay.fair.clears[round.id]
            round.coins = if count < Fair.Heats then Fair.CoinsPerHeat else 0
            if count < Fair.Heats then
                p.quay.fair.clears[round.id] = count + 1
                self.owner:changed(player, p)
            end
        end
        self.owner:celebrate(player, round.id, first)
    end
    self.owner.send(player)
end
function Service:remove(player)
    self.rounds[player], self.last[player], self.shops[player] = nil, nil, nil
end
return Service
