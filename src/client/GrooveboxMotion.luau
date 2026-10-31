-- Note activity, not an audio waveform. Motion follows actual pad/transport events.
local Run = game:GetService("RunService")
local Gui = require(script.Parent.GuiFactory)
local Theme = require(game.ReplicatedStorage.Shared.Theme)
local Motion = {}
Motion.__index = Motion
function Motion.new(view, parent)
    local self =
        setmetatable({ view = view, levels = table.create(16, 0), bars = {}, elapsed = 0 }, Motion)
    self.root = Gui.make(
        "Frame",
        parent,
        {
            Name = "NoteActivity",
            BackgroundTransparency = 1,
            Position = UDim2.new(0.69, 0, 0, 12),
            Size = UDim2.fromOffset(190, 45),
        }
    )
    for i = 1, 16 do
        self.bars[i] = Gui.round(
            Gui.make(
                "Frame",
                self.root,
                {
                    AnchorPoint = Vector2.new(0, 1),
                    Position = UDim2.new((i - 1) / 16, 0, 1, -12),
                    Size = UDim2.new(1 / 16, -3, 0, 2),
                    BackgroundColor3 = if i % 4 == 1 then Theme.Amber else Theme.FadedTeal,
                    BorderSizePixel = 0,
                }
            ),
            2
        )
    end
    local title = Gui.label(self.root, "NOTE ACTIVITY", 9, Theme.FadedTeal)
    title.Font, title.Position, title.Size =
        Enum.Font.Code, UDim2.new(0, 0, 1, -10), UDim2.new(1, 0, 0, 10)
    title.TextXAlignment = Enum.TextXAlignment.Center
    self.connection = Run.Heartbeat:Connect(function(dt)
        self.elapsed += dt
        if self.elapsed < 1 / 30 then
            return
        end
        local delta = self.elapsed
        self.elapsed = 0
        self.root.Visible = view.panel.Visible and view.panel.AbsoluteSize.X > 1280
        if not view.panel.Visible then
            return
        end
        for i, level in self.levels do
            self.levels[i] = math.max(0, level - delta * 2.8)
            local value = if view.effects then self.levels[i] else 0
            self.bars[i].Size = UDim2.new(1 / 16, -3, 0, 2 + value * 26)
            local pad = view.pads[i]
            local surface = pad and pad:FindFirstChild("PadSurface")
            local scale = surface and surface:FindFirstChildOfClass("UIScale")
            if scale then
                scale.Scale = 1 - value * 0.035
            end
        end
    end)
    parent.Destroying:Once(function()
        self.connection:Disconnect()
    end)
    return self
end
function Motion:hit(pad)
    self.levels[pad] = 1
end
return Motion
