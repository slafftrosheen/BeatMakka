local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage").Shared
local Pattern = require(Shared.Pattern)
local Cosmetics = require(Shared.CosmeticCatalog)
local Book = require(Shared.BeatBook)
local Quest = require(Shared.FirstPerformanceQuest)
local Rooms = require(Shared.RoomCatalog)

local ProfileStore = {}
local store

local function cloudStore()
    if not store then
        store = DataStoreService:GetDataStore("FrequencyZero.Patterns.v1")
    end
    return store
end

function ProfileStore.new()
    local slots = Book.sanitizeSlots(nil, {})
    return {
        slots = slots,
        activeSlot = 1,
        pattern = slots[1],
        shelf = Book.sanitizeShelf(nil, {}),
        quest = Quest.sanitize(nil),
        unlocked = {},
        finish = "quay",
        room = Rooms.sanitize(nil, {}),
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
    local book = Book.capture(profile)
    return {
        schema = 2,
        pattern = Pattern.sanitize(profile.pattern, profile.unlocked),
        slots = book.slots,
        activeSlot = book.activeSlot,
        shelf = book.shelf,
        quest = Quest.sanitize(profile.quest),
        unlocked = table.clone(profile.unlocked),
        finish = profile.finish,
        room = Rooms.sanitize(profile.room, profile),
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
    if
        not ok
        or (
            data ~= nil
            and (
                type(data) ~= "table"
                or (data.schema ~= 1 and data.schema ~= 2)
                or (data.revision ~= nil and not Pattern.integer(data.revision, 0, 1e12))
            )
        )
    then
        profile.loadFailed = true
        profile.saveMode = "unavailable"
    elseif type(data) == "table" then
        for _, id in { "I01", "I02", "I03" } do
            profile.unlocked[id] = type(data.unlocked) == "table" and data.unlocked[id] == true
        end
        Book.restoreWorking(profile, data)
        profile.shelf =
            Book.sanitizeShelf(if data.schema == 2 then data.shelf else nil, profile.unlocked)
        profile.quest = Quest.sanitize(if data.schema == 2 then data.quest else nil)
        profile.finish = if type(data.finish) == "string" and Cosmetics.Sets[data.finish]
            then data.finish
            else "quay"
        profile.storageRevision = if Pattern.integer(data.revision, 0, 1e12)
            then data.revision
            else 0
        profile.room = Rooms.sanitize(data.room, profile)
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
    if expected >= 1e12 then
        profile.saving = false
        return false, "This profile cannot be saved again. Your current work is still open."
    end
    snapshot.revision = expected + 1
    local ok, saved = pcall(function()
        return (storage or cloudStore()):UpdateAsync(tostring(player.UserId), function(previous)
            if
                previous ~= nil
                and (
                    type(previous) ~= "table"
                    or (previous.schema ~= 1 and previous.schema ~= 2)
                    or (previous.revision or 0) ~= expected
                )
            then
                return nil
            end
            if previous == nil and expected ~= 0 then
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
    return true, "Pattern slots, beat shelf, workshop and progress saved."
end

function ProfileStore.restore(profile)
    if profile.saved == nil then
        return false, "There is no saved pattern to restore yet."
    end
    -- Discoveries are permanent within this play session; restoring never revokes them.
    Book.restoreWorking(profile, profile.saved)
    profile.finish = profile.saved.finish or "quay"
    profile.editVersion += 1
    local hasNewDiscoveries = false
    for id, collected in profile.unlocked do
        if collected and profile.saved.unlocked[id] ~= true then
            hasNewDiscoveries = true
        end
    end
    local savedQuest = Quest.sanitize(profile.saved.quest)
    local preserved = hasNewDiscoveries
        or not Rooms.equal(profile.room, Rooms.sanitize(profile.saved.room, profile))
        or profile.quest.accepted ~= savedQuest.accepted
        or profile.quest.completed ~= savedQuest.completed
    for index = 1, Book.ShelfCapacity do
        local entry = profile.shelf[index]
        local saved = profile.saved.shelf and profile.saved.shelf[index]
        if (if entry then entry.version else 0) ~= (if saved then saved.version else 0) then
            preserved = true
        end
    end
    if not preserved then
        profile.savedEditVersion = profile.editVersion
    end
    return true,
        "Saved pattern slots restored. Your shelf, discoveries and quest progress stay with you."
end
return ProfileStore
