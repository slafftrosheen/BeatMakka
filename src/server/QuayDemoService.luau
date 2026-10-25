local Shared = game.ReplicatedStorage.Shared
local Progress = require(Shared.QuayProgress)
local Cosmetics = require(Shared.CosmeticCatalog)
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
        send = send,
        release = release,
        nearby = nearby,
        persist = persist,
        enterStation = enterStation,
        enterConcert = enterConcert,
        opened = {},
        pending = {},
        last = {},
    }, Service)
    if not world.demo then
        return self
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
                    "Find the marked activity station on the promenade. Scenic buildings have exterior activities."
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
    if welcome then
        self.opened[player] = nil
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
                then "Welcome to Needle Quay. Meet Tori at Dockside Exchange, or enter your Roamer to make music immediately."
                else "Back at your parked Roamer. Your music is still here."
        )
    end)
end

function Service:updateVan(player, profile)
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
    return {
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
    }
end

function Service:changed(player, profile)
    profile.editVersion += 1
    self.pending[player] = os.clock() + 2
end

function Service:award(player, profile, id)
    if profile.quay.completed[id] then
        return false
    end
    profile.quay.completed[id] = true
    self:changed(player, profile)
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
    local q = profile.quay
    local message
    if kind == "stop" then
        self.opened[player] = id
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
            message =
                "Tori: stow the three dock crates, then make four metal-hit steps in your Roamer. This is a preauthored virtual sound."
        elseif id == "P2" then
            message =
                "Ivo: isolate power, clear the intake, then restore power. Save different A and B patterns to your shelf."
        elseif id == "P3" then
            message =
                "Naya: listen to each record and tell me its musical role. Sana can help make room for our market stage."
        else
            if not profile.unlocked.I03 then
                profile.unlocked.I03 = true
                self:changed(player, profile)
            end
            message =
                "Mica: put Helper chirp on steps 1, 5, 9 and 13. Return here to check your answer and restore the signal. Preauthored sound; no microphone."
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
        local ready = true
        for _, n in { 0, 1, 2, 4, 5, 6, 7, 8, 9, 10 } do
            ready = ready and q.completed[string.format("NQ-Q%02d", n)] == true
        end
        if ready then
            self:award(player, profile, "NQ-Q11")
            message =
                "Ronan: the stage is ready. Bring a saved beat with two audible parts, an A/B variation and a collected sound. Enter for your six-part set."
        else
            message =
                "Ronan: finish the four neighborhood activities first. The journal shows what remains; a public performance is optional."
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
    local q = profile.quay
    local van = self:van(player)
    if action == "QuayInteract" then
        if type(value) ~= "string" or #value > 32 then
            return
        end
        if value:sub(1, 9) == "building:" then
            local node = self.scene.buildings[value:sub(10)]
            if node and self.nearby(player, node.anchor, 13) then
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
        if type(opened) ~= "string" or opened:sub(1, 9) ~= "building:" then
            return
        end
        local id = opened:sub(10)
        local building = self.scene.buildings[id]
        if not building or not self.nearby(player, building.anchor, 15) then
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
        self.send(player)
        return
    end
    if action == "QuayJournal" then
        self.opened[player] = "map"
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
            self:changed(player, profile)
            self:updateVan(player, profile)
            self.opened[player] = nil
            self.send(player, "Parked safely. Your patterns and Beat Shelf are unchanged.")
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
        self.send(
            player,
            "Naya: a pulse anchors the beat, texture adds detail, and a tune carries pitch.",
            ({ "kick", "closed_hat", "pluck" })[q.sort + 1]
        )
    elseif action == "QuaySort" and id == "P3" then
        local answers = { "pulse", "texture", "tune" }
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
        if id == "P1" and evidence.metal then
            success = self:award(player, profile, "NQ-Q02")
        elseif id == "P2" and evidence.variation and q.completed["NQ-Q04"] then
            success = self:award(player, profile, "NQ-Q05")
        elseif id == "P3" and evidence.saved then
            success = self:award(player, profile, "NQ-Q07")
        elseif id == "P4" and evidence.reply then
            success = self:award(player, profile, "NQ-Q09")
        end
        self.send(
            player,
            if success
                then "Your music meets this activity's steps. Progress recorded."
                else "No new completion yet. Check the journal instructions and save your shelf before returning."
        )
    end
end

function Service:tick()
    if not self.scene then
        return
    end
    for player, profile in self.profiles do
        if profile.ready then
            if profile.chapter.completed and profile.quay.completed["NQ-Q11"] then
                if self:award(player, profile, "NQ-Q12") then
                    self.send(player, "Needle Quay plays again. Your district is restored.")
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
    if self.scene then
        local van = self:van(player)
        if van then
            van.model:SetAttribute("OwnerUserId", nil)
            van.spawn.Enabled = false
            player.RespawnLocation = nil
            van.door.anchor.QuaySign.TextLabel.Text = "THE ROAMER / AVAILABLE"
            van.parking = nil
        end
    end
    self.opened[player], self.pending[player], self.last[player] = nil, nil, nil
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
