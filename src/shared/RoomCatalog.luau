-- Stable save IDs; access derives from server progress, never client grants.
local Cosmetics = require(script.Parent.CosmeticCatalog)
local Rooms = {
    Fields = { "finish", "sign", "decor" },
    Signs = { records = "RECORD SHOP", beats = "BEAT WORKSHOP" },
    SignOrder = { "records", "beats" },
    DecorOrder = { "none", "vinyl" },
}

function Rooms.allowed(profile, key, value)
    if type(value) ~= "string" or #value > 32 then
        return false
    end
    if key == "finish" then
        return Cosmetics.Sets[value] ~= nil
    elseif key == "sign" then
        return Rooms.Signs[value] ~= nil
    elseif key == "decor" then
        return value == "none"
            or (value == "vinyl" and profile.unlocked and profile.unlocked.I01 == true)
    end
    return false
end

function Rooms.sanitize(raw, profile)
    raw = if type(raw) == "table" then raw else {}
    local result = { finish = "quay", sign = "records", decor = "none" }
    for _, key in Rooms.Fields do
        if Rooms.allowed(profile, key, raw[key]) then
            result[key] = raw[key]
        end
    end
    return result
end

function Rooms.equal(a, b)
    for _, key in Rooms.Fields do
        if a[key] ~= b[key] then
            return false
        end
    end
    return true
end

return Rooms
