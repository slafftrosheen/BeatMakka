-- Authored optional dialogue. No quests, samples, patterns or profile fields are changed.
local Objectives = require(script.Parent.QuayObjectives)
local Samples = require(script.Parent.SampleCatalog)
local Conversations = {}
local options = {
    { id = "place", label = "Tell me about this place" },
    { id = "music", label = "A thought for my music?" },
    { id = "quay", label = "How is the quay changing?" },
}
local hosts = {
    P1 = {
        name = "Tori",
        role = "Dockside Exchange",
        accent = "Coral",
        place = "The dock used to keep time without trying. Boots, ropes, a cup on a crate. We don't need to make it perfect; just leave room to hear it.",
        music = "A pulse can be simple. Put the metal sound in different moments, then listen to the spaces. You decide how it should feel.",
        welcome = "Help me make a little room between the crates. Then we can hear what you've made.",
        thanks = "There's room for music on this dock again. Your own pulse belongs here.",
    },
    P2 = {
        name = "Ivo",
        role = "Morrow Repairs",
        accent = "Amber",
        place = "A machine tells you when something changes. I listen before I reach for a tool. The controls are numbered so nobody has to guess.",
        music = "Keep your first sequence. Make a musical variation and Save Sequence with another name. Both ideas can belong in your song.",
        welcome = "One step at a time: make it safe, clear the intake, then restore power. Your music can wait while we do this properly.",
        thanks = "That's a steadier breath from the vent. Thanks for making time to help, and for keeping your own versions of the beat.",
    },
    P3 = {
        name = "Naya",
        role = "Needle Records",
        accent = "Coral",
        place = "Every sleeve has a story, but first I want to hear what's inside. A record can anchor a pulse, add a little texture, or carry a tune.",
        music = "Listen to the ready record before choosing its role. Then arrange an owned saved sequence in Song Mode and Save Draft; you can finish it later.",
        welcome = "Come browse. Three records, three different jobs in the music. There's no hurry.",
        thanks = "You listened to the records and kept something of your own. That's a good day in a record shop.",
    },
    sana = {
        name = "Sana Bell",
        role = "Harbor Market Hall",
        accent = "Amber",
        stop = "P3",
        place = "The stalls stay where they are. Only those three marked cases need stowing; then people have room to stand and listen.",
        music = "Your saved music is enough to begin. An audience can join if they want, but you never need to find someone to finish your route.",
        welcome = "A hand with the stage cases would help. I can do the rest; solo is fine.",
        thanks = "The nook is clear. The market can keep working and still make a little space for music.",
    },
    P4 = {
        name = "Mica",
        role = "Breakwater Steps",
        accent = "Amber",
        place = "The little speaker sounds small here, until you leave it a pause. Then its reply can carry a long way across the water.",
        music = "Select one teaching bar. Let ready Helper chirp answer on its four quarter notes: ticks 0, 960, 1920 and 2880. Other bars are your choice.",
        welcome = "I have a small voice for a big place. Want to help me find a reply?",
        thanks = "The signal is reaching the breakwater. A little voice can still belong to the whole neighborhood.",
    },
    finale = {
        name = "Ronan Wren",
        role = "The Lantern Room",
        accent = "Amber",
        place = "This room is for listening as much as playing. A set can begin with one person, and a quiet room is still a room worth playing in.",
        music = "Choose the song you finished for this evening. We will hear its saved revision from the beginning to the last sound.",
        welcome = "Tell me when the neighborhood is ready. The journal will show what remains; a public performance is always optional.",
        thanks = "The room is ready for your music. Take a breath. We will hear your saved song through to its last sound.",
    },
    cafe = {
        name = "Nell Fen",
        role = "Warm Current Cafe",
        accent = "Coral",
        stop = "P1",
        place = "People come in for a warm cup and stay for the sound of someone else being here. Cups, chairs, a door that never quite closes quietly.",
        music = "Leave a little silence around an idea. It makes the next sound easier to notice. You don't have to fill every step.",
        welcome = "You're welcome to pause here. There isn't a job to finish or a sound you have to collect.",
        thanks = "Listen to the quay now. People are making room for each other again. You're welcome to pause here whenever you like.",
    },
}
function Conversations.valid(choice)
    return choice == "place" or choice == "music" or choice == "quay"
end
function Conversations.project(profile, id, choice)
    local host = hosts[id]
    if not host then
        return nil
    end
    local q = profile.quay
    local count, total = Objectives.region(q, host.stop or id)
    local done = count == total and total > 0
    local line = if choice == "place" or choice == "music"
        then host[choice]
        elseif choice == "quay" then (if q.completed["NQ-Q12"]
            then "The quay has its rhythm back. Keep making music in your own time."
            else string.format(
                "%d of %d main activities are ready in this corner. Every small contribution leaves room for the next one.",
                count,
                total
            ))
        else if done or q.completed["NQ-Q12"] then host.thanks else host.welcome
    if id == "cafe" and choice == "quay" then
        line = if q.completed["NQ-Q12"]
            then host.thanks
            else "It changes a little at a time: a clear dock, a running vent, a listening corner. Nobody has to do it all at once."
    end
    return {
        id = id,
        name = host.name,
        role = host.role,
        accent = host.accent,
        line = Samples.localDiscoveryText(line),
        options = options,
        regionReady = done,
    }
end
return Conversations
