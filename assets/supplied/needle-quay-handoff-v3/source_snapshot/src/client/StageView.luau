local Gui = require(script.Parent.GuiFactory)
local Theme = require(game.ReplicatedStorage.Shared.Theme)
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local View = {}
View.__index = View

function View.new(screen, command, mute)
    local self = setmetatable({}, View)
    self.panel = Gui.round(Gui.make("Frame", screen, {
        Name = "CourtyardStage",
        Position = UDim2.fromOffset(12, 12),
        Size = UDim2.new(1, -24, 1, -24),
        BackgroundColor3 = Theme.Ink,
        Visible = false,
    }))
    Gui.make("UISizeConstraint", self.panel, { MaxSize = Vector2.new(600, 640) })
    local body = Gui.make("ScrollingFrame", self.panel, {
        Name = "StageActions",
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
    self.label = Gui.label(body, "", 14, Theme.Cream)
    self.label.Size = UDim2.new(1, -8, 0, 120)
    self.label.AutomaticSize = Enum.AutomaticSize.Y
    local function button(name, text, order, action)
        local b = Gui.button(body, text, function()
            command(action)
        end)
        b.Name, b.LayoutOrder = name, order
        b.Size = UDim2.new(1, -8, 0, 48)
        return b
    end
    self.prepare = button("PrepareSet", "Prepare my current loop / copy only", 1, "StagePrepare")
    self.start = button("StartTurn", "Start my offered turn", 2, "StageStart")
    self.cancel = button("CancelSet", "Cancel my prepared set", 3, "StageCancel")
    self.join = button("JoinSet", "Listen to this performer", 4, "StageJoin")
    self.stop = button("StopSet", "End my performance", 5, "StageStop")
    self.mute = Gui.button(self.panel, "Sound", mute)
    self.mute.Position = UDim2.new(0, 12, 1, -56)
    self.mute.Size = UDim2.new(0.5, -18, 0, 44)
    self.close = Gui.button(self.panel, "Leave stage", function()
        command("StageClose")
    end)
    self.close.Position = UDim2.new(0.5, 6, 1, -56)
    self.close.Size = UDim2.new(0.5, -18, 0, 44)
    return self
end

function View:update(stage, muted, notice, audioStatus)
    local wasOpen = self.panel.Visible
    self.panel.Visible = stage ~= nil and stage.open == true
    local selected = GuiService.SelectedObject
    if wasOpen and not self.panel.Visible and selected and selected:IsDescendantOf(self.panel) then
        local screen = self.panel.Parent
        local station, hud = screen:FindFirstChild("Workstation"), screen:FindFirstChild("HubHud")
        GuiService.SelectedObject = if station and station.Visible
            then station.Navigation.Play
            elseif hud and hud.Visible then hud.Sound
            else nil
    end
    if not stage then
        return
    end
    if notice then
        self.notice, self.noticeUntil = notice, os.clock() + 6
    end
    local rows = {
        "COURTYARD / VOLUNTARY SETS",
        if stage.performer then "On stage: " .. stage.performer else "The stage is free.",
        "Your own music stays unchanged. This is separate from the NPC chapter.",
    }
    if stage.requesting then
        table.insert(
            rows,
            "Your prepared set: position " .. stage.position .. ". Cancel to replace its snapshot."
        )
    end
    if stage.canStart then
        local remaining = if stage.offerEndsAt
            then math.max(0, math.ceil(stage.offerEndsAt - workspace:GetServerTimeNow()))
            else stage.offerRemaining or 0
        table.insert(rows, "Your offered turn expires in " .. remaining .. "s.")
    end
    if #stage.queue > 0 then
        table.insert(rows, "Waiting: " .. table.concat(stage.queue, " / "))
    end
    table.insert(
        rows,
        if stage.hosting
            then "You are performing."
            elseif stage.listening then "Listening by choice. Leave stage to stop."
            else "Not listening. Join only when you choose."
    )
    if stage.listening and audioStatus then
        table.insert(rows, audioStatus)
    end
    if self.notice and os.clock() < self.noticeUntil then
        table.insert(rows, self.notice)
    end
    self.label.Text = table.concat(rows, "\n")
    self.prepare.Active = not stage.hosting and not stage.requesting
    self.start.Active = stage.canStart == true
    self.cancel.Active = stage.requesting == true
    self.join.Active = stage.performer ~= nil and not stage.listening
    self.stop.Active = stage.hosting == true
    for _, b in { self.prepare, self.start, self.cancel, self.join, self.stop } do
        b.Selectable = b.Active
    end
    if
        self.panel.Visible
        and UserInputService.GamepadEnabled
        and (
            not wasOpen
            or not selected
            or not selected:IsDescendantOf(self.panel)
            or not selected.Selectable
        )
    then
        GuiService.SelectedObject = if stage.hosting
            then self.stop
            elseif stage.canStart then self.start
            elseif stage.requesting then self.cancel
            elseif self.join.Active then self.join
            else self.prepare
    end
    self.mute.Text = if muted then "Sound MUTED" else "Sound ON"
end
return View
