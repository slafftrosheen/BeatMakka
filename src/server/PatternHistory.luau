-- Session-only, bounded edit history. Saved profiles keep their existing schema.
local Shared = game:GetService("ReplicatedStorage").Shared
local Pattern = require(Shared.Pattern)
local Book = require(Shared.BeatBook)
local History = {}
local LIMIT = 24

local function slot(profile)
    profile.editHistory = profile.editHistory or {}
    local index = profile.activeSlot
    profile.editHistory[index] = profile.editHistory[index] or { undo = {}, redo = {} }
    return profile.editHistory[index]
end

function History.capture(profile)
    return Pattern.sanitize(profile.pattern, profile.unlocked)
end

function History.record(profile, before, key)
    if Book.samePattern(before, profile.pattern) then
        return
    end
    local history = slot(profile)
    local now = os.clock()
    if not (key and history.key == key and now - (history.at or 0) < 0.4) then
        table.insert(history.undo, before)
        if #history.undo > LIMIT then
            table.remove(history.undo, 1)
        end
    end
    history.key, history.at, history.redo = key, now, {}
end

function History.restore(profile, redo)
    local history = slot(profile)
    local source = if redo then history.redo else history.undo
    if #source == 0 then
        return false
    end
    table.insert(if redo then history.undo else history.redo, History.capture(profile))
    profile.pattern = table.remove(source)
    profile.slots[profile.activeSlot] = profile.pattern
    history.key = nil
    profile.playing, profile.recording = false, false
    profile.epoch += 1
    return true
end

function History.summary(profile)
    local history = slot(profile)
    return { undo = #history.undo, redo = #history.redo, copiedPad = profile.copiedRowPad }
end

function History.clear(profile)
    profile.editHistory = nil
end

return History
