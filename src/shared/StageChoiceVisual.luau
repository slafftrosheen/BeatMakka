-- Read-only pictures from the exact resolved set schedule. No source edits or audio playback.
local Set = require(script.Parent.StreetSet)
local Visual = {}
function Visual.matches(review, choice, mode)
    local ref = review and review.ref
    return ref ~= nil and choice ~= nil and ref.kind == choice.kind
        and ref.id == choice.id and ref.revision == choice.revision and review.mode == mode
end
function Visual.from(prepared)
    local pattern, roles = table.create(16, false), {}
    for _, event in prepared.schedule.events do
        roles[Set.role(event)] = true
        if event.tick < 3840 then pattern[math.floor(event.tick / 240) + 1] = true end
    end
    return { pattern = pattern, roles = roles, bars = prepared.schedule.totalBars,
        duration = prepared.duration, localOnly = prepared.localOnly == true }
end
return Visual
