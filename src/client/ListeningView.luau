-- Bounded native listening deck. Title, cursor, sleeve and hardware keys stay live.
local GuiService = game:GetService("GuiService")
local Input = game:GetService("UserInputService")
local Transport = require(game.ReplicatedStorage.Shared.MusicTransport)
local W = require(script.Parent.DeviceWidgets)
local Skin = require(script.Parent.DeviceSkin)
local View = {}
View.__index = View
local Dim = Color3.fromRGB(117, 147, 112)
local function seconds(value)
    value = math.max(0, math.floor(value or 0))
    return string.format("%02d:%02d", math.floor(value / 60), value % 60)
end
local function label(parent, name, caption, size, color)
    local object = W.label(parent, name, caption, size, color)
    object.TextWrapped, object.TextTruncate = false, Enum.TextTruncate.AtEnd
    object.ZIndex = 12
    return object
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
function View.new(screen, leave, mute)
    local self = setmetatable({ connections = {}, screen = screen }, View)
    self.panel = W.frame(screen, "ListeningSession", W.ink)
    self.panel.Position, self.panel.Size = UDim2.fromOffset(12, 12), UDim2.new(1, -24, 0, 176)
    self.panel.Visible, self.panel.ClipsDescendants, self.panel.ZIndex = false, true, 10
    W.make("UISizeConstraint", self.panel, { MaxSize = Vector2.new(600, 176) })
    W.make("UIStroke", self.panel, { Color = Color3.fromRGB(73, 105, 76), Thickness = 1 })
    self.art = W.frame(self.panel, "PinnedSleeve", Color3.fromRGB(74, 103, 65))
    self.art.ZIndex = 11
    self.sleeve = Skin.image(
        self.art,
        "sleeve-v4",
        { Name = "LocalSleeveGraphic", ScaleType = Enum.ScaleType.Fit, ZIndex = 12 }
    )
    self.art:SetAttribute("ArtworkKind", "local_device_sleeve")
    self.kind = label(self.panel, "ListeningKind", "PUBLIC LISTENING", 10, W.amber)
    self.label = label(self.panel, "ListeningTitle", "", 16, W.text)
    self.performer = label(self.panel, "Performer", "", 11, Dim)
    self.clock = label(self.panel, "DigitalClock", "00:00 / 00:00", 17, W.amber)
    self.detail = label(self.panel, "CurrentSection", "", 11, W.text)
    self.audio = label(self.panel, "AudioStatus", "", 10, Dim)
    self.progress = W.frame(self.panel, "ListeningProgress", Color3.fromRGB(43, 69, 47))
    self.progress.ZIndex = 11
    self.fill = W.frame(self.progress, "ElapsedMusic", W.amber)
    self.fill.Size, self.fill.ZIndex = UDim2.fromScale(0, 1), 12
    self.leave = W.key(self.panel, "LeaveListening", "stop", "LEAVE", leave)
    self.mute = W.key(self.panel, "MuteListening", "sound", "SOUND ON", mute or function() end)
    self.leave.ZIndex, self.mute.ZIndex = 13, 13
    table.insert(
        self.connections,
        self.panel:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            self:_layout()
        end)
    )
    table.insert(
        self.connections,
        screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            self:_resize()
        end)
    )
    self:_resize()
    return self
end
function View:_resize()
    local height = math.min(176, math.max(132, self.screen.AbsoluteSize.Y - 24))
    self.panel.Size = UDim2.new(1, -24, 0, height)
    self:_layout()
