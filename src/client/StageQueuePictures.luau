-- Passive queue positions; never prepares, starts or joins audio.
local W = require(script.Parent.DeviceWidgets)
local Icons = require(script.Parent.GameIcons)
local Pictures = {}
Pictures.__index = Pictures
function Pictures.new(parent)
    local self = setmetatable({ items = {} }, Pictures)
    self.root = W.frame(parent, "QueuePictures")
    for i = 1, 5 do
        local root = W.frame(self.root, "Place" .. i, W.ink)
        root.Position, root.Size, root.ZIndex = UDim2.new((i - 1) / 5, 2, 0, 0), UDim2.new(0.2, -4, 1, 0), 17
        local caption = W.label(root, "Name", "", 11)
        caption.Position, caption.Size, caption.ZIndex = UDim2.fromOffset(2, 36), UDim2.new(1, -4, 0, 22), 19
        caption.TextWrapped, caption.TextTruncate, caption.TextXAlignment = false, Enum.TextTruncate.AtEnd, Enum.TextXAlignment.Center
        local border = W.make("UIStroke", root, { Color = W.text, Thickness = 1, Enabled = false })
        local hand = Icons.make(root, "hand", W.ink, 14)
        hand.Position, hand.ZIndex = UDim2.new(1, -16, 0, 2), 20
        for _, child in hand:GetDescendants() do if child:IsA("GuiObject") then child.ZIndex = 20 end end
        self.items[i] = { root = root, caption = caption, border = border, hand = hand }
    end
    return self
end
function Pictures:update(stage)
    local entries = stage.entries or {}
    self.root.Visible = stage.performer ~= nil or #entries > 0
    for i, item in self.items do
        local entry = entries[i - 1]
        local mine = if i == 1 then stage.hosting else stage.position == i - 1
        item.root.Visible = i == 1 or entry ~= nil
        local offered = mine and stage.canStart and i == 2
        local icon = if i == 1 then (if stage.performer then "sound" else "pads")
            elseif offered then "play" else "people"
        local color = if mine then W.ink else W.text
        item.root.BackgroundColor3 = if mine then W.amber else W.ink
        item.border.Enabled, item.hand.Visible = mine, mine
        item.caption.TextColor3 = color
        item.caption.Text = if offered then tostring(math.max(0, math.ceil((stage.offerEndsAt or 0) - workspace:GetServerTimeNow()))) .. "s"
            elseif mine then "YOU" elseif i == 1 then (stage.performer or "FREE") else entry and entry.performer or ""
        if item.icon ~= icon then
            if item.picture then item.picture:Destroy() end
            item.picture = Icons.make(item.root, icon, color, 28)
            item.picture.Position, item.picture.ZIndex = UDim2.new(0.5, -14, 0, 4), 19
            for _, child in item.picture:GetDescendants() do if child:IsA("GuiObject") then child.ZIndex = 19 end end
            item.icon = icon
        end
        Icons.tint(item.picture, color)
        item.root:SetAttribute("AccessibleLabel", if i == 1 then "On stage: " .. (stage.performer or "nobody")
            elseif entry then (if mine then "Your set" else entry.performer) .. " / queue position " .. (i - 1)
                .. " / " .. entry.title .. " / " .. entry.venue .. (if offered then " / press Play now" else " / waiting") else "")
    end
end
return Pictures
