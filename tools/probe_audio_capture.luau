-- Non-recording capability inspection. No microphone, graph, playback or capture.
-- Roblox engine global is missing from this project's pinned Selene standard.
-- selene: allow(undefined_variable)
local engineVersion = version()
local result = {
    engineVersion = engineVersion,
    placeId = game.PlaceId,
    universeId = game.GameId,
    scope = "Edit, unparented and unwired; RecordAsync not called",
    microphoneCreated = false,
    audioCaptured = false,
}
local created, recorder = pcall(Instance.new, "AudioRecorder")
result.constructible = created
if created then
    result.methods = {}
    for _, name in { "CanRecordAsync", "GetTemporaryContent", "RecordAsync", "Stop", "Clear" } do
        local ok, value = pcall(function()
            return recorder[name]
        end)
        result.methods[name] = if ok then typeof(value) else tostring(value)
    end
    local ok, value = pcall(function()
        return recorder:CanRecordAsync()
    end)
    result.canRecordCallSucceeded = ok
    result.canRecordResult = if ok then value else tostring(value)
    recorder:Destroy()
else
    result.error = tostring(recorder)
end
return result
