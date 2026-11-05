-- Local picture signs and nearby performance lighting. No progression or rewards.
local Run = game:GetService("RunService")
local Players = game:GetService("Players")
local Theme = require(game.ReplicatedStorage.Shared.Theme)
local Symbols = require(game.ReplicatedStorage.Shared.QuayGuideSymbols)
local Icons = require(script.Parent.GameIcons)
local Gui = require(script.Parent.GuiFactory)
local Field = require(script.Parent.QuayMusicField)
local Guide = {}
Guide.__index = Guide
function Guide.new(screen)
    local self = setmetatable({ entries = {}, lights = {}, effects = true, elapsed = 0 }, Guide)
    local world = workspace:WaitForChild("NeedleQuay")
    local function register(object)
        if self.dead or not object.Parent or not object:IsA("BasePart") then return end
        if object:GetAttribute("InteriorMusicLight") then
            self.lights[object] = object.Color
        end
        local key = object:GetAttribute("QuayInteraction")
        local street = object:GetAttribute("StreetActivity")
        if not key and not street and not object:GetAttribute("PerformanceVenue") then return end
        local iconName = object:GetAttribute("GuideIcon") or Symbols.forTarget(key or ("activity_" .. (street or "busk")))
        local gui = Gui.make("BillboardGui", screen.Parent, {
            Name = "QuayPictureSign", Adornee = object, Size = UDim2.fromOffset(48, 48),
            StudsOffsetWorldSpace = Vector3.new(0, 4, 0), MaxDistance = 38, AlwaysOnTop = false, Enabled = false,
        })
        local backing = Gui.round(Gui.make("Frame", gui, { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Ink, BorderSizePixel = 0 }), 24)
        Icons.make(backing, iconName, Theme.Amber, 32).Position = UDim2.fromOffset(8, 8)
        self.entries[object] = gui
    end
    for _, object in world:GetDescendants() do register(object) end
    self.added = world.DescendantAdded:Connect(function(object) task.defer(register, object) end)
    self.connection = Run.Heartbeat:Connect(function(dt)
        self.elapsed += dt
        if self.elapsed < 0.12 then return end
        self.elapsed = 0
        local character = Players.LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        for part, gui in self.entries do
            if not part.Parent then gui:Destroy(); self.entries[part] = nil
            else
                local owner = part.Parent:GetAttribute("OwnerUserId")
                gui.Enabled = root ~= nil and (part.Position - root.Position).Magnitude <= 38
                    and (part:GetAttribute("QuayInteraction") ~= "enter" or owner == Players.LocalPlayer.UserId)
                    and part:GetAttribute("LocalCompleted") ~= true
                    and part:GetAttribute("InteriorHidden") ~= true
            end
        end
        for part, base in self.lights do
            if not part.Parent then self.lights[part] = nil
            elseif root and (part.Position - root.Position).Magnitude < 45 then
                local source = self.effects and Field.nearest(part.Position, 24)
                local amount = if source then 0.15 + math.max(0, math.sin((workspace:GetServerTimeNow() - source.startedAt) * math.pi)) * 0.35 else 0
                part.Color = base:Lerp(Theme.Cream, amount)
            else part.Color = base end
        end
    end)
    return self
end
function Guide:destroy()
    self.dead = true
    self.added:Disconnect()
    self.connection:Disconnect()
    for _, gui in self.entries do gui:Destroy() end
    for part, base in self.lights do if part.Parent then part.Color = base end end
end
return Guide
