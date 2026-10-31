local Shared = game:GetService("ReplicatedStorage").Shared
local Activities = require(Shared.QuayActivities)
local Wardrobe = require(Shared.WardrobeCatalog)
local Theme = require(Shared.Theme)
local Gui = require(script.Parent.GuiFactory)
local WardrobePreview = require(script.Parent.QuayWardrobePreview)
local Panel = {}
Panel.__index = Panel

local function stack(parent, name, order)
    local frame = Gui.make("Frame", parent, {
        Name = name,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -10, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = order or 3,
    })
    Gui.make(
        "UIListLayout",
        frame,
        { Padding = UDim.new(0, 9), SortOrder = Enum.SortOrder.LayoutOrder }
    )
    return frame
end

local function label(parent, text, order, size, color)
    local object = Gui.label(parent, text, size or 15, color)
    object.Size, object.AutomaticSize = UDim2.new(1, -8, 0, 0), Enum.AutomaticSize.Y
    object.LayoutOrder = order
    return object
end

local function button(parent, text, callback, order)
    local object = Gui.button(parent, text, callback)
    object.Size, object.LayoutOrder = UDim2.new(1, 0, 0, 44), order
    return object
end

local function row(parent, order)
    return Gui.make("Frame", parent, {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 44),
        LayoutOrder = order,
    })
end

local function rowButton(parent, text, callback, index, count)
    local object = Gui.button(parent, text, callback)
    object.Position = UDim2.fromScale((index - 1) / count, 0)
    object.Size = UDim2.new(1 / count, -5, 1, 0)
    return object
end

local function enable(object, enabled)
    object.Active, object.Selectable, object.AutoButtonColor = enabled, enabled, enabled
    object.BackgroundColor3 = if enabled then Theme.Teal else Theme.FadedTeal
end

