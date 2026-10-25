local Life = {}
Life.__index = Life
function Life.new()
    local self = setmetatable({ enabled = true, entries = {}, elapsed = 0 }, Life)
    local root =
        workspace:WaitForChild("NeedleQuay"):WaitForChild("DemoDistrict"):WaitForChild("LivingQuay")
    for _, object in root:GetDescendants() do
        if object:IsA("BasePart") and object:GetAttribute("QuaySway") then
            table.insert(self.entries, {
                object = object,
                base = object.CFrame,
                amount = object:GetAttribute("QuaySway"),
                phase = object.Position.X * 0.13,
            })
        elseif
            object:IsA("Model")
            and (object:GetAttribute("QuayBoat") or object:GetAttribute("QuayFan"))
        then
            table.insert(self.entries, {
                object = object,
                base = object:GetPivot(),
                boat = object:GetAttribute("QuayBoat"),
                fan = object:GetAttribute("QuayFan"),
                phase = object:GetPivot().Position.X * 0.13,
            })
        end
    end
    self.connection = game:GetService("RunService").Heartbeat:Connect(function(dt)
        self.elapsed += dt
        if self.elapsed < 1 / 24 then
            return
        end
        self.elapsed = 0
        local camera = workspace.CurrentCamera
        if not camera then
            return
        end
        local t = os.clock()
        for _, entry in self.entries do
            local near = (camera.CFrame.Position - entry.base.Position).Magnitude < 160
            local active = self.enabled
                and near
                and (not entry.fan or (self.progress and self.progress.completed["NQ-Q04"]))
            if not active and not entry.active then
                continue
            end
            entry.active = active
            local cf = entry.base
            if self.enabled and near then
                if entry.fan then
                    if self.progress and self.progress.completed["NQ-Q04"] then
                        cf *= CFrame.Angles(0, 0, t * 2.5)
                    end
                elseif entry.boat then
                    cf *= CFrame.new(0, math.sin(t * 0.7 + entry.phase) * 0.15, 0) * CFrame.Angles(
                        math.sin(t * 0.45 + entry.phase) * 0.012,
                        0,
                        math.cos(t * 0.6 + entry.phase) * 0.018
                    )
                else
                    cf *= CFrame.Angles(0, 0, math.sin(t * 0.8 + entry.phase) * entry.amount)
                end
            end
            if entry.boat or entry.fan then
                entry.object:PivotTo(cf)
            else
                entry.object.CFrame = cf
            end
        end
    end)
    return self
end
function Life:destroy()
    self.connection:Disconnect()
    for _, entry in self.entries do
        if entry.object.Parent then
            if entry.boat or entry.fan then
                entry.object:PivotTo(entry.base)
            else
                entry.object.CFrame = entry.base
            end
        end
    end
end
return Life
