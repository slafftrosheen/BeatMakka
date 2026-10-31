local Shared = game.ReplicatedStorage.Shared
local Progress = require(Shared.QuayProgress)
local Cosmetics = require(Shared.CosmeticCatalog)
local Story = require(Shared.QuayStory)
local Activities = require(Shared.QuayActivities)
local Samples = require(Shared.SampleCatalog)
local Conversations = require(Shared.QuayConversations)
local Rewards = require(Shared.QuayRewards)
local RewardPresentation = require(script.Parent.QuayRewardPresentation)
local Service = {}
local function buildingStop(id)
    return if id == "NQ-BLD-01"
        then "finale"
        elseif id == "NQ-BLD-03" or id == "NQ-BLD-09" then "P2"
        elseif id == "NQ-BLD-02" or id == "NQ-BLD-04" then "P3"
        elseif id == "NQ-BLD-05" or id == "NQ-BLD-12" then "P4"
        else "P1"
end
Service.__index = Service

function Service.new(
    world,
    profiles,
    rooms,
    send,
    release,
    nearby,
    persist,
    enterStation,
    enterConcert
)
    local self = setmetatable({
        world = world,
        scene = world.demo,
        profiles = profiles,
        rooms = rooms,
        send = function(player, notice, ...)
            send(player, Samples.localDiscoveryText(notice), ...)
        end,
        release = release,
        nearby = nearby,
        persist = persist,
        enterStation = enterStation,
        enterConcert = enterConcert,
        opened = {},
        pending = {},
        last = {},
        conversations = {},
    }, Service)
    if not world.demo then
        return self
    end
    self.commissions = require(script.Parent.QuayCommissionService).new(self)
    self.sideActivities = require(script.Parent.QuaySideActivities).new(self)
    self.life = require(script.Parent.QuayLifeService).new(self)
    self.celebrations = Instance.new("RemoteEvent")
    self.celebrations.Name = "QuayCelebration"
    self.celebrations.Parent = game.ReplicatedStorage.MusicNetwork
    self.celebrationSerial = 0
    self.waypoints = { finale = self.scene.finale.anchor.Position }
    for id, node in self.scene.stops do
        self.waypoints[id] = node.anchor.Position
    end
    for id, node in self.scene.actions do
        self.waypoints[id] = node.anchor.Position
    end
    for id, node in self.scene.stops do
        node.prompt.Triggered:Connect(function(player)
            self:interact(player, "stop", id)
        end)
    end
    for id, node in self.scene.actions do
        node.prompt.Triggered:Connect(function(player)
            self:interact(player, "target", id)
        end)
    end
    for id, node in self.scene.encounters do
        node.prompt.Triggered:Connect(function(player)
            self:encounter(player, id)
        end)
    end
    self.scene.finale.prompt.Triggered:Connect(function(player)
        self:interact(player, "finale")
    end)
    for _, van in self.scene.vans do
        van.door.prompt.Triggered:Connect(function(player)
            if
                van.model:GetAttribute("OwnerUserId") == player.UserId
                and self.nearby(player, van.door.anchor, 13)
            then
                self:command(player, "QuayEnter")
            else
                self.send(player, "This Roamer belongs to another musician. Use your own studio.")
            end
        end)
    end
    for _, node in { self.scene.exit, self.scene.courtExit } do
        node.prompt.Triggered:Connect(function(player)
            if self.nearby(player, node.anchor, 13) then
                self:command(player, "QuayReturn")
            end
        end)
    end
    for id, node in self.scene.buildings do
        do
            node.anchor:SetAttribute("QuayInteraction", "building:" .. id)
            node.prompt.Triggered:Connect(function(player)
                if not self.nearby(player, node.anchor, 13) then
                    return
                end
                self.opened[player] = "building:" .. id
                self.send(
                    player,
                    if Activities.Buildings[id]
                        then "There is a story or activity here. Open Explore in your journal."
                        else "Meet this place's neighbour to hear its story."
                )
            end)
        end
    end
    return self
end

function Service:van(player)
    local id = self.rooms.byPlayer[player]
    local index = if id == "Room_1" then 1 elseif id == "Room_2" then 2 else nil
    return index and self.scene.vans[index]
end

