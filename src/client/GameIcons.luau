-- Small authored vector glyphs; no font-glyph availability or uploaded icon dependency.
local Gui = require(script.Parent.GuiFactory)
local Icons = {}
local aliases = {
    sequence = "steps",
    song = "disc",
    settings = "knob",
    discovery = "sound",
    pin = "badge",
    logic = "pads",
    lantern = "lamp",
}
function Icons.forText(text)
    text = string.lower(text or "")
    if text == "?" then
        return "hint"
    end
    for _, pair in
        {
            { "jam", "people" },
            { "timing", "steps" },
            { "track", "steps" },
            { "erase", "trash" },
            { "copy", "duplicate" },
            { "kit", "pads" },
            { "crates", "library" },
            { "settings", "knob" },
            { "bank a", "drum" },
            { "bank b", "bass" },
            { "bank c", "mic" },
            { "bank d", "waves" },
            { "rename", "pencil" },
            { "variation", "duplicate" },
            { "duplicate", "duplicate" },
            { "repeat", "redo" },
            { "teach", "people" },
            { "overdub", "record" },
            { "record", "record" },
            { "pause", "pause" },
            { "play", "play" },
            { "stop", "stop" },
            { "save", "save" },
            { "keep", "save" },
            { "undo", "undo" },
            { "redo", "redo" },
            { "close", "close" },
            { "cancel", "close" },
            { "remove", "trash" },
            { "delete", "trash" },
            { "clear", "trash" },
            { "sequence", "steps" },
            { "song", "disc" },
            { "draft", "sleeve" },
            { "library", "library" },
            { "sound", "sound" },
            { "listen", "headphones" },
            { "audio", "sound" },
            { "mute", "sound" },
            { "mirror", "mirror" },
            { "rotate", "redo" },
            { "head", "headphones" },
            { "scarf", "scarf" },
            { "bag", "bag" },
            { "pin", "badge" },
            { "style", "headphones" },
            { "look", "headphones" },
            { "shop", "shop" },
            { "city", "city" },
            { "map", "route" },
            { "journal", "journal" },
            { "explore", "route" },
            { "route", "route" },
            { "park", "van" },
            { "roamer", "van" },
            { "friend", "people" },
            { "companion", "people" },
            { "people", "people" },
            { "hint", "hint" },
            { "help", "hint" },
            { "next", "arrow" },
            { "previous", "undo" },
            { "sleeve", "sleeve" },
            { "print", "sleeve" },
            { "new", "plus" },
            { "add", "plus" },
        }
    do
        if text:find(pair[1], 1, true) then
            return pair[2]
        end
    end
    return nil
