-- Authored story content for the existing Needle Quay route.
-- Reads server-owned completion state; never awards progress, edits music or writes profiles.
local Story = {}

Story.Title = "A Place for Every Sound"
Story.Premise =
    "The Lantern Room has an empty sleeve waiting for its next evening. Make a beat, meet your neighbours and bring a sound of your own."

Story.Chapters = {
    {
        id = "arrival",
        title = "A room to begin",
        summary = "Your Roamer is a studio and a place to call your own. An old invitation points towards the Lantern Room.",
        nextStep = "Meet Tori at Dockside Exchange, or enter your Roamer to make music.",
        required = { "NQ-Q00" },
    },
    {
        id = "dock",
        title = "The quay has a rhythm",
        summary = "Tori remembers when this dock corner had room for music. What could its everyday sounds become?",
        nextStep = "Make room at the dock, then put Quay metal on four distinct rhythmic positions in a named sequence and check your music with Tori.",
        required = { "NQ-Q01", "NQ-Q02" },
    },
    {
        id = "repair",
        title = "Leave room to change",
        summary = "Ivo keeps waiting for a perfect idea. You can try two versions and keep what you like about each.",
        nextStep = "Help Ivo finish the repair. Save an original named sequence and a musically distinct variation, then return for the music check.",
        required = { "NQ-Q04", "NQ-Q05" },
    },
    {
        id = "sleeve",
        title = "The blank sleeve",
        summary = "Naya has kept the old Lantern Room sleeves. The last one is empty for a reason.",
        nextStep = "Visit Needle Records, match the three musical roles and put an owned saved sequence in Song Mode and Save Draft. You can finish it later.",
        required = { "NQ-Q06", "NQ-Q07" },
    },
    {
        id = "invitation",
        title = "An invitation, not a demand",
        summary = "Sana is making room for visitors. Mica can carry a clear invitation to the breakwater.",
        nextStep = "Help Sana with the stage cases. Answer Mica using Helper chirp on the four quarter notes of your explicitly selected teaching bar, then restore the signal.",
        required = { "NQ-Q08", "NQ-Q09", "NQ-Q10" },
    },
    {
        id = "door",
        title = "Open the door",
        summary = "The neighbours are ready for a small evening. Ronan needs to hear that it can be a new one.",
        nextStep = "Meet Ronan at the Lantern Room. Select a successfully saved, ready Finished Song with two distinct sections and a collected sound layered with another part.",
        required = { "NQ-Q11" },
    },
    {
        id = "concert",
        title = "A place for every sound",
        summary = "This sleeve is for the music you made. A quiet room and a small audience are enough.",
        nextStep = "Perform your pinned Finished Song revision from beginning to its actual end. You can pause or stop whenever you want.",
        required = { "NQ-Q12" },
    },
    {
        id = "afterglow",
        title = "See you next time",
        summary = "There is a fresh invitation at the Lantern Room, and your music has a place in the quay's story.",
        nextStep = "Try a side activity, change your look, make another beat or simply enjoy the quay.",
        required = {},
    },
}

Story.NPCs = {
    Tori = {
        id = "NQ-NPC-TORI",
        name = "Tori",
        role = "Dock master",
        place = "Dockside Exchange",
        motive = "Make the dock useful and welcoming again.",
        arc = "From thinking music gets in the way of work to bringing chairs for a new gathering.",
    },
    Ivo = {
        id = "NQ-NPC-IVO",
        name = "Ivo",
        role = "Mechanic and sound experimenter",
        place = "Morrow Repairs",
        motive = "Finish the repair and find the courage to share an unfinished idea.",
        arc = "From waiting for one perfect version to enjoying what two versions can teach each other.",
    },
    Naya = {
        id = "NQ-NPC-NAYA",
        name = "Naya",
        role = "Music archivist",
        place = "Needle Records",
        motive = "Keep the old memories while making space for new ones.",
        arc = "From protecting a blank sleeve to inviting the player to fill it with their own music.",
    },
    Sana = {
        id = "NQ-NPC-SANA",
        name = "Sana Bell",
        role = "Market coordinator",
        place = "Harbor Market Hall",
        motive = "Help everyone find a comfortable place at the gathering.",
        arc = "From carrying all the arrangements to accepting help and leaving room for different ways to join.",
    },
    Mica = {
        id = "H04",
        name = "Mica",
        role = "Neighbourhood helper",
        place = "Breakwater Steps",
        motive = "Carry an invitation clearly and leave its meaning to the musician.",
        arc = "From waiting for a signal to carrying the player's invitation.",
    },
    Ronan = {
        id = "NQ-NPC-RONAN",
        name = "Ronan Wren",
        role = "Lantern Room caretaker",
        place = "The Lantern Room",
        motive = "Let the room matter again without demanding the old evenings return.",
        arc = "From avoiding an empty room to opening it for one small new gathering.",
    },
    Nell = {
        id = "NQ-NPC-NELL",
        name = "Nell Fen",
        role = "Café host and keeper of small stories",
        place = "Warm Current Café",
        motive = "Give people somewhere comfortable to stop, listen or simply sit.",
        arc = "From remembering the old gathering to keeping a postcard from the new one.",
    },
}

