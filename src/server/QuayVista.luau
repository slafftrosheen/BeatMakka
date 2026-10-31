-- Supplemental artbook dressing. No canonical footprints, IDs or mission anchors change.
local Theme = require(game.ReplicatedStorage.Shared.Theme)
local Assets = require(script.Parent.AssetSpawner)
local Vista = {}
function Vista.build(scene)
    local root = Instance.new("Folder")
    root.Name = "HarborVista"
    root.Parent = scene.root
    local function part(name, size, at, color, material)
        local p = Assets.part(root, name, size, CFrame.new(at), color, false)
        p.Material = material or Enum.Material.SmoothPlastic
        return p
    end
    -- Water continues to the horizon; the stone quay meets it rather than floating.
    workspace.Terrain:FillBlock(
        CFrame.new(450, -14, 0),
        Vector3.new(2200, 16, 1800),
        Enum.Material.Water
    )
    local seawall = part(
        "QuaySeawall",
        Vector3.new(440, 10, 344),
        Vector3.new(450, -5, -22),
        Theme.Stone,
        Enum.Material.Slate
    )
    seawall.CanCollide, seawall.CanQuery = true, true
    for _, x in { 230, 670 } do
        part(
            "StoneEdge",
            Vector3.new(1.3, 0.35, 344),
            Vector3.new(x, 0.17, -22),
            Theme.Cream,
            Enum.Material.Concrete
        )
        for z = -180, 140, 12 do
            part(
                "QuayMasonryJoint",
                Vector3.new(0.08, 8, 0.15),
                Vector3.new(x + if x < 450 then -0.04 else 0.04, -4, z),
                Theme.Walnut
            )
        end
    end
    -- Authored facade assets on a continuous far shore replace the box skyline.
    part(
        "FarHarborShore",
        Vector3.new(1200, 8, 160),
        Vector3.new(450, -4, 520),
        Theme.Stone,
        Enum.Material.Slate
    )
    for index = 1, 18 do
        local id = string.format("NQ-FACADE-%02d", (index - 1) % 3 + 1)
        local model = Assets.place(
            root,
            id,
            CFrame.new(-60 + index * 57, 0, 488 + (index % 3) * 22),
            Vector3.new(30, 50, 25),
            Theme.Teal,
            false
        )
        local art = model:FindFirstChild("Art")
        if art then
            art:ScaleTo(1.4 + (index % 4) * 0.32)
            for _, object in art:GetDescendants() do
                if object:IsA("Light") then
                    object.Enabled = false
                end
            end
        end
        model:SetAttribute("DistantAuthoredArchitecture", true)
    end
    local previous
    for index = 0, 18 do
        local x = 365 + index * 7
        local top = Vector3.new(x, 11.6 - math.sin(index / 18 * math.pi) * 1.8, 132)
        local p = part(
            "HarborBunting",
            Vector3.new(2.1, 2.8, 0.08),
            top - Vector3.new(0, 1.4, 0),
            ({ Theme.Coral, Theme.Cream, Theme.FadedTeal, Theme.Amber })[index % 4 + 1],
            Enum.Material.Fabric
        )
        p:SetAttribute("QuayBreeze", index * 0.7)
        p:SetAttribute("BreezePivot", Vector3.new(0, 1.4, 0))
        if previous then
            local line = part(
                "BuntingLine",
                Vector3.new(0.07, 0.07, (top - previous).Magnitude),
                (top + previous) / 2,
                Theme.Walnut
            )
            line.CFrame = CFrame.lookAt((top + previous) / 2, top)
            line.CastShadow = false
        end
        previous = top
    end
    for _, x in { 365, 491 } do
        part(
            "BuntingPost",
            Vector3.new(0.3, 11.8, 0.3),
            Vector3.new(x, 5.9, 132),
            Theme.Walnut,
            Enum.Material.Wood
        )
    end
    for _, at in
        {
            Vector3.new(245, 0, 105),
            Vector3.new(650, 0, -100),
            Vector3.new(510, 0, 120),
            Vector3.new(540, 0, -140),
        }
    do
        Assets.place(root, "P11", CFrame.new(at), Vector3.new(2, 2, 2), Theme.Coral, false)
        Assets.place(
            root,
            "P12",
            CFrame.new(at + Vector3.new(0, 1.2, 0)),
            Vector3.new(2, 2, 2),
            Theme.FadedTeal,
            false
        )
    end
    root:SetAttribute("ArtStage", "LOCAL_ARTBOOK_DRESSING_PENDING_REVIEW")
end
return Vista
