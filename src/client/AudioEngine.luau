local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")
local Shared = game:GetService("ReplicatedStorage").Shared
local ContentIds = require(Shared.ContentIds)
local LocalContent = require(Shared.LocalContent)
local RunService = game:GetService("RunService")
local Catalog = require(Shared.SampleCatalog)
local PadVoiceProcessor = require(script.Parent.PadVoiceProcessor)
local AudioEngine = {}
AudioEngine.__index = AudioEngine

-- Project limits, not Roblox API limits. No voices are allocated on a pad hit.
local MUSIC_VOICES = 4
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
    local id = ContentIds.Audio[sampleId]
    local localUri = if RunService:IsStudio() then LocalContent.Audio[sampleId] else nil
    local bank = {
        voices = {},
        cursor = 0,
        generation = 0,
        state = if id == nil then "unconfigured" else "invalid",
        music = music == true,
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
        voice.SoundGroup = self.group
        table.insert(bank.voices, voice)
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
        voice:Stop()
        voice:Destroy()
    end
    table.clear(bank.connections)
    table.clear(bank.voices)
    if bank.configured then
        self.configured -= 1
    end
    self.banks[id] = nil
end

function AudioEngine:setSelection(assignments, mask)
    if self.destroyed then
        return
    end
    local wanted = {}
    for pad = 1, 16 do
        if
            (mask ~= nil and not mask[pad]) or (self.strictSelection and assignments[pad] == nil)
        then
            continue
        end
        local id = assignments[pad]
        wanted[if Catalog.ById[id] then id else Catalog.List[pad].id] = true
    end
    if self.worldPreview then
        for _, id in { "kick", "closed_hat", "pluck" } do
            wanted[id] = true
        end
    end
    -- Keep the three discovery previews alongside active pads.
    for _, sample in Catalog.Packs[1].samples do
        if not self.strictSelection and sample.discovery then
            wanted[sample.id] = true
        end
    end
    local unchanged = self.selection ~= nil
    if unchanged then
        for id in wanted do
            if not self.selection[id] then
                unchanged = false
                break
            end
        end
        if unchanged then
            for id in self.selection do
                if not wanted[id] then
                    unchanged = false
                    break
                end
            end
        end
    end
    if unchanged then
        return
    end
    self.selection = wanted
    for id, bank in table.clone(self.banks) do
        if bank.music and not wanted[id] then
            self:_removeBank(id)
        end
    end
    for id in wanted do
        if not self.banks[id] then
            self:_addBank(id, self.musicVoices, true)
        end
    end
    self.Changed:Fire()
end

function AudioEngine.new(groupName, options)
    local self = setmetatable({
        banks = {},
        connections = {},
        muted = false,
        configured = 0,
        destroyed = false,
        ambientRequested = false,
        Changed = Instance.new("BindableEvent"),
    }, AudioEngine)
    options = options or {}
    self.strictSelection = options.strictSelection == true
    self.musicVoices = if options.jamTrack then 2 else MUSIC_VOICES
    self.volume = if options.jamTrack then 0.05 else 0.6
    local group = Instance.new("SoundGroup")
    group.Name = groupName or "PersonalSampler"
    group.Volume = self.volume
    group.Parent = SoundService
    self.group = group
    self.worldPreview = options.musicOnly ~= true
    self.processor = PadVoiceProcessor.new(group)
    self:setSelection({}, if self.strictSelection then {} else nil)
    if not options.musicOnly then
        for _, id in CUES do
            self:_addBank(id, 1)
        end
        self:_addBank("waterfront", 1)
    end
    return self
end

function AudioEngine:diagnostics()
    local states = {}
    for id, bank in self.banks do
        states[id] = { state = bank.state, fetchStatus = bank.fetchStatus, voices = #bank.voices }
    end
    return { muted = self.muted, destroyed = self.destroyed, banks = states }
end

function AudioEngine:status()
    if self.destroyed then
        return "Audio engine stopped."
    end
    local counts =
        { ready = 0, loading = 0, failed = 0, timedOut = 0, unconfigured = 0, invalid = 0 }
    local musicCount = 0
    for _, bank in self.banks do
        if bank.music then
            counts[bank.state] += 1
            musicCount += 1
        end
    end
    local prefix = if self.muted then "Sound muted. " else ""
    if counts.unconfigured == musicCount then
        return prefix .. "Sound bank not configured. You can still create and save patterns."
    end
    local parts = { string.format("Sounds %d/%d ready", counts.ready, musicCount) }
    for _, item in
        {
            { "loading", "loading" },
            { "failed", "failed" },
            { "timedOut", "timed out" },
            { "unconfigured", "unconfigured" },
            { "invalid", "invalid IDs" },
        }
    do
        if counts[item[1]] > 0 then
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

function AudioEngine:play(id, settings, pad)
    local bank = self.banks[id]
    if self.destroyed or self.muted or not bank or bank.state ~= "ready" or id == "waterfront" then
        return false
    end
    -- Prefer an idle voice, otherwise steal the next voice in the bounded ring.
    local index = bank.cursor % #bank.voices + 1
    for offset = 1, #bank.voices do
        local candidate = (bank.cursor + offset - 1) % #bank.voices + 1
        if bank.voices[candidate].IsLoaded and not bank.voices[candidate].IsPlaying then
            index = candidate
            break
        end
    end
    local voice = bank.voices[index]
    if not voice.IsLoaded then
        self:_refresh(bank)
        return false
    end
    bank.cursor = index
    voice:Stop()
    voice.TimePosition = 0
    self.processor:prepare(voice, settings, pad)
    voice:Play()
    return true
end

function AudioEngine:_stopVoices()
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
    self.group.Volume = if self.muted then 0 else self.volume
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
    self.Changed:Destroy()
end

return AudioEngine
