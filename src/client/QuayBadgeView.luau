local Gui = require(script.Parent.GuiFactory)
local Icons = require(script.Parent.GameIcons)
local Theme = require(game.ReplicatedStorage.Shared.Theme)
local Badges = require(game.ReplicatedStorage.Shared.QuayBadges)
local Recipes = require(game.ReplicatedStorage.Shared.QuayFxRecipes)
local View = {}
View.__index = View
function View.new(screen)
    local self = setmetatable({ rows = {}, queue = {}, effects = true, dead = false }, View)
    self.wardrobe = require(script.Parent.QuayWardrobeView).new(screen)
    self.dress = Gui.button(screen, "WARDROBE", function()
        self.panel.Visible = false
        self.wardrobe.panel.Visible = not self.wardrobe.panel.Visible
    end)
    self.dress.Position, self.dress.Size = UDim2.new(1, -282, 0, 58), UDim2.fromOffset(132, 42)
    self.toggle = Gui.button(screen, "     BADGES", function()
        self.wardrobe.panel.Visible = false
        self.panel.Visible = not self.panel.Visible
    end)
    self.toggle.Position, self.toggle.Size = UDim2.new(1, -144, 0, 58), UDim2.fromOffset(132, 42)
    Icons.make(self.toggle, "badge", Theme.Amber, 24).Position = UDim2.fromOffset(8, 8)
    self.panel = Gui.round(
        Gui.make("ScrollingFrame", screen, {
            Name = "QuayKeepsakes",
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -12, 0, 106),
            Size = UDim2.fromOffset(292, 382),
            CanvasSize = UDim2.fromOffset(0, #Badges.List * 52 + 58),
            ScrollBarThickness = 4,
            BackgroundColor3 = Theme.Ink,
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = 15,
        }),
        12
    )
    self.rank = Gui.label(self.panel, "NEW NEIGHBOR", 16, Theme.Amber)
    self.rank.Font = Enum.Font.Code
    self.rank.Position, self.rank.Size = UDim2.fromOffset(12, 8), UDim2.new(1, -24, 0, 34)
    for index, badge in Badges.List do
        local row = Gui.make("Frame", self.panel, {
            Position = UDim2.fromOffset(8, 50 + (index - 1) * 52),
            Size = UDim2.new(1, -16, 0, 48),
            BackgroundColor3 = Theme.Graphite,
            BorderSizePixel = 0,
        })
        local icon = Icons.make(row, badge.icon, Theme.Amber, 30)
        icon.Position = UDim2.fromOffset(8, 9)
        local text = Gui.label(row, badge.label, 13, Theme.Cream)
        text.Position, text.Size = UDim2.fromOffset(48, 2), UDim2.new(1, -54, 0, 23)
        local detail = Gui.label(row, badge.hint, 11, Theme.FadedTeal)
        detail.Position, detail.Size = UDim2.fromOffset(48, 24), UDim2.new(1, -54, 0, 20)
        self.rows[badge.id] = { frame = row, text = text, detail = detail }
    end
    self.banner = Gui.round(
        Gui.make("Frame", screen, {
            Name = "BadgeUnlocked",
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.fromScale(0.5, 0.12),
            Size = UDim2.fromOffset(280, 74),
            BackgroundColor3 = Theme.Ink,
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = 30,
        }),
        12
    )
    Icons.make(self.banner, "badge", Theme.Amber, 42).Position = UDim2.fromOffset(14, 16)
    self.bannerText = Gui.label(self.banner, "", 16, Theme.Amber)
    self.bannerText.Position, self.bannerText.Size =
        UDim2.fromOffset(66, 10), UDim2.new(1, -78, 1, -20)
    return self
end
function View:showNext()
    if self.showing or self.dead or #self.queue == 0 then
        return
    end
    self.showing = true
    local badge = table.remove(self.queue, 1)
    self.bannerText.Text = (
        if badge.fxReward
            then "FX DISCOVERED / SOUNDS\n"
            elseif badge.titleReward then "TITLE UNLOCKED\n"
            else "BADGE EARNED\n"
    ) .. badge.label
    self.banner.Visible = true
    Gui.Cue:Fire("ui_collect")
    if self.effects then
        local Tween = game:GetService("TweenService")
        for i = 1, 10 do
            local chip = Gui.make("Frame", self.banner, {
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(5, 9),
                BackgroundColor3 = if i % 2 == 0 then Theme.Amber else Theme.Coral,
                BorderSizePixel = 0,
            })
            local angle = i * math.pi * 0.2
            Tween
                :Create(chip, TweenInfo.new(0.75), {
                    Position = UDim2.new(0.5, math.cos(angle) * 150, 0.5, math.sin(angle) * 70),
                    BackgroundTransparency = 1,
                    Rotation = i * 45,
                })
                :Play()
            game:GetService("Debris"):AddItem(chip, 1)
        end
    end
    task.delay(3.5, function()
        if self.dead then
            return
        end
        self.banner.Visible = false
        self.showing = false
        self:showNext()
    end)
end
function View:accept(state)
    local q = state.quay
    local visible = q
        and state.ready
        and not state.station
        and not q.open
        and not q.sideActivity
        and not (state.concert and state.concert.open)
        and not (state.jam and state.jam.open)
    self.wardrobe:accept(state)
    self.dress.Visible = visible == true
    self.toggle.Visible = visible == true
    if not visible then
        self.wardrobe.panel.Visible = false
        self.panel.Visible = false
    end
    if not q or not state.ready then
        return
    end
    local fxEarned = {}
    for _, item in Recipes.List do
        fxEarned[item.id] = Recipes.earned(q.progress, item)
        if self.fxEarned and fxEarned[item.id] and not self.fxEarned[item.id] then
            table.insert(self.queue, { label = item.label, fxReward = true })
        end
    end
    self.fxEarned = fxEarned
    local earned, count = {}, 0
    for _, badge in Badges.List do
        local has = Badges.earned(q.progress, badge)
        earned[badge.id] = has
        local row = self.rows[badge.id]
        row.frame.BackgroundColor3 = if has then Theme.Teal else Theme.Graphite
        row.detail.Text = if has then "COLLECTED" else badge.hint
        if has then
            count += 1
            if self.earned and not self.earned[badge.id] then
                table.insert(self.queue, badge)
            end
        end
    end
    local rank = if count >= 9
        then "QUAY ICON"
        elseif count >= 6 then "BLOCK FAVORITE"
        elseif count >= 3 then "QUAY FRIEND"
        else "NEW NEIGHBOR"
    self.rank.Text = rank
    if self.lastCount then
        for _, milestone in { { 3, "QUAY FRIEND" }, { 6, "BLOCK FAVORITE" }, { 9, "QUAY ICON" } } do
            if self.lastCount < milestone[1] and count >= milestone[1] then
                table.insert(self.queue, { label = milestone[2], titleReward = true })
            end
        end
    end
    self.lastCount = count
    self.earned = earned
    self.toggle.Text = string.format("     %d / %d", count, #Badges.List)
    self:showNext()
end
function View:destroy()
    self.dead = true
    self.wardrobe:destroy()
    self.dress:Destroy()
    self.toggle:Destroy()
    self.panel:Destroy()
    self.banner:Destroy()
end
return View
