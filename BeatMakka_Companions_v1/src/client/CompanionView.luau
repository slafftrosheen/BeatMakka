-- Lightweight optional roaming UI; never overlays MK-I, listening, stage, or chapter controls.
local Shared = game:GetService("ReplicatedStorage").Shared
local Theme = require(Shared.Theme)
local Gui = require(script.Parent.GuiFactory)

local View = {}
View.__index = View

function View.new(screen, send)
    local self = setmetatable({}, View)
    local panel = Gui.make("Frame", screen, {
        Name = "CompanionDock",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -12, 0, 58),
        Size = UDim2.fromOffset(282, 190),
        BackgroundColor3 = Theme.White,
        BorderSizePixel = 0,
        Visible = false,
    })
    Gui.round(panel, 12)
    Gui.make("UIStroke", panel, { Color = Theme.Teal, Thickness = 1 })
    self.panel = panel

    local label = Gui.label(panel, "YOUR COMPANION", 15, Theme.Ink)
    label.Font = Theme.Bold
    label.Size = UDim2.new(1, -18, 0, 24)
    label.Position = UDim2.fromOffset(10, 7)
    self.label = label

    local buttons = {
        { "Alissia", "alissia" },
        { "Nikolas", "nikolas" },
        { "Alone", "none" },
    }
    self.buttons = {}
    for index, entry in buttons do
        local id = entry[2]
        local button = Gui.button(panel, entry[1], function()
            send("CompanionSelect", id)
        end)
        button.Name = "Choose_" .. id
        button.Size = UDim2.new(1 / 3, -11, 0, 44)
        button.Position = UDim2.new((index - 1) / 3, 7, 0, 37)
        self.buttons[id] = button
    end

    local hint = Gui.label(panel, "", 14, Theme.Ink)
    hint.Name = "CompanionHint"
    hint.Size = UDim2.new(1, -20, 0, 90)
    hint.Position = UDim2.fromOffset(10, 90)
    hint.TextYAlignment = Enum.TextYAlignment.Top
    self.hint = hint
    return self
end

function View:update(state)
    local open = state ~= nil
        and state.ready
        and state.station == nil
        and state.listening == nil
        and not (state.stage and state.stage.open)
        and not (state.concert and state.concert.open)
    self.panel.Visible = open == true
    if not open then
        return
    end
    local companion = state.companion or {}
    local selected = companion.selected or "none"
    self.label.Text = if selected == "none"
        then "COMPANIONS (OPTIONAL)"
        else (companion.name or "COMPANION") .. " / " .. (companion.role or "")
    self.hint.Text = companion.hint or "Choose a companion, or explore alone."
    for id, button in self.buttons do
        button.BackgroundColor3 = if id == selected then Theme.Coral else Theme.Teal
        button.TextColor3 = Theme.Cream
    end
end

return View