Story.Milestones = {
    ["NQ-Q00"] = {
        title = "Your own small studio",
        memory = "You found your Roamer and a place to begin.",
    },
    ["NQ-Q01"] = {
        title = "Room at the dock",
        memory = "Tori has a clear corner for people to gather.",
    },
    ["NQ-Q02"] = {
        title = "A familiar sound, a new beat",
        memory = "Tori heard the loading rail in your own rhythm.",
    },
    ["NQ-Q03"] = {
        title = "An open invitation",
        memory = "You chose how to take part. A public performance was your choice.",
    },
    ["NQ-Q04"] = {
        title = "The repair is ready",
        memory = "Ivo finished the vent with your help. The working pulse joined your sound collection.",
    },
    ["NQ-Q05"] = {
        title = "Two ideas worth keeping",
        memory = "You kept two musically different named sequences. Ivo is bringing his repaired lamp.",
    },
    ["NQ-Q06"] = {
        title = "What the records remember",
        memory = "Naya showed how pulse, texture and tune can share a piece of music.",
    },
    ["NQ-Q07"] = {
        title = "The next sleeve",
        memory = "Your saved Song Mode draft starts a new story beside the old ones.",
    },
    ["NQ-Q08"] = {
        title = "Room for visitors",
        memory = "Sana has space for people to play, listen or take a quiet break.",
    },
    ["NQ-Q09"] = {
        title = "A clear reply",
        memory = "Mica heard your Helper chirp pattern and has a signal to carry.",
    },
    ["NQ-Q10"] = {
        title = "Across the breakwater",
        memory = "Your invitation reached the local signal. The next step is a conversation with Ronan.",
    },
    ["NQ-Q11"] = {
        title = "A small evening is enough",
        memory = "Ronan opened the room for something new.",
    },
    ["NQ-Q12"] = {
        title = "The quay plays again",
        memory = "Your pinned song revision reached its actual end. Ronan has put up a fresh invitation.",
    },
}

Story.Dedications = {
    {
        id = "curiosity",
        title = "Let's hear what happens",
        label = "Let's hear what happens",
        line = "For the sounds we have not made yet.",
        response = "Ronan: We do not need to know the whole evening before it begins.",
        closing = "Your set was dedicated to curiosity. Naya's new sleeve remembers the sounds you dared to try.",
    },
    {
        id = "together",
        title = "A place for everyone",
        label = "A place for everyone",
        line = "For everyone who plays, listens or leaves a little room.",
        response = "Ronan: There is room to play, and room simply to be here.",
        closing = "Your set made room for everyone. Ronan has put up a fresh invitation, and Naya has a new sleeve to keep.",
    },
    {
        id = "beginnings",
        title = "A new beginning",
        label = "A new beginning",
        line = "For a new evening, in our own way.",
        response = "Ronan: It does not have to be the old evening. This one can be ours.",
        closing = "Your set marked a new beginning. This gathering belongs to the neighbours who made it, and the musician you are becoming.",
    },
}

-- Descriptive copy only. QuayActivities owns activity data; the server validates completion.
Story.SideActivities = {
    memory_walk = {
        title = "Nell's Memory Postcards",
        summary = "Visit the café, ferry office and Lantern Room. Small places keep different parts of a story.",
    },
    sound_safari = {
        title = "Sound Safari",
        summary = "Find the quay's three virtual sounds, then imagine how they could fit into your own music.",
    },
    pattern_bench = {
        title = "Ivo's Pattern Bench",
        summary = "Find the repeating pattern. Take your time; an idea is worth another try.",
    },
    sleeve_studio = {
        title = "Naya's Sleeve Studio",
        summary = "Give your music a cover with a motif and colours of your own choosing.",
    },
}

