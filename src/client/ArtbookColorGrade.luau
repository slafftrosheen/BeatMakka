-- Reusable local material treatment, applied once per source map before binding.
-- Original pixels, alpha, UVs, normal/roughness maps and authored files are retained.
local Grade = {}
local coral = Vector3.new(202, 116, 83)
local amber = Vector3.new(243, 182, 95)
local teal = Vector3.new(111, 145, 134)
local function luminance(r, g, b)
    return r * 0.2126 + g * 0.7152 + b * 0.0722
end

function Grade.apply(image, kind, cancelled)
    if kind ~= "supplied" then
        return
    end
    local size = image.Size
    local pixels = image:ReadPixelsBuffer(Vector2.zero, size)
    for index = 0, size.X * size.Y - 1 do
        local at = index * 4
        if buffer.readu8(pixels, at + 3) > 0 then
            local r, g, b =
                buffer.readu8(pixels, at),
                buffer.readu8(pixels, at + 1),
                buffer.readu8(pixels, at + 2)
            local low, high = math.min(r, g, b), math.max(r, g, b)
            local lum = luminance(r, g, b)
            local target
            if high - low < 25 then
                target = Vector3.new(lum, lum * 0.97, lum * 0.90)
            else
                local color = if r > g * 1.12 and r > b
                    then coral
                    elseif r > b * 1.18 and g > b * 1.12 then amber
                    else teal
                local gain = lum / math.max(1, luminance(color.X, color.Y, color.Z))
                target = color * gain
            end
            local blend = 0.58
            buffer.writeu8(
                pixels,
                at,
                math.clamp(math.floor(r * (1 - blend) + target.X * blend + 0.5), 0, 255)
            )
            buffer.writeu8(
                pixels,
                at + 1,
                math.clamp(math.floor(g * (1 - blend) + target.Y * blend + 0.5), 0, 255)
            )
            buffer.writeu8(
                pixels,
                at + 2,
                math.clamp(math.floor(b * (1 - blend) + target.Z * blend + 0.5), 0, 255)
            )
        end
        if index > 0 and index % 32768 == 0 then
            task.wait()
            if cancelled() then
                return
            end
        end
    end
    if not cancelled() then
        image:WritePixelsBuffer(Vector2.zero, size, pixels)
    end
end

return Grade
