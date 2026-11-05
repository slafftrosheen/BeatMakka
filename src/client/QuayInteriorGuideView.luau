-- Walk to a picture, then activate it. Coordinates/actions are always checked again on the server.
local Shared = game.ReplicatedStorage.Shared
local Catalog = require(Shared.QuayInteriorCatalog)
local Theme = require(Shared.Theme)
local Gui = require(script.Parent.GuiFactory)
local Icons = require(script.Parent.GameIcons)
local Players = game:GetService("Players")
local Guide = {}
Guide.__index = Guide
local choices = { { "set", "PLAY", "pads" }, { "look", "LOOK", "eye" }, { "exit", "OUT", "door" } }
function Guide.new(screen, send)
    local self = setmetatable({ send = send, selected = "set", buttons = {} }, Guide)
    self.route = require(script.Parent.QuayWayfinder).new()
    self.root = Gui.make("Frame", screen, { Name = "RoomPictureActions", Visible = false,
        AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, if game:GetService("UserInputService").TouchEnabled then -112 else -10),
        Size = UDim2.new(1, -24, 0, 72), BackgroundTransparency = 1, ZIndex = 10 })
    Gui.make("UISizeConstraint", self.root, { MaxSize = Vector2.new(336, 72) })
    for index, choice in choices do
        local kind = choice[1]
        local button = Gui.button(self.root, choice[2], function()
            self.selected = kind
            self:render()
            self:activate()
        end)
        button.Position, button.Size = UDim2.fromScale((index - 1) / 3, 0), UDim2.new(1 / 3, -4, 1, 0)
        button:SetAttribute("NoActionIcon", true)
        button.TextYAlignment = Enum.TextYAlignment.Bottom
        local icon = Icons.make(button, choice[3], Theme.Cream, 30)
        icon.Position, icon.ZIndex = UDim2.new(0.5, -15, 0, 5), 4
        for _, child in icon:GetDescendants() do if child:IsA("GuiObject") then child.ZIndex = 4 end end
        local hint = Icons.make(button, "route", Theme.Amber, 18)
        hint.Position, hint.ZIndex = UDim2.new(1, -22, 0, 5), 4
        for _, child in hint:GetDescendants() do if child:IsA("GuiObject") then child.ZIndex = 4 end end
        self.buttons[kind] = { root = button, icon = icon, hint = hint, hintName = "route" }
    end
    self.connection = game:GetService("RunService").Heartbeat:Connect(function() self:render() end)
    return self
end
function Guide:accept(state)
    self.state = state
    local id = state.quay and state.quay.interior
    if id ~= self.id then self.id, self.selected = id, "set" end
    self:render()
end
function Guide:isVisible() return self.root.Visible end
function Guide:activate()
    if not self.root.Visible or not self.near or os.clock() < (self.nextAction or 0) then return end
    self.nextAction = os.clock() + 0.35
    self.send("QuayRoomAction", { id = self.id, kind = self.selected })
end
function Guide:render()
    local s, spec = self.state, self.id and Catalog.ById[self.id]
    local character = Players.LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local inside = root and spec and math.abs(root.Position.X - spec.center.X) < 16
        and math.abs(root.Position.Z - spec.center.Z) < 17 and math.abs(root.Position.Y - spec.center.Y) < 16
    local busy = not s or not s.ready or s.station or s.listening
        or (s.stage and s.stage.open) or (s.concert and s.concert.open)
        or (s.jam and (s.jam.active or s.jam.open)) or (s.quay and s.quay.open)
    local wasVisible = self.root.Visible
    self.root.Visible = inside == true and not busy
    local targets = s and s.quay and s.quay.roomTargets
    local target = targets and targets[self.selected]
    local valid = typeof(target) == "Vector3"
    self.near = valid and root ~= nil and (target - root.Position).Magnitude <= 10
    self.route:update(root and root.Position, target, self.root.Visible and valid and not self.near)
    if not self.root.Visible then return end
    if not wasVisible and game:GetService("UserInputService").GamepadEnabled then
        game:GetService("GuiService").SelectedObject = self.buttons[self.selected].root
    end
    for _, choice in choices do
        local item = self.buttons[choice[1]]
        local selected = choice[1] == self.selected
        item.root.BackgroundColor3 = if selected then Theme.Amber else Theme.Ink
        Icons.tint(item.icon, if selected then Theme.Ink else Theme.Cream)
        local hintName = if selected and self.near then "hand" else "route"
        if item.hintName ~= hintName then
            item.hint:Destroy()
            item.hint = Icons.make(item.root, hintName, Theme.Ink, 18)
            item.hint.Position, item.hint.ZIndex = UDim2.new(1, -22, 0, 5), 4
            for _, child in item.hint:GetDescendants() do if child:IsA("GuiObject") then child.ZIndex = 4 end end
            item.hintName = hintName
        end
        Icons.tint(item.hint, if selected then Theme.Ink else Theme.Amber)
        item.root:SetAttribute("AccessibleLabel", choice[2] .. (if selected and self.near then " / activate" else " / follow the floor route"))
    end
end
function Guide:destroy()
    self.connection:Disconnect(); self.route:destroy(); self.root:Destroy()
end
return Guide
