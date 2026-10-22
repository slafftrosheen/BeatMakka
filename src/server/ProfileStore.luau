local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage").Shared
local Pattern = require(Shared.Pattern)
local Cosmetics = require(Shared.CosmeticCatalog)

local ProfileStore = {}
local store

local function cloudStore()
    if not store then
        store = DataStoreService:GetDataStore("FrequencyZero.Patterns.v1")
    end
    return store
end

function ProfileStore.new()
    return {
        pattern = Pattern.new(),
        unlocked = {},
        finish = "quay",
        saved = nil,
        storageRevision = 0,
        saveMode = if RunService:IsStudio() then "session" else "cloud",
        loadFailed = false,
        saving = false,
        ready = false,
        editVersion = 0,
        savedEditVersion = 0,
    }
end

local function capture(profile)
    return {
        schema = 1,
        pattern = Pattern.sanitize(profile.pattern, profile.unlocked),
        unlocked = table.clone(profile.unlocked),
        finish = profile.finish,
    }
end

function ProfileStore.load(player, profile, storage)
    if profile.saveMode == "session" then
        profile.ready = true
        return
    end
    local ok, data = pcall(function()
        return (storage or cloudStore()):GetAsync(tostring(player.UserId))
    end)
    if not ok or (data ~= nil and (type(data) ~= "table" or data.schema ~= 1)) then
        profile.loadFailed = true
        profile.saveMode = "unavailable"
    elseif type(data) == "table" then
        for _, id in { "I01", "I02", "I03" } do
            profile.unlocked[id] = type(data.unlocked) == "table" and data.unlocked[id] == true
        end
        profile.pattern = Pattern.sanitize(data.pattern, profile.unlocked)
        profile.finish = if type(data.finish) == "string" and Cosmetics.Sets[data.finish]
            then data.finish
            else "quay"
        profile.storageRevision = if Pattern.integer(data.revision, 0, 1e12)
            then data.revision
            else 0
        profile.saved = capture(profile)
    end
    profile.ready = true
end

function ProfileStore.save(player, profile, storage)
    if profile.loadFailed then
        return false, "Cloud load failed. Saving is disabled to protect your existing work."
    end
    if profile.saving then
        return false, "A save is already in progress."
    end
    profile.saving = true
    local snapshot = capture(profile)
    local capturedVersion = profile.editVersion
    if profile.saveMode == "session" then
        profile.saved = snapshot
        profile.savedEditVersion = capturedVersion
        profile.saving = false
        return true, "Saved for this Studio session only."
    end
    local expected = profile.storageRevision
    snapshot.revision = expected + 1
    local ok, saved = pcall(function()
        return (storage or cloudStore()):UpdateAsync(tostring(player.UserId), function(previous)
            if
                previous ~= nil
                and (
                    type(previous) ~= "table"
                    or previous.schema ~= 1
                    or previous.revision ~= expected
                )
            then
                return nil
            end
            return snapshot
        end)
    end)
    profile.saving = false
    if not ok then
        return false, "Save could not reach Roblox. Your current pattern is still open; try again."
    end
    if saved == nil then
        return false, "A newer save exists in another server. Rejoin before saving over it."
    end
    profile.saved = snapshot
    profile.savedEditVersion = capturedVersion
    profile.storageRevision = snapshot.revision
    return true, "Pattern and discoveries saved."
end

function ProfileStore.restore(profile)
    if profile.saved == nil then
        return false, "There is no saved pattern to restore yet."
    end
    -- Discoveries are permanent within this play session; restoring never revokes them.
    profile.pattern = Pattern.sanitize(profile.saved.pattern, profile.unlocked)
    profile.finish = profile.saved.finish or "quay"
    profile.editVersion += 1
    local hasNewDiscoveries = false
    for id, collected in profile.unlocked do
        if collected and profile.saved.unlocked[id] ~= true then
            hasNewDiscoveries = true
        end
    end
    if not hasNewDiscoveries then
        profile.savedEditVersion = profile.editVersion
    end
    return true, "Saved pattern restored."
end
return ProfileStore
