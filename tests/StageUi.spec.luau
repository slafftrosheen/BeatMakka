-- Explicit Studio Client routing/layout contract; no physical-input claim.
return function()
    local function expect(value, message)
        assert(value, message or debug.traceback("StageUi contract failed", 2))
    end
    local client = game.Players.LocalPlayer.PlayerScripts.Client
    local policy = require(client.CommandPolicy)
    expect(policy(nil, "StageClose"))
    expect(policy({ ready = true, stage = { open = true } }, "StagePrepare"))
    expect(not policy({ ready = true }, "StagePrepare"))
    expect(not policy({ ready = true, stage = { open = true } }, "Step"))
    local screen = Instance.new("ScreenGui")
    screen.Name = "StageUiQa"
    screen.Parent = game.Players.LocalPlayer.PlayerGui
    local view = require(client.StageView).new(screen, function() end, function() end)
    local listener = require(client.ListeningView).new(screen, function() end, function() end)
    local ok, result = pcall(function()
        view:update({
            open = true,
            performer = "Another artist",
            queue = { "Next artist" },
            position = 1,
            canStart = false,
            requesting = true,
            listening = false,
            hosting = false,
        }, true, "Stage is occupied.")
        expect(not view.start.Active and view.join.Active)
        expect(view.mute.Text:find("MUTED", 1, true))
        expect(view.label.Text:find("Stage is occupied.", 1, true))
        view.panel:FindFirstChildOfClass("UISizeConstraint"):Destroy()
        listener:update(
            { hosting = false, performer = "Another artist", pattern = { bpm = 96 } },
            "Audio unavailable",
            true
        )
        for _, size in { Vector2.new(280, 260), Vector2.new(360, 720), Vector2.new(740, 260) } do
            view.panel.Size = UDim2.fromOffset(size.X, size.Y)
            task.wait(0.2)
            expect(view.close.AbsoluteSize.Y >= 44 and view.mute.AbsoluteSize.Y >= 44)
            expect(
                view.close.AbsolutePosition.Y + view.close.AbsoluteSize.Y
                    <= view.panel.AbsolutePosition.Y + view.panel.AbsoluteSize.Y
            )
            expect(listener.mute.AbsoluteSize.Y >= 44 and listener.leave.AbsoluteSize.Y >= 44)
            expect(view.label.TextBounds.Y <= view.label.AbsoluteSize.Y + 1)
        end
        game.GuiService.SelectedObject = view.prepare
        view:update({ open = false, queue = {}, requesting = false, listening = false }, false)
        expect(
            game.GuiService.SelectedObject ~= view.prepare,
            "Focus remained on hidden stage control"
        )
        return { passed = true, layouts = 3, listenerMute = true, routing = true }
    end)
    screen:Destroy()
    expect(ok, result)
    return result
end
