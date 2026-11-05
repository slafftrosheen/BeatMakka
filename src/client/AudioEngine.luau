local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")
local Shared = game:GetService("ReplicatedStorage").Shared
local ContentIds = require(Shared.ContentIds)
local LocalContent = require(Shared.LocalContent)
local RunService = game:GetService("RunService")
local Catalog = require(Shared.SampleCatalog)
local Versions = require(Shared.SampleVersions)
local PadVoiceProcessor = require(script.Parent.PadVoiceProcessor)
local Mix = require(script.Parent.AudioMix)
local AudioEngine = {}
AudioEngine.__index = AudioEngine

-- Project limits, not Roblox API limits. No voices are allocated on a pad hit.
local MUSIC_VOICES = 2
local MUSIC_VOICE_LIMIT = 256
local ENGINE_VOICE_LIMIT = 64
local allocatedMusicVoices = 0
local LOAD_TIMEOUT = 15
local CUES = { "ui_tap", "ui_collect", "ui_save", "ui_error" }

local function validAssetId(id)
    return type(id) == "number" and id > 0 and id < 2 ^ 53 and id == math.floor(id)
end

local function allLoaded(bank)
    if #bank.voices == 0 then
        return false
    end
    for _, voice in bank.voices do
        if not voice.IsLoaded then
            return false
        end
    end
    return true
end

function AudioEngine:_isPlayable(id)
    return Catalog.isPlaybackReady(id)
end

function AudioEngine:_syncAmbient()
    local bank = self.banks.waterfront
    if self.destroyed or not bank or #bank.voices == 0 then
        return false
    end
    local voice = bank.voices[1]
    if self.ambientRequested and not self.muted and bank.state == "ready" and voice.IsLoaded then
        if not voice.IsPlaying then
            voice:Play()
        end
        return true
    end
    voice:Stop()
    return false
end

function AudioEngine:_setState(bank, state)
    if self.destroyed or bank.disposed or bank.state == state then
        return
    end
    bank.state = state
    bank.generation += 1
    if state == "loading" then
        local generation = bank.generation
        task.delay(LOAD_TIMEOUT, function()
            if not self.destroyed and bank.generation == generation and bank.state == "loading" then
                self:_setState(bank, if allLoaded(bank) then "ready" else "timedOut")
            end
        end)
    end
    self:_syncAmbient()
    self.Changed:Fire()
end

function AudioEngine:_refresh(bank)
    if self.destroyed or bank.disposed then
        return
    end
    if allLoaded(bank) then
        -- A late successful load may recover a timed-out or failed bank.
        self:_setState(bank, "ready")
    elseif bank.state == "ready" then
        self:_setState(bank, "loading")
    end
end

