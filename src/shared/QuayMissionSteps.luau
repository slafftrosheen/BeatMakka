local M = {}
function M.project(q, objective)
    local p = q.progress
    local id = objective.id
    local labels = { "FIND", "PLAY", "RETURN" }
    local done = 0
    local hint = objective.text
    if id and id:sub(1, 11) == "commission_" then
        labels = { "FX + BEAT", "SAVE SEQUENCE", "PLAY FOR HOST" }
        done = if objective.target ~= "enter" then 2 else 0
    elseif id == "NQ-Q01" or id == "NQ-Q08" then
        labels = { "CASE 1", "CASE 2", "CASE 3" }
        local field = if id == "NQ-Q01" then p.dock else p.market
        for _, hit in field do
            if hit then
                done += 1
            end
        end
        hint = "Follow the amber marker. Interact with the next glowing case."
    elseif id == "NQ-Q04" then
        labels = { "POWER", "CLEAR", "RESTART" }
        done = p.repair
        hint = ({ "Switch off control 1.", "Clear control 2 next.", "Restart at control 3." })[done + 1]
            or "Vent restored."
    elseif id == "NQ-Q06" then
        labels = { "RECORD 1", "RECORD 2", "RECORD 3" }
        done = p.sort
        hint = "Meet Naya. Listen to the record, then choose its musical role."
    elseif id == "NQ-Q02" or id == "NQ-Q09" then
        labels = { "COLLECT", if id == "NQ-Q02" then "2 POSITIONS + SAVE" else "2 VARIATIONS + SAVE", "RETURN" }
        local key = if id == "NQ-Q02" then "metal" else "reply"
        done = if q.evidence[key] then 2 elseif q.collected and q.collected[key] then 1 else 0
        hint = if done == 0
            then objective.text
            elseif done == 2 then "Your beat is ready. Meet the marked host."
            elseif
                id == "NQ-Q02"
            then "Save a named sequence with audible Quay metal on two different positions."
            else "Save two personal Helper chirp rhythms. Echo practice is optional; complete the earlier sound hunts too."
    elseif id == "NQ-Q05" or id == "NQ-Q07" then
        labels = { "MAKE", if id == "NQ-Q07" then "SAVE DRAFT" else "SAVE SEQUENCE", "RETURN" }
        done = if q.evidence[if id == "NQ-Q05" then "variation" else "draft"] then 2 else 0
        hint = if done == 2
            then "Saved and ready. Return to your host."
            elseif
                id == "NQ-Q05"
            then "Save Sequence for an original and a distinct audible musical variation."
            else "Song → add an owned saved ready sequence → Save Draft. Finish later."
    elseif id == "NQ-Q10" then
        labels = { "REPLY", "SIGNAL", "LIGHT" }
        done = if p.completed["NQ-Q09"] then 1 else 0
        hint = "After Mica accepts your reply, interact with the marked signal console."
    end
    local compact = {
        ["SAVE SEQUENCE"] = "SAVE", ["SAVE DRAFT"] = "DRAFT",
        ["2 POSITIONS + SAVE"] = "2 HITS", ["2 VARIATIONS + SAVE"] = "2 LOOPS",
        ["RECORD 1"] = "RECORD 1", ["RECORD 2"] = "RECORD 2", ["RECORD 3"] = "RECORD 3",
        ["FX + BEAT"] = "FX + BEAT",
    }
    local short, icons = {}, {}
    for index, label in labels do
        short[index] = compact[label] or label
        icons[index] = if label:find("SAVE", 1, true) then "save"
            elseif label:find("RECORD", 1, true) then "disc"
            elseif label:find("CASE", 1, true) then "crate"
            elseif label == "FIND" then "route"
            elseif label == "RETURN" then "people"
            elseif label == "COLLECT" then "discovery"
            elseif label == "POWER" or label == "RESTART" or label == "SIGNAL" or label == "LIGHT" then "lamp"
            else "pads"
    end
    local action = if done >= #labels then "Ready to return"
        elseif id == "NQ-Q02" and done == 1 then "Place metal at two positions, then save"
        elseif id == "NQ-Q09" and done == 1 then "Save two different chirp rhythms"
        elseif done == 2 and labels[3] == "RETURN" then "Return to your host"
        elseif id and id:sub(1, 11) == "commission_" then (if done == 2 then "Play your saved sequence for the host" else "Make the requested FX beat, then save")
        elseif id == "NQ-Q00" then "Meet Tori or open your Roamer"
        elseif id == "NQ-Q11" then "Meet Ronan with a saved Finished Song"
        elseif id == "NQ-Q12" then "Play your Finished Song through its ending"
        elseif id == "NQ-Q05" then "Save your original and a changed variation"
        elseif id == "NQ-Q07" then "Add a saved loop in Song, then Save Draft"
        elseif id == "NQ-Q04" then ({ "POWER OFF", "CLEAR INTAKE", "RESTORE POWER" })[done + 1]
        elseif id == "NQ-Q01" or id == "NQ-Q08" then "Stow the next marked case"
        elseif id == "NQ-Q06" then "Listen, then choose the record's role"
        elseif id == "NQ-Q10" then "Use the signal after Mica accepts your reply"
        else short[math.clamp(done + 1, 1, #short)]
    return {
        labels = labels,
        shortLabels = short, icons = icons, action = action,
        done = done,
        hint = hint,
        key = (id or objective.target) .. ":" .. objective.target .. ":" .. tostring(done),
    }
end
return M
