-- Fixed courtyard deck. Six source rows, four queue lamps and context keys.
local GuiService = game:GetService("GuiService")
local Input = game:GetService("UserInputService")
local W = require(script.Parent.DeviceWidgets)
local Skin = require(script.Parent.DeviceSkin)
local View = {}
View.__index = View
local Dim = Color3.fromRGB(117, 147, 112)
local Edge = Color3.fromRGB(66, 96, 69)
local function seconds(value)
    value = math.max(0, math.floor(value or 0))
    return string.format("%02d:%02d", math.floor(value / 60), value % 60)
end
local function referenceKey(reference)
    if type(reference) ~= "table" then
        return nil
    end
    return tostring(reference.kind)
        .. ":"
        .. tostring(reference.id)
        .. ":"
        .. tostring(reference.revision)
end
local function label(parent, name, caption, size, color)
    local object = W.label(parent, name, caption, size, color)
    object.TextWrapped, object.TextTruncate = false, Enum.TextTruncate.AtEnd
    object.ZIndex = parent.ZIndex + 1
    return object
end
local function enabled(button, value)
    button.Active, button.Selectable = value, value
    button:SetAttribute("Enabled", value)
end
local function restoreFocus(panel)
    local selected = GuiService.SelectedObject
    if not selected or not selected:IsDescendantOf(panel) then
        return
    end
    local screen = panel.Parent
    local station, hud = screen:FindFirstChild("Workstation"), screen:FindFirstChild("HubHud")
    local navigation = station and station:FindFirstChild("Navigation", true)
    GuiService.SelectedObject = if station
            and station.Visible
            and navigation
        then navigation:FindFirstChild("Sequence")
        elseif hud and hud.Visible then hud:FindFirstChild("Sound")
        else nil
end
function View:_connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(self.connections, connection)
    return connection
end
function View:_lcdButton(parent, name, caption, action)
    local button = W.make("TextButton", parent, {
        Name = name,
        Text = caption,
        Font = Enum.Font.Code,
        TextSize = 12,
        TextColor3 = W.text,
        BackgroundColor3 = W.ink,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Active = true,
        Selectable = true,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = parent.ZIndex + 1,
    })
    local stroke = W.make(
        "UIStroke",
        button,
        { Color = Edge, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }
    )
    self:_connect(button.SelectionGained, function()
        stroke.Color = W.amber
    end)
    self:_connect(button.SelectionLost, function()
        stroke.Color = Edge
    end)
    self:_connect(button.Activated, function()
        if button.Active then
            action()
        end
    end)
    return button
end
function View:_cycle(direction)
    local choices = self.stage and self.stage.available or {}
    if #choices == 0 then
        return
    end
    self.choiceIndex = ((self.choiceIndex or 1) - 1 + direction) % #choices + 1
    local item = choices[self.choiceIndex]
    self.selectedRef = { kind = item.kind, id = item.id, revision = item.revision }
    self:_render()
end
function View:_sourcePopup()
    self.popup.Visible = true
    self.popupPage = math.floor(((self.choiceIndex or 1) - 1) / 6) + 1
    self:_renderPopup()
    if Input.GamepadEnabled and self.popupRows[1].Visible then
        GuiService.SelectedObject = self.popupRows[1]
    end
