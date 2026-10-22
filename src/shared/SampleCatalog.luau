local samples = {
    { id = "kick", label = "Warm kick", key = "One" },
    { id = "snare", label = "Dry snare", key = "Two" },
    { id = "closed_hat", label = "Closed hat", key = "Three" },
    { id = "open_hat", label = "Open hat", key = "Four" },
    { id = "clap", label = "Hand clap", key = "Q" },
    { id = "rim", label = "Wood rim", key = "W" },
    { id = "low_tom", label = "Low tom", key = "E" },
    { id = "high_tom", label = "High tom", key = "R" },
    { id = "shaker", label = "Soft shaker", key = "A" },
    { id = "tambourine", label = "Tambourine", key = "S" },
    { id = "bell", label = "Small bell", key = "D" },
    { id = "pluck", label = "Warm pluck", key = "F" },
    { id = "bass_c", label = "Bass C", key = "Z" },
    { id = "bass_eb", label = "Bass E-flat", key = "X" },
    { id = "bass_g", label = "Bass G", key = "C" },
    { id = "chord", label = "Soft chord", key = "V" },
    { id = "metal_hit", label = "Quay metal", discovery = "I01" },
    { id = "vent_thump", label = "Vent thump", discovery = "I02" },
    { id = "robot_chirp", label = "Helper chirp", discovery = "I03" },
}
local Catalog = { List = samples, ById = {} }
for _, sample in samples do
    Catalog.ById[sample.id] = sample
end
function Catalog.isUnlocked(id, unlocked)
    local sample = Catalog.ById[id]
    return sample ~= nil and (sample.discovery == nil or unlocked[sample.discovery] == true)
end
return Catalog
