-- Run in Studio Client after mpc_client_probe.luau; uses real bank commands.
-- selene: allow(global_usage)
local qa = _G.NQQA
local gui = game.Players.LocalPlayer.PlayerGui
local results = {}
local function check(name, action)
    local ok, detail = xpcall(action, debug.traceback)
    table.insert(results, { name = name, passed = ok, detail = tostring(detail or "ok") })
end
local function luminance(color)
    local function channel(value)
        return if value <= 0.04045 then value / 12.92 else ((value + 0.055) / 1.055) ^ 2.4
    end
    return channel(color.R) * 0.2126 + channel(color.G) * 0.7152 + channel(color.B) * 0.0722
end
check("Chapter story remains readable on the journal panel", function()
    local journal = gui.NeedleQuayJournal.Journal
    local text = journal.Content.ChapterStory.ChapterText
    local a, b = luminance(text.TextColor3), luminance(journal.BackgroundColor3)
    local contrast = (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05)
    assert(contrast >= 4.5, "Story text blends into its panel")
    return string.format("Text contrast %.2f:1", contrast)
end)
check("Hardware display follows all four absolute bank addresses", function()
    local display = gui.NeedleQuayInstrument.Workstation.HardwareDisplay
    local sequenceId = qa.state.music.sequenceId
    local physical = 2
    for _, pad in
        gui.NeedleQuayInstrument.Workstation.DeviceBody.PerformanceDeck.PhysicalPads:GetChildren()
    do
        if pad:IsA("TextButton") and pad:GetAttribute("PadSelected") then
            physical = tonumber(pad.Name:match("%d+"))
        end
    end
    for bank = 1, 4 do
        qa.command("Bank", bank)
        local expected = string.char(64 + bank) .. string.format("%02d / STOPPED", physical)
        local found = false
        for _, label in display:GetChildren() do
            if label:IsA("TextLabel") and label.Text == expected then
                found = true
            end
        end
        assert(found, "Missing address " .. expected)
        assert(qa.state.music.sequenceId == sequenceId, "Bank switch selected another sequence")
    end
    qa.command("Bank", 1)
    return "All four bank addresses follow the selected physical pad; sequence unchanged"
end)
check("First Light pin teaches the finished-song finale", function()
    local catalog = require(game.ReplicatedStorage.Shared.WardrobeCatalog)
    local text = catalog.Items.lantern_pin.unlockHint
    assert(
        text:find("Finished Song", 1, true) and not text:find("six", 1, true),
        "Pin still teaches the superseded finale"
    )
    return text
end)
check("Wardrobe mirror allocates no hidden world or camera", function()
    local viewport = gui.NeedleQuayJournal:FindFirstChild("YourWornAvatar", true)
    assert(viewport, "Wardrobe mirror viewport missing")
    assert(
        not viewport:FindFirstChildWhichIsA("WorldModel") and viewport.CurrentCamera == nil,
        "Hidden mirror retained its scene"
    )
    return "Mirror is on demand; journal is closed during the instrument session"
end)
local failures = 0
for _, result in results do
    if not result.passed then
        failures += 1
    end
end
return { suite = "V3 presentation", tests = #results, failures = failures, results = results }