function Panel.new(parent, send)
    local self = setmetatable({
        send = send,
        motif = "waves",
        palette = "teal",
        slot = "head",
        sleeveEdited = false,
        cards = {},
        memoryCards = {},
        itemCards = {},
    }, Panel)
    self.explore = stack(parent, "NeighbourhoodActivities")
    label(self.explore, "Take a detour", 0, 21).Font = Theme.Bold
    label(
        self.explore,
        "Four optional things to try around the quay. Explore at your own pace; your next story step will wait.",
        1
    )
    for index, id in Activities.Order do
        local activity = Activities.ById[id]
        local card = stack(self.explore, id, index + 1)
        local heading = label(card, activity.title, 0, 18)
        heading.Font = Theme.Bold
        label(card, activity.kind .. "  /  " .. activity.location, 1, 13, Theme.Teal)
        label(card, activity.description, 2)
        local status = label(card, "", 3, 14, Theme.Teal)
        self.cards[id] = { root = card, heading = heading, status = status }
        if id == "memory_walk" then
            for memoryIndex, memory in Activities.Memories do
                local memoryCard = stack(card, memory.id, memoryIndex + 4)
                local text = label(memoryCard, "", 0)
                local read = button(memoryCard, "Read " .. memory.title, function()
                    send("LifeMemory", memory.id)
                end, 1)
                self.memoryCards[memory.id] = { text = text, read = read }
            end
        elseif id == "sound_safari" then
            self.soundProgress = label(card, "", 4)
        elseif id == "pattern_bench" then
            self.puzzleStart = button(card, "Sit at Ivo's pattern bench", function()
                send("LifeStartPuzzle")
            end, 4)
            self.puzzle = stack(card, "PatternPuzzle", 5)
            self.puzzleText = label(self.puzzle, "", 0, 18)
            local answers = row(self.puzzle, 1)
            for answerIndex, answer in { "Bolt", "Coil", "Lamp" } do
                rowButton(answers, answer, function()
                    send("LifeAnswer", answer)
                end, answerIndex, 3)
            end
            button(self.puzzle, "Ask Ivo for a hint", function()
                send("LifePuzzleHint")
            end, 2)
            self.puzzleHint = label(self.puzzle, "", 3)
        elseif id == "sleeve_studio" then
            self.sleevePreview = Gui.make("Frame", card, {
                Name = "YourRecordSleeve",
                Size = UDim2.new(1, 0, 0, 155),
                BackgroundColor3 = Theme.Teal,
                BorderSizePixel = 0,
                LayoutOrder = 4,
            })
            Gui.round(self.sleevePreview, 8)
            local disc = Gui.make("Frame", self.sleevePreview, {
                Name = "Record",
                Size = UDim2.fromOffset(110, 110),
                Position = UDim2.new(1, -125, 0, 20),
                BackgroundColor3 = Theme.Ink,
                BorderSizePixel = 0,
            })
            Gui.round(disc, 55)
            local centre = Gui.make("Frame", disc, {
                Size = UDim2.fromOffset(34, 34),
                Position = UDim2.fromOffset(38, 38),
                BackgroundColor3 = Theme.Cream,
                BorderSizePixel = 0,
            })
            Gui.round(centre, 17)
            self.sleeveText = Gui.label(self.sleevePreview, "", 20, Theme.Cream)
            self.sleeveText.Position = UDim2.fromOffset(14, 10)
            self.sleeveText.Size = UDim2.new(1, -145, 0, 75)
            self.sleeveText.Font = Theme.Bold
            self.motifArt = Gui.make("Frame", self.sleevePreview, {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(14, 90),
                Size = UDim2.new(1, -155, 0, 45),
            })
            local motifs, palettes = row(card, 5), row(card, 6)
            self.motifButtons, self.paletteButtons = {}, {}
            for optionIndex, option in Activities.Motifs do
                self.motifButtons[option.id] = rowButton(motifs, option.glyph, function()
                    self.motif, self.sleeveEdited = option.id, true
                    self:renderSleeve()
                end, optionIndex, 3)
            end
            for optionIndex, option in Activities.Palettes do
                self.paletteButtons[option.id] = rowButton(palettes, option.label, function()
                    self.palette, self.sleeveEdited = option.id, true
                    self:renderSleeve()
                end, optionIndex, 3)
            end
            self.sleeveSave = button(card, "Print and keep this sleeve", function()
                send("LifeSleeve", self.motif, self.palette)
            end, 7)
            self.copySleeve = button(card, "Copy kept sleeve to selected song draft", function()
                send(
                    "LifeCopySleeveToDraft",
                    self.state and self.state.selectedDraft and self.state.selectedDraft.id
                )
            end, 8)
            label(
                card,
                "A cover is copied deliberately. Save Draft, then Finish & Save Song for a new revision. Designing a sleeve never finishes music or changes older saved covers.",
                9,
                14
            )
        end
    end

    self.style = stack(parent, "GrooveboxerIdentity")
    self.rank = label(self.style, "Your groove", 0, 22)
    self.rank.Font = Theme.Bold
    self.tracks = label(self.style, "", 1, 16)
    label(
        self.style,
        "Grow by making music, listening and helping. New discoveries count once. Your clothes never change how your music is judged.",
        2,
        14
    )
    self.titles = stack(self.style, "Titles", 3)
    label(self.titles, "Choose your title", 0, 18).Font = Theme.Bold
    self.titleButtons = {}
    self.wardrobe = stack(self.style, "Wardrobe", 4)
    label(self.wardrobe, "Your wardrobe", 0, 19).Font = Theme.Bold
    label(
        self.wardrobe,
        "Add BeatMakka accessories to your own Roblox avatar. Choose a piece to wear it; use Remove to take it off.",
        1,
        14
    )
    self.preview = WardrobePreview.new(self.wardrobe)
    self.preview.root.LayoutOrder = 2
    local slots = row(self.wardrobe, 3)
    self.slotButtons = {}
    for index, slot in Wardrobe.Slots do
        self.slotButtons[slot] = rowButton(slots, Wardrobe.SlotLabels[slot], function()
            self.slot = slot
            self:renderItems()
        end, index, #Wardrobe.Slots)
    end
    self.items = stack(self.wardrobe, "Items", 4)
    for index, id in Wardrobe.Order do
        local item = Wardrobe.Items[id]
        local card = stack(self.items, id, index)
        local heading = label(card, item.label, 0, 17)
        heading.Font = Theme.Bold
        local detail = label(card, "", 1, 14)
        local wear = button(card, "Wear", function()
            if self.state and self.state.identity.equipped[item.slot] == id then
                send("LifeClear", item.slot)
            else
                send("LifeEquip", id)
            end
        end, 2)
        self.itemCards[id] = { root = card, heading = heading, detail = detail, wear = wear }
    end
    self.looks = stack(self.style, "SavedLooks", 5)
    label(self.looks, "Three looks to keep", 0, 18).Font = Theme.Bold
    self.lookButtons = {}
    for index = 1, Wardrobe.OutfitCapacity do
        local buttons = row(self.looks, index)
        local save = rowButton(buttons, "Save look " .. index, function()
            send("LifeSaveLook", index)
        end, 1, 2)
        local load = rowButton(buttons, "Wear look " .. index, function()
            send("LifeLoadLook", index)
        end, 2, 2)
        self.lookButtons[index] = { save = save, load = load }
    end
    button(self.style, "Remove all BeatMakka accessories", function()
        send("LifeResetLook")
    end, 6)
    self:renderSleeve()
    return self
end

function Panel:renderSleeve()
    local drawing = self.motif .. ":" .. self.palette
    if self.sleeveDrawn == drawing then
        return
    end
    self.sleeveDrawn = drawing
    local color = ({ teal = Theme.Teal, coral = Theme.Coral, amber = Theme.Amber })[self.palette]
    self.sleevePreview.BackgroundColor3 = color
    self.sleeveText.Text = "MY QUAY\n" .. string.upper(self.motif)
    self.sleeveText.TextColor3 = if self.palette == "amber" then Theme.Ink else Theme.Cream
    for _, child in self.motifArt:GetChildren() do
        child:Destroy()
    end
    if self.motif == "lantern" then
        Gui.round(
            Gui.make("Frame", self.motifArt, {
                Size = UDim2.fromOffset(24, 34),
                Position = UDim2.fromOffset(8, 4),
                BackgroundColor3 = Theme.Cream,
                BorderSizePixel = 0,
            }),
            7
        )
        Gui.make("Frame", self.motifArt, {
            Size = UDim2.fromOffset(38, 5),
            Position = UDim2.fromOffset(1, 0),
            BackgroundColor3 = Theme.Ink,
            BorderSizePixel = 0,
        })
    else
        for index = 1, 8 do
            local height = if self.motif == "steps" then (if index % 2 == 0 then 16 else 32) else 6
            Gui.round(
                Gui.make("Frame", self.motifArt, {
                    Size = UDim2.new(0.1, 0, 0, height),
                    Position = UDim2.new(
                        (index - 1) / 8,
                        0,
                        0,
                        if self.motif == "waves" then 12 + (index % 3) * 6 else 38 - height
                    ),
                    BackgroundColor3 = Theme.Cream,
                    BorderSizePixel = 0,
                }),
                3
            )
        end
    end
    for id, control in self.motifButtons do
        control.BackgroundColor3 = if id == self.motif then Theme.Ink else Theme.Teal
    end
    for id, control in self.paletteButtons do
        control.BackgroundColor3 = if id == self.palette then Theme.Ink else Theme.Teal
    end
end

function Panel:renderItems()
    if not self.state then
        return
    end
    for id, control in self.slotButtons do
        control.BackgroundColor3 = if id == self.slot then Theme.Ink else Theme.Teal
    end
    for _, item in self.state.identity.items do
        local card = self.itemCards[item.id]
        card.root.Visible = item.slot == self.slot
        card.heading.Text = item.label .. (if item.equipped then "  /  Wearing" else "")
        card.detail.Text = item.description
            .. "\n"
            .. (if item.owned then "In your wardrobe" else item.unlockHint)
        card.wear.Text = if item.equipped
            then "Remove"
            elseif item.owned then "Wear"
            elseif item.source == "premium" then "See the Shop tab"
            else "Earn through play"
        enable(card.wear, item.owned)
    end
end

function Panel:update(fullState, tab, journalVisible)
    local state = fullState and fullState.experience
    self.explore.Visible = state ~= nil and tab == "explore"
    self.style.Visible = state ~= nil and tab == "style"
    self.preview:setVisible(state ~= nil and tab == "style" and journalVisible == true)
    if not state then
        return
    end
    self.state = state
    self.copySleeve.Text = if state.selectedDraft
        then "Copy kept sleeve to draft / " .. state.selectedDraft.name
        else "Choose a Song Mode draft in your Roamer first"
    enable(self.copySleeve, state.selectedDraft ~= nil and state.progress.activities.sleeve_studio)
    for id, card in self.cards do
        local activity = state.activities[id]
        card.status.Text = (
            if activity.completed then "Keepsake earned  /  " else "First completion  /  "
        ) .. Activities.ById[id].reward
    end
    for _, memory in state.memories do
        local card = self.memoryCards[memory.id]
        card.text.Text = memory.title .. "\n" .. (memory.text or "A little story is waiting here.")
        card.read.Text = if memory.collected and not memory.nearby
            then "Visit to hear this story again"
            elseif memory.collected then "Read again"
            elseif memory.nearby then "Read this postcard"
            else "Find this postcard on your walk"
        enable(card.read, memory.nearby)
    end
    local sounds = {}
    for index, id in { "I01", "I02", "I03" } do
        table.insert(
            sounds,
            (if fullState.unlocked[id] then "Collected  /  " else "Still to find  /  ")
                .. ({ "Quay metal", "Vent thump", "Helper chirp" })[index]
        )
    end
    self.soundProgress.Text = table.concat(sounds, "\n")
    local bench = state.activities.pattern_bench
    enable(self.puzzleStart, bench.nearby)
    self.puzzleStart.Text = if not bench.nearby
        then "Visit Morrow Repairs to play"
        elseif state.puzzle then "Start three new patterns"
        elseif bench.completed then "Practise three new patterns"
        else "Sit at Ivo's pattern bench"
    self.puzzle.Visible = state.puzzle ~= nil
    if state.puzzle then
        self.puzzleText.Text = "Pattern "
            .. state.puzzle.round
            .. " of 3\n"
            .. table.concat(state.puzzle.tiles, "  /  ")
            .. "  /  ?"
        self.puzzleHint.Text = state.puzzle.hint or "There is no timer. What comes next?"
    end
    if not self.sleeveEdited then
        self.motif, self.palette = state.progress.sleeve.motif, state.progress.sleeve.palette
        self:renderSleeve()
    end
    enable(self.sleeveSave, state.activities.sleeve_studio.nearby)
    self.sleeveSave.Text = if state.activities.sleeve_studio.nearby
        then "Print and keep this sleeve"
        else "Visit Needle Records to print"
    local identity = state.identity
    self.rank.Text = identity.rank.label .. "  /  " .. identity.titleLabel
    local tracks = {}
    for _, track in identity.tracks do
        table.insert(
            tracks,
            track.label
                .. "  ·  "
                .. track.levelLabel
                .. "  ·  "
                .. track.xp
                .. " XP"
                .. (
                    if track.nextAt
                        then " / " .. track.nextAt .. " to next level"
                        else " / Demo mastery"
                )
        )
    end
    self.tracks.Text = table.concat(tracks, "\n")
    for index, title in identity.titles do
        if not self.titleButtons[title.id] then
            self.titleButtons[title.id] = button(self.titles, title.label, function()
                self.send("LifeTitle", title.id)
            end, index)
        end
        local control = self.titleButtons[title.id]
        control.Text = title.label
            .. (
                if identity.title == title.id
                    then "  /  Selected"
                    elseif not title.owned then "  /  Keep exploring"
                    else ""
            )
        enable(control, title.owned)
    end
    for _, look in identity.outfits do
        self.lookButtons[look.index].save.Text = (
            if look.saved then "Replace look " else "Save look "
        ) .. look.index
        enable(self.lookButtons[look.index].load, look.saved)
    end
    self:renderItems()
end

function Panel:destroy()
    self.preview:destroy()
    self.explore:Destroy()
    self.style:Destroy()
end

return Panel
