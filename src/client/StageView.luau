-- One stage surface for selection, queue, opt-in listening and short performance.
-- All controls are created once. Musical state remains server-owned.
local GuiService = game:GetService("GuiService")
local Input = game:GetService("UserInputService")
local TextService = game:GetService("TextService")
local Set = require(game.ReplicatedStorage.Shared.StreetSet)
local VisualSteps = require(script.Parent.VisualSteps)
local Icons = require(script.Parent.GameIcons)
local W = require(script.Parent.DeviceWidgets)
local Skin = require(script.Parent.DeviceSkin)
local View = {}
View.__index = View
local Dim = Color3.fromRGB(117, 147, 112)
local function seconds(value)
    value = math.max(0, math.floor(value or 0))
    return string.format("%02d:%02d", math.floor(value / 60), value % 60)
end
local function enabled(button, value)
    button.Active, button.Interactable, button.Selectable = value == true, value == true, value == true
    button.TextTransparency = if value then 0 else 0.4
end
local function visible(object)
    while object do
        if object:IsA("GuiObject") and not object.Visible then
            return false
        end
        object = object.Parent
    end
    return true
end
function View:_label(parent, name, caption, size)
    local label = W.label(parent, name, caption, size or 12, W.text)
    label.ZIndex = 17
    return label
