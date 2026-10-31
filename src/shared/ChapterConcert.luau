-- Finite playback of one successfully saved immutable Finished Song revision.
-- Legacy checkpoint history survives; it is never a certificate for a new performance.
local Pattern = require(script.Parent.Pattern)
local Quay = require(script.Parent.QuayProgress)
local Music = require(script.Parent.QuayMusicEvidence)
local Chapter = {}
Chapter.Hints = {
    "Choose your Finished Song. We will hear it from its beginning to its last sound.",
    "Rhythm",
    "Support",
    "Space",
    "Return",
    "Variation",
    "Signature",
}

function Chapter.sanitize(raw)
    raw = if type(raw) == "table" then raw else {}
    local completed = raw.completed == true
    local result = {
        completed = completed,
        checkpoint = if completed
            then 6
            elseif Pattern.integer(raw.checkpoint, 0, 5) then raw.checkpoint
            else 0,
    }
    local performance = raw.performance
    if
        type(performance) == "table"
        and type(performance.songId) == "string"
        and Pattern.integer(performance.revision, 1, 1e12)
        and type(performance.duration) == "number"
        and performance.duration > 0
        and type(performance.endedAt) == "number"
    then
        result.performance = {
            songId = performance.songId,
            revision = performance.revision,
            duration = performance.duration,
            endedAt = performance.endedAt,
            localOnly = performance.localOnly == true,
        }
    end
    return result
end

function Chapter.equal(a, b)
    a, b = Chapter.sanitize(a), Chapter.sanitize(b)
    if a.completed ~= b.completed or a.checkpoint ~= b.checkpoint then
        return false
    end
    if (a.performance == nil) ~= (b.performance == nil) then
        return false
    end
    if a.performance then
        for key, value in a.performance do
            if b.performance[key] ~= value then
                return false
            end
        end
    end
    return true
end

function Chapter.start(profile, reference, now)
    if not Quay.readyForFinale(profile) then
        return nil, "Finish the neighbourhood route and select a ready Finished Song with Ronan."
    end
    local id = if type(reference) == "table" then reference.id else reference
    if id == nil then
        id = profile.selectedFinishedSongId
    end
    if type(id) ~= "string" then
        return nil, "Select a successfully saved Finished Song first."
    end
    if id ~= profile.selectedFinishedSongId then
        return nil, "Select this saved Finished Song revision before starting the evening."
    end
    local evidence, message = Music.finished(profile, id)
    if not evidence then
        return nil, message
    end
    if
        type(reference) == "table"
        and reference.revision
        and reference.revision ~= evidence.revision
    then
        return nil, "That song revision changed. Select its saved revision again."
    end
    return {
        id = evidence.id,
        revision = evidence.revision,
        title = evidence.song.title,
        schedule = evidence.schedule,
        epoch = 1,
        startedAt = now + 0.3,
        lastAt = now + 0.3,
        position = 0,
        duration = evidence.schedule.duration,
        endDuration = evidence.schedule.completeAt
            or (evidence.schedule.duration + (evidence.schedule.audioTailSeconds or 0)),
        paused = false,
        ended = false,
        localOnly = evidence.localOnly,
    }
end

function Chapter.tick(session, now)
    if session.ended or session.paused then
        return session.ended
    end
    local delta = math.max(0, now - session.lastAt)
    session.lastAt = math.max(session.lastAt, now)
    session.position = math.min(session.endDuration, session.position + delta)
    if session.position >= session.endDuration then
        session.ended, session.endedAt = true, now
    end
    return session.ended
end

function Chapter.act(session, action, _, now)
    Chapter.tick(session, now)
    if action == "Pause" and not session.ended and not session.paused then
        session.paused = true
        session.epoch += 1
        return true, "Paused. Progress is frozen; resume this same song from this position."
    elseif action == "Resume" and session.paused and not session.ended then
        session.paused = false
        session.lastAt = now
        session.startedAt = now - session.position
        session.epoch += 1
        return true, "Resumed the pinned song revision."
    end
    return false, "The arrangement plays as saved. Pause, resume or stop at any time."
end

function Chapter.summary(profile, session, open)
    local ledger = Chapter.sanitize(profile.chapter)
    local songs = {}
    local music = profile.saved and profile.saved.music
    for _, id in (music and music.finishedOrder) or {} do
        local song = music.finishedSongs[id]
        if song then
            local evidence, reason = Music.finished(profile, id)
            table.insert(songs, {
                id = id,
                revision = song.revision,
                title = song.title,
                ready = evidence ~= nil,
                reason = reason,
                duration = song.duration,
                localOnly = evidence and evidence.localOnly or song.localOnly == true,
            })
        end
    end
    local position = session and session.position or 0
    local section
    if session then
        for _, candidate in session.schedule.sections do
            if position >= candidate.at and position < candidate.endAt then
                section = candidate
            end
        end
    end
    local progress = if session then math.clamp(position / session.endDuration, 0, 1) else 0
    return {
        open = open == true,
        eligible = Quay.readyForFinale(profile),
        completed = ledger.completed,
        checkpoint = ledger.checkpoint,
        songs = songs,
        selectedFinishedSongId = profile.selectedFinishedSongId,
        finishedSongId = session and session.id,
        revision = session and session.revision,
        title = session and session.title,
        position = position,
        duration = session and session.endDuration or 0,
        progress = progress,
        section = section,
        paused = session and session.paused or false,
        ended = session and session.ended or false,
        localOnly = session and session.localOnly or false,
        hint = if session and session.ended
            then "Your song reached its actual end. The room has heard this evening."
            elseif session and session.paused then "Paused at the same musical position."
            elseif session then "Your finished arrangement is playing from beginning to end."
            else Chapter.Hints[1],
        cue = if session then Chapter.Hints[math.min(7, math.floor(progress * 6) + 2)] else nil,
        playback = session and not session.ended and not session.paused and {
            kind = "finished",
            id = session.id,
            revision = session.revision,
            schedule = session.schedule,
            startedAt = session.startedAt,
            epoch = session.epoch,
            position = position,
            paused = false,
            loop = false,
            performer = "YOUR FINISHED SONG",
            hosting = true,
        } or nil,
        reaction = if session and session.ended
            then 4
            elseif session then math.min(3, math.floor(progress * 4) + 1)
            elseif ledger.completed then 4
            else 0,
    }
end
return Chapter
