-- Shared interaction sight check. Decorations and walls block queries, effects do not.
local O = {}
function O.visible(origin, target, character, progress)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = true
    local ignored = if character then { character } else {}
    local delta = target.Position - origin
    if delta.Magnitude < 0.05 then
        return true
    end
    for _ = 1, 16 do
        params.FilterDescendantsInstances = ignored
        local hit = workspace:Raycast(origin, delta, params)
        if not hit then
            return true
        end
        local part = hit.Instance
        if part == target or part:IsDescendantOf(target) then
            return true
        end
        local associated = part:GetAttribute("InteractionTarget")
        if associated and associated == target:GetAttribute("QuayInteraction") then
            return true
        end
        local key = target:GetAttribute("QuayPersonalTarget")
        if key and part:GetAttribute("QuayPersonalTarget") == key then
            return true
        end
        local personal = part:GetAttribute("QuayPersonalTarget")
        local stowed = false
        if personal and progress then
            local field = if personal:sub(1, 4) == "dock" then "dock" else "market"
            stowed = progress[field] and progress[field][tonumber(personal:sub(-1))] == true
        end
        if
            stowed
            or part.LocalTransparencyModifier >= 0.95
            or (part.Transparency >= 0.95 and not part.CanCollide)
            or part:GetAttribute("NonOccluding")
        then
            table.insert(ignored, part)
        else
            return false
        end
    end
    return false
end
return O
