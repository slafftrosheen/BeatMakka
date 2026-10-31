-- Fictional authored characters. No family photographs, likeness data or voice assets.
local Catalog = {
    Order = { "none", "alissia", "nikolas" },
    ById = {
        none = {
            name = "Alone",
            role = "Your own pace",
            description = "Explore and make music on your own. Every activity stays available.",
        },
        alissia = {
            name = "Alissia",
            asset = "NQ-CMP-ALISSIA",
            role = "The Sound Collector",
            description = "An attentive listener who notices the stories in everyday sounds.",
            accent = "Coral",
            height = 4.1,
        },
        nikolas = {
            name = "Nikolas",
            asset = "NQ-CMP-NIKOLAS",
            role = "The Beat Builder",
            description = "A curious maker who helps explain layers, steps and variations.",
            accent = "Amber",
            height = 3.8,
        },
    },
}
function Catalog.valid(id)
    return type(id) == "string" and Catalog.ById[id] ~= nil
end
function Catalog.sanitize(raw)
    -- The supplied v1 pack persisted a string; retain that choice during migration.
    if type(raw) == "string" then
        raw = { selected = raw }
    end
    raw = if type(raw) == "table" then raw else {}
    return {
        selected = if Catalog.valid(raw.selected) then raw.selected else "none",
        hints = raw.hints ~= false,
    }
end
function Catalog.equal(a, b)
    a, b = Catalog.sanitize(a), Catalog.sanitize(b)
    return a.selected == b.selected and a.hints == b.hints
end
return Catalog