end
function View:_layout()
    local width, height = self.panel.AbsoluteSize.X, self.panel.AbsoluteSize.Y
    if width <= 0 or height <= 0 then
        return
    end
    local keyHeight = 44
    local bodyHeight = height - keyHeight - 22
    local artSize = math.max(45, math.min(bodyHeight - 6, if width < 380 then 74 else 102))
    local textX, textWidth = artSize + 20, width - artSize - 30
    W.place(self.art, 10, 9, artSize, artSize)
    W.place(self.kind, textX, 7, textWidth, 13)
    W.place(self.label, textX, 20, textWidth, 23)
    W.place(self.performer, textX, 43, textWidth, 15)
    W.place(self.clock, textX, 58, textWidth, 21)
    W.place(self.detail, textX, 79, textWidth, 16)
    W.place(self.audio, textX, 96, textWidth, 14)
    self.audio.Visible = bodyHeight >= 108
    self.detail.Visible = bodyHeight >= 94
    self.label.TextSize = if width < 380 then 13 else 16
    W.place(self.progress, 10, height - keyHeight - 14, width - 20, 4)
    W.place(self.mute, 8, height - keyHeight - 6, (width - 22) / 2, keyHeight)
    W.place(self.leave, width / 2 + 3, height - keyHeight - 6, (width - 22) / 2, keyHeight)
end
function View:update(session, soundStatus, muted)
    local wasOpen = self.panel.Visible
    self.session, self.soundStatus, self.muted = session, soundStatus, muted
    self.panel.Visible = session ~= nil
    if not session then
        if wasOpen then
            restoreFocus(self.panel)
        end
        return
    end
    if not wasOpen and Input.GamepadEnabled then
        GuiService.SelectedObject = self.leave
    end
    W.legend(self.leave, if session.hosting then "STOP SET" else "LEAVE")
    W.legend(self.mute, if muted then "SOUND MUTED" else "SOUND ON")
    self.mute:SetAttribute("Selected", muted == true)
    W.set(self.label, "Text", session.title or "Untitled")
    W.set(
        self.performer,
        "Text",
        (if session.hosting then "YOUR SET · " else "BY ") .. (session.performer or "Performer")
    )
    W.set(
        self.kind,
        "Text",
        if session.ref and session.ref.kind == "finished"
            then "FINISHED SONG · PUBLIC LISTENING"
            else "SEQUENCE LOOP · PUBLIC LISTENING"
    )
    self.panel:SetAttribute("LocalOnly", session.localOnly == true)
    self:tick()
end
function View:tick()
    local session = self.session
    local schedule = session and session.schedule
    if not schedule then
        return
    end
    local duration = math.max(0, schedule.duration or 0)
    local elapsed =
        math.max(0, workspace:GetServerTimeNow() - session.startedAt + (session.offset or 0))
    local position = if session.loop and duration > 0
        then elapsed % duration
        else math.min(elapsed, duration)
    local cursor = Transport.cursor(schedule, position)
    W.set(self.clock, "Text", seconds(position) .. " / " .. seconds(duration))
    W.set(
        self.detail,
        "Text",
        string.format(
            "%s · %d/%d · BAR %d · %d BPM",
            cursor.sequenceName or "",
            cursor.repetition or 1,
            cursor.repeats or 1,
            cursor.bar or 1,
            cursor.bpm or 96
        )
    )
    local status = self.soundStatus or (if self.muted then "Sound muted" else "Sound on")
    if session.questPerformance then
        local remaining = math.max(
            0,
            math.ceil(
                (session.firstLoopEndsAt or session.startedAt + duration)
                    - workspace:GetServerTimeNow()
            )
        )
        status = "MICA · "
            .. (
                if remaining > 0
                    then tostring(remaining) .. "s TO COMPLETE THIS LOOP"
                    else "COMPLETING LOOP"
            )
    end
    W.set(self.audio, "Text", status)
    self.audio:SetAttribute("AccessibleLabel", status)
    W.set(self.fill, "Size", UDim2.fromScale(if duration > 0 then position / duration else 0, 1))
    self.panel:SetAttribute("PlaybackProgress", if duration > 0 then position / duration else 0)
end
function View:destroy()
    restoreFocus(self.panel)
    for _, connection in self.connections do
        connection:Disconnect()
    end
    self.panel:Destroy()
end
return View
