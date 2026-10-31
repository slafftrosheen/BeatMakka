local Shared = game.ReplicatedStorage.Shared
local Catalog = require(Shared.RoomCatalog)
local Cosmetics = require(Shared.CosmeticCatalog)
local Theme = require(Shared.Theme)
local Assets = require(script.Parent.AssetSpawner)
local Details = require(script.Parent.AssetDetails)
local Rooms = {}
Rooms.__index = Rooms

local function appearance(model, finish)
    for _, object in model:GetDescendants() do
        if object:IsA("BasePart") and object:GetAttribute("RoomTint") then
            object.Color = Cosmetics.Sets[finish].primary
        end
    end
    -- Imported art must explicitly match the shared atlas. Placeholders stay honest.
    for _, asset in model:GetDescendants() do
        local art = asset:FindFirstChild("Art")
        if not art or asset:GetAttribute("TextureLayout") ~= Cosmetics.TextureLayout then
            continue
        end
        local size = asset:GetAttribute("TextureResolution")
        if size ~= 512 and size ~= 1024 then
            continue
        end
        if game:GetService("RunService"):IsStudio() then
            local parts = art:GetDescendants()
            if art:IsA("MeshPart") then
                table.insert(parts, art)
            end
            for _, mesh in parts do
                if mesh:IsA("MeshPart") then
                    mesh:SetAttribute("LocalMaterialKey", finish .. "_" .. size)
                end
            end
            continue
        end
        local library = game.ReplicatedStorage:FindFirstChild("AppearanceLibrary")
        local template = library and library:FindFirstChild(finish .. "_" .. size)
        if not template or not template:IsA("SurfaceAppearance") then
            continue
        end
        local parts = art:GetDescendants()
        if art:IsA("MeshPart") then
            table.insert(parts, art)
        end
        for _, mesh in parts do
            if mesh:IsA("MeshPart") then
                for _, surface in mesh:GetChildren() do
                    if surface:IsA("SurfaceAppearance") then
                        surface:Destroy()
                    end
                end
                template:Clone().Parent = mesh
            end
        end
    end
end

function Rooms.new(bays, nearby)
    return setmetatable({ bays = bays, byPlayer = {}, nearby = nearby }, Rooms)
end

function Rooms:update(player, profile)
    local bay = self.bays[self.byPlayer[player]]
    if not bay or bay.owner ~= player then
        return
    end
    local room = Catalog.sanitize(profile.room, profile)
    local signature = room.finish .. ":" .. room.sign .. ":" .. room.decor
    if signature == bay.signature then
        return
    end
    bay.signature = signature
    bay.decor:ClearAllChildren()
    if room.decor == "vinyl" then
        local crate = Assets.place(
            bay.decor,
            "H03",
            CFrame.new(bay.x, 11.1, 10.3),
            Vector3.new(3, 2.5, 3),
            Theme.Walnut
        )
        Details.attach(crate, "H03", crate:GetPivot())
    end
    appearance(bay.model, room.finish)
    bay.label.Text = Catalog.Signs[room.sign] .. "\n" .. player.DisplayName
    bay.model:SetAttribute("Finish", room.finish)
    bay.model:SetAttribute("Sign", room.sign)
    bay.model:SetAttribute("Decor", room.decor)
end

function Rooms:assign(player, profile)
    if self.byPlayer[player] then
        return true
    end
    for _, id in { "Room_1", "Room_2" } do
        local bay = self.bays[id]
        if bay and not bay.owner then
            bay.owner = player
            bay.signature = nil
            self.byPlayer[player] = id
            bay.model:SetAttribute("OwnerUserId", player.UserId)
            self:update(player, profile)
            return true
        end
    end
    return false
end

function Rooms:summary(player, profile)
    local id = self.byPlayer[player]
    local bay = self.bays[id]
    return {
        id = id,
        stationId = bay and bay.stationId,
        choices = Catalog.sanitize(profile.room, profile),
        decorUnlocked = profile.unlocked.I01 == true,
    }
end

function Rooms:change(player, profile, key, value)
    local bay = self.bays[self.byPlayer[player]]
    if not bay or bay.owner ~= player then
        return false,
            "Both workshops are occupied. You can visit; a free bay is assigned when available."
    end
    if not self.nearby(player, bay.anchor, 15) then
        return false, "Return to your workshop to change its appearance."
    end
    if not Catalog.allowed(profile, key, value) then
        return false,
            "That workshop choice is unavailable. Discover the quay metal sound for vinyl decor."
    end
    if profile.room[key] == value then
        return false, "That workshop choice is already selected."
    end
    profile.room[key] = value
    profile.editVersion += 1
    self:update(player, profile)
    return true, "Workshop updated for everyone here. Save profile to keep your choices."
end

function Rooms:remove(player)
    local bay = self.bays[self.byPlayer[player]]
    self.byPlayer[player] = nil
    if bay and bay.owner == player then
        bay.owner = nil
        bay.signature = nil
        bay.decor:ClearAllChildren()
        appearance(bay.model, "quay")
        bay.label.Text = "RECORD SHOP\nAVAILABLE WORKSHOP"
        bay.model:SetAttribute("OwnerUserId", nil)
        bay.model:SetAttribute("Finish", "quay")
        bay.model:SetAttribute("Sign", "records")
        bay.model:SetAttribute("Decor", "none")
    end
end

return Rooms
