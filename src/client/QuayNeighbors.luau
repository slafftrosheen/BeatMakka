local MusicField = require(script.Parent.QuayMusicField)
local Expression = require(game.ReplicatedStorage.Shared.BeatExpression)
-- Personal, distance-limited resident presentation, separate from every music clock.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Neighbors = {}
Neighbors.__index = Neighbors
local path =
    { Vector3.new(-12, 0, 0), Vector3.new(12, 0, 0), Vector3.new(12, 0, 7), Vector3.new(-12, 0, 7) }
local function route(time, points, speed, pause)
    for index, a in points do
        local b = points[index % #points + 1]
        local duration = (b - a).Magnitude / speed
        if time < pause then
            return a, b - a, false
        end
        time -= pause
        if time < duration then
            return a:Lerp(b, time / duration), b - a, true
        end
        time -= duration
    end
    return nil
end

local function noticeKind(actor)
    return if (actor.musicNoticeUntil or 0) > (actor.noticeUntil or 0)
        then actor.musicNoticeKind
        else actor.noticeKind
end
local function rotation(actor, name, time, walking, greeting, engaged)
    local side = if name:sub(1, 4) == "Left" then 1 else -1
    local phase = time * 4.5 + actor.phase
    if time < math.max(actor.noticeUntil or 0, actor.musicNoticeUntil or 0) and not walking then
        if noticeKind(actor) == "roamer" and name == "RightUpperArm" then
            return CFrame.Angles(1.15, -0.25, 0.15)
        elseif noticeKind(actor) == "badge" and name == "Head" then
            return CFrame.Angles(math.sin(time * 5) * 0.13, 0, 0)
        elseif noticeKind(actor) == "title" and name:find("UpperArm") then
            return CFrame.Angles(0.9, 0, side * 0.18)
        elseif noticeKind(actor) == "title" and name:find("LowerArm") then
            return CFrame.Angles(0.75 + math.sin(time * 8) * 0.18, 0, 0)
        elseif noticeKind(actor) == "companion" and name == "RightUpperArm" then
            return CFrame.Angles(1.0, 0, math.sin(time * 6) * 0.12)
        end
    end
    if time < (actor.cheerUntil or 0) and not walking then
        if name:find("UpperArm") then
            return CFrame.Angles(1.0, 0, side * 0.2)
        end
        if name:find("LowerArm") then
            return CFrame.Angles(0.8 + math.sin(time * 9) * 0.18, 0, 0)
        end
    end
    if actor.dancing and not walking then
        local beat = actor.beatPhase or time * 5
        if name == "UpperTorso" then
            return CFrame.Angles(0, math.sin(beat / 2) * 0.1, math.sin(beat) * 0.07)
        end
        if name:find("UpperArm") then
            return CFrame.Angles(0.45 + math.sin(beat + side) * 0.2, 0, side * 0.12)
        end
        if name:find("LowerArm") then
            return CFrame.Angles(0.7, 0, 0)
        end
        if name:find("UpperLeg") then
            return CFrame.Angles(math.sin(beat) * side * 0.1, 0, 0)
        end
    end
    if greeting and name == "RightUpperArm" then
        return CFrame.Angles(1.1, 0, math.sin(time * 7) * 0.12)
    end
    if not walking and not greeting then
        if actor.role == "chat" and name == "RightLowerArm" then
            return CFrame.Angles(0.35 + math.sin(time * 1.7 + actor.phase) * 0.22, 0, 0)
        elseif actor.role == "browse" and name == "Head" then
            return CFrame.Angles(
                -0.16 + math.sin(time * 0.7 + actor.phase) * 0.05,
                math.sin(time * 0.4 + actor.phase) * 0.12,
                0
            )
        elseif actor.role == "repair" and name == "RightLowerArm" then
            return CFrame.Angles(0.6 + math.sin(time * 2.2 + actor.phase) * 0.12, 0, 0)
        end
    end
    if walking then
        if name:find("UpperLeg") then
            return CFrame.Angles(math.sin(phase) * 0.23 * side, 0, 0)
        end
        if name:find("LowerLeg") then
            return CFrame.Angles(-math.max(0, -math.sin(phase) * side) * 0.25, 0, 0)
        end
        if name:find("UpperArm") then
            return CFrame.Angles(-math.sin(phase) * 0.16 * side, 0, 0)
        end
    end
    if name == "Head" then
        return CFrame.Angles(
            if engaged then -0.06 else 0,
            math.sin(time * 0.65 + actor.phase) * 0.035,
            0
        )
    end
    if name == "UpperTorso" then
        return CFrame.new(0, math.sin(time * 1.1 + actor.phase) * 0.009, 0)
    end
    if not greeting then
        if actor.host == "cafe" and name:find("LowerArm") then
            return CFrame.Angles(0.5, 0, 0)
        end
        if actor.host == "P2" and name == "RightLowerArm" then
            return CFrame.Angles(0.4 + math.sin(time * 1.3) * 0.07, 0, 0)
        end
        if actor.host == "P3" and name == "LeftLowerArm" then
            return CFrame.Angles(0.3, 0, 0)
        end
        if actor.host == "sana" and name == "RightUpperArm" then
            return CFrame.Angles(0.15, 0, math.sin(time * 0.8) * 0.06)
        end
    end
    return CFrame.identity
end
function Neighbors.new()
    local self = setmetatable({ actors = {}, enabled = true, elapsed = 0 }, Neighbors)
    local function refreshMusic()
        local raw = workspace:GetAttribute("QuayPublicBeat")
        self.music = if raw then game:GetService("HttpService"):JSONDecode(raw) else nil
    end
    refreshMusic()
    self.musicConnection =
        workspace:GetAttributeChangedSignal("QuayPublicBeat"):Connect(refreshMusic)
    local folder =
        workspace:WaitForChild("NeedleQuay"):WaitForChild("DemoDistrict"):WaitForChild("Neighbors")
    local function register(model)
        if self.actors[model] or not model:IsA("Model") then
            return
        end
        local actor = {
            model = model,
            origin = model:GetPivot(),
            parts = {},
            joints = {},
            phase = model:GetPivot().Position.X * 0.07 + model:GetPivot().Position.Z * 0.13,
            host = model:GetAttribute("QuayHost"),
            travel = 0,
            role = model:GetAttribute("StreetRole"),
            speed = model:GetAttribute("WalkSpeed") or 2.2,
            pause = model:GetAttribute("WalkPause") or 4,
        }
        actor.path, actor.cycle = path, 0
        local routeData = model:GetAttribute("AmbientRoute")
        if routeData then
            actor.path = {}
            for _, point in game:GetService("HttpService"):JSONDecode(routeData) do
                table.insert(actor.path, Vector3.new(table.unpack(point)))
            end
        end
        for i, point in actor.path do
            actor.cycle += actor.pause + (actor.path[i % #actor.path + 1] - point).Magnitude / actor.speed
        end
        actor.travel = ((model:GetAttribute("AmbientPhase") or 0) * 3) % actor.cycle
        for _, part in model:GetDescendants() do
            if part:IsA("BasePart") then
                local bone = part:GetAttribute("RigidBone")
                local joint = part:GetAttribute("JointPivot")
                if bone and joint then
                    actor.joints[bone] = joint * model:GetScale()
                end
                table.insert(actor.parts, {
                    mesh = part,
                    base = part.CFrame,
                    frame = actor.origin:ToObjectSpace(part.CFrame),
                    bone = bone,
                })
            end
        end
        self.actors[model] = actor
    end
    for _, model in folder:GetChildren() do
        register(model)
    end
    self.added = folder.ChildAdded:Connect(register)
    self.connection = RunService.RenderStepped:Connect(function(dt)
        self.elapsed += dt
        local step = math.min(self.elapsed, 0.15)
        self.elapsed = 0
        local camera = workspace.CurrentCamera
        if not camera then
            return
        end
        local character = Players.LocalPlayer.Character
        local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
        local time = os.clock()
        for model, actor in self.actors do
            if not model.Parent then
                self.actors[model] = nil
                continue
            end
            local near = (camera.CFrame.Position - (actor.current or actor.origin).Position).Magnitude
                < 100
            local active = self.enabled and near
            if not active and actor.active == false then
                continue
            end
            actor.active = active
            local activity = self.state and self.state.quay and self.state.quay.sideActivity
            local music = MusicField.nearest((actor.current or actor.origin).Position, 48)
            local source = music and Vector3.new(music.x, music.y, music.z)
            local listening = active
                and model:GetAttribute("GenericResident")
                and source
                and ((actor.current or actor.origin).Position - source).Magnitude < 48
                and workspace:GetServerTimeNow() >= music.startedAt
            if listening then
                local change = Expression.change(actor.lastHeardMusic, music)
                if change and time > (actor.nextMusicReaction or 0) then
                    actor.musicNoticeKind = if change == "grit" or change == "energy"
                        then "title"
                        else "badge"
                    actor.musicNoticeUntil, actor.nextMusicReaction = time + 1.5, time + 7
                    actor.noticeTarget = source
                    model:SetAttribute("MusicReaction", change)
                end
                actor.lastHeardMusic = music
                actor.heardSince = actor.heardSince or time
                actor.beatPhase = Expression.phase(music, workspace:GetServerTimeNow())
                    * math.pi
                    * 2
                actor.energy = music.intensity or 0.5
                actor.musicStyle = music.style or "groove"
                model:SetAttribute("MusicStyle", actor.musicStyle)
                model:SetAttribute("MusicIntensity", actor.energy)
                model:SetAttribute("MusicBeat", actor.beatPhase / (math.pi * 2))
            else
                if active and actor.heardSince and time - actor.heardSince >= 4 then
                    actor.cheerUntil = time + 2.2
                end
                actor.heardSince, actor.beatPhase = nil, nil
            end
            actor.dancing = listening
                or (
                    active
                    and model:GetAttribute("StreetAudience")
                    and activity ~= nil
                    and playerRoot ~= nil
                    and (playerRoot.Position - actor.origin.Position).Magnitude < 24
                )
            local origin, walking = actor.current or actor.origin, false
            if
                active
                and model:GetAttribute("AmbientWalk")
                and not listening
                and time >= (actor.cheerUntil or 0)
                and time >= math.max(actor.noticeUntil or 0, actor.musicNoticeUntil or 0)
            then
                if not playerRoot or (playerRoot.Position - origin.Position).Magnitude > 5 then
                    actor.travel = (actor.travel + step) % actor.cycle
                end
                local offset, direction, moving =
                    route(actor.travel, actor.path, actor.speed, actor.pause)
                if offset then
                    local at = actor.origin.Position + offset
                    local facing = CFrame.lookAt(at, at + direction)
                    local turn = origin.Rotation:Lerp(facing.Rotation, 1 - math.exp(-step * 7))
                    origin = CFrame.new(at) * turn
                    walking = moving
                        and (not playerRoot or (playerRoot.Position - at).Magnitude > 5)
                end
            end
            if listening and source then
                local target = Vector3.new(source.X, origin.Position.Y, source.Z)
                if (target - origin.Position).Magnitude > 0.5 then
                    origin =
                        origin:Lerp(CFrame.lookAt(origin.Position, target), 1 - math.exp(-step * 3))
                end
            end
            local close = playerRoot and (playerRoot.Position - origin.Position).Magnitude < 14
            if
                active
                and close
                and not actor.close
                and (actor.host or model:GetAttribute("GenericResident"))
                and time > (actor.nextGreeting or 0)
            then
                actor.greetingUntil = time + 1.6
                actor.nextGreeting = time + 22 + actor.phase % 8
            end
            actor.close = close
            local engaged = self.state
                and self.state.quay
                and self.state.quay.dialogue
                and self.state.quay.dialogue.id == actor.host
            if active and close and actor.host then
                local localPoint = actor.origin:PointToObjectSpace(playerRoot.Position)
                local yaw = math.clamp(math.atan2(-localPoint.X, -localPoint.Z), -0.55, 0.55)
                local target = actor.origin * CFrame.Angles(0, yaw, 0)
                origin = origin:Lerp(target, 1 - math.exp(-step * 4))
            end
            if
                active
                and time < math.max(actor.noticeUntil or 0, actor.musicNoticeUntil or 0)
                and actor.noticeTarget
            then
                local target =
                    Vector3.new(actor.noticeTarget.X, origin.Position.Y, actor.noticeTarget.Z)
                if (target - origin.Position).Magnitude > 0.5 then
                    origin =
                        origin:Lerp(CFrame.lookAt(origin.Position, target), 1 - math.exp(-step * 4))
                end
            end
            actor.current = origin
            local greeting = active and time < (actor.greetingUntil or 0)
            -- Triangle-group fallback meshes are not a deformable rig. Keep the
            -- whole figure intact until its continuous weighted skin is ready.
            for _, entry in actor.parts do
                if entry.mesh.Parent then
                    entry.mesh.CFrame = origin * entry.frame
                end
            end
            local skin = model:FindFirstChild("LocalSkinnedBody")
            if skin ~= actor.skin then
                actor.skin, actor.bones = skin, {}
                if skin then
                    for _, bone in skin:GetDescendants() do
                        if bone:IsA("Bone") then
                            table.insert(actor.bones, bone)
                        end
                    end
                end
            end
            if skin then
                local presentation = CFrame.new()
                if actor.dancing and actor.beatPhase then
                    local beat, energy = actor.beatPhase, actor.energy or 0.5
                    local lift = if actor.musicStyle == "grit"
                        then math.max(0, math.sin(beat)) * 0.045 * energy
                        else 0
                    local sway = if actor.musicStyle == "space"
                        then math.sin(beat / 2) * 0.06 * energy
                        else 0
                    presentation = CFrame.new(sway, lift, 0)
                end
                skin.CFrame = origin * presentation * CFrame.new(skin:GetAttribute("SkinCenter"))
                local action = if time < (actor.cheerUntil or 0)
                    then "cheer"
                    elseif actor.dancing then "dance"
                    elseif greeting then "greet"
                    elseif walking then "walk"
                    else "greet"
                local gain = skin:GetAttribute("Motion_" .. action) or 1
                if actor.dancing then
                    gain *= 0.4 + 0.6 * (actor.energy or 0.5)
                end
                if time < math.max(actor.noticeUntil or 0, actor.musicNoticeUntil or 0) then
                    gain = math.min(
                        skin:GetAttribute("Motion_cheer") or 1,
                        skin:GetAttribute("Motion_greet") or 1
                    ) * 0.9
                end
                skin:SetAttribute("MotionGain", gain)
                for _, bone in actor.bones do
                    local target = if active
                        then rotation(actor, bone.Name, time, walking, greeting, engaged)
                        else CFrame.identity
                    target = CFrame.new():Lerp(target, gain)
                    bone.Transform = bone.Transform:Lerp(target, 1 - math.exp(-step * 12))
                end
            end
            model:SetAttribute(
                "NeighborhoodAction",
                if not active
                    then "rest"
                    elseif
                        time < math.max(actor.noticeUntil or 0, actor.musicNoticeUntil or 0)
                    then "notice_" .. noticeKind(actor)
                    elseif time < (actor.cheerUntil or 0) then "cheer"
                    elseif actor.dancing then "dance"
                    elseif greeting then "greet"
                    elseif engaged then "talk"
                    elseif walking then "walk"
                    elseif actor.host == "cafe" then "serve"
                    elseif actor.host == "P2" then "repair"
                    else "listen"
            )
        end
    end)
    return self
end
function Neighbors:destroy()
    self.musicConnection:Disconnect()
    self.connection:Disconnect()
    self.added:Disconnect()
    for _, actor in self.actors do
        for _, part in actor.parts do
            if part.mesh.Parent then
                part.mesh.CFrame = part.base
            end
        end
        if actor.skin and actor.skin.Parent then
            actor.skin.CFrame = actor.origin * CFrame.new(actor.skin:GetAttribute("SkinCenter"))
            for _, bone in actor.bones do
                if bone.Parent then
                    bone.Transform = CFrame.identity
                end
            end
        end
    end
    table.clear(self.actors)
end
function Neighbors:celebrate(position, _serial)
    if not self.enabled then
        return
    end
    local now = os.clock()
    for model, actor in self.actors do
        if
            model.Parent
            and ((actor.current or actor.origin).Position - position).Magnitude < 38
        then
            actor.cheerUntil = now + 2.4 + (actor.phase % 0.7)
            actor.greetingUntil = 0
        end
    end
end
return Neighbors
