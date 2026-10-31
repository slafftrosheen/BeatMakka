-- Permanent, guaranteed cosmetic bundles for this experience only.
-- Keep sales closed until the designated production account and final art are approved.
local Wardrobe = require(script.Parent.WardrobeCatalog)

local Catalog = {
    Enabled = false,
    ProductionGameId = nil,
    ProductionCreatorId = nil,
    ProductionCreatorType = nil, -- "User" or "Group"; never infer account eligibility.
    Order = { "harbor_afterglow", "workshop_weekend" },
    Bundles = {
        harbor_afterglow = {
            label = "Harbor Afterglow",
            description = "Warm coral and amber for evenings along the quay.",
            itemIds = { "afterglow_headphones", "afterglow_scarf", "afterglow_badge" },
            PassId = nil,
            AssetsApproved = false,
            ProposedDefaultPrice = 99, -- Planning only. Never render this as a purchase price.
        },
        workshop_weekend = {
            label = "Workshop Weekend",
            description = "Cream, faded teal and worn canvas from the workshop counter.",
            itemIds = { "weekend_earmuffs", "weekend_satchel", "weekend_patch" },
            PassId = nil,
            AssetsApproved = false,
            ProposedDefaultPrice = 99, -- Planning only. Never render this as a purchase price.
        },
    },
}

local function validId(value)
    return type(value) == "number" and value > 0 and value < 2 ^ 53 and value % 1 == 0
end

function Catalog.bindingReady(bundleId)
    local bundle = Catalog.Bundles[bundleId]
    if not bundle or not validId(bundle.PassId) or bundle.AssetsApproved ~= true then
        return false
    end
    for _, otherId in Catalog.Order do
        local other = Catalog.Bundles[otherId]
        if otherId ~= bundleId and other.PassId == bundle.PassId then
            return false -- Duplicate pass bindings cannot silently grant the wrong set.
        end
    end
    for _, itemId in bundle.itemIds do
        local item = Wardrobe.Items[itemId]
        if not item or item.source ~= "premium" or item.bundle ~= bundleId then
            return false
        end
    end
    return #bundle.itemIds > 0
end

function Catalog.productionMatches(gameId, creatorId, creatorType, isStudio)
    return not isStudio
        and validId(Catalog.ProductionGameId)
        and validId(Catalog.ProductionCreatorId)
        and (Catalog.ProductionCreatorType == "User" or Catalog.ProductionCreatorType == "Group")
        and gameId == Catalog.ProductionGameId
        and creatorId == Catalog.ProductionCreatorId
        and creatorType == Catalog.ProductionCreatorType
end

function Catalog.bundleForPass(passId)
    if not validId(passId) then
        return nil
    end
    for _, bundleId in Catalog.Order do
        if Catalog.bindingReady(bundleId) and Catalog.Bundles[bundleId].PassId == passId then
            return bundleId
        end
    end
    return nil
end

function Catalog.contents(bundleId)
    local bundle = Catalog.Bundles[bundleId]
    local labels = {}
    if bundle then
        for _, itemId in bundle.itemIds do
            local item = Wardrobe.Items[itemId]
            table.insert(labels, if item then item.label else "Unavailable item")
        end
    end
    return labels
end

return Catalog
