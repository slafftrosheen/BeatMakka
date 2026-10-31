-- Local rigid poses, never a musical clock or an animated gameplay collider.
return table.freeze({
    idle = { head = Vector3.new(0, 0, 0), left = 0, right = 0 },
    listen = { head = Vector3.new(-0.12, 0.18, 0), left = -0.12, right = 0.12 },
    chirp = { head = Vector3.new(-0.15, -0.15, 0.08), left = -0.2, right = 0.2 },
    celebrate = { head = Vector3.new(-0.1, 0, 0), left = -1.1, right = 1.1 },
    carry = { head = Vector3.new(0.15, 0, 0), left = -0.65, right = 0.65 },
})
