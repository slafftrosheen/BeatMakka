local Theme = require(game:GetService("ReplicatedStorage").Shared.Theme)
local Shared = game:GetService("ReplicatedStorage").Shared
local Ids = require(Shared.ContentIds)
local Atlas = require(Shared.UiAtlas)
local GuiFactory = {}
GuiFactory.Cue = Instance.new("BindableEvent")

function GuiFactory.make(className, parent, properties)
    local object = Instance.new(className)
    for key, value in properties do
        object[key] = value
    end
    object.Parent = parent
    return object
end

function GuiFactory.round(object, radius)
    GuiFactory.make("UICorner", object, { CornerRadius = UDim.new(0, radius or 10) })
    return object
end

function GuiFactory.label(parent, text, size, color)
    return GuiFactory.make("TextLabel", parent, {
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = color or Theme.Ink,
        Font = Theme.Font,
        TextSize = size or 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        BorderSizePixel = 0,
    })
end

function GuiFactory.button(parent, text, callback, options)
    local button = GuiFactory.make("TextButton", parent, {
        Text = text,
        BackgroundColor3 = Theme.Teal,
        TextColor3 = Theme.Cream,
        Font = Theme.Bold,
        TextSize = 14,
        TextWrapped = true,
        BorderSizePixel = 0,
        AutoButtonColor = true,
        Selectable = true,
        Size = UDim2.fromOffset(100, 44),
    })
    GuiFactory.round(button, 8)
    local ring = GuiFactory.make("UIStroke", button, {
        Name = "FocusRing",
        Color = Theme.Ink,
        Thickness = 3,
        Enabled = false,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
    button.SelectionGained:Connect(function()
        ring.Enabled = true
    end)
    button.SelectionLost:Connect(function()
        ring.Enabled = false
    end)
    button.Activated:Connect(function(input)
        if not options or not options.silent then
            GuiFactory.Cue:Fire("ui_tap")
        end
        callback(input)
    end)
    return button
end

function GuiFactory.icon(parent, name)
    local id = Ids.Images["ui.icons"]
    local library = game:GetService("ReplicatedStorage"):FindFirstChild("UiImageLibrary")
    local prepared = library and library:FindFirstChild("Icons")
    if prepared and prepared.ImageContent.SourceType == Enum.ContentSourceType.None then
        prepared = nil
    end
    if not Atlas[name] or (type(id) ~= "number" and not prepared) then
        return nil
    end
    local image = if prepared then prepared:Clone() else Instance.new("ImageLabel")
    local properties = {
        Name = "Icon",
        BackgroundTransparency = 1,
        ImageRectOffset = Atlas[name],
        ImageRectSize = Vector2.new(256, 256),
        Size = UDim2.fromOffset(16, 16),
        Position = UDim2.new(1, -20, 0, 3),
        ImageColor3 = Theme.Cream,
    }
    for key, value in properties do
        image[key] = value
    end
    if type(id) == "number" then
        image.Image = "rbxassetid://" .. tostring(id)
    end
    image.Parent = parent
    return image
end

function GuiFactory.panelMask(parent)
    local id = Ids.Images["ui.panel"]
    local library = game:GetService("ReplicatedStorage"):FindFirstChild("UiImageLibrary")
    local prepared = library and library:FindFirstChild("Panel")
    if prepared and prepared.ImageContent.SourceType == Enum.ContentSourceType.None then
        prepared = nil
    end
    if type(id) ~= "number" and not prepared then
        return
    end
    local image = if prepared then prepared:Clone() else Instance.new("ImageLabel")
    local properties = {
        Name = "PanelMask",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        ImageColor3 = Theme.Cream,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(18, 18, 46, 46),
    }
    for key, value in properties do
        image[key] = value
    end
    if type(id) == "number" then
        image.Image = "rbxassetid://" .. tostring(id)
    end
    image.Parent = parent
end
return GuiFactory
