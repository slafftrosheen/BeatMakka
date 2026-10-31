-- Fixed duet channel strips and a paged guide, with one shared jam clock.
local W = require(script.Parent.DeviceWidgets)
local Digital = require(script.Parent.DigitalDisplay)
local GuiService = game:GetService("GuiService")
local TextService = game:GetService("TextService")
local View = {}
View.__index = View
local Dim = Color3.fromRGB(112, 145, 117)
local function caption(key, value)
    W.set(key.Legend, "Text", value)
    W.set(key, "Text", value)
    key.TextTransparency = 1
    key:SetAttribute("AccessibleLabel", value)
end
local function label(parent, name, value, size, color)
    local item = W.label(parent, name, value, size, color)
    item.TextWrapped = false
    item.TextTruncate = Enum.TextTruncate.AtEnd
    return item
end
local function paginate(lines, width, height, size)
    local pages, current = {}, ""
    for _, paragraph in lines do
        local first = true
        for word in paragraph:gmatch("%S+") do
            local separator = if current == "" then "" elseif first then "\n" else " "
            local candidate = current .. separator .. word
            local bounds = TextService:GetTextSize(
                candidate,
                size,
                Enum.Font.Code,
                Vector2.new(math.max(1, width), 100000)
            )
            if current ~= "" and bounds.Y > height then
                table.insert(pages, current)
                current = word
            else
                current = candidate
            end
            first = false
        end
    end
    table.insert(pages, current)
    return pages
end
function View.new(screen, command, mute)
    local self = setmetatable({ page = "session", channels = {}, connections = {} }, View)
    self.panel = W.frame(screen, "TwoPlayerJam", Color3.fromRGB(29, 48, 40))
    self.panel.AnchorPoint, self.panel.Position = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5)
    self.panel.Size, self.panel.Visible, self.panel.ZIndex = UDim2.new(1, -24, 1, -24), false, 20
    self.panel.ClipsDescendants = true
    W.make("UISizeConstraint", self.panel, { MaxSize = Vector2.new(960, 660) })
    W.make("UIStroke", self.panel, { Color = Dim, Thickness = 2 })
    self.heading = label(self.panel, "JamTitle", "QUAY / TWO PLAYER JAM", 16, W.amber)
    self.tempo = Digital.new(self.panel)
    W.make("UIScale", self.tempo.root, { Scale = 0.55 })
    self.tempoLabel = label(self.panel, "SharedTempo", "BPM", 11, W.amber)
    self.info = W.key(self.panel, "JamInfo", "hint", "INFO", function()
        self.page = if self.page == "session" then "info" else "session"
        self:paint()
    end)
    self.body = W.frame(self.panel, "Actions", W.ink)
    self.body.ClipsDescendants = true
    W.make("UIStroke", self.body, { Color = Color3.fromRGB(62, 90, 70), Thickness = 1 })
    self.channelPage = W.frame(self.body, "DuetChannelStrips")
    self.channelPage.Size = UDim2.fromScale(1, 1)
    for slot = 1, 2 do
        local channel = {}
        channel.root = W.frame(self.channelPage, "Player" .. slot, Color3.fromRGB(27, 51, 41))
        W.make("UIStroke", channel.root, { Color = Color3.fromRGB(59, 84, 66), Thickness = 1 })
        channel.number =
            label(channel.root, "PlayerNumber", string.format("PLAYER %02d", slot), 11, W.amber)
        channel.name = label(channel.root, "PlayerName", "OPEN SEAT", 16, W.text)
        channel.source = label(channel.root, "PinnedSequence", "BRING YOUR OWN SECTION", 11, Dim)
        channel.status = label(channel.root, "SnapshotStatus", "WAITING", 10, Dim)
        channel.lamp = W.line(channel.root, "PendingLight", Dim)
        W.make("UICorner", channel.lamp, { CornerRadius = UDim.new(1, 0) })
        self.channels[slot] = channel
    end
    self.label = W.label(self.body, "JamGuide", "", 12, W.text)
    self.label.TextYAlignment, self.label.TextTruncate =
        Enum.TextYAlignment.Top, Enum.TextTruncate.AtEnd
    self.label.Visible = false
    self.infoPageIndex = 1
    self.infoPrevious = W.key(self.body, "PreviousInfoPage", "undo", "BACK", function()
        self.infoPageIndex = math.max(1, self.infoPageIndex - 1)
        self:paintInfo()
    end)
    self.infoNext = W.key(self.body, "NextInfoPage", "redo", "MORE", function()
        self.infoPageIndex += 1
        self:paintInfo()
    end)
    self.infoCounter = label(self.body, "InfoPageCount", "1 / 1", 11, Dim)
    self.infoCounter.TextXAlignment = Enum.TextXAlignment.Center
    self.noticeLine = label(self.panel, "JamNotice", "", 11, Dim)
    self.keys = W.frame(self.panel, "JamHardwareKeys")
    local function key(name, icon, title, action, value)
        return W.key(self.keys, name, icon, title, function()
            command(action, value)
        end)
    end
    self.join = key("Join", "people", "JOIN", "JamJoin")
    self.publish = key("Publish", "save", "PUBLISH", "JamPublish")
    self.down = key("TempoDown", "undo", "BPM −", "JamTempo", -1)
    self.up = key("TempoUp", "redo", "BPM +", "JamTempo", 1)
    self.leave = key("Leave", "close", "LEAVE JAM", "JamLeave")
    self.mute = W.key(self.panel, "Sound", "sound", "SOUND ON", mute)
    self.close = W.key(self.panel, "Back", "pads", "SAMPLER", function()
        command("JamHide")
    end)
    table.insert(
        self.connections,
        self.panel:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            self:resize()
        end)
    )
    self.panel.Destroying:Connect(function()
        for _, connection in self.connections do
            connection:Disconnect()
        end
    end)
    self:resize()
    self:paint()
    task.defer(function()
        if self.panel.Parent then
            self:resize()
        end
    end)
    return self
