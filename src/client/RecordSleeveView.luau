-- Reuses Sleeve Studio's three authored motifs/palettes; no external imagery.
local Gui = require(script.Parent.GuiFactory)
local Theme = require(game.ReplicatedStorage.Shared.Theme)
local Sleeve = {}
function Sleeve.new(parent, z)
    z = z or 8
    local root = Gui.make("Frame", parent, { Name = "AuthoredSleeveMark",
        Position = UDim2.fromScale(0.07, 0.68), Size = UDim2.fromScale(0.86, 0.25),
        BackgroundColor3 = Theme.Teal, BorderSizePixel = 0, ZIndex = z })
    local bars = {}
    for index = 1, 8 do
        bars[index] = Gui.make("Frame", root, { Name = "Motif" .. index,
            BackgroundColor3 = Theme.Cream, BorderSizePixel = 0, ZIndex = z + 1 })
    end
    return {
        update = function(_, cover)
            cover = cover or { motif = "waves", palette = "teal" }
            local color = ({ teal = Theme.Teal, coral = Theme.Coral, amber = Theme.Amber })[cover.palette] or Theme.Teal
            parent.BackgroundColor3, root.BackgroundColor3 = color, color
            for index, bar in bars do
                bar.Visible = cover.motif ~= "lantern" or index <= 2
                bar.BackgroundColor3 = if cover.palette == "amber" then Theme.Ink else Theme.Cream
                if cover.motif == "lantern" then
                    bar.Position = if index == 1 then UDim2.fromScale(0.4, 0.12) else UDim2.fromScale(0.32, 0.02)
                    bar.Size = if index == 1 then UDim2.fromScale(0.2, 0.8) else UDim2.fromScale(0.36, 0.12)
                else
                    local height = if cover.motif == "steps" then (if index % 2 == 0 then 0.4 else 0.8) else 0.15
                    bar.Position = UDim2.fromScale((index - 1) / 8 + 0.02,
                        if cover.motif == "waves" then 0.2 + (index % 3) * 0.15 else 0.9 - height)
                    bar.Size = UDim2.fromScale(0.085, height)
                end
            end
        end,
    }
end
return Sleeve
