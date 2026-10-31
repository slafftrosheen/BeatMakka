local Gui = require(script.Parent.GuiFactory)
local Skin = require(script.Parent.DeviceSkin)
local Shared = game:GetService("ReplicatedStorage").Shared
local Theme = require(Shared.Theme)
local Spec = require(Shared.PadSound)
local Input = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Actions = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")

local Controls = {}
Controls.__index = Controls

local keys = { "gain", "pitch", "tone", "drive", "echo", "reverb" }
local labels = {
    gain = "LEVEL",
    pitch = "PITCH",
    tone = "TONE",
    drive = "DRIVE",
    echo = "ECHO",
    reverb = "SPACE",
}
local directions = {
    [Enum.KeyCode.Left] = -1,
    [Enum.KeyCode.Down] = -1,
    [Enum.KeyCode.DPadLeft] = -1,
    [Enum.KeyCode.DPadDown] = -1,
    [Enum.KeyCode.Right] = 1,
    [Enum.KeyCode.Up] = 1,
    [Enum.KeyCode.DPadRight] = 1,
    [Enum.KeyCode.DPadUp] = 1,
}
local nextId = 0

local function quantize(key, value)
    local spec = Spec.Spec[key]
    if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then
        value = spec[3]
    end
    return math.clamp(math.floor(value / spec[4] + 0.5) * spec[4], spec[1], spec[2])
end

local function context(state, pad)
    local music = state.music or {}
    return {
        pad = pad,
        station = state.station,
        project = music.projectId,
        track = music.trackId,
        program = music.program and music.program.id,
        sequence = music.sequence and music.sequence.id,
        bank = music.bank,
    }
end

local function sameRoute(a, b)
    return a ~= nil
        and b ~= nil
        and a.pad == b.pad
        and a.station == b.station
        and a.project == b.project
        and a.track == b.track
        and a.program == b.program
        and a.sequence == b.sequence
        and a.bank == b.bank
end

local function soundValues(state, pad)
    return Spec.sanitize(
        state and state.pattern and state.pattern.sounds and state.pattern.sounds[pad]
    )
end

local function displayValue(key, value)
    if key == "pitch" then
        return string.format("%+d st", math.round(value))
    elseif key == "tone" then
        return string.format("%+d%%", math.round(value * 100))
    end
    return string.format("%d%%", math.round(value * 100))
end

