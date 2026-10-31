local Sound = {}
Sound.Spec = {
    gain = { 0, 1.5, 1, 0.05 },
    pitch = { -24, 24, 0, 1 },
    start = { 0, 0.98, 0, 0.01 },
    finish = { 0.02, 1, 1, 0.01 },
    attack = { 0, 2, 0, 0.01 },
    decay = { 0, 2, 0.08, 0.02 },
    sustain = { 0, 1, 1, 0.05 },
    release = { 0, 2, 0.02, 0.02 },
    gate = { 0.05, 1, 1, 0.05 },
    echo = { 0, 0.7, 0, 0.05 },
    delay = { 0.05, 1, 0.25, 0.025 },
    reverb = { 0, 0.7, 0, 0.05 },
    tone = { -1, 1, 0, 0.05 },
    drive = { 0, 0.6, 0, 0.05 },
}
function Sound.sanitize(raw)
    local result = {}
    for key, spec in Sound.Spec do
        local value = if type(raw) == "table" then raw[key] else nil
        result[key] = if type(value) == "number"
                and value == value
                and math.abs(value) < math.huge
            then math.clamp(value, spec[1], spec[2])
            else spec[3]
    end
    result.finish = math.max(result.finish, result.start + 0.02)
    return result
end
function Sound.level(s, t)
    if s.attack > 0 and t < s.attack then
        return t / s.attack
    end
    if s.decay > 0 and t < s.attack + s.decay then
        return 1 - (1 - s.sustain) * (t - s.attack) / s.decay
    end
    return s.sustain
end
function Sound.timing(s, duration)
    -- Fit a one-shot release to the available sample, retaining an audible body.
    local release = math.min(s.release, duration * 0.5)
    local gate = math.max(0, math.min(duration * s.gate, duration - release))
    return gate, math.min(duration, gate + release)
end
function Sound.envelope(s, duration, t)
    local gate, finish = Sound.timing(s, duration)
    if t >= finish then
        return 0
    end
    if t >= gate then
        return Sound.level(s, gate) * math.max(0, 1 - (t - gate) / math.max(0.001, finish - gate))
    end
    return Sound.level(s, t)
end
function Sound.same(a, b)
    for key, spec in Sound.Spec do
        if (a and a[key] or spec[3]) ~= (b and b[key] or spec[3]) then
            return false
        end
    end
    return true
end
function Sound.preset(raw, name, bpm)
    local s = Sound.sanitize(raw)
    if name == "reset" then
        return Sound.sanitize(nil)
    end
    if name == "dry" then
        s.echo, s.reverb = 0, 0
        s.tone, s.drive = 0, 0
    elseif name == "dub" then
        s.echo, s.delay, s.reverb = 0.35, math.clamp(60 / bpm * 0.75, 0.05, 1), 0.12
    elseif name == "room" then
        s.echo, s.reverb = 0, 0.25
    elseif name == "tape" then
        s.tone, s.drive, s.echo, s.reverb = -0.25, 0.22, 0.08, 0.08
        s.delay = math.clamp(60 / bpm * 0.5, 0.05, 1)
    elseif name == "air" then
        s.tone, s.drive, s.echo, s.reverb = 0.3, 0, 0.12, 0.4
        s.delay = math.clamp(60 / bpm * 0.75, 0.05, 1)
    else
        return nil
    end
    return s
end
return Sound
