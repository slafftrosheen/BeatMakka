local Objectives = require(script.Parent.QuayObjectives)
local Steps = require(script.Parent.QuayMissionSteps)
local H = {}
-- Preserve original recording metadata as provenance; these cues use revised
-- text only until a separately approved replacement recording exists.
H.TextOnly =
    { metal = true, chirp = true, variation = true, save = true, finale = true, fx_done = true }
function H.copy(cue, state)
    if cue == "metal" then
        return "Use ready Quay metal at four distinct rhythmic positions in your named sequence."
    end
    if cue == "chirp" then
        return "Select your teaching bar. Use ready Helper chirp at relative ticks 0, 960, 1920 and 2880."
    end
    if cue == "variation" then
        return "Keep your original sequence. Save a musically distinct variation with another name."
    end
    if cue == "save" then
        local active = state
            and state.quay
            and state.quay.commission
            and state.quay.commission.active
        return if active
            then "Save Sequence, wait for confirmation, then choose that named sequence for your host."
            else "In Song Mode, add an owned saved ready sequence and Save Draft. You can finish the song later."
    end
    if cue == "finale" then
        return "Choose your saved ready Finished Song. The Lantern Room will hear it from beginning to actual end."
    end
    if cue == "fx_done" then
        return "Your pad sound has changed. Save Sequence to keep this musical revision."
    end
    return nil
end
H.Workshop = {
    metal = true,
    chirp = true,
    variation = true,
    save = true,
    fx_select = true,
    fx_apply = true,
    fx_audition = true,
    fx_done = true,
}
H.Tutorial = { fx_select = true, fx_apply = true, fx_audition = true, fx_done = true }
H.Discoveries = {
    quay_echo = "fx_echo",
    quay_vent = "fx_vent",
    quay_lantern = "fx_lantern",
    quay_signal = "fx_signal",
}
function H.current(state)
    local q = state and state.quay
    local o = q and Objectives.select(q)
    if not o then
        return nil, nil
    end
    local phase = Steps.project(q, o)
    local key = phase.key .. ":" .. tostring(state.station ~= nil)
    if o.id and o.id:sub(1, 11) == "commission_" then
        return (if state.station
            then (if phase.done == 2 then "save" else "fx_select")
            elseif phase.done == 2 then "return_host"
            else "route"),
            key
    end
    if state.station then
        if
            phase.done == 2
            or (
                q.collected
                and (
                    (o.id == "NQ-Q02" and not q.collected.metal)
                    or (o.id == "NQ-Q09" and not q.collected.reply)
                )
            )
        then
            return nil, key
        end
        return ({
            ["NQ-Q02"] = "metal",
            ["NQ-Q09"] = "chirp",
            ["NQ-Q05"] = "variation",
            ["NQ-Q07"] = "save",
        })[o.id],
            key
    end
    if
        phase.done == 2
        and (o.id == "NQ-Q02" or o.id == "NQ-Q09" or o.id == "NQ-Q05" or o.id == "NQ-Q07")
    then
        return "return_host", key
    end
    if o.target == "enter" then
        return "route", key
    end
    if o.id == "NQ-Q01" or o.id == "NQ-Q08" then
        return "cases", key
    end
    if o.id == "NQ-Q04" then
        return ({ "power", "clear", "restart" })[q.progress.repair + 1], key
    end
    if o.id == "NQ-Q06" then
        return "records", key
    end
    if o.stop == "finale" then
        return "finale", key
    end
    return "meet", key
end
return H
