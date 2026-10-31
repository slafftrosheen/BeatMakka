-- Presentation only. No connection to transport time, pattern edits or quest awards.
local Animation = {}
Animation.Clips = {
    "idle",
    "idle_listen",
    "walk",
    "run",
    "point",
    "kneel",
    "think",
    "celebrate",
    "wave",
    "music_bob",
}
function Animation.rotation(name, clip, time)
    local phase = time * (if clip == "run" then 9 elseif clip == "walk" then 5 else 2)
    local side = if name:sub(1, 4) == "Left" then 1 else -1
    if clip == "walk" or clip == "run" then
        if name:find("UpperLeg") then
            return CFrame.Angles(
                math.sin(phase) * side * (if clip == "run" then 0.5 else 0.3),
                0,
                0
            )
        end
        if name:find("LowerLeg") then
            return CFrame.Angles(-math.max(0, -math.sin(phase) * side) * 0.3, 0, 0)
        end
        if name:find("UpperArm") then
            return CFrame.Angles(-math.sin(phase) * side * 0.25, 0, 0)
        end
    elseif
        (clip == "point" or clip == "wave" or clip == "celebrate") and name == "RightUpperArm"
    then
        -- Local front is -Z: raising a downward arm forward requires positive X.
        return CFrame.Angles(1.2, 0, if clip == "point" then 0 else math.sin(phase * 2) * 0.2)
    elseif clip == "kneel" and name:find("LowerLeg") then
        return CFrame.Angles(-0.8, 0, 0)
    elseif clip == "think" and name == "LeftLowerArm" then
        return CFrame.Angles(1.4, 0, 0)
    elseif clip == "music_bob" and name == "Spine" then
        return CFrame.Angles(0, 0, math.sin(phase) * 0.08)
    elseif clip == "idle_listen" and name == "Head" then
        return CFrame.Angles(-0.12, math.sin(phase * 0.5) * 0.03, 0)
    elseif clip == "idle" and name == "Head" then
        return CFrame.Angles(0, math.sin(phase * 0.6) * 0.03, 0)
    end
    return CFrame.identity
end
return Animation
