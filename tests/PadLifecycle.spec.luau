return function()
    local player = game.Players.LocalPlayer
    local View = require(player.PlayerScripts.Client.WorkshopView)
    local shared = game.ReplicatedStorage.Shared
    local hits, interruptions = 0, 0
    local view = View.new({
        command = function() end,
        tap = function()
            hits += 1
            return false
        end,
        mute = function() end,
        effects = function() end,
        interrupt = function()
            interruptions += 1
        end,
    })
    local ok, result = pcall(function()
        local state = {
            ready = true,
            station = "Station_1",
            pattern = require(shared.Pattern).new(),
            finish = require(shared.CosmeticCatalog).Order[1],
            unlocked = {},
            saveMode = "session",
            dirty = false,
            restoration = 0,
        }
        view:update(state)
        task.wait()
        local token = {}
        assert(view:beginPad(1, token), "Live pad blocked")
        view:showPage("Steps")
        assert(next(view.padInput.active) == nil, "Page exit left held input")
        assert(not view:beginPad(2, {}), "Hidden Play accepted input")
        view:showPage("Play")
        assert(view:beginPad(1, token), "Released token cannot retrigger")
        view:cancelInput(true)
        assert(not view.pads[1]:GetAttribute("Held"), "Interruption left visual held")
        local before = interruptions
        view:beginPad(2, {})
        view.screen.ScreenInsets = Enum.ScreenInsets.None
        task.wait(0.2)
        assert(
            interruptions > before and next(view.padInput.active) == nil,
            "Viewport change did not cancel"
        )
        state.station = nil
        view:update(state)
        assert(not view:beginPad(1, {}), "Released station accepted input")
        view.screen:Destroy()
        assert(
            view.padInput.destroyed
                and not view.endedConnection.Connected
                and not view.viewportConnection.Connected,
            "View leaked input connections"
        )
        return { passed = true, hits = hits, viewportCancellation = true, cleanup = true }
    end)
    if view.screen.Parent then
        view.screen:Destroy()
    end
    assert(ok, result)
    return result
end
