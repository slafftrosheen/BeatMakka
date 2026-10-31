local Gui = require(script.Parent.GuiFactory)
local Theme = require(game.ReplicatedStorage.Shared.Theme)
local Catalog = require(game.ReplicatedStorage.Shared.SampleCatalog)
local GuiService = game:GetService("GuiService")
local View = {}
View.__index = View

function View.new(screen, command, mute)
    local self = setmetatable({}, View)
    self.panel = Gui.round(Gui.make("Frame", screen, {
        Name = "TwoPlayerJam",
        Position = UDim2.fromOffset(12, 12),
        Size = UDim2.new(1, -24, 1, -24),
        BackgroundColor3 = Theme.Ink,
        Visible = false,
        ZIndex = 20,
    }))
    Gui.make("UISizeConstraint", self.panel, { MaxSize = Vector2.new(600, 640) })
    local body = Gui.make("ScrollingFrame", self.panel, {
        Name = "Actions",
        Position = UDim2.fromOffset(12, 8),
        Size = UDim2.new(1, -24, 1, -72),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(),
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ScrollBarThickness = 4,
    })
    Gui.make(
        "UIListLayout",
        body,
        { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) }
    )
    self.label = Gui.label(body, "TWO-PLAYER JAM", 14, Theme.Cream)
    self.label.Size = UDim2.new(1, -8, 0, 160)
    self.label.AutomaticSize = Enum.AutomaticSize.Y
    local function button(name, text, order, action, value)
        local b = Gui.button(body, text, function()
            command(action, value)
        end)
        b.Name, b.LayoutOrder = name, order
        b.Size = UDim2.new(1, -8, 0, 48)
        return b
    end
    self.join = button("Join", "Join with my active pattern", 1, "JamJoin")
    self.publish = button("Publish", "Publish my changes at next bar", 2, "JamPublish")
    self.down = button("TempoDown", "Shared tempo −", 3, "JamTempo", -1)
    self.up = button("TempoUp", "Shared tempo +", 4, "JamTempo", 1)
    self.leave = button("Leave", "Leave jam / keep my pattern", 5, "JamLeave")
    self.mute = Gui.button(self.panel, "Sound ON", mute)
    self.mute.Name = "Sound"
    self.mute.Position = UDim2.new(0, 12, 1, -56)
    self.mute.Size = UDim2.new(0.5, -18, 0, 44)
    self.close = Gui.button(self.panel, "Back to sampler", function()
        command("JamHide")
    end)
    self.close.Name = "Back"
    self.close.Position = UDim2.new(0.5, 6, 1, -56)
    self.close.Size = UDim2.new(0.5, -18, 0, 44)
    return self
end

function View:update(jam, muted, notice)
    local wasOpen = self.panel.Visible
    self.panel.Visible = jam ~= nil and jam.open == true
    local selected = GuiService.SelectedObject
    if wasOpen and not self.panel.Visible and selected and selected:IsDescendantOf(self.panel) then
        local station = self.panel.Parent:FindFirstChild("Workstation")
        GuiService.SelectedObject = if station and station.Visible
            then station.Navigation.Play
            else nil
    end
    if notice then
        self.notice, self.untilAt = notice, os.clock() + 6
    end
    if not jam then
        return
    end
    local s = jam.session
    local lines =
        { "TWO-PLAYER JAM", "Two owned tracks · one shared clock · changes join on a bar." }
    if s then
        local kit = Catalog.PackById[s.pack]
        table.insert(lines, string.format("%s · %s · %d BPM", kit.label, kit.key, s.bpm))
        for slot = 1, 2 do
            local t, pending = s.tracks[tostring(slot)], s.pending[tostring(slot)]
            table.insert(
                lines,
                if t
                    then string.format(
                        "Track %d: %s%s",
                        slot,
                        t.name,
                        if pending then " · next bar queued" else ""
                    )
                    else "Track " .. slot .. ": free"
            )
        end
        table.insert(
            lines,
            if jam.conductor
                then "You conduct shared tempo."
                else "Your partner conducts shared tempo."
        )
        if s.tempo then
            table.insert(lines, "Shared tempo queued: " .. s.tempo.bpm .. " BPM.")
        end
    else
        table.insert(
            lines,
            "Prepare notes on 1–4 unmuted pads from a fully uploaded style kit. Both partners use the same kit/key."
        )
    end
    table.insert(
        lines,
        "Your working pattern stays yours. Solo play, live pad audition and recording pause during the jam. Edit notes, then Publish."
    )
    if self.notice and os.clock() < self.untilAt then
        table.insert(lines, self.notice)
    end
    self.label.Text = table.concat(lines, "\n")
    self.join.Visible = not jam.active
    self.publish.Visible = jam.active
    self.down.Visible = jam.active and jam.conductor
    self.up.Visible = self.down.Visible
    self.leave.Visible = jam.active
    self.mute.Text = if muted then "Sound MUTED" else "Sound ON"
    if
        self.panel.Visible
        and (
            not wasOpen
            or (selected and selected:IsDescendantOf(self.panel) and not selected.Visible)
        )
    then
        GuiService.SelectedObject = if jam.active then self.publish else self.join
    end
end

return View