Story.Scenes = {
    arrival = {
        title = "An old invitation",
        speaker = "Mica",
        lines = {
            "Your studio is ready. Want to hear what this place sounds like?",
            "This card was tucked inside the welcome folder: 'Bring a sound. Leave a little room.'",
            "The Lantern Room is across the quay. Tori remembers the card. You can meet them, or make a beat first.",
        },
        prompt = "Your Roamer is ready whenever you want to make music.",
    },
    dock = {
        title = "A corner for music",
        speaker = "Tori",
        lines = {
            "We used to leave this corner clear for music. Then the crates took over.",
            "That loading rail has kept the same clank for years. I wonder what you would make of it.",
            "I'll bring the chairs if you want to try a little gathering. No need to play in public before you are ready.",
        },
        prompt = "Make room at the dock, then try Quay metal on four distinct rhythmic positions in a named sequence in your Roamer.",
    },
    dock_done = {
        title = "The loading rail, heard differently",
        speaker = "Tori",
        lines = {
            "That's our old loading rail. I never heard it like that.",
            "Ivo is finishing a repair up the alley. He always hears another rhythm hiding in a machine.",
            "Tell him I'll bring the chairs. This corner can hold more than crates.",
        },
        prompt = "Repair Alley is your next story stop. Sharing a dockside set is still optional.",
    },
    repair = {
        title = "An idea does not need to be perfect",
        speaker = "Ivo",
        lines = {
            "I have been fixing this lamp for the Lantern Room. It works; I keep thinking it should be better first.",
            "Let's finish the vent safely: power off, intake clear, power back. Then we can hear its pulse properly.",
            "Try two versions of your beat. We do not have to throw the first idea away to try another.",
        },
        prompt = "Use the repair controls in order. Save an original sequence and a distinct musical variation, then let Ivo hear.",
    },
    repair_done = {
        title = "Two versions worth keeping",
        speaker = "Ivo",
        lines = {
            "Your first sequence works. The variation asks another question. I like that you kept both.",
            "I'm bringing the lamp as it is. A little scratch does not stop it giving light.",
            "Naya has the old music sleeves at Needle Records. Ask her about the one with nothing on it.",
        },
        prompt = "Visit Naya at Vinyl Market. You can return to your sequences whenever you like.",
    },
    records = {
        title = "The sleeve nobody filled",
        speaker = "Naya",
        lines = {
            "People keep asking me for the last song they played at the Lantern Room.",
            "There was no one last song. Everyone brought a little piece. I kept the sleeves and their notes.",
            "First, let's make sense of these three records. A pulse, a texture and a tune each leave room for the others.",
        },
        prompt = "Match the record roles. Add one owned saved sequence to Song Mode and Save Draft; I will show you the empty sleeve.",
    },
    blank_sleeve = {
        title = "The next evening is yours to make",
        speaker = "Naya",
        lines = {
            "This sleeve was never missing a record. We left it empty for the next evening.",
            "I would rather remember what you made than ask you to copy what we did.",
            "A loop can keep an idea going. Song Mode lets you decide what happens next. Your saved draft belongs here; finish the song when you are ready.",
        },
        prompt = "Sana is making room at the market. The Sleeve Studio is an optional creative stop.",
    },
    market_done = {
        title = "A place to join in, or just listen",
        speaker = "Naya and Sana Bell",
        lines = {
            "Naya: This sleeve was never missing a record. We left it empty for the next evening. Your developing song belongs here.",
            "Sana: The cases are out of the aisle. Tori is bringing chairs, and Nell has a quiet table ready.",
            "We can invite people without asking every one of them to perform. Mica can carry our invitation to the breakwater.",
        },
        prompt = "Visit Mica at Breakwater Steps when you are ready.",
    },
    signal = {
        title = "Something worth answering",
        speaker = "Mica",
        lines = {
            "I can carry a signal. I cannot decide what you want to say.",
            "This Helper chirp is one of the quay's virtual sounds. Select a teaching bar. Try a clear reply at ticks 0, 960, 1920 and 2880 within that bar.",
            "An invitation does not need an answer straight away. People can join when they are ready.",
        },
        prompt = "Bring the four-note reply back for a check, then use the signal console.",
    },
    signal_done = {
        title = "An invitation across the breakwater",
        speaker = "Mica",
        lines = {
            "Your signal is clear. The local invitation has reached the breakwater.",
            "Ronan has kept the Lantern Room safe all this time. He has not put up a fresh card in a while.",
            "He may need to hear that a small new evening is enough.",
        },
        prompt = "Meet Ronan at the Lantern Room with your own successfully saved Finished Song.",
    },
    door_waiting = {
        title = "The room is still here",
        speaker = "Ronan Wren",
        lines = {
            "The room is safe. I just haven't put up a new invitation in a while.",
            "I kept hoping the next evening would be just like the old ones. Then I stopped asking anyone.",
            "If you are curious, ask Naya about that blank sleeve. We can talk again when your neighbourhood route is ready.",
        },
        prompt = "Your journal shows the remaining neighbourhood steps. Public sharing is optional.",
    },
    door_ready = {
        title = "A small evening is enough",
        speaker = "Ronan Wren",
        lines = {
            "Tori has chairs. Ivo brought the lamp, scratches and all. Sana and Nell made room.",
            "I kept thinking the next evening had to be as good as the old ones. It can simply be a new one.",
            "What would you like to dedicate your first set to? Whatever you choose, you can practise or stop whenever you want.",
        },
        prompt = "Choose a dedication if you like, then enter with your saved Finished Song. We will hear it from the beginning to the last sound.",
    },
    afterglow = {
        title = "See you next time",
        speaker = "Ronan Wren",
        lines = {
            "There. A fresh invitation. I can put up another one now.",
            "Naya has a new sleeve to keep. Nell asked which moment you would put on a postcard.",
            "You are welcome to play again, wander a little, or call it an evening. Your studio will be here.",
        },
        prompt = "Enjoy the quay, choose a new look or make another beat. Future city routes are still closed in this demo.",
    },
    cafe = {
        title = "The small things a place remembers",
        speaker = "Nell Fen",
        lines = {
            "Ronan remembers the stage. Naya remembers the sleeves. I remember who sat together.",
            "The ferry office and the Lantern Room keep different bits of the same story. Take a look when you are passing.",
            "You can bring me a postcard, or just sit for a minute. You do not owe a quiet corner a performance.",
        },
        prompt = "Nell's Memory Postcards is an optional walk through three familiar places.",
    },
    ferry = {
        title = "Before the next crossing",
        speaker = "Tori",
        lines = {
            "People used to wait here with a tune still in their heads from the Lantern Room.",
            "Nell would wrap a warm cup for the crossing. I would carry the folding chairs back in the morning.",
            "A place can remember a song even when nobody kept a recording.",
        },
        prompt = "The ferry office is one of Nell's postcard stops. Other district routes are not open yet.",
    },
}

