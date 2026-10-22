-- Authored project proposals. Confirm visual placement against the approved style board
-- before treating any blockout as art-approved.
local AssetContracts = {
    Sampler = {
        Id = "H01",
        Size = Vector3.new(6, 1.25, 4),
        PadCount = 16,
        PadRows = 4,
        PadColumns = 4,
        Forward = Vector3.new(0, 0, -1),
        TriangleBudget = 4500,
        CandidateFaceLimit = 2200,
    },
    StreetLamp = {
        Id = "H05",
        Size = Vector3.new(2.5, 12, 3),
        TriangleBudget = 1100,
        CandidateFaceLimit = 900,
    },
    Architecture = {
        BayWidth = 8,
        PlanningGrid = 4,
        WallBayHeight = 12,
        WallDepth = 1,
        WindowBayId = "M05",
        CornerPostId = "M03",
        AwningId = "M10",
        AwningSize = Vector3.new(8, 2, 4),
    },
}

return AssetContracts