function Controls.new(parent, api)
    nextId += 1
    local self = setmetatable({
        api = api,
        knobs = {},
        connections = {},
        nextSend = 0,
        action = "DevicePadKnobs" .. nextId,
    }, Controls)
    self.root = Gui.make("Frame", parent, {
        Name = "PadSoundKnobs",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    })
    self.root:SetAttribute("ControlFamily", "SelectedPadSound")
    self.root:SetAttribute("KnobCount", #keys)
    self.root:SetAttribute("Dragging", false)

    for index, key in keys do
        local card = Gui.make("Frame", self.root, {
            Name = "Knob_" .. key,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            LayoutOrder = index,
        })
        card:SetAttribute("PadSoundKey", key)
        local button = Gui.make("TextButton", card, {
            Name = "Dial",
            Text = "",
            AutoButtonColor = false,
            Selectable = true,
            Active = true,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0.5, 0.5),
        })
        button:SetAttribute("PadSoundKey", key)
        button:SetAttribute("ControlLabel", labels[key])
        button:SetAttribute("InputKind", "Rotary")
        Gui.round(button, 100)
        local focus = Gui.make("UIStroke", button, {
            Name = "FocusRing",
            Color = Theme.Amber,
            Thickness = 2,
            Enabled = false,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        })
        local icon = Skin.image(button, "knob", {
            Name = "KnobImage",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
        })
        local name = Gui.label(card, labels[key], 11, Theme.Cream)
        name.Name, name.Font = "Name", Theme.Bold
        name.TextXAlignment = Enum.TextXAlignment.Center
        name.TextWrapped = false
        local value = Gui.label(card, "", 11, Theme.Amber)
        value.Name, value.Font = "Value", Enum.Font.Code
        value.TextXAlignment = Enum.TextXAlignment.Center
        value.TextWrapped = false
        self.knobs[key] = {
            card = card,
            button = button,
            icon = icon,
            name = name,
            value = value,
        }
        table.insert(
            self.connections,
            button.SelectionGained:Connect(function()
                focus.Enabled = true
            end)
        )
        table.insert(
            self.connections,
            button.SelectionLost:Connect(function()
                focus.Enabled = false
                if self.edit and self.edit.kind == "pointer" and self.edit.key == key then
                    self:cancel()
                end
            end)
        )
        table.insert(
            self.connections,
            button.InputBegan:Connect(function(input)
                if
                    input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch
                then
                    self:begin(key, input)
                end
            end)
        )
        table.insert(
            self.connections,
            button.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseWheel then
                    self:adjust(key, input.Position.Z)
                end
            end)
        )
    end

    table.insert(
        self.connections,
        Input.InputChanged:Connect(function(input)
            local edit = self.edit
            if not edit or edit.kind ~= "pointer" then
                return
            end
            if not self:valid(edit) then
                self:cancel()
                return
            end
            local mouse = edit.input.UserInputType == Enum.UserInputType.MouseButton1
            if
                (mouse and input.UserInputType == Enum.UserInputType.MouseMovement)
                or (not mouse and input == edit.input)
            then
                local spec = Spec.Spec[edit.key]
                edit.pending = quantize(
                    edit.key,
                    edit.initial + (edit.y - input.Position.Y) * (spec[2] - spec[1]) / 180
                )
                self:paint(edit.key, edit.pending, edit.route.pad)
                self:flush(false)
            end
        end)
    )
    table.insert(
        self.connections,
        Input.InputEnded:Connect(function(input)
            local edit = self.edit
            if not edit or edit.kind ~= "pointer" then
                return
            end
            if
                input == edit.input
                or (
                    edit.input.UserInputType == Enum.UserInputType.MouseButton1
                    and input.UserInputType == Enum.UserInputType.MouseButton1
                )
            then
                self:flush(true)
                if self.edit == edit then
                    edit.kind, edit.input, edit.expires = "settle", nil, os.clock() + 0.8
                    self.root:SetAttribute("Dragging", false)
                end
            end
        end)
    )
    table.insert(
        self.connections,
        Input.WindowFocusReleased:Connect(function()
            self:cancel()
        end)
    )
    table.insert(
        self.connections,
        Input.TextBoxFocused:Connect(function()
            self:cancel()
        end)
    )
    table.insert(
        self.connections,
        self.root:GetPropertyChangedSignal("Visible"):Connect(function()
            if not self.root.Visible then
                self:cancel()
            end
        end)
    )
    table.insert(
        self.connections,
        RunService.Heartbeat:Connect(function()
            if self.edit then
                self:flush(false)
                if
                    self.edit
                    and self.edit.kind ~= "pointer"
                    and os.clock() >= self.edit.expires
                then
                    self:cancel()
                end
            end
        end)
    )
    Actions:BindActionAtPriority(
        self.action,
        function(_, inputState, input)
            if Input:GetFocusedTextBox() or not self:capture() then
                return Enum.ContextActionResult.Pass
            end
            for key, knob in self.knobs do
                if GuiService.SelectedObject == knob.button then
                    if inputState == Enum.UserInputState.Begin then
                        self:adjust(key, directions[input.KeyCode])
                    end
                    return Enum.ContextActionResult.Sink
                end
            end
            return Enum.ContextActionResult.Pass
        end,
        false,
        Enum.ContextActionPriority.High.Value + 1,
        Enum.KeyCode.Left,
        Enum.KeyCode.Right,
        Enum.KeyCode.Up,
        Enum.KeyCode.Down,
        Enum.KeyCode.DPadLeft,
        Enum.KeyCode.DPadRight,
        Enum.KeyCode.DPadUp,
        Enum.KeyCode.DPadDown
    )
    table.insert(
        self.connections,
        self.root.Destroying:Connect(function()
            self:destroy(true)
        end)
    )
    self:resize(160, 280)
    self:update(api.state(), api.absolutePad())
    return self
end

function Controls:capture()
    local state, pad = self.api.state(), self.api.absolutePad()
    if
        self.destroyed
        or not self.root.Visible
        or not self.api.visible()
        or not state
        or not state.ready
        or not state.pattern
        or type(pad) ~= "number"
        or pad % 1 ~= 0
        or pad < 1
        or pad > 64
    then
        return nil
    end
    return context(state, pad)
end

function Controls:valid(edit)
    return sameRoute(edit.route, self:capture())
end

function Controls:paint(key, value, pad)
    local knob, spec = self.knobs[key], Spec.Spec[key]
    knob.icon.Rotation = -135 + (value - spec[1]) / (spec[2] - spec[1]) * 270
    knob.value.Text = displayValue(key, value)
    for _, object in { knob.card, knob.button } do
        object:SetAttribute("PadSoundValue", value)
        object:SetAttribute("AbsolutePad", pad)
        object:SetAttribute("ControlValue", knob.value.Text)
    end
