local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Scheduler = require(script.Parent.SchedulePlayback)
local Field = require(script.Parent.QuayMusicField)
local Audio = require(script.Parent.AudioEngine)
local Mix = require(script.Parent.AudioMix)
local Playback = {}
function Playback.new(state)
    local audio = Audio.new("StreetSpeakers", { musicOnly = true, strictSelection = true })
    local current
    local scheduler = Scheduler.new(audio)
    local connection = RunService.Heartbeat:Connect(function()
        local s = state()
        local character = Players.LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local packet, distance
        if
            root
            and not Mix.muted
            and not (s and (s.station or s.listening or (s.concert and s.concert.playback)))
        then
            packet, distance = Field.nearest(root.Position, 48, nil, true)
        end
        if not packet then
            if current then
                scheduler:stop()
                audio:setSelection({})
            end
            current = nil
            return
        end
        if current ~= packet then
            scheduler:accept(packet.playback)
        end
        current = packet
        audio.volume = 0.5 * math.clamp((48 - distance) / 32, 0, 1)
        audio.applyMix()
        scheduler:step(workspace:GetServerTimeNow())
    end)
    return {
        destroy = function()
            connection:Disconnect()
            scheduler:stop()
            audio:destroy()
        end,
    }
end
return Playback
