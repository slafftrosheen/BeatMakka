-- Shared, bounded local device artwork. Hit targets, labels and state stay native.
local Assets = game:GetService("AssetService")
local Tween = game:GetService("TweenService")
local Uri = require(script.Parent.LocalTextureUri)
local Skin = {}
local images, waiting = {}, {}
local function make(class, parent, properties)
    local object = Instance.new(class)
    for key, value in properties do
        object[key] = value
    end
    object.Parent = parent
    return object
end
function Skin.image(parent, name, properties)
    local image = make("ImageLabel", parent, {
        Name = "DeviceArt_" .. name,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Active = false,
        ZIndex = 1,
    })
    for key, value in properties or {} do
        image[key] = value
    end
    image:SetAttribute("DeviceArt", name)
    local function bind(target)
        if target.Parent then
            target.ImageContent = Content.fromObject(images[name])
            target:SetAttribute("GraphicLoaded", true)
        end
    end
    if images[name] then
        bind(image)
    elseif waiting[name] then
        table.insert(waiting[name], image)
    else
        waiting[name] = { image }
        task.spawn(function()
            local ok, asset = pcall(function()
                return Assets:CreateEditableImageAsync(
                    Content.fromUri(Uri("rbxasset://needle-quay/ui-device-v3/" .. name .. ".png"))
                )
            end)
            if ok and asset then
                images[name] = asset
                for _, target in waiting[name] do
                    bind(target)
                end
            else
                for _, target in waiting[name] do
                    if target.Parent then
                        target:SetAttribute("ImageUnavailable", true)
                    end
                end
                warn("Device artwork unavailable: " .. name)
            end
            waiting[name] = nil
        end)
    end
    return image
end
function Skin.panel(frame, kind)
    if frame:FindFirstChild("DeviceSurface") then
        return
    end
    if kind == "lcd" then
        frame.BackgroundTransparency = 0
        frame.BackgroundColor3 = Color3.fromRGB(16, 32, 27)
        make("UIGradient", frame, {
            Color = ColorSequence.new(Color3.fromRGB(38, 62, 45), Color3.fromRGB(9, 24, 22)),
            Rotation = 90,
        })
        make(
            "UIStroke",
            frame,
            { Name = "DeviceSurface", Color = Color3.fromRGB(81, 92, 65), Thickness = 3 }
        )
        frame:SetAttribute("GraphicSurface", kind)
        return
    end
    local journal = kind == "journal"
    local image = Skin.image(frame, if journal then "journal" else "faceplate", {
        Name = "DeviceSurface",
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = if journal then Rect.new(86, 86, 682, 938) else Rect.new(92, 92, 932, 420),
        SliceScale = if journal then 0.5 else 0.6,
        ZIndex = 0,
    })
    image:SetAttribute("SurfaceKind", kind)
    frame.BackgroundTransparency = 1
    frame:SetAttribute("GraphicSurface", kind)
    frame:SetAttribute("DeviceSkinVersion", 3)
end
function Skin.cap(button)
    if button:FindFirstChild("DeviceCap") or button.Text == "" then
        return
    end
    button.AutoButtonColor = false
    button.TextTransparency = 1
    button.BackgroundTransparency = 1
    button:SetAttribute("GraphicButton", true)
    local root = make("Frame", button, {
        Name = "DeviceCap",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = button.ZIndex,
    })
    local image = Skin.image(root, "pad", {
        Name = "CapSurface",
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(100, 100, 284, 284),
        SliceScale = 0.13,
        ImageColor3 = button.BackgroundColor3,
        ZIndex = button.ZIndex,
    })
    local caption = make("TextLabel", root, {
        Name = "CapCaption",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(8, 2),
        Size = UDim2.new(1, -16, 1, -4),
        Text = button.Text,
        Font = button.Font,
        TextSize = button.TextSize,
        TextColor3 = button.TextColor3,
        TextWrapped = true,
        TextXAlignment = button.TextXAlignment,
        TextYAlignment = button.TextYAlignment,
        ZIndex = button.ZIndex + 2,
    })
    local scale = make("UIScale", root, { Scale = 1 })
    local lamp = make("Frame", root, {
        Name = "SelectedLamp",
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -5),
        Size = UDim2.new(0.35, 0, 0, 3),
        BackgroundColor3 = Color3.fromRGB(255, 201, 100),
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = button.ZIndex + 3,
    })
    make("UICorner", lamp, { CornerRadius = UDim.new(1, 0) })
    local function sync()
        caption.Text, caption.Font, caption.TextSize = button.Text, button.Font, button.TextSize
        caption.TextColor3 = button.TextColor3
        caption.TextXAlignment, caption.TextYAlignment =
            button.TextXAlignment, button.TextYAlignment
        image.ImageColor3 = button.BackgroundColor3
        image.ImageTransparency = if button.Active then 0 else 0.18
        lamp.Visible = button:GetAttribute("Selected") == true
    end
    for _, property in
        {
            "Text",
            "Font",
            "TextSize",
            "TextColor3",
            "BackgroundColor3",
            "Active",
            "TextXAlignment",
            "TextYAlignment",
        }
    do
        button:GetPropertyChangedSignal(property):Connect(sync)
    end
    button:GetAttributeChangedSignal("Selected"):Connect(sync)
    local function press(value)
        Tween:Create(scale, TweenInfo.new(0.09), { Scale = value }):Play()
    end
    button.InputBegan:Connect(function(input)
        if
            input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
        then
            press(0.96)
        end
    end)
    button.InputEnded:Connect(function(input)
        if
            input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
        then
            press(1)
        end
    end)
    button.MouseLeave:Connect(function()
        press(1)
    end)
    image:GetAttributeChangedSignal("ImageUnavailable"):Connect(function()
        button.BackgroundTransparency = 0
    end)
    sync()
