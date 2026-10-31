-- Personal session mix. Does not modify saved compositions or server transport.
local Mix = {
    music = 1,
    ambience = 0.65,
    cues = 0.7,
    voice = 0.8,
    subtitles = true,
    muted = false,
    voiceActive = false,
    rewardVoiceActive = false,
    commissionVoiceActive = false,
    Changed = Instance.new("BindableEvent"),
}
function Mix.set(channel, value)
    if
        channel ~= "music"
        and channel ~= "ambience"
        and channel ~= "cues"
        and channel ~= "voice"
    then
        return
    end
    Mix[channel] = math.clamp(value, 0, 1)
    Mix.Changed:Fire()
end
return Mix