end
function View.new(screen, command, mute)
    local self = setmetatable({
        command = command,
        screen = screen,
        connections = {},
        queueRows = {},
        popupRows = {},
        popupPage = 1,
    }, View)
    self.panel = W.frame(screen, "CourtyardStage", W.ink)
    self.panel.AnchorPoint, self.panel.Position = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5)
    self.panel.Size, self.panel.Visible = UDim2.new(1, -24, 1, -24), false
    self.panel.ZIndex, self.panel.ClipsDescendants = 14, true
    W.make("UISizeConstraint", self.panel, { MaxSize = Vector2.new(600, 420) })
    W.make("UIStroke", self.panel, { Color = Edge, Thickness = 1 })
    self.bezel = Skin.image(self.panel, "bezel-v4", {
        Name = "StageBezel",
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(80, 80, 944, 602),
        SliceScale = 0.12,
        ZIndex = 14,
    })
    self.label = label(self.panel, "StageHeading", "COURTYARD / PUBLIC SETS", 13, W.amber)
    self.queueToggle = self:_lcdButton(self.panel, "ShowQueue", "QUEUE 0", function()
        self.showQueue = not self.showQueue
        self:_layout()
    end)
    self.musicCard = W.frame(self.panel, "SelectedMusic", Color3.fromRGB(27, 49, 34))
    self.musicCard.ZIndex = 15
    self.art = self:_lcdButton(self.musicCard, "ChooseMusic", "", function()
        self:_sourcePopup()
    end)
    self.art.ClipsDescendants = true
    self.sleeve = Skin.image(
        self.art,
        "sleeve-v4",
        { Name = "SelectedSleeve", ScaleType = Enum.ScaleType.Fit, ZIndex = self.art.ZIndex + 1 }
    )
    self.musicKind = label(self.musicCard, "MusicKind", "YOUR MUSIC", 10, W.amber)
    self.musicTitle = label(self.musicCard, "MusicTitle", "Make a sequence first", 15, W.text)
    self.musicTitle.TextWrapped, self.musicTitle.TextTruncate = true, Enum.TextTruncate.None
    self.musicDetail = label(self.musicCard, "MusicDuration", "", 11, Dim)
    self.previous = self:_lcdButton(self.musicCard, "PreviousMusic", "‹", function()
        self:_cycle(-1)
    end)
    self.next = self:_lcdButton(self.musicCard, "NextMusic", "›", function()
        self:_cycle(1)
    end)
    self.choicePage = label(self.musicCard, "MusicChoice", "0 / 0", 10, Dim)
    self.choicePage.TextXAlignment = Enum.TextXAlignment.Center
    self.queueCard = W.frame(self.panel, "PublicQueue", Color3.fromRGB(27, 49, 34))
    self.queueCard.ZIndex = 15
    self.nowHeading = label(self.queueCard, "StageState", "STAGE FREE", 11, W.amber)
    self.performer = label(self.queueCard, "CurrentPerformer", "A QUIET ROOM IS ENOUGH", 11, W.text)
    self.performanceTitle = label(self.queueCard, "PerformanceTitle", "", 10, Dim)
    for slot = 1, 4 do
        local row = W.frame(self.queueCard, "QueueSlot" .. slot)
        row.ZIndex = 16
        local lamp = W.frame(row, "TurnLamp", Edge)
        lamp.ZIndex = 17
        W.make("UICorner", lamp, { CornerRadius = UDim.new(1, 0) })
        self.queueRows[slot] =
            { root = row, lamp = lamp, text = label(row, "PerformerName", "", 10, Dim) }
    end
    self.noticeLabel = label(
        self.panel,
        "StageNotice",
        "Choose music. Prepare a pinned set. Join by choice.",
        10,
        Dim
    )
    local function key(name, icon, legend, action)
        local button = W.key(self.panel, name, icon, legend, function()
            command(action, if action == "StagePrepare" then self.selectedRef else nil)
        end)
        button.ZIndex = 18
        return button
    end
    self.prepare = key("PrepareSet", "sleeve", "PREPARE", "StagePrepare")
    self.start = key("StartTurn", "play", "START TURN", "StageStart")
    self.cancel = key("CancelSet", "close", "CANCEL SET", "StageCancel")
    self.join = key("JoinSet", "sound", "JOIN", "StageJoin")
    self.stop = key("StopSet", "stop", "END SET", "StageStop")
    self.mute = W.key(self.panel, "MuteStage", "sound", "SOUND ON", mute or function() end)
    self.close = key("LeaveStage", "back", "LEAVE STAGE", "StageClose")
    self.mute.ZIndex, self.close.ZIndex = 18, 18
    self.popup = W.frame(self.panel, "ChooseMusicPopup", W.ink)
    self.popup.ZIndex, self.popup.Visible = 25, false
    W.make("UIStroke", self.popup, { Color = W.amber, Thickness = 1 })
    self.popupTitle = label(self.popup, "MusicPickerTitle", "CHOOSE YOUR MUSIC", 12, W.amber)
    self.popupClose = self:_lcdButton(self.popup, "CloseMusicPicker", "×", function()
        self.popup.Visible = false
        if Input.GamepadEnabled then
            GuiService.SelectedObject = self.art
        end
    end)
    for slot = 1, 6 do
        self.popupRows[slot] = self:_lcdButton(self.popup, "MusicSource" .. slot, "", function()
            local item = (self.stage and self.stage.available or {})[(self.popupPage - 1) * 6 + slot]
            if item then
                self.choiceIndex = (self.popupPage - 1) * 6 + slot
                self.selectedRef = { kind = item.kind, id = item.id, revision = item.revision }
                self.popup.Visible = false
                self:_render()
                if Input.GamepadEnabled then
                    GuiService.SelectedObject = self.art
                end
            end
        end)
        self.popupRows[slot].TextXAlignment = Enum.TextXAlignment.Left
    end
    self.popupPrevious = self:_lcdButton(self.popup, "PreviousMusicPage", "‹", function()
        self.popupPage = math.max(1, self.popupPage - 1)
        self:_renderPopup()
    end)
    self.popupNext = self:_lcdButton(self.popup, "NextMusicPage", "›", function()
        self.popupPage += 1
        self:_renderPopup()
    end)
    self.popupPageLabel = label(self.popup, "MusicPickerPage", "1 / 1", 10, Dim)
    self.popupPageLabel.TextXAlignment = Enum.TextXAlignment.Center
    self:_connect(self.panel:GetPropertyChangedSignal("AbsoluteSize"), function()
        self:_layout()
    end)
    self:_layout()
    return self
