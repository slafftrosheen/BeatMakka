-- A receipt for this session's set, never a saved-song or reward badge.
local W = require(script.Parent.DeviceWidgets)
local Icons = require(script.Parent.GameIcons)
local Picture = {}
Picture.__index = Picture
function Picture.new(parent)
    local self = setmetatable({}, Picture)
    self.root = W.frame(parent, "SetFinishPicture")
    self.heading = W.label(self.root, "Outcome", "", 20, W.amber)
    self.heading.Position, self.heading.Size, self.heading.ZIndex = UDim2.fromOffset(64, 2), UDim2.new(1, -68, 0, 32), 19
    self.title = W.label(self.root, "PerformedMusic", "", 12)
    self.title.Position, self.title.Size, self.title.ZIndex = UDim2.fromOffset(64, 36), UDim2.new(1, -68, 0, 38), 19
    self.title.TextTruncate, self.title.TextWrapped = Enum.TextTruncate.AtEnd, true
    return self
end
function Picture:update(result)
    if not result then return end
    local icon = if result.completed then "check" else "stop"
    if self.icon ~= icon then
        if self.glyph then self.glyph:Destroy() end
        self.glyph = Icons.make(self.root, icon, W.amber, 48)
        self.glyph.Position, self.glyph.ZIndex = UDim2.fromOffset(4, 12), 19
        for _, child in self.glyph:GetDescendants() do if child:IsA("GuiObject") then child.ZIndex = 19 end end
        self.icon = icon
    end
    self.heading.Text = if result.completed then "PLAYED!" elseif result.mode == "practice" then "LOOP STOPPED" else "STOPPED"
    self.title.Text = result.title or "YOUR SET"
    self.root:SetAttribute("AccessibleLabel", self.heading.Text .. " / " .. self.title.Text .. ". Choose Again to select music, Studio to create, or Out to return to the room. This does not save music.")
end
return Picture
