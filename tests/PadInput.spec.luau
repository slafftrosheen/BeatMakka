return function()
    local player = game:GetService("Players").LocalPlayer
    local Input = require(player.PlayerScripts.Client.PadInput)
    local hits, held = {}, {}
    local input = Input.new(function(pad)
        table.insert(hits, pad)
        return false -- No configured sound bank in this isolated test.
    end, function(pad, value)
        held[pad] = value
    end)
    local tokens = {}
    for pad = 1, 16 do
        tokens[pad] = {}
        assert(input:begin(pad, tokens[pad]))
        assert(not input:begin(pad, tokens[pad]), "Duplicate begin hit twice")
    end
    assert(#hits == 16, "Simultaneous chord lost hits")
    for pad = 1, 16 do
        assert(held[pad], "Pad did not show held state")
        input:finish(tokens[pad])
        assert(not held[pad], "Pad stayed held after release")
    end
    for _ = 1, 64 do
        assert(input:begin(1, tokens[1]))
        input:finish(tokens[1])
    end
    assert(#hits == 80, "Roll missed or duplicated hits")
    local second = {}
    input:begin(2, tokens[2])
    input:begin(2, second)
    input:finish(tokens[2])
    assert(held[2], "First release cancelled another finger")
    input:cancel()
    assert(not held[2] and next(input.active) == nil, "Cancellation left held input")
    assert(not input:begin(0, {}) and not input:begin(17, {}), "Invalid pad accepted")
    input:destroy()
    assert(not input:begin(1, {}), "Destroyed owner accepted a hit")
    local metrics = input:diagnostics()
    assert(metrics.hits == 82 and metrics.submitted == 0, "Unavailable audio counted as audible")
    return { passed = true, hits = #hits, submitted = metrics.submitted, chord = 16, roll = 64 }
end
