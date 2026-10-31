-- Fixed cosmetic mounts. No navigation, functional targets or arbitrary placement.
local Theme = require(game.ReplicatedStorage.Shared.Theme)
local Assets = require(script.Parent.AssetSpawner)
local Builder = {}

function Builder.build(parent)
    local rooms = {}
    for index, x in { -8, 8 } do
        local model = Instance.new("Model")
        model.Name = "Room_" .. index
        model:SetAttribute("PersonalWorkshop", true)
        model:SetAttribute("RoomStationId", "Station_" .. index)
        model:SetAttribute("Finish", "quay")
        model:SetAttribute("Sign", "records")
        model:SetAttribute("Decor", "none")
        model.Parent = parent
        local frame = Assets.part(
            model,
            "SignBacking",
            Vector3.new(6.4, 1.8, 0.2),
            CFrame.new(x, 8.7, 10.5),
            Theme.Teal,
            false
        )
        frame:SetAttribute("RoomTint", true)
        local shelf = Assets.place(
            model,
            "P05",
            CFrame.new(x, 10.4, 10.5),
            Vector3.new(6, 0.7, 1.5),
            Theme.Walnut
        )
        local anchor = Assets.part(
            model,
            "SignMount",
            Vector3.new(6, 1.4, 0.05),
            CFrame.new(x, 8.7, 10.35),
            Theme.Ink,
            false
        )
        local gui = Instance.new("SurfaceGui")
        gui.Name = "WorkshopSign"
        gui.Face = Enum.NormalId.Front
        gui.CanvasSize = Vector2.new(480, 144)
        gui.LightInfluence = 0
        gui.Parent = anchor
        local text = Instance.new("TextLabel")
        text.Name = "OwnerSign"
        text.Size = UDim2.fromScale(1, 1)
        text.BackgroundColor3 = Theme.Ink
        text.TextColor3 = Theme.Cream
        text.TextSize = 44
        text.TextWrapped = true
        text.Font = Theme.Bold
        text.Text = "RECORD SHOP\nAVAILABLE WORKSHOP"
        text.Parent = gui
        local decor = Instance.new("Folder")
        decor.Name = "FixedDecor"
        decor.Parent = model
        rooms[model.Name] = {
            model = model,
            anchor = anchor,
            label = text,
            shelf = shelf,
            decor = decor,
            x = x,
            stationId = "Station_" .. index,
        }
    end
    return rooms
end

return Builder
