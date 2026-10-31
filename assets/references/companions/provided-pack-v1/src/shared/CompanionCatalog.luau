-- Optional player companions. New stable IDs; never reassign existing H04 / NPC IDs.
local Catalog = {
    Order = { "alissia", "nikolas" },
    ById = {
        alissia = {
            displayName = "Alissia",
            title = "The Sound Collector",
            role = "listening",
            accent = "coral",
            introduction = "I'll help you notice the little sounds around the quay.",
        },
        nikolas = {
            displayName = "Nikolas",
            title = "The Beat Builder",
            role = "rhythm",
            accent = "amber",
            introduction = "Let's put the sounds together and make a rhythm.",
        },
    },
}

function Catalog.normalize(id)
    if type(id) == "string" and Catalog.ById[id] ~= nil then
        return id
    end
    return "none"
end

function Catalog.select(profile, requested)
    if requested ~= "none" and (type(requested) ~= "string" or Catalog.ById[requested] == nil) then
        return false, false
    end
    local selected = Catalog.normalize(requested)
    if profile.companion == selected then
        return true, false
    end
    profile.companion = selected
    return true, true
end

return Catalog
