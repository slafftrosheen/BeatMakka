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
        labels = { "COLLECT", "4 POSITIONS", "RETURN" }
        local key = if id == "NQ-Q02" then "metal" else "reply"
        done = if q.evidence[key] then 2 elseif q.collected and q.collected[key] then 1 else 0
        hint = if done == 0
            then objective.text
            elseif done == 2 then "Your beat is ready. Meet the marked host."
            elseif
                id == "NQ-Q02"
            then "Sequence → ready Quay metal. Add four distinct rhythmic positions."
            else "Sequence → selected teaching bar. Ready I03 at relative ticks 0, 960, 1920, 2880 only."
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
    return {
        labels = labels,
        done = done,
        hint = hint,
        key = (id or objective.target) .. ":" .. objective.target .. ":" .. tostring(done),
    }
end
return M
