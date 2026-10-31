-- Fixed LCD library. Every visual and hit target is constructed once; updates
-- only rebind six reusable cards and their native labels.
local RawGui = require(script.Parent.GuiFactory)
local Skin = require(script.Parent.DeviceSkin)
local Icons = require(script.Parent.GameIcons)
local Theme = require(game.ReplicatedStorage.Shared.Theme)
local Library = {}
Library.__index = Library

local Ink = Color3.fromRGB(175, 209, 157)
local Dim = Color3.fromRGB(112, 145, 118)
local Edge = Color3.fromRGB(61, 87, 70)
local Selected = Color3.fromRGB(39, 62, 43)
local Amber = Theme.Amber
local function frame(parent, name, properties)
    local object = RawGui.make("Frame", parent, {
        Name = name,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    })
    for key, value in properties or {} do
        object[key] = value
    end
    return object
end
local function text(parent, name, caption, size, color)
    return RawGui.make("TextLabel", parent, {
        Name = name,
        Text = caption,
        Font = Enum.Font.Code,
        TextSize = size or 12,
        TextColor3 = color or Ink,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 3,
    })
end
local function button(self, parent, name, caption, callback, iconName)
    local object = RawGui.make("TextButton", parent, {
        Name = name,
        Text = caption,
        Font = Enum.Font.Code,
        TextSize = 12,
        TextColor3 = Ink,
        BackgroundColor3 = Theme.Screen,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Selectable = true,
        Active = true,
        ZIndex = 3,
    })
    local stroke = RawGui.make("UIStroke", object, {
        Color = Edge,
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
    local focus = RawGui.make("UIStroke", object, {
        Name = "KeyboardFocus",
        Color = Amber,
        Thickness = 2,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Enabled = false,
    })
    table.insert(
        self.connections,
        object.SelectionGained:Connect(function()
            focus.Enabled = true
        end)
    )
    table.insert(
        self.connections,
        object.SelectionLost:Connect(function()
            focus.Enabled = false
        end)
    )
    table.insert(
        self.connections,
        object.Activated:Connect(function()
            if object.Active then
                callback()
            end
        end)
    )
    local icon
    if iconName then
        icon = Icons.make(object, iconName, Ink, 17)
        icon.Position = UDim2.new(0, 8, 0.5, -8)
        icon.ZIndex = 4
        for _, child in icon:GetDescendants() do
            if child:IsA("GuiObject") then
                child.ZIndex = 4
            end
        end
    end
    return { root = object, stroke = stroke, icon = icon }
end
local function tint(control, enabled, selected)
    control.root.Active = enabled
    control.root.Selectable = enabled
    control.root.TextColor3 = if selected then Amber elseif enabled then Ink else Dim
    control.root.BackgroundColor3 = if selected then Selected else Theme.Screen
    control.stroke.Color = if selected then Amber else Edge
    if control.icon then
        for _, child in control.icon:GetDescendants() do
            if child:IsA("Frame") then
                child.BackgroundColor3 = control.root.TextColor3
            elseif child:IsA("UIStroke") then
                child.Color = control.root.TextColor3
            end
        end
    end
end
local function seconds(value)
    value = math.max(0, math.floor(tonumber(value) or 0))
    return string.format("%d:%02d", math.floor(value / 60), value % 60)
end

function Library.new(parent, callbacks)
    local self = setmetatable({
        callbacks = callbacks,
        connections = {},
        section = "Sections",
        pageIndex = 1,
        pageSize = 6,
        selectedIds = {},
        cards = {},
        tabs = {},
        entries = {},
    }, Library)
    self.rootFrame = frame(parent, "DeviceLibraryScreen", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 0,
        BackgroundColor3 = Theme.Screen,
        ClipsDescendants = true,
    })
    self.header = frame(self.rootFrame, "LibrarySegments")
    for index, spec in
        {
            { "Sections", "SECTIONS", "steps" },
            { "Drafts", "DRAFTS", "sleeve" },
            { "Finished", "FINISHED", "disc" },
        }
    do
        local section = spec[1]
        local tab = button(self, self.header, section, spec[2], function()
            self.section, self.pageIndex, self.publicHint = section, 1, false
            self.popup.Visible = false
            self:_render()
        end, spec[3])
        tab.root.SelectionOrder = index
        self.tabs[section] = tab
    end
    self.options = button(self, self.header, "Options", "...", function()
        self.popup.Visible = not self.popup.Visible
    end)
    self.options.root.TextSize = 20
    self.options.root.SelectionOrder = 4
    self.body = frame(self.rootFrame, "SleeveCards")
    self.empty = text(self.body, "EmptyLibrary", "", 12, Dim)
    self.empty.Size = UDim2.fromScale(1, 1)
    self.empty.TextWrapped = true
    self.empty.TextXAlignment = Enum.TextXAlignment.Center
    self.empty.TextTruncate = Enum.TextTruncate.None
    for index = 1, 6 do
        local card = button(self, self.body, "SleeveCard" .. index, "", function()
            self:_choose(index)
        end)
        card.root.SelectionOrder = index + 4
        card.art = frame(card.root, "VinylSleeve", {
            BackgroundTransparency = 0,
            BackgroundColor3 = Color3.fromRGB(121, 133, 93),
            ClipsDescendants = true,
            ZIndex = 4,
        })
        local disc = frame(card.art, "NativeVinylFallback", {
            Position = UDim2.fromScale(0.14, 0.14),
            Size = UDim2.fromScale(0.72, 0.72),
            BackgroundTransparency = 0,
            BackgroundColor3 = Theme.Ink,
            ZIndex = 4,
        })
        RawGui.make("UICorner", disc, { CornerRadius = UDim.new(1, 0) })
        RawGui.make("UIStroke", disc, { Color = Edge, Thickness = 2 })
        local center = frame(disc, "VinylLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromScale(0.27, 0.27),
            BackgroundTransparency = 0,
            BackgroundColor3 = Amber,
            ZIndex = 5,
        })
        RawGui.make("UICorner", center, { CornerRadius = UDim.new(1, 0) })
        card.image = Skin.image(card.art, "sleeve-v4", {
            Name = "SleeveArtwork",
            ScaleType = Enum.ScaleType.Fit,
            ZIndex = 6,
        })
        card.number = text(card.root, "SourceCode", "", 11, Dim)
        card.title = text(card.root, "SourceTitle", "", 12, Ink)
        card.detail = text(card.root, "SourceLength", "", 11, Dim)
        card.saved = frame(card.root, "SavedLight", {
            Size = UDim2.fromOffset(5, 5),
            BackgroundTransparency = 0,
            BackgroundColor3 = Dim,
            ZIndex = 5,
        })
        RawGui.make("UICorner", card.saved, { CornerRadius = UDim.new(1, 0) })
        self.cards[index] = card
    end
    self.footer = frame(self.rootFrame, "LibraryFooter")
    self.previous = button(self, self.footer, "PreviousPage", "<", function()
        self.pageIndex = math.max(1, self.pageIndex - 1)
        self:_render()
    end)
    self.next = button(self, self.footer, "NextPage", ">", function()
        self.pageIndex = math.min(self.pageCount, self.pageIndex + 1)
        self:_render()
    end)
    self.pageLabel = text(self.footer, "PageCount", "1 / 1", 11, Dim)
    self.pageLabel.TextXAlignment = Enum.TextXAlignment.Center
    self.play = button(self, self.footer, "PlaySelection", "PLAY", function()
        self:_play()
    end, "play")
    self.public = button(self, self.footer, "PublicSelection", "PUBLIC", function()
        local item = self:_selected()
        if not item then
            return
        end
        self.callbacks.command("ListeningSelect", {
            kind = if self.section == "Finished" then "finished" else "sequence",
            id = item.id,
            revision = item.revision,
        })
        self.callbacks.command("QuayStage")
        self.publicHint = true
        self:_render()
    end, "people")
    self.hint = text(self.rootFrame, "LibraryHint", "", 11, Dim)
    self.popup = frame(self.rootFrame, "LibraryOptions", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        BackgroundTransparency = 0,
        BackgroundColor3 = Theme.Screen,
        Active = true,
        Visible = false,
        ZIndex = 20,
    })
    RawGui.make("UIStroke", self.popup, { Color = Amber, Thickness = 1 })
    local heading = text(self.popup, "OptionsHeading", "LIBRARY / OPTIONS", 12, Amber)
    heading.Position, heading.Size, heading.ZIndex =
        UDim2.fromOffset(14, 8), UDim2.new(1, -28, 0, 24), 22
    self.copy = button(self, self.popup, "OpenEditableCopy", "OPEN EDITABLE COPY", function()
        local item = self:_selected()
        if item and self.section == "Finished" then
            self.callbacks.command("FinishedOpen", item.id)
            self.popup.Visible = false
            self.callbacks.page("Song")
        end
    end, "pencil")
    self.imports = button(self, self.popup, "LegacyImports", "LEGACY IMPORTS", function()
        self.section, self.pageIndex, self.publicHint = "Archives", 1, false
        self.popup.Visible = false
        self:_render()
    end, "library")
    self.recovery = button(self, self.popup, "RecoveryProject", "OPEN RECOVERY PROJECT", function()
        self.callbacks.command("RecoveryOpen")
        self.popup.Visible = false
        self.callbacks.page("Sequence")
    end, "undo")
    self.closeOptions = button(self, self.popup, "CloseOptions", "CLOSE", function()
        self.popup.Visible = false
    end, "close")
    for index, control in { self.copy, self.imports, self.recovery, self.closeOptions } do
        control.root.Position = UDim2.fromOffset(12, 38 + (index - 1) * 38)
        control.root.Size = UDim2.new(1, -24, 0, 32)
        control.root.ZIndex = 22
        control.root.SelectionOrder = index + 20
        if control.icon then
            control.icon.ZIndex = 23
            for _, child in control.icon:GetDescendants() do
                if child:IsA("GuiObject") then
                    child.ZIndex = 23
                end
            end
        end
    end
    self:resize(parent.AbsoluteSize.X, parent.AbsoluteSize.Y)
    self:_render()
    return self
