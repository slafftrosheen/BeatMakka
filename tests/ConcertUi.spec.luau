-- Explicit Studio Client routing/layout regression; no physical-input claim.
return function()
    local client = game.Players.LocalPlayer.PlayerScripts.Client
    local policy = require(client.CommandPolicy)
    assert(
        policy({ ready = true, concert = { open = true } }, "ChapterStart"),
        "Chapter Start blocked away from workstation"
    )
    assert(policy(nil, "ChapterClose"), "Cleanup Close blocked without state")
    assert(not policy({ ready = true }, "ChapterStart"), "Closed chapter routed")
    assert(
        not policy({ ready = true, concert = { open = true } }, "Step"),
        "Chapter grants instrument editing"
    )
    local screen = Instance.new("ScreenGui")
    screen.Name = "ConcertUiQa"
    screen.Parent = game.Players.LocalPlayer.PlayerGui
    local view = require(client.ConcertView).new(screen, function() end, function() end)
    local ok, result = pcall(function()
        view:update({
            open = true,
            eligible = true,
            phase = 0,
            hint = "Choose your saved beat.",
            checkpoint = 0,
            completed = false,
        }, "cloud", false, "Save failed. Your progress is temporary.", false, true)
        assert(
            view.label.Text:find("Save failed", 1, true)
                and view.label.Text:find("UNSAVED", 1, true),
            "Save failure hidden behind concert panel"
        )
        assert(not view.action.Active, "Arrangement action enabled before Start")
        view.panel:FindFirstChildOfClass("UISizeConstraint"):Destroy()
        for _, size in
            {
                Vector2.new(280, 260),
                Vector2.new(360, 720),
                Vector2.new(740, 260),
                Vector2.new(600, 640),
            }
        do
            view.panel.Size = UDim2.fromOffset(size.X, size.Y)
            task.wait(0.2)
            assert(
                view.close.AbsoluteSize.Y >= 44 and view.mute.AbsoluteSize.Y >= 44,
                "Exit/mute target too small"
            )
            assert(
                view.close.AbsolutePosition.Y + view.close.AbsoluteSize.Y
                    <= view.panel.AbsolutePosition.Y + view.panel.AbsoluteSize.Y,
                "Exit outside panel"
            )
            assert(
                view.label.TextBounds.Y <= view.label.AbsoluteSize.Y + 1,
                "Concert notice clipped"
            )
        end
        return {
            passed = true,
            clientRouting = true,
            saveNoticeVisible = true,
            shortLayoutSizes = 4,
        }
    end)
    screen:Destroy()
    assert(ok, result)
    return result
end
