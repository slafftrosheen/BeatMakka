-- One catalog for server stations, client presentation, navigation and saved keepsakes.
return {
    Order = { "echo", "pulse", "chase", "lantern", "targets", "bells", "rings" },
    Routes = { "echo", "pulse", "chase", "lantern", "targets", "bells", "rings", "busk" },
    ById = {
        targets = {
            title = "CORK GALLERY", position = Vector3.new(558, 2, -21), icon = "target",
            hint = "Tap the raised target. Four cork hits fill a coin stamp.",
            lesson = "Leave space between hits. A rest makes the next sound stand out.",
        },
        bells = {
            title = "BEAT BELLS", position = Vector3.new(580, 2, -21), icon = "lamp",
            hint = "Wait for the bell to light, then tap it. Four catches fill a coin stamp.",
            lesson = "Wait, then answer. Listening helps a musical call and response.",
        },
        rings = {
            title = "RING TOSS", position = Vector3.new(602, 2, -21), icon = "disc",
            hint = "Let the ring reach the peg, then tap. Four throws fill a coin stamp.",
            lesson = "Repeat a steady movement. Repetition builds a groove.",
        },
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
