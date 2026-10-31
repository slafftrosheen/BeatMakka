-- Weight matching keeps close but distinct vertices separate at UV/material seams.
local Lookup = {}
function Lookup.new(rows)
    local buckets = {}
    local function key(x, y, z)
        return string.format("%d:%d:%d", x, y, z)
    end
    for _, row in rows do
        local p = Vector3.new(table.unpack(row[1]))
        local k = key(math.floor(p.X * 1000), math.floor(p.Y * 1000), math.floor(p.Z * 1000))
        buckets[k] = buckets[k] or {}
        table.insert(buckets[k], { position = p, weights = row[2] })
    end
    return function(p)
        local x, y, z = math.floor(p.X * 1000), math.floor(p.Y * 1000), math.floor(p.Z * 1000)
        local closest, distance = nil, math.huge
        for dx = -2, 2 do
            for dy = -2, 2 do
                for dz = -2, 2 do
                    for _, row in buckets[key(x + dx, y + dy, z + dz)] or {} do
                        local delta = (row.position - p).Magnitude
                        if delta < distance then
                            closest, distance = row.weights, delta
                        end
                    end
                end
            end
        end
        assert(closest and distance < 0.002, "Skin weight vertex does not match its source")
        return closest, distance
    end
end
return Lookup

