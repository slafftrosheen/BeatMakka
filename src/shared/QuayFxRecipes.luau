-- Discovery recipes use the existing audio processors; free sound editing stays available.
local Sound = require(script.Parent.PadSound)
local R = {}
R.List = {
    {
        id = "quay_echo",
        label = "DOCK ECHO",
        icon = "sound",
        side = "echo",
        hint = "Win Echo Pads",
        target = "echo",
        echo = 0.45,
        beats = 0.75,
        reverb = 0.08,
    },
    {
        id = "quay_vent",
        label = "VENT ROOM",
        icon = "knob",
        quest = "NQ-Q04",
        hint = "Restore Ivo's vent",
        reverb = 0.38,
        echo = 0,
        beats = 0.5,
    },
    {
        id = "quay_lantern",
        label = "LANTERN SPACE",
        icon = "badge",
        side = "lantern",
        hint = "Win Lantern Lock",
        target = "lantern",
        reverb = 0.52,
        echo = 0.15,
        beats = 0.5,
    },
    {
        id = "quay_signal",
        label = "SIGNAL REPEAT",
        icon = "steps",
        quest = "NQ-Q10",
        hint = "Light the breakwater",
        reverb = 0.10,
        echo = 0.55,
        beats = 0.25,
    },
}
function R.earned(q, item)
    return q ~= nil
        and (if item.side then q.side[item.side] == true else q.completed[item.quest] == true)
end
function R.find(id)
    for _, item in R.List do
        if item.id == id then
            return item
        end
    end
end
function R.apply(q, raw, id, bpm)
    local item = R.find(id)
    if not item or not R.earned(q, item) then
        return nil
    end
    local s = Sound.sanitize(raw)
    s.echo, s.reverb, s.delay = item.echo, item.reverb, math.clamp(60 / bpm * item.beats, 0.05, 1)
    return Sound.sanitize(s)
end
return R
