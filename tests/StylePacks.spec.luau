-- Explicit Server contracts: no cloud data or audio upload.
return function()
    local shared = game.ReplicatedStorage.Shared
    local Catalog = require(shared.SampleCatalog)
    local Pattern = require(shared.Pattern)
    assert(
        Catalog.Packs and #Catalog.Packs == 11,
        "Ten style kits plus the original collection are missing"
    )
    assert(
        #Catalog.List == 179 and Catalog.List[1].id == "kick" and Catalog.List[16].id == "chord",
        "Legacy sample IDs or pad ordering changed"
    )
    local seen = {}
    local count = 0
    for index, pack in Catalog.Packs do
        if index > 1 then
            assert(
                #pack.samples == 16 and type(pack.key) == "string",
                "Kit must have sixteen sounds and one key"
            )
            local p = Pattern.new()
            for pad, sample in pack.samples do
                assert(not seen[sample.id] and #sample.id <= 40, "Invalid or duplicate style ID")
                seen[sample.id] = true
                assert(
                    Catalog.isUnlocked(sample.id, {}),
                    "Starter sample incorrectly discovery-gated"
                )
                p.assignments[pad] = sample.id
                count += 1
            end
            p.rows[1][1] = true
            local restored = Pattern.sanitize(p, {})
            for pad = 1, 16 do
                assert(
                    restored.assignments[pad] == p.assignments[pad],
                    "Style assignments lost during save sanitization"
                )
            end
            assert(restored.rows[1][1], "Kit changed pattern notes")
        end
    end
    assert(not Catalog.isUnlocked("style.invalid.01", {}), "Unknown style ID admitted")
    return {
        passed = true,
        packs = 10,
        samples = count,
        legacyPreserved = true,
        assignmentsRoundTrip = true,
    }
end
