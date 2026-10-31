-- Apply physics/query/shadow defaults to solid scenery, preserving authored proxies.
local S = {}
local function context(object, root)
    local authored, actor = false, false
    local p = object.Parent
    while p and p ~= root do
        authored = authored or p:GetAttribute("AuthoredCollision") == true
        actor = actor
            or p:GetAttribute("ArtKind") == "npc"
            or p:GetAttribute("ArtKind") == "companion"
            or p:GetAttribute("QuayHost") ~= nil
            or p:GetAttribute("StreetRole") ~= nil
            or p:GetAttribute("AmbientWalk") ~= nil
            or p:GetAttribute("QuayFan") == true
            or (p:IsA("Model") and p:FindFirstChildOfClass("Humanoid") ~= nil)
        if p:IsA("Model") and p:FindFirstChild("CollisionProxy") then
            authored = true
        end
        p = p.Parent
    end
    return authored, actor
end
function S.apply(object, root)
    if object:IsA("BillboardGui") or object:IsA("SurfaceGui") then
        object.AlwaysOnTop = false
    elseif object:IsA("Light") then
        object.Shadows = true
    elseif object:IsA("ProximityPrompt") then
        -- Sampler targets deliberately sit inside their own pad geometry.
        if not object.Parent:GetAttribute("StationId") then
            object.RequiresLineOfSight = true
        end
    elseif object:IsA("BasePart") then
        local authored, actor = context(object, root)
        if object.Transparency >= 0.95 then
            object.CastShadow = false
            -- Invisible authored collision must still stop sight queries.
            object.CanQuery = object.CanCollide
            return
        end
        if actor then
            object.CastShadow = true
            return
        end
        if object:GetAttribute("NonOccluding") or object.Name:find("Water") then
            return
        end
        object.CastShadow = true
        -- Authored shells/proxies own blocking and line of sight. Box queries on
        -- their decorative mesh envelopes otherwise hide reachable door prompts.
        object.CanQuery = if authored then object.CanCollide else object.CanQuery
        object.CanTouch = false
        -- Preserve the builder's collision decision for foliage, cables, trim,
        -- rugs and awnings. Turning every anchored visual into a collider traps walkers.
        if object:GetAttribute("SolidCollision") == true and not authored then
            object.CanCollide = true
            object.CanQuery = true
        end
        object:SetAttribute("SolidScenery", true)
    end
end
function S.install(root)
    local count = 0
    for _, object in root:GetDescendants() do
        S.apply(object, root)
        count += 1
        if count % 500 == 0 then
            task.wait()
        end
    end
    root.DescendantAdded:Connect(function(object)
        task.defer(function()
            if object:IsDescendantOf(root) then
                S.apply(object, root)
            end
        end)
    end)
    root:SetAttribute(
        "SolidSceneryPolicy",
        "Collision + queries + shadows; actors/effects excluded"
    )
end
return S
