-- A readable front door to existing activities. Routes only; the server owns play and rewards.
local Shared = game.ReplicatedStorage.Shared
local Theme = require(Shared.Theme)
local Life = require(Shared.QuayLifeCatalog)
local Games = require(Shared.QuayStreetGames)
local Identity = require(Shared.QuayIdentity)
local Gui = require(script.Parent.GuiFactory)
local Icons = require(script.Parent.GameIcons)
local Board = {}
Board.__index = Board

local function label(parent, name, size, color)
    local object = Gui.label(parent, "", size, color or Theme.Ink)
    object.Name, object.Font = name, Enum.Font.Code
    return object
end
local function stack(parent, name, order)
    local frame = Gui.make("Frame", parent, { Name = name, Size = UDim2.new(1, -10, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = order or 1 })
    Gui.make("UIListLayout", frame, { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder })
    return frame
end
local function bar(parent, y, color)
    local rail = Gui.make("Frame", parent, { Position = UDim2.fromOffset(0, y),
        Size = UDim2.new(1, 0, 0, 5), BackgroundColor3 = Theme.Stone, BorderSizePixel = 0 })
    local fill = Gui.make("Frame", rail, { Size = UDim2.fromScale(0, 1),
        BackgroundColor3 = color or Theme.Teal, BorderSizePixel = 0 })
    return fill
end

function Board.new(parent, callbacks)
    local self = setmetatable({ callbacks = callbacks, filter = "play", entries = {}, filters = {}, skills = {} }, Board)
    self.root = stack(parent, "QuayActivityBoard")
    self.root.Visible = false
    self.notice = label(self.root, "ActivityNotice", 13, Theme.Ink)
    self.notice.Size, self.notice.AutomaticSize, self.notice.LayoutOrder = UDim2.new(1, 0, 0, 0), Enum.AutomaticSize.Y, 0
    self.notice.Visible = false
    local profile = Gui.make("Frame", self.root, { Name = "NeighbourhoodRank", Size = UDim2.new(1, 0, 0, 148),
        BackgroundTransparency = 1, LayoutOrder = 1 })
    Icons.make(profile, "badge", Theme.Teal, 36).Position = UDim2.fromOffset(0, 4)
    self.rank = label(profile, "RankTitle", 18)
    self.rank.Position, self.rank.Size = UDim2.fromOffset(46, 0), UDim2.new(1, -46, 0, 26)
    self.rank.TextTruncate = Enum.TextTruncate.AtEnd
    self.rank.TextWrapped = false
    self.nextRank = label(profile, "NextRank", 11, Theme.Teal)
    self.nextRank.Position, self.nextRank.Size = UDim2.fromOffset(46, 28), UDim2.new(1, -46, 0, 22)
    self.rankFill = bar(profile, 56)
    for index, id in Identity.TrackOrder do
        local item = Gui.make("Frame", profile, { Name = id, Position = UDim2.new((index - 1) / 3, 0, 0, 72),
            Size = UDim2.new(1 / 3, -8, 0, 72), BackgroundTransparency = 1 })
        Icons.make(item, ({ listener = "headphones", beatmaker = "pads", neighbour = "people" })[id], Theme.Teal, 22).Position = UDim2.fromOffset(0, 0)
        local title = label(item, "Skill", 11)
        title.Position, title.Size = UDim2.fromOffset(0, 25), UDim2.new(1, 0, 0, 22)
        title.Text = Identity.TrackLabels[id]
        title.TextWrapped, title.TextTruncate = false, Enum.TextTruncate.AtEnd
        local level = label(item, "Level", 11, Theme.Teal)
        level.Position, level.Size = UDim2.fromOffset(27, 0), UDim2.new(1, -27, 0, 22)
        self.skills[id] = { root = item, level = level, fill = bar(item, 56) }
    end
    local navigation = Gui.make("Frame", self.root, { Name = "ActivityFilters", Size = UDim2.new(1, 0, 0, 44),
        BackgroundTransparency = 1, LayoutOrder = 2 })
    for index, definition in { { "play", "PLAY", "pads" }, { "explore", "EXPLORE", "headphones" }, { "help", "HELP", "flower" } } do
        local id = definition[1]
        local button = Gui.button(navigation, definition[2], function()
            self.filter = id
            self:update(self.state)
        end)
        button.Name, button.Position, button.Size = id, UDim2.fromScale((index - 1) / 3, 0), UDim2.new(1 / 3, -4, 0, 44)
        button:SetAttribute("UiIcon", definition[3])
        self.filters[id] = button
    end
    self.summary = label(self.root, "ActivitySummary", 12, Theme.Teal)
    self.summary.Size, self.summary.LayoutOrder = UDim2.new(1, 0, 0, 24), 3
    self.list = stack(self.root, "ActivityRoutes", 4)
    local function add(id, category, title, detail, icon, route, completed, target)
        local entry = { id = id, category = category, title = title, detail = detail, route = route, completed = completed, target = target }
        local button = Gui.button(self.list, "", function()
            if self.state and self.state.ready and entry.available then entry.route() end
        end)
        button.Name, button.Size, button.LayoutOrder = id, UDim2.new(1, 0, 0, 76), #self.entries + 1
        button:SetAttribute("NoActionIcon", true)
        button.BackgroundColor3 = Theme.Paper
        button.FocusRing.Color = Theme.Teal
        Icons.make(button, icon, Theme.Teal, 32).Position = UDim2.fromOffset(10, 12)
        local heading = label(button, "Activity", 14)
        heading.Text, heading.Position, heading.Size = title, UDim2.fromOffset(54, 8), UDim2.new(1, -66, 0, 28)
        heading.TextTruncate, heading.TextWrapped = Enum.TextTruncate.AtEnd, false
        local note = label(button, "OneAction", 11, Theme.Walnut)
        note.Position, note.Size = UDim2.fromOffset(54, 38), UDim2.new(1, -106, 0, 30)
        local action = label(button, "RouteAction", 11, Theme.Teal)
        action.Position, action.Size = UDim2.new(1, -48, 0, 38), UDim2.fromOffset(38, 28)
        action.TextXAlignment = Enum.TextXAlignment.Right
        entry.root, entry.note, entry.action = button, note, action
        table.insert(self.entries, entry)
    end
    for _, id in Games.Order do
        local game = Games.ById[id]
        add(id, "play", game.title, ({ echo = "Listen, then copy", pulse = "Tap four beats", chase = "Catch the lit pad", lantern = "Stop on amber", targets = "Tap the raised target", bells = "Wait / catch the bell", rings = "Toss on the peg" })[id] or game.hint, game.icon,
            function() callbacks.game(id) end, function(s) return s.quay.progress.side[id] == true end, "activity_" .. id)
    end
    add("street_set", "play", "STREET SET", "Bring a loop or Song", "sound", function() callbacks.game("busk") end, nil, "activity_busk")
    add("make_music", "play", "YOUR ROAMER", "Make a beat or try Same Crate", "van", function()
        callbacks.place("enter", "YOUR ROAMER", "Open the instrument. Same Crate is in Crates > Options.")
    end, nil, "enter")
    for _, id in require(Shared.QuayInteriorCatalog).Order do
        local info = require(Shared.QuayInteriorCatalog).ById[id]
        add("room_" .. id, "play", info.title, "Enter / play a set / explore", "pads", function()
            callbacks.place("inside_" .. id, info.title, "Follow the doorway symbol. Enter to play or explore.")
        end, nil, "inside_" .. id)
    end
    add("fair_prizes", "play", "FAIR PRIZES", "Earn coins / choose a prize", "badge", function()
        callbacks.place("fair_prizes", "FAIR PRIZES", "Follow the prize symbol. Pick a prize with your earned coins.")
    end, nil, "fair_prizes")
    for _, row in Life.Stamps do
        add("postcard_" .. row.id, "explore", row.title, "Pause and listen", "headphones", function()
            callbacks.life("listen_" .. row.id, row.title, "Stay by the listening post to collect this sound postcard.")
        end, function(s) return s.quay.life.progress.stamps[row.id] == true end, "life_listen_" .. row.id)
    end
    add("pattern_bench", "explore", "PATTERN BENCH", "Three patterns / untimed", "logic", function()
        callbacks.place("building_NQ-BLD-03", "PATTERN BENCH", "At Morrow Repairs, open Explore and try Ivo's pattern bench.", "pattern_bench")
    end, function(s) return s.experience and s.experience.activities.pattern_bench.completed == true end, "building_NQ-BLD-03")
    add("sleeve_studio", "explore", "SLEEVE STUDIO", "Make a cover at Needle Records", "sleeve", function()
        callbacks.place("building_NQ-BLD-02", "SLEEVE STUDIO", "At Needle Records, open Explore to design and print a sleeve.", "sleeve_studio")
    end, function(s) return s.experience and s.experience.activities.sleeve_studio.completed == true end, "building_NQ-BLD-02")
    for _, row in Life.Gardens do
        add("garden_" .. row.id, "help", row.title, "Tend the planter", "flower", function()
            callbacks.life("garden_" .. row.id, row.title, "Interact with this planter to tend it.")
        end, function(s) return s.quay.life.progress.gardens[row.id] == true end, "life_garden_" .. row.id)
    end
    add("delivery", "help", "SLEEVES FOR TORI", "A delivery from Naya", "crate", function()
        local parcel = self.state.quay.life.progress.parcel
        callbacks.life(if parcel == 1 then "parcel_drop" else "parcel_pickup", "SLEEVES FOR TORI",
            if parcel == 1 then "Take Naya's sleeves to Tori's record box."
                elseif parcel == 2 then "Visit Naya. Your delivery is already complete." else "Collect the sleeves from Naya.")
    end, function(s) return s.quay.life.progress.parcel == 2 end,
        function(s) return if s.quay.life.progress.parcel == 1 then "life_parcel_drop" else "life_parcel_pickup" end)
    local links = Gui.make("Frame", self.root, { Name = "JournalShortcuts", Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1, LayoutOrder = 5 })
    for index, definition in { { "LIFE", "life", "journal" }, { "STYLE", "style", "headphones" }, { "FINDS", "explore", "discovery" } } do
        local b = Gui.button(links, definition[1], function() callbacks.tab(definition[2]) end)
        b.Position, b.Size = UDim2.fromScale((index - 1) / 3, 0), UDim2.new(1 / 3, -4, 0, 44)
        b:SetAttribute("UiIcon", definition[3])
    end
    self.storage = label(self.root, "ProgressStorage", 11, Theme.Walnut)
    self.storage.Size, self.storage.LayoutOrder = UDim2.new(1, 0, 0, 38), 6
    self.save = Gui.button(self.root, "SAVE JOURNAL", function() callbacks.save() end)
    self.save.Name, self.save.Size, self.save.LayoutOrder = "SaveActivityJournal", UDim2.new(1, 0, 0, 44), 7
    self.save:SetAttribute("UiIcon", "save")
    return self
end

function Board:update(state)
    self.state = state
    local q = state and state.quay
    local life = q and q.life
    if not life then return end
    if state.notice then self.notice.Text = state.notice end
    self.notice.Visible = self.notice.Text ~= ""
    self.rank.Text = life.title
    local nextRank = Life.Ranks[life.rank + 1]
    self.nextRank.Text = if nextRank then string.format("%d XP to %s", math.max(0, nextRank[1] - life.xp), nextRank[2]) else "HARBOR HEART / MAX RANK"
    self.rank:SetAttribute("AccessibleLabel", "Neighborhood rank " .. life.rank .. ": " .. life.title)
    self.rankFill.Size = UDim2.fromScale(if life.next then math.clamp((life.xp - life.floor) / math.max(1, life.next - life.floor), 0, 1) else 1, 1)
    local identity = state.experience and state.experience.identity
    for _, track in identity and identity.tracks or {} do
        local skill = self.skills[track.id]
        local floor = Identity.TrackLevels[track.level] or 0
        skill.level.Text = "LV " .. track.level
        skill.fill.Size = UDim2.fromScale(if track.nextAt then math.clamp((track.xp - floor) / math.max(1, track.nextAt - floor), 0, 1) else 1, 1)
        skill.root:SetAttribute("AccessibleLabel", track.label .. ": " .. track.levelLabel .. ", " .. track.xp .. " XP")
    end
    local complete = 0
    for id, control in self.filters do
        control.BackgroundColor3 = if id == self.filter then Theme.Ink else Theme.Teal
        control:SetAttribute("Selected", id == self.filter)
    end
    for _, entry in self.entries do
        local done = entry.completed and entry.completed(state) == true
        local target = if type(entry.target) == "function" then entry.target(state) else entry.target
        entry.available = state.ready == true and q.waypoints ~= nil and typeof(q.waypoints[target]) == "Vector3"
        entry.root.Active, entry.root.Interactable, entry.root.Selectable = entry.available, entry.available, entry.available
        entry.root.Visible = entry.category == self.filter
        if entry.root.Visible and done then complete += 1 end
        entry.note.Text = if not entry.available then "Route unavailable" elseif done then "KEPT / " .. entry.detail else entry.detail
        entry.action.Text = if not entry.available then "WAIT" elseif done then "VISIT" else "GO"
        entry.root:SetAttribute("AccessibleLabel", entry.title .. " / " .. entry.note.Text .. " / show route")
        entry.root:SetAttribute("Completed", done == true)
    end
    self.summary.Text = ({ play = "TRY SOMETHING", explore = "TAKE THE LONG WAY", help = "A SMALL FAVOR" })[self.filter]
        .. (if complete > 0 then " / " .. complete .. " KEPT" else " / YOUR CHOICE")
    self.storage.Text = if state.saving then "SAVING…" elseif state.saveMode == "session" then "Progress: Studio session only. First discoveries count once."
        elseif state.saveMode == "unavailable" then "Storage unavailable / progress is temporary."
        elseif state.dirty then "Unsaved changes / Save before leaving." else "First discoveries count once. Music is always open."
    local canSave = state.ready and not state.saving and state.saveMode ~= "unavailable"
    self.save.Active, self.save.Interactable, self.save.Selectable = canSave, canSave, canSave
    self.save.Text = if state.saving then "SAVING…" elseif state.saveMode == "unavailable" then "SAVE UNAVAILABLE"
        elseif state.saveMode == "session" then "SAVE / STUDIO SESSION" else "SAVE JOURNAL"
end

return Board
