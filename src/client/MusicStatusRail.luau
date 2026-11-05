-- Separate transport/save signals keep the selected musical source legible.
local Gui = require(script.Parent.GuiFactory)
local Theme = require(game.ReplicatedStorage.Shared.Theme)
local Rail = {}
Rail.__index = Rail
local function label(parent, name)
    return Gui.make("TextLabel", parent, { Name = name, Text = "", Font = Enum.Font.Code,
        TextSize = 11, TextColor3 = Theme.Cream, BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
        BorderSizePixel = 0, ZIndex = 6 })
end
function Rail.new(parent)
    local self = setmetatable({}, Rail)
    self.root = Gui.make("Frame", parent, { Name = "MusicContextRail", BorderSizePixel = 0,
        BackgroundColor3 = Theme.Screen, ZIndex = 5 })
    self.lamp = Gui.make("Frame", self.root, { Name = "TransportLamp", Position = UDim2.fromOffset(3, 9),
        Size = UDim2.fromOffset(6, 6), BorderSizePixel = 0, BackgroundColor3 = Theme.Cream, ZIndex = 6 })
    Gui.round(self.lamp, 3)
    self.transport, self.save, self.source = label(self.root, "Transport"), label(self.root, "SaveBoundary"), label(self.root, "Source")
    return self
end
function Rail:update(state, source, address, fullCaption)
    local save = if state.saving then "SAVING" elseif state.saveMode == "unavailable" then "NO SAVE"
        elseif state.dirty then "UNSAVED" elseif not state.hasSave then "NEW"
        elseif state.saveMode == "session" then "SESSION" else "SAVED"
    self.transport.Text = if state.recording then "REC" elseif state.playing then "PLAY" else "STOP"
    self.lamp.BackgroundColor3 = if state.recording then Theme.Coral elseif state.playing then Theme.Amber else Theme.Cream
    self.save.Text, self.save.TextColor3 = save, if save == "SAVED" or save == "SESSION" then Theme.Cream else Theme.Amber
    self.source.Text = address .. " / " .. source
    self.save:SetAttribute("AccessibleLabel", if save == "SESSION" then "Saved for this Studio session only"
        elseif save == "NO SAVE" then "Temporary work: storage unavailable" else save)
    self.root:SetAttribute("AccessibleLabel", fullCaption)
    self.source:SetAttribute("FullTitle", source)
end
function Rail:resize(width)
    self.transport.Position, self.transport.Size = UDim2.fromOffset(15, 0), UDim2.fromOffset(36, 24)
    self.save.Position, self.save.Size = UDim2.fromOffset(58, 0), UDim2.fromOffset(64, 24)
    self.source.Position, self.source.Size = UDim2.fromOffset(132, 0), UDim2.fromOffset(math.max(0, width - 134), 24)
end
return Rail
