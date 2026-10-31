local Players = game:GetService("Players")
local Input = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local Shared = game.ReplicatedStorage.Shared
local Theme = require(Shared.Theme)
local Catalog = require(Shared.NeedleQuayCatalog)
local Story = require(Shared.QuayStory)
local Activities = require(Shared.QuayActivities)
local Gui = require(script.Parent.GuiFactory)
local ExperiencePanel = require(script.Parent.QuayExperiencePanel)
local ShopPanel = require(script.Parent.QuayShopPanel)
local View = {}
View.__index = View
local instructions = {
    P1 = "TORI / DOCKSIDE EXCHANGE\nStow the three marked crates. Enter your Roamer, assign Quay metal in Sounds, and enable at least four different steps. Return here to check. Public performance is optional.",
    P2 = "IVO / REPAIR ALLEY\nUse controls 1, 2, 3 in order. In your Roamer, make two different patterns in A and B. Save to Beat Shelf, then save your profile. Return here to check.",
    P3 = "NAYA + SANA / VINYL MARKET\nListen to each record and match its role. Save your own beat in your Roamer, then help Sana clear three stage cases.",
    P4 = "MICA / BREAKWATER STEPS\nAssign Helper chirp to a pad. Enable only steps 1, 5, 9 and 13 for that sound. Return to check your reply, then use the signal console. Virtual game sounds only; no microphone.",
    finale = "RONAN / THE LANTERN ROOM\nFinish the neighborhood journal, then enter the concert room. Your saved beat needs two audible parts, a different A/B pattern, and a collected sound layered with another part. Use the Chapter concert prompt for the six-part set.",
    map = "NEEDLE QUAY / YOUR ROUTE\nWalk to your Roamer or a parking station to travel. Enter the studio at your own van door. Your music is always available; future district locks never restrict your choice of genre.",
}