function AudioEngine:_addBank(sampleId, voiceCount, music)
    if music and not self:_isPlayable(sampleId) then
        return false
    end
    if music then
        voiceCount = math.min(
            voiceCount,
            MUSIC_VOICE_LIMIT - allocatedMusicVoices,
            ENGINE_VOICE_LIMIT - self.musicVoiceCount
        )
    end
    if voiceCount <= 0 then
        return false
    end
    local id = ContentIds.Audio[sampleId]
    local localUri = if RunService:IsStudio() then LocalContent.Audio[sampleId] else nil
    local preview = self.allowLocalPreview and Catalog.isPreviewAvailable(sampleId)
    if preview then
        localUri = LocalContent.PreviewAudio[sampleId]
    end
    local bank = {
        voices = {},
        cursor = 0,
        generation = 0,
        state = if id == nil then "unconfigured" else "invalid",
        music = music == true,
        localPreview = preview == true,
        connections = {},
    }
    self.banks[sampleId] = bank
    if not localUri and not validAssetId(id) then
        return
    end
    self.configured += 1
    bank.configured = true
    for index = 1, voiceCount do
        local voice = Instance.new("Sound")
        voice.Name = sampleId .. "_" .. tostring(index)
        voice.SoundId = localUri or ("rbxassetid://" .. string.format("%.0f", id))
        voice.Volume = if sampleId == "waterfront" then 0.12 else 0.7
        voice.Looped = sampleId == "waterfront"
        voice.SoundGroup = if sampleId == "waterfront"
            then self.ambienceGroup
            elseif table.find(CUES, sampleId) then self.cueGroup
            else self.group
        table.insert(bank.voices, voice)
        if music then
            allocatedMusicVoices += 1
            self.musicVoiceCount += 1
        end
    end
    self:_setState(bank, "loading")
    for _, voice in bank.voices do
        table.insert(
            bank.connections,
            voice:GetPropertyChangedSignal("IsLoaded"):Connect(function()
                self:_refresh(bank)
            end)
        )
        voice.Parent = SoundService
    end
    self:_refresh(bank)
    task.spawn(function()
        if self.destroyed or bank.disposed then
            return
        end
        local ok = pcall(function()
            ContentProvider:PreloadAsync(bank.voices, function(_, fetchStatus)
                if self.destroyed or bank.disposed then
                    return
                end
                bank.fetchStatus = fetchStatus.Name
                if allLoaded(bank) then
                    self:_setState(bank, "ready")
                elseif fetchStatus == Enum.AssetFetchStatus.Failure then
                    self:_setState(bank, "failed")
                elseif fetchStatus == Enum.AssetFetchStatus.TimedOut then
                    self:_setState(bank, "timedOut")
                end
            end)
        end)
        if self.destroyed or bank.disposed then
            return
        end
        if not ok and not allLoaded(bank) then
            self:_setState(bank, "failed")
        else
            self:_refresh(bank)
        end
    end)
    return true
end

function AudioEngine:_removeBank(id)
    local bank = self.banks[id]
    if not bank then
        return
    end
    bank.disposed = true
    bank.generation += 1
    for _, connection in bank.connections do
        connection:Disconnect()
    end
    for _, voice in bank.voices do
        self.processor:forget(voice)
        self.voiceStarted[voice] = nil
        self.voiceOwners[voice] = nil
        voice:Stop()
        voice:Destroy()
        if bank.music then
            allocatedMusicVoices -= 1
            self.musicVoiceCount -= 1
        end
    end
    table.clear(bank.connections)
    table.clear(bank.voices)
    if bank.configured then
        self.configured -= 1
    end
    self.banks[id] = nil
end

local function voicePlaying(bank)
    for _, voice in bank.voices do
        if voice.IsPlaying then
            return true
        end
    end
    return false
end

function AudioEngine:_syncMusic()
    if self.destroyed then
        return
    end
    local wanted = {}
    for id in self.selection or {} do
        wanted[id] = true
    end
    for id in self.scheduleSelection or {} do
        wanted[id] = true
    end
    if self.worldPreview then
        for _, role in
            { "preview_kick", "preview_closed_hat", "preview_pluck", "I01", "I02", "I03" }
        do
            local id = Catalog.sampleForRole(role)
            if id then
                wanted[id] = true
            end
        end
    end
    -- Keep every requested identity for truthful status even when it cannot
    -- allocate a voice. Readiness never substitutes a different sample.
    self.requestedMusic = table.clone(wanted)
    for id in self.scheduleUnavailable or {} do self.requestedMusic[id] = true end
    local ordered = {}
    for id in wanted do
        if self:_isPlayable(id) then
            table.insert(ordered, id)
        else
            wanted[id] = nil
        end
    end
    table.sort(ordered)
    local desired = if #ordered <= ENGINE_VOICE_LIMIT / MUSIC_VOICES then MUSIC_VOICES else 1
    self.reconcilePending = false
    for id, bank in table.clone(self.banks) do
        if bank.music then
            if not wanted[id] and not voicePlaying(bank) then
                self:_removeBank(id)
            elseif not wanted[id] then
                self.reconcilePending = true
            elseif #bank.voices > desired then
                for index = #bank.voices, desired + 1, -1 do
                    local voice = bank.voices[index]
                    if not voice.IsPlaying then
                        self.processor:forget(voice)
                        self.voiceOwners[voice] = nil
                        self.voiceStarted[voice] = nil
                        voice:Destroy()
                        table.remove(bank.voices, index)
                        allocatedMusicVoices -= 1
                        self.musicVoiceCount -= 1
                    else
                        self.reconcilePending = true
                    end
                end
            end
        end
    end
    -- Preallocate from selection/schedule preparation. A hit never creates a Sound.
    for _, id in ordered do
        if not self.banks[id] and not self:_addBank(id, desired, true) then
            self.reconcilePending = true
        end
    end
    self.wantedMusic = wanted
    self.selectionWorldPreview = self.worldPreview
    if #ordered == 0 and self.musicVoiceCount == 0 then
        self.processor:releaseChannels()
    end
    self.Changed:Fire()
