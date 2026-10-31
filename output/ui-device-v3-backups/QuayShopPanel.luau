local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage").Shared
local Catalog = require(Shared.CommerceCatalog)
local Theme = require(Shared.Theme)
local Gui = require(script.Parent.GuiFactory)

local Shop = {}
Shop.__index = Shop

local function label(parent, name, text, size, order)
    local object = Gui.label(parent, text, size)
    object.Name = name
    object.Size = UDim2.new(1, 0, 0, size + 4)
    object.AutomaticSize = Enum.AutomaticSize.Y
    object.LayoutOrder = order
    object.TextYAlignment = Enum.TextYAlignment.Top
    return object
end

local function setButton(button, text, enabled)
    button.Text = text
    button.Active = enabled
    button.Selectable = enabled
    button.AutoButtonColor = enabled
    button.TextTransparency = if enabled then 0 else 0.28
    button.BackgroundColor3 = if enabled then Theme.Teal else Theme.Graphite
end

function Shop.new(parent, refreshOwnership)
    local self = setmetatable({
        cards = {},
        state = nil,
        prompt = nil,
        refreshOwnership = refreshOwnership,
        destroyed = false,
    }, Shop)
    self.frame = Gui.make("Frame", parent, {
        Name = "NeedleQuayShop",
        Size = UDim2.new(1, -6, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = 1,
    })
    Gui.make("UIListLayout", self.frame, {
        Padding = UDim.new(0, 12),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    local heading = label(self.frame, "Heading", "THE QUAY STYLE COUNTER", 18, 1)
    heading.Font = Theme.Bold
    label(
        self.frame,
        "Introduction",
        "Find your own look. Every set is permanent and cosmetic, for use in BeatMakka. Earn more styles by exploring the Quay.",
        14,
        2
    )
    self.status = label(self.frame, "ShopStatus", "Checking the counter...", 14, 3)
    for index, bundleId in Catalog.Order do
        local bundle = Catalog.Bundles[bundleId]
        local card = Gui.round(Gui.make("Frame", self.frame, {
            Name = "Bundle_" .. bundleId,
            Size = UDim2.fromScale(1, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = Theme.Stone,
            BorderSizePixel = 0,
            LayoutOrder = index + 3,
        }))
        Gui.make("UIPadding", card, {
            PaddingLeft = UDim.new(0, 12),
            PaddingRight = UDim.new(0, 12),
            PaddingTop = UDim.new(0, 12),
            PaddingBottom = UDim.new(0, 12),
        })
        Gui.make("UIListLayout", card, {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })
        local title = label(card, "Title", bundle.label, 17, 1)
        title.Font = Theme.Bold
        label(card, "Description", bundle.description, 14, 2)
        label(
            card,
            "Contents",
            "Includes: " .. table.concat(Catalog.contents(bundleId), ", ") .. ".",
            13,
            3
        )
        local status = label(card, "Status", "Not on sale.", 13, 4)
        local buy = Gui.button(card, "Not on sale", function()
            self:_buy(bundleId)
        end)
        buy.Name = "BuyBundle"
        buy.Size = UDim2.new(1, 0, 0, 44)
        buy.LayoutOrder = 5
        local retry = Gui.button(card, "Check price again", function()
            if self.cards[bundleId].retryMode == "ownership" then
                self:_retryOwnership(bundleId)
            else
                self:_fetchPrice(bundleId, true)
            end
        end)
        retry.Name = "RetryPrice"
        retry.Size = UDim2.new(1, 0, 0, 44)
        retry.LayoutOrder = 6
        retry.Visible = false
        self.cards[bundleId] = {
            frame = card,
            status = status,
            buy = buy,
            retry = retry,
            priceState = "idle",
            price = nil,
            priceAt = 0,
            priceToken = 0,
            notice = nil,
            verifying = false,
            nextOwnershipRetry = 0,
        }
    end
    self.purchaseConnection = MarketplaceService.PromptGamePassPurchaseFinished:Connect(
        function(player, passId, wasPurchased)
            local pending = self.prompt
            if
                self.destroyed
                or player ~= Players.LocalPlayer
                or not pending
                or pending.passId ~= passId
            then
                return
            end
            self.prompt = nil
            local card = self.cards[pending.bundleId]
            if wasPurchased then
                card.verifying = true
                card.notice =
                    "Checking ownership. Your items appear in Wardrobe after verification."
            else
                card.verifying = false
                card.notice = "Purchase cancelled. Your current look stays the same."
            end
            -- Only a later server summary can mark this bundle owned.
            self:_render()
        end
    )
    self.destroyConnection = self.frame.Destroying:Connect(function()
        self:destroy(true)
    end)
    self:_render()
    return self
end

function Shop:_available(bundleId)
    local state = self.state
    local entry = state and state.bundles and state.bundles[bundleId]
    return state ~= nil
        and state.enabled == true
        and Catalog.Enabled == true
        and Catalog.bindingReady(bundleId)
        and entry ~= nil
        and entry.available == true
        and not (state.owned and state.owned[bundleId] == true)
end

function Shop:_retryOwnership(bundleId)
    local card = self.cards[bundleId]
    if self.destroyed or not self.refreshOwnership or os.clock() < card.nextOwnershipRetry then
        return
    end
    card.nextOwnershipRetry = os.clock() + 5
    -- A retry requests server evidence; it must never reopen a purchase window.
    self.refreshOwnership()
end

function Shop:_fetchPrice(bundleId, force)
    local card = self.cards[bundleId]
    if
        self.destroyed
        or not card
        or card.verifying
        or not self:_available(bundleId)
        or card.priceState == "loading"
    then
        return
    end
    if not force and card.priceState ~= "idle" then
        return
    end
    card.priceToken += 1
    local token = card.priceToken
    card.priceState = "loading"
    card.price = nil
    self:_render()
    task.spawn(function()
        local ok, info = pcall(function()
            return MarketplaceService:GetProductInfoAsync(
                Catalog.Bundles[bundleId].PassId,
                Enum.InfoType.GamePass
            )
        end)
        if self.destroyed or card.priceToken ~= token then
            return
        end
        local price = if ok and type(info) == "table" then info.PriceInRobux else nil
        if ok and type(info) == "table" and info.IsForSale ~= true then
            card.priceState = "unavailable"
        elseif type(price) == "number" and price > 0 and price < 2 ^ 53 and price % 1 == 0 then
            card.price = price
            card.priceAt = os.clock()
            card.priceState = "ready"
        else
            card.priceState = "error"
        end
        self:_render()
    end)
end

function Shop:_buy(bundleId)
    local card = self.cards[bundleId]
    if self.destroyed or self.prompt or not self:_available(bundleId) or card.verifying then
        return
    end
    if card.priceState ~= "ready" then
        self:_fetchPrice(bundleId, true)
        return
    end
    if os.clock() - card.priceAt > 60 then
        card.notice = "Refreshing the price. Review it, then choose Buy when you are ready."
        self:_fetchPrice(bundleId, true)
        return
    end
    local passId = Catalog.Bundles[bundleId].PassId
    self.prompt = { bundleId = bundleId, passId = passId }
    card.notice = nil
    self:_render()
    local ok = pcall(function()
        MarketplaceService:PromptGamePassPurchase(Players.LocalPlayer, passId)
    end)
    if not ok and not self.destroyed then
        self.prompt = nil
        card.notice = "The purchase window could not open. You can try again when ready."
        self:_render()
    end
end

function Shop:_render()
    if self.destroyed then
        return
    end
    local state = self.state
    self.status.Text = if not state
        then "Checking the counter..."
        elseif
            state.enabled ~= true
        then "These sets are being prepared. The full Needle Quay adventure is available through play."
        else "Optional style sets. The price below comes from Roblox for your account; the Roblox window confirms your purchase."
    for _, bundleId in Catalog.Order do
        local card = self.cards[bundleId]
        local entry = state and state.bundles and state.bundles[bundleId]
        local owned = state and state.owned and state.owned[bundleId] == true
        card.retry.Visible = false
        card.retryMode = "price"
        card.retry.Text = "Check price again"
        if owned then
            card.verifying = false
            card.notice = nil
            card.status.Text = "Yours permanently in BeatMakka. Choose these items in Wardrobe."
            setButton(card.buy, "Owned", false)
        elseif not state or (entry and entry.status == "checking") then
            card.status.Text = "Checking your owned styles..."
            setButton(card.buy, "Checking ownership", false)
        elseif entry and entry.status == "error" then
            card.status.Text =
                "Ownership could not be confirmed. Check again, or rejoin to restore completed purchases."
            setButton(card.buy, "Ownership unavailable", false)
            card.retryMode = "ownership"
            card.retry.Text = "Check ownership again"
            card.retry.Visible = self.refreshOwnership ~= nil
        elseif not self:_available(bundleId) then
            card.status.Text = "This style set is being prepared and is not on sale."
            setButton(card.buy, "Not on sale", false)
        elseif self.prompt then
            card.status.Text = "Finish or close the Roblox purchase window to continue."
            setButton(
                card.buy,
                if self.prompt.bundleId == bundleId
                    then "Purchase window open"
                    else "Purchase in progress",
                false
            )
        elseif card.verifying then
            card.status.Text =
                "Roblox has not confirmed ownership yet. Check again, or rejoin to restore your items. No second purchase window will open."
            setButton(card.buy, "Checking purchase", false)
            card.retryMode = "ownership"
            card.retry.Text = "Check ownership again"
            card.retry.Visible = self.refreshOwnership ~= nil
        elseif card.priceState == "error" then
            card.status.Text = "The current price could not be loaded. No purchase has been opened."
            setButton(card.buy, "Price unavailable", false)
            card.retry.Visible = true
        elseif card.priceState == "unavailable" then
            card.status.Text = "This set is not currently for sale on Roblox."
            setButton(card.buy, "Not on sale", false)
            card.retry.Visible = true
        elseif card.priceState == "ready" then
            card.status.Text = card.notice
                or "Three guaranteed cosmetic items. No effect on music tools, XP or story progress."
            setButton(card.buy, "Buy for " .. tostring(card.price) .. " Robux", true)
        else
            card.status.Text = "Loading the current price for your account..."
            setButton(card.buy, "Loading price", false)
        end
    end
end

function Shop:update(commerceSummary)
    if self.destroyed then
        return
    end
    self.state = commerceSummary
    self:_render()
    for _, bundleId in Catalog.Order do
        self:_fetchPrice(bundleId, false)
    end
end

function Shop:destroy(parentDestroying)
    if self.destroyed then
        return
    end
    self.destroyed = true
    if self.purchaseConnection then
        self.purchaseConnection:Disconnect()
    end
    if self.destroyConnection then
        self.destroyConnection:Disconnect()
    end
    if not parentDestroying then
        self.frame:Destroy()
    end
end

return Shop
