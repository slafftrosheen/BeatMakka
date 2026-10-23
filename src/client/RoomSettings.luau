local Shared = game.ReplicatedStorage.Shared
local Cosmetics = require(Shared.CosmeticCatalog)
local Catalog = require(Shared.RoomCatalog)
local Gui = require(script.Parent.GuiFactory)
local Settings = {}
Settings.__index = Settings

function Settings.new(parent, command)
    local self = setmetatable({}, Settings)
    self.title = Gui.label(parent, "YOUR WORKSHOP", 15)
    self.title.Name = "RoomStatus"
    self.title.Size = UDim2.new(1, -8, 0, 84)
    self.title.AutomaticSize = Enum.AutomaticSize.Y
    self.title.LayoutOrder = 6
    self.buttons = {}
    for index, field in Catalog.Fields do
        local button = Gui.button(parent, "Workshop " .. field, function()
            self:cycle(field)
        end)
        button.Name = "Room_" .. field
        button.Size = UDim2.new(1, -8, 0, 48)
        button.LayoutOrder = 6 + index
        self.buttons[field] = button
    end
    self.command = command
    return self
end

function Settings:cycle(field)
    local room = self.state and self.state.room
    if not room or not room.id or not self.state.ready then
        return
    end
    if field == "decor" and not room.decorUnlocked then
        return
    end
    local order = if field == "finish"
        then Cosmetics.Order
        elseif field == "sign" then Catalog.SignOrder
        elseif field == "decor" then Catalog.DecorOrder
        else nil
    if not order then
        return
    end
    local current = table.find(order, room.choices[field]) or 1
    self.command("Room", field, order[current % #order + 1])
end

function Settings:update(state)
    self.state = state
    local room = state.room
    if not room then
        self.title.Text = "Workshop information loading..."
        return
    end
    self.title.Text = if room.id
        then (if room.id == "Room_1" then "Left workshop" else "Right workshop")
            .. " / your workshop. Everyone sees your decor.\nChanges apply nearby; Save profile keeps them. "
            .. (
                if state.saveMode == "session"
                    then "This Studio session only."
                    elseif state.saveMode == "unavailable" then "Cloud saving unavailable."
                    else "Cloud save available."
            )
        else "Visitor / both workshops occupied. A free bay will be assigned when available."
    local enabled = room.id ~= nil and state.ready
    for field, button in self.buttons do
        local locked = field == "decor" and not room.decorUnlocked
        button.Active = enabled and not locked
        button.Selectable = enabled and not locked
        button.AutoButtonColor = enabled and not locked
        button.TextTransparency = if enabled and not locked then 0 else 0.35
    end
    self.buttons.finish.Text = "Workshop finish: " .. Cosmetics.Sets[room.choices.finish].label
    self.buttons.sign.Text = "Workshop sign: " .. Catalog.Signs[room.choices.sign]
    self.buttons.decor.Text = if not room.decorUnlocked
        then "Vinyl decor locked / discover Quay metal"
        elseif room.choices.decor == "vinyl" then "Shelf decor: vinyl crate"
        else "Shelf decor: none"
end

return Settings
