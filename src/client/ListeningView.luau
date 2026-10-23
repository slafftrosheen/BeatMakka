local Theme = require(game:GetService("ReplicatedStorage").Shared.Theme)
local Gui = require(script.Parent.GuiFactory)
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local ListeningView = {}
ListeningView.__index = ListeningView

function ListeningView.new(screen, leave, mute)
    local self = setmetatable({}, ListeningView)
    local panel = Gui.round(Gui.make("Frame", screen, {
        Name = "ListeningSession",
        Position = UDim2.fromOffset(12, 12),
        Size = UDim2.new(1, -24, 0, 154),
        BackgroundColor3 = Theme.Ink,
        BorderSizePixel = 0,
        Visible = false,
    }))
    Gui.make("UISizeConstraint", panel, { MaxSize = Vector2.new(600, 154) })
    self.panel = panel
    local body = Gui.make("ScrollingFrame", panel, {
        Position = UDim2.fromOffset(12, 8),
        Size = UDim2.new(1, -24, 0, 80),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ScrollBarThickness = 4,
    })
    self.label = Gui.label(body, "", 14, Theme.Cream)
    self.label.Size = UDim2.new(1, -8, 0, 80)
    self.label.AutomaticSize = Enum.AutomaticSize.Y
    self.leave = Gui.button(panel, "Leave listening", leave)
    self.leave.Name = "LeaveListening"
    self.leave.Position = UDim2.fromOffset(12, 98)
    self.leave.Position = UDim2.new(0.5, 6, 0, 98)
    self.leave.Size = UDim2.new(0.5, -18, 0, 44)
    self.mute = Gui.button(panel, "Sound ON", mute or function() end)
    self.mute.Name = "MuteListening"
    self.mute.Position = UDim2.fromOffset(12, 98)
    self.mute.Size = UDim2.new(0.5, -18, 0, 44)
    return self
end

function ListeningView:update(session, soundStatus, muted)
    local wasOpen = self.panel.Visible
    self.session = session
    self.soundStatus = soundStatus
    self.panel.Visible = session ~= nil
    if not session then
        local selected = GuiService.SelectedObject
        if wasOpen and selected and selected:IsDescendantOf(self.panel) then
            local screen = self.panel.Parent
            local station, hud =
                screen:FindFirstChild("Workstation"), screen:FindFirstChild("HubHud")
            GuiService.SelectedObject = if station and station.Visible
                then station.Navigation.Play
                elseif hud and hud.Visible then hud.Sound
                else nil
        end
        return
    end
    if not wasOpen and UserInputService.GamepadEnabled then
        GuiService.SelectedObject = self.leave
    end
    self.leave.Text = if session.hosting then "Stop sharing" else "Leave listening"
    self.mute.Text = if muted then "Sound MUTED" else "Sound ON"
    self.label.Text = string.format(
        "%s / %s\n%s%s",
        if session.hosting then "SHARING YOUR LOOP" else "LISTENING TO " .. session.performer,
        tostring(session.pattern.bpm) .. " BPM",
        soundStatus,
        if session.questPerformance then "\nMica's request: finish one complete loop." else ""
    )
end

function ListeningView:tick()
    local session = self.session
    if session and session.questPerformance then
        local remaining = math.max(
            0,
            math.ceil(session.firstLoopEndsAt - game:GetService("Workspace"):GetServerTimeNow())
        )
        self.label.Text = string.format(
            "SHARING YOUR LOOP / %d BPM\n%s\nMica's request: %s",
            session.pattern.bpm,
            self.soundStatus,
            if remaining > 0
                then tostring(remaining) .. "s to finish this loop."
                else "finishing this loop..."
        )
    end
end

return ListeningView
