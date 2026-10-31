-- selene: allow(global_usage)
-- Real local player commands and observation; no fake readiness, no cloud writes.
local network = game.ReplicatedStorage:WaitForChild("MusicNetwork", 120)
local qa = { states = 0, deltas = 0, soundStarts = {}, connections = {} }
-- selene: allow(global_usage)
_G.NQV4 = qa
table.insert(
    qa.connections,
    network.State.OnClientEvent:Connect(function(state)
        qa.state = state
        qa.states += 1
    end)
)
table.insert(
    qa.connections,
    network.Delta.OnClientEvent:Connect(function()
        qa.deltas += 1
    end)
)
function qa.command(action, a, b, predicate)
    local before = qa.states
    network.Command:FireServer(action, a, b)
    local started = os.clock()
    local deadline = started + (if action == "QuayEnter" then 20 else 5)
    repeat
        task.wait(0.02)
    until qa.states > before
            and os.clock() - started > 0.2
            and (not predicate or predicate(qa.state))
        or os.clock() > deadline
    assert(
        qa.states > before and (not predicate or predicate(qa.state)),
        "No expected state: " .. action
    )
    return qa.state
end
local function watch(sound)
    if sound:IsA("Sound") and sound.Name:find("nq.harbour", 1, true) then
        table.insert(
            qa.connections,
            sound.Played:Connect(function()
                table.insert(qa.soundStarts, {
                    name = sound.Name,
                    at = os.clock(),
                    duration = sound.TimeLength,
                    group = sound.SoundGroup and sound.SoundGroup.Name,
                })
            end)
        )
    end
end
for _, sound in game.SoundService:GetChildren() do
    watch(sound)
end
table.insert(qa.connections, game.SoundService.ChildAdded:Connect(watch))
local readyDeadline = os.clock() + 90
repeat
    network.Command:FireServer("Hello")
    task.wait(0.5)
until qa.state
        and qa.state.ready
        and qa.state.quay
        and (qa.state.quay.nearVan or qa.state.station)
    or os.clock() > readyDeadline
assert(qa.state and qa.state.ready, "Player profile did not become ready")
qa.command("QuayClose")
qa.command("QuayEnter", nil, nil, function(s)
    return s.station ~= nil
end)
qa.command("Stop")
return {
    station = qa.state.station,
    saveMode = qa.state.saveMode,
    localKit = #require(game.ReplicatedStorage.Shared.SampleCatalog).List,
    ui = game.Players.LocalPlayer.PlayerGui:FindFirstChild("NeedleQuayInstrument") ~= nil,
}
