-- One Roamer-facing view of the existing workshop finish/sign/decor fields.
-- No parallel inventory, arbitrary text, asset placement or ownership flag.
local Shared = game:GetService("ReplicatedStorage").Shared
local Catalog = require(Shared.RoomCatalog)
local Cosmetics = require(Shared.CosmeticCatalog)
local Theme = require(Shared.Theme)
local Gui = require(script.Parent.GuiFactory)
local Panel = {}
Panel.__index = Panel

local function label(parent, name, order, text, size)
    local item = Gui.label(parent, text or "", size or 14, Theme.Ink)
    item.Name = name
    item.Font = Enum.Font.Code
    item.Size = UDim2.new(1, -16, 0, 0)
    item.AutomaticSize = Enum.AutomaticSize.Y
    item.LayoutOrder = order
    item.TextWrapped = true
    return item
end

local function button(parent, name, order, title, action)
    local item = Gui.button(parent, title, action)
    item.Name = name
    item.LayoutOrder, item.Size = order, UDim2.new(1, -16, 0, 48)
    item.TextWrapped = true
    item.TextSize = 13
    item.Font = Enum.Font.Code
    item:SetAttribute("AccessibleLabel", title)
    return item
end

local function active(control, enabled)
    enabled = enabled == true
    control.Active, control.Selectable, control.AutoButtonColor =
        enabled, enabled, enabled
    control.TextTransparency = if enabled then 0 else 0.35
end

function Panel.new(parent, send)
    local self = setmetatable({ send = send, controls = {} }, Panel)
    self.root = Gui.make("Frame", parent, {
        Name = "YourRoamerStudio", BackgroundColor3 = Theme.Cream,
        BackgroundTransparency = 0.08, BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, -10, 0, 0), LayoutOrder = 2,
    })
    Gui.round(self.root, 10)
    Gui.make("UIStroke", self.root, {
        Color = Theme.FadedTeal, Thickness = 1, Transparency = 0.4,
    })
    Gui.make("UIPadding", self.root, {
        PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
    })
    Gui.make("UIListLayout", self.root, {
        Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder,
    })
    self.heading = label(self.root, "RoamerHeading", 0, "YOUR ROAMER / PERSONAL STUDIO", 19)
    self.status = label(self.root, "RoamerStatus", 1,
        "Your existing workshop choices travel with your Roamer.", 14)
    for index, field in Catalog.Fields do
        local entry = field
        self.controls[field] = button(self.root, "Roamer_" .. field, index + 1,
            "CHOOSE " .. string.upper(field), function()
                self:cycle(entry)
            end)
    end
    self.shelf = button(self.root, "OpenBeatShelf", 6, "OPEN MY BEAT SHELF", function()
        self.send("QuayShelf")
    end)
    self.save = button(self.root, "SaveRoamerLook", 7, "SAVE STUDIO CHOICES", function()
        self.send("QuaySave")
    end)
    self.footer = label(self.root, "RoamerBoundaries", 8,
        "Finish and decor change only the cosmetic shell. Neither your music nor other players' studios are edited.", 13)
    return self
end

function Panel:cycle(field)
    local state = self.state
    local quay, room = state and state.quay, state and state.room
    if not state or not state.ready or not quay or not quay.ownsVan
        or not quay.nearVan or not room or not room.choices or state.saving then
        return
    end
    if field == "decor" and not room.decorUnlocked then return end
    local order = if field == "finish" then Cosmetics.Order
        elseif field == "sign" then Catalog.SignOrder
        elseif field == "decor" then Catalog.DecorOrder
        else nil
    if not order then return end
    local position = table.find(order, room.choices[field]) or 1
    self.send("QuayRoamerSet", {
        key = field, value = order[position % #order + 1],
    })
end

function Panel:update(state)
    self.state = state
    local quay, room = state and state.quay, state and state.room
    local owned = state and state.ready == true and quay
        and quay.ownsVan == true and room and room.id ~= nil
    local adjacent = owned and quay.nearVan == true
    local working = adjacent and state.saving ~= true
    local choices = room and room.choices or {}
    self.status.Text = if not owned
        then "No personal Roamer bay is assigned. Your saved room choices are retained until one is available."
        elseif not adjacent
        then "Your Roamer is parked at " .. tostring(quay.progress and quay.progress.parking or "the quay")
            .. ". Stand beside its studio door to change its exterior or enter your Beat Shelf."
        else "YOUR PARKED STUDIO / OWNED\n"
            .. (if state.saving then "SAVING..."
                elseif state.dirty then "UNSAVED CHANGES"
                elseif state.saveMode == "session" then "STUDIO SESSION SAVE ONLY"
                else "Review the save acknowledgement before leaving.")
    for field, control in self.controls do
        active(control, working and (field ~= "decor" or room.decorUnlocked))
    end
    local finish = Cosmetics.Sets[choices.finish] or Cosmetics.Sets.quay
    local sign = Catalog.Signs[choices.sign] or Catalog.Signs.records
    self.controls.finish.Text = "ROAMER FINISH / " .. finish.label .. " / CHANGE"
    self.controls.sign.Text = "ROAMER SIGN / " .. sign .. " / CHANGE"
    self.controls.decor.Text = if not room or not room.decorUnlocked
        then "VINYL EMBLEM / DISCOVER QUAY METAL"
        elseif choices.decor == "vinyl" then "VINYL EMBLEM / DISPLAYED / CHANGE"
        else "VINYL EMBLEM / NONE / CHANGE"
    for _, control in self.controls do
        control:SetAttribute("AccessibleLabel", control.Text)
    end
    active(self.shelf, adjacent)
    active(self.save, state and state.ready and not state.saving)
    self.save.Text = if state and state.saving then "SAVING..."
        elseif state and state.saveMode == "session" then "SAVE / STUDIO SESSION ONLY"
        elseif state and state.saveMode == "unavailable" then "SAVE UNAVAILABLE"
        else "SAVE STUDIO CHOICES"
    if state and state.saveMode == "unavailable" then active(self.save, false) end
    self.save:SetAttribute("AccessibleLabel", self.save.Text)
    self.footer.Text = if state and state.saveMode == "session"
        then "Saved choices last this Studio session only. Your Roamer uses the same saved workshop fields."
        elseif state and state.saveMode == "unavailable"
        then "Persistence unavailable. Visual changes can remain temporary; no cloud durability is claimed."
        else "This shares the existing workshop save. A save acknowledgement, not changing the finish, confirms persistence."
end

return Panel
