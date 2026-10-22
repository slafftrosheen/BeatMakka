-- Run in Edit after installing the current ContentIds module. No uploads.
local rs = game:GetService("ReplicatedStorage")
-- Clone avoids an older Edit-mode require cache after changing the bindings.
local module = rs.Shared.ContentIds:Clone()
module.Parent = rs
local ids = require(module).Images
module:Destroy()
local appearances = rs:FindFirstChild("AppearanceLibrary") or Instance.new("Folder")
appearances.Name = "AppearanceLibrary"
appearances.Parent = rs
for _, size in { 512, 1024 } do
    for _, finish in { "quay", "chalk", "coral", "afterhours" } do
        local name = finish .. "_" .. tostring(size)
        local previous = appearances:FindFirstChild(name)
        if previous then previous:Destroy() end
        local surface = Instance.new("SurfaceAppearance")
        surface.Name = name
        surface.ColorMap = "rbxassetid://" .. ids["atlas." .. finish .. ".basecolor." .. size]
        surface.RoughnessMap = "rbxassetid://" .. ids["atlas.roughness." .. size]
        surface.MetalnessMap = "rbxassetid://" .. ids["atlas.metalness." .. size]
        surface:SetAttribute("FinishSet", finish)
        surface.Parent = appearances
    end
end
local graphics = rs:FindFirstChild("UiImageLibrary") or Instance.new("Folder")
graphics.Name = "UiImageLibrary"
graphics.Parent = rs
for name, key in { Icons = "ui.icons", Panel = "ui.panel" } do
    local previous = graphics:FindFirstChild(name)
    if previous then previous:Destroy() end
    local image = Instance.new("ImageLabel")
    image.Name = name
    image.Image = "rbxassetid://" .. ids[key]
    image.Parent = graphics
end
return "Bound 8 persistent surface templates and 2 UI image templates."
