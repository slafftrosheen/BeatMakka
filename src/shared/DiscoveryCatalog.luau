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
            use = "Use ready I01 at four distinct rhythmic positions in a named sequence.",
        },
        I02 = {
            sample = "nq.harbour.v1.d02",
            role = "discovery_vent",
            address = 50,
            label = "Vent thump",
            origin = "A low thump from the alley vent. Approved sample audio is pending.",
            use = "Layer ready I02 with another part in a named sequence.",
        },
        I03 = {
            sample = "nq.harbour.v1.d03",
            role = "discovery_robot",
            address = 51,
            label = "Helper chirp",
            origin = "A short reply from Mica's speaker. Approved sample audio is pending.",
            use = "Select a teaching bar; use ready I03 at relative ticks 0, 960, 1920 and 2880.",
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
        discovery.use = binding.use
        discovery.localOnly, discovery.recordingEquivalence = true, false
        discovery.sourceSubstitute = true
        discovery.sourceLabel, discovery.sourceAddress = binding.label, binding.address
        discovery.audioApproved, discovery.runtimeAdmitted = false, false
        discovery.listeningReview = "pending"
    end
end
return Discoveries
