-- True seven-segment hardware numerals. Text stays accessible in the adjacent BPM label.
local Gui = require(script.Parent.GuiFactory)
local Display = {}
Display.__index = Display
local patterns = {
    ["0"] = "abcdef",
    ["1"] = "bc",
    ["2"] = "abged",
    ["3"] = "abgcd",
    ["4"] = "fgbc",
    ["5"] = "afgcd",
    ["6"] = "afgecd",
    ["7"] = "abc",
    ["8"] = "abcdefg",
    ["9"] = "abfgcd",
}
function Display.new(parent)
    local self = setmetatable({ digits = {} }, Display)
    self.root = Gui.make(
        "Frame",
        parent,
        { Name = "TempoDigits", Size = UDim2.fromOffset(114, 48), BackgroundTransparency = 1 }
    )
    for i = 1, 3 do
        local digit = Gui.make(
            "Frame",
            self.root,
            {
                Position = UDim2.fromOffset((i - 1) * 38, 0),
                Size = UDim2.fromOffset(32, 48),
                BackgroundTransparency = 1,
            }
        )
        local parts = {}
        for key, box in
            {
                a = { 5, 1, 22, 4 },
                b = { 26, 5, 4, 17 },
                c = { 26, 26, 4, 17 },
                d = { 5, 44, 22, 4 },
                e = { 2, 26, 4, 17 },
                f = { 2, 5, 4, 17 },
                g = { 5, 23, 22, 4 },
            }
        do
            parts[key] = Gui.round(
                Gui.make(
                    "Frame",
                    digit,
                    {
                        Position = UDim2.fromOffset(box[1], box[2]),
                        Size = UDim2.fromOffset(box[3], box[4]),
                        BackgroundColor3 = Color3.fromRGB(243, 182, 95),
                        BorderSizePixel = 0,
                    }
                ),
                2
            )
        end
        self.digits[i] = parts
    end
    return self
end
function Display:set(value)
    local text = string.format("%03d", math.clamp(math.floor(value), 0, 999))
    for i, parts in self.digits do
        local lit = patterns[text:sub(i, i)]
        for key, part in parts do
            part.BackgroundTransparency = if lit:find(key, 1, true) then 0 else 0.92
        end
    end
end
return Display
