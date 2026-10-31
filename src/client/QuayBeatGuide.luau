-- Read-only compatibility guide; all evidence is projected by the current server model.
-- The main instrument now teaches Sequence / Song / Library directly.
local Shared = game.ReplicatedStorage.Shared
local Objectives = require(Shared.QuayObjectives)
local Theme = require(Shared.Theme)
local Gui = require(script.Parent.GuiFactory)
local Guide = {}
Guide.__index = Guide
function Guide.new(parent, workshop)
    local self = setmetatable({ workshop = workshop }, Guide)
    self.root = Gui.make("Frame", parent, {
        Name = "VisualSequenceGuide",
        Position = UDim2.fromOffset(0, 28),
        Size = UDim2.new(1, 0, 0, 64),
        BackgroundColor3 = Theme.Ink,
        Visible = false,
    })
    self.label = Gui.label(self.root, "", 13, Theme.Amber)
    self.label.Size, self.label.Position = UDim2.new(1, -16, 1, -4), UDim2.fromOffset(8, 2)
    return self
end
function Guide:update(state, _)
    local objective = Objectives.select(state.quay)
    local id = objective and objective.id
    self.root.Visible = id == "NQ-Q02" or id == "NQ-Q05" or id == "NQ-Q07" or id == "NQ-Q09"
    if not self.root.Visible then
        return false
    end
    local evidence = state.quay.evidence
    self.label.Text = if id == "NQ-Q02"
        then "Sequence / ready Quay metal at four distinct rhythmic positions. " .. tostring(
            evidence.metalSteps
        ) .. "/4"
        elseif
            id == "NQ-Q05"
        then "Save Sequence / keep your original and save a musically distinct named variation."
        elseif
            id == "NQ-Q07"
        then "Song / add an owned saved sequence, then Save Draft. Finish later."
        else "Sequence / teaching bar "
            .. tostring(evidence.teachingBar)
            .. ": ready I03 at ticks 0, 960, 1920, 2880."
    return true
end
return Guide
