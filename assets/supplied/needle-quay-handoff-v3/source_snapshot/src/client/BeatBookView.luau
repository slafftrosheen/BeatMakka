local Shared = game:GetService("ReplicatedStorage").Shared
local Theme = require(Shared.Theme)
local Book = require(Shared.BeatBook)
local Gui = require(script.Parent.GuiFactory)
local BeatBookView = {}
BeatBookView.__index = BeatBookView

function BeatBookView.new(parent, callbacks)
    local self =
        setmetatable({ callbacks = callbacks, selected = 1, slots = {}, beats = {} }, BeatBookView)
    local slots = Gui.make("Frame", parent, {
        Name = "PatternSlots",
        Size = UDim2.new(1, -6, 0, 76),
        BackgroundTransparency = 1,
        LayoutOrder = 3,
    })
    local title = Gui.label(slots, "PATTERNS / A - D", 15)
    title.Font = Theme.Bold
    title.Size = UDim2.new(1, 0, 0, 24)
    local row = Gui.make("Frame", slots, {
        Position = UDim2.fromOffset(0, 30),
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundTransparency = 1,
    })
    Gui.make("UIGridLayout", row, {
        CellSize = UDim2.new(0.25, -6, 0, 44),
        CellPadding = UDim2.fromOffset(8, 0),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    for index = 1, Book.SlotCount do
        local button = Gui.button(row, Book.SlotLabels[index], function()
            if self.state and self.state.book.activeSlot ~= index then
                self.confirmation = nil
                callbacks.command("SelectSlot", index)
            end
        end)
        button.Name = "Slot_" .. Book.SlotLabels[index]
        button.LayoutOrder = index
        self.slots[index] = button
    end
    local shelf = Gui.round(Gui.make("Frame", parent, {
        Name = "BeatShelf",
        Size = UDim2.new(1, -6, 0, 272),
        BackgroundColor3 = Theme.Stone,
        BorderSizePixel = 0,
        LayoutOrder = 6,
    }))
    local shelfTitle = Gui.label(shelf, "YOUR BEAT SHELF / Select a position", 15)
    shelfTitle.Font = Theme.Bold
    shelfTitle.Position = UDim2.fromOffset(10, 8)
    shelfTitle.Size = UDim2.new(1, -20, 0, 34)
    local grid = Gui.make("Frame", shelf, {
        Position = UDim2.fromOffset(10, 48),
        Size = UDim2.new(1, -20, 0, 96),
        BackgroundTransparency = 1,
    })
    Gui.make("UIGridLayout", grid, {
        CellSize = UDim2.new(1 / 3, -6, 0, 44),
        CellPadding = UDim2.fromOffset(8, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    for index = 1, Book.ShelfCapacity do
        local button = Gui.button(grid, string.format("Beat %02d\nEMPTY", index), function()
            self.selected = index
            self.confirmation = nil
            if self.state then
                self:update(self.state)
            end
        end)
        button.Name = string.format("Beat_%02d", index)
        button.LayoutOrder = index
        self.beats[index] = button
    end
    self.store = Gui.button(shelf, "Save to shelf", function()
        self:act("ShelfStore")
    end)
    self.store.Name = "ShelfStore"
    self.store.Position = UDim2.fromOffset(10, 154)
    self.store.Size = UDim2.new(0.5, -14, 0, 44)
    self.load = Gui.button(shelf, "Load beat", function()
        self:act("ShelfLoad")
    end)
    self.load.Name = "ShelfLoad"
    self.load.Position = UDim2.new(0.5, 4, 0, 154)
    self.load.Size = UDim2.new(0.5, -14, 0, 44)
    self.detail = Gui.label(shelf, "", 13)
    self.detail.Position = UDim2.fromOffset(10, 204)
    self.detail.Size = UDim2.new(1, -20, 0, 58)
    local quest = Gui.round(Gui.make("Frame", parent, {
        Name = "MicasRequest",
        Size = UDim2.new(1, -6, 0, 124),
        BackgroundColor3 = Theme.Teal,
        BorderSizePixel = 0,
        LayoutOrder = 11,
    }))
    self.questTitle = Gui.label(quest, "MICA / A TUNE FOR THE QUAY", 15, Theme.Cream)
    self.questTitle.Font = Theme.Bold
    self.questTitle.Position = UDim2.fromOffset(12, 8)
    self.questTitle.Size = UDim2.new(1, -24, 0, 32)
    self.questBody = Gui.label(quest, "Meet Mica in the sound alley.", 14, Theme.Cream)
    self.questBody.Position = UDim2.fromOffset(12, 44)
    self.questBody.Size = UDim2.new(1, -24, 0, 72)
    return self
end

function BeatBookView:act(action)
    local state = self.state
    if not state or not state.ready then
        return
    end
    if state.saving then
        self.callbacks.notice("Wait for the current save to finish.")
        return
    end
    local entry = state.book.shelf[self.selected]
    if action == "ShelfLoad" and not entry.exists then
        self.callbacks.notice("Choose an occupied shelf position to load a beat.")
        return
    end
    local confirm = action == "ShelfLoad" or entry.exists
    local pending = self.confirmation
    if
        confirm
        and not (
            pending
            and pending.action == action
            and pending.index == self.selected
            and pending.version == entry.version
            and pending.expires > os.clock()
        )
    then
        self.confirmation = {
            action = action,
            index = self.selected,
            version = entry.version,
            editVersion = state.editVersion,
            expires = os.clock() + 5,
        }
        local confirmation = self.confirmation
        task.delay(5, function()
            if self.store.Parent and self.confirmation == confirmation then
                self:tick()
            end
        end)
        self:update(state)
        return
    end
    self.confirmation = nil
    self.callbacks.command(action, self.selected, entry.version)
    self:update(state)
end

function BeatBookView:update(state)
    self.state = state
    local book = state.book
    if not book then
        return
    end
    local entry = book.shelf[self.selected]
    local pending = self.confirmation
    if
        pending
        and (
            pending.expires <= os.clock()
            or pending.version ~= entry.version
            or pending.editVersion ~= state.editVersion
            or state.saving
            or not state.station
        )
    then
        self.confirmation = nil
        pending = nil
    end
    for index, button in self.slots do
        local slot = book.slots[index]
        local selected = book.activeSlot == index
        button.Text = string.format(
            "%s / %s\n%d BPM",
            slot.label,
            if selected then "ACTIVE" elseif slot.hasNotes then "LOOP" else "EMPTY",
            slot.bpm
        )
        button.BackgroundColor3 = if selected then Theme.Amber else Theme.Teal
        button.TextColor3 = if selected then Theme.Ink else Theme.Cream
    end
    for index, button in self.beats do
        local beat = book.shelf[index]
        button.Text = string.format(
            "%sBeat %02d\n%s",
            if index == self.selected then "> " else "",
            index,
            if beat.exists then tostring(beat.populated) .. " PATTERNS" else "EMPTY"
        )
        button.BackgroundColor3 = if index == self.selected then Theme.Amber else Theme.Teal
        button.TextColor3 = if index == self.selected then Theme.Ink else Theme.Cream
    end
    self.store.Text = if pending and pending.action == "ShelfStore"
        then string.format("Replace Beat %02d?", self.selected)
        elseif state.saving then "Saving..."
        else "Save to shelf"
    self.load.Text = if pending and pending.action == "ShelfLoad"
        then "Replace slots A-D?"
        elseif entry.exists then "Load beat"
        else "Shelf position empty"
    self.detail.Text = if pending
        then "Press the same button again to confirm. Selecting another beat cancels."
        elseif state.saving then "Saving your profile. Newer edits may still need another save."
        elseif
            entry.exists and not entry.saved
        then "This beat is only in memory. Save your profile to keep it."
        elseif
            state.saveMode == "session"
        then "Studio shelf saves last for this Play session only."
        elseif
            state.saveMode == "unavailable"
        then "Saving is unavailable. Current shelf changes are temporary."
        else "Each beat saves all four slots. Loading replaces the current slots."
    if state.quest then
        self.questTitle.Text = if state.quest.completed
            then "FIRST COURTYARD SET / COMPLETE"
            else "MICA / A TUNE FOR THE QUAY"
        self.questBody.Text = state.quest.objective
    end
end

function BeatBookView:tick()
    if self.confirmation and self.confirmation.expires <= os.clock() then
        self.confirmation = nil
        if self.state then
            self:update(self.state)
        end
    end
end

return BeatBookView
