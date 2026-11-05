local W = require(script.Parent.DeviceWidgets)
local Icons = require(script.Parent.GameIcons)
local Visual = require(game.ReplicatedStorage.Shared.StageChoiceVisual)
local Picker = {}
Picker.__index = Picker
local function icon(parent, name, size, color)
    local object = Icons.make(parent, name, color or W.text, size)
    object.ZIndex = 19
    for _, child in object:GetDescendants() do if child:IsA("GuiObject") then child.ZIndex = 19 end end
    return object
end
local function button(parent, name, callback)
    local b = W.make("TextButton", parent, { Name = name, Text = "", BackgroundColor3 = W.ink,
        BorderSizePixel = 0, AutoButtonColor = false, Selectable = true, ZIndex = 18 })
    local stroke = W.make("UIStroke", b, { Color = W.text, Thickness = 1 })
    b.SelectionGained:Connect(function() stroke.Thickness = 3 end)
    b.SelectionLost:Connect(function() stroke.Thickness = 1 end)
    b.Activated:Connect(function() if b.Active then callback() end end)
    return b
end
local function enable(b, value) b.Active, b.Interactable, b.Selectable = value, value, value end
function Picker.new(parent, choose, mode)
    local self = setmetatable({ choose = choose, mode = mode, rows = {}, cells = {}, roles = {}, page = 1 }, Picker)
    self.root = W.frame(parent, "MusicPictures")
    self.rowsRoot = W.frame(self.root, "Sources")
    for slot = 1, 2 do
        local row = {}
        row.button = button(self.rowsRoot, "Source" .. slot, function() if row.index then choose(row.index) end end)
        row.picture = icon(row.button, "pads", 28)
        row.picture.Position = UDim2.fromOffset(8, 12)
        row.title = W.label(row.button, "Name", "", 13, W.text)
        row.title.Position, row.title.Size, row.title.ZIndex = UDim2.fromOffset(44, 3), UDim2.new(1, -80, 0, 28), 19
        row.title.TextTruncate, row.title.TextWrapped = Enum.TextTruncate.AtEnd, false
        row.info = W.label(row.button, "Length", "", 11, W.text)
        row.info.Position, row.info.Size, row.info.ZIndex = UDim2.fromOffset(44, 30), UDim2.new(1, -80, 0, 20), 19
        row.mark = icon(row.button, "check", 22, W.amber)
        row.mark.Position = UDim2.new(1, -28, 0.5, -11)
        self.rows[slot] = row
    end
    self.back = button(self.root, "PreviousPage", function() self.page = math.max(1, self.page - 1); self:paint() end)
    icon(self.back, "undo", 24).Position = UDim2.fromOffset(10, 10)
    self.next = button(self.root, "NextPage", function() self.page = math.min(self.pages, self.page + 1); self:paint() end)
    icon(self.next, "arrow", 24).Position = UDim2.fromOffset(10, 10)
    self.pageLabel = W.label(self.root, "SourcePage", "", 12, W.text)
    self.pageLabel.TextXAlignment, self.pageLabel.ZIndex = Enum.TextXAlignment.Center, 19
    self.preview = W.frame(self.root, "FirstBarPicture")
    for i = 1, 16 do
        self.cells[i] = W.line(self.preview, "NoteBin" .. i, W.text)
        self.cells[i].ZIndex = 18
    end
    for i, role in { "drums", "bass", "hook", "harbour" } do
        local glyph = icon(self.preview, ({ drums = "drum", bass = "bass", hook = "sound", harbour = "waves" })[role], 24)
        glyph.Position = UDim2.new((i - 1) / 4, 6, 0, 25)
        self.roles[role] = glyph
    end
    self.short = button(self.root, "ShortSet", function() mode(true) end)
    self.long = button(self.root, "LoopOrSong", function() mode(false) end)
    self.shortIcon = icon(self.short, "play", 26)
    self.shortIcon.Position = UDim2.fromOffset(8, 10)
    self.longIcon = icon(self.long, "redo", 26)
    self.longIcon.Position = UDim2.fromOffset(8, 10)
    self.shortText = W.label(self.short, "Mode", "SHORT", 12, W.text)
    self.longText = W.label(self.long, "Mode", "LOOP", 12, W.text)
    for _, text in { self.shortText, self.longText } do
        text.Position, text.Size, text.ZIndex = UDim2.fromOffset(42, 0), UDim2.new(1, -48, 1, 0), 19
    end
    return self
end
function Picker:set(stage, index, short)
    self.stage, self.index, self.isShort = stage, index, short
    local choice = (stage.available or {})[index]
    local key = choice and choice.kind .. ":" .. choice.id
    if key ~= self.key then self.page = math.floor((index - 1) / 2) + 1; self.key = key end
    self:paint()