end
function View:_layout()
    local width, height = self.panel.AbsoluteSize.X, self.panel.AbsoluteSize.Y
    if width <= 0 or height <= 0 then
        return
    end
    W.place(self.label, 10, 6, width - 104, 23)
    W.place(self.queueToggle, width - 90, 5, 80, 26)
    local actionY, footerY = height - 103, height - 51
    local bodyY, bodyHeight = 37, math.max(30, actionY - 57)
    local stacked = width < 480
    self.compactBody = stacked and bodyHeight < 185
    if not stacked then
        W.place(self.musicCard, 10, bodyY, math.floor((width - 30) * 0.59), bodyHeight)
        W.place(
            self.queueCard,
            20 + math.floor((width - 30) * 0.59),
            bodyY,
            math.ceil((width - 30) * 0.41),
            bodyHeight
        )
        self.musicCard.Visible, self.queueCard.Visible = true, true
    elseif self.compactBody then
        W.place(self.musicCard, 10, bodyY, width - 20, bodyHeight)
        W.place(self.queueCard, 10, bodyY, width - 20, bodyHeight)
        self.musicCard.Visible, self.queueCard.Visible = not self.showQueue, self.showQueue == true
    else
        local musicHeight = math.floor(bodyHeight * 0.53)
        W.place(self.musicCard, 10, bodyY, width - 20, musicHeight)
        W.place(
            self.queueCard,
            10,
            bodyY + musicHeight + 5,
            width - 20,
            bodyHeight - musicHeight - 5
        )
        self.musicCard.Visible, self.queueCard.Visible = true, true
    end
    local cardWidth, cardHeight = self.musicCard.Size.X.Offset, self.musicCard.Size.Y.Offset
    local artSize = math.max(30, math.min(cardHeight - 34, 94, cardWidth * 0.32))
    W.place(self.art, 6, 6, artSize, artSize)
    local textX = artSize + 14
    W.place(self.musicKind, textX, 5, cardWidth - textX - 6, 15)
    W.place(self.musicTitle, textX, 21, cardWidth - textX - 6, math.max(20, cardHeight - 64))
    W.place(self.musicDetail, textX, cardHeight - 39, cardWidth - textX - 6, 15)
    self.musicDetail.Visible = cardHeight >= 80
    self.musicTitle.TextSize = if cardHeight < 90 then 12 else 15
    self.musicTitle.TextWrapped = cardHeight >= 95
    self.musicTitle.TextTruncate = if cardHeight >= 95
        then Enum.TextTruncate.None
        else Enum.TextTruncate.AtEnd
    W.place(self.previous, 6, cardHeight - 26, 28, 22)
    W.place(self.next, cardWidth - 34, cardHeight - 26, 28, 22)
    W.place(self.choicePage, 38, cardHeight - 26, cardWidth - 76, 22)
    local queueWidth, queueHeight = self.queueCard.Size.X.Offset, self.queueCard.Size.Y.Offset
    W.place(self.nowHeading, 6, 3, queueWidth - 12, 15)
    W.place(self.performer, 6, 18, queueWidth - 12, 17)
    W.place(self.performanceTitle, 6, 35, queueWidth - 12, 14)
    local rowTop = if queueHeight >= 108 then 49 else 36
    self.performanceTitle.Visible = queueHeight >= 108
    local queueColumns = if queueHeight < 92 then 2 else 1
    local queueRowCount = 4 / queueColumns
    local rowHeight = math.max(9, (queueHeight - rowTop - 4) / queueRowCount)
    local rowWidth = (queueWidth - 12) / queueColumns
    for slot, row in self.queueRows do
        W.place(
            row.root,
            6 + (slot - 1) % queueColumns * rowWidth,
            rowTop + math.floor((slot - 1) / queueColumns) * rowHeight,
            rowWidth,
            rowHeight
        )
        W.place(row.lamp, 1, math.max(1, (rowHeight - 5) / 2), 5, 5)
        W.place(row.text, 13, 0, rowWidth - 14, rowHeight)
        row.text.TextSize = if rowHeight < 14 then 9 else 10
    end
    W.place(self.noticeLabel, 10, actionY - 18, width - 20, 15)
    local keyWidth = (width - 26) / 2
    for _, button in { self.prepare, self.start, self.cancel, self.stop } do
        W.place(button, 8, actionY, keyWidth, 44)
    end
    W.place(self.join, width / 2 + 5, actionY, keyWidth, 44)
    if self.stage and self.stage.hosting then
        W.place(self.stop, 8, actionY, width - 16, 44)
    end
    if self.stage and self.stage.canStart then
        W.place(self.cancel, width / 2 + 5, actionY, keyWidth, 44)
    end
    W.place(self.mute, 8, footerY, keyWidth, 44)
    W.place(self.close, width / 2 + 5, footerY, keyWidth, 44)
    local popupWidth, popupHeight = math.min(width - 16, 420), math.min(height - 12, 320)
    W.place(
        self.popup,
        (width - popupWidth) / 2,
        (height - popupHeight) / 2,
        popupWidth,
        popupHeight
    )
    W.place(self.popupTitle, 8, 3, popupWidth - 53, 25)
    W.place(self.popupClose, popupWidth - 38, 3, 30, 25)
    local rowHeightPopup = math.max(16, (popupHeight - 64) / 6)
    for slot, row in self.popupRows do
        W.place(row, 8, 32 + (slot - 1) * rowHeightPopup, popupWidth - 16, rowHeightPopup - 2)
    end
    W.place(self.popupPrevious, 8, popupHeight - 27, 34, 22)
    W.place(self.popupPageLabel, 46, popupHeight - 27, popupWidth - 92, 22)
    W.place(self.popupNext, popupWidth - 42, popupHeight - 27, 34, 22)
    W.set(
        self.queueToggle,
        "Text",
        if self.compactBody and self.showQueue
            then "MUSIC"
            else "QUEUE " .. #(self.stage and self.stage.queue or {})
    )
    enabled(self.queueToggle, self.compactBody)
