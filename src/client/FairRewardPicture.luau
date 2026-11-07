-- Authored native pictures of where earned items go; no asset or camera changes.
local Gui = require(script.Parent.GuiFactory)
local Icons = require(script.Parent.GameIcons)
local Theme = require(game.ReplicatedStorage.Shared.Theme)
local Picture = {}
Picture.__index = Picture
function Picture.new(parent, prize)
    local self = setmetatable({ prize = prize }, Picture)
    self.root = Gui.make("Frame", parent, { Name = "RewardOnOwner", Size = UDim2.fromOffset(60, 76), BackgroundTransparency = 1 })
    local owner = Icons.make(self.root, if prize.category == "roamer" then "van" else "people", Theme.Cream, 48)
    owner.Position = UDim2.fromOffset(4, 20)
    local item = Icons.make(self.root, if prize.category == "companion" then "bell" else prize.icon, Theme.Amber, 26)
    self.item = item
    self.wornPosition = if prize.category == "title" then UDim2.fromOffset(18, 0) else UDim2.fromOffset(32, 46)
    item.Position = self.wornPosition
    self.mark = Icons.make(self.root, "bag", Theme.Amber, 20)
    self.markName = "bag"
    self.mark.Position = UDim2.fromOffset(0, 0)
    self.mark.Visible = false
    for _, glyph in { owner, item, self.mark } do
        glyph.ZIndex = 5
        for _, child in glyph:GetDescendants() do if child:IsA("GuiObject") then child.ZIndex = 5 end end
    end
    self.root:SetAttribute("AccessibleLabel", prize.label .. (if prize.category == "roamer" then " / Roamer running lights"
        elseif prize.category == "companion" then " / optional companion charm" else " / title above your avatar"))
    return self
end
function Picture:update(owned, equipped)
    equipped = owned == true and equipped == true
    local name = if equipped then "check" else "bag"
    if self.markName ~= name then
        self.mark:Destroy()
        self.mark = Icons.make(self.root, name, Theme.Amber, 20)
        self.mark.Position, self.mark.ZIndex = UDim2.fromOffset(0, 0), 5
        for _, child in self.mark:GetDescendants() do if child:IsA("GuiObject") then child.ZIndex = 5 end end
        self.markName = name
    end
    self.mark.Visible = owned == true
    self.item.Position = if equipped then self.wornPosition else UDim2.fromOffset(28, 0)
    Icons.tint(self.item, if owned then Theme.Amber else Theme.Stone)
    self.root:SetAttribute("AccessibleLabel", self.prize.label .. (if equipped then " / collected and worn"
        elseif owned then " / collected, not worn yet" else " / not collected") .. (if self.prize.category == "roamer" then " / Roamer lights"
        elseif self.prize.category == "companion" then " / optional companion charm" else " / title above your avatar"))
end
return Picture
