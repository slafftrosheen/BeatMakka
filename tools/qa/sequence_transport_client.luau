-- Studio Client probe. Fake audio records consumer decisions without real sound,
-- profile edits, GUI input, uploads or storage calls.
local Playback = require(game.Players.LocalPlayer.PlayerScripts.Client.SchedulePlayback)
local results = {}
local function check(name, action)
    local ok, detail = xpcall(action, debug.traceback)
    table.insert(results, { name = name, passed = ok, detail = tostring(detail or "ok") })
end
local function fixture(events)
    local audio = { stops = 0, played = {}, playedSettings = {} }
    function audio:stop()
        self.stops += 1
    end
    function audio:setSchedule(schedule)
        self.schedule = schedule
    end
    function audio:play(id, settings)
        table.insert(self.played, id)
        table.insert(self.playedSettings, settings or {})
        return true
    end
    local playback = Playback.new(audio)
    local packet = {
        epoch = 1,
        startedAt = 100,
        playing = true,
        loop = true,
        schedule = {
            source = { id = "private_sequence" },
            duration = 1,
            completeAt = 3,
            events = events,
        },
    }
    return playback, audio, packet
end
check("replacement epoch stops voices and does not replay pre-edit hits", function()
    local playback, audio, packet = fixture({
        { at = 0.10, sampleId = "earlier" },
        { at = 0.12, sampleId = "recent" },
        { at = 0.20, sampleId = "later" },
    })
    playback:accept(packet)
    playback:step(100.13)
    assert(#audio.played == 2, "Fixture did not consume earlier hits")
    local stops = audio.stops
    packet = table.clone(packet)
    packet.epoch = 2
    packet.scheduleChangedAt = 100.14
    playback:accept(packet)
    assert(audio.stops == stops + 1, "Schedule replacement did not cancel existing voices")
    playback:step(100.15)
    assert(#audio.played == 2, "Replacement replayed hits from before the edit")
    playback:step(100.21)
    assert(#audio.played == 3 and audio.played[3] == "later", "Future note was skipped")
end)
check(
    "same-epoch FX revision preserves tails and changes only future trigger parameters",
    function()
        local playback, audio, packet = fixture({
            { at = 0.10, sampleId = "first", settings = { echo = 0 } },
            { at = 0.20, sampleId = "future", settings = { echo = 0 } },
        })
        playback:accept(packet)
        playback:step(100.11)
        local stops = audio.stops
        assert(
            #audio.played == 1 and audio.playedSettings[1].echo == 0,
            "Fixture did not start dry"
        )
        packet = table.clone(packet)
        packet.scheduleRevision = 1
        packet.scheduleChangedAt = 100.12
        packet.schedule = table.clone(packet.schedule)
        packet.schedule.events = {
            { at = 0.10, sampleId = "first", settings = { echo = 0.6 } },
            { at = 0.115, sampleId = "added_before_edit", settings = { echo = 0.6 } },
            { at = 0.20, sampleId = "future", settings = { echo = 0.6 } },
        }
        playback:accept(packet)
        playback:step(100.13)
        assert(audio.stops == stops, "FX/additive revision cut off the previous voice tail")
        assert(#audio.played == 1, "Revision replayed old or newly inserted past notes")
        playback:step(100.21)
        assert(
            #audio.played == 2
                and audio.played[2] == "future"
                and audio.playedSettings[2].echo == 0.6,
            "Next trigger did not receive the changed FX settings"
        )
        return "Unchanged transport epoch retains voices; changed revision advances the consumption floor"
    end
)
check("cleared replacement and deleted transport cannot produce looping notes", function()
    local playback, audio, packet = fixture({ { at = 0.10, sampleId = "deleted" } })
    playback:accept(packet)
    playback:step(100.11)
    assert(#audio.played == 1, "Fixture did not play its first note")
    packet = table.clone(packet)
    packet.epoch = 2
    packet.scheduleChangedAt = 100.12
    packet.schedule = table.clone(packet.schedule)
    packet.schedule.events = {}
    playback:accept(packet)
    playback:step(101.11)
    assert(#audio.played == 1, "Clear allowed the deleted note to loop")
    playback:accept(nil)
    playback:step(102.11)
    assert(#audio.played == 1 and audio.schedule == nil, "Deleted transport remained active")
end)
check("resume and seek never replay notes before the explicit cursor", function()
    local playback, audio, packet = fixture({
        { at = 0.10, sampleId = "earlier" },
        { at = 0.20, sampleId = "before_pause" },
        { at = 0.30, sampleId = "after_resume" },
    })
    playback:accept(packet)
    playback:step(100.13)
    playback:step(100.21)
    assert(#audio.played == 2, "Pause fixture did not consume its earlier notes")
    packet = table.clone(packet)
    packet.epoch, packet.offset, packet.playing = 2, 0.22, false
    packet.scheduleChangedAt = 100.12
    playback:accept(packet)
    packet = table.clone(packet)
    packet.epoch, packet.startedAt, packet.playing = 3, 200, true
    playback:accept(packet)
    playback:step(199.86)
    playback:step(199.96)
    assert(#audio.played == 2, "Resume's future start lead rewound the consumption cursor")
    playback:step(200.01)
    assert(#audio.played == 2, "Resume replayed a pre-pause note through lookbehind")
    playback:step(200.09)
    assert(
        #audio.played == 3 and audio.played[3] == "after_resume",
        "Resume skipped the future note"
    )
    local seek, seekAudio, seekPacket = fixture(packet.schedule.events)
    seekPacket.offsetSeconds = 0.22
    seek:accept(seekPacket)
    seek:step(100.01)
    assert(#seekAudio.played == 0, "Explicit seek replayed the previous note")
end)
local passed = 0
for _, result in results do
    passed += if result.passed then 1 else 0
end
return { passed = passed, failed = #results - passed, checks = results }