end
function View:_renderPopup()
    local choices = self.stage and self.stage.available or {}
    local pages = math.max(1, math.ceil(#choices / 6))
    self.popupPage = math.clamp(self.popupPage, 1, pages)
    for slot, row in self.popupRows do
        local item = choices[(self.popupPage - 1) * 6 + slot]
        row.Visible = item ~= nil
        if item then
            W.set(
                row,
                "Text",
                "  " .. (if item.kind == "finished" then "SONG · " else "LOOP · ") .. item.title
            )
            row:SetAttribute("MusicId", item.id)
            row:SetAttribute("MusicRevision", item.revision)
        end
    end
    W.set(self.popupPageLabel, "Text", tostring(self.popupPage) .. " / " .. tostring(pages))
    enabled(self.popupPrevious, self.popupPage > 1)
    enabled(self.popupNext, self.popupPage < pages)
end
function View:_render()
    local stage = self.stage
    if not stage then
        return
    end
    local choices = stage.available or {}
    self.choiceIndex = math.clamp(self.choiceIndex or 1, 1, math.max(1, #choices))
    local choice = choices[self.choiceIndex]
    W.set(self.musicTitle, "Text", choice and choice.title or "Make a sequence first")
    self.musicTitle:SetAttribute(
        "AccessibleLabel",
        choice and choice.title or "Make a sequence first"
    )
    W.set(
        self.musicKind,
        "Text",
        if choice and choice.kind == "finished" then "FINISHED SONG" else "SEQUENCE LOOP"
    )
    W.set(
        self.musicDetail,
        "Text",
        if choice and choice.kind == "finished"
            then seconds(choice.duration) .. " · PLAYS ONCE"
            elseif choice then tostring(choice.bars or 0) .. " BARS · " .. tostring(
                choice.bpm or 96
            ) .. " BPM"
            else "Your music stays yours"
    )
    W.set(
        self.choicePage,
        "Text",
        tostring(if choice then self.choiceIndex else 0)
            .. " / "
            .. tostring(#choices)
            .. " · CHOOSE"
    )
    W.set(
        self.nowHeading,
        "Text",
        if stage.hosting
            then "YOUR PUBLIC SET"
            elseif stage.listening then "LISTENING BY CHOICE"
            elseif stage.performer then "ON STAGE"
            else "STAGE FREE"
    )
    W.set(self.performer, "Text", stage.performer or "A QUIET ROOM IS ENOUGH")
    W.set(self.performanceTitle, "Text", stage.title or "Prepare music when you are ready")
    for slot, row in self.queueRows do
        local name = (stage.queue or {})[slot]
        row.root.Visible = name ~= nil
        W.set(row.text, "Text", string.format("%02d  %s", slot, name or ""))
        row.text:SetAttribute(
            "AccessibleLabel",
            name and ("Queue position " .. slot .. ": " .. name) or ""
        )
        W.set(row.lamp, "BackgroundColor3", if stage.position == slot then W.amber else Dim)
    end
    local status
    if stage.canStart then
        local remaining = if stage.offerEndsAt
            then math.max(0, math.ceil(stage.offerEndsAt - workspace:GetServerTimeNow()))
            else stage.offerRemaining or 0
        status = "YOUR TURN · START WITHIN " .. remaining .. "s"
    elseif self.notice and os.clock() < self.noticeUntil then
        status = self.notice
    elseif stage.requesting then
        status = "PINNED SET · QUEUE POSITION "
            .. tostring(stage.position)
            .. " · CANCEL TO REPLACE"
    elseif stage.listening then
        status = self.audioStatus or "Listening by choice. Sound and leave are always available."
    else
        status = "Prepare your music. Join another set only when you choose."
    end
    W.set(self.noticeLabel, "Text", status)
    self.noticeLabel:SetAttribute("AccessibleLabel", status)
    enabled(self.prepare, choice ~= nil and not stage.hosting and not stage.requesting)
    enabled(self.start, stage.canStart == true)
    enabled(self.cancel, stage.requesting == true)
    enabled(self.join, stage.performer ~= nil and not stage.listening)
    enabled(self.stop, stage.hosting == true)
    enabled(self.previous, #choices > 1)
    enabled(self.next, #choices > 1)
    enabled(self.art, choice ~= nil)
    self.prepare:SetAttribute(
        "AccessibleLabel",
        if choice
            then "Prepare " .. (if choice.kind == "finished"
                then "Finished Song: "
                else "Sequence loop: ") .. choice.title
            else "No music available to prepare"
    )
    W.legend(self.join, if stage.listening then "LISTENING" else "JOIN")
    self.prepare.Visible = not stage.hosting and not stage.requesting
    self.start.Visible = stage.canStart == true
    self.cancel.Visible = stage.requesting == true and not stage.hosting
    self.stop.Visible = stage.hosting == true
    self.join.Visible = not stage.canStart and not stage.hosting
    self.stop:SetAttribute("Selected", stage.hosting == true)
    self.join:SetAttribute("Selected", stage.listening == true)
    if self.popup.Visible then
        self:_renderPopup()
    end
    self:_layout()
end
function View:update(stage, muted, notice, audioStatus)
    local wasOpen = self.panel.Visible
    self.stage, self.audioStatus = stage, audioStatus
    self.panel.Visible = stage ~= nil and stage.open == true
    if wasOpen and not self.panel.Visible then
        restoreFocus(self.panel)
        self.popup.Visible = false
    end
    if not stage then
        return
    end
    local choices = stage.available or {}
    local externalKey = referenceKey(stage.selectedRef)
    local opening = self.panel.Visible and not wasOpen
    local externalChanged = externalKey ~= self.externalRefKey
    local requested = if stage.selectedRef and (opening or externalChanged)
        then stage.selectedRef
        else self.selectedRef or stage.selectedRef
    self.externalRefKey = externalKey
    self.choiceIndex = 1
    for index, item in choices do
        if requested and requested.kind == item.kind and requested.id == item.id then
            self.choiceIndex = index
            break
        end
    end
    local choice = choices[self.choiceIndex]
    self.selectedRef = choice and { kind = choice.kind, id = choice.id, revision = choice.revision }
    if notice then
        self.notice, self.noticeUntil = notice, os.clock() + 6
    end
    W.legend(self.mute, if muted then "SOUND MUTED" else "SOUND ON")
    self.mute:SetAttribute("Selected", muted == true)
    self:_render()
    local selected = GuiService.SelectedObject
    if
        self.panel.Visible
        and Input.GamepadEnabled
        and (
            not wasOpen
            or not selected
            or not selected:IsDescendantOf(self.panel)
            or not selected.Selectable
            or not selected.Visible
        )
    then
        GuiService.SelectedObject = if stage.hosting
            then self.stop
            elseif stage.canStart then self.start
            elseif stage.requesting then self.cancel
            elseif self.join.Active then self.join
            else self.prepare
    end
end
function View:destroy()
    restoreFocus(self.panel)
    for _, connection in self.connections do
        connection:Disconnect()
    end
    self.panel:Destroy()
end
return View
