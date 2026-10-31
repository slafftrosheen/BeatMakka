local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Cosmetics = require(ReplicatedStorage.Shared.CosmeticCatalog)
local WorkspaceModel = require(script.Parent.MusicWorkspace)
local Quest = require(ReplicatedStorage.Shared.FirstPerformanceQuest)
local Profiles = require(script.Parent.ProfileStore)
local ListeningSession = require(script.Parent.ListeningSession)
local RoomService = require(script.Parent.RoomService)
local Missions = require(ReplicatedStorage.Shared.NeighborhoodMissions)
local Discoveries = require(ReplicatedStorage.Shared.DiscoveryCatalog)
local Catalog = require(ReplicatedStorage.Shared.SampleCatalog)
local ConcertService = require(script.Parent.ConcertService)
local JamService = require(script.Parent.JamService)
local QuayDemoService = require(script.Parent.QuayDemoService)
local CompanionService = require(script.Parent.CompanionService)
local QuayExperienceService = require(script.Parent.QuayExperienceService)
local CommerceService = require(script.Parent.CommerceService)
local WardrobeService = require(script.Parent.WardrobeService)
local MusicService = {}

function MusicService.start(world)
    local network = Instance.new("Folder")
    network.Name = "MusicNetwork"
    local command = Instance.new("RemoteEvent")
    command.Name = "Command"
    command.Parent = network
    local state = Instance.new("RemoteEvent")
    state.Name = "State"
    state.Parent = network
    local delta = Instance.new("RemoteEvent")
    delta.Name = "Delta"
    delta.Parent = network
    network.Parent = ReplicatedStorage
    local profiles = {}
    local liveMusic = require(script.Parent.QuayLiveMusic).new()
    local listening
    local concert
    local jam
    local quay
    local companions
    local experience
    local commerce
    local wardrobe

    local function nearby(player, anchor, distance)
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        return root ~= nil
            and humanoid ~= nil
            and humanoid.Health > 0
            and (root.Position - anchor.Position).Magnitude <= distance
            and (
                (
                    not anchor:GetAttribute("QuayInteraction")
                    and not anchor:GetAttribute("StreetActivity")
                )
                or require(ReplicatedStorage.Shared.QuayOcclusion).visible(
                    (character:FindFirstChild("Head") or root).Position,
                    anchor,
                    character,
                    profiles[player] and profiles[player].quay
                )
            )
    end

    local rooms = RoomService.new(world.rooms, nearby)

    local function send(player, notice, preview, cue)
        local profile = profiles[player]
        if profile == nil or player.Parent == nil then
            return
        end
        WorkspaceModel.sync(profile)
        if experience and profile.ready then
            experience:reconcile(player, profile)
        end
        liveMusic:update(player, profile, quay and quay:van(player))
        rooms:update(player, profile)
        local count = 0
        for _, id in { "I01", "I02", "I03" } do
            count += if profile.unlocked[id] then 1 else 0
        end
        local station = world.stations[profile.station]
        if station and station.owner == player then
            station.screen.Text = string.format(
                "%s\n%d BPM",
                if profile.recording
                    then "RECORDING"
                    elseif profile.playing then "PLAYING"
                    else "READY",
                profile.pattern.bpm
            )
        end
        state:FireClient(player, {
            ready = profile.ready,
            pattern = profile.pattern,
            music = WorkspaceModel.projection(profile),
            quest = Quest.summary(profile),
            unlocked = profile.unlocked,
            station = profile.station,
            playing = profile.playing,
            broadcast = profile.broadcast == true,
            recording = profile.recording,
            startedAt = profile.startedAt,
            epoch = profile.epoch,
            saveMode = profile.saveMode,
            saving = profile.saving,
            hasSave = profile.saved ~= nil,
            finish = profile.finish,
            room = rooms:summary(player, profile),
            neighborhood = Missions.summary(profile),
            dirty = profile.editVersion ~= profile.savedEditVersion,
            editVersion = profile.editVersion,
            restoration = if count == 3 and next(profile.music.project.sequences) ~= nil
                then 4
                else count,
            notice = Catalog.localDiscoveryText(notice),
            preview = preview,
            cue = cue,
            listening = listening and listening:state(player),
            stage = listening and listening:stageState(player),
            concert = concert and concert:state(player),
            jam = jam and jam:state(player),
            quay = quay and quay:summary(player, profile),
            companion = companions and companions:summary(player, profile),
            experience = experience and profile.ready and experience:summary(player, profile)
                or nil,
        })
    end

    local function release(player, notice)
        local profile = profiles[player]
        if not profile then
            return
        end
        local station = world.stations[profile.station]
        if jam then
            jam:leave(player)
        end
        if concert then
            concert:stop(player)
        end
        if station and station.owner == player then
            station.owner = nil
            station.label.Text = "MK-I  /  READY"
            station.prompt.ActionText = "Make music"
            station.screen.Text = "MK-I\nREADY"
        end
        profile.station = nil
        WorkspaceModel.stop(profile, true)
        send(player, notice)
    end

    local drainQuestSave
    local function persist(player, profile, successNotice, musicOverride, accepted)
        if profile.saving then
            return false
        end
        profile.saving = true
        send(player, "Saving...")
        task.spawn(function()
            -- ProfileStore owns the flag across its yielding storage operation.
            profile.saving = false
            local ok, result = Profiles.save(player, profile, nil, musicOverride)
            if accepted then
                accepted(ok)
            end
            WorkspaceModel.sync(profile)
            if ok and profile.editVersion ~= profile.savedEditVersion then
                result = "Snapshot saved. Your newer edits are not saved yet."
            elseif ok and successNotice then
                result = successNotice
            elseif not ok then
                result = "Current work is temporary. " .. result
            end
            send(player, result, nil, if ok then "ui_save" else "ui_error")
            drainQuestSave(player, profile)
        end)
        return true
    end

    drainQuestSave = function(player, profile)
        if not profile.progressNeedsSave or profile.saving then
            return
        end
        profile.progressNeedsSave = false
        persist(
            player,
            profile,
            if profile.saveMode == "session"
                then "Music and progress saved for this Studio session only."
                else "Your music and progress are saved."
        )
    end

    listening = ListeningSession.new(world.listening, profiles, send, release, nearby, {
        eligible = function(player, pattern)
            local profile = profiles[player]
            return profile ~= nil and Quest.canPerform(profile, pattern)
        end,
        performed = function(player, pattern)
            local profile = profiles[player]
            if not profile or not Quest.canPerform(profile, pattern) then
                return
            end
            profile.quest.completed = true
            profile.editVersion += 1
            profile.progressNeedsSave = true
            send(
                player,
                "Mica: That's our quay! Your first courtyard set is complete.",
                nil,
                "ui_collect"
            )
            drainQuestSave(player, profile)
        end,
    })

    concert = ConcertService.new(
        world.concert,
        profiles,
        send,
        function(player)
            listening:depart(player)
            release(player)
        end,
        nearby,
        function(player, profile)
            profile.progressNeedsSave = true
            drainQuestSave(player, profile)
        end
    )

    jam = JamService.new(world.stations, profiles, send, function(player)
        listening:depart(player)
        concert:stop(player)
    end, nearby)
    task.spawn(function()
        while network.Parent do
            task.wait(0.1)
            jam:tick()
            for player, profile in profiles do
                if WorkspaceModel.tick(profile) then
                    send(player)
                end
            end
        end
    end)

    world.quest.prompt.Triggered:Connect(function(player)
        local profile = profiles[player]
        if not profile or not profile.ready or not nearby(player, world.quest.anchor, 9) then
            return
        end
        local now = os.clock()
        if profile.lastTalk and now - profile.lastTalk < 1 then
            return
        end
        profile.lastTalk = now
        profile.companionRoute = "legacy"
        if not profile.quest.accepted then
            profile.quest.accepted = true
            profile.editVersion += 1
            send(
                player,
                "Mica: Help me give the quay a tune. Collect our three sounds, save a beat using one, then play it at the courtyard."
            )
        elseif profile.quest.completed then
            send(
                player,
                "Mica: The quay has its tune. Your first set belongs here. Keep making it yours."
            )
        else
            send(player, "Mica: " .. Quest.summary(profile).objective)
        end
    end)

    local function enterStation(player, id)
        local profile = profiles[player]
        local station = world.stations[id]
        if
            not profile
            or not profile.ready
            or not station
            or not nearby(player, station.anchor, 11)
        then
            return
        end
        if station.owner and station.owner ~= player then
            send(player, "This station is occupied. The other workbench is available to try.")
            return
        end
        listening:depart(player)
        release(player)
        profile.station = id
        station.owner = player
        station.label.Text = "MK-I  /  " .. player.DisplayName
        station.prompt.ActionText = "Occupied"
        send(
            player,
            "Select a sound bank and pad, then add notes. Arrange named sections in Song Mode."
        )
    end
    quay = QuayDemoService.new(
        world,
        profiles,
        rooms,
        send,
        function(player)
            listening:depart(player)
            release(player)
        end,
        nearby,
        persist,
        enterStation,
        function(player)
            concert:open(player)
        end
    )
    commerce = CommerceService.new(profiles, function(player)
        if wardrobe then
            wardrobe:refresh(player)
        end
        send(player)
    end, function(player, message)
        send(player, message)
    end)
    wardrobe = WardrobeService.new(profiles, function(player)
        return commerce:verified(player)
    end)
    experience = QuayExperienceService.new(world, profiles, nearby, send, function(player, profile)
        quay:changed(player, profile)
    end, wardrobe, commerce)
    task.spawn(function()
        while world.root.Parent do
            task.wait(1)
            quay:tick()
        end
    end)

    companions = CompanionService.new(profiles, send, function(player, profile)
        profile.progressNeedsSave = true
        drainQuestSave(player, profile)
    end, world)

    local function join(player)
        if profiles[player] then
            return
        end
        local profile = Profiles.new()
        profile.playing = false
        profile.recording = false
        profile.startedAt = 0
        profile.epoch = 0
        profile.tokens = 36
        profile.lastToken = os.clock()
        profile.tapTokens = 96
        profile.lastTapToken = profile.lastToken
        profile.lastSave = -math.huge
        WorkspaceModel.sync(profile)
        profiles[player] = profile
        task.spawn(function()
            Profiles.load(player, profile)
            if profiles[player] ~= profile or player.Parent ~= Players then
                return
            end
            WorkspaceModel.sync(profile)
            rooms:assign(player, profile)
            wardrobe:bind(player)
            commerce:load(player)
            quay:arrive(player, profile, true)
            send(
                player,
                if profile.loadFailed
                    then "Your cloud save could not be loaded. Current work is temporary."
                    else nil
            )
        end)
        player.CharacterRemoving:Connect(function()
            listening:depart(player)
            release(player)
        end)
        player.CharacterAdded:Connect(function()
            if profile.ready then
                quay:arrive(player, profile, false)
            end
        end)
    end
    Players.PlayerAdded:Connect(join)
    for _, player in Players:GetPlayers() do
        join(player)
    end
    Players.PlayerRemoving:Connect(function(player)
        liveMusic:remove(player)
        quay:flush(player)
        listening:depart(player)
        release(player)
        companions:remove(player)
        experience:remove(player)
        wardrobe:remove(player)
        commerce:remove(player)
        profiles[player] = nil
        quay:remove(player)
        rooms:remove(player)
        for visitor, profile in profiles do
            if profile.ready and rooms:assign(visitor, profile) then
                send(visitor)
            end
        end
    end)
    game:BindToClose(function()
        for player in profiles do
            quay:flush(player)
        end
        local deadline = os.clock() + 25
        while os.clock() < deadline do
            local saving = false
            for _, profile in profiles do
                saving = saving or profile.saving or profile.progressNeedsSave == true
            end
            if not saving then
                break
            end
            task.wait(0.1)
        end
        commerce:destroy()
    end)

    for id, station in world.stations do
        station.prompt.Triggered:Connect(function(player)
            local profile = profiles[player]
            if not profile or not profile.ready or not nearby(player, station.anchor, 11) then
                return
            end
            if station.owner and station.owner ~= player then
                send(player, "This station is occupied. The other workbench is available to try.")
                return
            end
            listening:depart(player)
            release(player)
            profile.station = id
            station.owner = player
            station.label.Text = "MK-I  /  " .. player.DisplayName
            station.prompt.ActionText = "Occupied"
            send(
                player,
                "Select a sound bank and pad, then add notes. Arrange named sections in Song Mode."
            )
        end)
    end

    for id, node in world.discoveries do
        node.prompt.Triggered:Connect(function(player)
            local profile = profiles[player]
            if not profile or not profile.ready or not nearby(player, node.anchor, 11) then
                return
            end
            local now = os.clock()
            if profile.lastDiscovery and now - profile.lastDiscovery < 0.5 then
                return
            end
            profile.lastDiscovery = now
            profile.companionRoute = "legacy"
            local collected = profile.unlocked[id] == true
            profile.unlocked[id] = true
            if not collected then
                profile.editVersion += 1
            end
            send(
                player,
                if collected
                    then "Already in your collection. Preview requested."
                    else Discoveries.ById[id].origin
                        .. " Virtual sample collected. At a sampler, choose Sounds to assign it to a pad.",
                node.sampleId
            )
        end)
    end

    local function bounded(value, depth, budget)
        if depth > 8 then
            return false
        end
        budget.nodes += 1
        if budget.nodes > 512 then
            return false
        end
        local kind = type(value)
        if kind == "table" then
            for key, item in value do
                if type(key) ~= "string" and type(key) ~= "number" then
                    return false
                end
                if not bounded(key, depth + 1, budget) or not bounded(item, depth + 1, budget) then
                    return false
                end
            end
        elseif kind == "string" then
            if #value > 1024 then
                return false
            end
        elseif kind == "number" then
            if value ~= value or math.abs(value) == math.huge then
                return false
            end
        elseif kind ~= "boolean" and kind ~= "nil" then
            return false
        end
        return true
    end
    command.OnServerEvent:Connect(function(player, action, a, b)
        local profile = profiles[player]
        if not profile or type(action) ~= "string" or #action > 32 then
            return
        end
        if not bounded(a, 0, { nodes = 0 }) or not bounded(b, 0, { nodes = 0 }) then
            return
        end
        local now = os.clock()
        if action:sub(1, 9) == "Companion" then
            companions:command(player, action, a, b)
            return
        end
        if action == "Tap" then
            -- Keep a dense multi-pad roll from consuming Stop/Release's budget.
            profile.tapTokens = math.min(96, profile.tapTokens + (now - profile.lastTapToken) * 96)
            profile.lastTapToken = now
            if profile.tapTokens < 1 then
                return
            end
            profile.tapTokens -= 1
        else
            profile.tokens = math.min(36, profile.tokens + (now - profile.lastToken) * 24)
            profile.lastToken = now
            if profile.tokens < 1 then
                return
            end
            profile.tokens -= 1
        end
        if action == "Hello" then
            send(player)
            return
        end
        if not profile.ready then
            return
        end
        if action == "LeaveListening" then
            listening:depart(player)
            return
        end
        if action == "Release" then
            local leaveWorkshop = profile.station ~= nil and world.demo ~= nil
            listening:depart(player)
            release(player)
            if leaveWorkshop then
                quay:returnToRoamer(player, profile)
            end
            return
        end
        if action == "Room" then
            local _, notice = rooms:change(player, profile, a, b)
            send(player, notice)
            return
        end
        if action:sub(1, 4) == "Life" then
            experience:command(player, action, a, b)
            return
        end
        if action == "QuayStage" then
            local station = world.stations[profile.station]
            if not station or station.owner ~= player or not nearby(player, station.anchor, 15) then
                send(
                    player,
                    "Open your music library at a workbench to take a set to the courtyard."
                )
                return
            end
            if quay:teleport(player, world.listening.anchor.Position + Vector3.new(0, 0, -5)) then
                profile.stageFromWorkshop = true
                listening:openBoard(player)
            end
            return
        end
        if action:sub(1, 4) == "Quay" then
            quay:command(player, action, a)
            return
        end
        if action:sub(1, 3) == "Jam" then
            jam:command(player, action, a)
            return
        end
        if action:sub(1, 7) == "Chapter" then
            concert:command(player, action, a)
            return
        end
        if action:sub(1, 5) == "Stage" or action:sub(1, 9) == "Listening" then
            listening:command(player, action, a)
            if action == "StageClose" and profile.stageFromWorkshop then
                profile.stageFromWorkshop = nil
                quay:returnToRoamer(player, profile)
            end
            return
        end
        local station = world.stations[profile.station]
        if not station or station.owner ~= player or not nearby(player, station.anchor, 15) then
            release(player, "Return to a workbench to edit your project.")
            return
        end
        if
            jam.members[player]
            and (
                action == "Play"
                or action == "PlayStart"
                or action == "Record"
                or action == "Overdub"
                or action == "SongPlay"
                or action == "FinishedPlay"
                or action == "Tap"
            )
        then
            send(
                player,
                "The jam owns playback. Edit notes, then publish; leave the jam for solo play."
            )
            return
        end
        if WorkspaceModel.handles(action) then
            local ok, result, detail =
                WorkspaceModel.command(player, profile, action, a, b, persist, send)
            if action == "Tap" and ok then
                profile.noteDeltas = profile.noteDeltas or {}
                if detail and detail.event then
                    table.insert(profile.noteDeltas, detail)
                end
                if not profile.pendingTapState then
                    profile.pendingTapState = true
                    task.delay(1 / 30, function()
                        profile.pendingTapState = false
                        if profiles[player] ~= profile then
                            return
                        end
                        local revisions, drafts = {}, {}
                        for id, sequence in profile.music.project.sequences do
                            revisions[id] = sequence.revision
                        end
                        for id, draft in profile.music.project.drafts do
                            drafts[id] = draft.revision
                        end
                        delta:FireClient(player, {
                            projectId = profile.music.project.id,
                            projectRevision = profile.music.project.revision,
                            events = profile.noteDeltas,
                            sequenceRevisions = revisions,
                            draftRevisions = drafts,
                            editVersion = profile.editVersion,
                        })
                        profile.noteDeltas = {}
                        liveMusic:update(player, profile, quay and quay:van(player))
                    end)
                end
            else
                send(player, result)
            end
        elseif action == "Broadcast" and type(a) == "boolean" then
            profile.broadcast = a
            send(player)
        elseif action == "Finish" and type(a) == "string" and Cosmetics.Sets[a] then
            profile.finish = a
            profile.editVersion += 1
            send(player)
        elseif action == "Restore" and a == profile.editVersion and not profile.saving then
            local _, message = Profiles.restore(profile)
            WorkspaceModel.stop(profile, true)
            WorkspaceModel.sync(profile)
            send(player, message)
        end
    end)

    task.spawn(function()
        while network.Parent do
            task.wait(1)
            listening:tick()
            concert:tick()
            for player, profile in profiles do
                drainQuestSave(player, profile)
                local station = world.stations[profile.station]
                if station and not nearby(player, station.anchor, 18) then
                    release(player, "Station released. Your project stays with you.")
                end
            end
        end
    end)
end
return MusicService
