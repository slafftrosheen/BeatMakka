-- Client Studio integration check for the five-second confirmation deadline.
-- Invoked explicitly through MCP; excluded from the production project.
return function()
    local player = game.Players.LocalPlayer
    local View = require(player.PlayerScripts.Client.BeatBookView)
    local screen = Instance.new("ScreenGui")
    screen.Name = "MilestoneConfirmationQa"
    screen.Parent = player.PlayerGui
    local frame = Instance.new("Frame")
    frame.Visible = false
    frame.Parent = screen
    local commands = {}
    local view = View.new(frame, {
        command = function(...)
            table.insert(commands, { ... })
        end,
        notice = function() end,
    })
    local state = {
        ready = true,
        station = "Station_1",
        saving = false,
        saveMode = "session",
        editVersion = 1,
        book = { activeSlot = 1, slots = {}, shelf = {} },
    }
    for index = 1, 4 do
        state.book.slots[index] = { label = tostring(index), bpm = 96, hasNotes = true }
    end
    for index = 1, 6 do
        state.book.shelf[index] = { exists = true, version = 1, saved = true, populated = 1 }
    end
    local ok, err = pcall(function()
        view:update(state)
        view:act("ShelfStore")
        assert(
            #commands == 0 and view.store.Text == "Replace Beat 01?",
            "Replacement skipped confirmation"
        )
        task.wait(5.2)
        assert(
            view.confirmation == nil and view.store.Text == "Save to shelf",
            "Expired text remained visible"
        )
        view:act("ShelfStore")
        assert(#commands == 0, "Expired confirmation was accepted")
        view:act("ShelfStore")
        assert(
            #commands == 1 and commands[1][1] == "ShelfStore" and commands[1][3] == 1,
            "Confirmed overwrite did not send the expected shelf version"
        )
        view:act("ShelfLoad")
        state.editVersion += 1
        view:update(state)
        assert(view.confirmation == nil, "Editing did not cancel a pending load")
    end)
    screen:Destroy()
    assert(ok, err)
    return {
        passed = true,
        expirySeconds = 5,
        replacementRequiresTwoClicks = true,
        editCancelsLoad = true,
    }
end