local goals = {
    ["NQ-Q00"] = "Meet Tori and step inside your Roamer studio.",
    ["NQ-Q01"] = "Stow the three dock crates to open up the music corner.",
    ["NQ-Q02"] = "Put Quay metal on four different steps, then play it for Tori.",
    ["NQ-Q03"] = "Choose whether to share a dockside performance.",
    ["NQ-Q04"] = "Help Ivo: isolate power, clear the intake, restore power.",
    ["NQ-Q05"] = "Make different A and B patterns and save them to your Beat Shelf.",
    ["NQ-Q06"] = "Listen to Naya's three records and match their musical roles.",
    ["NQ-Q07"] = "Keep a composition on your Beat Shelf and save your session.",
    ["NQ-Q08"] = "Help Sana stow three cases around the market stage.",
    ["NQ-Q09"] = "Answer Mica with Helper chirp on steps 1, 5, 9 and 13.",
    ["NQ-Q10"] = "Switch on the breakwater signal after Mica hears your reply.",
    ["NQ-Q11"] = "Meet Ronan when the neighborhood is ready for music.",
    ["NQ-Q12"] = "Bring your saved beat to the Lantern Room and finish your set.",
}
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
    self.toggle = Gui.button(self.screen, "QUAY / MAP", function()
        send("QuayJournal")
    end)
    self.toggle.Position = UDim2.new(1, -144, 0, 8)
    self.toggle.Size = UDim2.fromOffset(132, 44)
    self.interactionTargets = {}
    local function registerTarget(object)
        self.interactionTargets[object] = true
        local prompt = object:FindFirstChildOfClass("ProximityPrompt")
        if prompt then
            prompt.Enabled = false
            prompt:SetAttribute("QuayCustomPrompt", true)
            prompt.Style = Enum.ProximityPromptStyle.Custom
            prompt.KeyboardKeyCode = Enum.KeyCode.Unknown
            prompt.GamepadKeyCode = Enum.KeyCode.Unknown
        end
    end
    self.interact = Gui.button(self.screen, "Interact", function()
        self:interactWithNearest(send)
    end)
    self.interact.Name = "NearbyActivity"
    self.interact.AnchorPoint = Vector2.new(0.5, 1)
    self.interact.Position = UDim2.new(0.5, 0, 1, -10)
    self.interact.Size = UDim2.fromOffset(240, 44)
    self.interact.Visible = false
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
    Gui.make(
        "UISizeConstraint",
        self.panel,
        { MaxSize = Vector2.new(850, 780), MinSize = Vector2.new(280, 200) }
    )
    local title = Gui.label(self.panel, "NEEDLE QUAY", 20)
    self.title = title
    title.Position, title.Size = UDim2.fromOffset(16, 10), UDim2.new(1, -100, 0, 40)
    local close = Gui.button(self.panel, "Close", function()
        send("QuayClose")
    end)
    close.Position, close.Size = UDim2.new(1, -80, 0, 8), UDim2.fromOffset(68, 44)
    close.Modal = true
    self.close = close
    local tabs = Gui.make("Frame", self.panel, {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(12, 58),
        Size = UDim2.new(1, -24, 0, 44),
    })
    self.tabs = {}
    local tabNames =
        { route = "Story", explore = "Explore", style = "My style", shop = "Shop", city = "City" }
    for index, name in { "route", "explore", "style", "shop", "city" } do
        local button = Gui.button(tabs, tabNames[name], function()
            self.tab = name
            self.scroll.CanvasPosition = Vector2.zero
            if name == "shop" then
                send("LifeRefreshShop")
            end
            self:render()
        end)
        button.Position = UDim2.fromScale((index - 1) * 0.2, 0)
        button.Size = UDim2.new(0.2, -4, 1, 0)
        self.tabs[name] = button
    end
    self.scroll = Gui.make("ScrollingFrame", self.panel, {
        Name = "Content",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(12, 112),
        Size = UDim2.new(1, -24, 1, -124),
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
    self.notice = Gui.label(self.scroll, "", 15)
    self.notice.Size = UDim2.new(1, -10, 0, 0)
    self.notice.AutomaticSize = Enum.AutomaticSize.Y
    self.notice.LayoutOrder = 0
    self.help = Gui.label(self.scroll, "", 17)
    self.help.Size = UDim2.new(1, -10, 0, 0)
    self.help.AutomaticSize = Enum.AutomaticSize.Y
    self.help.LayoutOrder = 1
    self.progress = Gui.label(self.scroll, "", 15, Theme.Teal)
    self.progress.Font = Theme.Bold
    self.progress.Size, self.progress.AutomaticSize = UDim2.new(1, -10, 0, 0), Enum.AutomaticSize.Y
    self.progress.LayoutOrder = 2
    self.storyControls = Gui.make("Frame", self.scroll, {
        Name = "StoryControls",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -10, 0, 44),
        LayoutOrder = 2,
    })
    self.nextLine = Gui.button(self.storyControls, "Next", function()
        local scene = self.currentScene
        if scene then
            self.storyPage = (self.storyPage or 1) % #scene.lines + 1
            self:render()
        end
    end)
    self.nextLine.Size = UDim2.new(0.5, -4, 1, 0)
    self.showHint = Gui.button(self.storyControls, "How do I do that?", function()
        self.hintOpen = not self.hintOpen
        self:render()
    end)
    self.showHint.Position, self.showHint.Size = UDim2.fromScale(0.5, 0), UDim2.new(0.5, -4, 1, 0)
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
    local dedicationLabel = Gui.label(self.dedications, "What is your set for?", 17)
    dedicationLabel.Size = UDim2.new(1, 0, 0, 28)
    dedicationLabel.LayoutOrder = 0
    self.dedicationButtons = {}
    for index, option in
        {
            { "curiosity", "For the sounds we have yet to find" },
            { "together", "For everyone who made room" },
            { "beginnings", "For trying something new" },
        }
    do
        local control = Gui.button(self.dedications, option[2], function()
            send("LifeDedicate", option[1])
        end)
        control.Size, control.LayoutOrder = UDim2.new(1, 0, 0, 44), index
        self.dedicationButtons[option[1]] = control
    end
    self.actions = Gui.make("Frame", self.scroll, {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -10, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 3,
    })
    Gui.make(
        "UIListLayout",
        self.actions,
        { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }
    )
    self.buttons = {}
    local function button(key, titleText, action, value)
        local b = Gui.button(self.actions, titleText, function()
            send(action, value)
        end)
        b.Name = key
        b.Size = UDim2.new(1, 0, 0, 44)
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
    button("enter", "Enter my Roamer studio", "QuayEnter")
    button("visit", "Go to the activity host", "QuayVisit")
    button("explore", "Continue exploring", "QuayClose")
    button("back", "Return from studio / concert", "QuayReturn")
    button("listen", "Listen to this record", "QuayListen")
    button("check", "Check my music for this activity", "QuayCheck")
    for _, tag in { "pulse", "texture", "tune" } do
        button(tag, string.upper(tag), "QuaySort", tag)
    end
    button("optional", "Continue without a public performance", "QuayOptional")
    button("finale", "Enter The Lantern Room concert", "QuayFinale")
    button("save", "Save profile and journal", "QuaySave")
    self.details = Gui.button(self.actions, "Show chapter details", function()
        self.journalExpanded = not self.journalExpanded
        self:render()
    end)
    self.details.Size, self.details.LayoutOrder = UDim2.new(1, 0, 0, 44), 32
    self.recordChoices = Gui.make("Frame", self.actions, {
        Name = "RecordTags",
        LayoutOrder = 2,
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundTransparency = 1,
    })
    for index, tag in { "pulse", "texture", "tune" } do
        local b = self[tag]
        b.Parent = self.recordChoices
        b.Position, b.Size = UDim2.fromScale((index - 1) / 3, 0), UDim2.new(1 / 3, -4, 1, 0)
    end
    self.listen.LayoutOrder, self.visit.LayoutOrder, self.finale.LayoutOrder = 1, 1, 1
    self.check.LayoutOrder, self.enter.LayoutOrder = 10, 11
    self.explore.LayoutOrder, self.save.LayoutOrder = 30, 31
    for index, stop in Catalog.stops do
        self[stop.existing_parking_id].LayoutOrder = 12 + index
    end
    self.journal = Gui.make("Frame", self.scroll, {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -10, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 3,
    })
    Gui.make(
        "UIListLayout",
        self.journal,
        { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }
    )
    self.rows = {}
    for index, quest in Catalog.quests do
        local label = Gui.label(self.journal, "", 15)
        label.Size = UDim2.new(1, 0, 0, 0)
        label.AutomaticSize = Enum.AutomaticSize.Y
        label.LayoutOrder = index
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
    self.cityList = Gui.label(self.scroll, "", 16)
    self.cityList.LayoutOrder = 3
    self.cityList.Size = UDim2.new(1, -10, 0, 0)
    self.cityList.AutomaticSize = Enum.AutomaticSize.Y
    local names = {}
    for _, district in Catalog.districts do
        table.insert(
            names,
            district.id
                .. " / "
                .. district.name
                .. (if district.id == "N00" then " — OPEN" else " — LOCKED")
        )
    end
    self.cityList.Text = table.concat(names, "\n\n")
    table.insert(
        self.connections,
        network.State.OnClientEvent:Connect(function(state)
            self.state = state
            if not self.targetsReady then
                self.targetsReady = true
                for _, object in workspace:GetDescendants() do
                    if object:IsA("BasePart") and object:GetAttribute("QuayInteraction") then
                        registerTarget(object)
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
            if object:IsA("BasePart") and object:GetAttribute("QuayInteraction") then
                registerTarget(object)
            end
            if
                object:IsA("BasePart")
                and (
                    object:GetAttribute("QuayPersonalTarget")
                    or object:GetAttribute("QuayRadio")
                    or object:GetAttribute("QuayRestoration")
                )
            then
                self.personal[object] = true
                self:project(object)
            end
        end)
    )
    for _, object in workspace:GetDescendants() do
        if object:IsA("BasePart") then
            if object:GetAttribute("QuayInteraction") then
                registerTarget(object)
            end
            if
                object:GetAttribute("QuayPersonalTarget")
                or object:GetAttribute("QuayRadio")
                or object:GetAttribute("QuayRestoration")
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
                        and prompt
                        and prompt:GetAttribute("QuayCustomPrompt") == true
                        and distance < best
                    then
                        best = distance
                        self.nearest = object
                    end
                end
            end
            self.interact.Visible = self.nearest ~= nil
            if self.nearest then
                self.interact.Text = "E / X  ·  " .. self.nearest.ProximityPrompt.ActionText
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
    elseif object:GetAttribute("QuayRestoration") then
        local restored = q.completed["NQ-Q12"]
        local practical = object:GetAttribute("PracticalBrightness")
        if practical then
            object.Color = Theme.Amber
            object.Material = Enum.Material.Neon
            local light = object:FindFirstChildOfClass("PointLight")
            if light then
                light.Brightness = practical * (if restored then 1.15 else 0.65)
            end
            return
        end
        object.Color = if restored then Theme.Amber else Theme.FadedTeal
        object.Material = if restored and self.effects ~= false
            then Enum.Material.Neon
            else Enum.Material.SmoothPlastic
        local light = object:FindFirstChildOfClass("PointLight")
        if light then
            light.Enabled = self.effects ~= false
            light.Brightness = if restored then 1.2 else 0.2
        end
    end
end

function View:setEffects(enabled)
    self.effects = enabled
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
    local wasOpen = self.panel.Visible
    self.panel.Visible = quay ~= nil
        and quay.open ~= nil
        and not state.station
        and not (state.concert and state.concert.open)
    if not quay then
        self.experiencePanel:update(state, self.tab, false)
        return
    end
    self.toggle.Text = if quay.progress.completed["NQ-Q12"]
        then "QUAY / OPEN NIGHT"
        else "QUAY / JOURNAL"
    if self.panel.Visible and (not wasOpen or self.lastOpen ~= quay.open) then
        if quay.open ~= "map" then
            local buildingId = type(quay.open) == "string"
                and quay.open:sub(1, 9) == "building:"
                and quay.open:sub(10)
            self.tab = if buildingId
                    and Activities.Buildings[buildingId]
                    and buildingId ~= "NQ-BLD-01"
                then "explore"
                else "route"
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
    local city = self.tab == "city"
    local route = self.tab == "route"
    for name, button in self.tabs do
        button.BackgroundColor3 = if name == self.tab then Theme.Ink else Theme.Teal
    end
    self.city.Visible, self.cityList.Visible = city, city
    self.actions.Visible, self.journal.Visible =
        route, route and quay.open == "map" and self.journalExpanded == true
    self.details.Visible = quay.open == "map"
    self.details.Text = if self.journalExpanded
        then "Hide chapter details"
        else "Show chapter details"
    self.experiencePanel:update(state, self.tab, self.panel.Visible)
    self.shopRoot.Visible = self.tab == "shop"
    self.shopPanel:update(state.experience and state.experience.commerce)
    self.help.Visible = route or city
    self.storyControls.Visible = route
    self.help.Text = if city
        then "RESONANCE CITY\nOnly Needle Quay is open in this demo. Genres remain freely selectable in the sampler."
        else instructions[quay.open] or instructions.map
    local open = quay.open
    local building = type(open) == "string" and open:sub(1, 9) == "building:"
    self.visit.Visible = building
    self.explore.Visible = open ~= "map"
    self.title.Text = if building
        then string.upper(buildingNames[open:sub(10)] or "NEEDLE QUAY")
        elseif open == "map" then "NEEDLE QUAY / JOURNAL"
        else "NEIGHBORHOOD ACTIVITY"
    if building and not city then
        local host = hosts[destination(open:sub(10))]
        self.help.Text = "Music starts with the people around you. Meet "
            .. host
            .. " to help the neighborhood and collect new sounds."
        self.visit.Text = "Meet " .. host
    end
    if route then
        local buildingId = building and open:sub(10)
        local sceneKey = if buildingId == "NQ-BLD-06" or buildingId == "NQ-BLD-07"
            then buildingId
            elseif building then destination(buildingId)
            else open
        local scene = Story.scene(sceneKey, quay.progress.completed)
        local chapter = Story.chapter(quay.progress.completed)
        if self.currentScene ~= scene then
            self.currentScene, self.storyPage, self.hintOpen = scene, 1, false
        end
        local page = self.storyPage or 1
        self.help.Text = (if scene then scene.speaker .. " / " .. scene.title else chapter.title)
            .. "\n\n"
            .. (scene and scene.lines[page] or chapter.summary)
            .. "\n\n"
            .. (scene and scene.prompt or chapter.nextStep)
            .. (
                if self.hintOpen then "\n\n" .. (instructions[sceneKey] or instructions.map) else ""
            )
        if quay.progress.completed["NQ-Q12"] and state.experience then
            self.help.Text ..= "\n\n" .. Story.dedication(state.experience.progress.dedication).closing
        end
        self.nextLine.Text = if scene and page < #scene.lines
            then "Next  " .. page .. "/" .. #scene.lines
            else "Read again"
        self.showHint.Text = if self.hintOpen then "Hide the steps" else "How do I do that?"
    end
    if self.tab == "explore" then
        self.title.Text = "AROUND NEEDLE QUAY"
    elseif self.tab == "style" then
        self.title.Text = "YOUR GROOVE + WARDROBE"
    elseif self.tab == "shop" then
        self.title.Text = "QUAYSIDE COSMETICS"
    end
    self.dedications.Visible = route
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
            "Repairs %d/3  ·  A/B variation %s",
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
    self.progress.Visible = route and self.progress.Text ~= ""
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
            and (open == "map" or open == stop.existing_parking_id)
    end
    self.save.Text = if state.saving
        then "Saving…"
        elseif state.saveMode == "session" then "Save journal / Studio session only"
        else "Save profile and journal"
    for _, quest in Catalog.quests do
        local milestone = Story.milestone(quest.id)
        self.rows[quest.id].Text = (
            if quay.progress.completed[quest.id] then "DONE  " else "TO DO  "
        )
            .. quest.name
            .. (if quest.optional_performance then " (optional)" else "")
            .. "\n"
            .. (
                if quay.progress.completed[quest.id] and milestone
                    then milestone.memory
                    else goals[quest.id] or quest.name
            )
    end
    local old, current = self.projected, quay.progress
    local changed = not old or old.repair ~= current.repair
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
    for _, connection in self.connections do
        connection:Disconnect()
    end
    self.experiencePanel:destroy()
    self.shopPanel:destroy()
    self.screen:Destroy()
end
return View
