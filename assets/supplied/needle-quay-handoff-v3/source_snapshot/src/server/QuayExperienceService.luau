local Shared = game:GetService("ReplicatedStorage").Shared
local Activities = require(Shared.QuayActivities)
local Identity = require(Shared.QuayIdentity)
local Wardrobe = require(Shared.WardrobeCatalog)
local Story = require(Shared.QuayStory)
local Service = {}
Service.__index = Service

-- Answers never arrive from the client as completion flags.
local puzzles = {
    {
        tiles = { "Bolt", "Coil", "Bolt", "Coil" },
        answer = "Bolt",
        hint = "Two things take turns: Bolt, Coil.",
    },
    {
        tiles = { "Lamp", "Lamp", "Coil", "Lamp", "Lamp" },
        answer = "Coil",
        hint = "Two lamps, then one coil. Start that group again.",
    },
    {
        tiles = { "Coil", "Bolt", "Lamp", "Coil", "Bolt" },
        answer = "Lamp",
        hint = "The group has three things: Coil, Bolt, Lamp.",
    },
    {
        tiles = { "Bolt", "Bolt", "Lamp", "Lamp", "Bolt" },
        answer = "Bolt",
        hint = "Each thing has a partner: two bolts, then two lamps.",
    },
    {
        tiles = { "Lamp", "Coil", "Lamp", "Coil", "Lamp" },
        answer = "Coil",
        hint = "A lamp is followed by a coil.",
    },
    {
        tiles = { "Coil", "Bolt", "Bolt", "Coil", "Bolt" },
        answer = "Bolt",
        hint = "One coil, then two bolts. Repeat that group.",
    },
}

function Service.new(world, profiles, nearby, send, changed, wardrobe, commerce)
    return setmetatable({
        scene = world.demo,
        profiles = profiles,
        nearby = nearby,
        send = send,
        changed = changed,
        wardrobe = wardrobe,
        commerce = commerce,
        puzzles = {},
        last = {},
        random = Random.new(),
    }, Service)
end

function Service:at(player, buildingId)
    local node = self.scene and self.scene.buildings[buildingId]
    return node ~= nil and self.nearby(player, node.anchor, 18)
end

function Service:reconcile(player, profile)
    local changed = Activities.reconcile(profile)
    changed = Identity.reconcile(profile) or changed
    if changed then
        self.changed(player, profile)
    end
    return changed
end

function Service:summary(player, profile)
    if not self.scene then
        return nil
    end
    local progress = Activities.sanitize(profile.experience)
    local memories, activities = {}, {}
    for _, memory in Activities.Memories do
        table.insert(memories, {
            id = memory.id,
            title = memory.title,
            speaker = memory.speaker,
            collected = progress.memories[memory.id],
            nearby = self:at(player, memory.building),
            text = if progress.memories[memory.id]
                then (if profile.quay.completed["NQ-Q12"] then memory.after else memory.text)
                else nil,
        })
    end
    for _, id in Activities.Order do
        local activity = Activities.ById[id]
        activities[id] = {
            completed = progress.activities[id],
            nearby = activity.building ~= nil and self:at(player, activity.building),
        }
    end
    local puzzle = self.puzzles[player]
    local current = puzzle and puzzles[puzzle.order[puzzle.round]]
    return {
        progress = progress,
        memories = memories,
        activities = activities,
        chapter = Story.chapter(profile.quay.completed),
        puzzle = current and {
            round = puzzle.round,
            tiles = current.tiles,
            hint = if puzzle.hint then current.hint else nil,
        },
        identity = Identity.summary(profile, self.commerce:verified(player)),
        commerce = self.commerce:summary(player),
    }
end

function Service:commit(player, profile, message, appearance)
    self.changed(player, profile)
    self:reconcile(player, profile)
    if appearance then
        self.wardrobe:refresh(player)
    end
    self.send(player, message)
end

