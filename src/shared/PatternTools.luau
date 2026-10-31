-- Musical transformations of a single 16-step row. The server selects the row.
local Tools = {}

function Tools.transform(row, operation)
    local result = table.clone(row)
    for step = 1, 16 do
        if operation == "left" then
            result[step] = row[step % 16 + 1]
        elseif operation == "right" then
            result[step] = row[(step - 2) % 16 + 1]
        elseif operation == "reverse" then
            result[step] = row[17 - step]
        elseif operation == "clear" then
            result[step] = false
        else
            return nil
        end
    end
    return result
end

function Tools.rhythm(hits)
    local result = table.create(16, false)
    -- Evenly distribute hits around the bar, always starting on the downbeat.
    for step = 0, 15 do
        result[step + 1] = (step * hits) % 16 < hits
    end
    return result
end

return table.freeze(Tools)
