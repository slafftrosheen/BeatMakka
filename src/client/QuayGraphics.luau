-- Bind only graphics present in this scene; each local image is shared and owned once.
local Assets = game:GetService("AssetService")
local textureUri = require(script.Parent.LocalTextureUri)
local Graphics = {}
Graphics.__index = Graphics

function Graphics.new()
    local self = setmetatable({ images = {}, waiting = {}, dead = false }, Graphics)
    local function bind(object)
        if self.dead or not object:IsA("ImageLabel") then
            return
        end
        local uri = object:GetAttribute("QuayGraphicUri")
        if type(uri) ~= "string" then
            return
        end
        if self.images[uri] then
            object.ImageContent = Content.fromObject(self.images[uri])
        elseif self.waiting[uri] then
            table.insert(self.waiting[uri], object)
        else
            self.waiting[uri] = { object }
            task.spawn(function()
                local ok, image = pcall(function()
                    return Assets:CreateEditableImageAsync(Content.fromUri(textureUri(uri)))
                end)
                if self.dead then
                    if ok and image then
                        image:Destroy()
                    end
                    return
                end
                if ok and image then
                    self.images[uri] = image
                    for _, label in self.waiting[uri] do
                        if label.Parent then
                            label.ImageContent = Content.fromObject(image)
                        end
                    end
                else
                    warn("Quay graphic unavailable: " .. uri)
                end
                self.waiting[uri] = nil
            end)
        end
    end
    local root = workspace:WaitForChild("NeedleQuay")
    self.connection = root.DescendantAdded:Connect(bind)
    for _, object in root:GetDescendants() do
        bind(object)
    end
    return self
end

function Graphics:destroy()
    self.dead = true
    self.connection:Disconnect()
    for _, image in self.images do
        image:Destroy()
    end
    table.clear(self.images)
end

return Graphics
