-- One filled coin is one earned ten-coin heat. Empty outlined slots need another heat.
local Gui = require(script.Parent.GuiFactory)
local Icons = require(script.Parent.GameIcons)
local Theme = require(game.ReplicatedStorage.Shared.Theme)
local Slots = {}
Slots.__index = Slots
function Slots.new(parent, count, size, gap, z)
    local self = setmetatable({ items = {}, size = size, gap = gap }, Slots)
    self.root = Gui.make("Frame", parent, { Name = "FairCoinSlots", BackgroundTransparency = 1,
        Size = UDim2.fromOffset(count * (size + gap) - gap, size), ZIndex = z or 4 })
    for i = 1, count do
        local slot = Gui.round(Gui.make("Frame", self.root, { Name = "Coin" .. i,
            Position = UDim2.fromOffset((i - 1) * (size + gap), 0), Size = UDim2.fromOffset(size, size),
            BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = z or 4 }), size / 2)
        local outline = Gui.make("UIStroke", slot, { Color = Theme.Stone, Thickness = 1.5 })
        local coin = Icons.make(slot, "coin", Theme.Amber, size)
        coin.ZIndex = z or 4
        for _, child in coin:GetDescendants() do if child:IsA("GuiObject") then child.ZIndex = coin.ZIndex end end
        self.items[i] = { root = slot, outline = outline, coin = coin }
    end
    return self
end
function Slots:update(filled, total)
    total = math.clamp(total or #self.items, 0, #self.items)
    filled = math.clamp(math.floor(filled or 0), 0, total)
    self.root.Size = UDim2.fromOffset(math.max(0, total * (self.size + self.gap) - self.gap), self.size)
    for i, item in self.items do
        item.root.Visible = i <= total
        item.coin.Visible, item.outline.Enabled = i <= filled, i > filled
    end
    self.root:SetAttribute("AccessibleLabel", filled .. " of " .. total .. " ten-coin slots filled")
end
return Slots
