-- IDs are stable save data. Material masks are authoring inputs; Roblox receives
-- precomposed atlases so customization does not depend on an unsupported shader.
local Theme = require(script.Parent.Theme)
local Cosmetics = {
    Order = { "quay", "chalk", "coral", "afterhours" },
    Sets = {
        quay = { label = "Workshop teal", primary = Theme.Teal },
        chalk = { label = "Warm cream", primary = Theme.Cream },
        coral = { label = "Repaired coral", primary = Theme.Coral },
        afterhours = { label = "After hours", primary = Theme.Graphite },
    },
    TextureLayout = "FZ_MaterialAtlas_v1",
    Slots = {
        Device = { "paint_primary", "paint_secondary", "trim", "accent", "rubber", "bare_metal" },
        Item = { "wood", "stone", "ceramic", "leather", "bare_metal" },
        CharacterClothing = { "canvas", "cloth", "cloth_trim", "leather", "bare_metal" },
    },
}
return Cosmetics