end
function View:paint()
    local jam = self.jam or {}
    local session = jam.session
    self.tempo:set(session and session.bpm or 96)
    self.tempoLabel.Text = if jam.active and jam.conductor then "YOUR BPM" else "SHARED BPM"
    self.tempoLabel:SetAttribute("BPM", session and session.bpm or 96)
    local lines = {
        "TWO PLAYERS / 64-PAD PROGRAMS / ONE SHARED CLOCK",
        "Your project stays yours. Personal playback and recording pause while joined.",
    }
    for slot, channel in self.channels do
        local track = session and session.tracks and session.tracks[tostring(slot)]
        local pending = session and session.pending and session.pending[tostring(slot)]
        local source = track and track.snapshot and track.snapshot.title
        W.set(channel.name, "Text", track and track.name or "OPEN SEAT")
        W.set(
            channel.source,
            "Text",
            source or (if track then "PINNED SEQUENCE" else "BRING YOUR OWN SECTION")
        )
        W.set(
            channel.status,
            "Text",
            if pending
                then "NEXT BAR QUEUED"
                elseif track then "PLAYING PINNED COPY"
                else "WAITING FOR A PLAYER"
        )
        W.set(
            channel.lamp,
            "BackgroundColor3",
            if pending then W.amber elseif track then W.text else Dim
        )
        channel.root:SetAttribute("Occupied", track ~= nil)
        channel.root:SetAttribute("Pending", pending ~= nil)
        table.insert(
            lines,
            string.format(
                "PLAYER %d / %s%s%s",
                slot,
                track and track.name or "FREE",
                if source then " / " .. source else "",
                if pending then " / NEXT BAR QUEUED" else ""
            )
        )
    end
    table.insert(
        lines,
        if session
            then string.format(
                "%d BPM / %s",
                session.bpm,
                if jam.conductor then "YOU CONDUCT THE TEMPO" else "YOUR PARTNER CONDUCTS"
            )
            else "Select a named Sequence with available audio, then join."
    )
    if session and session.tempo then
        table.insert(lines, "TEMPO QUEUED / " .. session.tempo.bpm .. " BPM")
    end
    table.insert(
        lines,
        "Edit your Sequence in the sampler, then Publish a pinned copy for the next bar. Source Sequence tempos are retained."
    )
    local notice = if self.notice and os.clock() < self.untilAt then self.notice else nil
    if notice then
        table.insert(lines, notice)
    end
    self.infoLines = lines
    W.set(
        self.noticeLine,
        "Text",
        notice
            or (
                if session and session.tempo
                    then "NEXT BAR / " .. session.tempo.bpm .. " BPM QUEUED"
                    elseif jam.active then "EDIT YOUR SECTION → PUBLISH AT THE NEXT BAR"
                    else "SELECT YOUR SECTION IN THE SAMPLER → JOIN"
            )
    )
    self.join.Visible, self.publish.Visible = not jam.active, jam.active == true
    self.down.Visible, self.up.Visible =
        jam.active == true and jam.conductor == true, jam.active == true and jam.conductor == true
    self.leave.Visible = jam.active == true
    self.channelPage.Visible, self.label.Visible = self.page == "session", self.page == "info"
    self.infoPrevious.Visible, self.infoNext.Visible, self.infoCounter.Visible =
        self.page == "info", self.page == "info", self.page == "info"
    caption(self.info, if self.page == "info" then "DUET" else "INFO")
    self.info:SetAttribute("Selected", self.page == "info")
    self:paintInfo()
