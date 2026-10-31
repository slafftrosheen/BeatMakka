-- Authored taste briefs, evaluated from saved sound settings, not microphone analysis.
local Recipes = require(script.Parent.QuayFxRecipes)
local Evidence = require(script.Parent.QuayMusicEvidence)
local C = {}
C.List = {
    {
        id = "dock",
        host = "P1",
        name = "Tori",
        title = "Echoes for the dock",
        fx = "quay_echo",
        low = 95,
        high = 135,
        thanks = "Those echoes leave room for the dock. That's our pulse!",
    },
    {
        id = "repair",
        host = "P2",
        name = "Ivo",
        title = "Workshop rhythm",
        fx = "quay_vent",
        low = 105,
        high = 145,
        thanks = "Roomy percussion, steady pace. Even the workshop has a groove.",
    },
    {
        id = "records",
        host = "P3",
        name = "Naya",
        title = "After-hours records",
        fx = "quay_lantern",
        low = 70,
        high = 105,
        thanks = "Slow and spacious. I'd keep that on for the evening.",
    },
    {
        id = "signal",
        host = "P4",
        name = "Mica",
        title = "Breakwater ident",
        fx = "quay_signal",
        low = 115,
        high = 155,
        thanks = "Tight repeats and a clear pulse. That's a signal worth keeping!",
    },
}
table.insert(C.List, {
    id = "dock_warm",
    host = "P1",
    name = "Tori",
    title = "Sunset dock remix",
    fx = "quay_echo",
    low = 85,
    high = 110,
    prerequisite = "dock",
    voice = "dock",
    tone = "warm",
    thanks = "Warm echoes for sunset. Keep that one on the quay!",
})
table.insert(C.List, {
    id = "repair_grit",
    host = "P2",
    name = "Ivo",
    title = "Grit in the gears",
    fx = "quay_vent",
    low = 105,
    high = 135,
    prerequisite = "repair",
    voice = "repair",
    tone = "drive",
    thanks = "That rough edge gives the workshop its own sound!",
})
function C.available(q, item)
    return Recipes.earned(q, Recipes.find(item.fx))
        and (not item.prerequisite or (q.commissions and q.commissions[item.prerequisite] == true))
end
function C.find(id)
    for _, item in C.List do
        if item.id == id then
            return item
        end
    end
end
function C.review(q, item, evidence)
    local recipe = Recipes.find(item.fx)
    local layers, fxHits, styleHits = 0, 0, 0
    local sequence = evidence and evidence.sequence
    local groups = {}
    for _, event in (evidence and evidence.schedule.events) or {} do
        local key = event.route.key
        if not groups[key] then
            groups[key] = { settings = event.settings, hits = 0 }
        end
        groups[key].hits += 1
    end
    for _, group in groups do
        local s, hits = group.settings, group.hits
        if
            s.gain >= 0.15
            and s.gate >= 0.25
            and s.finish - s.start >= 0.15
            and s.attack <= 0.15
            and s.sustain >= 0.3
            and hits > 0
        then
            layers += 1
            if
                math.abs(s.echo - recipe.echo) <= 0.08
                and math.abs(s.reverb - recipe.reverb) <= 0.08
                and math.abs(s.delay - math.clamp(60 / sequence.bpm * recipe.beats, 0.05, 1))
                    <= 0.04
            then
                fxHits = math.max(fxHits, hits)
                if
                    not item.tone
                    or (item.tone == "warm" and (s.tone or 0) <= -0.3)
                    or (item.tone == "drive" and (s.drive or 0) >= 0.2)
                then
                    styleHits = math.max(styleHits, hits)
                end
            end
        end
    end
    local checks = {
        {
            ok = C.available(q, item),
            label = recipe.label,
            fix = recipe.hint .. " to discover this FX.",
        },
        {
            ok = sequence ~= nil,
            label = "SAVED SEQUENCE",
            fix = "Save Sequence and wait for confirmation. Choose the named saved sequence to submit.",
        },
        {
            ok = sequence ~= nil and sequence.bpm >= item.low and sequence.bpm <= item.high,
            label = tostring(item.low) .. "–" .. tostring(item.high) .. " BPM",
            fix = "Try "
                .. tostring(item.low)
                .. "–"
                .. tostring(item.high)
                .. " BPM for this brief.",
        },
        {
            ok = layers >= 2,
            label = "2 AUDIBLE PADS",
            fix = "Add a second unmuted pad. Keep its gain, sustain and sample region audible.",
        },
        {
            ok = fxHits >= 4,
            label = "4 HITS + FX",
            fix = "Sounds → apply "
                .. recipe.label
                .. " to an audible pad with four hits. Save Sequence again.",
        },
    }
    table.insert(checks, {
        ok = not item.tone or styleHits >= 4,
        label = if item.tone == "warm"
            then "WARM TONE"
            elseif item.tone == "drive" then "DRIVE 20%+"
            else "YOUR STYLE",
        fix = if item.tone == "warm"
            then "Sounds > FX: turn Warm / Bright below -30% on your echo pad."
            else "Sounds > FX: add at least 20% Drive to your room pad. Save Sequence for the remix.",
    })
    local passed, hint = true, "Ready for your host."
    local cue = "success"
    for index, check in checks do
        if not check.ok then
            if passed then
                hint = check.fix
                cue = ({
                    "fx",
                    "save",
                    if sequence and sequence.bpm < item.low then "slow" else "fast",
                    "layers",
                    "fx",
                })[index] or "fx"
            end
            passed = false
        end
    end
    return { passed = passed, checks = checks, hint = hint, cue = cue }
end
function C.saved(profile, id)
    for _, sequence in Evidence.savedSequences(profile) do
        if sequence.id == id then
            return sequence
        end
    end
    return nil
end
return C
