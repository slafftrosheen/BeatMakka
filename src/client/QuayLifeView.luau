local Gui = require(script.Parent.GuiFactory)
local Icons = require(script.Parent.GameIcons)
local Theme = require(game.ReplicatedStorage.Shared.Theme)
local Life = require(game.ReplicatedStorage.Shared.QuayLifeCatalog)
local View = {}
View.__index = View
local function stack(parent, name, order)
    local frame = Gui.make("Frame", parent, {
        Name = name,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = order,
    })
    Gui.make(
        "UIListLayout",
        frame,
        { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }
    )
    return frame
end
local function label(parent, text, height, order, size, color)
    local value = Gui.label(parent, text, size or 15, color or Theme.Ink)
    value.Size, value.LayoutOrder = UDim2.new(1, 0, 0, height), order
    return value
end
function View.new(parent, track)
    local self = setmetatable(
        { stamps = {}, gardens = {}, track = track, found = {}, bonds = {}, metrics = {} },
        View
    )
    self.root = stack(parent, "QuayLifeJournal", 1)
    self.root.Size, self.root.Visible = UDim2.new(1, -10, 0, 0), false
    self.rank = label(self.root, "", 42, 1, 19, Theme.Teal)
    self.rank.Font = Enum.Font.Code
    local bar = Gui.round(
        Gui.make("Frame", self.root, {
            Size = UDim2.new(1, 0, 0, 8),
            BackgroundColor3 = Theme.FadedTeal,
            BorderSizePixel = 0,
            LayoutOrder = 2,
        }),
        4
    )
    self.fill = Gui.round(
        Gui.make(
            "Frame",
            bar,
            { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Theme.Teal, BorderSizePixel = 0 }
        ),
        4
    )
    local metrics = Gui.make("Frame", self.root, {
        Name = "NeighbourhoodProgress",
        Size = UDim2.new(1, 0, 0, 90),
        BackgroundTransparency = 1,
        LayoutOrder = 3,
    })
    for index, definition in
        { { "XP", "badge" }, { "POSTCARDS", "headphones" }, { "GARDENS", "flower" } }
    do
        local card = Gui.round(
            Gui.make("Frame", metrics, {
                Name = definition[1],
                Position = UDim2.fromScale((index - 1) / 3, 0),
                Size = UDim2.new(1 / 3, -5, 1, 0),
                BackgroundColor3 = Theme.Teal,
                BorderSizePixel = 0,
            }),
            8
        )
        Icons.make(card, definition[2], Theme.Amber, 24).Position = UDim2.new(0.5, -12, 0, 7)
        local value = label(card, "", 30, 0, 20, Theme.Cream)
        value.Font, value.TextXAlignment, value.Position =
            Enum.Font.Code, Enum.TextXAlignment.Center, UDim2.fromOffset(0, 34)
        local caption = label(card, definition[1], 22, 0, 9, Theme.Cream)
        caption.Font, caption.TextXAlignment, caption.Position =
            Enum.Font.Code, Enum.TextXAlignment.Center, UDim2.fromOffset(0, 65)
        self.metrics[index] = value
    end
    self.bag = Gui.button(self.root, "DELIVERY", function()
        if self.parcel == 2 then
            return
        end
        track(
            if self.parcel == 1 then "parcel_drop" else "parcel_pickup",
            "RECORD SLEEVES",
            "Take Naya's spare sleeves to Tori's record box by the dock."
        )
    end)
    self.bag.Name, self.bag.Size, self.bag.LayoutOrder = "DeliveryFavor", UDim2.new(1, 0, 0, 60), 4
    self.bag:SetAttribute("UiIcon", "crate")
    label(self.root, "YOUR NEIGHBOURS", 30, 5, 18, Theme.Teal).Font = Enum.Font.Code
    local neighbours = Gui.make("Frame", self.root, {
        Name = "NeighbourCards",
        Size = UDim2.new(1, 0, 0, 180),
        BackgroundTransparency = 1,
        LayoutOrder = 6,
    })
    for index, name in { "Tori", "Ivo", "Naya", "Nell" } do
        local card = Gui.round(
            Gui.make("Frame", neighbours, {
                Name = name,
                Position = UDim2.new((index - 1) % 2 / 2, 0, 0, math.floor((index - 1) / 2) * 92),
                Size = UDim2.new(0.5, -5, 0, 86),
                BackgroundColor3 = Theme.Stone,
                BorderSizePixel = 0,
            }),
            10
        )
        Icons.make(card, "people", Theme.Teal, 24).Position = UDim2.fromOffset(8, 7)
        local title = label(card, name, 26, 0, 15)
        title.Font, title.Position, title.Size =
            Enum.Font.Code, UDim2.fromOffset(38, 6), UDim2.new(1, -42, 0, 26)
        local status = label(card, "", 28, 0, 11, Theme.Teal)
        status.Position, status.Size = UDim2.fromOffset(8, 32), UDim2.new(1, -16, 0, 28)
        local dots = {}
        for dot = 1, 3 do
            dots[dot] = Gui.round(
                Gui.make("Frame", card, {
                    Position = UDim2.new((dot - 1) / 3, 8, 1, -16),
                    Size = UDim2.new(1 / 3, -12, 0, 6),
                    BackgroundColor3 = Theme.FadedTeal,
                    BorderSizePixel = 0,
                }),
                3
            )
        end
        self.bonds[name] = { status = status, dots = dots }
    end
    label(self.root, "SOUND POSTCARDS", 32, 7, 18, Theme.Teal).Font = Enum.Font.Code
    for index, row in Life.Stamps do
        local card = stack(self.root, "PostcardCard_" .. row.id, 7 + index)
        card.BackgroundColor3, card.BackgroundTransparency = Theme.Cream, 0
        Gui.round(card, 10)
        Gui.make("UIPadding", card, {
            PaddingLeft = UDim.new(0, 12),
            PaddingRight = UDim.new(0, 12),
            PaddingTop = UDim.new(0, 10),
            PaddingBottom = UDim.new(0, 10),
        })
        local header = Gui.make("Frame", card, {
            Name = "PostcardTitle",
            Size = UDim2.new(1, 0, 0, 48),
            BackgroundTransparency = 1,
            LayoutOrder = 0,
        })
        Icons.make(header, "journal", Theme.Teal, 32).Position = UDim2.fromOffset(0, 7)
        local title = label(header, row.title, 48, 0, 15)
        title.Position, title.Size, title.Font =
            UDim2.fromOffset(44, 0), UDim2.new(1, -44, 1, 0), Enum.Font.Code
        local note = label(card, row.note, 0, 2, 15)
        note.AutomaticSize, note.Visible = Enum.AutomaticSize.Y, false
        local b = Gui.button(card, "LISTEN", function()
            if self.found[row.id] then
                self.expandedPostcard = if self.expandedPostcard == row.id then nil else row.id
                self:update(self.state)
                return
            end
            track("listen_" .. row.id, row.title, "Stay by the listening post for a few seconds.")
        end)
        b.Name, b.Size, b.LayoutOrder = "Postcard_" .. row.id, UDim2.new(1, 0, 0, 48), 1
        b:SetAttribute("UiIcon", "headphones")
        self.stamps[row.id] = { button = b, note = note, title = title }
    end
    label(self.root, "GARDENS TO CARE FOR", 32, 20, 18, Theme.Teal).Font = Enum.Font.Code
    for index, row in Life.Gardens do
        local b = Gui.button(self.root, row.title, function()
            track("garden_" .. row.id, row.title, "Tend the planter beside your neighbor's place.")
        end)
        b.Name, b.Size, b.LayoutOrder = "Garden_" .. row.id, UDim2.new(1, 0, 0, 56), 20 + index
        b:SetAttribute("UiIcon", "flower")
        self.gardens[row.id] = b
    end
    self.save = label(self.root, "", 32, 30, 12, Theme.Walnut)
    self.save.Font = Enum.Font.Code
    self.saveDetails = label(self.root, "", 0, 32, 14, Theme.Walnut)
    self.saveDetails.AutomaticSize, self.saveDetails.Visible = Enum.AutomaticSize.Y, false
    local details
    details = Gui.button(self.root, "JOURNAL DETAILS", function()
        self.saveDetails.Visible = not self.saveDetails.Visible
        details.Text = if self.saveDetails.Visible then "HIDE DETAILS" else "JOURNAL DETAILS"
    end)
    details.Name, details.Size, details.LayoutOrder = "LifeDetails", UDim2.new(1, 0, 0, 44), 31
    details:SetAttribute("UiIcon", "hint")
    return self
