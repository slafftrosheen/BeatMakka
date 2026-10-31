-- Supplemental placements; canonical building IDs/dimensions are unchanged.
return {
    buildings = {
        {
            id = "NQ-SCENIC-01",
            at = Vector3.new(-26, 0, -128),
            yaw = 180,
            label = "SWEETS & SMALL THINGS",
        },
        {
            id = "NQ-SCENIC-02",
            at = Vector3.new(115, 0, -130),
            yaw = 180,
            label = "SECOND SPIN / CLOTHES",
        },
        { id = "NQ-SCENIC-03", at = Vector3.new(205, 0, 10), yaw = 90, label = "QUAYSIDE SWEETS" },
    },
    traffic = {
        { id = "NQ-TRAFFIC-TAXI", z = -72, direction = 1, x = -180, speed = 13 },
        { id = "NQ-TRAFFIC-POST", z = -58, direction = -1, x = 140, speed = 11 },
        { id = "NQ-TRAFFIC-BUS", z = 58, direction = 1, x = -100, speed = 10 },
        { id = "NQ-TRAFFIC-TAXI", z = 72, direction = -1, x = 200, speed = 13 },
    },
    -- Artwork IDs and intended districts from the environment production register.
    graffiti = {
        { id = "GRA-01", building = "NQ-BLD-13", wall = "left", width = 10, height = 6 },
        { id = "GRA-02", building = "NQ-BLD-01", wall = "left", width = 8, height = 4 },
        { id = "GRA-03", building = "NQ-BLD-09", wall = "left", width = 5, height = 2.5 },
        { id = "GRA-04", at = Vector3.new(-55, 2.6, 146.2), yaw = 0, width = 12, height = 4 },
        { id = "GRA-05", at = Vector3.new(120, 2.6, 146.2), yaw = 0, width = 16, height = 5 },
        -- 05 has no readable clear panel; 04 is an open pavilion with no side wall.
        -- Use existing rear masonry, retaining artwork IDs and aspect ratios.
        { id = "GRA-06", building = "NQ-BLD-09", wall = "back", width = 7, height = 5 },
        { id = "GRA-07", building = "NQ-BLD-13", wall = "back", width = 10, height = 6 },
        { id = "GRA-08", building = "NQ-BLD-03", wall = "left", width = 3, height = 2.25 },
        { id = "GRA-09", building = "NQ-BLD-08", wall = "back", width = 1.6, height = 1.2 },
        { id = "GRA-10", building = "NQ-BLD-01", wall = "back", width = 8, height = 3.2 },
    },
}
