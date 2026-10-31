-- In-game keepsakes only; no Roblox BadgeService publishing or account entitlement.
local Badges = {}
Badges.List = {
    {
        id = "chase",
        label = "QUICK HANDS",
        icon = "pads",
        side = "chase",
        hint = "Catch four street lights",
    },
    {
        id = "lantern",
        label = "LIGHT KEEPER",
        icon = "knob",
        side = "lantern",
        hint = "Lock four lantern pulses",
    },
    {
        id = "dock",
        label = "ROOM FOR MUSIC",
        icon = "flag",
        quest = "NQ-Q01",
        hint = "Clear the dock",
    },
    {
        id = "repair",
        label = "GOOD NEIGHBOR",
        icon = "knob",
        quest = "NQ-Q04",
        hint = "Restore the vent",
    },
    {
        id = "record",
        label = "CRATE DIGGER",
        icon = "disc",
        quest = "NQ-Q06",
        hint = "Match the records",
    },
    {
        id = "signal",
        label = "SIGNAL MAKER",
        icon = "sound",
        quest = "NQ-Q10",
        hint = "Light the breakwater",
    },
    {
        id = "echo",
        label = "ECHO EAR",
        icon = "pads",
        side = "echo",
        hint = "Repeat the street phrase",
    },
    {
        id = "pulse",
        label = "POCKET RHYTHM",
        icon = "steps",
        side = "pulse",
        hint = "Hit four street pulses",
    },
    {
        id = "finale",
        label = "QUAY HEADLINER",
        icon = "badge",
        quest = "NQ-Q12",
        hint = "Play the Lantern Room",
    },
}
function Badges.earned(progress, badge)
    return if badge.side
        then progress.side and progress.side[badge.side] == true
        else progress.completed[badge.quest] == true
end
return Badges
