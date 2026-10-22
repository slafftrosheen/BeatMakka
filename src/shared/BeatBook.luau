local Pattern = require(script.Parent.Pattern)
local Book = { SlotCount = 4, ShelfCapacity = 6, SlotLabels = { "A", "B", "C", "D" } }

function Book.sanitizeSlots(raw, unlocked)
    local slots = {}
    for index = 1, Book.SlotCount do
        slots[index] = Pattern.sanitize(if type(raw) == "table" then raw[index] else nil, unlocked)
    end
    return slots
end

function Book.hasPlayableNotes(pattern)
    for pad = 1, Pattern.Pads do
        if not pattern.muted[pad] then
            for _, enabled in pattern.rows[pad] do
                if enabled then
                    return true
                end
            end
        end
    end
    return false
end

function Book.hasNotes(profile)
    for _, pattern in profile.slots do
        if Pattern.hasNotes(pattern) then
            return true
        end
    end
    return false
end

function Book.select(profile, index)
    if not Pattern.integer(index, 1, Book.SlotCount) then
        return false
    end
    -- Retain the current projection even when a caller replaced the pattern table.
    profile.slots[profile.activeSlot] = profile.pattern
    profile.activeSlot = index
    profile.pattern = profile.slots[index]
    return true
end

function Book.restoreWorking(profile, data)
    profile.slots = Book.sanitizeSlots(data.slots, profile.unlocked)
    if data.schema == 1 then
        profile.slots[1] = Pattern.sanitize(data.pattern, profile.unlocked)
    end
    profile.activeSlot = if Pattern.integer(data.activeSlot, 1, Book.SlotCount)
        then data.activeSlot
        else 1
    profile.pattern = profile.slots[profile.activeSlot]
end

function Book.sanitizeShelf(raw, unlocked)
    local shelf = {}
    for index = 1, Book.ShelfCapacity do
        local entry = if type(raw) == "table" then raw[index] else nil
        if type(entry) == "table" and Pattern.integer(entry.version, 1, 1e12) then
            shelf[index] = {
                version = entry.version,
                activeSlot = if Pattern.integer(entry.activeSlot, 1, Book.SlotCount)
                    then entry.activeSlot
                    else 1,
                slots = Book.sanitizeSlots(entry.slots, unlocked),
            }
        else
            shelf[index] = false
        end
    end
    return shelf
end

function Book.capture(profile)
    profile.slots[profile.activeSlot] = profile.pattern
    return {
        slots = Book.sanitizeSlots(profile.slots, profile.unlocked),
        activeSlot = profile.activeSlot,
        shelf = Book.sanitizeShelf(profile.shelf, profile.unlocked),
    }
end

function Book.store(profile, index, expectedVersion)
    if
        not Pattern.integer(index, 1, Book.ShelfCapacity)
        or not Pattern.integer(expectedVersion, 0, 1e12)
    then
        return false, "Choose a valid shelf position."
    end
    local previous = profile.shelf[index]
    local version = if previous then previous.version else 0
    if version ~= expectedVersion then
        return false, "That shelf position changed. Select it again before replacing it."
    end
    if version >= 1e12 then
        return false, "This shelf position cannot be replaced again."
    end
    local snapshot = Book.capture(profile)
    local playable = false
    for _, pattern in snapshot.slots do
        playable = playable or Book.hasPlayableNotes(pattern)
    end
    if not playable then
        return false, "Add a step to an unmuted pad before saving a beat."
    end
    profile.shelf[index] =
        { version = version + 1, slots = snapshot.slots, activeSlot = snapshot.activeSlot }
    return true, string.format("Beat %02d stored on your shelf.", index)
end

function Book.load(profile, index, expectedVersion)
    if not Pattern.integer(index, 1, Book.ShelfCapacity) then
        return false, "Choose a valid shelf position."
    end
    local entry = profile.shelf[index]
    if not entry then
        return false, "That shelf position is empty."
    end
    if not Pattern.integer(expectedVersion, 1, 1e12) or expectedVersion ~= entry.version then
        return false, "That beat changed. Select it again before loading it."
    end
    Book.restoreWorking(profile, entry)
    return true, string.format("Beat %02d loaded into slots A-D. Your shelf is unchanged.", index)
end

function Book.samePattern(a, b)
    if a.bpm ~= b.bpm then
        return false
    end
    for pad = 1, Pattern.Pads do
        if a.assignments[pad] ~= b.assignments[pad] or a.muted[pad] ~= b.muted[pad] then
            return false
        end
        for step = 1, Pattern.Steps do
            if a.rows[pad][step] ~= b.rows[pad][step] then
                return false
            end
        end
    end
    return true
end

function Book.savedPattern(profile, pattern)
    local shelf = profile.saved and profile.saved.shelf
    if not shelf then
        return false
    end
    for index = 1, Book.ShelfCapacity do
        local entry = shelf[index]
        if entry then
            for _, candidate in entry.slots do
                if Book.samePattern(candidate, pattern) then
                    return true
                end
            end
        end
    end
    return false
end

function Book.summary(profile)
    local slots, shelf = {}, {}
    for index, pattern in profile.slots do
        slots[index] = {
            label = Book.SlotLabels[index],
            hasNotes = Pattern.hasNotes(pattern),
            bpm = pattern.bpm,
        }
    end
    for index = 1, Book.ShelfCapacity do
        local entry = profile.shelf[index]
        local populated = 0
        if entry then
            for _, pattern in entry.slots do
                if Pattern.hasNotes(pattern) then
                    populated += 1
                end
            end
        end
        local saved = profile.saved and profile.saved.shelf and profile.saved.shelf[index]
        shelf[index] = {
            exists = entry ~= false and entry ~= nil,
            version = if entry then entry.version else 0,
            populated = populated,
            saved = entry ~= false
                and entry ~= nil
                and saved ~= false
                and saved ~= nil
                and saved.version == entry.version,
        }
    end
    return { activeSlot = profile.activeSlot, slots = slots, shelf = shelf }
end

return Book
