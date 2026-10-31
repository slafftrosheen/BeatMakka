local Shared = game.ReplicatedStorage.Shared
local Catalog = require(Shared.QuayLifeCatalog)
local Theme = require(Shared.Theme)
local Assets = require(script.Parent.AssetSpawner)
local Service = {}
Service.__index = Service
function Service.new(owner)
    local self = setmetatable({ owner = owner, nodes = {}, last = {}, listening = {} }, Service)
    local root = Instance.new("Folder")
    root.Name = "NeighborhoodLife"
    root.Parent = owner.scene.root
    self.root = root
    local function node(key, title, at, kind)
        local part = Assets.part(
            root,
            key,
            Vector3.new(2.2, 2.4, 0.7),
            CFrame.new(at + Vector3.new(0, 1.6, 0)),
            Theme.Teal,
            false
        )
        part:SetAttribute("QuayInteraction", "life:" .. key)
        part:SetAttribute("QuayLifeKind", kind)
        local p = Instance.new("ProximityPrompt")
        p.ActionText = if kind == "postcard"
            then "Listen"
            elseif kind == "garden" then "Tend flowers"
            elseif key == "parcel_pickup" then "Pick up sleeves"
            else "Deliver sleeves"
        p.ObjectText, p.MaxActivationDistance = title:gsub("\n", " · "), 10
        p.RequiresLineOfSight = false
        p.Parent = part
        p.Triggered:Connect(function(player)
            self:interact(player, key)
        end)
        local gui = Instance.new("SurfaceGui")
        gui.Face = Enum.NormalId.Front
        gui.PixelsPerStud = 55
        gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
        gui.Parent = part
        local text = Instance.new("TextLabel")
        text.Size = UDim2.fromScale(1, 1)
        text.BackgroundTransparency = 1
        text.TextColor3 = Theme.Cream
        text.Font = Enum.Font.GothamBold
        text.TextSize = 15
        text.TextWrapped = true
        text.Text = title
        text.Parent = gui
        self.nodes[key] = part
        return part
    end
    for _, row in Catalog.Stamps do
        node("listen_" .. row.id, "LISTEN\n" .. row.title, row.at, "postcard")
        Assets.place(
            root,
            "P03",
            CFrame.new(row.at + Vector3.new(3.5, 0, 1)),
            Vector3.new(5, 3, 2),
            Theme.Walnut,
            false
        )
    end
    for _, row in Catalog.Gardens do
        local p = node("garden_" .. row.id, "TEND\n" .. row.title, row.at, "garden")
        p.Size, p.Transparency = Vector3.new(2, 2, 2), 1
        p:FindFirstChildOfClass("SurfaceGui"):Destroy()
        Assets.place(root, "P11", CFrame.new(row.at), Vector3.new(2, 2, 2), Theme.Coral, false)
        local leaves = Assets.place(
            root,
            "P12",
            CFrame.new(row.at + Vector3.new(0, 1, 0)),
            Vector3.new(2, 2, 2),
            Theme.FadedTeal,
            false
        )
        leaves:SetAttribute("LifeGarden", row.id)
    end
    node("parcel_pickup", "NAYA'S DELIVERY\nSpare record sleeves", Catalog.Parcel.pickup, "parcel")
    node("parcel_drop", "TORI'S RECORD BOX\nLeave a delivery", Catalog.Parcel.drop, "parcel")
    return self
end
function Service:valid(player, key)
    local p = self.owner.profiles[player]
    return p
        and p.ready
        and not p.station
        and self.nodes[key]
        and self.owner.nearby(player, self.nodes[key], 12)
end
function Service:interact(player, key)
    if not self:valid(player, key) or os.clock() - (self.last[player] or 0) < 0.35 then
        return
    end
    self.last[player] = os.clock()
    local profile = self.owner.profiles[player]
    local life = profile.quay.life
    if key:sub(1, 7) == "listen_" then
        local id = key:sub(8)
        for _, row in Catalog.Stamps do
            if row.id == id then
                if life.stamps[id] then
                    self.owner.send(player, row.note)
                    return
                end
                self.listening[player] =
                    { key = key, id = id, untilTime = os.clock() + 3.5, note = row.note }
                self.owner.send(player, "Stay a moment and listen… your notebook is open.")
                return
            end
        end
    elseif key:sub(1, 7) == "garden_" then
        local id = key:sub(8)
        if life.gardens[id] then
            self.owner.send(player, "Already tended. The flowers are doing well.")
            return
        end
        life.gardens[id] = true
        self:award(player, profile, "A little care goes a long way. +20 neighborhood XP.")
    elseif key == "parcel_pickup" then
        if life.parcel == 0 then
            life.parcel = 1
            self.owner:changed(player, profile)
            self.owner.send(
                player,
                "Naya: Could you take these spare sleeves to Tori's record box by the dock? They are in your bag."
            )
        else
            self.owner.send(
                player,
                if life.parcel == 1
                    then "The sleeves are in your bag. Tori's record box is beside the dock listening post."
                    else "Naya: Tori loved the sleeves. Thanks for taking the long way around."
            )
        end
    elseif key == "parcel_drop" then
        if life.parcel == 1 then
            life.parcel = 2
            self:award(
                player,
                profile,
                "Tori: Perfect timing! These will keep the records dry. +45 neighborhood XP."
            )
        else
            self.owner.send(
                player,
                if life.parcel == 2
                    then "Tori: The records are safe. You're always welcome here."
                    else "An empty delivery tray. Naya at the record market might have something for Tori."
            )
        end
    end
end
function Service:award(player, profile, message)
    self.owner:changed(player, profile)
    self.owner:celebrate(player, "neighborhood_life", true)
    self.owner.send(player, message)
end
function Service:tick()
    for player, listen in self.listening do
        if not self:valid(player, listen.key) then
            self.listening[player] = nil
        elseif os.clock() >= listen.untilTime then
            self.listening[player] = nil
            local profile = self.owner.profiles[player]
            if not profile.quay.life.stamps[listen.id] then
                profile.quay.life.stamps[listen.id] = true
                self:award(
                    player,
                    profile,
                    listen.note .. "  Sound postcard collected. +15 neighborhood XP."
                )
            end
        end
    end
end
function Service:remove(player)
    self.last[player], self.listening[player] = nil, nil
end
return Service
