local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Pattern = require(ReplicatedStorage.Shared.Pattern)
local Catalog = require(ReplicatedStorage.Shared.SampleCatalog)
local Cosmetics = require(ReplicatedStorage.Shared.CosmeticCatalog)
local Book = require(ReplicatedStorage.Shared.BeatBook)
local Quest = require(ReplicatedStorage.Shared.FirstPerformanceQuest)
local Profiles = require(script.Parent.ProfileStore)
local ListeningSession = require(script.Parent.ListeningSession)
local RoomService = require(script.Parent.RoomService)
local Missions = require(ReplicatedStorage.Shared.NeighborhoodMissions)
local Discoveries = require(ReplicatedStorage.Shared.DiscoveryCatalog)
local ConcertService = require(script.Parent.ConcertService)
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
    network.Parent = ReplicatedStorage
    local profiles = {}
    local listening
    local concert

    local function nearby(player, anchor, distance)
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        return root ~= nil
            and humanoid ~= nil
            and humanoid.Health > 0
            and (root.Position - anchor.Position).Magnitude <= distance
    end

    local rooms = RoomService.new(world.rooms, nearby)

    local function send(player, notice, preview, cue)
        local profile = profiles[player]
        if profile == nil or player.Parent == nil then
            return
        end
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
            book = Book.summary(profile),
            quest = Quest.summary(profile),
            unlocked = profile.unlocked,
            station = profile.station,
            playing = profile.playing,
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
            restoration = if count == 3 and Book.hasNotes(profile) then 4 else count,
            notice = notice,
            preview = preview,
            cue = cue,
            listening = listening and listening:state(player),
            stage = listening and listening:stageState(player),
            concert = concert and concert:state(player),
        })
    end

    local function release(player, notice)
        local profile = profiles[player]
        if not profile then
            return
        end
        local station = world.stations[profile.station]
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
        profile.playing = false
        profile.recording = false
        profile.epoch += 1
        send(player, notice)
    end

    local drainQuestSave
    local function persist(player, profile, successNotice)
        if profile.saving then
            return false
        end
        profile.saving = true
        send(player, "Saving...")
        task.spawn(function()
            -- ProfileStore owns the flag across its yielding storage operation.
            profile.saving = false
            local ok, result = Profiles.save(player, profile)
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
        profiles[player] = profile
        task.spawn(function()
            Profiles.load(player, profile)
            if profiles[player] ~= profile or player.Parent ~= Players then
                return
            end
            rooms:assign(player, profile)
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
    end
    Players.PlayerAdded:Connect(join)
    for _, player in Players:GetPlayers() do
        join(player)
    end
    Players.PlayerRemoving:Connect(function(player)
        listening:depart(player)
        release(player)
        profiles[player] = nil
        rooms:remove(player)
        for visitor, profile in profiles do
            if profile.ready and rooms:assign(visitor, profile) then
                send(visitor)
            end
        end
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
            send(player, "Select a pad, then add steps. Space plays your loop.")
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

    command.OnServerEvent:Connect(function(player, action, a, b)
        local profile = profiles[player]
        if not profile or type(action) ~= "string" or #action > 32 then
            return
        end
        local now = os.clock()
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
            listening:depart(player)
            release(player)
            return
        end
        if action == "Room" then
            local _, notice = rooms:change(player, profile, a, b)
            send(player, notice)
            return
        end
        if action:sub(1, 7) == "Chapter" then
            concert:command(player, action, a)
            return
        end
        if action:sub(1, 5) == "Stage" then
            listening:command(player, action)
            return
        end
        local station = world.stations[profile.station]
        if not station or station.owner ~= player or not nearby(player, station.anchor, 15) then
            release(player, "Return to a workbench to edit your pattern.")
            return
        end
        local notice
        if action == "SelectSlot" and Pattern.integer(a, 1, Book.SlotCount) then
            Book.select(profile, a)
            profile.playing = false
            profile.recording = false
            profile.epoch += 1
        elseif action == "ShelfStore" then
            if profile.saving or now - profile.lastSave < 5 then
                send(player, "Please wait a moment between saves.")
                return
            end
            local ok, result = Book.store(profile, a, b)
            if not ok then
                send(player, result)
                return
            end
            profile.editVersion += 1
            profile.lastSave = now
            persist(
                player,
                profile,
                result
                    .. (
                        if profile.saveMode == "session"
                            then " Saved for this Studio session only."
                            else " Profile saved."
                    )
            )
            return
        elseif action == "ShelfLoad" then
            if profile.saving then
                send(player, "Wait for the current save before loading a beat.")
                return
            end
            local ok, result = Book.load(profile, a, b)
            if not ok then
                send(player, result)
                return
            end
            notice = result
            profile.playing = false
            profile.recording = false
            profile.epoch += 1
        elseif action == "Step" and Pattern.integer(a, 1, 16) and Pattern.integer(b, 1, 16) then
            profile.pattern.rows[a][b] = not profile.pattern.rows[a][b]
        elseif action == "MutePad" and Pattern.integer(a, 1, 16) then
            profile.pattern.muted[a] = not profile.pattern.muted[a]
        elseif action == "ClearPad" and Pattern.integer(a, 1, 16) then
            profile.pattern.rows[a] = table.create(16, false)
        elseif
            action == "Assign"
            and Pattern.integer(a, 1, 16)
            and type(b) == "string"
            and #b <= 40
            and Catalog.isUnlocked(b, profile.unlocked)
        then
            profile.pattern.assignments[a] = b
        elseif action == "Pack" and type(a) == "string" and #a < 32 and Catalog.PackById[a] then
            if b ~= profile.editVersion or profile.saving then
                send(player, "Sounds changed or saving is in progress. Review the kit again.")
                return
            end
            local assignments = {}
            for pad = 1, 16 do
                local sample = Catalog.PackById[a].samples[pad]
                if not sample or not Catalog.isUnlocked(sample.id, profile.unlocked) then
                    return
                end
                assignments[pad] = sample.id
            end
            profile.pattern.assignments = assignments
            notice = Catalog.PackById[a].label .. " kit selected. Notes and tempo kept."
        elseif action == "Finish" and type(a) == "string" and #a < 32 and Cosmetics.Sets[a] then
            profile.finish = a
        elseif action == "Bpm" and Pattern.integer(a, Pattern.MinBpm, Pattern.MaxBpm) then
            profile.pattern.bpm = a
            if profile.playing then
                profile.startedAt = Workspace:GetServerTimeNow() + 0.15
                profile.epoch += 1
            end
        elseif action == "Play" then
            profile.playing = not profile.playing
            profile.recording = false
            profile.startedAt = Workspace:GetServerTimeNow() + 0.15
            profile.epoch += 1
        elseif action == "Stop" then
            profile.playing = false
            profile.recording = false
            profile.epoch += 1
        elseif action == "Record" then
            profile.recording = not profile.recording
            if profile.recording and not profile.playing then
                profile.playing = true
                profile.startedAt = Workspace:GetServerTimeNow() + 0.15
                profile.epoch += 1
            end
        elseif action == "Tap" and Pattern.integer(a, 1, 16) then
            if not profile.recording then
                return
            end
            local step = Pattern.recordStep(
                profile.pattern.bpm,
                profile.startedAt,
                Workspace:GetServerTimeNow(),
                b,
                profile.epoch
            )
            if not step then
                return
            end
            if profile.pattern.rows[a][step] then
                return
            end
            profile.pattern.rows[a][step] = true
            profile.editVersion += 1
            -- Apply notes immediately, but coalesce chord feedback into one state.
            if not profile.pendingTapState then
                profile.pendingTapState = true
                task.delay(1 / 30, function()
                    profile.pendingTapState = false
                    if profiles[player] == profile then
                        send(player)
                    end
                end)
            end
            return
        elseif action == "Save" then
            if profile.saving or now - profile.lastSave < 5 then
                send(player, "Please wait a moment between saves.")
                return
            end
            profile.lastSave = now
            persist(player, profile)
            return
        elseif action == "Restore" then
            if a ~= profile.editVersion then
                send(player, "Slots changed. Review Restore slots again before replacing A-D.")
                return
            end
            if profile.saving then
                send(player, "Wait for the current save before restoring slots.")
                return
            end
            local _, result = Profiles.restore(profile)
            notice = result
            profile.playing = false
            profile.recording = false
            profile.epoch += 1
        else
            return
        end
        if
            action == "Step"
            or action == "MutePad"
            or action == "ClearPad"
            or action == "Assign"
            or action == "Pack"
            or action == "Bpm"
            or action == "Finish"
            or action == "SelectSlot"
            or action == "ShelfLoad"
        then
            profile.editVersion += 1
        end
        send(player, notice)
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
                    release(player, "Station released. Your pattern stays with you.")
                end
            end
        end
    end)
end
return MusicService
