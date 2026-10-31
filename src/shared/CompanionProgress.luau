-- Read-only projection. This module never edits beats, unlocks samples or awards progress.
local Quay = require(script.Parent.QuayProgress)
local Missions = require(script.Parent.NeighborhoodMissions)
local Quest = require(script.Parent.FirstPerformanceQuest)
local Progress = {}
local stopTasks = {
    P1 = { "NQ-Q00", "NQ-Q01", "NQ-Q02" },
    P2 = { "NQ-Q04", "NQ-Q05" },
    P3 = { "NQ-Q06", "NQ-Q07", "NQ-Q08" },
    P4 = { "NQ-Q09", "NQ-Q10" },
    finale = { "NQ-Q11", "NQ-Q12" },
}
local hints = {
    ["NQ-Q00"] = {
        "There is music in the everyday work of this quay.",
        "Tori knows the dock. Your own Roamer studio is available straight away.",
        "Meet Tori at Dockside Exchange, or use the studio door on your own Roamer.",
    },
    ["NQ-Q01"] = {
        "A little space would make this a welcoming music corner.",
        "Tori's marked dock crates can be stowed one at a time.",
        "Walk to each of the three marked crates and use its nearby action.",
    },
    ["NQ-Q02"] = {
        "Try turning a familiar harbor sound into your own pulse.",
        "A repeating pulse needs different moments in the bar, not repeated taps on one step.",
        "Use ready Quay metal at four distinct rhythmic positions in a named sequence, then ask Tori to check.",
    },
    ["NQ-Q04"] = {
        "That ventilation has a rhythm of its own.",
        "Ivo's repair is a safe sequence. Follow the numbered controls.",
        "Use 1 to isolate power, 2 to clear the intake, then 3 to restore power. The sound becomes yours after the repair.",
    },
    ["NQ-Q05"] = {
        "A small change can make a returning rhythm feel new.",
        "Keep your first named sequence. Make a musical variation and save it under another name.",
        "Save Sequence for both the original and a musically distinct variation. Wait for saved confirmation before returning to Ivo.",
    },
    ["NQ-Q06"] = {
        "What job does each sound do in the music? Listen before deciding.",
        "A pulse anchors a beat, a texture adds detail, and a tune carries pitch.",
        "Use Listen for the current record, then choose its role. A wrong match keeps your earlier progress.",
    },
    ["NQ-Q07"] = {
        "An idea is worth keeping, even while it is still growing.",
        "Song Mode arranges your named sequences from beginning to end. Save Draft keeps this developing arrangement.",
        "Add an owned saved ready sequence to Song Mode and Save Draft. Wait for confirmation, then ask Naya to check. You can finish it later.",
    },
    ["NQ-Q08"] = {
        "Sana is making a place where everyone can listen.",
        "The stalls can stay. Only the three marked stage cases need moving.",
        "Use each marked market case's nearby action. Sana helps even when you play solo.",
    },
    ["NQ-Q09"] = {
        "Mica is waiting for a musical reply, and your hands can make it.",
        "Think of four evenly spaced beats across a sixteen-step bar.",
        "Select the teaching bar of your chosen sequence. Use ready I03 exactly at relative ticks 0, 960, 1920 and 2880; other bars and instruments are your choice.",
    },
    ["NQ-Q10"] = {
        "Your reply has reached Mica. There is one more practical step.",
        "The signal console at the breakwater is ready after your rhythm is checked.",
        "Use the marked signal console, then visit Ronan at the Lantern Room.",
    },
    ["NQ-Q11"] = {
        "This neighborhood is nearly ready to hear what you have made.",
        "Ronan can open the room when your neighbourhood route and saved Finished Song are ready.",
        "Select a ready saved Finished Song, then meet Ronan. Optional loop sharing never needs an audience or a Finished Song.",
    },
    ["NQ-Q12"] = {
        "Your song belongs in this room, from its beginning to its actual end.",
        "Choose a saved ready Finished Song with two distinct sections and a collected sound layered with another part.",
        "Play that pinned immutable revision through its actual end. Pause freezes position; stopping or leaving cancels the incomplete attempt. No audience is required.",
    },
    complete = {
        "The quay has its rhythm back. What would you like to make next?",
        "Revisit your favorite sounds or try a new kit; your musical style is always yours.",
        "Every sampler, available kit and solo activity stays open. Make another composition whenever you like.",
    },
}
local places = {
    ["NQ-Q00"] = "P1",
    ["NQ-Q01"] = "P1",
    ["NQ-Q02"] = "P1",
    ["NQ-Q04"] = "P2",
    ["NQ-Q05"] = "P2",
    ["NQ-Q06"] = "P3",
    ["NQ-Q07"] = "P3",
    ["NQ-Q08"] = "P3",
    ["NQ-Q09"] = "P4",
    ["NQ-Q10"] = "P4",
    ["NQ-Q11"] = "finale",
    ["NQ-Q12"] = "finale",
}
local voices = {
    alissia = { first = "Let's listen for what is already here. ", next = "I noticed something: " },
    nikolas = {
        first = "We can build this one small idea at a time. ",
        next = "Here's a practical thing to try: ",
    },
}
local legacy = {
    metal_pulse = {
        "A metal sound can be the start of a pulse.",
        "Try the legacy neighborhood job's two different metal steps.",
        "For this neighbourhood job, collect I01 and Save Sequence with ready Quay metal at two distinct rhythmic positions.",
    },
    vent_duet = {
        "The vent and the metal could answer each other.",
        "Try two ready layers together in one named sequence.",
        "For the alley duet, Save Sequence with ready Quay metal and Vent thump together.",
    },
    helper_reply = {
        "A second rhythm could be a new answer for Mica.",
        "Compare ready Helper chirp rhythms in two saved named sequences.",
        "For this neighbourhood mission, Save Sequence for two different audible Helper chirp rhythms.",
    },
}
function Progress.project(profile, route, selected, level)
    level = math.clamp(math.floor(level or 1), 1, 3)
    local id, lines, location
    if route then
        local q = Quay.sanitize(profile.quay)
        for _, candidate in stopTasks[profile.companionStop or q.parking] or {} do
            if not q.completed[candidate] then
                id = candidate
                break
            end
        end
        for _, candidate in
            {
                "NQ-Q00",
                "NQ-Q01",
                "NQ-Q02",
                "NQ-Q04",
                "NQ-Q05",
                "NQ-Q06",
                "NQ-Q07",
                "NQ-Q08",
                "NQ-Q09",
                "NQ-Q10",
                "NQ-Q11",
                "NQ-Q12",
            }
        do
            if not id and not q.completed[candidate] then
                id = candidate
                break
            end
        end
        id = id or "complete"
        lines, location = hints[id], places[id]
    else
        local mission = Missions.summary(profile)
        if not profile.quest.accepted then
            id, lines =
                "legacy:meet", {
                    "Mica knows the neighborhood's sounds.",
                    "Start with Mica's courtyard request.",
                    "Meet Mica in the sound alley. Your sampler is available before accepting a quest.",
                }
        elseif mission.nextId then
            id, lines = "legacy:" .. mission.nextId, legacy[mission.nextId]
        elseif mission.courtReady and not profile.chapter.completed then
            id, lines = "legacy:concert", hints["NQ-Q12"]
        else
            local quest = Quest.summary(profile)
            id, lines =
                "legacy:" .. quest.stage,
                { "Keep making this music your own.", quest.objective, quest.objective }
        end
    end
    local voice = voices[selected] or voices.alissia
    return {
        context = id,
        level = level,
        maxLevel = 3,
        location = location,
        text = (if level == 1 then voice.first else voice.next) .. lines[level],
    }
end
return Progress
