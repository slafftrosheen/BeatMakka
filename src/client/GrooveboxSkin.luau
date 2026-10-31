-- Three shared local UI images; every label, hit target and state remains native.
local AssetService = game:GetService("AssetService")
local TextService = game:GetService("TextService")
local Gui = require(script.Parent.GuiFactory)
local Theme = require(game.ReplicatedStorage.Shared.Theme)
local textureUri = require(script.Parent.LocalTextureUri)
local Skin = {}
local images, waiting = {}, {}

function Skin.focus(button)
    -- Replace Studio's blue default selection image with the native cream ring.
    button.SelectionImageObject = Gui.make("Frame", button, {
        Name = "FocusSelection",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        BorderSizePixel = 0,
        Active = false,
    })
end

function Skin.image(parent, name, properties)
    local label = Gui.make("ImageLabel", parent, {
        Name = name,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Active = false,
        ZIndex = 1,
    })
    for key, value in properties or {} do
        label[key] = value
    end
    if images[name] then
        label.ImageContent = Content.fromObject(images[name])
    elseif waiting[name] then
        table.insert(waiting[name], label)
    else
        waiting[name] = { label }
        task.spawn(function()
            local ok, image = pcall(function()
                return AssetService:CreateEditableImageAsync(
                    Content.fromUri(textureUri("rbxasset://needle-quay/ui-mki/" .. name .. ".png"))
                )
            end)
            if ok and image then
                images[name] = image
                for _, target in waiting[name] do
                    if target.Parent then
                        target.ImageContent = Content.fromObject(image)
                    end
                end
            else
                for _, target in waiting[name] do
                    if target.Parent then
                        target:SetAttribute("ImageUnavailable", true)
                    end
                end
                warn("MK-I UI material unavailable: " .. name)
            end
            waiting[name] = nil
        end)
    end
    return label
end

function Skin.pad(button)
    Skin.focus(button)
    button.BackgroundTransparency, button.AutoButtonColor = 1, false
    local gradient = button:FindFirstChildOfClass("UIGradient")
    if gradient then
        gradient:Destroy()
    end
    local outline
    for _, child in button:GetChildren() do
        if child:IsA("UIStroke") then
            if child.Name == "FocusRing" then
                child.Color, child.Transparency, child.Thickness = Theme.Cream, 0, 2
            else
                outline = child
                child.Transparency = 1
            end
        end
    end
    local image = Skin.image(button, "pad", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(1.08, 1.08),
    })
    image.Name = "PadSurface"
    image:GetAttributeChangedSignal("ImageUnavailable"):Connect(function()
        button.BackgroundTransparency = 0
        if outline then
            outline.Transparency = 0.15
        end
    end)
    local number = Gui.label(button, "", 11, Theme.Ink)
    number.Name, number.Font, number.ZIndex = "PadNumber", Enum.Font.Code, 3
    local caption = Gui.label(button, "", 14, Theme.Ink)
    caption.Name, caption.Font, caption.ZIndex = "Caption", Theme.Bold, 3
    local status = Gui.label(button, "", 9, Theme.Ink)
    status.Name, status.Font, status.ZIndex = "PadStatus", Enum.Font.Code, 3
    local stripe = Gui.round(
        Gui.make("Frame", button, {
            Name = "SelectedMarker",
            BorderSizePixel = 0,
            BackgroundColor3 = Theme.Ink,
            ZIndex = 3,
        }),
        2
    )
    local function refresh()
        local size = button.AbsoluteSize.X
        local micro, compact = size < 60, size < 88
        local inset = if micro then 7 else 12
        local muted = button:GetAttribute("PadMuted")
        number.Text =
            string.format("%02d%s", button.LayoutOrder, if muted and compact then " M" else "")
        number.Position, number.Size =
            UDim2.fromOffset(inset, if micro then 3 else 8), UDim2.new(1, -inset * 2, 0, 14)
        number.TextSize = if micro then 9 else 11
        caption.Text = button:GetAttribute(if compact then "ShortName" else "SampleName") or ""
        local textSize = if micro then 10 elseif compact then 11 else 14
        -- Wrap between words, never in the middle of Tambourine or CHORD.
        local available = math.max(1, size - inset * 2)
        for word in caption.Text:gmatch("%S+") do
            while
                textSize > 9
                and TextService:GetTextSize(word, textSize, Theme.Bold, Vector2.new(1000, 100)).X
                    > available
            do
                textSize -= 1
            end
        end
        caption.TextSize = textSize
        caption.Position = UDim2.fromOffset(inset, if micro then 15 elseif compact then 23 else 28)
        caption.Size = UDim2.new(1, -inset * 2, 0, if micro then 23 elseif compact then 28 else 34)
        caption.TextYAlignment = Enum.TextYAlignment.Center
        status.Text = if muted then "MUTED" else "KEY " .. (button:GetAttribute("PadKey") or "")
        status.Visible = not compact
        status.Position, status.Size = UDim2.new(0, inset, 1, -27), UDim2.new(1, -inset * 2, 0, 12)
        stripe.Visible = button:GetAttribute("PadSelected") == true
        stripe.Position, stripe.Size =
            UDim2.fromOffset(if micro then 5 else 8, 8), UDim2.new(0, 2, 1, -20)
    end
    button:GetPropertyChangedSignal("AbsoluteSize"):Connect(refresh)
    for _, attribute in { "SampleName", "ShortName", "PadKey", "PadMuted", "PadSelected" } do
        button:GetAttributeChangedSignal(attribute):Connect(refresh)
    end
    button:GetPropertyChangedSignal("BackgroundColor3"):Connect(function()
        image.ImageColor3 = button.BackgroundColor3
    end)
    button.TextTransparency = 1
    image.ImageColor3 = button.BackgroundColor3
    refresh()
    local scale = Gui.make("UIScale", image, { Scale = 1 })
    button:SetAttribute("SkinReady", true)
    return scale
end

return Skin
