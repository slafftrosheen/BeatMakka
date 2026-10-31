local Shared = game.ReplicatedStorage.Shared
local Catalog = require(Shared.CompanionCatalog)
local Theme = require(Shared.Theme)
local Gui = require(script.Parent.GuiFactory)
local Portrait = require(script.Parent.CompanionPortrait)
local View = {}
View.__index = View
function View.new(parent, send)
    local self = setmetatable({ buttons = {} }, View)
    self.root = Gui.round(
        Gui.make("Frame", parent, {
            Name = "Companions",
            LayoutOrder = 1,
            Size = UDim2.new(1, -10, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = Theme.Ink,
            BorderSizePixel = 0,
            Visible = false,
        }),
        12
    )
    Gui.make("UIPadding", self.root, {
        PaddingTop = UDim.new(0, 14),
        PaddingBottom = UDim.new(0, 14),
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
    })
    Gui.make(
        "UIListLayout",
        self.root,
        { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }
    )
    local function label(text, order, size, color)
        local value = Gui.label(self.root, text, size or 15, color or Theme.Cream)
        value.Size, value.AutomaticSize, value.LayoutOrder =
            UDim2.fromScale(1, 0), Enum.AutomaticSize.Y, order
        return value
    end
    label("HEAR IT. BUILD IT. MAKE IT YOURS.", 1, 18, Theme.Amber)
    label(
        "Choose a walking companion, or explore Alone. The music and every solo activity are always yours.",
        2
    )
    local row = Gui.make("Frame", self.root, {
        Name = "Choices",
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundTransparency = 1,
        LayoutOrder = 3,
    })
    for i, id in Catalog.Order do
        local b = Gui.button(row, Catalog.ById[id].name, function()
            send("CompanionSelect", id)
        end)
        b.Name = id
        b.Position = UDim2.fromScale((i - 1) / 3, 0)
        b.Size = UDim2.new(1 / 3, -4, 1, 0)
        self.buttons[id] = b
    end
    local card = Gui.round(
        Gui.make("Frame", self.root, {
            Name = "CharacterCard",
            Size = UDim2.new(1, 0, 0, 176),
            BackgroundColor3 = Theme.Cream,
            BorderSizePixel = 0,
            LayoutOrder = 4,
        }),
        12
    )
    self.card = card
    self.portrait = Portrait.new(card)
    self.role = Gui.label(card, "Alone / Your own pace", 18, Theme.Ink)
    self.role.Font = Theme.Bold
    self.role.Position, self.role.Size = UDim2.fromOffset(162, 12), UDim2.new(1, -172, 0, 54)
    self.description = Gui.label(card, "", 15, Theme.Ink)
    self.description.Position, self.description.Size =
        UDim2.fromOffset(162, 68), UDim2.new(1, -172, 0, 98)
    self.hints = Gui.button(self.root, "Hints ON", function()
        if self.state then
            send("CompanionHints", not self.state.hints)
        end
    end)
    self.hints.Name = "CompanionHints"
    self.hints.Size = UDim2.new(1, 0, 0, 44)
    self.hints.LayoutOrder = 6
    self.hint = label("", 7, 17)
    self.more = Gui.button(self.root, "A more specific hint", function()
        send("CompanionHint")
    end)
    self.more.Name = "MoreHint"
    self.more.Size = UDim2.new(1, 0, 0, 44)
    self.more.LayoutOrder = 8
    self.notebookTitle = label("", 9, 19, Theme.Amber)
    self.notebookCaption = label("", 10, 14)
    local pages = Gui.make("Frame", self.root, {
        Name = "NotebookPages",
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundTransparency = 1,
        LayoutOrder = 11,
    })
    self.pages, self.pageButtons = pages, {}
    for index = 1, 3 do
        local button = Gui.button(pages, "Page " .. index, function()
            self.page = index
            self:renderNotebook()
        end)
        button.Name = "NotebookPage" .. index
        button.Position, button.Size =
            UDim2.fromScale((index - 1) / 3, 0), UDim2.new(1 / 3, -4, 1, 0)
        self.pageButtons[index] = button
    end
    self.pageStatus = label("", 12, 13, Theme.Amber)
    self.pageText = label("", 13, 16)
    self.conversation = Gui.button(self.root, "Talk about this place", function()
        self.line = if self.line == 1 then 2 else 1
        self:renderNotebook()
    end)
    self.conversation.Name = "CompanionConversation"
    self.conversation.Size, self.conversation.LayoutOrder = UDim2.new(1, 0, 0, 44), 14
    self.story = label("", 15, 16)
    self.saving = label("", 16, 13, Theme.FadedTeal)
    label(
        "Alissia listens first; Nikolas experiments first. Neither changes your beat, collects a sound or completes an activity for you.",
        17,
        13
    )
    self.cardResize = card:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        self:layoutCard()
    end)
    self:layoutCard()
    return self
