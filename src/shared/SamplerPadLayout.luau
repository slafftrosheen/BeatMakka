-- Canonical sampler mapping: Pad_01 is the far/top-left control, Pad_16 is
-- the near/bottom-right control when viewed from above with the front at -Z.
local SamplerPadLayout = {}

local PAD_SIZE = 0.72
local PAD_GAP = 0.13
local FIRST_X = -2.16
local FIRST_Z = 1.455
local PAD_HEIGHT = 1.31

function SamplerPadLayout.getPads()
    local pads = table.create(16)
    local index = 1

    for row = 1, 4 do
        for column = 1, 4 do
            pads[index] = {
                id = index,
                name = string.format("Pad_%02d", index),
                row = row,
                column = column,
                size = Vector3.new(PAD_SIZE, 0.08, PAD_SIZE),
                position = Vector3.new(
                    FIRST_X + (column - 1) * (PAD_SIZE + PAD_GAP),
                    PAD_HEIGHT,
                    FIRST_Z - (row - 1) * (PAD_SIZE + PAD_GAP)
                ),
            }
            index += 1
        end
    end

    return pads
end

function SamplerPadLayout.createTargets(parent: Instance, housingPivot: CFrame): Folder
    local folder = Instance.new("Folder")
    folder.Name = "PadTargets"
    folder.Parent = parent

    for _, pad in SamplerPadLayout.getPads() do
        local target = Instance.new("Part")
        target.Name = pad.name
        target.Anchored = true
        target.CanCollide = false
        target.CanQuery = true
        target.CanTouch = false
        target.CastShadow = false
        target.Material = Enum.Material.SmoothPlastic
        target.Color = Color3.fromRGB(44, 48, 49)
        target.Size = pad.size
        target.CFrame = housingPivot * CFrame.new(pad.position)
        target:SetAttribute("PadId", pad.id)
        target:SetAttribute("Row", pad.row)
        target:SetAttribute("Column", pad.column)
        target.Parent = folder
        local face = Instance.new("SurfaceGui")
        face.Name = "PadNumber"
        face.Face = Enum.NormalId.Top
        face.CanvasSize = Vector2.new(128, 128)
        face.LightInfluence = 1
        face.Parent = target
        local text = Instance.new("TextLabel")
        text.Size = UDim2.fromScale(1, 1)
        text.BackgroundTransparency = 1
        text.Font = Enum.Font.GothamBold
        text.TextColor3 = Color3.fromRGB(232, 216, 183)
        text.TextSize = 54
        text.Text = string.format("%02d", pad.id)
        text.Parent = face
    end

    return folder
end

return SamplerPadLayout
