local Shared = game:GetService("ReplicatedStorage").Shared
local Activities = require(Shared.QuayActivities)
local Wardrobe = require(Shared.WardrobeCatalog)
local Theme = require(Shared.Theme)
local Gui = require(script.Parent.GuiFactory)
local Icons = require(script.Parent.GameIcons)
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
    if (size or 15) >= 18 then
        object.Font = Enum.Font.Code
    end
    return object
end

local function button(parent, text, callback, order, iconName)
    local object = Gui.button(parent, text, callback)
    object.Size, object.LayoutOrder = UDim2.new(1, 0, 0, 48), order
    object.Font, object.TextXAlignment = Enum.Font.Code, Enum.TextXAlignment.Left
    Gui.make("UIPadding", object, { PaddingLeft = UDim.new(0, 48), PaddingRight = UDim.new(0, 12) })
    object:SetAttribute("UiIcon", iconName or "arrow")
    return object
end

local function row(parent, order)
    return Gui.make("Frame", parent, {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 68),
        LayoutOrder = order,
    })
end

local function rowButton(parent, text, callback, index, count, iconName)
    local object = Gui.button(parent, text, callback)
    object.Position = UDim2.fromScale((index - 1) / count, 0)
    object.Size = UDim2.new(1 / count, -5, 1, 0)
    object:SetAttribute("NoActionIcon", true)
    object.Font, object.TextSize, object.TextYAlignment =
        Enum.Font.Code, 12, Enum.TextYAlignment.Bottom
    Gui.make("UIPadding", object, {
        PaddingBottom = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 4),
    })
    local icon = Icons.make(object, iconName or "badge", Theme.Amber, 28)
    icon.ZIndex = 3
    icon.AnchorPoint, icon.Position = Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 7)
    Gui.round(
        Gui.make("Frame", object, {
            Name = "SelectedMark",
            ZIndex = 4,
            Position = UDim2.fromOffset(8, 2),
            Size = UDim2.new(1, -16, 0, 3),
            BackgroundColor3 = Theme.Amber,
            BorderSizePixel = 0,
            Visible = false,
        }),
        2
    )
    return object
end

local function decorateCard(frame, iconName, title)
    frame.BackgroundTransparency, frame.BackgroundColor3 = 0.08, Theme.Stone
    Gui.round(frame, 12)
    Gui.make("UIStroke", frame, { Color = Theme.FadedTeal, Transparency = 0.4, Thickness = 1 })
    Gui.make("UIPadding", frame, {
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        PaddingTop = UDim.new(0, 12),
        PaddingBottom = UDim.new(0, 12),
    })
    local header = row(frame, 0)
    header.Size = UDim2.new(1, 0, 0, 48)
    Icons.make(header, iconName, Theme.Teal, 38).Position = UDim2.fromOffset(2, 5)
    local heading = Gui.label(header, title, 18, Theme.Ink)
    heading.Font = Enum.Font.Code
    heading.Position, heading.Size = UDim2.fromOffset(52, 0), UDim2.new(1, -52, 1, 0)
    return heading
end

local function details(parent, text, order)
    local content = label(parent, text, order + 1, 14)
    content.Visible = false
    local control
    control = button(parent, "HINTS / DETAILS", function()
        content.Visible = not content.Visible
        control.Text = if content.Visible then "HIDE DETAILS" else "HINTS / DETAILS"
    end, order, "hint")
    return content
end