end
function View:_button(parent, name, caption, action, iconName)
    local button = W.make("TextButton", parent, {
        Name = name, Text = caption, Font = Enum.Font.Code, TextSize = 12,
        TextColor3 = W.text, BackgroundColor3 = W.ink, BorderSizePixel = 0,
        TextWrapped = true, AutoButtonColor = false, Selectable = true, Active = true, ZIndex = 18,
    })
    button:SetAttribute("AccessibleLabel", caption)
    local icon = Icons.make(button, iconName or Icons.forText(caption) or "arrow", W.text, 20)
    icon.Position, icon.ZIndex = UDim2.new(0, 9, 0.5, -10), 19
    for _, child in icon:GetDescendants() do if child:IsA("GuiObject") then child.ZIndex = 19 end end
    W.make("UIPadding", button, { PaddingLeft = UDim.new(0, 36), PaddingRight = UDim.new(0, 6) })
    button.TextXAlignment = Enum.TextXAlignment.Left
    local ring = W.make("UIStroke", button, {
        Color = Dim, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
    button.SelectionGained:Connect(function()
        ring.Color = W.amber
    end)
    button.SelectionLost:Connect(function()
        ring.Color = Dim
    end)
    button.Activated:Connect(function()
        if button.Active then
            action()
        end
    end)
    return button
end
function View:_caption(button, text)
    W.set(button, "Text", text)
    button:SetAttribute("AccessibleLabel", text)
end
function View:_selected()
    local choices = self.stage and self.stage.available or {}
    return choices[self.choiceIndex or 1]
end
function View:_cycle(direction)
    local choices = self.stage and self.stage.available or {}
    if #choices == 0 then
        return
    end
    self.choiceIndex = ((self.choiceIndex or 1) - 1 + direction) % #choices + 1
    local choice = self:_selected()
    self.selectedRef = { kind = choice.kind, id = choice.id, revision = choice.revision }
    self:_render()
end
function View:_performance(action, values)
    local p = self.stage and self.stage.performance
    if not p then
        return
    end
    local packet = values or {}
    packet.schema, packet.epoch, packet.revision = 1, p.epoch, p.revision
    self.command(action, packet)
end
local function takeKey(take)
    if not take or take.imported or not take.context then return nil end
    local c = take.context
    return table.concat({ take.id, tostring(c.projectId), tostring(c.projectRevision),
        tostring(c.workspaceGeneration), tostring(c.editVersion) }, ":")
end
function View:_takeAction(action)
    local stage = self.stage
    local take = stage and stage.take
    if not take or take.imported or not stage.canManageTake or not self.panel.Visible then return end
    local key, pending = takeKey(take), self.takeConfirmation
    if pending and pending.key == key and pending.action == action and os.clock() < pending.untilAt then
        self.takeConfirmation = nil
        self.command(action, { schema = 1, id = take.id, context = table.clone(take.context) })
        self:_render()
        return
    end
    self.takeConfirmation = { key = key, action = action, untilAt = os.clock() + 5 }
    self.noticeText = if action == "StageTakeKeep"
        then "Press CONFIRM KEEP again: create an unsaved editable draft. Source music stays unchanged."
        else "Press CONFIRM DISCARD again: remove only this temporary recording."
    self.noticeUntil = os.clock() + 5
    self:_render()
end
function View.new(screen, command, mute)
    local self = setmetatable({ command = command, screen = screen, short = true, connections = {}, layers = {}, sources = {}, requests = {} }, View)
    self.panel = W.frame(screen, "CourtyardStage", W.ink)
    self.panel.AnchorPoint, self.panel.Position = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5)
    self.panel.Size, self.panel.Visible = UDim2.new(1, -24, 1, -24), false
    self.panel.ZIndex, self.panel.ClipsDescendants = 14, true
    W.make("UISizeConstraint", self.panel, { MaxSize = Vector2.new(640, 620) })
    Skin.image(self.panel, "bezel-v4", {
        Name = "StageBezel", ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(80, 80, 944, 602), SliceScale = 0.12, ZIndex = 14,
    })
    self.heading = self:_label(self.panel, "StageHeading", "STREET SET / YOUR MUSIC", 14)
    self.heading.TextColor3 = W.amber
    self.scroll = W.make("ScrollingFrame", self.panel, {
        Name = "StageControls", BackgroundTransparency = 1, BorderSizePixel = 0,
        CanvasSize = UDim2.fromOffset(0, 0), ScrollBarThickness = 4,
        ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 15,
    })
    self.flow = VisualSteps.new(self.scroll, { { "CHOOSE", "library" }, { "PREPARE", "flag" }, { "PLAY", "play" } }, 16)
    self.selection = W.frame(self.scroll, "SelectionAndQueue")
    self.sourceLabel = self:_label(self.selection, "SourceTitle", "Choose your own music", 16)
    self.previous = self:_button(self.selection, "PreviousSource", "PREVIOUS", function() self:_cycle(-1) end)
    self.next = self:_button(self.selection, "NextSource", "NEXT", function() self:_cycle(1) end)
    self.mode = self:_button(self.selection, "PerformanceMode", "SPOTLIGHT EXCERPT", function()
        self.short = not self.short
        if not self.short then self.captureTake = false end
        self.takeConfirmation = nil
        self:_render()
    end)
    self.capture = self:_button(self.selection, "CaptureTake", "CAPTURE OFF", function()
        self.captureTake = not self.captureTake
        self.takeConfirmation = nil
        self:_render()
    end)
    self.takeStatus = self:_label(self.selection, "RetainedTake", "", 12)
    self.keepTake = self:_button(self.selection, "KeepTake", "KEEP AS DRAFT", function()
        self:_takeAction("StageTakeKeep")
    end)
    self.discardTake = self:_button(self.selection, "DiscardTake", "DISCARD TAKE", function()
        self:_takeAction("StageTakeDiscard")
    end)
    self.context = self:_label(self.selection, "SourceContext", "", 12)
    self.queue = self:_label(self.selection, "PublicQueue", "", 12)
    self.queueRows = {}
    for index = 1, 4 do
        local row = self:_label(self.selection, "QueuedSet" .. index, "", 12)
        row.BackgroundColor3, row.BackgroundTransparency = Color3.fromRGB(29, 48, 40), 0
        W.make("UIPadding", row, { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) })
        self.queueRows[index] = row
    end
    self.result = self:_label(self.selection, "PreviousSetResult", "", 12)
    self.performance = W.frame(self.scroll, "PerformanceControls")
    self.clock = self:_label(self.performance, "PerformanceClock", "", 16)
    self.current = self:_label(self.performance, "CurrentSection", "", 13)
    self.timeline = W.frame(self.performance, "SetBars")
    self.bars = {}
    for index = 1, 24 do self.bars[index] = W.line(self.timeline, "Bar" .. index, Dim); self.bars[index].ZIndex = 17 end
    self.pending = self:_label(self.performance, "QueuedState", "", 12)
    self.cancelChange = self:_button(self.performance, "CancelTransition", "CANCEL QUEUED CHANGE", function()
        self:_performance("StageTransitionCancel")
    end)
    self.layerHint = self:_label(self.performance, "LayerHint", "LAYERS / CHANGE ON THE NEXT BAR", 11)
    for _, role in Set.RoleOrder do
        self.layers[role] = self:_button(self.performance, "Layer_" .. role, Set.Labels[role], function()
            local p = self.stage and self.stage.performance
            if p then
                self:_performance("StageLayer", { role = role, muted = not p.current.mutes[role] })
            end
        end, ({ drums = "drum", bass = "bass", hook = "sound", harbour = "waves" })[role])
    end
    self.sourceHint = self:_label(self.performance, "PinnedVariations", "SWITCH SECTION / NEXT BAR", 11)
    for index = 1, Set.MaxSources do
        self.sources[index] = self:_button(self.performance, "PinnedSequence" .. index, "", function()
            self:_performance("StageSequence", { source = index })
        end)
    end
    self.requestHint = self:_label(self.performance, "AudienceKind", "NPC AUDIENCE / OPTIONAL REQUESTS", 12)
    for _, kind in Set.RequestOrder do
        self.requests[kind] = self:_button(self.performance, "Request_" .. kind, "", function()
            self:_performance("StageAudienceRequest", { kind = kind })
        end)
    end
    self.suggestion = self:_label(self.performance, "ListenerSuggestion", "", 12)
    self.accept = self:_button(self.performance, "AcceptRequest", "ACCEPT REQUEST", function()
        self:_performance("StageRequestAccept")
    end)
    self.ignore = self:_button(self.performance, "IgnoreRequest", "IGNORE REQUEST", function()
        self:_performance("StageRequestIgnore")
    end)
    self.feedback = self:_label(self.performance, "NpcResponse", "", 12)
    self.helpToggle = self:_button(self.scroll, "StageDetails", "SET + CAPTURE DETAILS", function()
        self.helpOpen = not self.helpOpen
        self:_render()
    end, "hint")
    self.help = self:_label(self.scroll, "StageHelp", "", 12)
    self.notice = self:_label(self.panel, "StageNotice", "", 12)
    self.primary = self:_button(self.panel, "PrimaryStageAction", "PREPARE", function()
        local stage = self.stage
        if not stage then return end
        self.takeConfirmation = nil
        if stage.hosting then
            command("StageStop")
        elseif stage.canStart then
            command("StageStart")
        elseif stage.requesting then
            command("StageCancel")
        else
            local choice = self:_selected()
            if choice then
                command("StagePrepare", {
                    kind = choice.kind, id = choice.id, revision = choice.revision,
                    mode = if self.short then "spotlight" elseif choice.kind == "finished" then "full" else "practice",
                    capture = self.short and self.captureTake == true,
                })
            end
        end
    end)
    self.secondary = self:_button(self.panel, "SecondaryStageAction", "JOIN BY CHOICE", function()
        command(if self.stage and self.stage.canStart then "StageCancel" else "StageJoin")
    end)
    self.mute = self:_button(self.panel, "MuteStage", "SOUND ON", mute or function() end)
    self.close = self:_button(self.panel, "LeaveStage", "LEAVE / EDIT", function() command("StageClose") end)
    local function cancelTake()
        self.takeConfirmation = nil
        if self.stage then self:_render() end
    end
    table.insert(self.connections, Input.WindowFocusReleased:Connect(cancelTake))
    table.insert(self.connections, Input.TextBoxFocused:Connect(cancelTake))
    table.insert(self.connections, screen:GetPropertyChangedSignal("Enabled"):Connect(function()
        if not screen.Enabled then cancelTake() end
    end))
    table.insert(self.connections, self.panel:GetPropertyChangedSignal("Visible"):Connect(function()
        if not self.panel.Visible then cancelTake() end
    end))
    table.insert(self.connections, self.panel:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        self.takeConfirmation = nil
        self:_layout()
    end))
    self.panel.Destroying:Connect(function()
        for _, connection in self.connections do connection:Disconnect() end
    end)
    self:_layout()
    return self