function Service:arrive(player, profile, welcome)
    if not self.scene then
        return
    end
    profile.companionRoute = "quay"
    profile.companionStop = profile.quay.parking
    if welcome then
        self.opened[player] = if profile.quay.completed["NQ-Q00"] then nil else "map"
    end
    self:updateVan(player, profile)
    task.spawn(function()
        local character = player.Character or player.CharacterAdded:Wait()
        local root = character:WaitForChild("HumanoidRootPart", 10)
        if not root or self.profiles[player] ~= profile or player.Character ~= character then
            return
        end
        local van = self:van(player)
        local parking = self.scene.stops[profile.quay.parking]
        character:PivotTo(
            CFrame.new(
                parking.position + Vector3.new(if van then (van.index - 1) * 32 else 0, 0, 0)
            )
        )
        self.send(
            player,
            if welcome
                then "The Lantern Room's old card says: Bring a sound. Leave a little room. Meet Tori, or enter your Roamer to make music."
                else "Back at your parked Roamer. Your music is still here."
        )
    end)
end

function Service:updateVan(player, profile)
    RewardPresentation.player(player, profile)
    local van = self:van(player)
    if not van then
        return
    end
    local parking = if self.scene.stops[profile.quay.parking] then profile.quay.parking else "P1"
    local finish = profile.room.finish
    if van.owner ~= player or van.displayName ~= player.DisplayName then
        van.owner, van.displayName = player, player.DisplayName
        van.model:SetAttribute("OwnerUserId", player.UserId)
        van.door.anchor.QuaySign.TextLabel.Text = "THE ROAMER / " .. player.DisplayName
    end
    if van.parking ~= parking then
        van.parking = parking
        local destination = self.scene.stops[parking].center
            + Vector3.new(-1.5 + (van.index - 1) * 32, 5.5, 0)
        van.model:PivotTo(CFrame.new(destination))
        van.spawn.CFrame = CFrame.new(
            self.scene.stops[parking].position + Vector3.new((van.index - 1) * 32, -2.9, 0)
        )
    end
    RewardPresentation.roamer(van, profile)
    van.spawn.Enabled = true
    player.RespawnLocation = van.spawn
    if van.finish ~= finish and Cosmetics.Sets[finish] then
        van.finish = finish
        for _, item in van.model:GetDescendants() do
            if item:IsA("BasePart") and item:GetAttribute("VanTint") then
                item.Color = Cosmetics.Sets[finish].primary
            end
        end
    end
end

function Service:summary(player, profile)
    if not self.scene then
        return nil
    end
    self:updateVan(player, profile)
    local van = self:van(player)
    local nearVan = van ~= nil and self.nearby(player, van.door.anchor, 24)
    local canTravel = nearVan
    for _, stop in self.scene.stops do
        canTravel = canTravel or self.nearby(player, stop.anchor, 35)
    end
    local open = self.opened[player]
    local host = if open and open:sub(1, 10) == "encounter:" then open:sub(11) else open
    local conversation = self.conversations[player]
    local waypoints = table.clone(self.waypoints)
    for id, node in self.life.nodes do
        waypoints["life_" .. id] = node.Position
    end
    local streetSet = workspace:FindFirstChild("QuayStreetBusking")
    if streetSet then
        waypoints.activity_busk = streetSet.Position
    end
    for id, node in self.sideActivities.nodes do
        waypoints["activity_" .. id] = node.Position
    end
    if van then
        waypoints.enter = van.door.anchor.Position
    end
    return {
        collected = { metal = profile.unlocked.I01 == true, reply = profile.unlocked.I03 == true },
        life = require(Shared.QuayLifeCatalog).summary(profile.quay),
        rewards = Rewards.sanitize(profile.rewards, profile.quay),
        sideActivity = self.sideActivities:summary(player),
        commission = self.commissions:summary(player, profile),
        canTravel = van ~= nil and canTravel,
        progress = Progress.sanitize(profile.quay),
        open = self.opened[player],
        ownsVan = van ~= nil,
        nearVan = nearVan,
        canReturn = self.nearby(player, self.scene.exit.anchor, 45)
            or self.nearby(player, self.scene.courtExit.anchor, 40),
        evidence = Progress.evidence(profile),
        finaleReady = Progress.readyForFinale(profile),
        chapterComplete = profile.chapter.completed,
        dialogue = Conversations.project(
            profile,
            host,
            if conversation and conversation.host == host then conversation.choice else nil
        ),
        waypoints = waypoints,
    }
