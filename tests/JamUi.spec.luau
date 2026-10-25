-- Explicit Studio Client: native geometry/focus assertions, no synthetic click claim.
return function()
    local player = game.Players.LocalPlayer
    local View = require(player.PlayerScripts.Client.JamView)
    local screen = Instance.new("ScreenGui")
    screen.Name = "JamUiCheck"
    screen.Parent = player.PlayerGui
    local old = game.GuiService.SelectedObject
    local view = View.new(screen, function() end, function() end)
    local ok, result = pcall(function()
        local idle = { open = true, active = false }
        view:update(idle, false)
        assert(game.GuiService.SelectedObject == view.join, "Opening focus")
        local active = {
            open = true,
            active = true,
            conductor = true,
            session = {
                bpm = 120,
                pack = "triphop",
                pending = {},
                tracks = {
                    ["1"] = { name = "Rhythm", ownerUserId = 1 },
                    ["2"] = { name = "Melody", ownerUserId = 2 },
                },
            },
        }
        view:update(active, false)
        assert(
            game.GuiService.SelectedObject == view.publish and not view.join.Visible,
            "Join focus not advanced"
        )
        game.GuiService.SelectedObject = view.up
        active.conductor = false
        view:update(active, true)
        assert(
            game.GuiService.SelectedObject == view.publish and not view.up.Visible,
            "Handoff focus"
        )
        assert(view.mute.Text:find("MUTED"), "Mute affordance")
        view.panel:FindFirstChildOfClass("UISizeConstraint"):Destroy()
        local sizes = {
            Vector2.new(360, 720),
            Vector2.new(740, 260),
            Vector2.new(820, 1060),
            Vector2.new(1024, 720),
        }
        for _, size in sizes do
            view.panel.Size = UDim2.fromOffset(size.X, size.Y)
            task.wait(0.1)
            for _, button in { view.mute, view.close } do
                local p, s = button.AbsolutePosition, button.AbsoluteSize
                local q, t = view.panel.AbsolutePosition, view.panel.AbsoluteSize
                assert(s.X >= 44 and s.Y >= 44, "Touch target")
                assert(
                    p.X >= q.X and p.Y >= q.Y and p.X + s.X <= q.X + t.X and p.Y + s.Y <= q.Y + t.Y,
                    "Footer clipped"
                )
            end
            assert(
                view.panel.Actions.ScrollingDirection == Enum.ScrollingDirection.Y,
                "Short viewport scrolling"
            )
        end
        view:update({ open = false, active = false }, false)
        assert(not view.panel.Visible and game.GuiService.SelectedObject == nil, "Close selection")
        return {
            passed = true,
            layouts = #sizes,
            openingJoinAndHandoffFocus = true,
            footerBounds = true,
            scrolling = true,
        }
    end)
    screen:Destroy()
    game.GuiService.SelectedObject = old
    assert(ok, result)
    return result
end
