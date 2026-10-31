-- Studio Client probe: checks all 64 native local sounds; requires installed package.
-- Uses disposable audio engines, without editing/saving the active composition.
local Client = game.Players.LocalPlayer.PlayerScripts.Client
local AudioEngine = require(Client.AudioEngine)
local Catalog = require(game.ReplicatedStorage.Shared.SampleCatalog)
local Waves = require(game.ReplicatedStorage.Shared.SampleWaveforms)
local results = {}
local private = AudioEngine.new(
    "PreviewRegressionPersonal",
    { musicOnly = true, strictSelection = true, allowLocalPreview = true }
)
local public =
    AudioEngine.new("PreviewRegressionPublic", { musicOnly = true, strictSelection = true })
local selected = {}
for pad = 1, 64 do
    selected[pad] = Catalog.List[pad].id
end
local function check(name, action)
    local ok, detail = xpcall(action, debug.traceback)
    table.insert(results, { name = name, passed = ok, detail = tostring(detail or "ok") })
end
check("local public-performance engine loads and starts the same pending local sources", function()
    public:setSelection(selected)
    local deadline = os.clock() + 12
    repeat
        local ready = true
        for _, id in selected do
            ready = ready and public.banks[id] ~= nil and public.banks[id].state == "ready"
        end
        if ready then
            break
        end
        task.wait(0.1)
    until os.clock() >= deadline
    assert(public:diagnostics().engineMusicVoices == 64, "Local public sources were not prepared")
    local id = Catalog.List[2].id
    assert(public.banks[id].state == "ready", "Local public source failed to load")
    assert(public:play(id), "Local public engine rejected technically ready source")
    local playing = false
    for _, voice in public.banks[id].voices do
        playing = playing or voice.IsPlaying
    end
    assert(playing, "Local public source never started a Sound voice")
    assert(not Catalog.isReady(id), "Public playback invented approval")
    public:stop()
    return "Studio public performance starts local audio; strict admission stays false"
end)
check("personal engine loads 64 native candidates and starts their actual Sound voices", function()
    private:setSelection(selected)
    local deadline = os.clock() + 12
    repeat
        local ready = true
        for _, id in selected do
            ready = ready and private.banks[id] ~= nil and private.banks[id].state == "ready"
        end
        if ready then
            break
        end
        task.wait(0.1)
    until os.clock() >= deadline
    for _, id in selected do
        local bank = private.banks[id]
        assert(bank and bank.state == "ready", id .. " failed to load")
        assert(bank.localPreview, "Private bank lost audition status")
        assert(
            bank.voices[1].SoundId == "rbxasset://needle-quay/preview-audio/" .. id .. ".wav",
            "Voice does not use installed native candidate"
        )
        assert(bank.voices[1].TimeLength > 0, "Loaded candidate has no duration")
        local wave = Waves[id]
        assert(wave and #wave.peaks == 64, "Real sample waveform is missing")
        assert(
            math.abs(wave.duration - bank.voices[1].TimeLength) < 0.001,
            "Waveform duration differs from actual Sound"
        )
        local peak = 0
        for _, value in wave.peaks do
            peak = math.max(peak, value)
        end
        assert(peak > 0, "Real sample waveform contains no signal")
        assert(private:play(id, nil, "preview_regression:" .. id, 100), id .. " did not start")
        local playing = false
        for _, voice in bank.voices do
            playing = playing or voice.IsPlaying
        end
        assert(playing, id .. " has no playing voice")
        task.wait(0.03)
        private:stop()
    end
    return "64 locally loaded Sound voices started; human listening approval remains pending"
end)
check("stopping transport retains the visible pad audition selection", function()
    local Playback = require(Client.SchedulePlayback)
    local before = private:diagnostics().engineMusicVoices
    local playback = Playback.new(private)
    playback:stop()
    assert(
        before == 64 and private:diagnostics().engineMusicVoices == before,
        "Transport stop cleared pad voices"
    )
    for _, id in selected do
        assert(private.selection[id], "Transport stop cleared a visible audition assignment")
    end
    return "Schedule selection cleared while 64 pad audition voices remain prepared"
end)
check("mute and stop suppress audition playback", function()
    private:setMuted(true)
    assert(not private:play(Catalog.List[2].id), "Muted private engine accepted playback")
    assert(private.group.Volume == 0, "Muted private group retains volume")
    private:setMuted(false)
    private:stop()
    for _, bank in private.banks do
        for _, voice in bank.voices do
            assert(not voice.IsPlaying, "Stop left an audition voice playing")
        end
    end
    return "Muted play rejected and every disposable voice stopped"
end)
private:destroy()
public:destroy()
local failures = 0
for _, result in results do
    if not result.passed then
        failures += 1
    end
end
return game:GetService("HttpService"):JSONEncode({
    scope = "studio_client_voice_state",
    human_listening_approval = false,
    failures = failures,
    results = results,
})