end

function Service:encounter(player, id)
    local profile, node = self.profiles[player], self.scene.encounters[id]
    if not profile or not profile.ready or not node or not self.nearby(player, node.anchor, 13) then
        return
    end
    local now = os.clock()
    if now - (self.last[player] or 0) < 0.25 then
        return
    end
    self.last[player] = now
    self.opened[player] = "encounter:" .. id
    self.conversations[player] = nil
    profile.companionRoute, profile.companionStop = "quay", if id == "sana" then "P3" else "P1"
    self.send(player)
end

function Service:changed(player, profile)
    profile.editVersion += 1
    self.pending[player] = os.clock() + 2
end
function Service:celebrate(player, id, first)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        return
    end
    self.celebrationSerial += 1
    self.celebrations:FireAllClients({
        serial = self.celebrationSerial,
        userId = player.UserId,
        position = root.Position,
        id = id,
        first = first == true,
    })
end

function Service:award(player, profile, id)
    if profile.quay.completed[id] then
        return false
    end
    profile.quay.completed[id] = true
    self:changed(player, profile)
    self:celebrate(player, id, true)
    return true
end

function Service:teleport(player, at)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid or humanoid.Health <= 0 then
        return false
    end
    self.release(player)
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    character:PivotTo(CFrame.new(at))
    return true
end

function Service:returnToRoamer(player, profile)
    local van = self:van(player)
    local stop = self.scene.stops[profile.quay.parking] or self.scene.stops.P1
    local at = stop.position + Vector3.new(if van then (van.index - 1) * 32 else 0, 0, 0)
    if self:teleport(player, at) then
        self.opened[player] = nil
        profile.companionRoute, profile.companionStop = "quay", profile.quay.parking
        self.send(player, "Back beside your Roamer.")
        return true
    end
    return false
end