end
function View:_layout()
    local width, height = self.panel.AbsoluteSize.X, self.panel.AbsoluteSize.Y
    if width <= 0 or height <= 0 then return end
    W.place(self.heading, 12, 4, width - 24, 32)
    W.place(self.scroll, 12, 40, width - 24, math.max(0, height - 192))
    W.place(self.notice, 12, height - 148, width - 24, 44)
    local keyWidth = (width - 30) / 2
    W.place(self.primary, 12, height - 100, keyWidth, 44)
    W.place(self.secondary, 18 + keyWidth, height - 100, keyWidth, 44)
    W.place(self.mute, 12, height - 50, keyWidth, 44)
    W.place(self.close, 18 + keyWidth, height - 50, keyWidth, 44)
    local w, y = math.max(0, width - 32), 0
    W.place(self.flow.root, 0, 0, w, 56)
    local live = self.stage and self.stage.performance ~= nil
    self.selection.Visible, self.performance.Visible = not live, live
    local root = if live then self.performance else self.selection
    local function textHeight(control, minimum)
        return math.max(minimum or 24, TextService:GetTextSize(control.Text, control.TextSize,
            control.Font, Vector2.new(math.max(1, w - 16), 100000)).Y + 8)
    end
    local function place(control, h)
        if not control.Visible then return end
        W.place(control, 0, y, w, h or textHeight(control))
        y += (h or textHeight(control)) + 8
    end
    local function pair(a, b)
        if not a.Visible and not b.Visible then return end
        if w < 300 or not a.Visible or not b.Visible then place(a, 48); place(b, 48)
        else
            W.place(a, 0, y, (w - 8) / 2, 48)
            W.place(b, (w + 8) / 2, y, (w - 8) / 2, 48)
            y += 56
        end
    end
    if live then
        place(self.clock, textHeight(self.clock, 28)); place(self.timeline, 12); place(self.current)
        place(self.pending); place(self.cancelChange, 44); place(self.layerHint)
        pair(self.layers.drums, self.layers.bass); pair(self.layers.hook, self.layers.harbour)
        place(self.sourceHint)
        for _, button in self.sources do place(button, 48) end
        place(self.requestHint)
        for _, kind in Set.RequestOrder do place(self.requests[kind], 48) end
        place(self.suggestion); pair(self.accept, self.ignore); place(self.feedback)
    else
        place(self.sourceLabel, textHeight(self.sourceLabel, 40)); pair(self.previous, self.next)
        place(self.mode, 48); place(self.capture, 48); place(self.context)
        place(self.queue)
        for _, row in self.queueRows do place(row, textHeight(row, 48)) end
        place(self.takeStatus); pair(self.keepTake, self.discardTake); place(self.result)
    end
    W.place(root, 0, 64, w, y)
    W.place(self.helpToggle, 0, 64 + y, w, 44)
    self.help.Visible = self.helpOpen == true
    self:_caption(self.helpToggle, if self.helpOpen then "LESS DETAIL" else "SET + CAPTURE DETAILS")
    local helpHeight = if self.helpOpen then textHeight(self.help) else 0
    W.place(self.help, 0, y + 116, w, helpHeight)
    self.scroll.CanvasSize = UDim2.fromOffset(0, y + 120 + helpHeight)