end
function Picker:paint()
    local stage = self.stage
    if not stage then return end
    local choices = stage.available or {}
    local pinned = stage.requesting and stage.entries and stage.entries[stage.position]
    self.pages = math.max(1, math.ceil(#choices / 2))
    self.page = math.clamp(self.page, 1, self.pages)
    local editable = not stage.requesting and not stage.hosting and not stage.listening
    self.rowsRoot.Visible = editable and #choices > 0
    local y = 0
    for slot, row in self.rows do
        row.index = (self.page - 1) * 2 + slot
        local item = choices[row.index]
        row.button.Visible = item ~= nil and editable
        enable(row.button, item ~= nil and editable)
        if item and editable then
            W.place(row.button, 0, (slot - 1) * 60, (self.width or self.root.AbsoluteSize.X), 56)
            local selected = row.index == self.index
            row.button.BackgroundColor3 = if selected then W.amber else W.ink
            row.mark.Visible = selected
            row.title.Text = item.title
            row.title.TextColor3, row.info.TextColor3 = if selected then W.ink else W.text, if selected then W.ink else W.text
            row.info.Text = if item.kind == "finished" then "SONG" elseif item.kind == "challenge" then "8 / DRAFT" else tostring(item.bars) .. " / " .. tostring(item.bpm)
            local pictureName = if item.kind == "finished" then "disc" elseif item.kind == "challenge" then "crate" else "pads"
            if row.pictureName ~= pictureName then row.picture:Destroy(); row.picture = icon(row.button, pictureName, 28); row.picture.Position = UDim2.fromOffset(8, 12); row.pictureName = pictureName end
            Icons.tint(row.picture, if selected then W.ink else W.text)
            Icons.tint(row.mark, W.ink)
            row.button:SetAttribute("AccessibleLabel", item.title .. " / " .. row.info.Text .. (if selected then " / selected" else " / choose"))
            y += 60
        end
    end
    -- Keep paging height stable, including an odd final page.
    y = if editable then math.min(2, #choices) * 60 else 0
    W.place(self.rowsRoot, 0, 0, (self.width or self.root.AbsoluteSize.X), y)
    self.back.Visible, self.next.Visible, self.pageLabel.Visible = editable and self.pages > 1, editable and self.pages > 1, editable and self.pages > 1
    if self.back.Visible then
        W.place(self.back, 0, y, 44, 44); W.place(self.next, math.max(0, (self.width or self.root.AbsoluteSize.X) - 44), y, 44, 44)
        W.place(self.pageLabel, 48, y, math.max(0, (self.width or self.root.AbsoluteSize.X) - 96), 44)
        self.pageLabel.Text = self.page .. " / " .. self.pages
        enable(self.back, self.page > 1); enable(self.next, self.page < self.pages)
        y += 52
    end
    local choice = choices[self.index]
    local mode = if self.isShort then "spotlight" elseif choice and choice.kind == "finished" then "full" else "practice"
    local review = if Visual.matches(stage.sourceReview, choice, mode) then stage.sourceReview else nil
    local visual = if pinned then pinned.visual elseif editable then review and review.visual else nil
    self.preview.Visible = visual ~= nil
    if visual then
        W.place(self.preview, 0, y, (self.width or self.root.AbsoluteSize.X), 54)
        for i, cell in self.cells do
            cell.Position, cell.Size = UDim2.new((i - 1) / 16, 1, 0, 0), UDim2.new(1 / 16, -3, 0, 14)
            cell.BackgroundColor3 = if visual.pattern[i] then W.amber else Color3.fromRGB(53, 75, 59)
        end
        for role, glyph in self.roles do Icons.tint(glyph, if visual.roles[role] then W.text else Color3.fromRGB(117, 147, 112)) end
        self.preview:SetAttribute("AccessibleLabel", "First bar note overview; active layer pictures")
        y += 62
    end
    self.short.Visible, self.long.Visible = choice ~= nil and editable, choice ~= nil and editable
    if self.short.Visible then
        local width = math.max(0, ((self.width or self.root.AbsoluteSize.X) - 8) / 2)
        W.place(self.short, 0, y, width, 48); W.place(self.long, width + 8, y, width, 48)
        enable(self.short, true); enable(self.long, choice.kind ~= "challenge")
        self.short.BackgroundColor3, self.long.BackgroundColor3 = if self.isShort then W.amber else W.ink, if self.isShort then W.ink else W.amber
        self.shortText.TextColor3, self.longText.TextColor3 = if self.isShort then W.ink else W.text, if self.isShort then W.text else W.ink
        self.longText.Text = if choice.kind == "finished" then "SONG" else "LOOP"
        local name = if choice.kind == "finished" then "disc" else "redo"
        if self.longName ~= name then self.longIcon:Destroy(); self.longIcon = icon(self.long, name, 26); self.longIcon.Position = UDim2.fromOffset(8, 10); self.longName = name end
        Icons.tint(self.shortIcon, if self.isShort then W.ink else W.text)
        Icons.tint(self.longIcon, if self.isShort then W.text else W.ink)
        y += 56
    end
    self.height = y
end
function Picker:layout(width)
    self.width = width
    self.root.Size = UDim2.fromOffset(width, self.height or 0)
    self:paint()
    self.root.Size = UDim2.fromOffset(width, self.height or 0)
end
return Picker
