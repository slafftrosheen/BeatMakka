-- The same picture names appear at the destination, route HUD and nearby action.
local Symbols = {}
function Symbols.forTarget(id)
    id = id or ""
    local gameId = id:match("^activity_(.+)$")
    if gameId then
        local info = require(script.Parent.QuayStreetGames).ById[gameId]
        if info then return info.icon end
    end
    if id == "enter" then return "van" end
    if id == "return" or id:match("^inside_") or id:match("^outside_") then return "door" end
    if id == "fair:prizes" or id == "fair_prizes" then return "badge" end
    if id:match("^dock") or id:match("^market") or id:find("parcel", 1, true) then return "crate" end
    if id:match("^repair") then return "lamp" end
    if id == "radio" then return "sound" end
    if id:find("garden", 1, true) then return "flower" end
    if id:find("listen_", 1, true) then return "headphones" end
    if id:find("NQ%-BLD%-02") then return "disc" end
    if id:find("NQ%-BLD%-03") then return "pads" end
    return "people"
end
return Symbols
