local Http = game:GetService("HttpService")
local Expression = require(game.ReplicatedStorage.Shared.BeatExpression)
local Publisher = {}
Publisher.__index = Publisher
function Publisher.new()
    local folder = Instance.new("Folder")
    folder.Name, folder.Parent = "QuayLiveMusic", workspace
    return setmetatable({ folder = folder }, Publisher)
end
function Publisher:remove(player)
    local value = self.folder:FindFirstChild(tostring(player.UserId))
    if value then
        value:Destroy()
    end
end
function Publisher:update(player, profile, van)
    local name = tostring(player.UserId)
    local value = self.folder:FindFirstChild(name)
    if not (profile.broadcast and profile.playing and profile.station and van) then
        if value then
            value:Destroy()
        end
        return
    end
    local t = profile.transport
    local expression = t
        and Expression.describeSchedule(t.schedule, t.startedAt, t.epoch, t.offset, t.loop)
    if not expression then
        self:remove(player)
        return
    end
    if not expression.active then
        if value then
            value:Destroy()
        end
        return
    end
    local at = van.door.anchor.Position
    expression.x, expression.y, expression.z = at.X, at.Y, at.Z
    expression.owner = player.UserId
    expression.playback = {
        schedule = t.schedule,
        startedAt = t.startedAt,
        epoch = t.epoch,
        offset = t.offset,
        loop = t.loop,
        playing = t.playing,
    }
    local encoded = Http:JSONEncode(expression)
    if not value then
        value = Instance.new("StringValue")
        value.Name = name
    end
    if value.Value ~= encoded then
        value.Value = encoded
    end
    value.Parent = self.folder
end
return Publisher
