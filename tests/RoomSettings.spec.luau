-- Client integration: callbacks and native layout, not physical input acceptance.
return function()
    local player = game.Players.LocalPlayer
    local View = require(player.PlayerScripts.Client.WorkshopView)
    local commands = {}
    local view = View.new({
        command = function(...)
            table.insert(commands, { ... })
        end,
        tap = function() end,
        mute = function() end,
        effects = function() end,
    })
    local shared = game.ReplicatedStorage.Shared
    local state = {
        ready = true,
        station = "Station_1",
        pattern = require(shared.Pattern).new(),
        finish = "quay",
        unlocked = {},
        saveMode = "session",
        dirty = false,
        restoration = 0,
        room = {
            id = "Room_1",
            stationId = "Station_1",
            choices = { finish = "quay", sign = "records", decor = "none" },
            decorUnlocked = false,
        },
    }
    local ok, result = pcall(function()
        view:update(state)
        view:showPage("Settings")
        local room = view.roomSettings
        room:cycle("finish")
        room:cycle("sign")
        room:cycle("decor")
        room:cycle("owner")
        assert(
            #commands == 2
                and commands[1][1] == "Room"
                and commands[1][2] == "finish"
                and commands[1][3] == "chalk"
                and commands[2][3] == "beats",
            "Room callbacks or locked decor incorrect"
        )
        assert(not room.buttons.decor.Selectable, "Locked decor is focusable")
        state.room.decorUnlocked = true
        view:update(state)
        room:cycle("decor")
        assert(#commands == 3 and commands[3][3] == "vinyl", "Unlocked decor cannot be selected")
        local results = {}
        view.panel:FindFirstChildOfClass("UISizeConstraint"):Destroy()
        for _, size in
            {
                Vector2.new(360, 720),
                Vector2.new(740, 260),
                Vector2.new(820, 1060),
                Vector2.new(1024, 720),
            }
        do
            view.panel.Size = UDim2.fromOffset(size.X, size.Y)
            task.wait(0.2)
            local settings = view.pages.Settings
            assert(
                settings:IsA("ScrollingFrame")
                    and settings.ScrollingDirection == Enum.ScrollingDirection.Y,
                "Settings must scroll independently of performance"
            )
            for _, button in room.buttons do
                assert(button.AbsoluteSize.Y >= 44, "Room control too small")
                assert(
                    button.AbsolutePosition.X >= settings.AbsolutePosition.X
                        and button.AbsolutePosition.X + button.AbsoluteSize.X
                            <= settings.AbsolutePosition.X + settings.AbsoluteSize.X,
                    "Room control outside horizontal bounds"
                )
            end
            assert(
                room.title.TextBounds.Y <= room.title.AbsoluteSize.Y + 1,
                "Owner/status copy clipped"
            )
            assert(
                settings.AbsoluteCanvasSize.Y
                    >= room.buttons.decor.AbsolutePosition.Y
                        - settings.AbsolutePosition.Y
                        + settings.CanvasPosition.Y
                        + room.buttons.decor.AbsoluteSize.Y
                        - 1,
                "Last room control unreachable"
            )
            table.insert(results, tostring(size))
        end
        state.room.id = nil
        view:update(state)
        room:cycle("finish")
        assert(
            #commands == 3
                and not room.buttons.finish.Selectable
                and string.find(room.title.Text, "Visitor", 1, true),
            "Visitor UI permits editing"
        )
        return {
            passed = true,
            sizes = results,
            lockedAndVisitorCallbacksBlocked = true,
            nativeControls = 3,
        }
    end)
    view.screen:Destroy()
    assert(ok, result)
    return result
end
