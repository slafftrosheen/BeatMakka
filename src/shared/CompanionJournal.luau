-- Optional, read-only notebooks. Saved evidence is never promoted into quest awards here.
local Discovery = require(script.Parent.DiscoveryCatalog)
local Music = require(script.Parent.QuayMusicEvidence)
local Journal = {}
local observations = {
    I01 = {
        place = "Dockside Exchange / Tori",
        text = "A short, bright strike. The dock's work can become a pulse.",
    },
    I02 = {
        place = "Repair Alley / Ivo",
        text = "A low breath with a soft edge. Hear the space it leaves beside metal.",
    },
    I03 = {
        place = "Breakwater / Mica",
        text = "A small rising answer. The same voice can tell a different story with a new rhythm.",
    },
}
local stories = {
    legacy = {
        title = "Mica's courtyard",
        alissia = {
            "Mica knows the little sounds people usually walk past.",
            "A sound in my notebook is a memory of a place. Your music decides what that memory becomes.",
        },
        nikolas = {
            "Mica's neighborhood jobs use your saved music. My notes don't tick them off for you.",
            "We can try another version whenever you want. You decide which sequences to save.",
        },
    },
    P1 = {
        title = "Tori's dock",
        alissia = {
            "Tori hears the dock even when everyone else just hears work.",
            "My notebook keeps the place with the sound. A metal strike feels different when you remember who was there.",
        },
        nikolas = {
            "Tori says a useful rhythm leaves room for someone else's part.",
            "I like trying one small change, then listening again. You decide which version belongs in your beat.",
        },
    },
    P2 = {
        title = "Ivo's repair alley",
        alissia = {
            "That vent has a deeper voice than the dock's metal. Ivo notices when its sound changes.",
            "First we listen; then we follow Ivo's safe repair controls. My notebook doesn't switch anything on.",
        },
        nikolas = {
            "Ivo checks one part at a time. That's a good way to build a beat, too.",
            "I used to change everything at once. Alissia asked me what I had actually heard. Now I keep a version before trying another.",
        },
    },
    P3 = {
        title = "Naya and Sana's market",
        alissia = {
            "Naya remembers the people behind old records. A sleeve can hold a whole afternoon.",
            "Sana makes room for listening. We can help without needing an audience or another player.",
        },
        nikolas = {
            "Sana keeps the market moving; Naya keeps its stories. Our sequence library can keep our own ideas.",
            "A saved beat doesn't have to be perfect. It gives you something to come back to and change.",
        },
    },
    P4 = {
        title = "Mica at the breakwater",
        alissia = {
            "Mica's little chirp carries across the quiet water. Let's leave a pause so we can hear its answer.",
            "Later I'd like to ask Nell what the cafe used to sound like. Today this little reply belongs on its own page.",
        },
        nikolas = {
            "Mica gives us a voice; you choose its rhythm. My counter isn't a score or a clock for your music.",
            "One, two, three, four. Count slowly, then let your own steps make the reply.",
        },
    },
    finale = {
        title = "Ronan's Lantern Room",
        alissia = {
            "Ronan says listening is part of performing. You can take a breath before you start.",
            "The Quiet Fade isn't a monster to beat. We make room for each other, one piece of music at a time.",
        },
        nikolas = {
            "Ronan will guide the set. You choose every musical part; I won't press the pads for you.",
            "My good beat is one you heard and changed yourself. A quiet room is allowed to be the beginning.",
        },
    },
}
function Journal.project(profile, selected, location)
    local pages, count = {}, 0
    if selected == "alissia" then
        for _, id in Discovery.Order do
            local found = profile.unlocked[id] == true
            if found then
                count += 1
            end
            local note, definition = observations[id], Discovery.ById[id]
            table.insert(pages, {
                title = definition.label,
                available = found,
                place = note.place,
                text = if found
                    then note.text
                    else "An empty page for a sound you may find here. Collect it through the existing activity when you want to.",
                status = if found then "FOUND SOUND" else "UNWRITTEN PAGE",
            })
        end
    else
        local metalSteps, layered, chirps, savedBeats = 0, false, {}, 0
        for _, evidence in Music.savedSequences(profile) do
            savedBeats += 1
            local metal, vent = 0, 0
            for _ in evidence.positions.I01 or {} do
                metal += 1
            end
            for _ in evidence.positions.I02 or {} do
                vent += 1
            end
            metalSteps = math.max(metalSteps, metal)
            layered = layered or (metal > 0 and vent > 0)
            local ticks = {}
            for tick in evidence.positions.I03 or {} do
                table.insert(ticks, tick)
            end
            table.sort(ticks)
            if #ticks > 0 then
                chirps[table.concat(ticks, ",")] = true
            end
        end
        local variants = 0
        for _ in chirps do
            variants += 1
        end
        pages = {
            {
                title = "Pulse",
                available = metalSteps > 0,
                place = "Quay metal / saved sequences",
                text = if metalSteps > 0
                    then string.format(
                        "Your saved metal rhythm uses up to %d distinct rhythmic positions in a sequence. Change one moment and hear what happens.",
                        metalSteps
                    )
                    else "Try a metal pulse in MK-I. Save Sequence when you want to remember it.",
                status = if metalSteps > 0 then "SAVED OBSERVATION" else "AN IDEA TO TRY",
            },
            {
                title = "Layers",
                available = layered,
                place = "Metal + vent / saved sequences",
                text = if layered
                    then "One of your saved sequences lets metal and vent sound together. Each voice can leave room for the other."
                    else "Metal and vent have different edges. Try both in one sequence, then save a version you like.",
                status = if layered then "SAVED OBSERVATION" else "AN IDEA TO TRY",
            },
            {
                title = "Replies",
                available = variants >= 2,
                place = "Helper chirp / saved sequences",
                text = string.format(
                    "Your last successfully saved sequences hold %d different audible chirp rhythms. Try changing the reply in another sequence.",
                    variants
                ),
                status = if variants >= 2 then "SAVED OBSERVATION" else "AN IDEA TO TRY",
            },
        }
        for _, page in pages do
            if page.available then
                count += 1
            end
        end
        if savedBeats == 0 then
            pages[3].text =
                "Your saved sequence library has no ready music yet. You choose what to keep; I never store or change a beat for you."
        end
    end
    local story = stories[location] or stories.P1
    return {
        title = if selected == "alissia" then "The sound notebook" else "The beat bench",
        caption = if selected == "alissia"
            then "Places and timbres from your collected sounds. No microphone."
            else "Observations from your last successful sequence save. These do not complete Quay activities.",
        count = count,
        total = #pages,
        pages = pages,
        story = {
            context = location or "P1",
            title = story.title,
            lines = story[selected] or story.alissia,
        },
    }
end
return Journal
