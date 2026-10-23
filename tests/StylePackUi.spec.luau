return function()
    local View = require(game.Players.LocalPlayer.PlayerScripts.Client.WorkshopView)
    local shared = game.ReplicatedStorage.Shared
    local Catalog = require(shared.SampleCatalog)
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
        finish = "quay",
        unlocked = {},
        saveMode = "session",
        dirty = false,
        restoration = 0,
        editVersion = 4,
    }
    local ok, result = pcall(function()
        view:update(state)
        view:showPage("Sounds")
        view:browsePack(1)
        local count = 0
        for _, button in view.samples do
            if button.Visible then
                count += 1
            end
        end
        assert(
            count == 16 and view.packLabel.Text:find("A minor"),
            "Kit filter or key label missing"
        )
        view:applyPack()
        assert(#commands == 0, "Kit replaced sounds without confirmation")
        state.editVersion = 5
        view:update(state)
        view:applyPack()
        assert(#commands == 0, "Stale kit confirmation was accepted")
        view:applyPack()
        assert(
            #commands == 1
                and commands[1][1] == "Pack"
                and commands[1][2] == Catalog.Packs[2].id
                and commands[1][3] == 5,
            "Confirmed kit did not bind reviewed version"
        )
        view:applyPack()
        view:browsePack(1)
        assert(view.packConfirmation == nil, "Kit browse retained old confirmation")
        view:applyPack()
        view:showPage("Play")
        assert(view.packConfirmation == nil, "Hidden kit confirmation survived navigation")
        return {
            passed = true,
            filteredSamples = 16,
            keyVisible = true,
            twoPress = true,
            staleRejected = true,
            browseAndNavigationCancel = true,
        }
    end)
    view.screen:Destroy()
    assert(ok, result)
    return result
end
