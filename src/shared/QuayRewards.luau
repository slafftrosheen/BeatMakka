-- Local in-game equipment; unlocks are derived from server-owned progress.
local Badges = require(script.Parent.QuayBadges)
local R = {}
R.Categories = { "title", "badge", "companion", "roamer" }
R.Labels = { title = "TITLES", badge = "PINS", companion = "CHARMS", roamer = "ROAMER" }
R.Items = {
    title = {
        { id = "remixer", label = "QUAY REMIXER", commissions = 6, icon = "knob" },
        { id = "producer", label = "QUAY PRODUCER", commissions = 4, icon = "disc" },
        { id = "friend", label = "QUAY FRIEND", count = 3, icon = "flag" },
        { id = "favorite", label = "BLOCK FAVORITE", count = 6, icon = "badge" },
        { id = "icon", label = "QUAY ICON", count = 9, icon = "badge" },
    },
    badge = {},
    companion = {
        {
            id = "echo",
            label = "ECHO DISC",
            badge = "echo",
            icon = "disc",
            color = Color3.fromRGB(70, 175, 165),
        },
        {
            id = "lantern",
            label = "LANTERN CHARM",
            badge = "lantern",
            icon = "knob",
            color = Color3.fromRGB(247, 181, 72),
        },
        {
            id = "headliner",
            label = "HEADLINER STAR",
            badge = "finale",
            icon = "badge",
            color = Color3.fromRGB(235, 117, 100),
        },
    },
    roamer = {
        {
            id = "coral",
            label = "CORAL RUNNING LIGHTS",
            badge = "dock",
            icon = "steps",
            color = Color3.fromRGB(235, 117, 100),
        },
        {
            id = "teal",
            label = "NEIGHBOR TEAL LIGHTS",
            count = 3,
            icon = "steps",
            color = Color3.fromRGB(70, 175, 165),
        },
        {
            id = "amber",
            label = "AMBER ENCORE LIGHTS",
            count = 6,
            icon = "steps",
            color = Color3.fromRGB(247, 181, 72),
        },
    },
}
for _, badge in Badges.List do
    table.insert(
        R.Items.badge,
        { id = badge.id, label = badge.label, badge = badge.id, icon = badge.icon }
    )
end
function R.find(category, id)
    for _, item in R.Items[category] or {} do
        if item.id == id then
            return item
        end
    end
    return nil
end
function R.count(progress)
    local count = 0
    for _, badge in Badges.List do
        if Badges.earned(progress, badge) then
            count += 1
        end
    end
    return count
end
function R.earned(progress, item)
    if not item then
        return false
    end
    if item.commissions then
        local count = 0
        for _, request in require(script.Parent.QuayBeatCommissions).List do
            if progress.commissions and progress.commissions[request.id] then
                count += 1
            end
        end
        return count >= item.commissions
    end
    if item.count then
        return R.count(progress) >= item.count
    end
    for _, badge in Badges.List do
        if badge.id == item.badge then
            return Badges.earned(progress, badge)
        end
    end
    return false
end
function R.hint(item)
    if item.commissions then
        return "Complete " .. tostring(item.commissions) .. " beat requests"
    end
    if item.count then
        return tostring(item.count) .. " keepsakes"
    end
    for _, badge in Badges.List do
        if badge.id == item.badge then
            return badge.hint
        end
    end
    return ""
end
function R.sanitize(value, progress)
    local result = {}
    for _, category in R.Categories do
        local id = if type(value) == "table" then value[category] else nil
        result[category] = if type(id) == "string"
                and R.earned(progress, R.find(category, id))
            then id
            else "none"
    end
    return result
end
function R.equal(a, b)
    for _, category in R.Categories do
        if (a and a[category] or "none") ~= (b and b[category] or "none") then
            return false
        end
    end
    return true
end
return R