function Service:interact(player, kind, id)
    local profile = self.profiles[player]
    if not profile or not profile.ready or not self.scene then
        return
    end
    local now = os.clock()
    if now - (self.last[player] or 0) < 0.25 then
        return
    end
    self.last[player] = now
    local node = if kind == "stop"
        then self.scene.stops[id]
        elseif kind == "target" then self.scene.actions[id]
        else self.scene.finale
    if not node or not self.nearby(player, node.anchor, 13) then
        return
    end
    profile.companionRoute = "quay"
    profile.companionStop = if kind == "stop"
        then id
        elseif kind == "finale" then "finale"
        elseif id:sub(1, 4) == "dock" then "P1"
        elseif id:sub(1, 6) == "repair" then "P2"
        elseif id:sub(1, 6) == "market" then "P3"
        else "P4"
    local q = profile.quay
    local message
    if kind == "stop" then
        self.opened[player] = id
        self.conversations[player] = nil
        if id == "P1" then
            self:award(player, profile, "NQ-Q00")
            if not profile.quest.accepted then
                profile.quest.accepted = true
                self:changed(player, profile)
            end
            if not profile.unlocked.I01 then
                profile.unlocked.I01 = true
                self:changed(player, profile)
            end
            message = if q.completed["NQ-Q02"]
                then "Tori: That is our loading rail in your rhythm. Ivo could use a visit next."
                else "Tori: Stow the three dock crates, then use Quay metal at four different rhythmic positions in a named sequence. Give it a name so you can find it again."
        elseif id == "P2" then
            message = if q.completed["NQ-Q05"]
                then "Ivo: You kept both ideas. Maybe I can bring this lamp without polishing it forever. Naya is at the market."
                else "Ivo: Isolate power, clear the intake, then restore power. Keep your first sequence, make a musical variation and save it with another name. Both ideas can belong in your song."
        elseif id == "P3" then
            message = if q.completed["NQ-Q07"]
                then "Naya: That blank sleeve is waiting for your next song. Sana is making room for our evening."
                else "Naya: Listen to these records. A sequence is a section you can repeat. A song arranges sections from beginning to end. Put a saved sequence in Song Mode and Save Draft; finishing can wait."
        else
            if not profile.unlocked.I03 then
                profile.unlocked.I03 = true
                self:changed(player, profile)
            end
            message = if q.completed["NQ-Q10"]
                then "Mica: The invitation is out. Nobody has to perform to belong. Ronan is waiting at the Lantern Room."
                else "Mica: Select a teaching bar in your sequence. Put Helper chirp on its four quarter notes: ticks 0, 960, 1920 and 2880 within that bar. Then bring the reply back."
        end
    elseif kind == "target" then
        local index = tonumber(id:sub(-1))
        if id:sub(1, 4) == "dock" then
            if not q.dock[index] then
                q.dock[index] = true
                self:changed(player, profile)
            end
            if q.dock[1] and q.dock[2] and q.dock[3] then
                self:award(player, profile, "NQ-Q01")
            end
            message = "Dock crate safely stowed for your route."
        elseif id:sub(1, 6) == "repair" then
            if index == q.repair + 1 then
                q.repair = index
                self:changed(player, profile)
                if index == 3 then
                    self:award(player, profile, "NQ-Q04")
                    profile.unlocked.I02 = true
                end
                message = if index == 3
                    then "Vent restored. Vent thump is in your virtual sound collection."
                    else "Repair step complete. Follow the next numbered control."
            else
                message =
                    "Ivo: follow the safe order: 1 isolate, 2 clear, 3 restore. Completed steps stay done."
            end
        elseif id:sub(1, 6) == "market" then
            if not q.market[index] then
                q.market[index] = true
                self:changed(player, profile)
            end
            if q.market[1] and q.market[2] and q.market[3] then
                self:award(player, profile, "NQ-Q08")
            end
            message =
                "Sana: case stored. The stalls stay in place; we are making room for music together."
        elseif id == "radio" then
            if q.completed["NQ-Q09"] then
                self:award(player, profile, "NQ-Q10")
                message =
                    "Mica: your signal is reaching the breakwater. Visit Ronan at The Lantern Room."
            else
                message =
                    "Check your four-note Helper chirp answer with Mica before switching on the signal."
            end
        end
    else
        self.opened[player] = "finale"
        self.conversations[player] = nil
        local ready = true
        for _, n in { 0, 1, 2, 4, 5, 6, 7, 8, 9, 10 } do
            ready = ready and q.completed[string.format("NQ-Q%02d", n)] == true
        end
        if ready and Progress.evidence(profile).finished then
            self:award(player, profile, "NQ-Q11")
            message =
                "Ronan: Choose the song you finished for this evening. We will hear that saved revision from its beginning to the last sound. A small gathering is enough."
        else
            message = if ready
                then "Ronan: Finish and save your own song, then select its saved revision. Use two different sequence sections and layer a collected sound with another part. Audio pending approval cannot make the room ready."
                else "Ronan: Your journal shows the neighbourhood steps still to do. Optional loop sharing never needs an audience."
        end
    end
    self.send(player, message)
end