end
function View:_render()
    local stage = self.stage
    if not stage then return end
    local choice = self:_selected()
    local choices = stage.available or {}
    local challenge = choice and choice.kind == "challenge"
    self.flow:update(if stage.hosting or stage.listening or stage.canStart then 3 elseif stage.requesting then 2 else 1)
    if challenge then self.short, self.captureTake = true, false end
    W.set(self.heading, "Text", string.upper(stage.venue or "Courtyard") .. " / " .. (if stage.hosting then "YOUR SET" else "PUBLIC SETS"))
    local pinned = stage.requesting and stage.entries and stage.entries[stage.position]
    W.set(self.sourceLabel, "Text", (pinned and "PINNED / " .. pinned.title or choice and choice.title or "Make a sequence first")
        .. (if pinned then "" else "\n" .. tostring(self.choiceIndex or 0) .. " / " .. #choices))
    local normalMode = if choice and choice.kind == "finished" then "FULL SONG" else "PRACTICE LOOP"
    self:_caption(self.mode, if stage.requesting then "PINNED / " .. string.upper(stage.preparedMode or "SET")
        elseif challenge then "SAME CRATE / 8 BARS" elseif self.short then "SPOTLIGHT / SWITCH" else normalMode .. " / SWITCH")
    W.set(self.context, "Text", if challenge
        then "Your complete eight-bar challenge draft, with its deliberate ending. It remains an editable Draft Song. No take capture or Finished Song label is added."
        elseif self.short
        then "A short, bar-aligned excerpt. Target: 20-40 seconds; exact duration appears after Prepare. Your source Song is never shortened."
        else if normalMode == "FULL SONG" then "Play the accepted Finished Song in full, with its original ending. No excerpt or performance mutations."
        else "Loop the chosen Sequence until you stop. Spotlight adds short-set layer controls; Practice keeps the source unchanged.")
    local contextDetail = self.context.Text
    self.context.Text = if stage.requesting then "PINNED / " .. tostring(stage.preparedMode) .. " / " .. seconds(stage.preparedDuration)
        elseif challenge then "DRAFT / eight-bar ending / source stays editable"
        elseif self.short then "SHORT EXCERPT / source stays intact"
        elseif normalMode == "FULL SONG" then "FULL FINISHED SONG / original ending" else "LOOP / plays until stopped"
    local rows = { if stage.performer then "ON STAGE / " .. stage.performer else "STAGE FREE / SOLO WELCOME" }
    for index, row in self.queueRows do
        local entry = stage.entries and stage.entries[index]
        row.Visible = entry ~= nil
        if entry then row.Text = (if index == stage.position then "YOU / " else index .. " / ") .. entry.performer .. "\n" .. entry.title end
    end
    if stage.requesting then
        table.insert(rows, "PINNED: " .. tostring(stage.preparedMode) .. " / " .. seconds(stage.preparedDuration)
            .. (if stage.preparedCapture then " / CAPTURE ON" else " / CAPTURE OFF"))
    end
    W.set(self.queue, "Text", table.concat(rows, "\n"))
    local result = stage.result
    W.set(self.result, "Text", if result then
        (if result.completed then "SPOTLIGHT FINISHED" else "SET INTERRUPTED") .. " / " .. result.bars .. " bars / " .. seconds(result.duration)
            .. "\n" .. result.count .. " of 3 optional NPC responses. No votes or persistent rewards. Prepare again, or leave and edit your variation."
            .. (if result.captureNotice then "\n" .. result.captureNotice else "")
        else "NPC reactions are authored game feedback, not real fans or votes. Joining another player's audio is always your choice.")
    local resultDetail = self.result.Text
    self.result.Visible = result ~= nil
    if result then self.result.Text = (if result.completed then "SET COMPLETE" else "SET INTERRUPTED") .. " / " .. result.bars .. " BARS"
        .. "\nNPC RESPONSES / " .. result.count .. "/3" .. (if result.captureNotice then "\n" .. result.captureNotice else "") end
    local editable = not stage.requesting and not stage.hosting
    enabled(self.previous, #choices > 1 and editable); enabled(self.next, #choices > 1 and editable)
    enabled(self.mode, choice ~= nil and editable and not challenge)
    local take = stage.take
    local retained = take ~= nil and not take.imported
    if retained then self.captureTake = false end
    local pending = self.takeConfirmation
    if pending and (pending.key ~= takeKey(take) or os.clock() >= pending.untilAt
        or not stage.canManageTake or not self.panel.Visible) then
        self.takeConfirmation, pending = nil, nil
    end
    self:_caption(self.capture, if not self.short then "CAPTURE / SPOTLIGHT ONLY"
        elseif stage.requesting then (if stage.preparedCapture then "CAPTURE ON / PREPARED" else "CAPTURE OFF / PREPARED")
        elseif retained then "TAKE RETAINED / KEEP OR DISCARD BEFORE CAPTURING"
        elseif self.captureTake then "CAPTURE BAR CHANGES / ON"
        else "CAPTURE BAR CHANGES / OFF")
    enabled(self.capture, self.short and editable and not retained and not challenge)
    self:_caption(self.keepTake, if pending and pending.action == "StageTakeKeep" then "CONFIRM KEEP" else "KEEP AS DRAFT")
    self:_caption(self.discardTake, if pending and pending.action == "StageTakeDiscard" then "CONFIRM DISCARD" else "DISCARD TAKE")
    enabled(self.keepTake, retained and stage.canManageTake and not take.saving)
    enabled(self.discardTake, retained and stage.canManageTake)
    self.keepTake.Visible, self.discardTake.Visible = retained, retained
    W.set(self.takeStatus, "Text", if retained then
        "TEMPORARY TAKE / " .. take.bars .. " of " .. take.plannedBars .. " bars / " .. seconds(take.duration)
            .. (if take.partial then " / completed-bar excerpt" else "")
            .. "\nNot saved. Keep as Draft, then Save at the instrument. Lost on leaving this server."
        elseif take and take.imported then
            "DRAFT IMPORTED / " .. take.title .. "\n"
                .. (if not take.inWorkspace then "Not in this workspace: check Undo/Redo or your library."
                    elseif take.saved then (if take.saveMode == "session" then "Saved for this Studio session only." else "Saved by the normal storage path.")
                    else "Unsaved. Leave to your instrument, open SONG and Save. Undo/Redo is available.")
        else "Optional take capture records Spotlight bar changes, not microphone/audio. Keep creates an editable Draft, never an automatic Finished Song.")
    self.takeStatus.Visible = take ~= nil
    self.help.Text = contextDetail .. "\n\n" .. resultDetail
        .. "\n\nCapture records Spotlight bar changes, not audio or microphone. Keep creates an unsaved Draft; save it at your instrument. One-shot tails finish naturally."
    for _, kind in Set.RequestOrder do self.help.Text ..= "\n" .. Set.Requests[kind] end
    local p = stage.performance
    if p then
        local now = workspace:GetServerTimeNow()
        local elapsed = math.clamp(now - p.startedAt, 0, p.duration)
        local bar = math.clamp(math.floor(elapsed * p.bpm / 240) + 1, 1, p.bars)
        for index, marker in self.bars do
            marker.Visible = index <= p.bars
            marker.Position, marker.Size = UDim2.new((index - 1) / p.bars, 0, 0, 2), UDim2.new(1 / p.bars, -3, 0, 8)
            marker.BackgroundColor3 = if index == bar then W.amber elseif index < bar then W.text else Dim
        end
        self.timeline:SetAttribute("AccessibleLabel", "Set bar " .. bar .. " of " .. p.bars)
        local current = if p.pending and now >= p.pending.at then p.pending else p.current
        local source = p.sources[current.source]
        W.set(self.clock, "Text", seconds(elapsed) .. " / " .. seconds(p.duration) .. " · " .. p.bars .. " BARS · " .. p.bpm .. " BPM")
        W.set(self.current, "Text", "SPOTLIGHT EXCERPT / " .. (source and source.title or "")
            .. (if p.localOnly then "\nLocal preview / listening approval pending" else "")
            .. (if stage.hosting and p.capturing then "\nCAPTURING / accepted completed bars only" else ""))
        W.set(self.pending, "Text", if p.pending then
            (if now >= p.pending.at then "APPLIED / awaiting state acknowledgement" elseif now >= p.pending.at - Set.Lead then "COMMITTED" else "QUEUED")
                .. " · bar " .. p.pending.bar .. " / source " .. p.sources[p.pending.source].title
            else "NEXT CHANGE / BAR BOUNDARY")
        self.cancelChange.Visible = p.pending ~= nil
        local canEdit = stage.hosting and not p.pending and now < p.endsAt
        enabled(self.cancelChange, stage.hosting and p.pending ~= nil and now < p.pending.at - Set.Lead)
        for _, role in Set.RoleOrder do
            self:_caption(self.layers[role], Set.Labels[role] .. " / " .. (if not p.roles[role] then "NOT IN SET" elseif current.mutes[role] then "MUTED" else "ON"))
            enabled(self.layers[role], canEdit and p.roles[role] == true)
        end
        for index, button in self.sources do
            local item = p.sources[index]
            button.Visible = item ~= nil
            if item then
                self:_caption(button, (if current.source == index then "CURRENT / " else "QUEUE / ") .. item.title)
                enabled(button, canEdit and index ~= current.source)
            end
        end
        local responses = 0
        for _, kind in Set.RequestOrder do if p.fulfilled[kind] then responses += 1 end end
        W.set(self.requestHint, "Text", if stage.hosting then "NPC RESPONSES / " .. responses .. "/3 / OPTIONAL" else "ASK ONCE / AUTHOR CAN DECLINE")
        for _, kind in Set.RequestOrder do
            local status = if p.fulfilled[kind] then "DONE" elseif p.availableRequests[kind] then "OPTIONAL" else "SOURCE PARTS MISSING"
            local shortRequest = ({ hook = "MAKE ROOM FOR HOOK", bass = "BASS BREAK + RETURN", harbour = "FEATURE HARBOUR" })[kind]
            self:_caption(self.requests[kind], status .. " / " .. shortRequest)
            self.requests[kind].Visible = not stage.hosting
            enabled(self.requests[kind], not stage.hosting and p.canRequest and p.availableRequests[kind] and not p.fulfilled[kind] and now < p.endsAt)
        end
        W.set(self.suggestion, "Text", if p.suggestion then "Listener " .. p.suggestion.name .. " requests: " .. Set.Requests[p.suggestion.kind]
            elseif p.focusRequest then "Accepted request: " .. Set.Requests[p.focusRequest]
            else "No listener request. A real audience is not required.")
        self.suggestion.Visible = p.suggestion ~= nil or p.focusRequest ~= nil
        self.accept.Visible, self.ignore.Visible = stage.hosting and p.suggestion ~= nil, stage.hosting and p.suggestion ~= nil
        enabled(self.accept, stage.hosting and p.suggestion ~= nil); enabled(self.ignore, stage.hosting and p.suggestion ~= nil)
        W.set(self.feedback, "Text", p.feedback)
    end
    self:_caption(self.primary, if stage.hosting then "END SET" elseif stage.canStart then "START TURN"
        elseif stage.requesting then "CANCEL SET" elseif result then "PREPARE AGAIN" else "PREPARE SET")
    enabled(self.primary, stage.hosting or stage.canStart or stage.requesting
        or (choice ~= nil and not (self.short and self.captureTake and retained)))
    self:_caption(self.secondary, if stage.canStart then "CANCEL SET" elseif stage.listening then "LISTENING" else "JOIN BY CHOICE")
    enabled(self.secondary, stage.canStart or (stage.canJoin and not stage.listening))
    local notice = if self.noticeText and os.clock() < self.noticeUntil then self.noticeText
        elseif stage.canStart then "Your turn / start within " .. math.max(0, math.ceil((stage.offerEndsAt or 0) - workspace:GetServerTimeNow())) .. "s"
        elseif stage.listening then self.audioStatus or "Sound and Leave remain available."
        else "Your work stays yours. No tutorial, chores or real audience required."
    W.set(self.notice, "Text", notice)
    self.notice:SetAttribute("AccessibleLabel", notice)
    self:_layout()
end
function View:update(stage, muted, notice, audioStatus)
    local wasOpen = self.panel.Visible
    local oldPerformance = self.stage and self.stage.performance ~= nil
    self.stage, self.audioStatus = stage, audioStatus
    self.panel.Visible = stage ~= nil and stage.open == true
    if not stage then self.takeConfirmation = nil; return end
    local choices = stage.available or {}
    local requested = self.selectedRef or stage.selectedRef
    if self.panel.Visible and not wasOpen and stage.selectedRef then requested = stage.selectedRef end
    self.choiceIndex = 1
    for index, item in choices do
        if requested and requested.kind == item.kind and requested.id == item.id then self.choiceIndex = index; break end
    end
    local choice = self:_selected()
    self.selectedRef = choice and { kind = choice.kind, id = choice.id, revision = choice.revision }
    if notice then self.noticeText, self.noticeUntil = notice, os.clock() + 6 end
    self:_caption(self.mute, if muted then "SOUND MUTED" else "SOUND ON")
    self:_render()
    if oldPerformance ~= (stage.performance ~= nil) then self.scroll.CanvasPosition = Vector2.zero end
    local selected = GuiService.SelectedObject
    if self.panel.Visible and Input.GamepadEnabled and (not wasOpen or not selected
        or not selected:IsDescendantOf(self.panel) or not selected.Selectable or not visible(selected)) then
        GuiService.SelectedObject = if self.primary.Selectable then self.primary elseif self.secondary.Selectable then self.secondary else self.close
    elseif wasOpen and not self.panel.Visible and selected and selected:IsDescendantOf(self.panel) then
        GuiService.SelectedObject = nil
    end
end
function View:destroy()
    local selected = GuiService.SelectedObject
    if selected and selected:IsDescendantOf(self.panel) then GuiService.SelectedObject = nil end
    for _, connection in self.connections do connection:Disconnect() end
    self.panel:Destroy()
end
return View