end
function View:update(state)
    self.state = state
    local q = state and state.quay
    if not q or not q.life then
        return
    end
    local l = q.life
    self.parcel = l.progress.parcel
    self.rank.Text = string.format("%02d / %s", l.rank, l.title)
    self.fill.Size = UDim2.fromScale(
        if l.next then math.clamp((l.xp - l.floor) / (l.next - l.floor), 0, 1) else 1,
        1
    )
    self.metrics[1].Text, self.metrics[2].Text, self.metrics[3].Text =
        tostring(l.xp), l.stamps .. "/6", l.gardens .. "/3"
    self.bag.Text = if self.parcel == 0
        then "COLLECT FROM NAYA\nRECORD SLEEVES"
        elseif self.parcel == 1 then "DELIVER TO TORI\nRECORD SLEEVES"
        else "DELIVERY COMPLETE"
    self.bag.BackgroundColor3 = if self.parcel == 2 then Theme.Walnut else Theme.Teal
    local done = q.progress.completed
    local tori = (if done["NQ-Q01"] then 1 else 0)
        + (if done["NQ-Q02"] then 1 else 0)
        + (if self.parcel == 2 then 1 else 0)
    local ivo = (if done["NQ-Q04"] then 1 else 0)
        + (if done["NQ-Q05"] then 1 else 0)
        + (if l.progress.gardens.alley then 1 else 0)
    local naya = (if done["NQ-Q06"] then 1 else 0)
        + (if done["NQ-Q07"] then 1 else 0)
        + (if self.parcel == 2 then 1 else 0)
    local nell = (if l.progress.gardens.cafe then 1 else 0)
        + (if l.progress.stamps.cafe then 1 else 0)
    for name, amount in { Tori = tori, Ivo = ivo, Naya = naya, Nell = nell } do
        local card = self.bonds[name]
        card.status.Text = ({ "New face", "Acquainted", "Trusted", "Good neighbor" })[math.clamp(
            amount + 1,
            1,
            4
        )]
        for index, dot in card.dots do
            dot.BackgroundColor3 = if index <= amount then Theme.Teal else Theme.FadedTeal
        end
    end
    for _, row in Life.Stamps do
        local found = l.progress.stamps[row.id]
        self.found[row.id] = found
        local card = self.stamps[row.id]
        local expanded = found and self.expandedPostcard == row.id
        card.note.Visible = expanded == true
        card.button.Text = if expanded
            then "CLOSE POSTCARD"
            elseif found then "RECALL POSTCARD"
            else "FIND LISTENING POST"
        card.button:SetAttribute("UiIcon", if found then "journal" else "headphones")
        card.button.BackgroundColor3 = if found then Theme.Walnut else Theme.Teal
    end
    for _, row in Life.Gardens do
        local found = l.progress.gardens[row.id]
        local b = self.gardens[row.id]
        b.Text = (if found then "TENDED / " else "TEND / ") .. row.title
        b.BackgroundColor3 = if found then Theme.Walnut else Theme.Teal
    end
    self.save.Text = if state.saveMode == "session"
        then "STUDIO SESSION ONLY / XP ONCE"
        else "PROFILE SAVE / XP ONCE"
    self.saveDetails.Text = if state.saveMode == "session"
        then "Progress is saved for this Studio session. XP is awarded once per discovery or favor."
        else "Your journal uses the existing profile save. XP is awarded once per discovery or favor."
end
return View
