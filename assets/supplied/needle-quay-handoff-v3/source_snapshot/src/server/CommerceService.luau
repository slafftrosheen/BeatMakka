local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Catalog = require(game:GetService("ReplicatedStorage").Shared.CommerceCatalog)

local Commerce = {}
Commerce.__index = Commerce

local function productionMatches()
    return Catalog.productionMatches(
        game.GameId,
        game.CreatorId,
        game.CreatorType.Name,
        RunService:IsStudio()
    )
end

function Commerce.new(profiles, changedCallback, notifyCallback)
    local self = setmetatable({
        profiles = profiles,
        changed = changedCallback,
        notify = notifyCallback,
        records = {},
        destroyed = false,
    }, Commerce)
    self.purchaseConnection = MarketplaceService.PromptGamePassPurchaseFinished:Connect(
        function(player, passId, wasPurchased)
            local bundleId = Catalog.bundleForPass(passId)
            local record = self.records[player]
            if not wasPurchased or not bundleId or not record or not productionMatches() then
                return
            end
            -- This server event starts verification; it is not a client entitlement claim.
            -- Invalidate an older in-flight check so its stale answer cannot win the race.
            record.tokens[bundleId] += 1
            record.states[bundleId] = "pending"
            record.nextCheck[bundleId] = 0
            record.purchaseChecks[bundleId] = true
            self:refresh(player, bundleId)
        end
    )
    return self
end

function Commerce:_current(player, record)
    return not self.destroyed
        and self.records[player] == record
        and self.profiles[player] == record.profile
        and player.Parent == Players
end

function Commerce:_changed(player)
    if self.changed then
        local ok = pcall(self.changed, player)
        if not ok then
            warn("Commerce state callback failed.")
        end
    end
end

function Commerce:_notify(player, message)
    if self.notify then
        local ok = pcall(self.notify, player, message)
        if not ok then
            warn("Commerce notification callback failed.")
        end
    end
end

function Commerce:_check(player, record, bundleId, token, attempt)
    task.spawn(function()
        if not self:_current(player, record) or record.tokens[bundleId] ~= token then
            return
        end
        local bundle = Catalog.Bundles[bundleId]
        local ok, owns = pcall(function()
            return MarketplaceService:UserOwnsGamePassAsync(player.UserId, bundle.PassId)
        end)
        if not self:_current(player, record) or record.tokens[bundleId] ~= token then
            return
        end
        if not productionMatches() or not Catalog.bindingReady(bundleId) then
            record.states[bundleId] = "unavailable"
            self:_changed(player)
            return
        end
        if ok and owns == true then
            local newlyOwned = record.owned[bundleId] ~= true
            record.owned[bundleId] = true
            record.states[bundleId] = "owned"
            local purchasedHere = record.purchaseChecks[bundleId] == true
            record.purchaseChecks[bundleId] = nil
            self:_changed(player)
            if newlyOwned and purchasedHere then
                self:_notify(player, bundle.label .. " is ready. Choose your items in Wardrobe.")
            end
            return
        end
        -- Once confirmed, a transient query must not strip a permanent purchase this session.
        if record.owned[bundleId] == true then
            record.states[bundleId] = "owned"
            record.purchaseChecks[bundleId] = nil
            self:_changed(player)
            return
        end
        if (not ok or record.purchaseChecks[bundleId]) and attempt < 3 then
            record.states[bundleId] = "checking"
            self:_changed(player)
            task.delay(if attempt == 1 then 3 else 10, function()
                if self:_current(player, record) and record.tokens[bundleId] == token then
                    self:_check(player, record, bundleId, token, attempt + 1)
                end
            end)
            return
        end
        record.states[bundleId] = if not ok or record.purchaseChecks[bundleId]
            then "error"
            else "available"
        record.purchaseChecks[bundleId] = nil
        self:_changed(player)
    end)
end

function Commerce:load(player)
    if self.destroyed or not self.profiles[player] then
        return
    end
    if self.records[player] then
        self:refresh(player)
        return
    end
    local record = {
        profile = self.profiles[player],
        owned = {},
        states = {},
        tokens = {},
        nextCheck = {},
        purchaseChecks = {},
    }
    for _, bundleId in Catalog.Order do
        record.states[bundleId] = "unavailable"
        record.tokens[bundleId] = 0
        record.nextCheck[bundleId] = 0
    end
    self.records[player] = record
    self:refresh(player)
end

function Commerce:refresh(player, requestedBundleId)
    local record = self.records[player]
    if not record or not self:_current(player, record) then
        return false
    end
    if requestedBundleId ~= nil and not Catalog.Bundles[requestedBundleId] then
        return false
    end
    local allowed = productionMatches() and record.profile.ready and not record.profile.loadFailed
    for _, bundleId in Catalog.Order do
        if requestedBundleId ~= nil and requestedBundleId ~= bundleId then
            continue
        end
        if not allowed or not Catalog.bindingReady(bundleId) then
            record.states[bundleId] = "unavailable"
            continue
        end
        if record.states[bundleId] == "checking" or os.clock() < record.nextCheck[bundleId] then
            continue
        end
        record.tokens[bundleId] += 1
        record.nextCheck[bundleId] = os.clock() + 5
        record.states[bundleId] = "checking"
        self:_check(player, record, bundleId, record.tokens[bundleId], 1)
    end
    self:_changed(player)
    return true
end

function Commerce:verified(player)
    local record = self.records[player]
    return if record and self:_current(player, record) then table.clone(record.owned) else {}
end

function Commerce:summary(player)
    local record = self.records[player]
    local profile = self.profiles[player]
    local allowed = not self.destroyed
        and productionMatches()
        and profile ~= nil
        and profile.ready == true
        and not profile.loadFailed
    local summary =
        { enabled = false, status = "unavailable", owned = self:verified(player), bundles = {} }
    local checking, failed = false, false
    for _, bundleId in Catalog.Order do
        local bound = allowed and Catalog.bindingReady(bundleId)
        local state = if record then record.states[bundleId] else "unavailable"
        local forSale = bound and Catalog.Enabled == true
        summary.bundles[bundleId] = {
            status = if bound then state else "unavailable",
            available = forSale and state == "available",
        }
        summary.enabled = summary.enabled or forSale
        checking = checking or (bound and state == "checking")
        failed = failed or (bound and state == "error")
    end
    if summary.enabled then
        summary.status = if checking then "checking" elseif failed then "error" else "available"
    end
    return summary
end

function Commerce:remove(player)
    self.records[player] = nil
end

function Commerce:destroy()
    if self.destroyed then
        return
    end
    self.destroyed = true
    self.purchaseConnection:Disconnect()
    table.clear(self.records)
end

return Commerce