end
function Skin.pad(button)
    local cap = button:FindFirstChild("DeviceCap")
    if cap then
        cap:Destroy()
    end
    local action = button:FindFirstChild("ActionIcon")
    if action then
        action:Destroy()
    end
    button.BackgroundTransparency, button.TextTransparency, button.AutoButtonColor = 1, 1, false
    button:SetAttribute("GraphicPad", true)
    local image = Skin.image(button, "pad", { Name = "PadSurface", ZIndex = 1 })
    local scale = make("UIScale", image, { Scale = 1 })
    local number = make("TextLabel", button, {
        Name = "PadNumber",
        Position = UDim2.fromScale(0.1, 0.08),
        Size = UDim2.fromScale(0.55, 0.17),
        Text = "",
        Font = Enum.Font.Code,
        TextSize = 13,
        TextColor3 = Color3.fromRGB(25, 38, 35),
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 3,
    })
    local key = number:Clone()
    key.Name, key.Parent = "PadKey", button
    key.Position, key.Size, key.TextXAlignment =
        UDim2.fromScale(0.68, 0.08), UDim2.fromScale(0.22, 0.17), Enum.TextXAlignment.Right
    local caption = number:Clone()
    caption.Name, caption.Parent, caption.TextWrapped = "Caption", button, true
    caption.Position, caption.Size = UDim2.fromScale(0.1, 0.54), UDim2.fromScale(0.8, 0.34)
    caption.TextXAlignment, caption.TextYAlignment =
        Enum.TextXAlignment.Center, Enum.TextYAlignment.Center
    local status = number:Clone()
    status.Name, status.Parent, status.TextSize = "PadStatus", button, 9
    status.Position, status.Size, status.TextXAlignment =
        UDim2.fromScale(0.12, 0.79), UDim2.fromScale(0.76, 0.10), Enum.TextXAlignment.Center
    local indicator = make("Frame", button, {
        Name = "ReadyLamp",
        Position = UDim2.fromScale(0.15, 0.32),
        Size = UDim2.fromOffset(6, 6),
        BackgroundColor3 = Color3.fromRGB(47, 66, 55),
        BorderSizePixel = 0,
        ZIndex = 3,
    })
    make("UICorner", indicator, { CornerRadius = UDim.new(1, 0) })
    local selectedRing = make("Frame", button, {
        Name = "SelectionOutline",
        Position = UDim2.fromScale(0.1, 0.1),
        Size = UDim2.fromScale(0.8, 0.8),
        BackgroundTransparency = 1,
        Visible = false,
        ZIndex = 4,
    })
    make("UICorner", selectedRing, { CornerRadius = UDim.new(0, 5) })
    make(
        "UIStroke",
        selectedRing,
        {
            Color = Color3.fromRGB(44, 131, 134),
            Thickness = 2,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        }
    )
    local glyph, glyphName
    local function refresh()
        local preview = button:GetAttribute("PreviewAvailable") == true
        local available = button:GetAttribute("AudioReady") == true
        local held = button:GetAttribute("PadHeld") or button:GetAttribute("PadFlash")
        local selected = button:GetAttribute("PadSelected")
        local muted = button:GetAttribute("PadMuted")
        image.ImageColor3 = if held
            then Color3.fromRGB(255, 186, 94)
            elseif available then Color3.fromRGB(244, 239, 212)
            else Color3.fromRGB(145, 154, 143)
        number.Text = button:GetAttribute("Address") or ""
        key.Text = button:GetAttribute("PadKey") or ""
        caption.Text = button:GetAttribute("ShortName") or button:GetAttribute("SampleName") or ""
        local bank = button:GetAttribute("SoundFamily")
            or (button:GetAttribute("Address") or "A"):sub(1, 1)
        selectedRing.Visible = selected == true and not held
        local nextGlyph = button:GetAttribute("PadGlyph")
            or ({ A = "drum", B = "bass", C = "mic", D = "waves" })[bank]
            or "sound"
        if nextGlyph ~= glyphName then
            if glyph then
                glyph:Destroy()
            end
            glyphName = nextGlyph
            glyph = require(script.Parent.GameIcons).make(
                button,
                glyphName,
                Color3.fromRGB(32, 52, 47),
                22
            )
            glyph.Name = "SoundGlyph"
            glyph.AnchorPoint = Vector2.new(0.5, 0.5)
            glyph.Position = UDim2.fromScale(0.53, 0.39)
            glyph.ZIndex = 3
            for _, part in glyph:GetDescendants() do
                if part:IsA("GuiObject") then
                    part.ZIndex = 3
                end
            end
        end
        local small = button.AbsoluteSize.X < 78
        local tiny = button.AbsoluteSize.X < 64
        caption.TextSize, number.TextSize = if small then 9 else 11, if small then 10 else 13
        glyph.Size = UDim2.fromOffset(if small then 17 else 22, if small then 17 else 22)
        indicator.BackgroundColor3 = if held
            then Color3.fromRGB(255, 225, 142)
            elseif available then Color3.fromRGB(88, 202, 143)
            else Color3.fromRGB(74, 84, 72)
        key.Visible, status.Visible, caption.Visible = not small, muted and not tiny, not tiny
        glyph.Position = UDim2.fromScale(0.53, if tiny then 0.55 else 0.34)
        status.TextSize = if small then 8 else 9
        status.Text = if muted
            then "MUTED"
            elseif preview then "READY"
            elseif available then "READY"
            else "NO FILE"
        Tween:Create(scale, TweenInfo.new(0.07), { Scale = if held then 0.94 else 1 }):Play()
    end
    for _, attribute in
        {
            "Address",
            "SampleName",
            "ShortName",
            "SoundFamily",
            "PadGlyph",
            "PadKey",
            "PadMuted",
            "PadSelected",
            "PreviewAvailable",
            "AudioReady",
            "PadHeld",
            "PadFlash",
        }
    do
        button:GetAttributeChangedSignal(attribute):Connect(refresh)
    end
    button:GetPropertyChangedSignal("AbsoluteSize"):Connect(refresh)
    image:GetAttributeChangedSignal("ImageUnavailable"):Connect(function()
        button.BackgroundTransparency = 0
    end)
    refresh()
    return scale
