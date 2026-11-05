-- Authored construction placeholders; replace decoration without moving gameplay anchors.
local Theme = require(game.ReplicatedStorage.Shared.Theme)
local Fair = require(game.ReplicatedStorage.Shared.QuayFair)
local Games = require(game.ReplicatedStorage.Shared.QuayStreetGames)
local Scene = {}
function Scene.build(parent)
    local model = Instance.new("Model")
    model.Name, model.Parent = "NeedleQuayFair", parent
    model:SetAttribute("ArtStage", "CODE_BLOCKOUT_NOT_ART_APPROVED")
    local function part(name, size, at, color, collide)
        local p = Instance.new("Part")
        p.Name, p.Size, p.Position = name, size, at
        p.Anchored, p.CanCollide, p.Color = true, collide == true, color
        p.CanTouch, p.CanQuery = false, collide == true
        p.Material, p.Parent = Enum.Material.Wood, model
        return p
    end
    part("FairCarpet", Vector3.new(84, 0.08, 23), Vector3.new(590, 0.08, -22), Theme.Teal)
    for _, id in Fair.Games do
        local at = Games.ById[id].position
        for _, dx in { -6, 6 } do
            part("BoothPost", Vector3.new(0.35, 8, 0.35), at + Vector3.new(dx, 2, -2), Theme.Walnut, true)
        end
        for stripe = 1, 12 do
            part("AwningStripe", Vector3.new(1, 0.3, 6), at + Vector3.new(stripe - 6.5, 6.2, -1.5),
                if stripe % 2 == 0 then Theme.Cream else Theme.Coral)
        end
        part("GalleryBack", Vector3.new(12, 5, 0.4), at + Vector3.new(0, 1.5, -3.8), Theme.Teal, true)
        for i = 1, (if id == "rings" then 1 else 4) do
            local target = part("FairTarget", Vector3.new(0.25, 1.7, 1.7),
                at + Vector3.new(if id == "rings" then 0 else (i - 2.5) * 2.5, 2.1, -3.4), Theme.Amber)
            target.Shape = Enum.PartType.Cylinder
            target.CFrame *= CFrame.Angles(0, math.pi / 2, 0)
            target:SetAttribute("FairGame", id)
            target:SetAttribute("FairPad", i)
            target:SetAttribute("NonOccluding", true)
            local center = part("TargetCenter", Vector3.new(0.3, 0.8, 0.8), target.Position + Vector3.new(0, 0, 0.25), Theme.Coral)
            center.CFrame *= CFrame.Angles(0, math.pi / 2, 0)
            center.Shape = Enum.PartType.Cylinder
            center:SetAttribute("FairGame", id)
            center:SetAttribute("FairPad", i)
            if id == "bells" then
                target.Shape = Enum.PartType.Ball
                part("BellHandle", Vector3.new(0.18, 0.5, 0.18), target.Position + Vector3.new(0, 1, 0), Theme.Walnut)
            elseif id == "rings" then
                target.Transparency, center.Transparency = 1, 1
                part("RingPeg", Vector3.new(0.3, 1.4, 0.3), at + Vector3.new(0, 2.1, -2.7), Theme.Cream)
                for segment = 1, 12 do
                    local angle = segment * math.pi / 6
                    local ring = part("TossRing", Vector3.new(0.16, 0.16, 0.42),
                        at + Vector3.new(math.cos(angle) * 0.8, 2.1, -2.7 + math.sin(angle) * 0.8), Theme.Coral)
                    ring.CFrame *= CFrame.Angles(0, -angle, 0)
                    ring:SetAttribute("FairGame", id)
                    ring:SetAttribute("FairPad", 1)
                    ring:SetAttribute("FairRing", true)
                end
            end
        end
    end
    local prize = part("FairPrizes", Vector3.new(8, 3, 3), Fair.PrizePosition, Theme.Walnut, true)
    prize:SetAttribute("QuayInteraction", "fair:prizes")
    prize:SetAttribute("GuideIcon", "badge")
    for i = 1, 3 do
        local display = part("PrizeDisplay", Vector3.new(1.2, 1.2, 1.2), prize.Position + Vector3.new((i - 2) * 2.3, 2.2, 0), Theme.Amber)
        display.Shape = Enum.PartType.Ball
    end
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText, prompt.ObjectText = "Prizes", "FAIR COINS"
    prompt.MaxActivationDistance, prompt.RequiresLineOfSight, prompt.Parent = 10, false, prize
    -- Festoon runs behind the booths, clear of the market approach and street lanes.
    for i = 0, 18 do
        local bulb = part("FairBulb", Vector3.one * 0.35, Vector3.new(552 + i * 4.2, 9 - math.sin(i / 18 * math.pi), -27),
            if i % 2 == 0 then Theme.Amber else Theme.Coral)
        bulb.Shape, bulb.Material = Enum.PartType.Ball, Enum.Material.Neon
    end
    return prize
end
return Scene