end

local function sameSelection(a, b)
    for id in a or {} do
        if b[id] ~= a[id] then
            return false
        end
    end
    for id in b do
        if not a or a[id] ~= b[id] then
            return false
        end
    end
    return true
end

function AudioEngine:setSelection(assignments, mask, pins)
    if self.destroyed then
        return
    end
    local wanted, unavailable = {}, {}
    for address, value in if type(assignments) == "table" then assignments else {} do
        local id = if type(value) == "table" then value.sampleId else value
        if
            (mask == nil or mask[address] == true or mask[tonumber(address)] == true)
            and type(id) == "string"
        then
            wanted[id] = true
            if not Versions.matches(id, pins) then unavailable[id] = "versionMismatch" end
        end
    end
    if
        sameSelection(self.selection, wanted)
        and sameSelection(self.selectionUnavailable, unavailable)
        and self.selectionWorldPreview == self.worldPreview
    then
        return
    end
    self.selection = wanted
    self.selectionUnavailable = unavailable
    self:_syncMusic()
end

function AudioEngine:setSchedule(schedule)
    if self.destroyed then
        return
    end
    local wanted, unavailable = {}, {}
    if type(schedule) == "table" then
        for _, event in schedule.events or {} do
            if type(event.sampleId) == "string" then
                wanted[event.sampleId] = true
            end
        end
        for id in schedule.unavailable or {} do
            unavailable[id] = (schedule.unavailableReasons and schedule.unavailableReasons[id]) or "unavailable"
        end
    end
    if
        sameSelection(self.scheduleSelection, wanted)
        and sameSelection(self.scheduleUnavailable, unavailable)
        and self.selectionWorldPreview == self.worldPreview
    then
        return
    end
    self.scheduleSelection = wanted
    self.scheduleUnavailable = unavailable
    self:_syncMusic()
end

function AudioEngine.new(groupName, options)
    local self = setmetatable({
        banks = {},
        connections = {},
        muted = false,
        configured = 0,
        destroyed = false,
        ambientRequested = false,
        voiceStarted = {},
        voiceOwners = {},
        voiceGeneration = 0,
        musicVoiceCount = 0,
        chokes = {},
        Changed = Instance.new("BindableEvent"),
    }, AudioEngine)
    options = options or {}
    self.localMute = options.localMute == true
    -- Local Studio playback uses the same technical sources in the instrument,
    -- listening area and Finished Song. This never changes approval/admission.
    self.allowLocalPreview = RunService:IsStudio()
    self.strictSelection = options.strictSelection == true
    self.musicVoices = if options.jamTrack then 2 else MUSIC_VOICES
    self.volume = if options.jamTrack then 0.05 else 0.6
    local group = Instance.new("SoundGroup")
    group.Name = groupName or "PersonalSampler"
    group.Volume = self.volume
    group.Parent = SoundService
    self.group = group
    self.ambienceGroup = Instance.new("SoundGroup")
    self.ambienceGroup.Name = group.Name .. "Ambience"
    self.ambienceGroup.Parent = SoundService
    self.cueGroup = Instance.new("SoundGroup")
    self.cueGroup.Name = group.Name .. "Cues"
    self.cueGroup.Parent = SoundService
    local function applyMix()
        self.group.Volume = if self.muted then 0 else self.volume * Mix.music
        self.ambienceGroup.Volume = if self.muted
            then 0
            else self.volume * Mix.ambience * (if Mix.voiceActive
                    or Mix.commissionVoiceActive
                then 0.35
                else 1)
        self.cueGroup.Volume = if self.muted then 0 else self.volume * Mix.cues
    end
    self.applyMix = applyMix
    table.insert(self.connections, Mix.Changed.Event:Connect(applyMix))
    applyMix()
    self.worldPreview = options.musicOnly ~= true
    self.processor = PadVoiceProcessor.new(group)
    local reconcileAt = 0
    table.insert(
        self.connections,
        RunService.Heartbeat:Connect(function()
            if self.reconcilePending and os.clock() >= reconcileAt then
                reconcileAt = os.clock() + 0.25
                self:_syncMusic()
            end
        end)
    )
    self:setSelection({}, if self.strictSelection then {} else nil)
    if not options.musicOnly then
        for _, id in CUES do
            self:_addBank(id, 1)
        end
        self:_addBank("waterfront", 1)
    end
    return self
