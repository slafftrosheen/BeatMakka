-- Run explicitly in Studio Client; excluded from the production project.
return function()
    local player = game:GetService("Players").LocalPlayer
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
    local ok, result = pcall(function()
        assert(view.pages and view.pages.Play, "Dedicated Play page missing")
        assert(view.pages.Sounds and view.pages.Beats and view.pages.Settings, "Pages missing")
        local function bounds(inner, outer)
            local p, s = inner.AbsolutePosition, inner.AbsoluteSize
            local q, t = outer.AbsolutePosition, outer.AbsoluteSize
            return p.X >= q.X - 1
                and p.Y >= q.Y - 1
                and p.X + s.X <= q.X + t.X + 1
                and p.Y + s.Y <= q.Y + t.Y + 1
        end
        local sizes = {
            Vector2.new(360, 720),
            Vector2.new(740, 328),
            Vector2.new(742, 315),
            Vector2.new(740, 260),
            Vector2.new(820, 1060),
            Vector2.new(1024, 720),
        }
        view.panel.Visible = true
        view.panel:FindFirstChildOfClass("UISizeConstraint"):Destroy()
        local results = {}
        for _, size in sizes do
            view.panel.Size = UDim2.fromOffset(size.X, size.Y)
            view:showPage("Play")
            task.wait(0.15)
            local ancestor = view.pads[1].Parent
            while ancestor ~= view.panel do
                assert(not ancestor:IsA("ScrollingFrame"), "Performance can scroll")
                ancestor = ancestor.Parent
            end
            local origin = view.pads[1].AbsolutePosition
            for index, button in view.pads do
                assert(bounds(button, view.pages.Play), "Pad outside Play page: " .. index)
                assert(button.AbsoluteSize.X >= 44 and button.AbsoluteSize.Y >= 44, "Pad too small")
                if index > 1 then
                    local previous = view.pads[index - 1]
                    assert(button.AbsolutePosition ~= previous.AbsolutePosition, "Pads overlap")
                end
                local cell = view.pads[1].AbsoluteSize
                local expected = origin
                    + Vector2.new(
                        (index - 1) % 4 * (cell.X + 6),
                        math.floor((index - 1) / 4) * (cell.Y + 6)
                    )
                assert((button.AbsolutePosition - expected).Magnitude < 1, "Grid is not 4 by 4")
            end
            view:showPage("Sounds")
            view:showPage("Play")
            task.wait()
            assert(view.pads[1].AbsolutePosition == origin, "Page change moved pads")
            assert(view.stop.Visible and view.stop.Parent.Visible, "Stop unavailable")
            for _, button in view.panel.Navigation:GetChildren() do
                if button:IsA("TextButton") then
                    assert(bounds(button, view.panel), "Navigation outside panel: " .. button.Name)
                end
            end
            table.insert(results, tostring(size))
        end
        view.bookView.confirmation = { action = "ShelfStore" }
        view:showPage("Settings")
        assert(view.bookView.confirmation == nil, "Hidden shelf confirmation survived")
        assert(#commands == 0, "Navigation changed music")
        local shared = game:GetService("ReplicatedStorage").Shared
        local state = {
            ready = true,
            station = "Station_1",
            pattern = require(shared.Pattern).new(),
            finish = require(shared.CosmeticCatalog).Order[1],
            unlocked = {},
            saveMode = "session",
            dirty = true,
            restoration = 0,
        }
        view.panel.Size = UDim2.fromOffset(360, 720)
        view:update(state)
        view:notice("A shelf message must not hide transport or saving status.")
        state.recording = true
        state.saving = true
        view:update(state)
        task.wait()
        assert(
            view.status.Text:find("REC") and view.status.Text:find("SAVING"),
            "Notice hides status"
        )
        assert(view.status.TextBounds.Y <= view.status.AbsoluteSize.Y, "Portrait status is clipped")
        assert(view.noticeLabel.Text:find("shelf message"), "Notice is lost")
        return { passed = true, testedSizes = results, pads = #view.pads }
    end)
    view.screen:Destroy()
    assert(ok, result)
    return result
end
