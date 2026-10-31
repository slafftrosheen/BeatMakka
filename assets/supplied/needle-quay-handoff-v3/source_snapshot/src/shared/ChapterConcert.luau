-- Arrangement of an owned saved snapshot; no working-pattern or audience mutation.
local Pattern = require(script.Parent.Pattern)
local Book = require(script.Parent.BeatBook)
local Samples = require(script.Parent.SampleCatalog)
local Missions = require(script.Parent.NeighborhoodMissions)
local Quay = require(script.Parent.QuayProgress)
local Chapter = {
    Hints = {
        "Choose an audible pad to introduce your rhythm.",
        "Add a different low or supporting part.",
        "Make space: take the supporting part out.",
        "Bring your supporting part back.",
        "Switch to a different saved pattern.",
        "Feature a collected sound in this pattern. Switch again if needed.",
        "Play this last loop to finish the section. Your music can keep going.",
    },
}

function Chapter.sanitize(raw)
    raw = if type(raw) == "table" then raw else {}
    local completed = raw.completed == true
    return {
        completed = completed,
        checkpoint = if completed
            then 6
            elseif Pattern.integer(raw.checkpoint, 0, 5) then raw.checkpoint
            else 0,
    }
end

function Chapter.equal(a, b)
    a, b = Chapter.sanitize(a), Chapter.sanitize(b)
    return a.completed == b.completed and a.checkpoint == b.checkpoint
end

local function audible(pattern, pad)
    if pattern.muted[pad] then
        return false
    end
    for _, on in pattern.rows[pad] do
        if on then
            return true
        end
    end
    return false
end

local function discovery(pattern, pad)
    local sample = Samples.ById[pattern.assignments[pad]]
    return sample and sample.discovery ~= nil
end

local function parts(pattern, ordinaryOnly)
    local n = 0
    for pad = 1, 16 do
        if audible(pattern, pad) and (not ordinaryOnly or not discovery(pattern, pad)) then
            n += 1
        end
    end
    return n
end

function Chapter.start(profile, shelf, now)
    if
        not (Missions.summary(profile).courtReady or Quay.readyForFinale(profile))
        or not Pattern.integer(shelf, 1, 6)
    then
        return nil,
            "Prepare the neighborhood jobs and Mica's first courtyard set before this concert."
    end
    local entry = profile.saved and profile.saved.shelf and profile.saved.shelf[shelf]
    if not entry then
        return nil, "Choose a shelf beat that was successfully saved."
    end
    local slots = Book.sanitizeSlots(entry.slots, profile.unlocked)
    local first, varied, collected = nil, false, false
    for index, pattern in slots do
        if not first and parts(pattern) >= 2 then
            first = index
        end
        for pad = 1, 16 do
            collected = collected
                or (parts(pattern, true) > 0 and audible(pattern, pad) and discovery(pattern, pad))
        end
    end
    if first then
        for index, pattern in slots do
            varied = varied
                or (
                    index ~= first
                    and parts(pattern, true) > 0
                    and not Book.samePattern(pattern, slots[first])
                )
        end
    end
    if not first or not varied or not collected then
        return nil,
            "Save two audible parts, a different playable pattern, and a pattern layering a collected sound with another part. Your choice of notes and style."
    end
    local pattern = Pattern.sanitize(slots[first], profile.unlocked)
    for pad = 1, 16 do
        pattern.muted[pad] = true
    end
    return {
        slots = slots,
        unlocked = table.clone(profile.unlocked),
        slot = first,
        pattern = pattern,
        phase = 0,
        earned = 0,
        epoch = 1,
        startedAt = now,
        duration = Pattern.Steps * Pattern.stepDuration(pattern.bpm),
    }
end

local function restart(session, now)
    session.epoch += 1
    session.startedAt = now + 0.15
    session.duration = Pattern.Steps * Pattern.stepDuration(session.pattern.bpm)
end

function Chapter.act(session, action, value, now)
    if session.phase > 0 and session.earned < session.phase then
        return false, "Let this full loop finish before the next musical action."
    end
    local base = session.slots[session.slot]
    if action == "Rhythm" and session.phase == 0 then
        if not Pattern.integer(value, 1, 16) or not audible(base, value) then
            return false, "Choose an audible pad from your saved pattern."
        end
        session.rhythm = value
        session.pattern.muted[value] = false
        session.phase = 1
    elseif action == "Support" and session.phase == 1 then
        if
            not Pattern.integer(value, 1, 16)
            or value == session.rhythm
            or not audible(base, value)
        then
            return false, "Choose a different audible low or supporting part."
        end
        session.support = value
        session.pattern.muted[value] = false
        session.phase = 2
    elseif action == "Break" and session.phase == 2 then
        session.pattern.muted[session.support] = true
        session.phase = 3
    elseif action == "Return" and session.phase == 3 then
        session.pattern.muted[session.support] = false
        session.phase = 4
    elseif action == "Switch" and (session.phase == 4 or session.phase == 5) then
        if
            not Pattern.integer(value, 1, 4)
            or value == session.slot
            or parts(session.slots[value], true) == 0
            or Book.samePattern(base, session.slots[value])
        then
            return false, "Choose a different saved pattern with an audible non-collected part."
        end
        session.slot = value
        session.pattern = Pattern.sanitize(session.slots[value], session.unlocked)
        for pad = 1, 16 do
            if discovery(session.pattern, pad) then
                session.pattern.muted[pad] = true
            end
        end
        session.phase = 5
        session.earned = math.min(session.earned, 4)
    elseif action == "Feature" and session.phase == 5 then
        if
            not Pattern.integer(value, 1, 16)
            or not audible(base, value)
            or not discovery(base, value)
        then
            return false, "Choose a saved, unmuted collected-sound pad; switch pattern if needed."
        end
        session.pattern.muted[value] = false
        session.phase = 6
    else
        return false, "Follow the current musical action, or stop the set at any time."
    end
    restart(session, now)
    return true, Chapter.Hints[session.phase + 1]
end

function Chapter.tick(session, now)
    if session.phase > 0 and now >= session.startedAt + session.duration then
        session.earned = math.max(session.earned, session.phase)
    end
    return session.earned
end

function Chapter.summary(profile, session, open)
    local ledger = Chapter.sanitize(profile.chapter)
    local phase = if session then session.phase else 0
    return {
        open = open == true,
        eligible = Missions.summary(profile).courtReady or Quay.readyForFinale(profile),
        checkpoint = ledger.checkpoint,
        completed = ledger.completed,
        phase = phase,
        waiting = session ~= nil and session.earned < phase,
        hint = if session and session.earned == 6
            then "Section complete. Other chapters are still ahead. Stop or keep playing your set."
            elseif session then Chapter.Hints[phase + 1]
            else "Choose a saved shelf beat. Starting a new set keeps earned section progress.",
        slot = session and session.slot,
        base = session and session.slots[session.slot],
        playback = if session and phase > 0
            then {
                pattern = session.pattern,
                startedAt = session.startedAt,
                epoch = session.epoch,
                performer = "YOUR CHAPTER SET",
                hosting = true,
            }
            else nil,
        reaction = if session
            then (if session.earned == 6
                then 4
                elseif phase >= 5 then 3
                elseif phase >= 2 then 2
                else phase)
            else (if ledger.checkpoint == 6
                then 4
                elseif ledger.checkpoint >= 5 then 3
                elseif ledger.checkpoint >= 2 then 2
                else ledger.checkpoint),
    }
end

return Chapter
