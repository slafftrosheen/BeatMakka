-- Lightweight native loading graphics appear before local art and music are ready.
local storage = game:GetService("ReplicatedStorage")
local gui = Instance.new("ScreenGui")
gui.Name = "LocalQuayLoading"
gui.ResetOnSpawn = false
gui.DisplayOrder = 100
gui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
local text = Instance.new("TextLabel")
text.Size = UDim2.fromScale(1, 1)
text.BackgroundColor3 = Color3.fromRGB(22, 35, 34)
text.TextColor3 = Color3.fromRGB(232, 216, 183)
text.Font = Enum.Font.Code
text.TextSize = 22
text.TextWrapped = true
text.Parent = gui
local pads = {}
for index = 1, 4 do
    local pad = Instance.new("Frame")
    pad.Name = "TuningPad" .. index
    pad.AnchorPoint = Vector2.new(0.5, 1)
    pad.Position =
        UDim2.new(0.5, ((index - 1) % 2) * 48 - 24, 0.5, -70 + math.floor((index - 1) / 2) * 48)
    pad.Size = UDim2.fromOffset(40, 40)
    pad.BackgroundColor3 = Color3.fromRGB(232, 216, 183)
    pad.BorderSizePixel = 0
    pad.Rotation = -4
    pad.Parent = text
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 7)
    corner.Parent = pad
    pads[index] = pad
end
local rail = Instance.new("Frame")
rail.AnchorPoint = Vector2.new(0.5, 0)
rail.Position = UDim2.new(0.5, 0, 0.5, 80)
rail.Size = UDim2.new(0.6, 0, 0, 6)
rail.BackgroundColor3 = Color3.fromRGB(49, 81, 68)
rail.BorderSizePixel = 0
rail.Parent = text
local fill = rail:Clone()
fill.AnchorPoint, fill.Position, fill.Size = Vector2.zero, UDim2.new(), UDim2.fromScale(0, 1)
fill.BackgroundColor3 = Color3.fromRGB(245, 183, 91)
fill.Parent = rail
local beat = 0
while not storage:FindFirstChild("MusicNetwork") do
    local failure = storage:GetAttribute("LocalContentError")
    local loaded, total =
        storage:GetAttribute("LocalArtLoaded") or 0, storage:GetAttribute("LocalArtTotal") or 83
    fill.Size = UDim2.fromScale(math.clamp(loaded / math.max(total, 1), 0, 1), 1)
    beat = beat % 4 + 1
    for index, pad in pads do
        pad.BackgroundColor3 = if index == beat
            then Color3.fromRGB(245, 183, 91)
            else Color3.fromRGB(232, 216, 183)
        pad.Rotation = if index == beat then 2 else -4
    end
    text.Text = if failure
        then "Local content could not load.\nRun the local content installer for this Studio version.\n"
            .. failure
        else "NEEDLE QUAY\nTUNING YOUR NEIGHBOURHOOD\n" .. string.format(
            "%02d / %02d",
            loaded,
            total
        )
    task.wait(0.2)
end
gui:Destroy()