function Service:command(player, action, value, extra)
    local profile = self.profiles[player]
    if not profile or not profile.ready or not self.scene then
        return
    end
    local now = os.clock()
    if now - (self.last[player] or -math.huge) < 0.2 then
        return
    end
    self.last[player] = now
    local experience = profile.experience
    if action == "LifeMemory" then
        local memory = type(value) == "string" and Activities.MemoryById[value]
        if not memory or not self:at(player, memory.building) then
            self.send(player, "Walk up to the postcard's building to read it.")
            return
        end
        if not experience.memories[value] then
            experience.memories[value] = true
            self:commit(player, profile, memory.speaker .. ": " .. memory.text)
        else
            self.send(
                player,
                memory.speaker
                    .. ": "
                    .. (if profile.quay.completed["NQ-Q12"] then memory.after else memory.text)
            )
        end
    elseif action == "LifeStartPuzzle" then
        if not self:at(player, "NQ-BLD-03") then
            self.send(player, "Ivo's pattern bench is outside Morrow Repairs.")
            return
        end
        local order = { 1, 2, 3, 4, 5, 6 }
        for index = #order, 2, -1 do
            local other = self.random:NextInteger(1, index)
            order[index], order[other] = order[other], order[index]
        end
        self.puzzles[player] = { order = order, round = 1, hint = false }
        self.send(player, "Ivo: what belongs next? Three patterns, and all the time you need.")
    elseif action == "LifeAnswer" or action == "LifePuzzleHint" then
        local puzzle = self.puzzles[player]
        if not puzzle or not self:at(player, "NQ-BLD-03") then
            self.send(player, "Come back to Ivo's pattern bench to continue.")
            return
        end
        local current = puzzles[puzzle.order[puzzle.round]]
        if action == "LifePuzzleHint" then
            puzzle.hint = true
            self.send(player, "Ivo: " .. current.hint)
        elseif value == current.answer then
            if puzzle.round == 3 then
                self.puzzles[player] = nil
                if not experience.activities.pattern_bench then
                    experience.activities.pattern_bench = true
                    self:commit(
                        player,
                        profile,
                        "Ivo: you spotted how the pieces repeat. Your workshop keepsake is in My style."
                    )
                else
                    self.send(
                        player,
                        "Ivo: another three patterns solved. Come back whenever you want to practise."
                    )
                end
            else
                puzzle.round += 1
                puzzle.hint = false
                self.send(player, "Ivo: that's the next piece. Here is a different kind of repeat.")
            end
        elseif value == "Bolt" or value == "Coil" or value == "Lamp" then
            self.send(player, "Ivo: look for the group that repeats. You can ask me for a hint.")
        end
    elseif action == "LifeSleeve" then
        if not self:at(player, "NQ-BLD-02") then
            self.send(player, "Visit Needle Records to print your sleeve with Naya.")
            return
        end
        if not Activities.validSleeve(value, extra) then
            return
        end
        if
            experience.activities.sleeve_studio
            and experience.sleeve.motif == value
            and experience.sleeve.palette == extra
        then
            self.send(player, "Your sleeve is already kept in the journal.")
            return
        end
        experience.sleeve = { motif = value, palette = extra }
        experience.activities.sleeve_studio = true
        self:commit(
            player,
            profile,
            "Naya: that blank sleeve was waiting for your sound. Your cover is kept in the journal."
        )
    elseif action == "LifeDedicate" then
        if type(value) ~= "string" or not Activities.Dedications[value] then
            return
        end
        if experience.dedication ~= value then
            experience.dedication = value
            self:commit(
                player,
                profile,
                "Your concert dedication is saved in the journal. You can change it anytime."
            )
        end
    elseif action == "LifeRefreshShop" then
        self.commerce:refresh(player)
    else
        local changed, message = false, nil
        local passes = self.commerce:verified(player)
        if action == "LifeEquip" then
            changed, message = Identity.equip(profile, value, passes)
        elseif action == "LifeClear" then
            changed, message = Identity.clear(profile, value)
        elseif action == "LifeSaveLook" then
            changed, message = Identity.saveOutfit(profile, value)
        elseif action == "LifeLoadLook" then
            changed, message = Identity.loadOutfit(profile, value, passes)
        elseif action == "LifeTitle" then
            changed, message = Identity.setTitle(profile, value)
        elseif action == "LifeResetLook" then
            for _, slot in Wardrobe.Slots do
                local removed = Identity.clear(profile, slot)
                changed = removed or changed
            end
            message = "Your Roblox avatar is showing without BeatMakka accessories."
        end
        if changed then
            self:commit(player, profile, message, action ~= "LifeSaveLook")
        elseif message then
            self.send(player, message)
        end
    end
end

function Service:remove(player)
    self.puzzles[player], self.last[player] = nil, nil
end

return Service
