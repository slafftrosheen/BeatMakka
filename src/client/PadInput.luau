-- Input lifetime and local playback submission, independent of server round trips.
local PadInput = {}
PadInput.__index = PadInput

function PadInput.new(hit, changed)
    return setmetatable({
        hit = hit,
        changed = changed,
        active = {},
        held = {},
        hits = 0,
        submitted = 0,
        samples = {},
        destroyed = false,
    }, PadInput)
end

function PadInput:begin(pad, token)
    if
        self.destroyed
        or token == nil
        or self.active[token]
        or type(pad) ~= "number"
        or pad % 1 ~= 0
        or pad < 1
        or pad > 64
    then
        return false
    end
    local started = os.clock()
    self.active[token] = pad
    self.held[pad] = (self.held[pad] or 0) + 1
    self.changed(pad, true)
    local submitted, submittedAt = self.hit(pad)
    submitted = submitted == true
    self.hits += 1
    if submitted then
        self.submitted += 1
        -- Bounded measurements end at Sound:Play submission, never acoustic onset.
        self.samples[(self.submitted - 1) % 128 + 1] = ((submittedAt or os.clock()) - started)
            * 1000
    end
    return true
end

function PadInput:finish(token)
    local pad = self.active[token]
    if not pad then
        return false
    end
    self.active[token] = nil
    self.held[pad] -= 1
    if self.held[pad] == 0 then
        self.held[pad] = nil
        self.changed(pad, false)
    end
    return true
end

function PadInput:cancel()
    table.clear(self.active)
    for pad in self.held do
        self.changed(pad, false)
    end
    table.clear(self.held)
end

function PadInput:diagnostics()
    local sorted = table.clone(self.samples)
    table.sort(sorted)
    local sum = 0
    for _, value in sorted do
        sum += value
    end
    return {
        hits = self.hits,
        submitted = self.submitted,
        unavailable = self.hits - self.submitted,
        measured = #sorted,
        boundary = "input handler to local playback submission; not acoustic latency",
        meanMs = if #sorted > 0 then sum / #sorted else nil,
        p95Ms = sorted[math.ceil(#sorted * 0.95)],
        maxMs = sorted[#sorted],
    }
end

function PadInput:destroy()
    self:cancel()
    self.destroyed = true
end

return PadInput
