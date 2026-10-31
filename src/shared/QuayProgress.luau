-- Additive schema-2 field. No client award flags, genre locks or global restoration.
local Music = require(script.Parent.QuayMusicEvidence)
local Pattern = require(script.Parent.Pattern)
local Games = require(script.Parent.QuayStreetGames)
local Commissions = require(script.Parent.QuayBeatCommissions)
local Life = require(script.Parent.QuayLifeCatalog)
local Quay = {}
Quay.Order = {}
for i = 0, 12 do
    table.insert(Quay.Order, string.format("NQ-Q%02d", i))
end

function Quay.sanitize(raw)
    raw = if type(raw) == "table" then raw else {}
    local result =
        { parking = "P1", completed = {}, dock = {}, market = {}, side = {}, repair = 0, sort = 0 }
    result.commissions = {}
    result.life = Life.sanitize(raw.life)
    result.commission = if Commissions.find(raw.commission) then raw.commission else nil
    for _, item in Commissions.List do
        result.commissions[item.id] = type(raw.commissions) == "table"
            and raw.commissions[item.id] == true
    end
    for _, id in Games.Order do
        result.side[id] = type(raw.side) == "table" and raw.side[id] == true
    end
    if raw.parking == "P2" or raw.parking == "P3" or raw.parking == "P4" then
        result.parking = raw.parking
    end
    for _, id in Quay.Order do
        result.completed[id] = type(raw.completed) == "table" and raw.completed[id] == true
    end
    for i = 1, 3 do
        result.dock[i] = type(raw.dock) == "table" and raw.dock[i] == true
        result.market[i] = type(raw.market) == "table" and raw.market[i] == true
    end
    for _, key in { "repair", "sort" } do
        result[key] = if Pattern.integer(raw[key], 0, 3) then raw[key] else 0
    end
    return result
end

function Quay.equal(a, b)
    a, b = Quay.sanitize(a), Quay.sanitize(b)
    if not Life.equal(a.life, b.life) then
        return false
    end
    if a.commission ~= b.commission then
        return false
    end
    for _, item in Commissions.List do
        if a.commissions[item.id] ~= b.commissions[item.id] then
            return false
        end
    end
    for _, id in Games.Order do
        if a.side[id] ~= b.side[id] then
            return false
        end
    end
    if a.parking ~= b.parking or a.repair ~= b.repair or a.sort ~= b.sort then
        return false
    end
    for _, id in Quay.Order do
        if a.completed[id] ~= b.completed[id] then
            return false
        end
    end
    for i = 1, 3 do
        if a.dock[i] ~= b.dock[i] or a.market[i] ~= b.market[i] then
            return false
        end
    end
    return true
end

function Quay.rhythm(sequenceEvidence, discoveryId, bar)
    local result, count = {}, 0
    for tick in (sequenceEvidence and sequenceEvidence.positions[discoveryId]) or {} do
        if not bar or (tick >= (bar - 1) * 3840 and tick < bar * 3840) then
            result[if bar then tick - (bar - 1) * 3840 else tick] = true
            count += 1
        end
    end
    return result, count
end

function Quay.evidence(profile)
    local project = profile.music and profile.music.project
    local savedMusic = profile.saved and profile.saved.music
    local unlockedKey = tostring(profile.unlocked.I01)
        .. tostring(profile.unlocked.I02)
        .. tostring(profile.unlocked.I03)
    local cache = profile.quayMusicEvidence
    if
        cache
        and cache.project == project
        and cache.revision == (project and project.revision)
        and cache.savedMusic == savedMusic
        and cache.unlockedKey == unlockedKey
        and cache.sequenceId == profile.sequenceId
        and cache.teachingBar == profile.teachingBar
        and cache.finishedId == profile.selectedFinishedSongId
    then
        return cache.result
    end
    local metal, reply, metalSteps = false, false, 0
    for _, id in (project and project.sequenceOrder) or {} do
        local sequence = Music.sequence(project, id, profile.unlocked)
        if sequence then
            local _, count = Quay.rhythm(sequence, "I01")
            metalSteps = math.max(metalSteps, count)
            metal = metal or count >= 4
            if id == profile.sequenceId then
                local positions, hits = Quay.rhythm(sequence, "I03", profile.teachingBar or 1)
                reply = hits == 4
                    and positions[0]
                    and positions[960]
                    and positions[1920]
                    and positions[2880]
            end
        end
    end
    local saved, savedProject = Music.savedSequences(profile)
    local signatures, variation = {}, false
    for _, sequence in saved do
        signatures[sequence.signature] = true
    end
    local distinct = 0
    for _ in signatures do
        distinct += 1
    end
    variation = distinct >= 2
    local draftSaved = false
    for _, id in (savedProject and savedProject.draftOrder) or {} do
        local draft = savedProject.drafts[id]
        if draft and (draft.savedRevision or 0) > 0 and draft.savedRevision == draft.revision then
            for _, step in draft.steps or {} do
                local owned = savedProject.sequences[step.sequenceId]
                if
                    owned
                    and (owned.savedRevision or 0) > 0
                    and owned.savedRevision == owned.revision
                    and Music.sequence(savedProject, step.sequenceId, profile.unlocked)
                then
                    draftSaved = true
                end
            end
        end
    end
    local finished = profile.selectedFinishedSongId
        and Music.finished(profile, profile.selectedFinishedSongId)
    local result = {
        metal = metal and profile.unlocked.I01 == true,
        metalSteps = metalSteps,
        reply = reply == true and profile.unlocked.I03 == true,
        saved = #saved > 0,
        variation = variation,
        draft = draftSaved,
        finished = finished ~= nil and finished ~= false,
        teachingBar = profile.teachingBar or 1,
    }
    profile.quayMusicEvidence = {
        project = project,
        revision = project and project.revision,
        savedMusic = savedMusic,
        unlockedKey = unlockedKey,
        sequenceId = profile.sequenceId,
        teachingBar = profile.teachingBar,
        finishedId = profile.selectedFinishedSongId,
        result = result,
    }
    return result
end

function Quay.readyForFinale(profile)
    local completed = Quay.sanitize(profile.quay).completed
    for _, n in { 0, 1, 2, 4, 5, 6, 7, 8, 9, 10, 11 } do
        if not completed[string.format("NQ-Q%02d", n)] then
            return false
        end
    end
    return true
end
return Quay
