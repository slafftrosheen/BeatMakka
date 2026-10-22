local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Pattern = require(ReplicatedStorage.Shared.Pattern)
local Catalog = require(ReplicatedStorage.Shared.SampleCatalog)
local Cosmetics = require(ReplicatedStorage.Shared.CosmeticCatalog)
local Profiles = require(script.Parent.ProfileStore)
local ListeningSession = require(script.Parent.ListeningSession)
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

    local function nearby(player, anchor, distance)
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        return root ~= nil
            and humanoid ~= nil
            and humanoid.Health > 0
            and (root.Position - anchor.Position).Magnitude <= distance
    end

    local function send(player, notice, preview, cue)
        local profile = profiles[player]
        if profile == nil or player.Parent == nil then
            return
        end
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
            dirty = profile.editVersion ~= profile.savedEditVersion,
            restoration = if count == 3 and Pattern.hasNotes(profile.pattern) then 4 else count,
            notice = notice,
            preview = preview,
            cue = cue,
            listening = listening and listening:state(player),
        })
    end

    local function release(player, notice)
        local profile = profiles[player]
        if not profile then
            return
        end
        local station = world.stations[profile.station]
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

    listening = ListeningSession.new(world.listening, profiles, send, release, nearby)

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
        profile.lastSave = -math.huge
        profiles[player] = profile
        task.spawn(function()
            Profiles.load(player, profile)
            send(
                player,
                if profile.loadFailed
                    then "Your cloud save could not be loaded. Current work is temporary."
                    else nil
            )
        end)
        player.CharacterRemoving:Connect(function()
            listening:leave(player)
            release(player)
        end)
    end
    Players.PlayerAdded:Connect(join)
    for _, player in Players:GetPlayers() do
        join(player)
    end
    Players.PlayerRemoving:Connect(function(player)
        listening:leave(player)
        release(player)
        profiles[player] = nil
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
            listening:leave(player)
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
                    else "Sample collected. Assign it to a pad at a workstation.",
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
        profile.tokens = math.min(36, profile.tokens + (now - profile.lastToken) * 24)
        profile.lastToken = now
        if profile.tokens < 1 then
            return
        end
        profile.tokens -= 1
        if action == "Hello" then
            send(player)
            return
        end
        if not profile.ready then
            return
        end
        if action == "LeaveListening" then
            listening:leave(player)
            return
        end
        if action == "Release" then
            release(player)
            return
        end
        local station = world.stations[profile.station]
        if not station or station.owner ~= player or not nearby(player, station.anchor, 15) then
            release(player, "Return to a workbench to edit your pattern.")
            return
        end
        local notice
        if action == "Step" and Pattern.integer(a, 1, 16) and Pattern.integer(b, 1, 16) then
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
            local time = Workspace:GetServerTimeNow()
            if time < profile.startedAt then
                return
            end
            local absolute = math.floor(
                (time - profile.startedAt) / Pattern.stepDuration(profile.pattern.bpm) + 0.5
            )
            profile.pattern.rows[a][absolute % 16 + 1] = true
        elseif action == "Save" then
            if profile.saving or now - profile.lastSave < 5 then
                send(player, "Please wait a moment between saves.")
                return
            end
            profile.lastSave = now
            task.spawn(function()
                profile.saving = true
                send(player, "Saving...")
                profile.saving = false
                local ok, result = Profiles.save(player, profile)
                if ok and profile.editVersion ~= profile.savedEditVersion then
                    result = "Snapshot saved. Your newer edits are not saved yet."
                end
                send(player, result, nil, if ok then "ui_save" else "ui_error")
            end)
            return
        elseif action == "Restore" then
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
            or action == "Bpm"
            or action == "Finish"
            or action == "Tap"
        then
            profile.editVersion += 1
        end
        send(player, notice)
    end)

    task.spawn(function()
        while network.Parent do
            task.wait(1)
            listening:tick()
            for player, profile in profiles do
                local station = world.stations[profile.station]
                if station and not nearby(player, station.anchor, 18) then
                    release(player, "Station released. Your pattern stays with you.")
                end
            end
        end
    end)
end
return MusicService