function Service:command(player, action, value)
    if not self.scene then
        return
    end
    local profile = self.profiles[player]
    if not profile or not profile.ready then
        return
    end
    if action:sub(1, 14) == "QuayCommission" then
        self.commissions:command(player, profile, action, value)
        return
    end
    if action == "QuayEquipReward" then
        if
            type(value) ~= "table"
            or type(value.category) ~= "string"
            or type(value.id) ~= "string"
        then
            return
        end
        if not Rewards.Items[value.category] then
            return
        end
        if
            value.id ~= "none"
            and not Rewards.earned(profile.quay, Rewards.find(value.category, value.id))
        then
            return
        end
        if os.clock() - (self.last[player] or 0) < 0.25 then
            return
        end
        self.last[player] = os.clock()
        profile.rewards = Rewards.sanitize(profile.rewards, profile.quay)
        if profile.rewards[value.category] == value.id then
            return
        end
        profile.rewards[value.category] = value.id
        self:changed(player, profile)
        self.send(player)
        return
    end
    if action:sub(1, 8) == "QuaySide" then
        self.sideActivities:command(player, action, value)
        return
    end
    local q = profile.quay
    if action == "QuayTeachingBar" then
        local project = profile.music and profile.music.project
        local sequence = project and project.sequences[profile.sequenceId]
        if
            not sequence
            or type(value) ~= "number"
            or value % 1 ~= 0
            or value < 1
            or value > sequence.bars
        then
            return
        end
        profile.teachingBar = value
        self:changed(player, profile)
        self.send(player, "Mica will check bar " .. value .. " of your selected sequence.")
        return
    end
    local van = self:van(player)
    if action == "QuayInteract" then
        if type(value) ~= "string" or #value > 32 then
            return
        end
        if value:sub(1, 5) == "life:" then
            self.life:interact(player, value:sub(6))
        elseif value:sub(1, 10) == "encounter:" then
            self:encounter(player, value:sub(11))
        elseif value:sub(1, 9) == "building:" then
            local node = self.scene.buildings[value:sub(10)]
            if node and self.nearby(player, node.anchor, 13) then
                profile.companionRoute = "quay"
                self.opened[player] = value
                self.send(player, "This place has a neighborhood activity. Meet its host to begin.")
            end
        elseif self.scene.stops[value] then
            self:interact(player, "stop", value)
        elseif self.scene.actions[value] then
            self:interact(player, "target", value)
        elseif value == "finale" then
            self:interact(player, "finale")
        end
        return
    end
    local atVan = van and self.nearby(player, van.door.anchor, 24)
    if action == "QuayVisit" then
        local opened = self.opened[player]
        if opened == "encounter:sana" then
            local node = self.scene.encounters.sana
            if
                self.nearby(player, node.anchor, 15)
                and self:teleport(
                    player,
                    self.scene.stops.P3.anchor.Position + Vector3.new(0, 2, -5)
                )
            then
                self.last[player] = nil
                self:interact(player, "stop", "P3")
            end
            return
        end
        if type(opened) ~= "string" or opened:sub(1, 9) ~= "building:" then
            return
        end
        local id = opened:sub(10)
        local building = self.scene.buildings[id]
        if not building or not self.nearby(player, building.anchor, 15) then
            return
        end
        local encounter = if id == "NQ-BLD-06"
            then "cafe"
            elseif id == "NQ-BLD-04" then "sana"
            else nil
        if encounter then
            local node = self.scene.encounters[encounter]
            if self:teleport(player, node.anchor.Position + Vector3.new(0, 1, -4)) then
                self.last[player] = nil
                self:encounter(player, encounter)
            end
            return
        end
        local stopId = buildingStop(id)
        local stop = if stopId == "finale" then self.scene.finale else self.scene.stops[stopId]
        if self:teleport(player, stop.anchor.Position + Vector3.new(0, 2, -5)) then
            self.last[player] = nil
            self:interact(player, if stopId == "finale" then "finale" else "stop", stopId)
        end
        return
    end
    if action == "QuayClose" then
        self.opened[player] = nil
        self.conversations[player] = nil
        self.send(player)
        return
    end
    if action == "QuayJournal" then
        self.opened[player] = "map"
        self.send(player)
        return
    end
    if action == "QuayTalk" then
        if not Conversations.valid(value) then
            return
        end
        local opened = self.opened[player]
        local host = if opened and opened:sub(1, 10) == "encounter:" then opened:sub(11) else opened
        local node = self.scene.encounters[host]
            or self.scene.stops[host]
            or (host == "finale" and self.scene.finale)
        if not node or not self.nearby(player, node.anchor, 15) then
            return
        end
        local now = os.clock()
        if now - (self.last[player] or 0) < 0.25 then
            return
        end
        self.last[player] = now
        self.conversations[player] = { host = host, choice = value }
        self.send(player)
        return
    end
    if action == "QuaySave" then
        if os.clock() - (profile.lastSave or -math.huge) >= 5 then
            profile.lastSave = os.clock()
            self.persist(player, profile)
        end
        return
    end
    if action == "QuayPark" then
        if type(value) ~= "string" or not self.scene.stops[value] then
            return
        end
        local atStop = false
        for _, node in self.scene.stops do
            atStop = atStop or self.nearby(player, node.anchor, 35)
        end
        if not van or not (atVan or atStop) then
            self.send(player, "Visit your Roamer or a marked parking station to travel.")
            return
        end
        if
            self:teleport(
                player,
                self.scene.stops[value].position + Vector3.new((van.index - 1) * 32, 0, 0)
            )
        then
            q.parking = value
            profile.companionRoute, profile.companionStop = "quay", value
            self:changed(player, profile)
            self:updateVan(player, profile)
            self.opened[player] = nil
            self.send(
                player,
                "Parked safely. Your sequences, song drafts and saved songs are still here."
            )
        end
        return
    end
    if action == "QuayEnter" then
        if not atVan then
            self.send(player, "Walk to your Roamer's studio door first.")
            return
        end
        local bay = self.rooms.bays[self.rooms.byPlayer[player]]
        if not bay then
            return
        end
        local station = self.world.stations[bay.stationId]
        if station.owner and station.owner ~= player then
            self.send(player, "Your studio workbench is in use. Please wait.")
            return
        end
        if self:teleport(player, station.anchor.Position + Vector3.new(0, 0, -6)) then
            self:award(player, profile, "NQ-Q00")
            self.opened[player] = nil
            profile.companionRoute = "quay"
            self.enterStation(player, bay.stationId)
        end
        return
    end
    if action == "QuayReturn" then
        local atInterior = self.nearby(player, self.scene.exit.anchor, 45)
            or self.nearby(player, self.scene.courtExit.anchor, 40)
        if not atInterior then
            self.send(player, "Use the studio or concert exit to return.")
            return
        end
        local dest = self.scene.stops[q.parking].position
            + Vector3.new(if van then (van.index - 1) * 32 else 0, 0, 0)
        if self:teleport(player, dest) then
            self.opened[player] = nil
            profile.companionRoute, profile.companionStop = "quay", q.parking
            self.send(player, "Back at Needle Quay.")
        end
        return
    end
    if action == "QuayFinale" then
        if
            not self.nearby(player, self.scene.finale.anchor, 15)
            or not Progress.readyForFinale(profile)
        then
            self.send(
                player,
                "Meet Ronan at The Lantern Room after completing your neighborhood journal."
            )
            return
        end
        if self:teleport(player, self.world.concert.anchor.Position + Vector3.new(0, 0, -5)) then
            self.opened[player] = nil
            self.enterConcert(player)
        end
        return
    end
    local id = self.opened[player]
    local node = id and self.scene.stops[id]
    if not node or not self.nearby(player, node.anchor, 15) then
        self.send(player, "Return to the marked activity station.")
        return
    end
    if action == "QuayListen" and id == "P3" and q.sort < 3 then
        if os.clock() - (self.last[player] or 0) < 0.3 then
            return
        end
        self.last[player] = os.clock()
        local sample = Samples.sampleForRole(
            ({ "preview_kick", "preview_closed_hat", "preview_pluck" })[q.sort + 1]
        )
        self.send(
            player,
            if sample
                then "Naya: A pulse anchors the beat, texture adds detail, and a tune carries pitch."
                else "Naya: This record's audio is unavailable. Your earlier matches stay done; we can listen when it arrives.",
            sample
        )
    elseif action == "QuaySort" and id == "P3" then
        local answers = { "pulse", "texture", "tune" }
        if
            q.sort < 3
            and not Samples.sampleForRole(
                ({ "preview_kick", "preview_closed_hat", "preview_pluck" })[q.sort + 1]
            )
        then
            self.send(
                player,
                "This listening lesson needs available audio. Existing record matches are preserved."
            )
            return
        end
        if q.sort < 3 and value == answers[q.sort + 1] then
            q.sort += 1
            self:changed(player, profile)
            if q.sort == 3 then
                self:award(player, profile, "NQ-Q06")
            end
            self.send(
                player,
                "Naya: that tag fits. Keep your own musical style; this just organizes the record shelf."
            )
        else
            self.send(
                player,
                "Try again: kick / PULSE, hat / TEXTURE, melody / TUNE. Your earlier matches stay done."
            )
        end
    elseif action == "QuayOptional" and id == "P1" then
        self:award(player, profile, "NQ-Q03")
        self.send(
            player,
            "Invitation noted. Public performance is optional and never blocks your route."
        )
    elseif action == "QuayCheck" then
        local evidence = Progress.evidence(profile)
        local success = false
        local taskId = ({ P1 = "NQ-Q02", P2 = "NQ-Q05", P3 = "NQ-Q07", P4 = "NQ-Q09" })[id]
        if taskId and q.completed[taskId] then
            self.send(
                player,
                "This part is already ready. Keep exploring, or make another version of your music whenever you like."
            )
            return
        end
        if id == "P1" and evidence.metal then
            success = self:award(player, profile, "NQ-Q02")
        elseif id == "P2" and evidence.variation and q.completed["NQ-Q04"] then
            success = self:award(player, profile, "NQ-Q05")
        elseif id == "P3" and evidence.draft then
            success = self:award(player, profile, "NQ-Q07")
        elseif id == "P4" and evidence.reply then
            success = self:award(player, profile, "NQ-Q09")
        end
        local message
        if success then
            message = ({
                P1 = "Tori: There it is, our loading rail in your own rhythm. Give this sequence a name so you can find it again.",
                P2 = "Ivo: Two different sequences, both safely kept. I am bringing the lamp as it is. Go see what Naya has kept.",
                P3 = "Naya: Your Song Mode draft starts the next story. The blank sleeve is waiting for the song you will make; you can finish it later.",
                P4 = "Mica: I heard your reply. The signal console is ready now.",
            })[id]
        elseif id == "P1" then
            message = if not profile.unlocked.I01
                then "Meet Tori first to collect the quay's metal sound."
                else string.format(
                    "Quay metal is at %d of 4 distinct rhythmic positions in your fullest ready sequence. Use its available local kit pad; repeated hits at one position count once.",
                    evidence.metalSteps
                )
        elseif id == "P2" then
            message = if not q.completed["NQ-Q04"]
                then "Finish Ivo's three numbered repair controls first. Completed controls stay done."
                elseif
                    not evidence.saved
                then "Save Sequence for your original and wait for its saved confirmation. Pending audio cannot count as a playable sequence yet."
                else "Save a second named sequence with a musical difference you can hear. Renaming or editing an unused pad does not count as variation."
        elseif id == "P3" then
            message =
                "Add an owned saved sequence to Song Mode, then Save Draft and wait for confirmation. You can finish the song later."
        else
            message =
                "Select your teaching bar and place ready Helper chirp notes at ticks 0, 960, 1920 and 2880 within that bar. Extra chirps in that bar do not match; other bars and instruments are your choice."
        end
        self.send(player, message)
    end
