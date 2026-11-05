-- Current task first. The complete authored requirement stays one button away.
local Shared = game.ReplicatedStorage.Shared
local Theme = require(Shared.Theme)
local Objectives = require(Shared.QuayObjectives)
local MissionSteps = require(Shared.QuayMissionSteps)
local Gui = require(script.Parent.GuiFactory)
local VisualSteps = require(script.Parent.VisualSteps)
local View = {}
View.__index = View
function View.new(parent, track)
    local self = setmetatable({}, View)
    self.root = Gui.make("Frame", parent, { Name = "CurrentQuestGuide", Size = UDim2.new(1, -10, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 1 })
    Gui.make("UIListLayout", self.root, { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })
    local function label(order, size, color)
        local l = Gui.label(self.root, "", size, color)
        l.Size, l.AutomaticSize, l.LayoutOrder = UDim2.new(1, 0, 0, 0), Enum.AutomaticSize.Y, order
        return l
    end
    self.title = label(1, 19, Theme.Teal)
    self.title.Font = Enum.Font.Code
    self.steps = VisualSteps.new(self.root, { { "FIND", "route" }, { "MAKE", "pads" }, { "KEEP", "save" } })
    self.steps.root.LayoutOrder = 2
    self.action = label(3, 15, Theme.Ink)
    self.route = Gui.button(self.root, "SHOW ROUTE", function()
        if self.objective then track(self.objective.id) end
    end)
    self.route.Size, self.route.LayoutOrder = UDim2.new(1, 0, 0, 44), 4
    self.route:SetAttribute("UiIcon", "route")
    self.more = Gui.button(self.root, "REQUIREMENTS", function()
        self.expanded = not self.expanded
        self:renderDetails()
    end)
    self.more.Size, self.more.LayoutOrder = UDim2.new(1, 0, 0, 44), 5
    self.more:SetAttribute("UiIcon", "hint")
    self.detail = label(6, 14, Theme.Ink)
    self.detail.Visible = false
    return self
end
function View:renderDetails()
    self.detail.Visible = self.expanded == true
    self.more.Text = if self.expanded then "LESS" else "REQUIREMENTS"
end
function View:update(q, stop)
    local preferred
    if stop then
        for _, id in Objectives.Order do
            local task = Objectives.ById[id]
            if task.stop == stop and not task.optional and not q.progress.completed[id] then preferred = id; break end
        end
    end
    local objective = Objectives.select(q, preferred)
    if self.id ~= (objective and objective.id) then self.expanded = false end
    self.id, self.objective = objective and objective.id, objective
    if not objective then
        self.title.Text, self.action.Text = "CHAPTER KEPT", "Make music, visit a friend, or try another activity."
        self.steps.root.Visible, self.route.Visible, self.more.Visible, self.detail.Visible = false, false, false, false
        return
    end
    self.title.Text = objective.title
    local steps = MissionSteps.project(q, objective)
    local definitions, complete = {}, {}
    for index, text in steps.shortLabels do
        definitions[index], complete[index] = { text, steps.icons[index] }, index <= steps.done
    end
    self.steps:configure(definitions)
    self.steps:update(if steps.done < 3 then steps.done + 1 else nil, complete)
    self.action.Text, self.detail.Text = steps.action, steps.hint
    self.steps.root.Visible, self.route.Visible, self.more.Visible = true, true, true
    self:renderDetails()
end
return View
