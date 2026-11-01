-- Canonical virtual discoveries; planned pack addresses are not approved audio.
local Catalog = require(script.Parent.SampleCatalog)
local Discoveries = {
    Order = { "I01", "I02", "I03" },
    ById = {
        I01 = {
            sample = "nq.harbour.v1.d01",
            role = "discovery_metal",
            address = 49,
            label = "Quay metal",
            origin = "A metal strike at the quay. Approved sample audio is pending.",
            use = "Open SEQ / Full editor / Sound hunts. Add this sound at any two rhythmic positions, then save. Echo practice is optional.",
        },
        I02 = {
            sample = "nq.harbour.v1.d02",
            role = "discovery_vent",
            address = 50,
            label = "Vent thump",
            origin = "A low thump from the alley vent. Approved sample audio is pending.",
            use = "Layer this collected source with your metal part in a named sequence, then save your own rhythm.",
        },
        I03 = {
            sample = "nq.harbour.v1.d03",
            role = "discovery_robot",
            address = 51,
            label = "Helper chirp",
            origin = "A short reply from Mica's speaker. Approved sample audio is pending.",
            use = "Copy a variation, change the chirp rhythm and save both sequences. The echo exercise is optional, not the creative objective.",
        },
    },
}
for id, binding in Catalog.LocalDiscoveryBindings do
    local source = Catalog.LocalDiscoveryById[id]
    local discovery = Discoveries.ById[id]
    if source and discovery then
        discovery.authoredSample = discovery.sample
        discovery.sample, discovery.address = source.id, source.absolutePad
        discovery.label = source.localDiscoveryLabel
        discovery.origin = "Local kit source: "
            .. binding.address
            .. " "
            .. binding.label
            .. ". Gameplay role: "
            .. binding.substitute_for
            .. "."
        -- Preserve the old exercise description as provenance, not a mandatory
        -- completion rule for the current creative sound-hunt interaction.
        discovery.legacyUse = binding.use
        discovery.localOnly, discovery.recordingEquivalence = true, false
        discovery.sourceSubstitute = true
        discovery.sourceLabel, discovery.sourceAddress = binding.label, binding.address
        discovery.audioApproved, discovery.runtimeAdmitted = false, false
        discovery.listeningReview = "pending"
    end
end
return Discoveries
