-- Read-only narrative projection from existing server-authoritative state.
-- No client request can award a sound, shelf save, mission, or chapter completion.
local Catalog = require(script.Parent.CompanionCatalog)
local Quest = require(script.Parent.FirstPerformanceQuest)
local Missions = require(script.Parent.NeighborhoodMissions)

local Progress = {}

local function alissiaHint(profile, quest, missions)
    if not quest.accepted then
        return "Find Mica near the sound alley. He's waiting to show us Needle Quay."
    elseif profile.unlocked.I01 ~= true then
        return "Dockside Exchange: listen for a metal strike. That's our first found sound."
    elseif profile.unlocked.I02 ~= true then
        return "Repair Alley has a deep vent thump. Notice how different it sounds from metal."
    elseif profile.unlocked.I03 ~= true then
        return "Near Signal House, Mica's little chirp can become part of our beat."
    elseif missions.nextId then
        return "We've found the three quay sounds. Listen to the saved beats while we help restore the neighborhood."
    elseif not quest.completed then
        return "The city is listening. Share one full loop of your own saved music at the courtyard."
    elseif profile.chapter and profile.chapter.completed == true then
        return "Needle Quay has its voice back. There's still more to discover together."
    end
    return "Look around and listen. Little sounds can inspire a whole new song."
end

local function nikolasHint(profile, quest, missions)
    if not quest.accepted then
        return "Meet Mica, then I'll help turn the found sounds into a working beat."
    elseif profile.unlocked.I01 ~= true then
        return "First get the metal hit from Dockside Exchange, then bring it to MK-I."
    elseif missions.nextId == "metal_pulse" then
        return "Place Quay metal on two different unmuted steps; save the beat to your shelf."
    elseif profile.unlocked.I02 ~= true then
        return "Listen for the vent thump in Repair Alley before layering the next sound."
    elseif missions.nextId == "vent_duet" then
        return "Add metal and vent to the same pattern. Save a beat with both sounds audible."
    elseif profile.unlocked.I03 ~= true then
        return "Let's discover Mica's chirp next. That tiny sound can answer our rhythm."
    elseif missions.nextId == "helper_reply" then
        return "Make two different robot-chirp patterns, then save them. Variations make the groove."
    elseif not quest.completed then
        return "Your saved loop is the important part. Try the courtyard when you're ready."
    elseif profile.chapter and profile.chapter.completed == true then
        return "Great work! Keep experimenting with patterns A-D and the six shelf spots."
    end
    return "Try changing just one step and hearing how the whole beat feels different."
end

function Progress.summary(profile)
    local id = Catalog.normalize(profile.companion)
    if id == "none" then
        return { selected = "none", available = true, hint = "Choose a companion, or explore alone." }
    end
    local quest = Quest.summary(profile)
    local missions = Missions.summary(profile)
    local definition = Catalog.ById[id]
    return {
        selected = id,
        available = true,
        name = definition.displayName,
        title = definition.title,
        role = definition.role,
        hint = if id == "alissia"
            then alissiaHint(profile, quest, missions)
            else nikolasHint(profile, quest, missions),
        progress = {
            discoveries = quest.collected,
            neighborhood = missions.completed,
            originalSet = quest.completed,
            chapter = profile.chapter ~= nil and profile.chapter.completed == true,
        },
    }
end

return Progress