local function enable(object, enabled)
    object.Active, object.Interactable, object.Selectable, object.AutoButtonColor =
        enabled, enabled, enabled, enabled
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
    label(self.explore, "QUAY DISCOVERIES", 0, 21)
    details(
        self.explore,
        "Four optional things to try around the quay. Explore at your own pace; your next story step will wait.",
        1
    )
    for index, id in Activities.Order do
        local activity = Activities.ById[id]
        local card = stack(self.explore, id, index + 1)
        local activityIcons = {
            memory_walk = "route",
            sound_safari = "discovery",
            pattern_bench = "logic",
            sleeve_studio = "sleeve",
        }
        local heading = decorateCard(card, activityIcons[id], activity.title)
        details(
            card,
            activity.description .. "\n" .. activity.location .. "\n" .. activity.reward,
            20
        )
        local status = label(card, "", 3, 14, Theme.Teal)
        status.Font = Enum.Font.Code
        self.cards[id] = { root = card, heading = heading, status = status }
        if id == "memory_walk" then
            for memoryIndex, memory in Activities.Memories do
                local memoryCard = stack(card, memory.id, memoryIndex + 4)
                local text = label(memoryCard, "", 0)
                text.Font = Enum.Font.Code
                local read = button(memoryCard, "READ POSTCARD", function()
                    send("LifeMemory", memory.id)
                end, 1, "journal")
                local body = label(memoryCard, "", 2, 15)
                body.Visible = false
                local record = { text = text, read = read, body = body, expanded = false }
                local recall = button(memoryCard, "MY POSTCARD", function()
                    record.expanded = not record.expanded
                    body.Visible = record.expanded
                    record.recall.Text = if record.expanded then "CLOSE POSTCARD" else "MY POSTCARD"
                end, 3, "journal")
                recall.Visible, record.recall = false, recall
                self.memoryCards[memory.id] = record
            end
        elseif id == "sound_safari" then
            self.soundChips = {}
            local sounds = row(card, 4)
            for soundIndex, soundName in { "METAL", "THUMP", "CHIRP" } do
                local chip = Gui.round(
                    Gui.make("Frame", sounds, {
                        Name = "Sound_" .. soundIndex,
                        Position = UDim2.fromScale((soundIndex - 1) / 3, 0),
                        Size = UDim2.new(1 / 3, -5, 1, 0),
                        BackgroundColor3 = Theme.Teal,
                        BorderSizePixel = 0,
                    }),
                    8
                )
                Icons.make(chip, "sound", Theme.Amber, 28).Position = UDim2.new(0.5, -14, 0, 5)
                local caption = Gui.label(chip, soundName, 12, Theme.Cream)
                caption.Font, caption.TextXAlignment = Enum.Font.Code, Enum.TextXAlignment.Center
                caption.Position, caption.Size = UDim2.fromOffset(2, 39), UDim2.new(1, -4, 0, 24)
                self.soundChips[soundIndex] = { root = chip, caption = caption, name = soundName }
            end
        elseif id == "pattern_bench" then
            self.puzzleStart = button(card, "Sit at Ivo's pattern bench", function()
                send("LifeStartPuzzle")
            end, 4)
            self.puzzle = stack(card, "PatternPuzzle", 5)
            self.puzzleText = label(self.puzzle, "", 0, 18)
            self.puzzleTiles = row(self.puzzle, 1)
            local answers = row(self.puzzle, 2)
            for answerIndex, answer in { "Bolt", "Coil", "Lamp" } do
                rowButton(answers, answer, function()
                    send("LifeAnswer", answer)
                end, answerIndex, 3, string.lower(answer))
            end
            button(self.puzzle, "Ask Ivo for a hint", function()
                send("LifePuzzleHint")
            end, 3, "hint")
            self.puzzleHint = label(self.puzzle, "", 4)
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
            self.sleeveText.Font = Enum.Font.Code
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
                end, optionIndex, 3, option.id)
            end
            for optionIndex, option in Activities.Palettes do
                self.paletteButtons[option.id] = rowButton(
                    palettes,
                    string.upper(option.id),
                    function()
                        self.palette, self.sleeveEdited = option.id, true
                        self:renderSleeve()
                    end,
                    optionIndex,
                    3
                )
                local control = self.paletteButtons[option.id]
                control.Icon_badge:Destroy()
                local swatch = Gui.round(
                    Gui.make("Frame", control, {
                        Name = "ColourSwatch",
                        ZIndex = 3,
                        Size = UDim2.fromOffset(28, 28),
                        AnchorPoint = Vector2.new(0.5, 0),
                        Position = UDim2.new(0.5, 0, 0, 7),
                        BackgroundColor3 = ({
                            teal = Theme.Teal,
                            coral = Theme.Coral,
                            amber = Theme.Amber,
                        })[option.id],
                        BorderSizePixel = 0,
                    }),
                    14
                )
                Gui.make("UIStroke", swatch, { Color = Theme.Cream, Thickness = 2 })
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
            details(
                card,
                "A cover is copied deliberately. Save Draft, then Finish & Save Song for a new revision. Designing a sleeve never finishes music or changes older saved covers.",
                22
            )
        end
    end

    self.style = stack(parent, "GrooveboxerIdentity")
    self.rank = label(self.style, "Your groove", 0, 22)
    self.rank.Font = Enum.Font.Code
    self.tracks = stack(self.style, "GrowthTracks", 1)
    self.trackCards = {}
    details(
        self.style,
        "Grow by making music, listening and helping. New discoveries count once. Your clothes never change how your music is judged.",
        20
    )
    self.titles = stack(self.style, "Titles", 3)
    label(self.titles, "YOUR TITLE", 0, 18)
    self.titleButtons = {}
    self.wardrobe = stack(self.style, "Wardrobe", 4)
    label(self.wardrobe, "WARDROBE", 0, 19)
    details(
        self.wardrobe,
        "Add BeatMakka accessories to your own Roblox avatar. Choose a piece to wear it; use Remove to take it off.",
        10
    )
    self.preview = WardrobePreview.new(self.wardrobe)
    self.preview.root.LayoutOrder = 2
    self.mirrorToggle = button(self.wardrobe, "OPEN MIRROR", function()
        self.mirrorOpen = not self.mirrorOpen
        self.preview:setVisible(
            self.mirrorOpen and self.journalVisible == true and self.style.Visible
        )
        self.mirrorToggle.Text = if self.mirrorOpen then "CLOSE MIRROR" else "OPEN MIRROR"
        self.mirrorToggle:SetAttribute("MirrorRequested", self.mirrorOpen == true)
    end, 1, "mirror")
    self.mirrorToggle.Name = "ToggleWardrobeMirror"
    local slots = row(self.wardrobe, 3)
    self.slotButtons = {}
    for index, slot in Wardrobe.Slots do
        self.slotButtons[slot] = rowButton(
            slots,
            ({ head = "HEAD", neck = "SCARF", back = "BAG", pin = "PIN" })[slot],
            function()
                self.slot = slot
                self:renderItems()
            end,
            index,
            #Wardrobe.Slots,
            ({ head = "headphones", neck = "scarf", back = "bag", pin = "pin" })[slot]
        )
    end
    self.items = stack(self.wardrobe, "Items", 4)
    for index, id in Wardrobe.Order do
        local item = Wardrobe.Items[id]
        local card = stack(self.items, id, index)
        local heading = decorateCard(
            card,
            ({ head = "headphones", neck = "scarf", back = "bag", pin = "pin" })[item.slot],
            item.label
        )
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
    label(self.looks, "SAVE A LOOK", 0, 18)
    self.lookButtons = {}
    for index = 1, Wardrobe.OutfitCapacity do
        local buttons = row(self.looks, index)
        local save = rowButton(buttons, "Save look " .. index, function()
            send("LifeSaveLook", index)
        end, 1, 2, "save")
        local load = rowButton(buttons, "Wear look " .. index, function()
            send("LifeLoadLook", index)
        end, 2, 2, "people")
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
        control.SelectedMark.Visible = id == self.motif
    end
    for id, control in self.paletteButtons do
        control.BackgroundColor3 = if id == self.palette then Theme.Ink else Theme.Teal
        control.SelectedMark.Visible = id == self.palette
    end
