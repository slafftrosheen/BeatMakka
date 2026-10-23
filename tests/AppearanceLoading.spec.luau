-- Exercise the real template lifecycle with controlled async creation, no uploads.
return function()
    local Appearance = require(game.Players.LocalPlayer.PlayerScripts.Client.DeviceAppearance)
    local storage = game.ReplicatedStorage
    local library = storage:FindFirstChild("AppearanceLibrary")
    if library then
        library.Parent = nil
    end
    local renderers = {}
    local function renderer(factory)
        local value = Appearance.new(factory)
        table.insert(renderers, value)
        return value
    end
    local ok, result = pcall(function()
        local completed = Instance.new("SurfaceAppearance")
        local calls = 0
        local ready = renderer(function()
            calls += 1
            task.wait()
            return completed
        end)
        assert(ready:template("quay", 512) == nil, "Async creation did not return pending")
        assert(ready.pending.quay_512 == "loading", "Loading status missing")
        ready:template("quay", 512)
        task.wait(0.1)
        assert(calls == 1 and ready:template("quay", 512) == completed, "Template was not cached")
        ready:destroy()
        assert(not pcall(function()
            completed.Parent = storage
        end), "Owned template survived teardown")
        local failedCalls = 0
        local failed = renderer(function()
            failedCalls += 1
            error("Expected QA import failure")
        end)
        failed:template("quay", 512)
        task.wait()
        failed:template("quay", 512)
        assert(
            failed.pending.quay_512 == "failed" and failedCalls == 1,
            "Failure retries or status incorrect"
        )
        local late = Instance.new("SurfaceAppearance")
        local loading = renderer(function()
            task.wait(0.1)
            return late
        end)
        loading:template("quay", 512)
        loading:destroy()
        task.wait(0.2)
        assert(not pcall(function()
            late.Parent = storage
        end), "Late result survived destruction")
        assert(
            next(loading.templates) == nil and next(loading.pending) == nil,
            "Destroyed renderer repopulated caches"
        )
        assert(loading:template("chalk", 1024) == nil, "Destroyed renderer restarted loading")
        return {
            passed = true,
            loading = true,
            cached = true,
            failureBounded = true,
            ownedDisposed = true,
            lateDisposed = true,
        }
    end)
    for _, value in renderers do
        value:destroy()
    end
    if library then
        library.Parent = storage
    end
    assert(ok, result)
    return result
end
