local Pattern = require(script.Parent.Pattern)
local Catalog = require(script.Parent.SampleCatalog)
local Content = require(script.Parent.ContentIds)
local Jam = { Lead = 0.75, MaxPads = 4, TrackGain = 0.05, Voices = 2 }
-- Wire slots are always string-keyed maps. RemoteEvents convert sparse numeric
-- keys to strings; dense arrays would change shape when either owner leaves.

function Jam.capture(raw, unlocked, expectedPack)
    local p = Pattern.sanitize(raw, unlocked)
    local mask, count, pack = table.create(16, false), 0, nil
    for pad = 1, 16 do
        if not p.muted[pad] and table.find(p.rows[pad], true) then
            local sample = Catalog.ById[p.assignments[pad]]
            local kit = sample and Catalog.PackById[sample.pack]
            if not kit or not kit.key then
                return nil, "Choose a fully uploaded style kit for your audible pads."
            end
            if (pack and pack ~= kit.id) or (expectedPack and expectedPack ~= kit.id) then
                return nil, "Both tracks need the same style kit and key."
            end
            for _, sound in kit.samples do
                if not Pattern.integer(Content.Audio[sound.id], 1, 9007199254740991) then
                    return nil, "This kit is still awaiting uploads. Choose a complete kit."
                end
            end
            pack, mask[pad], count = kit.id, true, count + 1
            if count > Jam.MaxPads then
                return nil, "Use at most four audible pads per jam track; mute the others."
            end
        end
    end
    if count == 0 then
        return nil, "Add a note on an unmuted style pad before joining."
    end
    return { pattern = p, mask = mask, pack = pack }
end

function Jam.boundary(anchor, bpm, now)
    local bar = Pattern.stepDuration(bpm) * 16
    return anchor + math.max(0, math.floor((now + Jam.Lead - anchor) / bar) + 1) * bar
end

function Jam.request(packet, generation, revision, now)
    return type(packet) == "table"
        and packet.generation == generation
        and packet.revision == revision
        and type(packet.at) == "number"
        and packet.at == packet.at
        and packet.at >= now - 0.35
        and packet.at <= now + 0.05
end

-- Both server and renderer resolve proposals against the original clock. The
-- renderer never waits for a boundary broadcast to begin an already queued bar.
function Jam.resolve(session, now)
    local bpm, anchor = session.bpm, session.anchor
    if session.tempo and now >= session.tempo.applyAt then
        bpm, anchor = session.tempo.bpm, session.tempo.applyAt
    end
    local tracks = {}
    for slot = 1, 2 do
        local track, pending = session.tracks[tostring(slot)], session.pending[tostring(slot)]
        if track then
            tracks[slot] = {
                ownerUserId = track.ownerUserId,
                version = track.version,
                snapshot = track.snapshot,
                sinceAt = track.sinceAt,
            }
            if pending and now >= pending.applyAt then
                tracks[slot].snapshot, tracks[slot].version = pending.snapshot, pending.version
                tracks[slot].sinceAt = pending.applyAt
            end
        end
    end
    return bpm, anchor, tracks
end

return Jam
