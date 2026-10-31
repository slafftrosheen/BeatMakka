-- Lantern Room hardware display. Every control is allocated once.
local W = require(script.Parent.DeviceWidgets)
local Skin = require(script.Parent.DeviceSkin)
local GuiService = game:GetService("GuiService")
local TextService = game:GetService("TextService")
local View = {}
View.__index = View
local Dim = Color3.fromRGB(115, 147, 119)
local function caption(key, value)
    W.set(key.Legend, "Text", value)
    W.set(key, "Text", value)
    key.TextTransparency = 1
    key:SetAttribute("AccessibleLabel", value)
end
local function enabled(key, value)
    key.Active, key.Selectable = value == true, value == true
    key:SetAttribute("Enabled", value == true)
    key.Legend.TextTransparency = if value then 0 else 0.45
end
local function time(value)
    local seconds = math.max(0, math.floor(tonumber(value) or 0))
    return string.format("%02d:%02d", math.floor(seconds / 60), seconds % 60)
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
    local self = setmetatable({ index = 1, connections = {}, segments = {}, page = "song" }, View)
    self.panel = W.frame(screen, "ChapterConcert", Color3.fromRGB(29, 48, 40))
    self.panel.AnchorPoint, self.panel.Position = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5)
    self.panel.Size, self.panel.Visible, self.panel.ZIndex = UDim2.new(1, -24, 1, -24), false, 20
    self.panel.ClipsDescendants = true
    W.make("UISizeConstraint", self.panel, { MaxSize = Vector2.new(960, 660) })
    W.make("UIStroke", self.panel, { Color = Dim, Thickness = 2 })
    self.heading = label(self.panel, "RoomTitle", "THE LANTERN ROOM", 16, W.amber)
    self.clock = label(self.panel, "PerformanceClock", "00:00", 23, W.amber)
    self.clock.TextXAlignment = Enum.TextXAlignment.Right
    self.info = W.key(self.panel, "RoomInfo", "hint", "INFO", function()
        self.page = if self.page == "song" then "info" else "song"
        self:refresh()
    end)
    self.body = W.frame(self.panel, "FinishedSongPerformance", W.ink)
    self.body.ClipsDescendants = true
    W.make("UIStroke", self.body, { Color = Color3.fromRGB(62, 90, 70), Thickness = 1 })
    self.songPage = W.frame(self.body, "SavedSongDisplay")
    self.songPage.Size = UDim2.fromScale(1, 1)
    self.song = W.make("TextButton", self.songPage, {
        Name = "Choose Finished Song",
        Text = "",
        TextTransparency = 1,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Selectable = true,
        AutoButtonColor = false,
    })
    self.cover = W.frame(self.song, "SavedSleeve", Color3.fromRGB(99, 126, 88))
    local disc = W.frame(self.cover, "Vinyl", W.ink)
    disc.Position, disc.Size = UDim2.fromScale(0.12, 0.12), UDim2.fromScale(0.76, 0.76)
    W.make("UICorner", disc, { CornerRadius = UDim.new(1, 0) })
    local center = W.frame(disc, "Label", W.amber)
    center.AnchorPoint, center.Position, center.Size =
        Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.25, 0.25)
    W.make("UICorner", center, { CornerRadius = UDim.new(1, 0) })
    Skin.image(self.cover, "sleeve-v4", { Name = "SleeveArtwork", ScaleType = Enum.ScaleType.Fit })
    self.sourceCode = label(self.song, "SavedRevision", "SAVED SONG / 00", 11, Dim)
    self.songTitle = label(self.song, "SongTitle", "FINISH YOUR FIRST SONG", 16, W.text)
    self.songDetail = label(self.song, "Readiness", "OPEN SONG IN THE ROAMER", 11, Dim)
    local function browse(delta)
        local songs = self.state and self.state.songs or {}
        if #songs > 0 then
            self.index = (self.index - 1 + delta) % #songs + 1
        end
        self:refresh()
    end
    table.insert(
        self.connections,
        self.song.Activated:Connect(function()
            browse(1)
        end)
    )
    self.previous = W.key(self.songPage, "PreviousSavedSong", "undo", "PREV", function()
        browse(-1)
    end)
    self.next = W.key(self.songPage, "NextSavedSong", "redo", "NEXT", function()
        browse(1)
    end)
    self.progress = W.frame(self.songPage, "SongProgress")
    for index = 1, 24 do
        self.segments[index] = W.line(self.progress, "Bar" .. index, Color3.fromRGB(46, 70, 55))
    end
    self.section = label(self.songPage, "CurrentSection", "CHOOSE A SAVED REVISION", 11, Dim)
    self.label = W.label(self.body, "RoomInformation", "", 12, W.text)
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
    self.noticeLine = label(self.panel, "ProgressNotice", "", 11, Dim)
    self.actions = W.frame(self.panel, "PerformanceKeys")
    self.select = W.key(self.actions, "Select this saved revision", "check", "SELECT", function()
        local song = self.state and (self.state.songs or {})[self.index]
        if song then
            command("ChapterSelect", { id = song.id, revision = song.revision })
        end
    end)
    self.start = W.key(self.actions, "Perform from the beginning", "play", "PERFORM", function()
        local song = self.state and (self.state.songs or {})[self.index]
        if song then
            command("ChapterStart", { id = song.id, revision = song.revision })
        end
    end)
    self.pause = W.key(self.actions, "Pause", "pause", "PAUSE", function()
        command(if self.state and self.state.paused then "ChapterResume" else "ChapterPause")
    end)
    self.action = self.pause
    self.save = W.key(self.actions, "Retry progress save", "save", "SAVE", function()
        command("ChapterSave")
    end)
    self.mute = W.key(self.panel, "Sound", "sound", "SOUND ON", mute)
    self.close = W.key(self.panel, "Leave / stop song", "close", "LEAVE / STOP", function()
        command("ChapterClose")
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
    self:refresh()
    task.defer(function()
        if self.panel.Parent then
            self:resize()
        end
    end)
    return self
end
function View:refresh()
    local state = self.state or {}
    local songs = state.songs or {}
    self.index = math.clamp(self.index, 1, math.max(1, #songs))
    local song = songs[self.index]
    local selected = song ~= nil and song.id == state.selectedFinishedSongId
    self.song.Text = if song
        then song.title .. " / revision " .. song.revision
        else "No Finished Songs yet"
    W.set(self.songTitle, "Text", song and song.title or "FINISH YOUR FIRST SONG")
    W.set(
        self.sourceCode,
        "Text",
        string.format("SAVED SONG %02d / %02d", if song then self.index else 0, #songs)
    )
    W.set(
        self.songDetail,
        "Text",
        if song
            then string.format(
                "REV %d / %s / %s",
                song.revision,
                time(song.duration),
                if selected then "SELECTED" elseif song.ready then "READY" else "AUDIO PENDING"
            )
            else "ARRANGE, FINISH & SAVE IN YOUR ROAMER"
    )
    self.songDetail.TextColor3 = if song and song.ready then W.text else Dim
    caption(self.select, if selected then "SELECTED" else "SELECT")
    caption(self.start, if state.finishedSongId then "RESTART" else "PERFORM")
    caption(self.pause, if state.paused then "RESUME" else "PAUSE")
    caption(self.info, if self.page == "info" then "SONG" else "INFO")
    enabled(self.previous, #songs > 1)
    enabled(self.next, #songs > 1)
    enabled(self.select, song ~= nil and song.ready == true)
    enabled(self.start, state.eligible == true and song ~= nil and song.ready == true and selected)
    enabled(self.pause, state.finishedSongId ~= nil and not state.ended)
    enabled(self.save, not self.saving)
    self.pause.Visible = state.finishedSongId ~= nil and not state.ended
    self.songPage.Visible, self.label.Visible = self.page == "song", self.page == "info"
    self.infoPrevious.Visible, self.infoNext.Visible, self.infoCounter.Visible =
        self.page == "info", self.page == "info", self.page == "info"
    self.info:SetAttribute("Selected", self.page == "info")
    W.set(self.clock, "Text", time(state.position))
    local section = state.section
    W.set(
        self.section,
        "Text",
        if section
            then section.name .. " / REPEAT " .. tostring(section.repetition)
            elseif state.ended then "YOUR SONG REACHED ITS END"
            else "BEGINNING → YOUR ARRANGEMENT → LAST SOUND"
    )
    local progress = math.clamp(state.progress or 0, 0, 1)
    for index, segment in self.segments do
        W.set(
            segment,
            "BackgroundColor3",
            if index <= math.floor(progress * 24) then W.amber else Color3.fromRGB(46, 70, 55)
        )
    end
    local saveStatus = if self.saveMode == "session"
        then "STUDIO SESSION ONLY"
        elseif self.saveMode == "unavailable" then "TEMPORARY / SAVING UNAVAILABLE"
        elseif self.saving then "SAVING PROGRESS"
        elseif self.dirty then "UNSAVED PROGRESS"
        else "SAVED PROFILE"
    local notice = if self.notice and os.clock() < self.noticeUntil then self.notice else nil
    W.set(self.noticeLine, "Text", if notice then notice .. " / " .. saveStatus else saveStatus)
    self.infoLines = {
        notice or "",
        saveStatus,
        state.hint or "Choose your saved Finished Song.",
        if state.title
            then state.title .. " / REV " .. tostring(state.revision)
            else "Your immutable saved arrangement plays from its beginning.",
        time(state.position) .. " / " .. time(state.duration) .. " / " .. math.floor(
            progress * 100
        ) .. "%",
        if state.cue then "THE ROOM / " .. state.cue else "Pause, resume or leave at any time.",
        if not state.eligible
            then "Meet Ronan after your neighbourhood route to perform."
            else "YOUR FINISHED SONG / READY TO PERFORM",
        if song and not song.ready
            then song.reason or "Audio is not ready for this saved revision."
            else "",
    }
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
    enabled(self.infoPrevious, self.infoPageIndex > 1)
    enabled(self.infoNext, self.infoPageIndex < #pages)
end
function View:update(state, saveMode, muted, notice, saving, dirty)
    local wasOpen = self.panel.Visible
    self.state, self.saveMode, self.saving, self.dirty = state, saveMode, saving, dirty
    self.panel.Visible = state ~= nil and state.open == true
    if notice then
        self.notice, self.noticeUntil = notice, os.clock() + 6
    end
    if state and state.selectedFinishedSongId ~= self.lastSelectedId then
        self.lastSelectedId = state.selectedFinishedSongId
        for index, song in state.songs or {} do
            if song.id == state.selectedFinishedSongId then
                self.index = index
                break
            end
        end
    end
    caption(self.mute, if muted then "SOUND MUTED" else "SOUND ON")
    self:refresh()
    local selected = GuiService.SelectedObject
    if wasOpen and not self.panel.Visible and selected and selected:IsDescendantOf(self.panel) then
        local station = self.panel.Parent:FindFirstChild("Workstation")
        local navigation = station and station:FindFirstChild("Navigation", true)
        GuiService.SelectedObject = if station
                and station.Visible
                and navigation
            then navigation:FindFirstChild("Sequence")
            else nil
    elseif self.panel.Visible and not wasOpen then
        GuiService.SelectedObject = if self.start.Active then self.start else self.song
    end
end
function View:resize()
    local w, h = self.panel.AbsoluteSize.X, self.panel.AbsoluteSize.Y
    if w <= 0 or h <= 0 then
        return
    end
    local margin, gap = 10, 6
    local footerY, actionY = h - 54, h - 104
    W.place(self.heading, margin, 7, math.max(1, w - 188), 30)
    self.heading.TextSize = if w < 400 then 12 else 16
    W.place(self.clock, w - 170, 7, 103, 30)
    W.place(self.info, w - 60, 5, 50, 36)
    local bw, bh = w - margin * 2, math.max(1, actionY - 72)
    W.place(self.body, margin, 46, bw, bh)
    local art = math.max(24, math.min(bh - 32, 112))
    W.place(self.song, 6, 5, bw - 12, math.max(1, bh - 31))
    W.place(self.cover, 0, 0, art, art)
    W.place(self.sourceCode, art + 10, 0, bw - art - 115, 17)
    W.place(self.songTitle, art + 10, 18, bw - art - 115, if bh < 130 then 21 else 32)
    W.place(self.songDetail, art + 10, if bh < 130 then 40 else 56, bw - art - 115, 18)
    self.songTitle.TextSize = if bw < 400 then 12 else 16
    self.songDetail.Visible = bh >= 100
    if bh < 120 then
        W.place(self.previous, bw - 88, 4, 38, 44)
        W.place(self.next, bw - 46, 4, 38, 44)
    else
        W.place(self.previous, bw - 60, 4, 54, math.max(30, (bh - 32) / 2))
        W.place(
            self.next,
            bw - 60,
            6 + math.max(30, (bh - 32) / 2),
            54,
            math.max(30, (bh - 32) / 2)
        )
    end
    W.place(self.progress, 6, bh - 24, bw - 12, 8)
    for index, segment in self.segments do
        W.place(segment, (index - 1) * (bw - 12) / 24, 0, (bw - 12) / 24 - 2, 7)
    end
    W.place(self.section, 6, bh - 15, bw - 12, 14)
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
    W.place(self.actions, margin, actionY, w - margin * 2, 44)
    local keyWidth = (w - margin * 2 - gap * 3) / 4
    for index, key in { self.select, self.start, self.pause, self.save } do
        W.place(key, (index - 1) * (keyWidth + gap), 0, keyWidth, 44)
    end
    W.place(self.mute, margin, footerY, (w - margin * 2 - gap) / 2, 44)
    W.place(self.close, (w + gap) / 2, footerY, (w - margin * 2 - gap) / 2, 44)
    self:paintInfo()
end
return View
