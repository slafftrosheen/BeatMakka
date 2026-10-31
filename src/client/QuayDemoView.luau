local Players = game:GetService("Players")
local Input = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local Shared = game.ReplicatedStorage.Shared
local Theme = require(Shared.Theme)
local Catalog = require(Shared.NeedleQuayCatalog)
local Gui = require(script.Parent.GuiFactory)
local Story = require(Shared.QuayStory)
local ExperiencePanel = require(script.Parent.QuayExperiencePanel)
local ShopPanel = require(script.Parent.QuayShopPanel)
local CompanionView = require(script.Parent.CompanionView)
local DialogueView = require(script.Parent.QuayDialogueView)
local ObjectiveView = require(script.Parent.QuayObjectiveView)
local Objectives = require(Shared.QuayObjectives)
local Samples = require(Shared.SampleCatalog)
local Icons = require(script.Parent.GameIcons)
local DeviceSkin = require(script.Parent.DeviceSkin)
local StreetGames = require(Shared.QuayStreetGames)
local View = {}
View.__index = View
local function graphicButton(button, iconName)
    button.Font = Enum.Font.Code
    button.TextXAlignment = Enum.TextXAlignment.Left
    Gui.make("UIPadding", button, { PaddingLeft = UDim.new(0, 46), PaddingRight = UDim.new(0, 10) })
    button:SetAttribute("UiIcon", iconName)
end
local instructions = {
    P1 = "TORI / DOCKSIDE EXCHANGE\nStow three crates. Make a named sequence with ready Quay metal at four distinct rhythmic positions, then return to Tori. Sharing a loop is optional.",
    P2 = "IVO / REPAIR ALLEY\nUse controls 1, 2, 3 in order. Save Sequence for your original and a musically distinct variation. Names and unused pad edits do not make a variation.",
    P3 = "NAYA + SANA / VINYL MARKET\nListen and match each ready record's role. Put an owned saved sequence into Song Mode and Save Draft. Finishing can wait. Help Sana stow three cases.",
    P4 = "MICA / BREAKWATER STEPS\nSelect a teaching bar in your sequence. Use ready Helper chirp exactly at ticks 0, 960, 1920 and 2880 of that bar. Other bars and instruments are your choice. Return to check, then use the signal console.",
    finale = "RONAN / THE LANTERN ROOM\nFinish and save your own song, then select its saved immutable revision. It needs two distinct musical sections and a collected sound layered with another part. Perform from beginning to actual end; pauses freeze progress and stopping cancels this attempt.",
    map = "NEEDLE QUAY / YOUR ROUTE\nYour Roamer holds your sequences and songs. A sequence is a section you can repeat. A song is your sections arranged from beginning to end. Pending sample audio cannot make a musical quest ready.",
}
local goals = {
    ["NQ-Q00"] = "Meet Tori or enter your own Roamer studio.",
    ["NQ-Q01"] = "Stow three dock crates.",
    ["NQ-Q02"] = "Use I01 at four distinct rhythmic positions in a ready named sequence.",
    ["NQ-Q03"] = "Share a saved loop if wanted, or continue privately. No audience or Finished Song needed.",
    ["NQ-Q04"] = "Isolate power, clear intake, restore power; collect I02.",
    ["NQ-Q05"] = "Save an original named sequence and a musically distinct variation.",
    ["NQ-Q06"] = "Listen to three ready records and match their roles.",
    ["NQ-Q07"] = "Save a Song Mode draft containing an owned saved sequence.",
    ["NQ-Q08"] = "Help Sana stow three stage cases.",
    ["NQ-Q09"] = "Use I03 on quarter notes of the selected teaching bar: ticks 0, 960, 1920, 2880.",
    ["NQ-Q10"] = "Use the signal after Mica hears your reply.",
    ["NQ-Q11"] = "Select a ready, successfully saved Finished Song with Ronan.",
    ["NQ-Q12"] = "Perform that pinned revision from beginning to its actual end.",
}
if Samples.LocalDiscoveryById.I01 then
    instructions.finale =
        "RONAN / THE LANTERN ROOM\nFinish and save a song with two distinct musical sections and at least two audible parts in one section. Select its saved revision and perform from beginning to end; pauses freeze progress and stopping cancels this attempt."
    instructions.map =
        "NEEDLE QUAY / YOUR ROUTE\nYour Roamer holds your sequences and songs. The local kit supports creation and performance. Named local substitutes keep discovery lessons playable; human listening approval remains pending."
end
for id, text in instructions do
    instructions[id] = Samples.localDiscoveryText(text)
end
goals["NQ-Q02"] = "Use "
    .. Samples.discoveryLabel("I01", "I01")
    .. " at four distinct rhythmic positions in a ready named sequence."
goals["NQ-Q09"] = "Use "
    .. Samples.discoveryLabel("I03", "I03")
    .. " on teaching-bar ticks 0, 960, 1920 and 2880."
local buildingNames = {}
for _, building in Catalog.buildings do
    buildingNames[building.id] = building.name
end
local hosts = {
    finale = "Ronan at the Lantern Room",
    P1 = "Tori at the dock",
    P2 = "Ivo at the repair alley",
    P3 = "Naya at the record market",
    P4 = "Mica at the breakwater",
}
local function destination(id)
    return if id == "NQ-BLD-01"
        then "finale"
        elseif id == "NQ-BLD-03" or id == "NQ-BLD-09" then "P2"
        elseif id == "NQ-BLD-02" or id == "NQ-BLD-04" then "P3"
        elseif id == "NQ-BLD-05" or id == "NQ-BLD-12" then "P4"
        else "P1"
