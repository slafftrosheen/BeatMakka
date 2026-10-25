-- Rigid authored joints retain the source geometry; animation is client-local.
local Neighbors = {}
Neighbors.__index = Neighbors
function Neighbors.new()
    local self = setmetatable({ actors = {}, enabled = true, elapsed = 0 }, Neighbors)
    local district = workspace:WaitForChild("NeedleQuay"):WaitForChild("DemoDistrict")
    for index, actor in district:WaitForChild("Neighbors"):GetChildren() do
        local parts, joints = {}, {}
        for _, mesh in actor:GetDescendants() do
            if mesh:IsA("MeshPart") and mesh:GetAttribute("RigidBone") then
                local bone = mesh:GetAttribute("RigidBone")
                joints[bone] = mesh:GetAttribute("JointPivot")
                table.insert(parts, {
                    mesh = mesh,
                    base = mesh.CFrame,
                    localFrame = actor:GetPivot():ToObjectSpace(mesh.CFrame),
                    bone = bone,
                })
            end
        end
        table.insert(self.actors, {
            model = actor,
            origin = actor:GetPivot(),
            parts = parts,
            joints = joints,
            phase = index * 1.7,
        })
    end
    self.connection = game:GetService("RunService").Heartbeat:Connect(function(dt)
        self.elapsed += dt
        if self.elapsed < 1 / 30 then
            return
        end
        self.elapsed = 0
        local camera = workspace.CurrentCamera
        for _, actor in self.actors do
            local origin = actor.origin
            local walk = actor.model:GetAttribute("AmbientWalk")
            local walking = walk and self.enabled
            if walking then
                local t = os.clock() * 0.14 + actor.phase
                local at = origin.Position + Vector3.new(math.sin(t) * walk, 0, math.cos(t) * 2)
                origin =
                    CFrame.lookAt(at, at + Vector3.new(math.cos(t) * walk, 0, -math.sin(t) * 2))
            end
            local active = self.enabled
                and camera
                and (origin.Position - camera.CFrame.Position).Magnitude < 80
            local phase = os.clock() * 1.1 + actor.phase
            for _, part in actor.parts do
                local transform = CFrame.identity
                if active then
                    local jointName = if walking
                            and (part.bone:find("Left.*Leg") or part.bone == "LeftFoot")
                        then "LeftUpperLeg"
                        elseif
                            walking and (part.bone:find("Right.*Leg") or part.bone == "RightFoot")
                        then "RightUpperLeg"
                        elseif
                            part.bone:find("Left.*Arm")
                            or part.bone == "LeftHand"
                        then "LeftUpperArm"
                        elseif
                            part.bone:find("Right.*Arm") or part.bone == "RightHand"
                        then "RightUpperArm"
                        elseif part.bone == "Head" then "Head"
                        else nil
                    local joint = jointName and actor.joints[jointName]
                    -- Imported continuous surfaces must not open cracks at rigid group cuts.
                    if joint and not actor.model:GetAttribute("ContinuousSkin") then
                        local pivot = origin * CFrame.new(joint)
                        transform = pivot
                            * CFrame.Angles(
                                if walking
                                    then math.sin(os.clock() * 4 + actor.phase) * (if part.bone:find(
                                            "Left"
                                        )
                                        then 0.24
                                        else -0.24)
                                    else 0,
                                math.sin(phase) * 0.025,
                                math.sin(phase * 0.7) * 0.018
                            )
                            * pivot:Inverse()
                    end
                    transform = CFrame.new(0, math.sin(phase) * 0.018, 0) * transform
                end
                part.mesh.CFrame = transform * origin * part.localFrame
            end
            local skin = actor.model:FindFirstChild("LocalSkinnedBody")
            if skin then
                skin.CFrame = origin * CFrame.new(skin:GetAttribute("SkinCenter"))
                for _, bone in skin:GetDescendants() do
                    if bone:IsA("Bone") then
                        local transform = CFrame.identity
                        if active then
                            local side = if bone.Name:find("Left") then 1 else -1
                            if bone.Name:find("UpperLeg") and walking then
                                transform = CFrame.Angles(
                                    math.sin(os.clock() * 4 + actor.phase) * 0.23 * side,
                                    0,
                                    0
                                )
                            elseif bone.Name:find("LowerLeg") and walking then
                                transform = CFrame.Angles(
                                    math.max(0, -math.sin(os.clock() * 4 + actor.phase) * side)
                                        * 0.25,
                                    0,
                                    0
                                )
                            elseif bone.Name:find("UpperArm") then
                                transform = CFrame.Angles(
                                    if walking
                                        then -math.sin(os.clock() * 4 + actor.phase) * 0.12 * side
                                        else math.sin(phase) * 0.025,
                                    0,
                                    math.sin(phase * 0.7) * 0.018
                                )
                            elseif bone.Name == "Head" then
                                transform = CFrame.Angles(0, math.sin(phase * 0.55) * 0.045, 0)
                            elseif bone.Name == "UpperTorso" then
                                transform = CFrame.new(0, math.sin(phase) * 0.012, 0)
                            end
                        end
                        bone.Transform = transform
                    end
                end
            end
        end
    end)
    return self
end
function Neighbors:destroy()
    self.connection:Disconnect()
    for _, actor in self.actors do
        for _, part in actor.parts do
            if part.mesh.Parent then
                part.mesh.CFrame = part.base
            end
        end
    end
end
return Neighbors
