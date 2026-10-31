-- Only the local demo uses these budgeted copies; source atlases stay intact.
local bindings = require(game:GetService("ReplicatedStorage").Shared.LocalTextureBudget)
return function(uri)
    return bindings[uri] or uri
end