end
function View:paintInfo()
    local pages = paginate(
        self.infoLines or {},
        self.label.AbsoluteSize.X,
        math.max(1, self.label.AbsoluteSize.Y),
        self.label.TextSize
    )
    self.infoPageIndex = math.clamp(self.infoPageIndex, 1, #pages)
    W.set(self.label, "Text", pages[self.infoPageIndex])
    W.set(self.infoCounter, "Text", string.format("%d / %d", self.infoPageIndex, #pages))
    self.infoPrevious.Active, self.infoPrevious.Selectable =
        self.infoPageIndex > 1, self.infoPageIndex > 1
    self.infoNext.Active, self.infoNext.Selectable =
        self.infoPageIndex < #pages, self.infoPageIndex < #pages
end
function View:update(jam, muted, notice)
    local wasOpen = self.panel.Visible
    self.jam = jam
    self.panel.Visible = jam ~= nil and jam.open == true
    if notice then
        self.notice, self.untilAt = notice, os.clock() + 6
    end
    caption(self.mute, if muted then "SOUND MUTED" else "SOUND ON")
    self:paint()
    local selected = GuiService.SelectedObject
    if wasOpen and not self.panel.Visible and selected and selected:IsDescendantOf(self.panel) then
        local station = self.panel.Parent:FindFirstChild("Workstation")
        local navigation = station and station:FindFirstChild("Navigation", true)
        GuiService.SelectedObject = if station
                and station.Visible
                and navigation
            then navigation:FindFirstChild("Sequence")
            else nil
    elseif
        self.panel.Visible
        and (
            not wasOpen
            or (selected and selected:IsDescendantOf(self.panel) and not selected.Visible)
        )
    then
        GuiService.SelectedObject = if jam.active then self.publish else self.join
    end
end
function View:resize()
    local w, h = self.panel.AbsoluteSize.X, self.panel.AbsoluteSize.Y
    if w <= 0 or h <= 0 then
        return
    end
    local margin, gap = 10, 6
    local footerY, actionY = h - 54, h - 104
    W.place(self.heading, margin, 7, math.max(1, w - 208), 30)
    self.heading.TextSize = if w < 400 then 11 else 16
    W.place(self.tempo.root, w - 190, 7, 114, 48)
    W.place(self.tempoLabel, w - 121, 10, 57, 26)
    self.tempoLabel.TextSize = 9
    W.place(self.info, w - 60, 5, 50, 36)
    local bw, bh = w - margin * 2, math.max(1, actionY - 72)
    W.place(self.body, margin, 46, bw, bh)
    local vertical = w < 450 and bh >= 170
    local cw, ch =
        if vertical then bw - 12 else (bw - 18) / 2, if vertical then (bh - 18) / 2 else bh - 12
    for slot, channel in self.channels do
        W.place(
            channel.root,
            if vertical then 6 else 6 + (slot - 1) * (cw + 6),
            if vertical then 6 + (slot - 1) * (ch + 6) else 6,
            cw,
            ch
        )
        W.place(channel.number, 8, 5, cw - 24, 15)
        W.place(channel.lamp, cw - 14, 9, 5, 5)
        W.place(channel.name, 8, 23, cw - 16, if ch < 100 then 21 else 30)
        W.place(channel.source, 8, if ch < 100 then 46 else 59, cw - 16, 17)
        W.place(channel.status, 8, ch - 22, cw - 16, 17)
        channel.name.TextSize = if cw < 200 then 12 else 16
        channel.source.Visible = ch >= 93
        channel.status.Visible = ch >= 60
    end
    local compactInfo = bh < 90
    local infoNavHeight = if compactInfo then 22 else 40
    local infoNavY = bh - infoNavHeight - (if compactInfo then 2 else 6)
    local infoTextY = if compactInfo then 1 else 6
    W.place(self.label, 8, infoTextY, bw - 16, math.max(1, infoNavY - infoTextY - 2))
    self.label.TextSize = if h < 330 then 10 else 12
    W.place(self.infoPrevious, 6, infoNavY, 58, infoNavHeight)
    W.place(self.infoNext, bw - 64, infoNavY, 58, infoNavHeight)
    W.place(self.infoCounter, 68, infoNavY, bw - 136, infoNavHeight)
    for _, key in { self.infoPrevious, self.infoNext } do
        key.Glyph.Visible = not compactInfo
        key.Legend.Position = if compactInfo then UDim2.fromScale(0, 0) else UDim2.fromOffset(2, 24)
        key.Legend.Size = if compactInfo then UDim2.fromScale(1, 1) else UDim2.new(1, -4, 1, -25)
    end
    W.place(self.noticeLine, margin, actionY - 22, w - margin * 2, 18)
    W.place(self.keys, margin, actionY, w - margin * 2, 44)
    local keyWidth = (w - margin * 2 - gap * 3) / 4
    W.place(self.join, 0, 0, keyWidth, 44)
    W.place(self.publish, 0, 0, keyWidth, 44)
    W.place(self.down, keyWidth + gap, 0, keyWidth, 44)
    W.place(self.up, (keyWidth + gap) * 2, 0, keyWidth, 44)
    W.place(self.leave, (keyWidth + gap) * 3, 0, keyWidth, 44)
    W.place(self.mute, margin, footerY, (w - margin * 2 - gap) / 2, 44)
    W.place(self.close, (w + gap) / 2, footerY, (w - margin * 2 - gap) / 2, 44)
    self:paintInfo()
end
return View
