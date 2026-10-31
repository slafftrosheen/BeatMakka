-- Shared clothing variations. Story hosts retain their authored identities.
local Style = {}
Style.Outfits = {
    {
        name = "harbor teal",
        shirt = Color3.fromRGB(167, 224, 210),
        trousers = Color3.fromRGB(142, 156, 153),
    },
    {
        name = "clay workwear",
        shirt = Color3.fromRGB(244, 171, 130),
        trousers = Color3.fromRGB(183, 169, 143),
    },
    {
        name = "ochre knit",
        shirt = Color3.fromRGB(247, 210, 139),
        trousers = Color3.fromRGB(145, 174, 165),
    },
    {
        name = "cream canvas",
        shirt = Color3.fromRGB(250, 238, 211),
        trousers = Color3.fromRGB(151, 168, 177),
    },
    {
        name = "walnut linen",
        shirt = Color3.fromRGB(201, 167, 143),
        trousers = Color3.fromRGB(217, 207, 183),
    },
    {
        name = "sea glass",
        shirt = Color3.fromRGB(183, 214, 185),
        trousers = Color3.fromRGB(189, 171, 156),
    },
}

function Style.assign(actor, rng)
    local index = rng:NextInteger(1, #Style.Outfits)
    actor:SetAttribute("OutfitIndex", index)
    actor:SetAttribute("OutfitPattern", rng:NextInteger(1, 3))
    actor:SetAttribute("OutfitName", Style.Outfits[index].name)
    actor:SetAttribute("AppearanceSeed", rng:NextInteger(1, 1000000))
    for _, part in actor:GetDescendants() do
        if part:IsA("MeshPart") then
            local bone = part:GetAttribute("RigidBone") or ""
            if bone == "UpperTorso" or bone == "LowerTorso" then
                part.Color = Style.Outfits[index].shirt
            elseif bone:find("UpperLeg") then
                part.Color = Style.Outfits[index].trousers
            end
        end
    end
end

function Style.vertexColor(actor, weights, height)
    local outfit = Style.Outfits[actor:GetAttribute("OutfitIndex")]
    if not outfit then
        return Color3.new(1, 1, 1)
    end
    local shirt, trousers = 0, 0
    for _, weight in weights do
        local bone = weight[1]
        if bone == "UpperTorso" or bone == "LowerTorso" or bone:find("UpperArm") then
            shirt += weight[2]
        elseif bone:find("UpperLeg") then
            trousers += weight[2]
        end
    end
    -- Hands, face, hair, shoes and exposed calves keep their original texture color.
    local tint = if shirt > 0.8
        then outfit.shirt
        elseif trousers > 0.8 then outfit.trousers
        else Color3.new(1, 1, 1)
    local pattern = actor:GetAttribute("OutfitPattern")
    if
        shirt > 0.8
        and pattern ~= 1
        and math.floor(height * (if pattern == 2 then 3 else 7)) % 3 == 0
    then
        tint = tint:Lerp(Color3.new(1, 1, 1), 0.4)
    end
    return tint
end

return Style
