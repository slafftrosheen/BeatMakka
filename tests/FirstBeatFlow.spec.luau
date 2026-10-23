return function()
    local player = game.Players.LocalPlayer
    local View = require(player.PlayerScripts.Client.WorkshopView)
    local shared = game.ReplicatedStorage.Shared
    local commands = {}
    local view = View.new({
        command = function(...)
            table.insert(commands, { ... })
        end,
        tap = function()
            return false
        end,
        mute = function() end,
        effects = function() end,
    })
    local state = {
        ready = true,
        station = "Station_1",
        pattern = require(shared.Pattern).new(),
        finish = require(shared.CosmeticCatalog).Order[1],
        unlocked = {},
        saveMode = "session",
        hasSave = true,
        dirty = true,
        restoration = 0,
        editVersion = 7,
    }
    local ok, result = pcall(function()
        view:update(state)
        view:showPage("Settings")
        view:restoreSlots()
        assert(#commands == 0, "Restore lost edits without confirmation")
        state.editVersion = 8
        view:update(state)
        view:restoreSlots()
        assert(#commands == 0, "Stale confirmation accepted")
        view:restoreSlots()
        assert(
            #commands == 1 and commands[1][1] == "Restore" and commands[1][2] == 8,
            "Confirmed restore did not send its reviewed edit version"
        )
        view:restoreSlots()
        view:showPage("Play")
        assert(view.restoreConfirmation == nil, "Hidden restore confirmation survived")
        view:showPage("Settings")
        view:restoreSlots()
        view.restoreConfirmation.expires = os.clock() - 1
        view:update(state)
        assert(view.restoreConfirmation == nil, "Expired confirmation survived")
        view.panel:FindFirstChildOfClass("UISizeConstraint"):Destroy()
        for _, size in { Vector2.new(360, 720), Vector2.new(740, 260) } do
            view.panel.Size = UDim2.fromOffset(size.X, size.Y)
            task.wait(0.1)
            for _, page in { "Play", "Steps", "Sounds", "Beats", "Settings" } do
                view:showPage(page)
                task.wait()
                assert(
                    view.noticeLabel.TextFits,
                    "Guide does not fit " .. page .. " at " .. tostring(size)
                )
            end
        end
        state.hasSave = false
        state.dirty = false
        view:update(state)
        assert(view.status.Text:find("NEW"), "Unsaved new project claims SAVED")
        view:restoreSlots()
        assert(#commands == 1, "No-save restore was sent")
        state.hasSave = true
        view:update(state)
        assert(view.status.Text:find("SESSION SAVED"), "Session persistence boundary hidden")
        state.saveMode = "unavailable"
        view:update(state)
        assert(view.status.Text:find("TEMPORARY"), "Unavailable save claims durability")
        return {
            passed = true,
            restoreRequiresConfirmation = true,
            staleConfirmationRejected = true,
            navigationCancels = true,
            saveLabels = true,
        }
    end)
    view.screen:Destroy()
    assert(ok, result)
    return result
end