end

function Library:_selected()
    local id = self.selectedIds[self.section]
    for _, item in self.entries do
        if item.id == id then
            return item
        end
    end
    return nil
end
function Library:_choose(index)
    local item = self.cards[index].entry
    if not item then
        return
    end
    self.selectedIds[self.section] = item.id
    self.publicHint = false
    if self.section == "Sections" then
        self.callbacks.command("SequenceSelect", item.id)
        self.callbacks.page("Sequence")
    elseif self.section == "Drafts" then
        self.callbacks.command("SongSelect", item.id)
        self.callbacks.page("Song")
    elseif self.section == "Finished" then
        self.callbacks.command("FinishedSelect", item.id)
    else
        self.callbacks.command("ArchiveOpen", item.id)
        if item.readOnly == false then
            self.callbacks.page("Sequence")
        end
    end
    self:_render()
end
function Library:_play()
    local item = self:_selected()
    if not item then
        return
    end
    if self.section == "Finished" then
        self.callbacks.command("FinishedSelect", item.id)
        self.callbacks.command("FinishedPlay")
    elseif self.section == "Drafts" then
        self.callbacks.command("SongSelect", item.id)
        self.callbacks.command("SongPlay")
    elseif self.section == "Sections" then
        self.callbacks.command("SequenceSelect", item.id)
        self.callbacks.command("PlayStart")
    else
        self.callbacks.command("ArchiveOpen", item.id)
    end
