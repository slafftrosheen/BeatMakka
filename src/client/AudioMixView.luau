local Gui = require(script.Parent.GuiFactory)
local Mix = require(script.Parent.AudioMix)
local Theme = require(game.ReplicatedStorage.Shared.Theme)
local View = {}
function View.new(parent)
    local root = Gui.make("Frame", parent, {
        Name = "PersonalAudioMix",
        Size = UDim2.new(1, -8, 0, 260),
        BackgroundColor3 = Theme.Ink,
        BorderSizePixel = 0,
        LayoutOrder = 3,
    })
    for i, channel in { "music", "ambience", "cues", "voice" } do
        local text = Gui.label(root, "", 13, Theme.Amber)
        text.Font = Enum.Font.Code
        text.Position, text.Size = UDim2.fromOffset(12, (i - 1) * 52 + 6), UDim2.new(1, -128, 0, 40)
        local rail = Gui.make("Frame", root, {
            Position = UDim2.new(0.43, 0, 0, (i - 1) * 52 + 21),
            Size = UDim2.new(0.57, -120, 0, 9),
            BackgroundColor3 = Theme.Graphite,
            BorderSizePixel = 0,
        })
        local fill = Gui.make(
            "Frame",
            rail,
            {
                Size = UDim2.fromScale(Mix[channel], 1),
                BackgroundColor3 = Theme.Amber,
                BorderSizePixel = 0,
            }
        )
        for _, sign in { -1, 1 } do
            local button = Gui.button(root, if sign < 0 then "-" else "+", function()
                Mix.set(channel, Mix[channel] + sign * 0.1)
            end)
            button.Position, button.Size =
                UDim2.new(1, if sign < 0 then -104 else -54, 0, (i - 1) * 52 + 4),
                UDim2.fromOffset(44, 44)
        end
        local function refresh()
            text.Text = string.upper(channel)
                .. string.format(" %03d", math.floor(Mix[channel] * 100 + 0.5))
            fill.Size = UDim2.fromScale(Mix[channel], 1)
        end
        refresh()
        local connection = Mix.Changed.Event:Connect(refresh)
        root.Destroying:Connect(function()
            connection:Disconnect()
        end)
    end
    local subtitles
    subtitles = Gui.button(root, "SUBTITLES / ON", function()
        Mix.subtitles = not Mix.subtitles
        subtitles.Text = if Mix.subtitles then "SUBTITLES / ON" else "SUBTITLES / OFF"
        Mix.Changed:Fire()
    end)
    subtitles.Position, subtitles.Size = UDim2.fromOffset(12, 212), UDim2.new(1, -24, 0, 40)
    return root
end
return View
