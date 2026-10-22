local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")
local Shared = game:GetService("ReplicatedStorage").Shared
local ContentIds = require(Shared.ContentIds)
local Catalog = require(Shared.SampleCatalog)
local AudioEngine = {}
AudioEngine.__index = AudioEngine

function AudioEngine.new(groupName)
    local self = setmetatable(
        { banks = {}, muted = false, configured = 0, Changed = Instance.new("BindableEvent") },
        AudioEngine
    )
    local group = Instance.new("SoundGroup")
    group.Name = groupName or "PersonalSampler"
    group.Volume = 0.6
    group.Parent = SoundService
    self.group = group
    local preload = {}
    local ids = {}
    for _, sample in Catalog.List do
        table.insert(ids, sample.id)
    end
    for _, id in { "ui_tap", "ui_collect", "ui_save", "ui_error", "waterfront" } do
        table.insert(ids, id)
    end
    for _, sampleId in ids do
        local id = ContentIds.Audio[sampleId]
        if type(id) == "number" and id > 0 then
            self.configured += 1
            local voice = Instance.new("Sound")
            voice.Name = sampleId
            voice.SoundId = "rbxassetid://" .. tostring(id)
            voice.Volume = 0.7
            voice.SoundGroup = group
            voice.Parent = SoundService
            self.banks[sampleId] = { voices = { voice }, cursor = 0 }
            table.insert(preload, voice)
        end
    end
    task.spawn(function()
        if #preload > 0 then
            pcall(function()
                ContentProvider:PreloadAsync(preload)
            end)
        end
        self.Changed:Fire()
    end)
    return self
end

function AudioEngine:status()
    if self.configured == 0 then
        return "Sound bank unavailable in this preview. You can still create and save patterns."
    end
    local ready = 0
    local configured = 0
    for _, sample in Catalog.List do
        local bank = self.banks[sample.id]
        if bank then
            configured += 1
        end
        if bank and bank.voices[1].IsLoaded then
            ready += 1
        end
    end
    return string.format(
        "Sounds ready: %d / %d. %d unavailable in this preview.",
        ready,
        configured,
        #Catalog.List - ready
    )
end

function AudioEngine:ambient(enabled)
    local bank = self.banks.waterfront
    if not bank then
        return false
    end
    local voice = bank.voices[1]
    if enabled and not self.muted and voice.IsLoaded then
        voice.Looped = true
        voice.Volume = 0.12
        if not voice.IsPlaying then
            voice:Play()
        end
        return true
    end
    voice:Stop()
    return false
end

function AudioEngine:play(id)
    local bank = self.banks[id]
    if self.muted or not bank or not bank.voices[1].IsLoaded then
        return false
    end
    bank.cursor = bank.cursor % 4 + 1
    local voice = bank.voices[bank.cursor]
    if not voice then
        voice = bank.voices[1]:Clone()
        voice.Parent = SoundService
        bank.voices[bank.cursor] = voice
    end
    voice:Stop()
    voice.TimePosition = 0
    voice:Play()
    return true
end

function AudioEngine:setMuted(value)
    self.muted = value
    self.group.Volume = if value then 0 else 0.6
    if value then
        self:stop()
    end
end

function AudioEngine:stop()
    for _, bank in self.banks do
        for _, voice in bank.voices do
            voice:Stop()
        end
    end
end
return AudioEngine
