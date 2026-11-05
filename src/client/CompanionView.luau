local Shared = game.ReplicatedStorage.Shared
local Catalog = require(Shared.CompanionCatalog)
local Theme = require(Shared.Theme)
local Gui = require(script.Parent.GuiFactory)
local Portrait = require(script.Parent.CompanionPortrait)
local Icons = require(script.Parent.GameIcons)
local VisualSteps = require(script.Parent.VisualSteps)
local View = {}
View.__index = View
local function enable(button, value)
    button.Active, button.Interactable, button.Selectable = value == true, value == true, value == true
end
function View.new(parent, send)
    local self = setmetatable({ buttons = {}, section = "guide", topicButtons = {}, tabs = {}, pageButtons = {} }, View)
    self.root = Gui.make("Frame", parent, { Name = "Companions", LayoutOrder = 1,
        Size = UDim2.new(1, -10, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.Ink, BorderSizePixel = 0, Visible = false })
    Gui.round(self.root, 12)
    Gui.make("UIPadding", self.root, { PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) })
    Gui.make("UIListLayout", self.root, { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder })
    local function label(text, order, size, color)
        local l = Gui.label(self.root, text, size or 14, color or Theme.Cream)
        l.Size, l.AutomaticSize, l.LayoutOrder = UDim2.new(1, 0, 0, 0), Enum.AutomaticSize.Y, order
        return l
    end
    local function row(name, order, height)
        return Gui.make("Frame", self.root, { Name = name, Size = UDim2.new(1, 0, 0, height),
            BackgroundTransparency = 1, LayoutOrder = order })
    end
    local function button(parentFrame, name, text, order, callback, icon)
        local b = Gui.button(parentFrame, text, callback)
        b.Name, b.Size, b.LayoutOrder = name, UDim2.new(1, 0, 0, 44), order
        b.FocusRing.Color = Theme.Amber
        if icon then b:SetAttribute("UiIcon", icon) end
        return b
    end
    label("WALK TOGETHER", 1, 19, Theme.Amber).Font = Enum.Font.Code
    local choices = row("Choices", 2, 76)
    for index, id in Catalog.Order do
        local b = button(choices, id, string.upper(Catalog.ById[id].name), index, function() send("CompanionSelect", id) end)
        b.Position, b.Size = UDim2.fromScale((index - 1) / 3, 0), UDim2.new(1 / 3, -4, 1, 0)
        b.TextSize, b.TextYAlignment = 12, Enum.TextYAlignment.Bottom
        b:SetAttribute("NoActionIcon", true)
        Gui.make("UIPadding", b, { PaddingBottom = UDim.new(0, 8) })
        local glyph = Icons.make(b, if id == "none" then "route" else "people", Theme.Amber, 28)
        glyph.Position, glyph.ZIndex = UDim2.new(0.5, -14, 0, 10), 3
        self.buttons[id] = b
    end
    self.card = row("CharacterCard", 3, 130)
    self.card.BackgroundTransparency, self.card.BackgroundColor3 = 0, Theme.Cream
    Gui.round(self.card, 10)
    self.portrait = Portrait.new(self.card)
    self.portrait.frame.Position, self.portrait.frame.Size = UDim2.fromOffset(6, 6), UDim2.fromOffset(100, 114)
    self.role = Gui.label(self.card, "", 15, Theme.Ink)
    self.role.Font = Enum.Font.Code
    self.role.Position, self.role.Size = UDim2.fromOffset(116, 8), UDim2.new(1, -128, 1, -16)
    self.navigation = row("CompanionSections", 4, 44)
    for index, definition in { { "guide", "GUIDE", "hint" }, { "notes", "NOTES", "journal" }, { "chat", "CHAT", "people" } } do
        local section = definition[1]
        local b = button(self.navigation, section, definition[2], index, function()
            self.section = section
            self:render()
        end, definition[3])
        b.Position, b.Size = UDim2.fromScale((index - 1) / 3, 0), UDim2.new(1 / 3, -4, 0, 44)
        self.tabs[section] = b
    end
    self.hints = button(self.root, "CompanionHints", "HINTS ON", 5, function()
        if self.state then send("CompanionHints", not self.state.hints) end
    end, "hint")
    self.hints.LayoutOrder = 7
    self.topics = row("GuidanceTopics", 8, 96)
    self.topicGrid = Gui.make("UIGridLayout", self.topics, { CellSize = UDim2.new(1 / 3, -4, 0, 44),
        CellPadding = UDim2.fromOffset(4, 4), SortOrder = Enum.SortOrder.LayoutOrder })
    local captions = { auto = "NOW", hunt = "HUNT", sequence = "LOOP", draft = "DRAFT", finished = "SONG", route = "ROUTE" }
    local glyphs = { auto = "hint", hunt = "discovery", sequence = "steps", draft = "sleeve", finished = "disc", route = "route" }
    for index, topic in Catalog.HintTopics do
        self.topicButtons[topic] = button(self.topics, topic, captions[topic], index, function()
            self.detailsOpen = false
            send("CompanionTopic", topic)
        end, glyphs[topic])
        self.topicButtons[topic]:SetAttribute("AccessibleLabel", Catalog.HintLabels[topic])
    end
    self.steps = VisualSteps.new(self.root, { { "SOUND", "pads" }, { "MAKE", "steps" }, { "KEEP", "save" } })
    self.steps.root.LayoutOrder = 5
    self.hint = label("", 6, 16, Theme.Cream)
    self.hint.Font = Enum.Font.Code
    self.detailToggle = button(self.root, "HintDetails", "FULL HINT", 9, function()
        self.detailsOpen = not self.detailsOpen
        self:render()
    end, "hint")
    self.fullHint, self.workspace = label("", 10), label("", 11, 12, Theme.Cream)
    self.more = button(self.root, "MoreHint", "NEXT HINT", 12, function()
        self.detailsOpen = true
        self:render()
        send("CompanionHint")
    end, "hint")
    self.notebookTitle, self.notebookCaption = label("", 13, 18, Theme.Amber), label("", 14)
    self.pages = row("NotebookPages", 15, 76)
    for index = 1, 3 do
        local b = button(self.pages, "NotebookPage" .. index, "", index, function()
            self.page = index
            self:renderNotebook()
        end)
        b.Position, b.Size = UDim2.fromScale((index - 1) / 3, 0), UDim2.new(1 / 3, -4, 1, 0)
        b.TextSize, b.TextYAlignment = 11, Enum.TextYAlignment.Bottom
        b:SetAttribute("NoActionIcon", true)
        Gui.make("UIPadding", b, { PaddingBottom = UDim.new(0, 6) })
        local glyph = Icons.make(b, "journal", Theme.Amber, 24)
        glyph.Position, glyph.ZIndex = UDim2.new(0.5, -12, 0, 8), 3
        self.pageButtons[index] = b
    end
    self.pageStatus, self.pageText = label("", 16, 12, Theme.Amber), label("", 17, 15)
    self.conversation = button(self.root, "CompanionConversation", "TALK", 18, function()
        self.line = if self.line == 2 then 1 else 2
        self:renderNotebook()
    end, "people")
    self.story = label("", 19, 15)
    self.saving = label("", 20, 12, Theme.Cream)
    self.details = button(self.root, "CompanionDetails", "ABOUT", 21, function()
        self.aboutOpen = not self.aboutOpen
        self:render()
    end, "people")
    self.description = label("", 22, 14)
    self.cardResize = self.card:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        self:layoutCard()
        local columns = if self.card.AbsoluteSize.X < 260 then 2 else 3
        self.topicGrid.CellSize = UDim2.new(1 / columns, -4, 0, 44)
        self.topics.Size = UDim2.new(1, 0, 0, math.ceil(#Catalog.HintTopics / columns) * 48)
    end)
    return self
end

function View:layoutCard()
    local hasPortrait = self.selected ~= nil and self.selected ~= "none"
    local narrow = hasPortrait and self.card.AbsoluteSize.X < 300
    self.card.Size = UDim2.new(1, 0, 0, if not hasPortrait then 84 elseif narrow then 184 else 130)
    self.portrait.frame.Position = if narrow then UDim2.new(0.5, -44, 0, 6) else UDim2.fromOffset(6, 6)
    self.portrait.frame.Size = if narrow then UDim2.fromOffset(88, 100) else UDim2.fromOffset(100, 114)
    self.role.Position = if narrow then UDim2.fromOffset(12, 114) else UDim2.fromOffset(if hasPortrait then 116 else 14, 8)
    self.role.Size = if narrow then UDim2.new(1, -24, 0, 56) else UDim2.new(1, if hasPortrait then -128 else -28, 1, -16)
    self.role.TextXAlignment = if narrow then Enum.TextXAlignment.Center else Enum.TextXAlignment.Left
end

function View:renderNotebook()
    local journal = self.state and self.state.journal
    local notes = journal ~= nil and self.selected ~= "none" and self.section == "notes"
    for _, object in { self.notebookTitle, self.notebookCaption, self.pages, self.pageStatus, self.pageText } do object.Visible = notes end
    local chat = journal ~= nil and self.selected ~= "none" and self.section == "chat"
    self.conversation.Visible, self.story.Visible = chat, chat
    if not journal then return end
    self.notebookTitle.Text = journal.title .. " / " .. journal.count .. "/" .. journal.total
    self.notebookCaption.Text = journal.caption
    local pageIndex = self.page or 1
    for index, b in self.pageButtons do
        local page = journal.pages[index]
        b.Text = string.upper(page.title)
        b.BackgroundColor3 = if index == pageIndex then Theme.Ink else Theme.Teal
        b:SetAttribute("Selected", index == pageIndex)
    end
    local page = journal.pages[pageIndex]
    self.pageStatus.Text, self.pageText.Text = page.status .. " / " .. page.place, page.text
    self.conversation.Text = if self.line then "KEEP TALKING" else "TALK / " .. journal.story.title
    self.story.Text = Catalog.ById[self.selected].name .. ": " .. journal.story.lines[self.line or 1]
end

function View:render()
    local snapshot, selected = self.state, self.selected or "none"
    local hint = snapshot and snapshot.hint
    local guide = selected ~= "none" and self.section == "guide"
    self.navigation.Visible = selected ~= "none"
    for name, b in self.tabs do
        b.BackgroundColor3 = if name == self.section then Theme.Ink else Theme.Teal
        b:SetAttribute("Selected", name == self.section)
    end
    self.hints.Visible, self.topics.Visible = guide, guide
    self.hints.Text = if snapshot and snapshot.hints then "HINTS ON" else "HINTS OFF"
    local visual = hint and hint.visual
    self.steps.root.Visible, self.hint.Visible = guide and visual ~= nil, guide
    if visual then self.steps:configure(visual.steps); self.steps:update(visual.current) end
    self.hint.Text = if visual then visual.cue .. "\n" .. visual.detail elseif hint then hint.text else "Hints are off. Explore at your own pace."
    self.detailToggle.Visible = guide and hint ~= nil
    self.detailToggle.Text = if self.detailsOpen then "LESS" else "FULL HINT"
    self.fullHint.Visible, self.workspace.Visible = guide and hint ~= nil and self.detailsOpen == true, guide and hint ~= nil and self.detailsOpen == true
    self.fullHint.Text, self.workspace.Text = if hint then hint.text else "", if hint then hint.workspace or "" else ""
    self.more.Visible = guide and hint ~= nil and self.detailsOpen == true
    self.more.Text = if hint and hint.level >= hint.maxLevel then "ALL HINTS SHOWN" else "NEXT HINT"
    enable(self.more, self.ready and hint ~= nil and hint.level < hint.maxLevel)
    for topic, b in self.topicButtons do
        local selectedTopic = snapshot and snapshot.topic or "auto"
        b.BackgroundColor3 = if topic == selectedTopic then Theme.Ink else Theme.Teal
        b:SetAttribute("Selected", topic == selectedTopic)
    end
    self.description.Visible = self.aboutOpen == true
    self.details.Text = if self.aboutOpen then "LESS ABOUT" else "ABOUT"
    self:renderNotebook()
end

function View:setVisible(visible)
    self.portrait:set(self.selected or "none", visible)
end
function View:destroy()
    self.cardResize:Disconnect()
    self.portrait:destroy()
end
function View:update(snapshot, ready, saving)
    self.state, self.ready = snapshot, ready == true
    local selected = if snapshot and Catalog.valid(snapshot.selected) then snapshot.selected else "none"
    local context = snapshot and snapshot.journal and snapshot.journal.story.context
    if selected ~= self.selected or context ~= self.storyContext then self.page, self.line, self.detailsOpen = 1, nil, false end
    self.selected, self.storyContext = selected, context
    for id, b in self.buttons do
        enable(b, ready)
        b.BackgroundColor3 = if id == selected then Theme.Ink else Theme.Teal
        b:SetAttribute("Selected", id == selected)
        b:SetAttribute("AccessibleLabel", Catalog.ById[id].name .. (if id == selected then " / selected" else ""))
    end
    for _, b in self.tabs do enable(b, ready) end
    for _, b in self.topicButtons do enable(b, ready) end
    enable(self.hints, ready)
    local definition = Catalog.ById[selected]
    self.role.Text = definition.name .. "\n" .. definition.role
    self:layoutCard()
    self.description.Text = definition.description .. "\nAlone and every solo activity stay available. Companions never edit or complete tasks for you."
    local visual = snapshot and snapshot.hint and snapshot.hint.visual
    self.saving.Text = if not ready then "LOADING" elseif saving then "SAVING CHOICE"
        elseif snapshot and snapshot.saveMode == "session" then "CHOICE / STUDIO SESSION ONLY"
        elseif snapshot and snapshot.saveMode == "unavailable" then "TEMPORARY CHOICE / NO STORAGE"
        else "Choice saves with your music."
    if visual and visual.storage == "UNSAVED" then self.saving.Text ..= " / UNSAVED" end
    self:render()
end
return View