end

function Service:tick()
    if not self.scene then
        return
    end
    self.life:tick()
    for player, profile in self.profiles do
        if profile.ready then
            if
                profile.chapter.completed
                and profile.chapter.performance
                and profile.quay.completed["NQ-Q11"]
            then
                if self:award(player, profile, "NQ-Q12") then
                    self.opened[player] = "map"
                    self.send(
                        player,
                        "Ronan: "
                            .. Story.dedication(
                                profile.experience and profile.experience.dedication
                            ).closing
                            .. " Nell has put out one extra cup."
                    )
                end
            end
            local due = self.pending[player]
            if due and os.clock() >= due and not profile.saving then
                self.pending[player] = nil
                self.persist(player, profile)
            end
        end
    end
end

function Service:remove(player)
    if self.life then
        self.life:remove(player)
    end
    if self.commissions then
        self.commissions:remove(player)
    end
    if self.sideActivities then
        self.sideActivities:remove(player)
    end
    if self.scene then
        local van = self:van(player)
        if van then
            van.model:SetAttribute("OwnerUserId", nil)
            van.spawn.Enabled = false
            player.RespawnLocation = nil
            van.door.anchor.QuaySign.TextLabel.Text = "THE ROAMER / AVAILABLE"
            van.parking = nil
            van.rewardLook = nil
            local lights = van.model:FindFirstChild("RewardLights")
            if lights then
                lights:Destroy()
            end
        end
    end
    self.opened[player], self.pending[player], self.last[player], self.conversations[player] =
        nil, nil, nil, nil
end

function Service:flush(player)
    local profile = self.profiles[player]
    if not profile or not self.pending[player] then
        return
    end
    self.pending[player] = nil
    if profile.saving then
        profile.progressNeedsSave = true
    else
        self.persist(player, profile)
    end
end
return Service
