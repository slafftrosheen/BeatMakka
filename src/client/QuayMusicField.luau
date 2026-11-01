-- Shared read-only view of nearby public performance sources.
local Http = game:GetService("HttpService")
local Field = { sources = {} }
local function parse(key, value)
    local ok, decoded = pcall(Http.JSONDecode, Http, value)
    Field.sources[key] = if ok and type(decoded) == "table" then decoded else nil
    if ok and type(decoded) == "table" and type(decoded.frames) == "table" then
        -- Cache frame objects once. Change detection sees a new immutable frame
        -- at the musical boundary, not a source table mutated every render frame.
        for index, frame in decoded.frames do
            local current = table.clone(decoded)
            current.frames = nil
            for field, item in frame do
                current[field] = item
            end
            decoded.frames[index] = current
        end
    end
end
local function public()
    local raw = workspace:GetAttribute("QuayPublicBeat")
    if raw then
        parse("court", raw)
    else
        Field.sources.court = nil
    end
end
public()
workspace:GetAttributeChangedSignal("QuayPublicBeat"):Connect(public)
local folder = workspace:WaitForChild("QuayLiveMusic")
local function register(value)
    if not value:IsA("StringValue") then
        return
    end
    parse(value.Name, value.Value)
    local changed = value.Changed:Connect(function()
        parse(value.Name, value.Value)
    end)
    value.Destroying:Once(function()
        changed:Disconnect()
        Field.sources[value.Name] = nil
    end)
end
for _, value in folder:GetChildren() do
    register(value)
end
folder.ChildAdded:Connect(register)
function Field.nearest(position, radius, excludeOwner, speakersOnly)
    local best, distance
    local now = workspace:GetServerTimeNow()
    for key, original in Field.sources do
        local source = original
        if original.frames and type(original.barSeconds) == "number" and original.barSeconds > 0 then
            local bar = math.floor((now - original.startedAt) / original.barSeconds) + 1
            source = original.frames[bar]
        end
        if source and (not speakersOnly or key ~= "court")
            and (excludeOwner == nil or source.owner ~= excludeOwner)
            and source.active ~= false and now >= source.startedAt
            and (not source.expiresAt or now < source.expiresAt) then
            local d = (position - Vector3.new(source.x, source.y, source.z)).Magnitude
            if d < radius and (not distance or d < distance) then
                best, distance = source, d
            end
        end
    end
    return best, distance
end
return Field
