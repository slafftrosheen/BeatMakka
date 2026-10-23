-- Explicit Studio Client test. Pending while Studio MCP is disconnected.
return function()
    local player = game.Players.LocalPlayer
    local Guide = require(player.PlayerScripts.Client.RecorderGuide)
    local screen = Instance.new("ScreenGui")
    screen.Name = "RecorderGuideQa"
    screen.Parent = player.PlayerGui
    local parent = Instance.new("ScrollingFrame")
    parent.AutomaticCanvasSize = Enum.AutomaticSize.Y
    parent.Size = UDim2.fromOffset(344, 400)
    parent.Parent = screen
    local layout = Instance.new("UIListLayout")
    layout.Parent = parent
    local guide = Guide.new(parent)
    local state = {
        unlocked = { I01 = true },
        saveMode = "session",
        neighborhood = {
            completed = 1,
            earned = { metal_pulse = true },
            objective = "Layer the vent with metal.",
        },
    }
    local ok, result = pcall(function()
        guide:update(state)
        assert(not guide.body.Visible, "Guide should start compact")
        guide:setOpen(true)
        assert(
            guide.body.Visible and guide.cards.I01.Text:find("COMPLETE", 1, true),
            "Earned job/source not visible"
        )
        assert(
            guide.cards.I02.Text:find("FIND IN THE SOUND ALLEY", 1, true),
            "Locked source provenance missing"
        )
        assert(
            guide.intro.Text:find("not microphone", 1, true),
            "Virtual recorder disclosure missing"
        )
        for _, width in { 200, 344, 740, 1000 } do
            parent.Size = UDim2.fromOffset(width, 400)
            task.wait(0.2)
            for _, card in guide.cards do
                assert(card.TextBounds.Y <= card.AbsoluteSize.Y + 1, "Source/job copy clipped")
                assert(
                    card.AbsoluteSize.X <= parent.AbsoluteSize.X,
                    "Guide outside horizontal bounds"
                )
            end
        end
        guide:setOpen(false)
        assert(not guide.body.Visible, "Guide did not collapse")
        return { passed = true, widths = { 200, 344, 740, 1000 }, sources = 3 }
    end)
    screen:Destroy()
    assert(ok, result)
    return result
end