end
function View.new()
    local self = setmetatable({ connections = {}, personal = {}, tab = "route" }, View)
    local network = game.ReplicatedStorage:WaitForChild("MusicNetwork")
    local command = network:WaitForChild("Command")
    local function send(action, value, extra)
        command:FireServer(action, value, extra)
    end
    self.screen = Gui.make("ScreenGui", Players.LocalPlayer:WaitForChild("PlayerGui"), {
        Name = "NeedleQuayJournal",
        ResetOnSpawn = false,
        DisplayOrder = 12,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    self.route = ObjectiveView.new(self.screen)
    self.voice = require(script.Parent.CompanionVoice).new(self.screen)
    self.commissionVoice = require(script.Parent.QuayCommissionVoice).new(self.screen)
    self.sideActivities = require(script.Parent.QuaySideActivityView).new(self.screen, send)
    self.badges = require(script.Parent.QuayBadgeView).new(self.screen)
    self.toggle = Gui.button(self.screen, "MAP", function()
        send("QuayJournal")
    end)
    self.toggle.Name = "QuayMapToggle"
    self.toggle.Position = UDim2.new(1, -144, 0, 8)
    self.toggle.Size = UDim2.fromOffset(132, 44)
    graphicButton(self.toggle, "route")
    self.companionRibbon = Gui.button(self.screen, "PEOPLE", function()
        self.tab = "companions"
        if self.panel.Visible then
            self:render()
        else
            send("QuayJournal")
        end
    end)
    self.companionRibbon.Name = "CompanionShortcut"
    self.companionRibbon.Position, self.companionRibbon.Size =
        UDim2.fromOffset(12, 8), UDim2.new(0.5, -24, 0, 44)
    graphicButton(self.companionRibbon, "people")
    Gui.make(
        "UISizeConstraint",
        self.companionRibbon,
        { MaxSize = Vector2.new(220, 44), MinSize = Vector2.new(100, 44) }
    )
    self.interactionTargets = {}
    self.targetWatchers = {}
    local function registerTarget(object)
        if self.interactionTargets[object] then
            return
        end
        local prompt = object:FindFirstChildOfClass("ProximityPrompt")
        if prompt then
            self.interactionTargets[object] = true
            prompt.Enabled = false
            prompt:SetAttribute("QuayCustomPrompt", true)
            prompt.Style = Enum.ProximityPromptStyle.Custom
            prompt.KeyboardKeyCode = Enum.KeyCode.None
            prompt.GamepadKeyCode = Enum.KeyCode.None
        end
    end
    local function monitorPrompt(prompt)
        local object = prompt.Parent
        if
            not object
            or not object:IsA("BasePart")
            or self.interactionTargets[object]
            or self.targetWatchers[object]
        then
            return
        end
        if object:GetAttribute("QuayInteraction") then
            registerTarget(object)
            return
        end
        local watchers = {}
        local function clear()
            for _, connection in watchers do
                connection:Disconnect()
            end
            self.targetWatchers[object] = nil
        end
        self.targetWatchers[object] = watchers
        table.insert(
            watchers,
            object:GetAttributeChangedSignal("QuayInteraction"):Connect(function()
                if object:GetAttribute("QuayInteraction") then
                    clear()
                    registerTarget(object)
                end
            end)
        )
        table.insert(
            watchers,
            object.AncestryChanged:Connect(function()
                if not object:IsDescendantOf(workspace) then
                    clear()
                end
            end)
        )
    end
    self.interact = Gui.button(self.screen, "Interact", function()
        self:interactWithNearest(send)
    end)
    self.interact.Name = "NearbyActivity"
    self.interact.AnchorPoint = Vector2.new(0.5, 1)
    self.interact.Position = UDim2.new(0.5, 0, 1, -10)
    self.interact.Size = UDim2.fromOffset(240, 44)
    self.interact.Visible = false
    graphicButton(self.interact, "arrow")
    self.panel = Gui.make("Frame", self.screen, {
        Name = "Journal",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(0.94, 0.88),
        BackgroundColor3 = Theme.Cream,
        BorderSizePixel = 0,
        Visible = false,
    })
    Gui.round(self.panel, 14)
    DeviceSkin.panel(self.panel, "journal")
    Gui.make(
        "UISizeConstraint",
        self.panel,
        { MaxSize = Vector2.new(850, 780), MinSize = Vector2.new(280, 200) }
    )
    local title = Gui.label(self.panel, "NEEDLE QUAY", 20)
    title.Font = Enum.Font.Code
    self.title = title
    title.Position, title.Size = UDim2.fromOffset(56, 10), UDim2.new(1, -204, 0, 40)
    title.TextScaled = true
    Gui.make("UITextSizeConstraint", title, { MinTextSize = 12, MaxTextSize = 20 })
    local details = Gui.button(self.panel, "HINTS", function()
        self.details = not self.details
        self:render()
    end)
    details.Font, details.TextSize = Enum.Font.Code, 12
    details.Position, details.Size = UDim2.new(1, -144, 0, 8), UDim2.fromOffset(64, 44)
    self.detailsControl = details
    local close = Gui.button(self.panel, "", function()
        send("QuayClose")
    end)
    close.Position, close.Size = UDim2.new(1, -72, 0, 8), UDim2.fromOffset(60, 44)
    close:SetAttribute("NoActionIcon", true)
    local closeIcon = Icons.make(close, "close", Theme.Cream, 24)
    closeIcon.Position, closeIcon.ZIndex = UDim2.fromOffset(18, 10), 3
    close.Modal = true
    self.close = close
    local tabs = Gui.make("ScrollingFrame", self.panel, {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(56, 58),
        Size = UDim2.new(1, -84, 0, 68),
        CanvasSize = UDim2.fromOffset(728, 0),
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollingDirection = Enum.ScrollingDirection.X,
    })
    self.tabs = {}
    local tabNames = {
        route = "Story",
        explore = "Explore",
        style = "Style",
        shop = "Shop",
        city = "City",
        life = "Life",
        companions = "People",
    }
    local tabIcons = {
        route = "journal",
        explore = "discovery",
        style = "headphones",
        shop = "shop",
        city = "city",
        life = "route",
        companions = "people",
    }
    for index, name in { "route", "explore", "style", "shop", "city", "life", "companions" } do
        local button = Gui.button(tabs, tabNames[name], function()
            self.tab = name
            self.scroll.CanvasPosition = Vector2.zero
            if name == "shop" then
                send("LifeRefreshShop")
            end
            self:render()
        end)
        button.Name = "Tab_" .. name
        button.Position, button.Size =
            UDim2.fromOffset((index - 1) * 104, 0), UDim2.fromOffset(100, 64)
        button.Font, button.TextSize, button.TextYAlignment =
            Enum.Font.Code, 12, Enum.TextYAlignment.Bottom
        button:SetAttribute("NoActionIcon", true)
        Gui.make("UIPadding", button, { PaddingBottom = UDim.new(0, 6) })
        local tabIcon = Icons.make(button, tabIcons[name], Theme.Amber, 28)
        tabIcon.Position, tabIcon.ZIndex = UDim2.fromOffset(36, 6), 3
        Gui.round(
            Gui.make("Frame", button, {
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
        self.tabs[name] = button
    end
    self.scroll = Gui.make("ScrollingFrame", self.panel, {
        Name = "Content",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(56, 136),
        Size = UDim2.new(1, -84, 1, -160),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(),
        ScrollBarThickness = 5,
        BorderSizePixel = 0,
    })
    Gui.make(
        "UIListLayout",
        self.scroll,
        { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }
    )
    self.companions = CompanionView.new(self.scroll, send)
    self.life = require(script.Parent.QuayLifeView).new(
        self.scroll,
        function(key, lifeTitle, detail)
            self.route:trackLife(key, lifeTitle, detail)
            send("QuayClose")
        end
    )
    self.dialogue = DialogueView.new(self.scroll, send)
    self.commissions = require(script.Parent.QuayCommissionView).new(self.dialogue.root, send)
    self.notice = Gui.label(self.scroll, "", 15)
    self.notice.Size = UDim2.new(1, -10, 0, 0)
    self.notice.AutomaticSize = Enum.AutomaticSize.Y
    self.notice.LayoutOrder = 0
    self.help = Gui.label(self.scroll, "", 17)
    self.help.Size = UDim2.new(1, -10, 0, 0)
    self.help.AutomaticSize = Enum.AutomaticSize.Y
    self.help.LayoutOrder = 2
    self.progress = Gui.label(self.scroll, "", 15, Theme.Teal)
    self.progress.Font, self.progress.BackgroundTransparency, self.progress.BackgroundColor3 =
        Enum.Font.Code, 0, Theme.Teal
    self.progress.TextColor3 = Theme.Cream
    Gui.round(self.progress, 8)
    Gui.make("UIPadding", self.progress, {
        PaddingTop = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
    })
    self.progress.Size, self.progress.AutomaticSize = UDim2.new(1, -10, 0, 0), Enum.AutomaticSize.Y
    self.progress.LayoutOrder = 3
    self.experiencePanel = ExperiencePanel.new(self.scroll, send)
    self.shopRoot = Gui.make("Frame", self.scroll, {
        Name = "QuayShop",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -10, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 3,
        Visible = false,
    })
    self.shopPanel = ShopPanel.new(self.shopRoot, function()
        send("LifeRefreshShop")
    end)
    self.storyRoot = Gui.make("Frame", self.scroll, {
        Name = "ChapterStory",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -10, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 1,
    })
    Gui.make(
        "UIListLayout",
        self.storyRoot,
        { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }
    )
    self.storyHeading = Gui.label(self.storyRoot, "", 17, Theme.Teal)
    self.storyHeading.Font = Enum.Font.Code
    self.storyHeading.Size, self.storyHeading.AutomaticSize =
        UDim2.new(1, -8, 0, 0), Enum.AutomaticSize.Y
    self.storyHeading.LayoutOrder = 0
    self.storyText = Gui.label(self.storyRoot, "", 17, Theme.Ink)
    self.storyText.Name = "ChapterText"
    self.storyText.Size, self.storyText.AutomaticSize = UDim2.new(1, -8, 0, 0), Enum.AutomaticSize.Y
    self.storyText.LayoutOrder = 1
    self.storyNext = Gui.button(self.storyRoot, "Next", function()
        if self.currentScene then
            self.storyPage = (self.storyPage or 1) % #self.currentScene.lines + 1
        end
        self:render()
    end)
    self.storyNext.Size, self.storyNext.LayoutOrder = UDim2.new(1, -8, 0, 48), 2
    graphicButton(self.storyNext, "arrow")
    self.dedications = Gui.make("Frame", self.scroll, {
        Name = "ConcertDedication",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -10, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 4,
        Visible = false,
    })
    Gui.make(
        "UIListLayout",
        self.dedications,
        { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }
    )
    self.dedicationButtons = {}
    for index, option in Story.Dedications do
        local control = Gui.button(self.dedications, option.label, function()
            send("LifeDedicate", option.id)
        end)
        control.Size, control.LayoutOrder = UDim2.new(1, 0, 0, 44), index
        self.dedicationButtons[option.id] = control
    end
    self.actions = Gui.make("Frame", self.scroll, {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -10, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 4,
    })
    Gui.make(
        "UIListLayout",
        self.actions,
        { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }
    )
    self.buttons = {}
    self.activityButtons = {}
    for index, activity in StreetGames.Routes do
        local b = Gui.button(self.actions, StreetGames.ById[activity].title .. "  →", function()
            self.route:trackActivity(activity)
            send("QuayClose")
        end)
        b.Name = "FindStreetGame_" .. activity
        b.LayoutOrder = 20 + index
        b.Size = UDim2.new(1, 0, 0, 52)
        b.TextXAlignment = Enum.TextXAlignment.Center
        graphicButton(b, StreetGames.ById[activity].icon)
        self.activityButtons[activity] = b
    end
    local function button(key, titleText, action, value)
        local b = Gui.button(self.actions, titleText, function()
            send(action, value)
        end)
        b.Name = key
        b.Size = UDim2.new(1, 0, 0, 48)
        graphicButton(b, ({
            enter = "pads",
            visit = "people",
            explore = "route",
            back = "arrow",
            listen = "disc",
            check = "check",
            pulse = "steps",
            texture = "sound",
            tune = "disc",
            optional = "arrow",
            finale = "play",
            save = "save",
        })[key] or "route")
        b.LayoutOrder = #self.buttons + 1
        table.insert(self.buttons, b)
        self[key] = b
    end
    for _, stop in Catalog.stops do
        button(
            stop.existing_parking_id,
            "Park at " .. stop.name,
            "QuayPark",
            stop.existing_parking_id
        )
    end
    button("enter", "MY STUDIO", "QuayEnter")
    button("visit", "MEET THE HOST", "QuayVisit")
    button("explore", "KEEP EXPLORING", "QuayClose")
    button("back", "RETURN TO QUAY", "QuayReturn")
    button("listen", "LISTEN", "QuayListen")
    button("check", "CHECK MY MUSIC", "QuayCheck")
    for _, tag in { "pulse", "texture", "tune" } do
        button(tag, string.upper(tag), "QuaySort", tag)
    end
    button("optional", "CONTINUE PRIVATELY", "QuayOptional")
    button("finale", "ENTER CONCERT", "QuayFinale")
    button("save", "Save profile and journal", "QuaySave")
    self.recordChoices = Gui.make("Frame", self.actions, {
        Name = "RecordTags",
        LayoutOrder = 2,
        Size = UDim2.new(1, 0, 0, 68),
        BackgroundTransparency = 1,
    })
    for index, tag in { "pulse", "texture", "tune" } do
        local b = self[tag]
        b.Parent = self.recordChoices
        b.Position, b.Size = UDim2.fromScale((index - 1) / 3, 0), UDim2.new(1 / 3, -4, 1, 0)
        b:SetAttribute("NoActionIcon", true)
        b:FindFirstChildOfClass("UIPadding"):Destroy()
        b.Font, b.TextSize, b.TextXAlignment, b.TextYAlignment =
            Enum.Font.Code, 12, Enum.TextXAlignment.Center, Enum.TextYAlignment.Bottom
        Gui.make("UIPadding", b, { PaddingBottom = UDim.new(0, 6) })
        local icon = Icons.make(
            b,
            ({ pulse = "steps", texture = "sound", tune = "disc" })[tag],
            Theme.Amber,
            26
        )
        icon.ZIndex = 3
        icon.AnchorPoint, icon.Position = Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 8)
    end
    self.listen.LayoutOrder, self.visit.LayoutOrder, self.finale.LayoutOrder = 1, 1, 1
    self.check.LayoutOrder, self.enter.LayoutOrder = 10, 11
    self.explore.LayoutOrder, self.save.LayoutOrder = 30, 31
    for index, stop in Catalog.stops do
        self[stop.existing_parking_id].LayoutOrder = 12 + index
    end
    self.journal = Gui.make("Frame", self.scroll, {
        Name = "QuestList",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -10, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 5,
    })
    Gui.make(
        "UIListLayout",
        self.journal,
        { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }
    )
    self.rows = {}
    local summary = Gui.make("Frame", self.journal, {
        Name = "ChapterProgress",
        Size = UDim2.new(1, 0, 0, 58),
        BackgroundTransparency = 1,
        LayoutOrder = 0,
    })
    Icons.make(summary, "flag", Theme.Teal, 28).Position = UDim2.fromOffset(4, 5)
    self.questTotals = Gui.label(summary, "", 17, Theme.Ink)
    self.questTotals.Font = Enum.Font.Code
    self.questTotals.Position, self.questTotals.Size =
        UDim2.fromOffset(42, 0), UDim2.new(1, -42, 0, 38)
    local rail = Gui.round(
        Gui.make("Frame", summary, {
            Position = UDim2.fromOffset(4, 46),
            Size = UDim2.new(1, -8, 0, 8),
            BackgroundColor3 = Theme.FadedTeal,
            BorderSizePixel = 0,
        }),
        4
    )
    self.questFill = Gui.round(
        Gui.make(
            "Frame",
            rail,
            { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Theme.Teal, BorderSizePixel = 0 }
        ),
        4
    )
    for index, quest in Catalog.quests do
        local label = Gui.button(self.journal, "", function()
            self.route:track(quest.id)
            send("QuayClose")
        end)
        label.Name = quest.id
        label.TextSize = 15
        label.TextXAlignment = Enum.TextXAlignment.Left
        Gui.make("UIPadding", label, {
            PaddingLeft = UDim.new(0, 52),
            PaddingRight = UDim.new(0, 10),
            PaddingTop = UDim.new(0, 8),
            PaddingBottom = UDim.new(0, 8),
        })
        Gui.make("UISizeConstraint", label, { MinSize = Vector2.new(0, 64) })
        label.Size = UDim2.fromScale(1, 0)
        label.AutomaticSize = Enum.AutomaticSize.Y
        label.LayoutOrder = index
        label.Font = Enum.Font.Code
        label:SetAttribute("NoActionIcon", true)
        Icons.make(label, "check", Theme.Teal, 28).Name = "QuestDone"
        label.QuestDone.Position = UDim2.fromOffset(12, 14)
        label.QuestDone.ZIndex = 3
        Icons.make(label, "flag", Theme.Amber, 28).Name = "QuestNext"
        label.QuestNext.Position = UDim2.fromOffset(12, 14)
        label.QuestNext.ZIndex = 3
        self.rows[quest.id] = label
    end
    self.city = Gui.make("Frame", self.scroll, {
        BackgroundColor3 = Theme.Ink,
        Size = UDim2.new(1, -10, 0, 260),
        LayoutOrder = 2,
        Visible = false,
    })
    -- Authored district polygon outlines in normalized map coordinates, no uploaded image.
    local maxX, maxY = 1, 1
    for _, district in Catalog.districts do
        for _, point in district.polygon do
            maxX = math.max(maxX, point[1])
            maxY = math.max(maxY, point[2])
        end
    end
    local function drawMap()
        for _, item in self.city:GetChildren() do
            item:Destroy()
        end
        local size = self.city.AbsoluteSize
        for _, district in Catalog.districts do
            local cx, cy = 0, 0
            for i, point in district.polygon do
                local nextPoint = district.polygon[i % #district.polygon + 1]
                local a =
                    Vector2.new(point[1] / maxX * (size.X - 12) + 6, point[2] / maxY * 248 + 6)
                local b = Vector2.new(
                    nextPoint[1] / maxX * (size.X - 12) + 6,
                    nextPoint[2] / maxY * 248 + 6
                )
                local delta = b - a
                Gui.make("Frame", self.city, {
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2),
                    Size = UDim2.fromOffset(delta.Magnitude, 2),
                    Rotation = math.deg(math.atan2(delta.Y, delta.X)),
                    BackgroundColor3 = if district.id == "N00"
                        then Theme.Amber
                        else Theme.FadedTeal,
                    BorderSizePixel = 0,
                })
                cx += a.X
                cy += a.Y
            end
            local label = Gui.label(
                self.city,
                district.id .. (if district.id == "N00" then "\nOPEN" else "\nLOCKED"),
                11,
                Theme.Cream
            )
            label.Font = Enum.Font.Code
            label.AnchorPoint = Vector2.new(0.5, 0.5)
            label.Position = UDim2.fromOffset(cx / #district.polygon, cy / #district.polygon)
            label.Size = UDim2.fromOffset(66, 34)
            label.TextXAlignment = Enum.TextXAlignment.Center
        end
    end
    table.insert(
        self.connections,
        self.city:GetPropertyChangedSignal("AbsoluteSize"):Connect(drawMap)
    )
    self.cityList =
        Gui.make("Frame", self.scroll, { Name = "CityDistrictCards", BackgroundTransparency = 1 })
    self.cityList.LayoutOrder = 3
    self.cityList.Size = UDim2.new(1, -10, 0, 0)
    self.cityList.AutomaticSize = Enum.AutomaticSize.Y
    Gui.make(
        "UIListLayout",
        self.cityList,
        { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }
    )
    for index, district in Catalog.districts do
        local open = district.id == "N00"
        local card = Gui.round(
            Gui.make("Frame", self.cityList, {
                Name = district.id,
                Size = UDim2.new(1, 0, 0, 72),
                BackgroundColor3 = if open then Theme.Teal else Theme.Ink,
                BorderSizePixel = 0,
                LayoutOrder = index,
            }),
            10
        )
        Icons.make(card, if open then "city" else "lock", Theme.Amber, 32).Position =
            UDim2.fromOffset(12, 18)
        local titleLabel = Gui.label(card, district.name, 15, Theme.Cream)
        titleLabel.Font = Enum.Font.Code
        titleLabel.Position, titleLabel.Size = UDim2.fromOffset(54, 6), UDim2.new(1, -64, 0, 40)
        local status = Gui.label(
            card,
            district.id .. " / " .. (if open then "OPEN" else "LOCKED"),
            11,
            if open then Theme.Cream else Theme.Amber
        )
        status.Font = Enum.Font.Code
        status.Position, status.Size = UDim2.fromOffset(54, 46), UDim2.new(1, -64, 0, 20)
    end
    table.insert(
        self.connections,
        network.State.OnClientEvent:Connect(function(state)
            self.state = state
            self.route:accept(state)
            self.voice:accept(state)
            self.commissionVoice:accept(state)
            self.sideActivities:accept(state)
            self.badges:accept(state)
            if not self.targetsReady then
                self.targetsReady = true
                for _, object in workspace:GetDescendants() do
                    if object:IsA("BasePart") and object:GetAttribute("QuayInteraction") then
                        registerTarget(object)
                    elseif object:IsA("ProximityPrompt") then
                        monitorPrompt(object)
                    end
                end
            end
            if state.notice then
                self.notice.Text = state.notice
            end
            self:render()
        end)
    )
    table.insert(
        self.connections,
        Input.InputBegan:Connect(function(input, processed)
            if processed or Input:GetFocusedTextBox() then
                return
            end
            if input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.ButtonX then
                if self.interact.Visible then
                    self:interactWithNearest(send)
                end
            end
            if input.KeyCode == Enum.KeyCode.M then
                send(if self.panel.Visible then "QuayClose" else "QuayJournal")
            end
            if input.KeyCode == Enum.KeyCode.ButtonSelect then
                send(if self.panel.Visible then "QuayClose" else "QuayJournal")
            elseif input.KeyCode == Enum.KeyCode.ButtonB and self.panel.Visible then
                send("QuayClose")
            end
        end)
    )
    table.insert(
        self.connections,
        workspace.DescendantAdded:Connect(function(object)
            if object:IsA("ProximityPrompt") then
                monitorPrompt(object)
            elseif object:IsA("BasePart") and object:GetAttribute("QuayInteraction") then
                registerTarget(object)
            end
            if
                object:IsA("BasePart")
                and (
                    object:GetAttribute("QuayPersonalTarget")
                    or object:GetAttribute("QuayRadio")
                    or object:GetAttribute("QuayRestoration")
                    or object:GetAttribute("QuayNoticeStop")
                )
            then
                self.personal[object] = true
                self:project(object)
            end
        end)
    )
    for _, object in workspace:GetDescendants() do
        if object:IsA("ProximityPrompt") then
            monitorPrompt(object)
        end
        if object:IsA("BasePart") then
            if object:GetAttribute("QuayInteraction") then
                registerTarget(object)
            end
            if
                object:GetAttribute("QuayPersonalTarget")
                or object:GetAttribute("QuayRadio")
                or object:GetAttribute("QuayRestoration")
                or object:GetAttribute("QuayNoticeStop")
            then
                self.personal[object] = true
            end
        end
    end
    local elapsed = 0
    table.insert(
        self.connections,
        RunService.Heartbeat:Connect(function(dt)
            elapsed += dt
            if elapsed < 0.2 then
                return
            end
            elapsed = 0
            self.nearest = nil
            local character = Players.LocalPlayer.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            local best = 12
            if root and self.state and not self.state.station and not self.panel.Visible then
                for object in self.interactionTargets do
                    if not object.Parent then
                        self.interactionTargets[object] = nil
                        continue
                    end
                    local prompt = object:FindFirstChildOfClass("ProximityPrompt")
                    local owner = object.Parent:GetAttribute("OwnerUserId")
                    local allowed = object:GetAttribute("QuayInteraction") ~= "enter"
                        or owner == Players.LocalPlayer.UserId
                    local distance = (root.Position - object.Position).Magnitude
                    if
                        allowed
                        and not object:GetAttribute("LocalCompleted")
                        and prompt
                        and prompt:GetAttribute("QuayCustomPrompt") == true
                        and distance < best
                        and require(Shared.QuayOcclusion).visible(
                            (character:FindFirstChild("Head") or root).Position,
                            object,
                            character,
                            self.state.quay and self.state.quay.progress
                        )
                        and (
                            not workspace.CurrentCamera
                            or require(Shared.QuayOcclusion).visible(
                                workspace.CurrentCamera.CFrame.Position,
                                object,
                                character,
                                self.state.quay and self.state.quay.progress
                            )
                        )
                    then
                        best = distance
                        self.nearest = object
                    end
                end
            end
            self.interact.Visible = self.nearest ~= nil
            if self.nearest then
                local action = self.nearest.ProximityPrompt.ActionText
                local id = self.nearest:GetAttribute("QuayInteraction")
                local life = self.state.quay and self.state.quay.life
                if life and id:sub(1, 5) == "life:" then
                    local key, progress = id:sub(6), life.progress
                    if key:sub(1, 7) == "listen_" and progress.stamps[key:sub(8)] then
                        action = "Recall postcard"
                    elseif key:sub(1, 7) == "garden_" and progress.gardens[key:sub(8)] then
                        action = "Check flowers"
                    elseif key == "parcel_pickup" and progress.parcel > 0 then
                        action = if progress.parcel == 1 then "View delivery" else "Thank Naya"
                    elseif key == "parcel_drop" and progress.parcel ~= 1 then
                        action = if progress.parcel == 2 then "Visit Tori" else "Read delivery note"
                    end
                end
                self.interact.Text = (if Input.TouchEnabled then "" else "E / X  ·  ") .. action
            end
        end)
    )
    local function resizePanel()
        local height = self.screen.AbsoluteSize.Y
        local content = self.scroll.UIListLayout.AbsoluteContentSize.Y + 140
        self.panel.Size = UDim2.new(0.94, 0, 0, math.min(height * 0.88, math.max(320, content)))
    end
    table.insert(
        self.connections,
        self.scroll.UIListLayout
            :GetPropertyChangedSignal("AbsoluteContentSize")
            :Connect(resizePanel)
    )
    table.insert(
        self.connections,
        self.screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(resizePanel)
    )
    resizePanel()
    send("Hello")
    return self
end

function View:interactWithNearest(send)
    local target = self.nearest
    if not target or not target.Parent then
        return
    end
    local id = target:GetAttribute("QuayInteraction")
    if id == "enter" then
        send("QuayEnter")
    elseif id == "return" then
        send("QuayReturn")
    else
        send("QuayInteract", id)
    end
end

function View:project(object)
    local q = self.state and self.state.quay and self.state.quay.progress
    if not q then
        return
    end
    local id = object:GetAttribute("QuayPersonalTarget")
    if id then
        local kind = if id:sub(1, 4) == "dock" then "dock" else "market"
        local done = q[kind][tonumber(id:sub(-1))] == true
        object.LocalTransparencyModifier = if done then 1 else 0
        object:SetAttribute("LocalCompleted", done)
        object.CanCollide = not done and object.Transparency < 0.95
        object.CanQuery = not done and object.Transparency < 0.95
        object.CastShadow = not done and object.Transparency < 0.95
        local prompt = object:FindFirstChildOfClass("ProximityPrompt")
        if prompt then
            prompt.Enabled = false
            prompt:SetAttribute("QuayCustomPrompt", not done)
        end
        local sign = object:FindFirstChildOfClass("BillboardGui")
        if sign then
            sign.Enabled = not done
        end
    elseif object:GetAttribute("QuayRadio") then
        object.Color = if q.completed["NQ-Q10"] then Theme.Amber else Theme.Teal
    elseif object:GetAttribute("QuayNoticeStop") then
        local stop = object:GetAttribute("QuayNoticeStop")
        local count, total = Objectives.region(q, stop)
        local gui = object:FindFirstChild("NeighborhoodNotice")
        local text = gui and gui:FindFirstChild("Status")
        if text then
            text.Text = if count == total
                then "ROOM FOR MUSIC\nThis corner is ready"
                else string.format("MAKING ROOM\n%d / %d local activities", count, total)
        end
    elseif object:GetAttribute("QuayRestoration") then
        local restored = q.completed["NQ-Q12"]
        local stop = object:GetAttribute("QuayRestorationStop")
        local count, total = Objectives.region(q, stop)
        local amount = if restored then 1 elseif total > 0 then count / total else 0
        local practical = object:GetAttribute("PracticalBrightness")
        if practical then
            object.Color = Theme.FadedTeal:Lerp(Theme.Amber, 0.55 + amount * 0.45)
            object.Material = if self.effects == false
                then Enum.Material.SmoothPlastic
                else Enum.Material.Neon
            local light = object:FindFirstChildOfClass("PointLight")
            if light then
                light.Brightness = practical * (0.35 + amount * 0.8)
                light.Enabled = self.effects ~= false
            end
            return
        end
        object.Color = Theme.FadedTeal:Lerp(Theme.Amber, amount)
        object.Material = if amount > 0 and self.effects ~= false
            then Enum.Material.Neon
            else Enum.Material.SmoothPlastic
        local light = object:FindFirstChildOfClass("PointLight")
        if light then
            light.Enabled = self.effects ~= false
            light.Brightness = 0.2 + amount
        end
    end
end

function View:setEffects(enabled)
    self.effects = enabled
    self.badges.effects = enabled
    for object in self.personal do
        if object.Parent then
            self:project(object)
        end
    end
end

function View:render()
    local state = self.state
    local quay = state and state.quay
    self.toggle.Visible = quay ~= nil
        and not state.station
        and not (state.concert and state.concert.open)
    local busy = state
        and (
            state.station
            or state.listening
            or (state.stage and state.stage.open)
            or (state.concert and state.concert.open)
            or (state.jam and (state.jam.active or state.jam.open))
        )
    self.companionRibbon.Visible = quay ~= nil and not busy and quay.open == nil
    local preference = state and state.companion
    self.companionRibbon.Text = if preference and preference.selected ~= "none"
        then (if preference.selected == "alissia" then "ALISSIA" else "NIKOLAS")
        else "PEOPLE / SOLO"
    self.companions:update(preference, state and state.ready, state and state.saving)
    local wasOpen = self.panel.Visible
    self.panel.Visible = quay ~= nil and quay.open ~= nil and not busy
    if not quay then
        self.experiencePanel:update(state, self.tab, false)
        self.companions:setVisible(false)
        self.dialogue:update(nil, false)
        self.commissions:update(nil, nil)
        return
    end
    self.toggle.Text = if quay.progress.completed["NQ-Q12"] then "OPEN NIGHT" else "MAP"
    if self.panel.Visible and (not wasOpen or self.lastOpen ~= quay.open) then
        if quay.open ~= "map" then
            self.tab = "route"
        end
        self.scroll.CanvasPosition = Vector2.zero
        if Input.GamepadEnabled then
            GuiService.SelectedObject = self.close
        end
    elseif
        not self.panel.Visible
        and wasOpen
        and GuiService.SelectedObject
        and GuiService.SelectedObject:IsDescendantOf(self.panel)
    then
        GuiService.SelectedObject = nil
    end
    self.lastOpen = quay.open
    for _, child in self.scroll:GetChildren() do
        if child:IsA("GuiObject") then
            child.Visible = true
        end
    end
    for name, button in self.tabs do
        button.BackgroundColor3 = if self.tab == name then Theme.Ink else Theme.Teal
        button.SelectedMark.Visible = self.tab == name
    end
    self.detailsControl.BackgroundColor3 = if self.details then Theme.Ink else Theme.Teal
    self.experiencePanel:update(state, self.tab, self.panel.Visible)
    self.shopRoot.Visible = self.tab == "shop"
    self.shopPanel:update(state.experience and state.experience.commerce)
    self.storyRoot.Visible = self.tab == "route"
    self.dedications.Visible = self.tab == "route"
        and (quay.open == "finale" or quay.open == "map")
        and state.experience ~= nil
    self.life:update(state)
    self.life.root.Visible = self.tab == "life"
    if self.tab == "life" then
        self.companions:setVisible(false)
        self.dialogue:update(nil, false)
        self.commissions:update(nil, nil)
        for _, child in self.scroll:GetChildren() do
            if child:IsA("GuiObject") then
                child.Visible = child == self.life.root
            end
        end
        self.title.Text = "YOUR LIFE IN NEEDLE QUAY"
        return
    end
    local otherTab = self.tab == "explore" or self.tab == "style" or self.tab == "shop"
    if otherTab then
        self.companions:setVisible(false)
        self.dialogue:update(nil, false)
        self.commissions:update(nil, nil)
        for _, child in self.scroll:GetChildren() do
            if child:IsA("GuiObject") then
                child.Visible = child == self.experiencePanel.explore and self.tab == "explore"
                    or child == self.experiencePanel.style and self.tab == "style"
                    or child == self.shopRoot and self.tab == "shop"
            end
        end
        self.title.Text = ({
            explore = "AROUND NEEDLE QUAY",
            style = "YOUR GROOVE + WARDROBE",
            shop = "QUAYSIDE COSMETICS",
        })[self.tab]
        return
    end
    local companionTab = self.tab == "companions"
    self.companions.root.Visible = companionTab
    self.companions:setVisible(self.panel.Visible and companionTab)
    self.help.Visible, self.notice.Visible = not companionTab, not companionTab
    local city = self.tab == "city"
    self.dialogue:update(quay.dialogue, not city and not companionTab)
    self.commissions:update(
        quay,
        if not city and not companionTab then quay.dialogue and quay.dialogue.id else nil
    )
    if
        quay.dialogue
        and self.notice.Text:sub(1, #quay.dialogue.name + 1) == quay.dialogue.name .. ":"
    then
        self.notice.Visible = false
    end
    self.city.Visible, self.cityList.Visible = city, city
    self.actions.Visible, self.journal.Visible =
        not city and not companionTab, not city and not companionTab and quay.open == "map"
    self.help.Text = if city
        then "RESONANCE CITY\nOnly Needle Quay is open in this demo. Genres remain freely selectable in the sampler."
        else instructions[quay.open] or instructions.map
    local open = quay.open
    for _, b in self.activityButtons do
        b.Visible = open == "map"
    end
    local building = type(open) == "string" and open:sub(1, 9) == "building:"
    self.visit.Visible = building or open == "encounter:sana"
    self.explore.Visible = open ~= "map"
    self.title.Text = if companionTab
        then "WALK TOGETHER / YOUR CHOICE"
        elseif building then string.upper(buildingNames[open:sub(10)] or "NEEDLE QUAY")
        elseif open == "map" then "NEEDLE QUAY / JOURNAL"
        elseif quay.dialogue then string.upper(quay.dialogue.role)
        else "NEIGHBORHOOD ACTIVITY"
    if building and not city then
        local host = hosts[destination(open:sub(10))]
        self.help.Text = "Music starts with the people around you. Meet "
            .. host
            .. " to help the neighborhood and collect new sounds."
        self.visit.Text = "Meet " .. host
        if open == "building:NQ-BLD-06" then
            self.help.Text =
                "Nell is just outside Warm Current Cafe. Stop for a conversation whenever you like; there is no required job here."
            self.visit.Text = "Meet Nell at the cafe"
        elseif open == "building:NQ-BLD-04" then
            self.help.Text =
                "Sana is making room for a market stage. Meet her to help with the cases; Naya's record activity is nearby."
            self.visit.Text = "Meet Sana at the market"
        end
    end
    if open == "encounter:cafe" then
        self.help.Text =
            "Take a pause, ask Nell a question, or continue exploring. Your music and progress stay yours."
    elseif open == "encounter:sana" then
        self.help.Text =
            "The three marked cases belong in storage. The market stalls stay in place. Naya's records are nearby when you want to listen."
        self.visit.Text = "Listen with Naya"
    end
    if quay.dialogue and not building and open ~= "encounter:cafe" and open ~= "encounter:sana" then
        self.help.Text = self.help.Text:match("\n(.*)") or self.help.Text
    end
    local sceneKey = if building
        then open:sub(10)
        elseif type(open) == "string" and open:sub(1, 10) == "encounter:" then open:sub(11)
        else open
    local scene = Story.scene(sceneKey, quay.progress.completed)
    if self.currentScene ~= scene then
        self.currentScene, self.storyPage = scene, 1
    end
    local page = self.storyPage or 1
    self.storyRoot.Visible = self.tab == "route"
    self.storyHeading.Text = scene.speaker .. " / " .. scene.title
    self.storyText.Text = scene.lines[page] .. "\n\n" .. scene.prompt
    self.storyNext.Text = if page < #scene.lines
        then "NEXT / " .. page .. "/" .. #scene.lines
        else "READ AGAIN"
    self.dedications.Visible = self.tab == "route"
        and (open == "finale" or open == "map")
        and state.experience ~= nil
    if state.experience then
        for id, control in self.dedicationButtons do
            control.BackgroundColor3 = if state.experience.progress.dedication == id
                then Theme.Ink
                else Theme.Teal
        end
    end
    self.listen.Visible = open == "P3" and quay.progress.sort < 3
    self.recordChoices.Visible = self.listen.Visible
    local p = quay.progress
    local function count(t)
        local n = 0
        for _, done in t do
            if done then
                n += 1
            end
        end
        return n
    end
    self.progress.Text = if open == "P1"
        then string.format(
            "Dock crates %d/3  ·  Metal rhythm %s",
            count(p.dock),
            if p.completed["NQ-Q02"] then "ready" else "to make"
        )
        elseif open == "P2" then string.format(
            "Repairs %d/3  ·  sequence variation %s",
            p.repair,
            if p.completed["NQ-Q05"] then "saved" else "to make"
        )
        elseif open == "P3" then string.format(
            "Records %d/3  ·  Stage cases %d/3",
            p.sort,
            count(p.market)
        )
        elseif open == "P4" then (if p.completed["NQ-Q09"]
            then "Reply heard  ·  "
            else "Mica is waiting for your four-note reply  ·  ") .. (if p.completed["NQ-Q10"]
            then "Signal on"
            else "Signal off")
        else ""
    self.progress.Visible = not city and not companionTab and self.progress.Text ~= ""
    self.check.Visible = open == "P1" or open == "P2" or open == "P3" or open == "P4"
    self.optional.Visible = open == "P1"
    self.finale.Visible = open == "finale"
    for _, tag in { "pulse", "texture", "tune" } do
        self[tag].Visible = open == "P3" and quay.progress.sort < 3
    end
    if open == "P3" and quay.progress.sort < 3 then
        self.help.Text ..= string.format(
            "\nRecord %d of 3: listen, then choose a tag.",
            quay.progress.sort + 1
        )
    end
    self.enter.Visible = quay.nearVan == true
    self.back.Visible = quay.canReturn == true
    for _, stop in Catalog.stops do
        self[stop.existing_parking_id].Visible = quay.canTravel == true
            and open == "map"
            and p.parking ~= stop.existing_parking_id
    end
    self.save.Text = if state.saving
        then "SAVING..."
        elseif state.saveMode == "session" then "SAVE / STUDIO SESSION"
        else "SAVE JOURNAL"
    local completedQuests = 0
    for _, quest in Catalog.quests do
        local done = quay.progress.completed[quest.id]
        completedQuests += if done then 1 else 0
        self.rows[quest.id].Interactable = not done
        self.rows[quest.id].Selectable = not done
        self.rows[quest.id].BackgroundColor3 = if done then Theme.Cream else Theme.Teal
        self.rows[quest.id].TextColor3 = if done then Theme.Ink else Theme.Cream
        self.rows[quest.id].QuestDone.Visible, self.rows[quest.id].QuestNext.Visible =
            done == true, done ~= true
        self.rows[quest.id].Text = quest.name
            .. (
                if self.details
                    then "\n" .. (if done and Story.milestone(quest.id)
                        then Story.milestone(quest.id).memory
                        else goals[quest.id] or quest.name)
                    else ""
            )
    end
    self.questTotals.Text = "YOUR CHAPTER / " .. completedQuests .. " OF " .. #Catalog.quests
    self.questFill.Size = UDim2.fromScale(completedQuests / math.max(1, #Catalog.quests), 1)
    self.help.Visible = not companionTab and self.details == true
    local old, current = self.projected, quay.progress
    local changed = not old or old.repair ~= current.repair or old.sort ~= current.sort
    if not changed then
        for _, field in { "completed", "dock", "market" } do
            for key, value in current[field] do
                if old[field][key] ~= value then
                    changed = true
                    break
                end
            end
        end
    end
    self.projected = current
    if not changed then
        return
    end
    for object in self.personal do
        if object.Parent then
            self:project(object)
        else
            self.personal[object] = nil
        end
    end
end

function View:destroy()
    self.experiencePanel:destroy()
    self.shopPanel:destroy()
    self.commissionVoice:destroy()
    self.commissions:destroy()
    for _, watchers in self.targetWatchers do
        for _, connection in watchers do
            connection:Disconnect()
        end
    end
    table.clear(self.targetWatchers)
    self.route:destroy()
    self.voice:destroy()
    self.sideActivities:destroy()
    self.badges:destroy()
    self.companions:destroy()
    for _, connection in self.connections do
        connection:Disconnect()
    end
    self.screen:Destroy()
end
return View
