-- selene: allow(global_usage)
-- Deliberate temporary probe state shared only between Studio MCP QA calls.
-- Temporary Studio Client probe: observes real remotes and drives normal commands.
local network = game.ReplicatedStorage:WaitForChild("MusicNetwork", 120)
local qa = { states = 0, deltas = 0, checks = {}, counter = 0 }
-- selene: allow(global_usage)
_G.NQQA = qa
network.State.OnClientEvent:Connect(function(state)
    qa.state = state
    qa.states += 1
end)
network.Delta.OnClientEvent:Connect(function(delta)
    qa.lastDelta = delta
    qa.deltas += 1
end)
function qa.command(action, a, b, predicate)
    local before = qa.states
    network.Command:FireServer(action, a, b)
    local deadline = os.clock() + 4
    repeat
        task.wait(0.03)
    until (qa.states > before and (not predicate or predicate(qa.state))) or os.clock() > deadline
    assert(
        qa.states > before and (not predicate or predicate(qa.state)),
        "No expected state for " .. action
    )
    return qa.state
end
function qa.control(text, isBox)
    local screen = game.Players.LocalPlayer.PlayerGui:FindFirstChild("NeedleQuayInstrument")
    assert(screen, "Instrument GUI is missing")
    for _, v in screen:GetDescendants() do
        if
            (isBox and v:IsA("TextBox") and v.PlaceholderText == text)
            or (not isBox and v:IsA("TextButton") and v.Text == text)
        then
            local node = v
            while node and node ~= game.Players.LocalPlayer.PlayerGui do
                if node.Name == "Frame" or node.Name == "TextButton" or node.Name == "TextBox" then
                    qa.counter += 1
                    node.Name = "QAControl_" .. qa.counter
                end
                node = node.Parent
            end
            local page = v:FindFirstAncestorWhichIsA("ScrollingFrame")
            if page then
                page.CanvasPosition = Vector2.new(
                    0,
                    page.CanvasPosition.Y + v.AbsolutePosition.Y - page.AbsolutePosition.Y - 12
                )
            end
            return v:GetFullName():gsub("^Players%.[^.]+", "LocalPlayer")
        end
    end
    error("Missing control: " .. text)
end
qa.command("Hello")
qa.command("QuayClose")
qa.command("QuayJournal")
qa.command("QuayEnter", nil, nil, function(s)
    return s.station ~= nil
end)
qa.command("SequenceRename", { name = "QA Harbour Intro" }, nil, function(s)
    return s.music.sequence.name == "QA Harbour Intro"
end)
qa.command("SequenceLength", { bars = 1 })
qa.command("Bpm", 180)
qa.command("Step", 1, 1)
qa.intro = qa.state.music.sequenceId
qa.command("SequenceNew", { name = "QA Main", bars = 1, bpm = 120 }, nil, function(s)
    return s.music.sequence.name == "QA Main"
end)
qa.command("Step", 17, 5)
qa.main = qa.state.music.sequenceId
for index = 3, 5 do
    local name = "QA Section " .. index
    qa.command("SequenceNew", { name = name, bars = 1, bpm = 180 }, nil, function(s)
        return s.music.sequence.name == name
    end)
end
qa.command("SequenceSelect", qa.main)
qa.command("SongNew", { name = "QA Harbour Song" }, nil, function(s)
    return s.music.draft and s.music.draft.name == "QA Harbour Song"
end)
qa.command("SongStepInsert", { sequenceId = qa.intro, repeats = 1 })
qa.command("SongStepInsert", { sequenceId = qa.main, repeats = 2 })
qa.command("SequenceSelect", qa.intro)
qa.command("SongStepUpdate", { stepId = qa.state.music.draft.steps[2].stepId, repeats = 2 })
assert(qa.state.music.draft.steps[2].sequenceId == qa.main, "Repeat edit changed sequence")
qa.command("SongTempo", { tempoMode = "song", bpm = 180 })
qa.command("SaveDraft", nil, nil, function(s)
    return not s.saving and s.music.draft.savedRevision == s.music.draft.revision
end)
return {
    ready = qa.state.ready,
    station = qa.state.station,
    sequences = #qa.state.music.library.sequences,
    draft = qa.state.music.draft,
    summary = qa.state.music.library.drafts,
}
