-- Fixed arrangement LCD. Cards, repeat blocks, popups and hardware keys are
-- allocated once; state updates only rebind their values and stable identities.
local Input = game:GetService("UserInputService")
local Http = game:GetService("HttpService")
local Shared = game.ReplicatedStorage.Shared
local Transport = require(Shared.MusicTransport)
local W = require(script.Parent.DeviceWidgets)
local Song = {}
Song.__index = Song
local Dim = Color3.fromRGB(114, 146, 111)
local Edge = Color3.fromRGB(58, 88, 68)
local Selected = Color3.fromRGB(42, 72, 49)
local function seconds(value)
    value = math.max(0, math.floor(tonumber(value) or 0))
    return string.format("%02d:%02d", math.floor(value / 60), value % 60)
end
local function pointer(input)
    return Vector2.new(input.Position.X, input.Position.Y)
end
local function text(parent, name, caption, size, color)
    local label = W.label(parent, name, caption, size, color)
    label.TextWrapped = false
    label.TextTruncate = Enum.TextTruncate.AtEnd
    label.ZIndex = parent.ZIndex + 1
    return label
end
function Song:_connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(self.connections, connection)
    return connection
end
function Song:_button(parent, name, caption, callback)
    local button = W.make("TextButton", parent, {
        Name = name,
        Text = caption,
        Font = Enum.Font.Code,
        TextSize = 12,
        TextColor3 = W.text,
        BackgroundColor3 = W.ink,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Selectable = true,
        Active = true,
        ZIndex = parent.ZIndex + 1,
    })
    button:SetAttribute("AccessibleLabel", caption)
    local stroke = W.make("UIStroke", button, {
        Color = Edge,
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
    self:_connect(button.SelectionGained, function()
        stroke.Color, stroke.Thickness = W.amber, 2
    end)
    self:_connect(button.SelectionLost, function()
        stroke.Color, stroke.Thickness = Edge, 1
    end)
    self:_connect(button.Activated, function()
        if button.Active then
            callback()
        end
    end)
    return button
end
function Song:_command(action, a, b)
    if self.callbacks.command then
        self.callbacks.command(action, a, b)
    end
end
function Song:_name(title, current, submit)
    if self.callbacks.namePrompt then
        self.callbacks.namePrompt(title, current, submit)
    else
        submit(current)
    end
end
function Song:_step()
    for index, step in self.summary and self.summary.steps or {} do
        if step.stepId == self.selectedStepId then
            return step, index
        end
    end
    return nil
end
function Song:_selectedCommand(action, payload)
    local step = self:_step()
    if step then
        payload = payload or {}
        payload.stepId = step.stepId
        self:_command(action, payload)
    end
end
function Song:_setPage(delta)
    local steps = self.summary and self.summary.steps or {}
    local count = #steps
    self.pageIndex = math.clamp(self.pageIndex + delta, 1, math.max(1, math.ceil(count / 4)))
    local selected = steps[(self.pageIndex - 1) * 4 + 1]
    self.selectedStepId = selected and selected.stepId
    self:_render()
end
function Song:_open(mode)
    self.popupMode, self.popupPage = mode, 1
    if mode == "sources" then
        local step = self:_step()
        self.sourceStepId = step and step.stepId
        if not self.sourceStepId then
            return
        end
    end
    self.popup.Visible = true
    self:_renderPopup()
end
function Song:_tempo(delta)
    local draft = self.state and self.state.music and self.state.music.draft
    if draft then
        self:_command("SongTempo", { bpm = math.clamp(draft.bpm + delta, 60, 180) })
    end
end
function Song:_play()
    local music = self.state and self.state.music
    if not music or not music.draft then
        return
    end
    local transport = music.transport
    if transport and transport.ref.kind == "song" and transport.ref.id == music.draftId then
        self:_command("Play")
    else
        self:_command("SongPlay")
    end
end
function Song:_finish()
    local music = self.state and self.state.music
    if not music or not music.draft then
        return
    end
    local key = table.concat({
        tostring(music.projectId),
        tostring(music.draftId),
        tostring(music.projectRevision),
        tostring(music.draft.revision),
    }, ":")
    if not self.finishRequests[key] then
        self.finishRequests[key] = Http:GenerateGUID(false)
        table.insert(self.finishOrder, key)
        if #self.finishOrder > 32 then
            self.finishRequests[table.remove(self.finishOrder, 1)] = nil
        end
    end
    self:_command("SongFinish", {
        requestId = self.finishRequests[key],
        projectRevision = music.projectRevision,
        draftRevision = music.draft.revision,
    })
end

function Song.new(parent, callbacks)
    local self = setmetatable({
        callbacks = callbacks or {},
        connections = {},
        cards = {},
        keys = {},
        popupRows = {},
        pageIndex = 1,
        popupPage = 1,
        finishRequests = {},
        finishOrder = {},
    }, Song)
    self.rootFrame = W.frame(parent, "DeviceSongScreen", W.ink)
    self.rootFrame.Size = UDim2.fromScale(1, 1)
    self.rootFrame.ClipsDescendants, self.rootFrame.ZIndex = true, 2
    self.title = self:_button(self.rootFrame, "DraftTitle", "NEW SONG", function()
        local draft = self.state and self.state.music and self.state.music.draft
        if draft then
            self:_name("Rename song draft", draft.name, function(name)
                self:_command("SongRename", { name = name })
            end)
        end
    end)
    self.title.TextXAlignment, self.title.TextSize = Enum.TextXAlignment.Left, 16
    self.drafts = self:_button(self.rootFrame, "ChooseDraft", "DRAFTS", function()
        self:_open("drafts")
    end)
    self.clock = text(self.rootFrame, "DigitalClock", "00:00", 20, W.amber)
    self.clock.TextXAlignment = Enum.TextXAlignment.Right
    self.overview = text(self.rootFrame, "SongOverview", "ARRANGE YOUR SECTIONS", 11, Dim)
    self.status = text(self.rootFrame, "SongStatus", "STOPPED", 11, Dim)
    self.status.TextXAlignment = Enum.TextXAlignment.Right
    self.timeline = W.frame(self.rootFrame, "ArrangementTimeline")
    self.timeline.ZIndex = 3
    self.timeline:SetAttribute("Graphic", "ordered_sequence_repeat_blocks")
    self.left = self:_button(self.timeline, "PreviousSections", "‹", function()
        self:_setPage(-1)
    end)
    self.right = self:_button(self.timeline, "NextSections", "›", function()
        self:_setPage(1)
    end)
    self.pageLabel = text(self.timeline, "SectionPage", "01 / 01", 10, Dim)
    self.pageLabel.TextXAlignment = Enum.TextXAlignment.Center
    self.empty = text(
        self.timeline,
        "EmptyArrangement",
        "ADD A SECTION\nBuild your song from saved or working sequences.",
        14,
        W.text
    )
    self.empty.TextWrapped, self.empty.TextXAlignment = true, Enum.TextXAlignment.Center
    for slot = 1, 4 do
        local card = {}
        card.root = self:_button(self.timeline, "SectionCard" .. slot, "", function()
            if card.stepId then
                self.selectedStepId = card.stepId
                self:_render()
            end
        end)
        card.root.ClipsDescendants = true
        card.fill = W.frame(card.root, "PlaybackFill", Selected)
        card.fill.ZIndex = card.root.ZIndex
        card.fill.Size = UDim2.fromScale(0, 1)
        card.number = text(card.root, "SectionNumber", "", 18, W.amber)
        card.name = text(card.root, "SequenceName", "", 12, W.text)
        card.name.TextWrapped, card.name.TextTruncate = true, Enum.TextTruncate.None
        card.detail = text(card.root, "SectionBars", "", 10, Dim)
        card.repeats = {}
        for index = 1, 32 do
            local block = W.frame(card.root, "RepeatBlock" .. index, W.text)
            block.ZIndex = card.root.ZIndex + 1
            card.repeats[index] = block
        end
        self:_connect(card.root.InputBegan, function(input)
            if
                not card.stepId
                or (
                    input.UserInputType ~= Enum.UserInputType.MouseButton1
                    and input.UserInputType ~= Enum.UserInputType.Touch
                )
            then
                return
            end
            local music = self.state and self.state.music
            self.drag = {
                input = input,
                origin = pointer(input),
                position = pointer(input),
                stepId = card.stepId,
                sourceIndex = card.index,
                projectId = music and music.projectId,
                draftId = music and music.draftId,
                name = card.name.Text,
            }
            self.selectedStepId = card.stepId
            self:_render()
        end)
        self.cards[slot] = card
    end
    self.tempoMode = self:_button(self.rootFrame, "TempoMode", "SECTION TEMPO", function()
        local draft = self.state and self.state.music and self.state.music.draft
        if draft then
            self:_command(
                "SongTempo",
                { tempoMode = if draft.tempoMode == "song" then "sequence" else "song" }
            )
        end
    end)
    self.bpmMinus = self:_button(self.rootFrame, "TempoDown", "−", function()
        self:_tempo(-1)
    end)
    self.bpm = self:_button(self.rootFrame, "MasterBpm", "096 BPM", function()
        local draft = self.state and self.state.music and self.state.music.draft
        if draft then
            self:_name("Song tempo / 60–180 BPM", tostring(draft.bpm), function(value)
                local number = tonumber(value)
                if number then
                    self:_command("SongTempo", { bpm = math.clamp(math.round(number), 60, 180) })
                end
            end)
        end
    end)
    self.bpmPlus = self:_button(self.rootFrame, "TempoUp", "+", function()
        self:_tempo(1)
    end)
    self.selected = text(self.rootFrame, "SelectedSection", "SELECT A SECTION", 10, Dim)
    self.repeatMinus = self:_button(self.rootFrame, "RepeatDown", "−", function()
        local step = self:_step()
        if step then
            self:_selectedCommand("SongStepUpdate", { repeats = math.max(1, step.repeats - 1) })
        end
    end)
    self.repeatLabel = text(self.rootFrame, "RepeatCount", "REPEAT ×1", 11, W.text)
    self.repeatLabel.TextXAlignment = Enum.TextXAlignment.Center
    self.repeatPlus = self:_button(self.rootFrame, "RepeatUp", "+", function()
        local step = self:_step()
        if step then
            self:_selectedCommand("SongStepUpdate", { repeats = math.min(32, step.repeats + 1) })
        end
    end)
    self.source = self:_button(self.rootFrame, "ChangeSource", "SOURCE", function()
        self:_open("sources")
    end)
    self.remove = self:_button(self.rootFrame, "RemoveSection", "REMOVE", function()
        self:_selectedCommand("SongStepRemove")
    end)
    for _, spec in
        {
            {
                "New",
                "plus",
                "NEW",
                function()
                    self:_name("New song draft", "My song", function(name)
                        self:_command("SongNew", { name = name })
                    end)
                end,
            },
            {
                "Add",
                "steps",
                "ADD",
                function()
                    local music = self.state and self.state.music
                    if music and music.draft then
                        self:_command(
                            "SongStepInsert",
                            { sequenceId = music.sequenceId, repeats = 1 }
                        )
                    end
                end,
            },
            {
                "Play",
                "play",
                "PLAY",
                function()
                    self:_play()
                end,
            },
            {
                "Save",
                "save",
                "SAVE",
                function()
                    self:_command("SaveDraft")
                end,
            },
            {
                "Finish",
                "disc",
                "FINISH",
                function()
                    self:_finish()
                end,
            },
            {
                "Tools",
                "knob",
                "TOOLS",
                function()
                    self:_open("tools")
                end,
            },
        }
    do
        local key = W.key(self.rootFrame, "Song" .. spec[1], spec[2], spec[3], spec[4])
        key.ZIndex = 7
        self.keys[spec[1]] = key
    end

    self.popup = W.frame(self.rootFrame, "SongPopup", W.ink)
    self.popup.ZIndex, self.popup.Visible = 20, false
    W.make("UIStroke", self.popup, { Color = W.amber, Thickness = 1 })
    self.popupTitle = text(self.popup, "PopupTitle", "TOOLS", 13, W.amber)
    self.popupClose = self:_button(self.popup, "ClosePopup", "×", function()
        self.popup.Visible = false
    end)
    for slot = 1, 6 do
        self.popupRows[slot] = self:_button(self.popup, "PopupItem" .. slot, "", function()
            self:_choosePopup(slot)
        end)
        self.popupRows[slot].TextXAlignment = Enum.TextXAlignment.Left
    end
    self.popupPrevious = self:_button(self.popup, "PreviousPopupPage", "‹", function()
        self.popupPage = math.max(1, self.popupPage - 1)
        self:_renderPopup()
    end)
    self.popupNext = self:_button(self.popup, "NextPopupPage", "›", function()
        self.popupPage += 1
        self:_renderPopup()
    end)
    self.popupCounter = text(self.popup, "PopupPage", "1 / 1", 11, Dim)
    self.popupCounter.TextXAlignment = Enum.TextXAlignment.Center
    self.dragGhost = W.frame(self.rootFrame, "DraggedSection", Selected)
    self.dragGhost.ZIndex, self.dragGhost.Visible = 30, false
    self.dragLabel = text(self.dragGhost, "DraggedSequence", "", 12, W.amber)
    self.dragLabel.Size = UDim2.new(1, -12, 1, 0)
    self.dragLabel.Position = UDim2.fromOffset(6, 0)
    self:_connect(Input.InputChanged, function(input)
        local drag = self.drag
        if
            not drag
            or (drag.input.UserInputType == Enum.UserInputType.Touch and input ~= drag.input)
            or (
                drag.input.UserInputType ~= Enum.UserInputType.Touch
                and input.UserInputType ~= Enum.UserInputType.MouseMovement
            )
        then
            return
        end
        drag.position = pointer(input)
        drag.moved = drag.moved or (drag.position - drag.origin).Magnitude > 8
        if drag.moved then
            self.dragGhost.Visible = true
            W.set(self.dragLabel, "Text", drag.name)
            local position = drag.position - self.rootFrame.AbsolutePosition
            W.place(self.dragGhost, position.X - 60, position.Y - 16, 120, 32)
        end
    end)
    self:_connect(Input.InputEnded, function(input)
        local drag = self.drag
        if
            not drag
            or (drag.input.UserInputType == Enum.UserInputType.Touch and input ~= drag.input)
            or (
                drag.input.UserInputType ~= Enum.UserInputType.Touch
                and input.UserInputType ~= Enum.UserInputType.MouseButton1
            )
        then
            return
        end
        self.drag, self.dragGhost.Visible = nil, false
        local music = self.state and self.state.music
        if
            not drag.moved
            or not music
            or music.projectId ~= drag.projectId
            or music.draftId ~= drag.draftId
        then
            return
        end
        local top = self.timeline.AbsolutePosition.Y - 8
        local bottom = top + self.timeline.AbsoluteSize.Y + 16
        if drag.position.Y < top or drag.position.Y > bottom then
            return
        end
        local nearest, distance
        for _, card in self.cards do
            if card.stepId then
                local center = card.root.AbsolutePosition.X + card.root.AbsoluteSize.X / 2
                local offset = math.abs(drag.position.X - center)
                if distance == nil or offset < distance then
                    nearest, distance = card.index, offset
                end
            end
        end
        if nearest and nearest ~= drag.sourceIndex then
            self:_command("SongStepMove", { stepId = drag.stepId, index = nearest })
        end
    end)
    self:_connect(self.rootFrame:GetPropertyChangedSignal("Visible"), function()
        if not self.rootFrame.Visible then
            self.drag, self.dragGhost.Visible, self.popup.Visible = nil, false, false
        end
    end)
    self:resize(640, 300)
    self:_render()
    return self
end

function Song:_tools()
    local draft = self.state and self.state.music and self.state.music.draft
    local step, index = self:_step()
    return {
        {
            title = "RENAME DRAFT",
            run = function()
                if draft then
                    self:_name("Rename song draft", draft.name, function(name)
                        self:_command("SongRename", { name = name })
                    end)
                end
            end,
        },
        {
            title = "CHOOSE DRAFT",
            run = function()
                self:_open("drafts")
            end,
        },
        {
            title = "PLAY FROM START",
            run = function()
                self:_command("SongPlay")
            end,
        },
        {
            title = "STOP / RETURN TO START",
            run = function()
                self:_command("Stop")
            end,
        },
        {
            title = "AUDITION SELECTED SECTION",
            run = function()
                if index then
                    self:_command("SongSeek", index)
                end
            end,
        },
        {
            title = "DUPLICATE SECTION",
            run = function()
                if step then
                    self:_selectedCommand("SongStepDuplicate")
                end
            end,
        },
        {
            title = "MOVE SECTION LEFT",
            run = function()
                if step then
                    self:_selectedCommand("SongStepMove", { index = math.max(1, index - 1) })
                end
            end,
        },
        {
            title = "MOVE SECTION RIGHT",
            run = function()
                if step then
                    self:_selectedCommand(
                        "SongStepMove",
                        { index = math.min(#self.summary.steps, index + 1) }
                    )
                end
            end,
        },
        {
            title = "CONVERT TO SEQUENCE",
            run = function()
                if draft then
                    self:_name("Converted sequence name", draft.name .. " sequence", function(name)
                        self:_command("SongConvert", { name = name })
                    end)
                end
            end,
        },
        {
            title = "DUPLICATE DRAFT",
            run = function()
                self:_command("SongDuplicate")
            end,
        },
        {
            title = "DELETE DRAFT / UNDO AVAILABLE",
            run = function()
                self:_command("SongDelete")
            end,
        },
        {
            title = "COPY MY SLEEVE TO DRAFT",
            run = function()
                local music = self.state and self.state.music
                if music then
                    self:_command("LifeCopySleeveToDraft", music.draftId)
                end
            end,
        },
        {
            title = "UNDO",
            run = function()
                self:_command("Undo")
            end,
        },
        {
            title = "REDO",
            run = function()
                self:_command("Redo")
            end,
        },
        {
            title = "FINISHED SONGS / PUBLIC",
            run = function()
                if self.callbacks.page then
                    self.callbacks.page("Library")
                end
            end,
        },
    }
end
function Song:_renderPopup()
    local music = self.state and self.state.music
    local library = music and music.library or {}
    if self.popupMode == "sources" then
        self.popupEntries = library.sequences or {}
    elseif self.popupMode == "drafts" then
        self.popupEntries = library.drafts or {}
    else
        self.popupEntries = self:_tools()
    end
    local pages = math.max(1, math.ceil(#self.popupEntries / 6))
    self.popupPage = math.clamp(self.popupPage, 1, pages)
    W.set(
        self.popupTitle,
        "Text",
        if self.popupMode == "sources"
            then "CHANGE SECTION SOURCE"
            elseif self.popupMode == "drafts" then "CHOOSE SONG DRAFT"
            else "ARRANGEMENT TOOLS"
    )
    for slot, row in self.popupRows do
        local item = self.popupEntries[(self.popupPage - 1) * 6 + slot]
        W.set(row, "Visible", item ~= nil)
        if item then
            W.set(row, "Text", "  " .. (item.title or item.name or "Untitled"))
            row:SetAttribute("SourceId", item.id)
        end
    end
    W.set(self.popupCounter, "Text", tostring(self.popupPage) .. " / " .. tostring(pages))
    self.popupPrevious.Active, self.popupNext.Active = self.popupPage > 1, self.popupPage < pages
end
function Song:_choosePopup(slot)
    local item = self.popupEntries and self.popupEntries[(self.popupPage - 1) * 6 + slot]
    if not item then
        return
    end
    local mode, capturedStep = self.popupMode, self.sourceStepId
    self.popup.Visible = false
    if mode == "sources" then
        if capturedStep then
            self:_command("SongStepUpdate", { stepId = capturedStep, sequenceId = item.id })
        end
    elseif mode == "drafts" then
        self:_command("SongSelect", item.id)
    elseif item.run then
        item.run()
    end
end
function Song:_render()
    local music = self.state and self.state.music or {}
    local draft, summary = music.draft, self.summary
    local steps = summary and summary.steps or {}
    local pageCount = math.max(1, math.ceil(#steps / 4))
    self.pageIndex = math.clamp(self.pageIndex, 1, pageCount)
    if self.selectedStepId and not self:_step() then
        self.selectedStepId = nil
    end
    self.selectedStepId = self.selectedStepId or (steps[1] and steps[1].stepId)
    W.set(self.title, "Text", if draft then draft.name else "NEW SONG / TAP NEW")
    W.set(
        self.overview,
        "Text",
        if summary
            then string.format(
                "%02d SECTIONS   %d BARS   %s TOTAL",
                #steps,
                summary.totalBars,
                seconds(summary.duration)
            )
            else "SEQUENCES → ADD → ARRANGE → FINISH"
    )
    W.set(self.pageLabel, "Text", string.format("%02d / %02d", self.pageIndex, pageCount))
    self.left.Active, self.right.Active = self.pageIndex > 1, self.pageIndex < pageCount
    self.left.TextColor3 = if self.left.Active then W.text else Dim
    self.right.TextColor3 = if self.right.Active then W.text else Dim
    self.empty.Visible = #steps == 0
    for slot, card in self.cards do
        local index = (self.pageIndex - 1) * 4 + slot
        local step = steps[index]
        card.stepId, card.index = step and step.stepId, index
        W.set(card.root, "Visible", step ~= nil)
        if step then
            card.root:SetAttribute("StepId", step.stepId)
            card.root:SetAttribute("SectionIndex", index)
            card.root:SetAttribute(
                "AccessibleLabel",
                "Section " .. index .. ": " .. step.name .. ", repeats " .. step.repeats
            )
            W.set(card.number, "Text", string.format("%02d", index))
            W.set(card.name, "Text", step.name)
            W.set(card.detail, "Text", string.format("%d BAR ×%d", step.bars, step.repeats))
            W.set(
                card.root,
                "BackgroundColor3",
                if step.stepId == self.selectedStepId then Selected else W.ink
            )
            local columns = math.min(16, step.repeats)
            local unit = math.max(1, (card.root.Size.X.Offset - 8) / columns)
            for repeatIndex, block in card.repeats do
                block.Visible = repeatIndex <= step.repeats
                block.Position = UDim2.new(
                    0,
                    4 + (repeatIndex - 1) % 16 * unit,
                    1,
                    -10 - math.floor((repeatIndex - 1) / 16) * 7
                )
                block.Size = UDim2.fromOffset(math.max(1, unit - 2), 5)
                block.BackgroundColor3 = if step.stepId == self.selectedStepId
                    then W.amber
                    else W.text
            end
        end
    end
    local step = self:_step()
    W.set(self.repeatLabel, "Text", if step then "REPEAT ×" .. step.repeats else "NO SECTION")
    W.set(self.source, "Text", if step then "SOURCE · " .. step.name else "SOURCE")
    W.set(self.selected, "Text", if step then "DRAG TO ORDER" else "ADD YOUR FIRST SECTION")
    for _, control in { self.repeatMinus, self.repeatPlus, self.source, self.remove } do
        control.Active, control.Selectable = step ~= nil, step ~= nil
        control.TextColor3 = if step then W.text else Dim
    end
    W.set(
        self.tempoMode,
        "Text",
        if draft and draft.tempoMode == "song" then "MASTER TEMPO" else "SECTION TEMPO"
    )
    W.set(self.bpm, "Text", string.format("%03d BPM", draft and draft.bpm or 96))
    self.bpm.TextColor3 = if draft and draft.tempoMode == "song" then W.amber else Dim
    for name, key in self.keys do
        local enabled = name == "New" or name == "Tools" or draft ~= nil
        if name == "Play" or name == "Finish" then
            enabled = draft ~= nil and #steps > 0
        end
        if name == "Save" or name == "Finish" then
            enabled = enabled and not (self.state and self.state.saving)
        end
        key.Active, key.Selectable = enabled, enabled
        key:SetAttribute("Enabled", enabled)
    end
    self.keys.Save:SetAttribute("Selected", draft ~= nil and draft.savedRevision == draft.revision)
    if self.popup.Visible then
        self:_renderPopup()
    end
    self:tick()
end
function Song:update(state)
    local oldId = self.state and self.state.music and self.state.music.draftId
    self.state, self.summary = state, nil
    local music = state and state.music
    if music then
        for _, summary in music.library and music.library.drafts or {} do
            if summary.id == music.draftId then
                self.summary = summary
                break
            end
        end
        if oldId ~= music.draftId then
            self.pageIndex, self.selectedStepId, self.popup.Visible = 1, nil, false
            self.drag, self.dragGhost.Visible = nil, false
        end
    end
    self:_render()
end
function Song:resize(width, height)
    self.width, self.height = math.max(240, width), math.max(170, height)
    local w, h = self.width, self.height
    local compact = h < 240
    local keyHeight, selectedHeight, tempoHeight =
        if compact then 38 else 44, if compact then 27 else 32, if compact then 24 else 28
    local keyY = h - keyHeight
    local selectedY = keyY - selectedHeight - 4
    local tempoY = selectedY - tempoHeight - 4
    local timelineY = if compact then 43 else 52
    local timelineHeight = math.max(24, tempoY - timelineY - 6)
    W.place(self.title, 6, 3, math.max(60, w - 170), 25)
    W.place(self.drafts, w - 158, 3, 70, 25)
    W.place(self.clock, w - 84, 3, 78, 25)
    W.place(self.overview, 6, 29, w - 104, 17)
    W.place(self.status, w - 98, 29, 92, 17)
    W.place(self.timeline, 5, timelineY, w - 10, timelineHeight)
    local arrow, gap = if w < 400 then 23 else 28, 6
    local cardWidth = (w - 10 - arrow * 2 - gap * 5) / 4
    W.place(self.left, 0, 0, arrow, math.max(24, timelineHeight - 18))
    W.place(self.right, w - 10 - arrow, 0, arrow, math.max(24, timelineHeight - 18))
    W.place(self.pageLabel, 0, timelineHeight - 17, w - 10, 17)
    W.place(self.empty, arrow + gap, 0, w - 10 - 2 * (arrow + gap), timelineHeight - 17)
    for slot, card in self.cards do
        local cardHeight = math.max(24, timelineHeight - 20)
        W.place(card.root, arrow + gap + (slot - 1) * (cardWidth + gap), 0, cardWidth, cardHeight)
        W.place(card.number, 5, 2, cardWidth - 10, if cardHeight < 70 then 16 else 23)
        W.place(
            card.name,
            5,
            if cardHeight < 70 then 19 else 29,
            cardWidth - 10,
            math.max(17, cardHeight - 65)
        )
        W.place(card.detail, 5, math.max(20, cardHeight - 33), cardWidth - 10, 16)
        card.detail.Visible = cardHeight >= 72
        card.number.TextSize = if cardHeight < 70 then 13 else 18
        card.name.TextSize = if cardWidth < 90 then 10 else 12
    end
    W.place(self.tempoMode, 6, tempoY, 112, tempoHeight)
    W.place(self.bpmMinus, 123, tempoY, 28, tempoHeight)
    W.place(self.bpm, 155, tempoY, 74, tempoHeight)
    W.place(self.bpmPlus, 233, tempoY, 28, tempoHeight)
    W.place(self.selected, 267, tempoY, w - 273, tempoHeight)
    self.selected.Visible = w >= 380
    W.place(self.repeatMinus, 6, selectedY, 28, selectedHeight)
    W.place(self.repeatLabel, 36, selectedY, 74, selectedHeight)
    W.place(self.repeatPlus, 112, selectedY, 28, selectedHeight)
    W.place(self.source, 146, selectedY, w - 218, selectedHeight)
    W.place(self.remove, w - 66, selectedY, 60, selectedHeight)
    local keyWidth = (w - 10 - 5 * 4) / 6
    for index, name in { "New", "Add", "Play", "Save", "Finish", "Tools" } do
        W.place(self.keys[name], 5 + (index - 1) * (keyWidth + 4), keyY, keyWidth, keyHeight)
    end
    local popupWidth, popupHeight = math.min(w - 20, 380), math.min(h - 8, 292)
    W.place(self.popup, (w - popupWidth) / 2, (h - popupHeight) / 2, popupWidth, popupHeight)
    W.place(self.popupTitle, 10, 3, popupWidth - 54, 28)
    W.place(self.popupClose, popupWidth - 39, 3, 32, 28)
    local rowHeight = math.max(16, (popupHeight - 68) / 6)
    for slot, row in self.popupRows do
        W.place(row, 8, 34 + (slot - 1) * rowHeight, popupWidth - 16, rowHeight - 2)
    end
    W.place(self.popupPrevious, 8, popupHeight - 29, 38, 24)
    W.place(self.popupCounter, 50, popupHeight - 29, popupWidth - 100, 24)
    W.place(self.popupNext, popupWidth - 46, popupHeight - 29, 38, 24)
    if self.state then
        self:_render()
    end
end
function Song:tick()
    if not self.state then
        return
    end
    local music = self.state.music or {}
    local transport = music.transport
    local active = transport and transport.ref.kind == "song" and transport.ref.id == music.draftId
    local playing = active and transport.playing
    W.legend(self.keys.Play, if playing then "PAUSE" else "PLAY")
    self.keys.Play:SetAttribute("Selected", playing == true)
    local position = 0
    local schedule = if active then transport.schedule else nil
    if schedule then
        position = (transport.offset or 0)
            + (
                if playing
                    then math.max(0, game.Workspace:GetServerTimeNow() - transport.startedAt)
                    else 0
            )
        position = math.clamp(position, 0, schedule.duration)
    end
    W.set(self.clock, "Text", seconds(position))
    W.set(
        self.status,
        "Text",
        if playing then "PLAYING" elseif active and position > 0 then "PAUSED" else "STOPPED"
    )
    local cursor = schedule and Transport.cursor(schedule, position)
    if schedule ~= self.spanSchedule then
        self.spanSchedule, self.playbackSpans = schedule, {}
        for _, section in schedule and schedule.sections or {} do
            if section.stepId then
                local span = self.playbackSpans[section.stepId]
                if span then
                    span.last = section.endAt
                else
                    self.playbackSpans[section.stepId] =
                        { first = section.at, last = section.endAt }
                end
            end
        end
    end
    self.rootFrame:SetAttribute("PlayingStep", cursor and cursor.stepIndex)
    self.rootFrame:SetAttribute(
        "PlaybackProgress",
        if schedule and schedule.duration > 0 then position / schedule.duration else 0
    )
    for _, card in self.cards do
        local span = card.stepId and self.playbackSpans and self.playbackSpans[card.stepId]
        local first, last = span and span.first, span and span.last
        local fraction = if first
                and last
                and last > first
            then math.clamp((position - first) / (last - first), 0, 1)
            else 0
        W.set(card.fill, "Size", UDim2.fromScale(fraction, 1))
        card.root:SetAttribute(
            "Playing",
            cursor ~= nil and cursor.stepIndex == card.index and position < schedule.duration
        )
    end
end
function Song:destroy()
    self.drag = nil
    for _, connection in self.connections do
        connection:Disconnect()
    end
    self.connections = {}
    self.rootFrame:Destroy()
end
return Song