end

function AudioEngine:_requestedState(id)
    local denied = self.selectionUnavailable and self.selectionUnavailable[id]
        or self.scheduleUnavailable and self.scheduleUnavailable[id]
    if denied then return denied end
    local sample = Catalog.ById[id]
    if not sample then return "unavailable" end
    if not self:_isPlayable(id) then
        if not sample.audioApproved or not sample.runtimeAdmitted then return "unadmitted" end
        local remote = ContentIds.Audio[id]
        return if remote == nil or remote == 0 then "unconfigured" else "invalid"
    end
    local bank = self.banks[id]
    return if bank then bank.state else "voiceBudget"
end

function AudioEngine:diagnostics()
    local states = {}
    for id, bank in self.banks do
        states[id] = {
            state = bank.state,
            fetchStatus = bank.fetchStatus,
            voices = #bank.voices,
            localPreview = bank.localPreview,
        }
    end
    local requested = {}
    for id in self.requestedMusic or {} do requested[id] = self:_requestedState(id) end
    return {
        muted = self.muted,
        destroyed = self.destroyed,
        banks = states,
        requested = requested,
        globalMusicVoices = allocatedMusicVoices,
        globalMusicVoiceLimit = MUSIC_VOICE_LIMIT,
        engineMusicVoices = self.musicVoiceCount,
        engineMusicVoiceLimit = ENGINE_VOICE_LIMIT,
        processor = self.processor:diagnostics(),
        allowLocalPreview = self.allowLocalPreview,
    }
end

function AudioEngine:status()
    if self.destroyed then
        return "Audio engine stopped."
    end
    local counts = { ready = 0 }
    local musicCount, previewCount = 0, 0
    for id in self.requestedMusic or {} do
        local state = self:_requestedState(id)
        counts[state] = (counts[state] or 0) + 1
        musicCount += 1
        local bank = self.banks[id]
        if bank and bank.localPreview then previewCount += 1 end
    end
    local prefix = if self.muted then "Sound muted. " else ""
    if musicCount == 0 then
        return prefix .. "No music sounds selected."
    end
    local parts = { string.format("Sounds %d/%d ready", counts.ready, musicCount) }
    if previewCount > 0 then
        table.insert(parts, "Harbour Pulse / local kit")
    end
    for _, item in
        {
            { "loading", "loading" },
            { "failed", "failed" },
            { "timedOut", "timed out" },
            { "unconfigured", "unconfigured" },
            { "invalid", "invalid IDs" },
            { "unavailable", "unavailable samples" },
            { "unadmitted", "awaiting audio approval" },
            { "versionMismatch", "different pack version" },
            { "voiceBudget", "waiting for voice capacity" },
        }
    do
        if (counts[item[1]] or 0) > 0 then
            table.insert(parts, tostring(counts[item[1]]) .. " " .. item[2])
        end
    end
    return prefix .. table.concat(parts, "; ") .. "."
end

function AudioEngine:ambient(enabled)
    if self.destroyed then
        return false
    end
    self.ambientRequested = enabled == true
    return self:_syncAmbient()
end