end
function View:layoutCard()
    local hasPortrait = self.selected ~= nil and self.selected ~= "none"
    local compact = hasPortrait and self.card.AbsoluteSize.X < 420
    local x = if hasPortrait and not compact then 162 else 14
    self.card.Size = UDim2.new(1, 0, 0, if compact then 326 else 176)
    self.portrait.frame.Position = if compact
        then UDim2.new(0.5, -72, 0, 8)
        else UDim2.fromOffset(6, 6)
    self.role.Position = UDim2.fromOffset(x, if compact then 180 else 12)
    self.role.Size = UDim2.new(1, -x - 14, 0, 54)
    self.description.Position = UDim2.fromOffset(x, if compact then 238 else 68)
    self.description.Size = UDim2.new(1, -x - 14, 0, if compact then 78 else 98)
end
function View:renderNotebook()
    local journal = self.state and self.state.journal
    local visible = journal ~= nil and self.selected ~= "none"
    for _, object in
        {
            self.notebookTitle,
            self.notebookCaption,
            self.pages,
            self.pageStatus,
            self.pageText,
            self.conversation,
        }
    do
        object.Visible = visible
    end
    self.story.Visible = visible and self.line ~= nil
    if not visible then
        return
    end
    self.notebookTitle.Text = journal.title .. " / " .. journal.count .. " of " .. journal.total
    self.notebookCaption.Text = journal.caption
    local pageIndex = self.page or 1
    for index, button in self.pageButtons do
        local page = journal.pages[index]
        button.Text = page.title .. (if page.available then " / noted" else "")
        button.BackgroundColor3 = if pageIndex == index then Theme.Amber else Theme.Teal
        button.TextColor3 = if pageIndex == index then Theme.Ink else Theme.Cream
    end
    local page = journal.pages[pageIndex]
    self.pageStatus.Text = page.status .. " / " .. page.place
    self.pageText.Text = page.text
    self.conversation.Text = if self.line
        then "Keep talking / " .. journal.story.title
        else "Talk / " .. journal.story.title
    self.story.Text = if self.line
        then Catalog.ById[self.selected].name .. ": " .. journal.story.lines[self.line]
        else ""
end
function View:setVisible(visible)
    self.portrait:set(self.selected or "none", visible)
end
function View:destroy()
    self.cardResize:Disconnect()
    self.portrait:destroy()
end
function View:update(snapshot, ready, saving)
    self.state = snapshot
    local selected = if snapshot and Catalog.valid(snapshot.selected)
        then snapshot.selected
        else "none"
    local story = snapshot and snapshot.journal and snapshot.journal.story
    local context = story and story.context
    if selected ~= self.selected or context ~= self.storyContext then
        self.page, self.line = 1, nil
    end
    self.selected, self.storyContext = selected, context
    for id, b in self.buttons do
        b.Active, b.Interactable = ready == true, ready == true
        b.Text = Catalog.ById[id].name .. (if id == selected then " / selected" else "")
        b.BackgroundColor3 = if id == selected then Theme.Amber else Theme.Teal
        b.TextColor3 = if id == selected then Theme.Ink else Theme.Cream
        b.FocusRing.Color = if id == selected then Theme.Ink else Theme.Amber
    end
    local definition = Catalog.ById[selected]
    self.role.Text = definition.name .. " / " .. definition.role
    self.description.Text = definition.description
    self:layoutCard()
    self:renderNotebook()
    self.hints.Visible = selected ~= "none"
    self.hints.Active, self.hints.Interactable = ready == true, ready == true
    self.hints.Text = if snapshot and snapshot.hints
        then "Hints ON / hide hints"
        else "Hints OFF / show hints"
    local hint = snapshot and snapshot.hint
    self.hint.Visible = hint ~= nil
    self.hint.Text = if hint then hint.text else ""
    self.more.Visible = hint ~= nil
    self.more.Active = hint ~= nil and hint.level < hint.maxLevel
    self.more.Interactable = self.more.Active
    self.more.Text = if hint and hint.level >= hint.maxLevel
        then "That is the most specific hint"
        else "A more specific hint"
    self.saving.Text = if not ready
        then "Loading your profile..."
        elseif saving then "Saving your choice with your music..."
        elseif
            snapshot and snapshot.saveMode == "session"
        then "Choice and music save for this Studio Play session only."
        elseif
            snapshot and snapshot.saveMode == "unavailable"
        then "Temporary choice: cloud saving is unavailable."
        else "Your choice saves with your music and progress."
end
return View
