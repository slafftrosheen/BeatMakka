local Shared = game.ReplicatedStorage.Shared
local Discoveries = require(Shared.DiscoveryCatalog)
local Missions = require(Shared.NeighborhoodMissions)
local Gui = require(script.Parent.GuiFactory)
local Guide = {}
Guide.__index = Guide

function Guide.new(parent)
    local self = setmetatable({ cards = {}, open = false }, Guide)
    self.frame = Gui.make("Frame", parent, {
        Name = "VirtualRecorder",
        Size = UDim2.new(1, -8, 0, 48),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = 2,
    })
    Gui.make(
        "UIListLayout",
        self.frame,
        { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) }
    )
    self.toggle = Gui.button(self.frame, "Virtual recorder / Jobs 0/3 / Open guide", function()
        self:setOpen(not self.open)
    end)
    self.toggle.Size = UDim2.new(1, 0, 0, 48)
    self.toggle.LayoutOrder = 1
    self.body = Gui.make("Frame", self.frame, {
        Name = "RecorderDetails",
        Size = UDim2.fromScale(1, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Visible = false,
        LayoutOrder = 2,
    })
    Gui.make(
        "UIListLayout",
        self.body,
        { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 12) }
    )
    self.intro = Gui.label(self.body, "", 14)
    self.intro.Size = UDim2.new(1, 0, 0, 84)
    self.intro.AutomaticSize = Enum.AutomaticSize.Y
    self.intro.LayoutOrder = 1
    for index, id in Discoveries.Order do
        local card = Gui.label(self.body, "", 14)
        card.Name = "Recorder_" .. id
        card.Size = UDim2.new(1, 0, 0, 120)
        card.AutomaticSize = Enum.AutomaticSize.Y
        card.LayoutOrder = index + 1
        self.cards[id] = card
    end
    return self
end

function Guide:setOpen(open)
    self.open = open == true
    self.body.Visible = self.open
    if self.state then
        self:update(self.state)
    end
end

function Guide:update(state)
    self.state = state
    local progress = state.neighborhood
        or { completed = 0, earned = {}, objective = "Meet Mica to begin the neighborhood jobs." }
    self.toggle.Text = string.format(
        "Virtual recorder / Jobs %d/3 / %s",
        progress.completed,
        if self.open then "Close guide" else "Open guide"
    )
    self.intro.Text = "Prerecorded game sounds, not microphone recording. Choose a sound bank and pad, then assign a collected sound. Save named sequences; arrange sections in Song Mode and Save Draft. Finish & Save Song is separate and needs approved audio.\nNEXT: "
        .. progress.objective
        .. (
            if state.saveMode == "session"
                then "\nStudio progress lasts for this session only."
                elseif
                    state.saveMode == "unavailable"
                then "\nSaving unavailable: rewards cannot be kept yet."
                else ""
        )
    for index, id in Discoveries.Order do
        local source = Discoveries.ById[id]
        local jobId = Missions.Order[index]
        local job = Missions.Definitions[jobId]
        local collected = state.unlocked and state.unlocked[id] == true
        self.cards[id].Text = source.label
            .. " / "
            .. (if collected then "COLLECTED" else "FIND IN THE SOUND ALLEY")
            .. "\n"
            .. source.origin
            .. " "
            .. source.use
            .. "\n"
            .. job.title
            .. ": "
            .. (if progress.earned[jobId] then "COMPLETE / " .. job.reward else job.objective)
    end
end

return Guide
