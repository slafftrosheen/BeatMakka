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
    local corner = object:FindFirstChildWhichIsA("UICorner")
    if corner then
        corner.CornerRadius = UDim.new(0, radius or 10)
    else
        GuiFactory.make("UICorner", object, { CornerRadius = UDim.new(0, radius or 10) })
    end
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
        Font = Enum.Font.Code,
        TextSize = 14,
        TextWrapped = true,
        BorderSizePixel = 0,
        AutoButtonColor = true,
        Selectable = true,
        Size = UDim2.fromOffset(100, 44),
    })
    GuiFactory.round(button, 8)
    local Skin = require(script.Parent.DeviceSkin)
    Skin.cap(button)
    local function renderActionIcon()
        -- Module loading can yield: finish it before replacing the owned glyph.
        local Icons = require(script.Parent.GameIcons)
        for _, previous in button:GetChildren() do
            if previous.Name == "ActionIcon" then
                previous:Destroy()
            end
        end
        local cap = button:FindFirstChild("DeviceCap")
        local caption = cap and cap:FindFirstChild("CapCaption")
        if caption then
            caption.Position, caption.Size = UDim2.fromOffset(8, 2), UDim2.new(1, -16, 1, -4)
        end
        if
            not caption
            or button:GetAttribute("GraphicPad")
            or button:GetAttribute("NoActionIcon")
        then
            return
        end
        local name = button:GetAttribute("UiIcon") or Icons.forText(button.Text)
        if name and button.AbsoluteSize.X >= 44 then
            local icon = Icons.make(button, name, button.TextColor3, 22)
            icon.Name = "ActionIcon"
            icon.Position = UDim2.new(0, 12, 0.5, -11)
            icon.ZIndex = button.ZIndex + 3
            for _, child in icon:GetDescendants() do
                if child:IsA("GuiObject") then
                    child.ZIndex = icon.ZIndex
                end
            end
            caption.Position, caption.Size = UDim2.fromOffset(40, 2), UDim2.new(1, -48, 1, -4)
            if button.AbsoluteSize.X < 100 then
                icon.Size = UDim2.fromOffset(18, 18)
                icon.Position = UDim2.new(0.5, -9, 0, 3)
                caption.Position, caption.Size = UDim2.fromOffset(3, 22), UDim2.new(1, -6, 1, -24)
            end
        else
            caption.Position, caption.Size = UDim2.fromOffset(8, 2), UDim2.new(1, -16, 1, -4)
        end
    end
    local updatingIcon, pendingIcon = false, false
    local updateActionIcon
    updateActionIcon = function()
        if updatingIcon then
            pendingIcon = true
            return
        end
        updatingIcon, pendingIcon = true, false
        renderActionIcon()
        updatingIcon = false
        if pendingIcon then
            task.defer(updateActionIcon)
        end
    end
    button:GetPropertyChangedSignal("Text"):Connect(function()
        if button.Text ~= "" and not button:GetAttribute("GraphicPad") then
            Skin.cap(button)
        end
        updateActionIcon()
    end)
    button:GetPropertyChangedSignal("TextColor3"):Connect(updateActionIcon)
    button:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateActionIcon)
    button:GetAttributeChangedSignal("UiIcon"):Connect(updateActionIcon)
    button:GetAttributeChangedSignal("NoActionIcon"):Connect(updateActionIcon)
    button:GetAttributeChangedSignal("GraphicPad"):Connect(updateActionIcon)
    task.defer(updateActionIcon)
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