end

function Library:_render()
    local m = self.music or {}
    local summary = m.library or {}
    self.entries = if self.section == "Sections"
        then summary.sequences or {}
        elseif self.section == "Drafts" then summary.drafts or {}
        elseif self.section == "Finished" then m.finishedSongs or {}
        else m.archives or {}
    self.pageCount = math.max(1, math.ceil(#self.entries / self.pageSize))
    self.pageIndex = math.clamp(self.pageIndex, 1, self.pageCount)
    for section, tab in self.tabs do
        tint(tab, true, self.section == section)
    end
    tint(self.options, true, self.section == "Archives")
    local selected = self:_selected()
    if not selected and self.entries[1] then
        self.selectedIds[self.section] = self.entries[1].id
        selected = self.entries[1]
    end
    for index, card in self.cards do
        local item = if index <= self.pageSize
            then self.entries[(self.pageIndex - 1) * self.pageSize + index]
            else nil
        card.entry = item
        card.root.Visible = item ~= nil
        tint(card, item ~= nil, item ~= nil and selected ~= nil and item.id == selected.id)
        if item then
            local title = item.title or item.name or "Untitled"
            local saved = self.section == "Finished"
                or (item.revision ~= nil and item.savedRevision == item.revision)
            card.title.Text = title
            card.title:SetAttribute("FullTitle", title)
            card.root:SetAttribute("SourceId", item.id)
            card.number.Text = string.format(
                "%s %02d",
                if self.section == "Sections"
                    then "SEQ"
                    elseif self.section == "Drafts" then "DRAFT"
                    elseif self.section == "Finished" then "SONG"
                    else "IMPORT",
                (self.pageIndex - 1) * self.pageSize + index
            )
            card.detail.Text = if self.section == "Sections"
                then string.format("%d BARS / %d BPM", item.bars or 0, item.bpm or 96)
                elseif self.section == "Drafts" then string.format(
                    "%d BARS / %s",
                    item.totalBars or 0,
                    seconds(item.duration)
                )
                elseif self.section == "Finished" then string.format(
                    "%s / REV %d",
                    seconds(item.duration),
                    item.revision or 1
                )
                else if item.readOnly == false then "EDITABLE SOURCE" else "RETAINED ORIGINAL"
            card.saved.BackgroundColor3 = if saved then Ink else Amber
            card.saved:SetAttribute("Saved", saved)
        end
    end
    self.empty.Visible = #self.entries == 0
    self.empty.Text = if self.section == "Sections"
        then "Your sections appear here.\nCreate an idea in Sequence."
        elseif self.section == "Drafts" then "No drafts yet.\nArrange your sections in Song."
        elseif
            self.section == "Finished"
        then "No finished songs yet.\nOpen Song, arrange your sections, then Finish & Save."
        else "No legacy imports in this workspace."
    self.pageLabel.Text = string.format("%d / %d", self.pageIndex, self.pageCount)
    tint(self.previous, self.pageIndex > 1, false)
    tint(self.next, self.pageIndex < self.pageCount, false)
    tint(self.play, selected ~= nil, false)
    self.play.root.Text = if self.section == "Archives" then "OPEN" else "PLAY"
    tint(
        self.public,
        selected ~= nil and (self.section == "Finished" or self.section == "Sections"),
        false
    )
    tint(self.copy, selected ~= nil and self.section == "Finished", false)
    tint(self.imports, #(m.archives or {}) > 0, false)
    tint(self.recovery, m.hasRecovery == true, false)
    self.hint.Text = if self.publicHint
        then "TAKING YOUR MUSIC TO THE COURTYARD / prepare, then start"
        elseif self.section == "Archives" then "LEGACY IMPORTS / original maps and notes retained"
        elseif self.section == "Finished" then "SAVED REVISIONS / OPTIONS opens an editable copy"
        else "GREEN = SAVED / AMBER = EDITS / select a sleeve to open"
end

function Library:update(state)
    if self.destroyed then
        return
    end
    self.music = state and (state.music or state.library and state) or nil
    local m = self.music or {}
    self.selectedIds.Sections = m.sequenceId or self.selectedIds.Sections
    self.selectedIds.Drafts = m.draftId or self.selectedIds.Drafts
    self.selectedIds.Finished = m.selectedFinishedSongId or self.selectedIds.Finished
    self:_render()
end
function Library:resize(width, height)
    if self.destroyed then
        return
    end
    width, height = math.max(1, width), math.max(1, height)
    local compact = width < 650
    self.pageSize = if compact then 4 else 6
    local margin, gap, headerHeight, footerHeight = 8, 7, 32, 32
    local bodyTop, footerY = margin + headerHeight + gap, height - margin - 52
    self.header.Position = UDim2.fromOffset(margin, margin)
    self.header.Size = UDim2.fromOffset(math.max(1, width - margin * 2), headerHeight)
    local tabWidth = math.max(1, (width - margin * 2 - 40 - gap * 3) / 3)
    for index, section in { "Sections", "Drafts", "Finished" } do
        local tab = self.tabs[section]
        tab.root.Position = UDim2.fromOffset((index - 1) * (tabWidth + gap), 0)
        tab.root.Size = UDim2.fromOffset(tabWidth, headerHeight)
        if tab.icon then
            tab.icon.Visible = tabWidth >= 108
        end
    end
    self.options.root.Position = UDim2.fromOffset(width - margin * 2 - 40, 0)
    self.options.root.Size = UDim2.fromOffset(40, headerHeight)
    local bodyHeight = math.max(1, footerY - bodyTop - gap)
    self.body.Position = UDim2.fromOffset(margin, bodyTop)
    self.body.Size = UDim2.fromOffset(math.max(1, width - margin * 2), bodyHeight)
    local columns = if compact then 2 else 3
    local cardWidth = math.max(1, (width - margin * 2 - gap * (columns - 1)) / columns)
    local cardHeight = math.max(1, (bodyHeight - gap) / 2)
    for index, card in self.cards do
        card.root.Position = UDim2.fromOffset(
            (index - 1) % columns * (cardWidth + gap),
            math.floor((index - 1) / columns) * (cardHeight + gap)
        )
        card.root.Size = UDim2.fromOffset(cardWidth, cardHeight)
        local artSize = math.max(16, math.min(cardHeight - 14, cardWidth * 0.35, 84))
        card.art.Position = UDim2.new(0, 7, 0.5, -artSize / 2)
        card.art.Size = UDim2.fromOffset(artSize, artSize)
        local left, available = artSize + 15, math.max(1, cardWidth - artSize - 24)
        local lineHeight = math.min(18, math.max(12, (cardHeight - 10) / 3))
        local titleTop = (cardHeight - lineHeight * 3) / 2
        card.number.Position = UDim2.fromOffset(left, titleTop)
        card.number.Size = UDim2.fromOffset(math.max(1, available - 9), lineHeight)
        card.title.Position = UDim2.fromOffset(left, titleTop + lineHeight)
        card.title.Size = UDim2.fromOffset(available, lineHeight)
        card.detail.Position = UDim2.fromOffset(left, titleTop + lineHeight * 2)
        card.detail.Size = UDim2.fromOffset(available, lineHeight)
        card.saved.Position = UDim2.fromOffset(cardWidth - 12, titleTop + lineHeight / 2 - 2)
    end
    self.footer.Position = UDim2.fromOffset(margin, footerY)
    self.footer.Size = UDim2.fromOffset(math.max(1, width - margin * 2), footerHeight)
    self.previous.root.Position, self.previous.root.Size =
        UDim2.fromOffset(0, 0), UDim2.fromOffset(32, footerHeight)
    self.pageLabel.Position, self.pageLabel.Size =
        UDim2.fromOffset(36, 0), UDim2.fromOffset(56, footerHeight)
    self.next.root.Position, self.next.root.Size =
        UDim2.fromOffset(96, 0), UDim2.fromOffset(32, footerHeight)
    local actionWidth = math.min(120, math.max(64, (width - margin * 2 - 148) / 2))
    self.play.root.Position, self.play.root.Size =
        UDim2.new(1, -actionWidth * 2 - gap, 0, 0), UDim2.fromOffset(actionWidth, footerHeight)
    self.public.root.Position, self.public.root.Size =
        UDim2.new(1, -actionWidth, 0, 0), UDim2.fromOffset(actionWidth, footerHeight)
    self.hint.Position = UDim2.fromOffset(margin, height - margin - 16)
    self.hint.Size = UDim2.fromOffset(math.max(1, width - margin * 2), 16)
    self.popup.Size = UDim2.fromOffset(math.max(1, math.min(360, width - 16)), 200)
    if self.music then
        self:_render()
    end
end
function Library:destroy()
    if self.destroyed then
        return
    end
    self.destroyed = true
    for _, connection in self.connections do
        connection:Disconnect()
    end
    table.clear(self.connections)
    self.rootFrame:Destroy()
end
return Library