end
function Icons.make(parent, name, color, size)
    name = aliases[name] or name
    local root = Gui.make("Frame", parent, {
        Name = "Icon_" .. name,
        Size = UDim2.fromOffset(size or 28, size or 28),
        BackgroundTransparency = 1,
    })
    local function bar(x, y, w, h, angle)
        return Gui.round(
            Gui.make("Frame", root, {
                Position = UDim2.fromScale(x, y),
                Size = UDim2.fromScale(w, h),
                Rotation = angle or 0,
                BackgroundColor3 = color,
                BorderSizePixel = 0,
            }),
            2
        )
    end
    local function outline(x, y, w, h, round)
        local shape = bar(x, y, w, h)
        shape.BackgroundTransparency = 1
        if round then
            Gui.round(shape, 100)
        end
        Gui.make("UIStroke", shape, {
            Color = color,
            Thickness = math.max(1.5, (size or 28) / 14),
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        })
        return shape
    end
    local function circle(x, y, d)
        return Gui.round(bar(x, y, d, d), 100)
    end
    if name == "pads" then
        for x = 0, 1 do
            for y = 0, 1 do
                bar(0.12 + x * 0.42, 0.12 + y * 0.42, 0.32, 0.32)
            end
        end
    elseif name == "steps" then
        for i = 0, 3 do
            bar(0.08 + i * 0.23, 0.25, 0.16, 0.5)
        end
    elseif name == "sound" then
        for i = 0, 4 do
            local h = ({ 0.25, 0.55, 0.85, 0.55, 0.25 })[i + 1]
            bar(0.06 + i * 0.19, (1 - h) / 2, 0.12, h)
        end
    elseif name == "disc" then
        local outer = bar(0.08, 0.08, 0.84, 0.84)
        Gui.round(outer, 100)
        Gui.round(
            Gui.make("Frame", outer, {
                Position = UDim2.fromScale(0.36, 0.36),
                Size = UDim2.fromScale(0.28, 0.28),
                BackgroundColor3 = Color3.fromRGB(22, 35, 34),
                BorderSizePixel = 0,
            }),
            100
        )
    elseif name == "check" then
        bar(0.15, 0.55, 0.3, 0.13, 45)
        bar(0.34, 0.4, 0.55, 0.13, -45)
    elseif name == "arrow" then
        bar(0.45, 0.14, 0.1, 0.73)
        bar(0.21, 0.24, 0.4, 0.1, -45)
        bar(0.43, 0.24, 0.4, 0.1, 45)
    elseif name == "flag" then
        bar(0.2, 0.12, 0.1, 0.78)
        bar(0.3, 0.12, 0.55, 0.38)
    elseif name == "badge" then
        bar(0.2, 0.1, 0.6, 0.6, 45)
        bar(0.25, 0.65, 0.18, 0.3, 15)
        bar(0.57, 0.65, 0.18, 0.3, -15)
    elseif name == "play" then
        bar(0.28, 0.15, 0.12, 0.7)
        bar(0.28, 0.28, 0.52, 0.12, 35)
        bar(0.28, 0.58, 0.52, 0.12, -35)
    elseif name == "stop" then
        bar(0.2, 0.2, 0.6, 0.6)
    elseif name == "flower" then
        for _, point in { { 0.38, 0.05 }, { 0.08, 0.32 }, { 0.68, 0.32 }, { 0.38, 0.57 } } do
            circle(point[1], point[2], 0.26)
        end
        circle(0.35, 0.29, 0.3)
        bar(0.47, 0.6, 0.07, 0.34)
        bar(0.52, 0.74, 0.28, 0.08, -25)
    elseif name == "crate" then
        outline(0.12, 0.15, 0.76, 0.7)
        bar(0.14, 0.44, 0.72, 0.08)
        bar(0.43, 0.17, 0.1, 0.66)
        bar(0.15, 0.18, 0.38, 0.07, 40)
        bar(0.49, 0.56, 0.38, 0.07, 40)
    elseif name == "lock" then
        outline(0.29, 0.08, 0.42, 0.49, true)
        bar(0.15, 0.43, 0.70, 0.45)
        circle(0.44, 0.54, 0.12)
    elseif name == "pause" then
        bar(0.22, 0.17, 0.2, 0.66)
        bar(0.58, 0.17, 0.2, 0.66)
    elseif name == "drum" then
        outline(0.14, 0.3, 0.72, 0.51)
        outline(0.14, 0.21, 0.72, 0.2, true)
        bar(0.3, 0.43, 0.06, 0.3)
        bar(0.63, 0.43, 0.06, 0.3)
        bar(0.08, 0.12, 0.5, 0.06, 25)
    elseif name == "bass" then
        for index = 0, 4 do
            local h = ({ 0.25, 0.6, 0.85, 0.6, 0.25 })[index + 1]
            bar(0.1 + index * 0.18, (1 - h) / 2, 0.1, h)
        end
    elseif name == "mic" then
        outline(0.35, 0.1, 0.3, 0.5, true)
        outline(0.22, 0.36, 0.56, 0.35, true)
        bar(0.46, 0.69, 0.08, 0.18)
        bar(0.3, 0.87, 0.4, 0.07)
    elseif name == "pencil" then
        bar(0.43, 0.12, 0.18, 0.72, 38)
        bar(0.19, 0.75, 0.18, 0.08, -18)
    elseif name == "duplicate" then
        outline(0.1, 0.1, 0.56, 0.62)
        outline(0.35, 0.32, 0.56, 0.62)
    elseif name == "record" then
        Gui.round(bar(0.15, 0.15, 0.7, 0.7), 100)
    elseif name == "close" then
        bar(0.15, 0.44, 0.7, 0.12, 45)
        bar(0.15, 0.44, 0.7, 0.12, -45)
    elseif name == "knob" then
        local outer = bar(0.08, 0.08, 0.84, 0.84)
        Gui.round(outer, 100)
        Gui.make("Frame", outer, {
            Position = UDim2.fromScale(0.45, 0.1),
            Size = UDim2.fromScale(0.1, 0.3),
            BackgroundColor3 = Color3.fromRGB(243, 182, 95),
            BorderSizePixel = 0,
        })
    elseif name == "headphones" then
        outline(0.18, 0.12, 0.64, 0.7, true)
        bar(0.10, 0.45, 0.23, 0.43)
        bar(0.67, 0.45, 0.23, 0.43)
    elseif name == "bag" or name == "shop" then
        outline(0.15, 0.30, 0.70, 0.58)
        outline(0.34, 0.08, 0.32, 0.38, true)
        if name == "shop" then
            for i = 0, 2 do
                bar(0.2 + i * 0.24, 0.46, 0.1, 0.2)
            end
        else
            bar(0.18, 0.55, 0.64, 0.08)
        end
    elseif name == "scarf" then
        outline(0.15, 0.14, 0.7, 0.28, true)
        bar(0.29, 0.35, 0.22, 0.55, 12)
        bar(0.55, 0.34, 0.18, 0.43, -8)
    elseif name == "people" then
        circle(0.11, 0.10, 0.27)
        circle(0.61, 0.14, 0.25)
        bar(0.08, 0.44, 0.36, 0.43)
        bar(0.56, 0.47, 0.36, 0.40)
    elseif name == "route" then
        outline(0.08, 0.15, 0.84, 0.7)
        bar(0.32, 0.15, 0.07, 0.7)
        bar(0.62, 0.15, 0.07, 0.7)
        circle(0.66, 0.25, 0.17)
        bar(0.55, 0.51, 0.3, 0.07, -35)
    elseif name == "journal" or name == "library" then
        outline(0.15, 0.1, 0.72, 0.8)
        bar(0.27, 0.1, 0.07, 0.8)
        if name == "library" then
            bar(0.45, 0.3, 0.08, 0.45)
            bar(0.64, 0.23, 0.08, 0.52)
        else
            for i = 0, 2 do
                bar(0.44, 0.29 + i * 0.18, 0.29, 0.06)
            end
        end
    elseif name == "sleeve" then
        outline(0.1, 0.1, 0.8, 0.8)
        outline(0.25, 0.25, 0.5, 0.5, true)
        circle(0.44, 0.44, 0.12)
    elseif name == "city" then
        outline(0.1, 0.38, 0.24, 0.52)
        outline(0.39, 0.1, 0.25, 0.8)
        outline(0.69, 0.27, 0.23, 0.63)
        for _, x in { 0.18, 0.47, 0.76 } do
            bar(x, 0.5, 0.07, 0.08)
            bar(x, 0.69, 0.07, 0.08)
        end
    elseif name == "hint" then
        outline(0.21, 0.08, 0.58, 0.58, true)
        bar(0.33, 0.70, 0.34, 0.08)
        bar(0.37, 0.84, 0.26, 0.08)
        bar(0.46, 0.38, 0.08, 0.3)
    elseif name == "save" then
        outline(0.15, 0.12, 0.7, 0.76)
        outline(0.31, 0.12, 0.38, 0.28)
        outline(0.30, 0.56, 0.40, 0.31)
    elseif name == "mirror" then
        outline(0.20, 0.06, 0.60, 0.72, true)
        bar(0.46, 0.78, 0.08, 0.12)
        bar(0.28, 0.89, 0.44, 0.07)
        bar(0.35, 0.25, 0.25, 0.05, -45)
    elseif name == "bolt" then
        bar(0.30, 0.12, 0.14, 0.52, 24)
        bar(0.34, 0.43, 0.36, 0.12)
        bar(0.55, 0.45, 0.14, 0.44, 24)
    elseif name == "coil" then
        for i = 0, 3 do
            outline(0.1 + i * 0.2, 0.22, 0.2, 0.56, true)
        end
    elseif name == "lamp" then
        outline(0.25, 0.27, 0.5, 0.53)
        outline(0.35, 0.06, 0.3, 0.3, true)
        bar(0.18, 0.2, 0.64, 0.1)
        bar(0.18, 0.82, 0.64, 0.1)
        circle(0.4, 0.43, 0.2)
    elseif name == "waves" then
        for row = 0, 2 do
            for i = 0, 2 do
                bar(0.1 + i * 0.29, 0.2 + row * 0.25, 0.23, 0.08, if i % 2 == 0 then -18 else 18)
            end
        end
    elseif name == "van" then
        outline(0.08, 0.25, 0.84, 0.47)
        outline(0.13, 0.31, 0.22, 0.20)
        outline(0.41, 0.31, 0.24, 0.20)
        circle(0.19, 0.65, 0.20)
        circle(0.66, 0.65, 0.20)
    elseif name == "trash" then
        outline(0.28, 0.29, 0.44, 0.57)
        bar(0.2, 0.19, 0.6, 0.09)
        bar(0.39, 0.08, 0.22, 0.09)
        for _, x in { 0.4, 0.56 } do
            bar(x, 0.42, 0.05, 0.30)
        end
    elseif name == "undo" or name == "redo" then
        local direction = if name == "undo" then -1 else 1
        outline(0.25, 0.3, 0.53, 0.45, true)
        bar(if direction < 0 then 0.13 else 0.61, 0.2, 0.32, 0.08, 35 * direction)
        bar(if direction < 0 then 0.13 else 0.61, 0.36, 0.32, 0.08, -35 * direction)
    else
        bar(0.15, 0.44, 0.7, 0.12)
        bar(0.44, 0.15, 0.12, 0.7)
    end
    return root
end
return Icons
