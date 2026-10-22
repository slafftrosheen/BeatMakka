local Theme = require(game:GetService("ReplicatedStorage").Shared.Theme)
local Gui = require(script.Parent.GuiFactory)
local ListeningView = {}
ListeningView.__index = ListeningView

function ListeningView.new(screen, leave)
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
    self.label = Gui.label(panel, "", 14, Theme.Cream)
    self.label.Position = UDim2.fromOffset(12, 8)
    self.label.Size = UDim2.new(1, -24, 0, 88)
    self.leave = Gui.button(panel, "Leave listening", leave)
    self.leave.Name = "LeaveListening"
    self.leave.Position = UDim2.fromOffset(12, 98)
    self.leave.Size = UDim2.new(1, -24, 0, 44)
    return self
end

function ListeningView:update(session, soundStatus)
    self.session = session
    self.soundStatus = soundStatus
    self.panel.Visible = session ~= nil
    if not session then
        return
    end
    self.leave.Text = if session.hosting then "Stop sharing" else "Leave listening"
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