end
function Skin.step(button)
    button:SetAttribute("NoActionIcon", true)
    local light = make("Frame", button, {
        Name = "StepLamp",
        Position = UDim2.new(0.5, -8, 0, 6),
        Size = UDim2.fromOffset(16, 3),
        BorderSizePixel = 0,
        ZIndex = button.ZIndex + 4,
    })
    make("UICorner", light, { CornerRadius = UDim.new(1, 0) })
    local function refresh()
        local active = button:GetAttribute("EnabledStep") == true
        local playhead = button:GetAttribute("Playhead") == true
        light.BackgroundColor3 = if playhead
            then Color3.fromRGB(156, 255, 204)
            elseif active then Color3.fromRGB(255, 201, 100)
            else Color3.fromRGB(59, 77, 66)
        button.BackgroundColor3 = if active
            then Color3.fromRGB(230, 174, 85)
            else Color3.fromRGB(36, 58, 51)
        button.TextColor3 = if active
            then Color3.fromRGB(22, 35, 31)
            else Color3.fromRGB(202, 220, 180)
    end
    button:GetAttributeChangedSignal("EnabledStep"):Connect(refresh)
    button:GetAttributeChangedSignal("Playhead"):Connect(refresh)
    refresh()
end
function Skin.setPadDown(button, held)
    button:SetAttribute("PadHeld", held == true)
end
function Skin.pulse(button)
    local epoch = (button:GetAttribute("PulseEpoch") or 0) + 1
    button:SetAttribute("PulseEpoch", epoch)
    button:SetAttribute("PadFlash", true)
    task.delay(0.13, function()
        if button.Parent and button:GetAttribute("PulseEpoch") == epoch then
            button:SetAttribute("PadFlash", false)
        end
    end)
end
return Skin
