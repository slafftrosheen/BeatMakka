local Gui = require(script.Parent.GuiFactory)
local Theme = require(game.ReplicatedStorage.Shared.Theme)
local Spec = require(game.ReplicatedStorage.Shared.PadSound)
local Input = game:GetService("UserInputService")
local Controls = {}
Controls.__index = Controls
local keys = { "tone", "drive", "echo", "reverb", "gain", "pitch" }
local labels = {
    tone = "TONE",
    drive = "DRIVE",
    echo = "ECHO",
    reverb = "SPACE",
    gain = "LEVEL",
    pitch = "PITCH",
}
function Controls.new(parent, view, command)
    local self = setmetatable({ view = view, command = command, knobs = {} }, Controls)
    self.root = Gui.round(
        Gui.make("Frame", parent, {
            Name = "LiveFX",
            Size = UDim2.fromScale(1, 0.5),
            BackgroundColor3 = Theme.Ink,
            BorderSizePixel = 0,
        }),
        8
    )
    local title = Gui.label(self.root, "LIVE FX / SELECTED PAD", 11, Theme.Amber)
    title.Font = Enum.Font.Code
    title.Position = UDim2.fromOffset(12, 4)
    title.Size = UDim2.new(1, -24, 0, 22)
    self.cards = Gui.make("Frame", self.root, {
        Name = "Controls",
        Position = UDim2.fromOffset(4, 30),
        Size = UDim2.new(1, -8, 1, -34),
        BackgroundTransparency = 1,
    })
    local grid = Gui.make("UIGridLayout", self.cards, {
        CellSize = UDim2.new(1 / 3, -5, 0.5, -4),
        CellPadding = UDim2.fromOffset(6, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    for i, key in keys do
        local card = Gui.make(
            "Frame",
            self.cards,
            { Name = key, LayoutOrder = i, BackgroundTransparency = 1 }
        )
        local b = Gui.button(card, "", function() end, { silent = true })
        b.Name = "Dial"
        require(script.Parent.GrooveboxSkin).focus(b)
        b.AnchorPoint = Vector2.new(0.5, 0)
        b.Position = UDim2.fromScale(0.5, 0)
        b.Size = UDim2.fromOffset(54, 54)
        b.BackgroundColor3 = Theme.Graphite
        b:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(0.5, 0)
        Gui.make("UIStroke", b, { Color = Theme.Stone, Thickness = 2, Transparency = 0.35 })
        local pointer = Gui.make("Frame", b, {
            Name = "Pointer",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
        })
        Gui.round(
            Gui.make("Frame", pointer, {
                Position = UDim2.new(0.5, -2, 0, 5),
                Size = UDim2.fromOffset(4, 15),
                BackgroundColor3 = Theme.Amber,
                BorderSizePixel = 0,
            }),
            2
        )
        local value = Gui.label(card, "", 11, Theme.Cream)
        value.Font = Enum.Font.Code
        value.Position = UDim2.new(0, 0, 1, -23)
        value.Size = UDim2.new(1, 0, 0, 22)
        value.TextXAlignment = Enum.TextXAlignment.Center
        self.knobs[key] = { icon = pointer, label = value, button = b }
        for _, child in pointer:GetChildren() do
            child:Destroy()
        end
        require(script.Parent.GrooveboxSkin).image(
            pointer,
            "knob",
            { Position = UDim2.fromScale(-0.08, -0.08), Size = UDim2.fromScale(1.16, 1.16) }
        )
        b.BackgroundTransparency = 1
        for _, stroke in b:GetChildren() do
            if stroke:IsA("UIStroke") then
                stroke.Transparency = if stroke.Name == "FocusRing" then 0 else 1
                if stroke.Name == "FocusRing" then
                    stroke.Color = Theme.Cream
                end
            end
        end
        local function adjust(sign)
            local s = view.state
            if not s or not s.ready then
                return
            end
            local v = Spec.sanitize(s.pattern.sounds and s.pattern.sounds[view.selectedPad])
            self:send(key, v[key] + sign * Spec.Spec[key][4], true)
        end
        for _, sign in { -1, 1 } do
            local change = Gui.button(card, if sign < 0 then "−" else "+", function()
                adjust(sign)
            end, { silent = true })
            change.Name = if sign < 0 then "Minus" else "Plus"
            change.AnchorPoint = Vector2.new(if sign < 0 then 1 else 0, 0)
            change.Position = UDim2.new(0.5, if sign < 0 then -34 else 34, 0, 6)
            change.Size = UDim2.fromOffset(44, 44)
            change.BackgroundTransparency = 0.4
        end
        b.InputBegan:Connect(function(input)
            if
                input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch
            then
                local s = view.state
                if not s or not s.ready then
                    return
                end
                self.drag = {
                    key = key,
                    input = input,
                    y = input.Position.Y,
                    value = Spec.sanitize(s.pattern.sounds and s.pattern.sounds[view.selectedPad])[key],
                    pad = view.selectedPad,
                    station = s.station,
                }
            end
        end)
        b.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseWheel then
                adjust(input.Position.Z)
            end
        end)
    end
    self.changed = Input.InputChanged:Connect(function(input)
        local d = self.drag
        if not d then
            return
        end
        if
            not view.panel.Visible
            or view.page ~= "Play"
            or not view.state
            or view.state.station ~= d.station
            or view.selectedPad ~= d.pad
        then
            self.drag = nil
            return
        end
        if input == d.input or input.UserInputType == Enum.UserInputType.MouseMovement then
            local spec = Spec.Spec[d.key]
            d.pending = d.value + (d.y - input.Position.Y) * (spec[2] - spec[1]) / 180
            self:send(d.key, d.pending, false)
        end
    end)
    self.ended = Input.InputEnded:Connect(function(input)
        local d = self.drag
        if d and (input == d.input or input.UserInputType == Enum.UserInputType.MouseButton1) then
            if
                d.pending
                and view.selectedPad == d.pad
                and view.state
                and view.state.station == d.station
            then
                self:send(d.key, d.pending, true)
            end
            self.drag = nil
        end
    end)
    self.focus = Input.WindowFocusReleased:Connect(function()
        self.drag = nil
    end)
    self.root.Destroying:Connect(function()
        self.changed:Disconnect()
        self.ended:Disconnect()
        self.focus:Disconnect()
    end)
    self.grid = grid
    self.presets = Gui.make("Frame", self.root, {
        Name = "FXScenes",
        Position = UDim2.new(0, 8, 1, -52),
        Size = UDim2.new(1, -16, 0, 44),
        BackgroundTransparency = 1,
    })
    Gui.make("UIGridLayout", self.presets, {
        CellSize = UDim2.new(0.25, -5, 0, 44),
        CellPadding = UDim2.fromOffset(6, 0),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    for index, name in { "dry", "tape", "dub", "air" } do
        local button = Gui.button(self.presets, string.upper(name), function()
            command("PadPreset", view.selectedPad, name)
        end)
        button.Name, button.LayoutOrder, button.TextSize = "FX_" .. name, index, 12
    end
    return self
end
function Controls:resize(width)
    local columns = if width < 520 then 2 else 3
    local rows = 6 / columns
    self.grid.CellSize =
        UDim2.fromOffset(math.floor((width - 16 - 6 * (columns - 1)) / columns), 104)
    self.cards.Size = UDim2.new(1, -8, 0, rows * 110)
    local height = rows * 110 + 90
    self.root.Size = UDim2.new(1, -6, 0, height)
    return height
end
function Controls:send(key, value, force)
    local s = self.view.state
    if not s or not s.ready or (not force and os.clock() < (self.nextSend or 0)) then
        return
    end
    local spec = Spec.Spec[key]
    value = math.clamp(math.floor(value / spec[4] + 0.5) * spec[4], spec[1], spec[2])
    self.nextSend = os.clock() + 0.08
    self.command("PadSound", self.view.selectedPad, { key = key, value = value })
end
function Controls:update(state, pad)
    local values = Spec.sanitize(state.pattern.sounds and state.pattern.sounds[pad])
    for key, k in self.knobs do
        local spec = Spec.Spec[key]
        k.icon.Rotation = -135 + (values[key] - spec[1]) / (spec[2] - spec[1]) * 270
        k.label.Text = if key == "pitch"
            then string.format("%s %+d", labels[key], values[key])
            else string.format("%s %d%%", labels[key], math.floor(values[key] * 100 + 0.5))
    end
end
return Controls
