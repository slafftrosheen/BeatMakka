-- Optional neighborhood RPG layer; canonical quests and free music tools stay intact.
local Life = {}
Life.Stamps = {
    {
        id = "dock",
        title = "Ropes & low tide",
        at = Vector3.new(267, 0, 123),
        note = "The dock ropes creak between the waves. Leave space between your notes.",
        zone = "waterfront",
    },
    {
        id = "market",
        title = "Sleeves & stories",
        at = Vector3.new(487, 0, -36),
        note = "Naya's record sleeves hold a hundred histories. Your next loop can start with just one.",
        zone = "market",
    },
    {
        id = "alley",
        title = "The alley hum",
        at = Vector3.new(349, 0, -132),
        note = "Ivo hears a steady pulse in every repaired fan. Listen for the quieter layers.",
        zone = "repair",
    },
    {
        id = "cafe",
        title = "Cups & conversation",
        at = Vector3.new(408, 0, 120),
        note = "Nell's cups tap out an accidental rhythm. Not every good beat was planned.",
        zone = "cafe",
    },
    {
        id = "signal",
        title = "A light across water",
        at = Vector3.new(626, 0, 123),
        note = "Mica keeps the signal warm. A short melody can travel a long way.",
        zone = "waterfront",
    },
    {
        id = "lantern",
        title = "Before the encore",
        at = Vector3.new(472, 0, 122),
        note = "The Lantern Room is quiet before a show. Soon, the room will remember your music.",
        zone = "market",
    },
}
Life.Gardens = {
    { id = "cafe", title = "Nell's windowsill", at = Vector3.new(373, 0, 120) },
    { id = "alley", title = "Ivo's hardy herbs", at = Vector3.new(333, 0, -133) },
    { id = "market", title = "Sana's stage flowers", at = Vector3.new(476, 0, -36) },
}
Life.Parcel = { pickup = Vector3.new(414, 0, -36), drop = Vector3.new(291, 0, 124) }
Life.Ranks = {
    { 0, "NEW ARRIVAL" },
    { 80, "FAMILIAR FACE" },
    { 200, "QUAY REGULAR" },
    { 380, "NEIGHBORHOOD VOICE" },
    { 620, "HARBOR HEART" },
}
function Life.sanitize(raw)
    raw = if type(raw) == "table" then raw else {}
    local out =
        { stamps = {}, gardens = {}, parcel = if raw.parcel == 1 or raw.parcel == 2
            then raw.parcel
            else 0 }
    for _, row in Life.Stamps do
        out.stamps[row.id] = type(raw.stamps) == "table" and raw.stamps[row.id] == true
    end
    for _, row in Life.Gardens do
        out.gardens[row.id] = type(raw.gardens) == "table" and raw.gardens[row.id] == true
    end
    return out
end
function Life.equal(a, b)
    a, b = Life.sanitize(a), Life.sanitize(b)
    if a.parcel ~= b.parcel then
        return false
    end
    for _, row in Life.Stamps do
        if a.stamps[row.id] ~= b.stamps[row.id] then
            return false
        end
    end
    for _, row in Life.Gardens do
        if a.gardens[row.id] ~= b.gardens[row.id] then
            return false
        end
    end
    return true
end
function Life.summary(progress)
    local saved = Life.sanitize(progress.life)
    local xp, stamps, gardens = 0, 0, 0
    for _, done in progress.completed or {} do
        if done then
            xp += 25
        end
    end
    for _, done in progress.side or {} do
        if done then
            xp += 20
        end
    end
    for _, done in progress.commissions or {} do
        if done then
            xp += 20
        end
    end
    for _, done in saved.stamps do
        if done then
            stamps += 1
            xp += 15
        end
    end
    for _, done in saved.gardens do
        if done then
            gardens += 1
            xp += 20
        end
    end
    if saved.parcel == 2 then
        xp += 45
    end
    local rank = 1
    for i, row in Life.Ranks do
        if xp >= row[1] then
            rank = i
        end
    end
    local nextRank = Life.Ranks[rank + 1]
    return {
        xp = xp,
        rank = rank,
        title = Life.Ranks[rank][2],
        floor = Life.Ranks[rank][1],
        next = nextRank and nextRank[1],
        stamps = stamps,
        gardens = gardens,
        progress = saved,
    }
end
return Life
