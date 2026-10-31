local names = {
    "play",
    "stop",
    "record",
    "pause",
    "save",
    "restore",
    "volume",
    "mute",
    "collect",
    "collected",
    "locked",
    "headphones",
    "wave",
    "robot",
    "settings",
    "close",
}
local rects = {}
for index, name in names do
    rects[name] = Vector2.new((index - 1) % 4 * 256, math.floor((index - 1) / 4) * 256)
end
return rects
