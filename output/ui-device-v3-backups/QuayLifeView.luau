local Gui = require(script.Parent.GuiFactory)
local Theme = require(game.ReplicatedStorage.Shared.Theme)
local Life = require(game.ReplicatedStorage.Shared.QuayLifeCatalog)
local View = {}
View.__index = View
function View.new(parent, track)
    local self = setmetatable({ stamps = {}, gardens = {}, track = track, found = {} }, View)
    self.root = Gui.make("Frame", parent, {
        Name = "QuayLifeJournal",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -10, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Visible = false,
    })
    Gui.make(
        "UIListLayout",
        self.root,
        { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }
    )
    local function label(text, height, color)
        local l = Gui.label(self.root, text, 15, color or Theme.Ink)
        l.Size = UDim2.new(1, 0, 0, height)
        l.TextWrapped = true
        return l
    end
    self.rank = label("", 32, Theme.Teal)
    self.rank.Font = Theme.Bold
    local bar = Gui.round(
        Gui.make(
            "Frame",
            self.root,
            { Size = UDim2.new(1, 0, 0, 8), BackgroundColor3 = Theme.Stone, BorderSizePixel = 0 }
        ),
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
    self.summary = label("", 38)
    self.bag = Gui.button(self.root, "", function()
        if self.parcel == 2 then
            return
        end
        track(
            if self.parcel == 1 then "parcel_drop" else "parcel_pickup",
            "RECORD SLEEVES",
            "Take Naya's spare sleeves to Tori's record box by the dock."
        )
    end)
    self.bag.Name, self.bag.Size = "DeliveryFavor", UDim2.new(1, 0, 0, 62)
    self.bonds = label("", 78, Theme.Teal)
    label("SOUND POSTCARDS  /  Listen, pause, collect a memory", 32, Theme.Walnut)
    for _, row in Life.Stamps do
        local b = Gui.button(self.root, "", function()
            if self.found[row.id] then
                self.expandedPostcard = if self.expandedPostcard == row.id then nil else row.id
                self:update(self.state)
                return
            end
            track("listen_" .. row.id, row.title, "Stay by the listening post for a few seconds.")
        end)
        b.Name, b.Size = "Postcard_" .. row.id, UDim2.new(1, 0, 0, 52)
        self.stamps[row.id] = b
    end
    label("SMALL ACTS OF CARE  /  Three neighbors' gardens", 32, Theme.Walnut)
    for _, row in Life.Gardens do
        local b = Gui.button(self.root, "", function()
            track("garden_" .. row.id, row.title, "Tend the planter beside your neighbor's place.")
        end)
        b.Name, b.Size = "Garden_" .. row.id, UDim2.new(1, 0, 0, 48)
        self.gardens[row.id] = b
    end
    self.save = label("", 38, Theme.Walnut)
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
    self.rank.Text = string.format("%02d  /  %s", l.rank, l.title)
    self.fill.Size = UDim2.fromScale(
        if l.next then math.clamp((l.xp - l.floor) / (l.next - l.floor), 0, 1) else 1,
        1
    )
    self.summary.Text = string.format(
        "%d neighborhood XP%s  ·  %d/6 postcards  ·  %d/3 gardens",
        l.xp,
        if l.next then " / " .. l.next else " / highest rank",
        l.stamps,
        l.gardens
    )
    self.bag.Text = if self.parcel == 0
        then "FAVOR / Naya has a parcel for Tori  →"
        elseif
            self.parcel == 1
        then "IN YOUR BAG / Spare record sleeves\nDeliver to Tori's record box  →"
        else "FAVOR COMPLETE / Tori's records are safe"
    self.bag.BackgroundColor3 = if self.parcel == 2 then Theme.Walnut else Theme.Teal
    local done = q.progress.completed
    local function bond(n)
        return ({ "New face", "Acquainted", "Trusted", "Good neighbor" })[math.clamp(n + 1, 1, 4)]
    end
    local tori = (if done["NQ-Q01"] then 1 else 0)
        + (if done["NQ-Q02"] then 1 else 0)
        + (if self.parcel == 2 then 1 else 0)
    local ivo = (if done["NQ-Q04"] then 1 else 0)
        + (if done["NQ-Q05"] then 1 else 0)
        + (if l.progress.gardens.alley then 1 else 0)
    local naya = (if done["NQ-Q06"] then 1 else 0)
        + (if done["NQ-Q07"] then 1 else 0)
        + (if self.parcel == 2 then 1 else 0)
    self.bonds.Text = "NEIGHBORS\nTori / "
        .. bond(tori)
        .. "     Ivo / "
        .. bond(ivo)
        .. "\nNaya / "
        .. bond(naya)
        .. "     Nell / "
        .. bond(
            (if l.progress.gardens.cafe then 1 else 0) + (if l.progress.stamps.cafe then 1 else 0)
        )
    for _, row in Life.Stamps do
        local found = l.progress.stamps[row.id]
        self.found[row.id] = found
        local b = self.stamps[row.id]
        local expanded = found and self.expandedPostcard == row.id
        b.Size = UDim2.new(1, 0, 0, if expanded then 132 else 52)
        b.TextWrapped = true
        b.Text = (if found then "COLLECTED / " else "LISTEN / ")
            .. row.title
            .. (if expanded then "\n\n" .. row.note elseif found then "  / RECALL" else "  →")
        b.BackgroundColor3, b.TextColor3 =
            if found then Theme.Cream else Theme.Teal, if found then Theme.Ink else Theme.Cream
    end
    for _, row in Life.Gardens do
        local found = l.progress.gardens[row.id]
        local b = self.gardens[row.id]
        b.Text = (if found then "TENDED / " else "TEND / ") .. row.title
        b.BackgroundColor3 = if found then Theme.Walnut else Theme.Teal
    end
    self.save.Text = if state.saveMode == "session"
        then "Progress is saved for this Studio session. XP is awarded once per discovery or favor."
        else "Your journal uses the existing profile save. XP is awarded once per discovery or favor."
end
return View
