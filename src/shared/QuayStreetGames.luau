-- One catalog for server stations, client presentation, navigation and saved keepsakes.
return {
    Order = { "echo", "pulse", "chase", "lantern" },
    Routes = { "echo", "pulse", "chase", "lantern", "busk" },
    ById = {
        busk = {
            title = "STREET SET",
            position = Vector3.new(509, 0.6, 53),
            icon = "sound",
            hint = "Bring your beat. Share it here and watch the neighbors react.",
        },
        echo = {
            title = "ECHO PADS",
            position = Vector3.new(476, 2, 32),
            icon = "pads",
            hint = "Watch the pads. Echo the pattern.",
        },
        pulse = {
            title = "PULSE CLUB",
            position = Vector3.new(528, 2, 121),
            icon = "steps",
            hint = "Follow the pulse. Tap four beats.",
        },
        chase = {
            title = "LIGHT CHASE",
            position = Vector3.new(424, 2, 84),
            icon = "pads",
            hint = "Catch the lit pad before it goes dark.",
        },
        lantern = {
            title = "LANTERN LOCK",
            position = Vector3.new(561, 2, 121),
            icon = "knob",
            hint = "Stop the moving light inside the amber window.",
        },
    },
}
