-- Loading feedback runs before the main player script waits for the world.
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
text.Font = Enum.Font.Gotham
text.TextSize = 20
text.TextWrapped = true
text.Parent = gui
while not storage:FindFirstChild("MusicNetwork") do
    local failure = storage:GetAttribute("LocalContentError")
    text.Text = if failure
        then "Local content could not load.\nRun the local content installer for this Studio version.\n"
            .. failure
        else "NEEDLE QUAY\nPreparing your neighborhood…\n" .. (storage:GetAttribute(
            "LocalArtLoaded"
        ) or 0) .. " / " .. (storage:GetAttribute("LocalArtTotal") or 39) .. " assets"
    task.wait(0.2)
end
gui:Destroy()
