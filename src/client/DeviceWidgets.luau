-- Small stable native controls. No implicit icon rebuilding or layout allocation.
local Gui = require(script.Parent.GuiFactory)
local Skin = require(script.Parent.DeviceSkin)
local Icons = require(script.Parent.GameIcons)
local W = {
    ink = Color3.fromRGB(18, 38, 34),
    text = Color3.fromRGB(195, 224, 171),
    amber = Color3.fromRGB(249, 190, 101),
}
W.make = Gui.make
local keyData = setmetatable({}, { __mode = "k" })
local function layoutKey(b)
    local data = keyData[b]
    if not data then
        return
    end
    local narrow = b.AbsoluteSize.X < 110
    data.glyph.Position = if narrow then UDim2.new(0.5, -9, 0, 4) else UDim2.new(0, 12, 0.5, -11)
    data.glyph.Size = UDim2.fromOffset(if narrow then 18 else 22, if narrow then 18 else 22)
    data.title.Position = if narrow then UDim2.fromOffset(2, 24) else UDim2.fromOffset(40, 2)
    data.title.Size = if narrow then UDim2.new(1, -4, 1, -25) else UDim2.new(1, -46, 1, -4)
    data.title.TextXAlignment = if narrow
        then Enum.TextXAlignment.Center
        else Enum.TextXAlignment.Left
    data.title.TextSize = if narrow then 10 else 12
end
function W.set(object, property, value)
    if object[property] ~= value then
        object[property] = value
    end
end
function W.label(parent, name, text, size, color)
    return Gui.make("TextLabel", parent, {
        Name = name,
        BackgroundTransparency = 1,
        Text = text,
        Font = Enum.Font.Code,
        TextSize = size or 13,
        TextColor3 = color or W.text,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        BorderSizePixel = 0,
    })
end
function W.frame(parent, name, color)
    return Gui.make("Frame", parent, {
        Name = name,
        BackgroundColor3 = color or W.ink,
        BackgroundTransparency = if color then 0 else 1,
        BorderSizePixel = 0,
    })
end
function W.key(parent, name, icon, text, callback)
    local b = Gui.make("TextButton", parent, {
        Name = name,
        Text = "",
        BackgroundColor3 = Color3.fromRGB(224, 211, 175),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Selectable = true,
        Size = UDim2.fromOffset(100, 44),
    })
    b:SetAttribute("AccessibleLabel", text)
    local image = Skin.image(b, "softkey-v4", {
        Name = "KeySurface",
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(36, 36, 348, 92),
        SliceScale = 0.25,
    })
    local glyph = Icons.make(b, icon or "plus", W.ink, 22)
    glyph.Name, glyph.Position, glyph.ZIndex = "Glyph", UDim2.new(0, 12, 0.5, -11), 3
    for _, child in glyph:GetDescendants() do
        if child:IsA("GuiObject") then
            child.ZIndex = 3
        end
    end
    local title = W.label(b, "Legend", text, 12, W.ink)
    keyData[b] = { glyph = glyph, title = title, icon = icon or "plus", fallback = icon or "plus" }
    title.Position, title.Size, title.ZIndex = UDim2.fromOffset(40, 2), UDim2.new(1, -46, 1, -4), 3
    local lamp = Gui.make("Frame", b, {
        Name = "SelectedLamp",
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -4),
        Size = UDim2.new(0.4, 0, 0, 3),
        BackgroundColor3 = W.amber,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 4,
    })
    local focus = Gui.make(
        "UIStroke",
        b,
        {
            Color = W.amber,
            Thickness = 2,
            Enabled = false,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        }
    )
    b.SelectionGained:Connect(function()
        focus.Enabled = true
    end)
    b.SelectionLost:Connect(function()
        focus.Enabled = false
    end)
    b.MouseEnter:Connect(function()
        image.ImageColor3 = Color3.fromRGB(255, 239, 194)
    end)
    b.MouseLeave:Connect(function()
        image.ImageColor3 = if b:GetAttribute("Selected")
            then Color3.fromRGB(255, 197, 111)
            else Color3.new(1, 1, 1)
    end)
    b:GetAttributeChangedSignal("Selected"):Connect(function()
        local selected = b:GetAttribute("Selected") == true
        lamp.Visible = selected
        image.ImageColor3 = if selected then Color3.fromRGB(255, 197, 111) else Color3.new(1, 1, 1)
    end)
    b:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        layoutKey(b)
    end)
    b.Activated:Connect(function(input)
        if b.Active then
            callback(input)
        end
    end)
    return b
end
function W.legend(key, text)
    if key.Legend.Text == text then
        return
    end
    W.set(key.Legend, "Text", text)
    if key:GetAttribute("AccessibleLabel") ~= text then
        key:SetAttribute("AccessibleLabel", text)
    end
    local data = keyData[key]
    if data then
        local family = text:match("^([ABCD])%d")
        local icon = ({ A = "drum", B = "bass", C = "mic", D = "waves" })[family]
            or Icons.forText(text)
            or data.fallback
        if icon ~= data.icon then
            data.glyph:Destroy()
            data.glyph = Icons.make(key, icon, W.ink, 22)
            data.glyph.Name, data.glyph.ZIndex = "Glyph", 3
            for _, child in data.glyph:GetDescendants() do
                if child:IsA("GuiObject") then
                    child.ZIndex = 3
                end
            end
            data.icon = icon
            layoutKey(key)
        end
    end
end
function W.place(object, x, y, w, h)
    object.Position, object.Size =
        UDim2.fromOffset(x, y), UDim2.fromOffset(math.max(0, w), math.max(0, h))
end
function W.line(parent, name, color)
    return Gui.make(
        "Frame",
        parent,
        { Name = name, BackgroundColor3 = color or W.text, BorderSizePixel = 0 }
    )
end
return W