end

function Controls:flush(force)
    local edit = self.edit
    if not edit then
        return
    end
    if not self:valid(edit) then
        self:cancel()
        return
    end
    if edit.pending == edit.sent or (not force and os.clock() < self.nextSend) then
        return
    end
    edit.sent = quantize(edit.key, edit.pending)
    self.nextSend = os.clock() + 0.08
    self.api.command("PadSound", edit.route.pad, { key = edit.key, value = edit.sent })
end

function Controls:begin(key, input)
    if self.edit and self.edit.kind == "pointer" then
        return
    end
    local route = self:capture()
    if not route then
        return
    end
    self:flush(true)
    local value = soundValues(self.api.state(), route.pad)[key]
    if self.edit and self.edit.key == key and sameRoute(self.edit.route, route) then
        value = self.edit.pending
    end
    self.edit = {
        key = key,
        kind = "pointer",
        route = route,
        input = input,
        y = input.Position.Y,
        initial = value,
        pending = quantize(key, value),
        sent = quantize(key, value),
    }
    self.root:SetAttribute("Dragging", true)
end

function Controls:adjust(key, amount)
    if not amount or amount == 0 or (self.edit and self.edit.kind == "pointer") then
        return
    end
    local route = self:capture()
    if not route then
        return
    end
    local edit = self.edit
    if not edit or edit.key ~= key or not sameRoute(edit.route, route) then
        self:flush(true)
        local value = quantize(key, soundValues(self.api.state(), route.pad)[key])
        edit = { key = key, kind = "step", route = route, pending = value, sent = value }
        self.edit = edit
    end
    edit.pending = quantize(key, edit.pending + amount * Spec.Spec[key][4])
    edit.expires = os.clock() + 0.8
    self:paint(key, edit.pending, route.pad)
    self:flush(false)
end

function Controls:resize(width, height)
    width, height = math.max(0, width), math.max(0, height)
    self.root.Size = UDim2.fromOffset(width, height)
    local gap = if width >= 140 then 8 else 4
    local cellWidth, cellHeight = (width - gap) / 2, height / 3
    local imageSize = math.max(0, math.min(68, cellWidth - 8, cellHeight - 32))
    local target = math.max(0, math.min(cellWidth, cellHeight, math.max(44, imageSize)))
    for index, key in keys do
        local knob = self.knobs[key]
        knob.card.Position = UDim2.fromOffset(
            (index - 1) % 2 * (cellWidth + gap),
            math.floor((index - 1) / 2) * cellHeight
        )
        knob.card.Size = UDim2.fromOffset(cellWidth, cellHeight)
        knob.button.Position = UDim2.fromOffset(cellWidth / 2, (cellHeight - 2) / 2)
        knob.button.Size = UDim2.fromOffset(target, target)
        knob.icon.Size = UDim2.fromOffset(imageSize, imageSize)
        knob.name.Position, knob.name.Size = UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 14)
        knob.value.Position, knob.value.Size = UDim2.new(0, 0, 1, -16), UDim2.new(1, 0, 0, 16)
    end
end

function Controls:update(state, absolutePad)
    if self.destroyed then
        return
    end
    local route = if state and type(absolutePad) == "number"
        then context(state, absolutePad)
        else nil
    local values = soundValues(state, absolutePad)
    local edit = self.edit
    if edit and (not sameRoute(edit.route, route) or not self:valid(edit)) then
        self.edit = nil
        self.root:SetAttribute("Dragging", false)
    elseif edit then
        if
            edit.kind ~= "pointer"
            and values[edit.key] == edit.pending
            and edit.sent == edit.pending
        then
            self.edit = nil
        else
            values[edit.key] = edit.pending
        end
    end
    self.root:SetAttribute("AbsolutePad", absolutePad)
    self.root:SetAttribute("Ready", self:capture() ~= nil)
    for _, key in keys do
        self:paint(key, values[key], absolutePad)
    end
end

function Controls:cancel()
    self.edit = nil
    self.root:SetAttribute("Dragging", false)
    if not self.destroyed then
        self:update(self.api.state(), self.api.absolutePad())
    end
end

function Controls:destroy(fromRoot)
    if self.destroyed then
        return
    end
    self.destroyed, self.edit = true, nil
    Actions:UnbindAction(self.action)
    for _, connection in self.connections do
        connection:Disconnect()
    end
    table.clear(self.connections)
    if not fromRoot then
        self.root:Destroy()
    end
end

return Controls