local function done(completed, id)
    return type(completed) == "table" and completed[id] == true
end

function Story.chapter(completed)
    if done(completed, "NQ-Q12") then
        return Story.Chapters[#Story.Chapters]
    end
    for _, chapter in Story.Chapters do
        for _, id in chapter.required do
            if not done(completed, id) then
                return chapter
            end
        end
    end
    return Story.Chapters[#Story.Chapters]
end

function Story.scene(key, completed)
    if type(key) == "string" and key:sub(1, 9) == "building:" then
        key = key:sub(10)
    end
    if key == "P1" then
        return if done(completed, "NQ-Q01") and done(completed, "NQ-Q02")
            then Story.Scenes.dock_done
            else Story.Scenes.dock
    elseif key == "P2" then
        return if done(completed, "NQ-Q05") then Story.Scenes.repair_done else Story.Scenes.repair
    elseif key == "P3" then
        if done(completed, "NQ-Q07") and done(completed, "NQ-Q08") then
            return Story.Scenes.market_done
        end
        return if done(completed, "NQ-Q07") then Story.Scenes.blank_sleeve else Story.Scenes.records
    elseif key == "P4" then
        return if done(completed, "NQ-Q10") then Story.Scenes.signal_done else Story.Scenes.signal
    elseif key == "finale" or key == "NQ-BLD-01" or key == "Lantern" then
        if done(completed, "NQ-Q12") then
            return Story.Scenes.afterglow
        end
        return if done(completed, "NQ-Q11")
            then Story.Scenes.door_ready
            else Story.Scenes.door_waiting
    elseif key == "cafe" or key == "NQ-BLD-06" then
        return Story.Scenes.cafe
    elseif key == "ferry" or key == "NQ-BLD-07" then
        return Story.Scenes.ferry
    elseif key == "afterglow" then
        return if done(completed, "NQ-Q12") then Story.Scenes.afterglow else Story.Scenes.arrival
    end
    if done(completed, "NQ-Q12") then
        return Story.Scenes.afterglow
    end
    local chapter = Story.chapter(completed)
    local keys = {
        arrival = "arrival",
        dock = "dock",
        repair = "repair",
        sleeve = "records",
        invitation = "blank_sleeve",
        door = "signal_done",
        concert = "door_ready",
    }
    return Story.Scenes[keys[chapter.id] or "arrival"]
end

function Story.dedication(id)
    for _, dedication in Story.Dedications do
        if dedication.id == id then
            return dedication
        end
    end
    return Story.Dedications[2]
end

function Story.milestone(id)
    return Story.Milestones[id]
end

return Story
