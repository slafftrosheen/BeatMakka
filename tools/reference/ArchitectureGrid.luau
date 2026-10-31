-- Offline blockout reference, excluded from the replicated runtime.
-- Exact outer interfaces for the first modular storefront blockout.
-- The window opening itself stays uncut until its dimensions are approved.
local ArchitectureGrid = {}

local BAY_WIDTH = 8
local GRID_SIZE = 4
local WALL_HEIGHT = 12
local WALL_DEPTH = 1
local AWNING_HEIGHT = 2
local AWNING_DEPTH = 4

function ArchitectureGrid.snap(value: number): number
    return math.round(value / GRID_SIZE) * GRID_SIZE
end

function ArchitectureGrid.bayOrigin(anchor: CFrame, bayIndex: number): CFrame
    return anchor * CFrame.new(bayIndex * BAY_WIDTH, 0, 0)
end

function ArchitectureGrid.cornerPostCenter(origin: CFrame): CFrame
    return origin * CFrame.new(0.5, WALL_HEIGHT / 2, -WALL_DEPTH / 2)
end

function ArchitectureGrid.awningCenter(origin: CFrame): CFrame
    return origin
        * CFrame.new(BAY_WIDTH / 2, WALL_HEIGHT - AWNING_HEIGHT / 2, -WALL_DEPTH - AWNING_DEPTH / 2)
end

return ArchitectureGrid
