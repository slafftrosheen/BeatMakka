-- Guidance only. Completion is always owned by QuayDemoService / ChapterConcert.
local Objectives = {}
local Samples = require(script.Parent.SampleCatalog)
Objectives.Order = {}
Objectives.ById = {}
local entries = {
    { 0, "Meet the quay", "Meet Tori, or enter your own Roamer studio.", "P1" },
    { 1, "Room for music", "Stow the three marked dock crates.", "P1" },
    {
        2,
        "Rhythm in the metal",
        "Use ready Quay metal at four distinct rhythmic positions in a named sequence.",
        "P1",
    },
    {
        3,
        "A public set / optional",
        "Share a saved loop if you want. Solo progress never needs an audience or a Finished Song.",
        "P1",
    },
    {
        4,
        "The vent has a pulse",
        "Help Ivo: isolate power, clear the intake, restore power.",
        "P2",
    },
    {
        5,
        "One beat, two ways",
        "Save an original named sequence and a distinct musical variation.",
        "P2",
    },
    { 6, "Records remember", "Listen to Naya's records and match their musical roles.", "P3" },
    {
        7,
        "Keep your sound",
        "Save a Song Mode draft containing an owned saved sequence, then return to Naya.",
        "P3",
    },
    { 8, "The market is listening", "Help Sana stow the three stage cases.", "P3" },
    {
        9,
        "Signal, not noise",
        "Select a teaching bar; use ready I03 at ticks 0, 960, 1920, 2880. Return to Mica.",
        "P4",
    },
    { 10, "Light the breakwater", "Use the signal console after Mica hears your reply.", "P4" },
    {
        11,
        "Open the Lantern Room",
        "Meet Ronan and select a ready saved Finished Song after the neighbourhood route.",
        "finale",
    },
    {
        12,
        "The quay plays again",
        "Perform your pinned Finished Song revision from beginning to its actual end.",
        "finale",
    },
}
for _, row in entries do
    local id = string.format("NQ-Q%02d", row[1])
    table.insert(Objectives.Order, id)
    Objectives.ById[id] = {
        id = id,
        title = row[2],
        text = Samples.localDiscoveryText(row[3]),
        stop = row[4],
        optional = row[1] == 3,
    }
end
local regions = {
    P1 = { "NQ-Q01", "NQ-Q02" },
    P2 = { "NQ-Q04", "NQ-Q05" },
    P3 = { "NQ-Q06", "NQ-Q07", "NQ-Q08" },
    P4 = { "NQ-Q09", "NQ-Q10" },
    finale = { "NQ-Q11", "NQ-Q12" },
}
function Objectives.region(progress, stop)
    local tasks = regions[stop] or {}
    local count = 0
    for _, id in tasks do
        if progress.completed[id] then
            count += 1
        end
    end
    return count, #tasks
end
function Objectives.select(quay, preferred)
    if not quay then
        return nil
    end
    local commission = quay.commission
    local request = commission
        and require(script.Parent.QuayBeatCommissions).find(commission.active)
    if request and not preferred then
        local ready = false
        for _, sequence in commission.sequences do
            ready = ready or sequence.review.passed
        end
        local recipe = require(script.Parent.QuayFxRecipes).find(request.fx)
        return {
            id = "commission_" .. request.id,
            title = request.title,
            stop = request.host,
            target = if ready then request.host else "enter",
            text = if ready
                then "Return to " .. request.name .. ". Choose a named saved sequence and play it."
                else "Sounds → "
                    .. recipe.label
                    .. ". Two audible pads, four FX hits, "
                    .. request.low
                    .. "–"
                    .. request.high
                    .. " BPM. Save Sequence and wait for confirmation.",
        }
    end
    local q = quay.progress
    local id = if Objectives.ById[preferred] and not q.completed[preferred] then preferred else nil
    if not id then
        for _, candidate in Objectives.Order do
            if candidate ~= "NQ-Q03" and not q.completed[candidate] then
                id = candidate
                break
            end
        end
    end
    if not id then
        return nil
    end
    local definition = Objectives.ById[id]
    local target, text = definition.stop, definition.text
    if id == "NQ-Q01" or id == "NQ-Q08" then
        local field = if id == "NQ-Q01" then "dock" else "market"
        for index = 1, 3 do
            if not q[field][index] then
                target = field .. index
                break
            end
        end
    elseif id == "NQ-Q04" then
        target = if q.repair < 3 then "repair" .. (q.repair + 1) else "P2"
        text = ({
            "Isolate the power at control 1.",
            "Clear the intake at control 2.",
            "Restore power at control 3.",
        })[q.repair + 1] or definition.text
    elseif id == "NQ-Q10" then
        target = "radio"
    elseif id == "NQ-Q02" or id == "NQ-Q05" or id == "NQ-Q07" or id == "NQ-Q09" then
        local key = ({
            ["NQ-Q02"] = "metal",
            ["NQ-Q05"] = "variation",
            ["NQ-Q07"] = "draft",
            ["NQ-Q09"] = "reply",
        })[id]
        if (key == "metal" or key == "reply") and quay.collected and not quay.collected[key] then
            target = definition.stop
            text = if key == "metal"
                then "Meet Tori to collect Quay metal."
                else "Meet Mica to collect Helper chirp."
        elseif not quay.evidence[key] then
            target = "enter"
        else
            text = "Your music is ready to check. Return to "
                .. ({ P1 = "Tori", P2 = "Ivo", P3 = "Naya", P4 = "Mica" })[definition.stop]
                .. "."
        end
    end
    return {
        id = id,
        title = definition.title,
        text = Samples.localDiscoveryText(text),
        target = target,
        stop = definition.stop,
    }
end
return Objectives
