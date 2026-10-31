-- selene: allow(global_usage)
-- Deliberate temporary probe state shared only between Studio MCP QA calls.
-- Run in Studio's Client DataModel after mpc_client_probe.luau.
local qa = _G.NQQA
local root = game.Players.LocalPlayer.PlayerGui.NeedleQuayInstrument.Workstation
local song = root:FindFirstChild("Song", true)
local results = {}
local function check(name, action)
    local ok, detail = xpcall(action, debug.traceback)
    table.insert(results, { name = name, passed = ok, detail = tostring(detail or "ok") })
end
local function field(placeholder)
    for _, v in root:GetDescendants() do
        if v:IsA("TextBox") and v.PlaceholderText == placeholder then
            return v
        end
    end
    error("Missing field " .. placeholder)
end
check("Song page exposes live position and pause control", function()
    local status = song:FindFirstChild("SongPosition")
    assert(status and status:IsA("TextLabel"), "Song position is hidden in the Sequence page")
    local found = false
    for _, v in song:GetDescendants() do
        if v:IsA("TextButton") and v.Text == "Play / pause" then
            found = true
        end
    end
    assert(found, "Song page has no touch-accessible pause control")
    return status.Text
end)
check("Arrangement step labels and controls use authored order", function()
    local count = 0
    for _, v in song:GetDescendants() do
        if v:IsA("UIListLayout") then
            assert(
                v.SortOrder == Enum.SortOrder.LayoutOrder,
                "Song list sorts by instance name instead of step order"
            )
            count += 1
        end
    end
    assert(count >= 2, "Expected: count >= 2")
    return "Step headings stay paired with their controls"
end)
check("Bar and Song BPM fields reflect the selected objects", function()
    assert(
        tonumber(field("Bars (1–64)").Text) == qa.state.music.sequence.bars,
        "Bars field shows another sequence's length"
    )
    assert(
        tonumber(field("Song BPM").Text) == qa.state.music.draft.bpm,
        "Song tempo field differs from saved draft"
    )
    return "Displayed values match server-owned selection"
end)
local failures = 0
for _, result in results do
    if not result.passed then
        failures += 1
    end
end
return { suite = "MPC UI assertions", tests = #results, failures = failures, results = results }
