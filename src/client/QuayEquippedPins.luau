local Players = game:GetService("Players")
local Rewards = require(game.ReplicatedStorage.Shared.QuayRewards)
local Gui = require(script.Parent.GuiFactory)
local Icons = require(script.Parent.GameIcons)
local Theme = require(game.ReplicatedStorage.Shared.Theme)
local P = {}
function P.new()
    local self = { links = {}, boards = {} }
    local function refresh(player)
        if self.boards[player] then
            self.boards[player]:Destroy()
            self.boards[player] = nil
        end
        local head = player.Character and player.Character:FindFirstChild("Head")
        if not head then
            return
        end
        local title = Rewards.find("title", player:GetAttribute("QuayTitle"))
        local badge = Rewards.find("badge", player:GetAttribute("QuayBadge"))
        if not title and not badge then
            return
        end
        local board = Gui.make(
            "BillboardGui",
            head,
            {
                Name = "QuayEquippedRewards",
                Adornee = head,
                Size = UDim2.fromOffset(190, 60),
                StudsOffset = Vector3.new(0, 2.6, 0),
                MaxDistance = 55,
                AlwaysOnTop = false,
            }
        )
        self.boards[player] = board
        if title then
            local label = Gui.label(board, title.label, 14, Theme.Amber)
            label.TextXAlignment = Enum.TextXAlignment.Center
            label.TextStrokeTransparency = 0.3
            label.Size = UDim2.new(1, 0, 0, 24)
        end
        if badge then
            Icons.make(board, badge.icon, Theme.Amber, 30).Position = UDim2.new(0.5, -15, 0, 26)
        end
    end
    local function hook(player)
        local links = {}
        self.links[player] = links
        table.insert(
            links,
            player:GetAttributeChangedSignal("QuayTitle"):Connect(function()
                refresh(player)
            end)
        )
        table.insert(
            links,
            player:GetAttributeChangedSignal("QuayBadge"):Connect(function()
                refresh(player)
            end)
        )
        local function characterAdded(character)
            task.spawn(function()
                local head = character:WaitForChild("Head", 10)
                if head and self.links[player] == links and player.Character == character then
                    refresh(player)
                end
            end)
        end
        table.insert(links, player.CharacterAdded:Connect(characterAdded))
        if player.Character then
            characterAdded(player.Character)
        end
    end
    local function unhook(player)
        for _, link in self.links[player] or {} do
            link:Disconnect()
        end
        self.links[player] = nil
        if self.boards[player] then
            self.boards[player]:Destroy()
            self.boards[player] = nil
        end
    end
    self.add = Players.PlayerAdded:Connect(hook)
    self.remove = Players.PlayerRemoving:Connect(unhook)
    for _, player in Players:GetPlayers() do
        hook(player)
    end
    function self:destroy()
        self.add:Disconnect()
        self.remove:Disconnect()
        for player in self.links do
            unhook(player)
        end
    end
    return self
end
return P