local function routeScope(route)
    if type(route) == "table" then
        return tostring(route.projectId or "")
            .. ":"
            .. tostring(route.trackId or "")
            .. ":"
            .. tostring(route.programId or "")
    end
    if type(route) == "string" then
        return route:match("^(.*):%d+$") or route
    end
    return tostring(route or "audition")
end

function AudioEngine:play(id, settings, route, velocity)
    local bank = self.banks[id]
    if
        self.destroyed
        or self.muted
        or not bank
        or bank.state ~= "ready"
        or id == "waterfront"
        or #bank.voices == 0
        or (bank.music and not self:_isPlayable(id))
    then
        return false
    end
    local voice, oldest = nil, math.huge
    for _, candidate in bank.voices do
        if candidate.IsLoaded then
            if not candidate.IsPlaying then
                voice = candidate
                break
            end
            local started = self.voiceStarted[candidate] or 0
            if started < oldest then
                voice, oldest = candidate, started
            end
        end
    end
    if not voice then
        self:_refresh(bank)
        return false
    end
    -- Oldest-voice stealing is deterministic and bounded to this sample.
    self.voiceOwners[voice] = nil
    voice:Stop()
    voice.TimePosition = 0
    local musicRoute = route or ("sample:" .. id)
    if
        not self.processor:prepare(
            voice,
            settings,
            if bank.music then musicRoute else nil,
            velocity
        )
    then
        return false
    end
    if bank.music then
        local sample = Catalog.ById[id]
        if sample.chokeGroup then
            local key = routeScope(route) .. ":" .. sample.chokeGroup
            local previous = self.chokes[key]
            if previous and previous ~= voice and previous.Parent then
                self.voiceOwners[previous] = nil
                previous:Stop()
                self.processor:forget(previous)
            end
            self.chokes[key] = voice
        end
    elseif table.find(CUES, id) then
        voice.SoundGroup = self.cueGroup
    end
    self.voiceStarted[voice] = os.clock()
    self.voiceGeneration += 1
    local handle = { engine = self, voice = voice, generation = self.voiceGeneration,
        sampleId = id, route = if type(route) == "table" then table.clone(route) else route }
    self.voiceOwners[voice] = handle
    voice:Play()
    return true, handle
end

-- Finger-up relinquishes a one-shot without cutting its authored tail. Cancel
-- stops only the captured hit; a recycled/choked voice has a different handle.
function AudioEngine:release(handle, cancelled)
    if type(handle) ~= "table" or handle.engine ~= self
        or self.voiceOwners[handle.voice] ~= handle then return false end
    self.voiceOwners[handle.voice] = nil
    if cancelled and handle.voice.Parent then
        handle.voice:Stop()
        self.processor:forget(handle.voice)
    end
    return true
end

function AudioEngine:click()
    return self:play("ui_tap", { gain = 0.35 }, nil, 127)
end

function AudioEngine:_stopVoices()
    table.clear(self.voiceOwners)
    self.processor:stop()
    for _, bank in self.banks do
        for _, voice in bank.voices do
            voice:Stop()
        end
    end
end

function AudioEngine:setMuted(value)
    if self.destroyed then
        return
    end
    self.muted = value == true
    if not self.localMute then
        Mix.muted = self.muted
        Mix.Changed:Fire()
    end
    self.applyMix()
    if self.muted then
        self:_stopVoices()
    else
        self:_syncAmbient()
    end
    self.Changed:Fire()
end

function AudioEngine:stop()
    if self.destroyed then
        return
    end
    self.ambientRequested = false
    self:_stopVoices()
end

function AudioEngine:destroy()
    if self.destroyed then
        return
    end
    self.destroyed = true
    for _, connection in self.connections do
        connection:Disconnect()
    end
    self:_stopVoices()
    for id in table.clone(self.banks) do
        self:_removeBank(id)
    end
    table.clear(self.connections)
    table.clear(self.banks)
    self.processor:destroy()
    self.group:Destroy()
    self.ambienceGroup:Destroy()
    self.cueGroup:Destroy()
    self.Changed:Destroy()
end

return AudioEngine
