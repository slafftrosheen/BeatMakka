-- selene: allow(global_usage)
-- Opt-in Studio Client composition, using normal commands and session saves.
-- Requires device_v4_client_setup and an empty fresh local profile.
assert(game:GetService("RunService"):IsStudio())
-- selene: allow(global_usage)
local qa = _G.NQV4
assert(
    qa and qa.state.saveMode == "session" and qa.state.station,
    "Open a fresh local Studio workbench first"
)
assert(
    #qa.state.music.library.sequences == 1 and qa.state.music.library.sequences[1].events == 0,
    "Demo composition requires an empty fresh profile"
)
local function command(action, payload, predicate)
    return qa.command(action, payload, nil, predicate)
end
command("SequenceRename", { name = "DOCKSIDE" })
command("SequenceLength", { bars = 1 })
command("Bpm", 96)
qa.first = qa.state.music.sequenceId
for _, tick in { 0, 960, 1920, 2880 } do
    command("EventPut", { pad = 1, tick = tick, velocity = 110 })
end
for _, tick in { 960, 2880 } do
    command("EventPut", { pad = 5, tick = tick, velocity = 96 })
end
for index = 0, 7 do
    command(
        "EventPut",
        { pad = 9, tick = index * 480, velocity = if index % 2 == 0 then 82 else 60 }
    )
end
command("SaveSequence")
command("SequenceDuplicate", { name = "LANTERN LIFT" }, function(state)
    return state.music.sequence.name == "LANTERN LIFT"
end)
qa.second = qa.state.music.sequenceId
command("TrackNew", { name = "BASS + BELLS" })
for _, tick in { 0, 1920 } do
    command("EventPut", { pad = 17, tick = tick, velocity = 104 })
end
for _, tick in { 960, 2880 } do
    command("EventPut", { pad = 49, tick = tick, velocity = 88 })
end
command("SaveSequence")
command("SongNew", { name = "QUAY SUNSET", bpm = 96 })
command("SongStepInsert", { sequenceId = qa.first, repeats = 1 })
command("SongStepInsert", { sequenceId = qa.second, repeats = 1 })
command("SongTempo", { tempoMode = "song", bpm = 96 })
command("SaveDraft")
return {
    first = qa.first,
    second = qa.second,
    draft = qa.state.music.draftId,
    tracks = #qa.state.music.library.tracks,
    steps = #qa.state.music.draft.steps,
}