end

function Panel:renderItems()
    if not self.state then
        return
    end
    for id, control in self.slotButtons do
        control.BackgroundColor3 = if id == self.slot then Theme.Ink else Theme.Teal
        control.SelectedMark.Visible = id == self.slot
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
    self.journalVisible = journalVisible
    if not state or tab ~= "style" or journalVisible ~= true then
        self.mirrorOpen = false
    end
    self.preview:setVisible(
        state ~= nil and tab == "style" and journalVisible == true and self.mirrorOpen == true
    )
    self.mirrorToggle.Text = if self.mirrorOpen then "CLOSE MIRROR" else "OPEN MIRROR"
    self.mirrorToggle:SetAttribute("MirrorRequested", self.mirrorOpen == true)
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
        card.status.Text = if activity.completed then "KEEPSAKE COLLECTED" else "DISCOVERY WAITING"
        card.status.TextColor3 = if activity.completed then Theme.Teal else Theme.Walnut
    end
    for _, memory in state.memories do
        local card = self.memoryCards[memory.id]
        card.text.Text = memory.title .. (if memory.collected then " / COLLECTED" else "")
        card.body.Text = memory.text or "A little story is waiting here."
        card.body.Visible = card.expanded and memory.text ~= nil
        card.recall.Visible = memory.collected == true
        card.read.Text = if memory.collected and not memory.nearby
            then "VISIT TO READ AGAIN"
            elseif memory.collected then "READ AGAIN"
            elseif memory.nearby then "READ POSTCARD"
            else "FIND POSTCARD"
        enable(card.read, memory.nearby)
    end
    for index, id in { "I01", "I02", "I03" } do
        local chip = self.soundChips[index]
        chip.root.BackgroundColor3 = if fullState.unlocked[id] then Theme.Ink else Theme.Teal
        chip.caption.Text = chip.name .. (if fullState.unlocked[id] then " / OK" else " / ?")
    end
    local bench = state.activities.pattern_bench
    enable(self.puzzleStart, bench.nearby)
    self.puzzleStart.Text = if not bench.nearby
        then "Visit Morrow Repairs to play"
        elseif state.puzzle then "Start three new patterns"
        elseif bench.completed then "Practise three new patterns"
        else "Sit at Ivo's pattern bench"
    self.puzzle.Visible = state.puzzle ~= nil
    if state.puzzle then
        self.puzzleText.Text = "ROUND " .. state.puzzle.round .. " / 3"
        local pattern = table.concat(state.puzzle.tiles, ":")
        if self.puzzleDrawn ~= pattern then
            self.puzzleDrawn = pattern
            self.puzzleTiles:ClearAllChildren()
            local count = #state.puzzle.tiles + 1
            for index = 1, count do
                local name = state.puzzle.tiles[index]
                local tile = Gui.round(
                    Gui.make("Frame", self.puzzleTiles, {
                        Name = name or "NextTile",
                        Position = UDim2.fromScale((index - 1) / count, 0),
                        Size = UDim2.new(1 / count, -3, 1, 0),
                        BackgroundColor3 = if name then Theme.Teal else Theme.Ink,
                        BorderSizePixel = 0,
                    }),
                    6
                )
                local icon =
                    Icons.make(tile, if name then string.lower(name) else "hint", Theme.Amber, 24)
                icon.Position = UDim2.new(0.5, -12, 0, 8)
                local caption =
                    Gui.label(tile, if name then string.upper(name) else "NEXT?", 10, Theme.Cream)
                caption.Font, caption.TextXAlignment = Enum.Font.Code, Enum.TextXAlignment.Center
                caption.Position, caption.Size = UDim2.new(0, 1, 1, -28), UDim2.new(1, -2, 0, 24)
            end
        end
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
    for index, track in identity.tracks do
        local card = self.trackCards[track.id]
        if not card then
            local frame = row(self.tracks, index)
            frame.BackgroundTransparency, frame.BackgroundColor3 = 0.08, Theme.Stone
            Gui.round(frame, 8)
            Icons.make(
                frame,
                ({ listener = "headphones", beatmaker = "pads", neighbour = "people" })[track.id]
                    or "badge",
                Theme.Teal,
                28
            ).Position =
                UDim2.fromOffset(10, 10)
            local title = Gui.label(frame, "", 14, Theme.Ink)
            title.Font = Enum.Font.Code
            title.Position, title.Size = UDim2.fromOffset(48, 5), UDim2.new(1, -56, 0, 38)
            local rail = Gui.round(
                Gui.make("Frame", frame, {
                    Position = UDim2.fromOffset(48, 49),
                    Size = UDim2.new(1, -60, 0, 8),
                    BackgroundColor3 = Theme.FadedTeal,
                    BorderSizePixel = 0,
                }),
                4
            )
            local fill = Gui.round(
                Gui.make("Frame", rail, {
                    Size = UDim2.fromScale(0, 1),
                    BackgroundColor3 = Theme.Teal,
                    BorderSizePixel = 0,
                }),
                4
            )
            card = { root = frame, title = title, fill = fill }
            self.trackCards[track.id] = card
        end
        card.title.Text = track.label
            .. " / "
            .. track.levelLabel
            .. "\n"
            .. track.xp
            .. " XP"
            .. (if track.nextAt then " / " .. track.nextAt else " / MASTERY")
        card.fill.Size = UDim2.fromScale(
            if track.nextAt then math.clamp(track.xp / math.max(1, track.nextAt), 0, 1) else 1,
            1
        )
    end
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
