-- Reuse local character art for generic passers-by; no NPC AI/network ownership cost.
local Life = {}
local Style = require(game.ReplicatedStorage.Shared.QuayResidentStyle)
function Life.build(scene)
    local templates = game.ServerStorage.AssetLibrary
    local seed = Random.new():NextInteger(1, 1000000)
    local rng = Random.new(seed)
    scene.root:SetAttribute("ResidentSessionSeed", seed)
    local appearances =
        { "NQ-NPC-NELL", "NQ-NPC-IVO", "NQ-NPC-NAYA", "NQ-NPC-TORI", "NQ-NPC-SANA", "NQ-NPC-RONAN" }
    local rows = {
        { "NQ-NPC-NELL", -70, 124, { { 0, 0, 0 }, { 24, 0, 0 }, { 24, 0, 5 }, { 0, 0, 5 } } },
        { "NQ-NPC-IVO", 10, 124, { { 0, 0, 0 }, { 28, 0, 0 }, { 28, 0, 5 }, { 0, 0, 5 } } },
        { "NQ-NPC-NAYA", 108, 124, { { 0, 0, 0 }, { 25, 0, 0 }, { 25, 0, 5 }, { 0, 0, 5 } } },
        { "NQ-NPC-TORI", 61, -27, { { 0, 0, 0 }, { 0, 0, 49 }, { 5, 0, 49 }, { 5, 0, 0 } } },
        { "NQ-NPC-NELL", -77, -88, { { 0, 0, 0 }, { 0, 0, -27 }, { 6, 0, -27 }, { 6, 0, 0 } } },
        { "NQ-NPC-NAYA", -28, 121, { { 0, 0, 0 }, { 17, 0, 0 }, { 17, 0, 6 }, { 0, 0, 6 } } },
        { "NQ-NPC-IVO", 29, 35, nil },
        { "NQ-NPC-TORI", 75, 117, nil },
        { "NQ-NPC-NELL", -39, 116, nil, "chat", 0 },
        { "NQ-NPC-NAYA", -39, 112, nil, "chat", 180 },
        { "NQ-NPC-TORI", 48, -7, nil, "browse", 0 },
        { "NQ-NPC-NELL", 80, 21, nil, "browse", 0 },
        { "NQ-NPC-IVO", -105, -113, nil, "repair", 90 },
        { "NQ-NPC-NAYA", 115, 126, { { 0, 0, 0 }, { 14, 0, 0 }, { 14, 0, 4 }, { 0, 0, 4 } } },
        { "NQ-NPC-TORI", 54, 60, nil, "chat", 0 },
        { "NQ-NPC-NAYA", 64, 60, nil, "chat", 0 },
    }
    for i, row in rows do
        local characterId = appearances[rng:NextInteger(1, #appearances)]
        local source = templates:FindFirstChild(characterId) or templates:FindFirstChild(row[1])
        if source then
            local actor = source:Clone()
            actor.Name = "StreetNeighbor" .. i
            actor:ScaleTo(rng:NextNumber(0.88, 1.04))
            actor:PivotTo(
                CFrame.new(450 + row[2], 0, row[3]) * CFrame.Angles(0, math.rad(row[6] or 0), 0)
            )
            actor:SetAttribute("QuayHost", nil)
            actor:SetAttribute("AmbientPhase", rng:NextNumber(0, 40))
            actor:SetAttribute("GenericResident", true)
            actor:SetAttribute(
                "RewardVoice",
                if characterId == "NQ-NPC-IVO"
                        or characterId == "NQ-NPC-TORI"
                        or characterId == "NQ-NPC-RONAN"
                    then "street_roger"
                    else "street_sarah"
            )
            actor:SetAttribute("StreetRole", row[5])
            actor:SetAttribute("WalkSpeed", rng:NextNumber(1.7, 2.8))
            actor:SetAttribute("WalkPause", rng:NextNumber(2.5, 8))
            Style.assign(actor, rng)
            for _, part in actor:GetDescendants() do
                if part:IsA("BasePart") then
                    part.CanCollide, part.CanTouch = false, false
                end
            end
            if row[4] then
                actor:SetAttribute("AmbientWalk", true)
                actor:SetAttribute(
                    "AmbientRoute",
                    game:GetService("HttpService"):JSONEncode(row[4])
                )
            elseif not row[5] then
                actor:SetAttribute("StreetAudience", true)
            end
            actor.Parent = scene.root.Neighbors
        end
    end
end
return Life
