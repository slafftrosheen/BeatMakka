local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local Workspace = game:GetService("Workspace")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Pattern = require(Shared.Pattern)
local Catalog = require(Shared.SampleCatalog)
local AudioEngine = require(script.AudioEngine)
local WorkshopView = require(script.WorkshopView)
local Restoration = require(script.Restoration)
local DeviceAppearance = require(script.DeviceAppearance)
local ListeningView = require(script.ListeningView)
local WorldFeedback = require(script.WorldFeedback)
local GuiFactory = require(script.GuiFactory)
local network = ReplicatedStorage:WaitForChild("MusicNetwork")
local command = network:WaitForChild("Command")
local stateEvent = network:WaitForChild("State")
local audio = AudioEngine.new()
local listeningAudio = AudioEngine.new("CourtyardListening", { musicOnly = true })
local listeningView
local listeningAbsolute = -1
local listeningEpoch = -1
local appearance = DeviceAppearance.new()
local state
local view
local lastAbsolute = -1
local epoch = -1
local effects = true
local transportInterrupted = false
local feedback = WorldFeedback.new()
local connections = {}
local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(connections, connection)
    return connection
end
connect(GuiFactory.Cue.Event, function(id)
    audio:play(id)
end)
local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local touchGui
local touchWasEnabled
local touchEnabledConnection

local function updateTouchControls()
    local current = playerGui:FindFirstChild("TouchGui")
    if state and state.station and current and current:IsA("ScreenGui") then
        if touchGui ~= current then
            if touchEnabledConnection then
                touchEnabledConnection:Disconnect()
            end
            touchGui = current
            touchWasEnabled = current.Enabled
            touchEnabledConnection = current:GetPropertyChangedSignal("Enabled"):Connect(function()
                if state and state.station and current.Enabled then
                    current.Enabled = false
                end
            end)
        end
        current.Enabled = false
    elseif touchGui then
        if touchEnabledConnection then
            touchEnabledConnection:Disconnect()
            touchEnabledConnection = nil
        end
        if touchGui.Parent then
            touchGui.Enabled = touchWasEnabled
        end
        touchGui = nil
        touchWasEnabled = nil
    end
end
connect(playerGui.ChildAdded, updateTouchControls)

local function send(action, a, b)
    if
        action == "Release"
        or action == "LeaveListening"
        or (state and state.ready and state.station)
    then
        if action == "Stop" or action == "Release" then
            transportInterrupted = true
            audio:stop()
        elseif action == "Play" or action == "Record" then
            transportInterrupted = false
        end
        command:FireServer(action, a, b)
    end
end

local function tap(pad)
    if state and state.ready and state.station then
        local submitted = false
        local hitAt = Workspace:GetServerTimeNow()
        if not state.pattern.muted[pad] then
            submitted = audio:play(state.pattern.assignments[pad])
        end
        local submittedAt = os.clock()
        feedback:pulse(pad, state.station)
        if state.recording then
            send("Tap", pad, { at = hitAt, epoch = state.epoch })
        end
        return submitted, submittedAt
    end
    return false
end

view = WorkshopView.new({
    command = send,
    tap = tap,
    interrupt = function()
        transportInterrupted = true
        audio:stop()
        -- Stop also covers a Play/Record command whose reply is still in flight.
        if state and state.ready and state.station then
            send("Stop")
        end
    end,
    mute = function(value)
        audio:setMuted(value)
        listeningAudio:setMuted(value)
        if state then
            listeningView:update(
                state.listening,
                if value then "MUTED / Sound control restores audio." else listeningAudio:status()
            )
        end
    end,
    effects = function(value)
        effects = value
        feedback:setEnabled(value)
        if state then
            Restoration.update(state.restoration, effects)
        end
    end,
})
connect(UserInputService.WindowFocusReleased, function()
    view:cancelInput(true)
end)
connect(UserInputService.TextBoxFocused, function()
    view:cancelInput(true)
end)
listeningView = ListeningView.new(view.screen, function()
    send("LeaveListening")
end)
connect(listeningAudio.Changed.Event, function()
    if state then
        listeningView:update(
            state.listening,
            if listeningAudio.muted
                then "MUTED / Sound control restores audio."
                else listeningAudio:status()
        )
    end
end)
view.audioStatus.Text = audio:status()
connect(audio.Changed.Event, function()
    view.audioStatus.Text = audio:status()
end)
connect(stateEvent.OnClientEvent, function(nextState)
    if
        state
        and ((state.playing and not nextState.playing) or (state.station and not nextState.station))
    then
        audio:stop()
    end
    local nextListening = nextState.listening
    if not nextListening or nextListening.epoch ~= listeningEpoch then
        listeningAudio:stop()
        listeningAbsolute = -1
        listeningEpoch = if nextListening then nextListening.epoch else -1
    end
    state = nextState
    audio:setSelection(state.pattern.assignments)
    listeningAudio:setSelection(if nextListening then nextListening.pattern.assignments else {})
    if not state.playing then
        transportInterrupted = false
    end
    if state.station or state.listening then
        -- Do not let waterfront ambience bleed into an opted-in music session.
        audio:ambient(false)
    end
    feedback:update(state)
    updateTouchControls()
    view:update(state)
    listeningView:update(
        state.listening,
        if listeningAudio.muted
            then "MUTED / Sound control restores audio."
            else listeningAudio:status()
    )
    view.audioStatus.Text = audio:status()
    Restoration.update(state.restoration, effects)
    appearance:apply(state)
    view.appearanceStatus.Text = appearance.status or ""
    if state.preview then
        local sample = Catalog.ById[state.preview]
        if sample and sample.discovery then
            feedback:discovery(sample.discovery)
        end
        audio:play("ui_collect")
        if not audio:play(state.preview) then
            view:notice(
                if audio.muted
                    then "Sample is in your collection. Sound is muted."
                    else "Sample is in your collection. Audio preview is unavailable."
            )
        end
    end
    if state.cue then
        audio:play(state.cue)
    end
end)
command:FireServer("Hello")

local keys = {
    Enum.KeyCode.Space,
    Enum.KeyCode.T,
    Enum.KeyCode.ButtonX,
    Enum.KeyCode.ButtonY,
    Enum.KeyCode.ButtonB,
    Enum.KeyCode.Escape,
}
for pad = 1, 16 do
    table.insert(keys, Enum.KeyCode[Catalog.List[pad].key])
end
ContextActionService:BindActionAtPriority("SamplerKeyboard", function(_, inputState, input)
    if UserInputService:GetFocusedTextBox() or not state or not state.station then
        return Enum.ContextActionResult.Pass
    end
    if inputState ~= Enum.UserInputState.Begin then
        view.padInput:finish(input)
        return Enum.ContextActionResult.Sink
    end
    if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonX then
        send("Play")
    elseif input.KeyCode == Enum.KeyCode.T or input.KeyCode == Enum.KeyCode.ButtonY then
        send("Record")
    elseif input.KeyCode == Enum.KeyCode.ButtonB or input.KeyCode == Enum.KeyCode.Escape then
        send("Release")
    else
        for pad = 1, 16 do
            if input.KeyCode == Enum.KeyCode[Catalog.List[pad].key] then
                view:beginPad(pad, input)
                break
            end
        end
    end
    return Enum.ContextActionResult.Sink
end, false, Enum.ContextActionPriority.High.Value, table.unpack(keys))

local refresh = 0
connect(RunService.Heartbeat, function(dt)
    feedback:step()
    local session = state and state.listening
    if session then
        local now = Workspace:GetServerTimeNow()
        local absolute, step = Pattern.position(session.pattern.bpm, session.startedAt, now)
        if absolute >= 0 and absolute ~= listeningAbsolute then
            listeningAbsolute = absolute
            local duration = Pattern.stepDuration(session.pattern.bpm)
            local lateness = now - session.startedAt - absolute * duration
            if lateness < math.min(0.08, duration * 0.8) then
                for pad = 1, Pattern.Pads do
                    if session.pattern.rows[pad][step] and not session.pattern.muted[pad] then
                        listeningAudio:play(session.pattern.assignments[pad])
                        feedback:pulse(pad, "Courtyard")
                    end
                end
            end
        end
    end
    refresh += dt
    if refresh > 1 then
        refresh = 0
        view:tick()
        listeningView:tick()
        if state then
            Restoration.update(state.restoration, effects)
        end
        if state then
            appearance:apply(state)
            view.appearanceStatus.Text = appearance.status or ""
        end
        local character = game:GetService("Players").LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        audio:ambient(
            root ~= nil
                and root.Position.Z < -20
                and (not state or (not state.station and not state.listening))
        )
    end
    if not state or not state.playing or transportInterrupted then
        lastAbsolute = -1
        return
    end
    if epoch ~= state.epoch then
        epoch = state.epoch
        lastAbsolute = -1
    end
    local now = Workspace:GetServerTimeNow()
    local absolute, step = Pattern.position(state.pattern.bpm, state.startedAt, now)
    if absolute < 0 then
        return
    end
    if absolute ~= lastAbsolute then
        lastAbsolute = absolute
        -- On a stalled frame, skip old ticks rather than playing a burst of late notes.
        local lateness = now - state.startedAt - absolute * Pattern.stepDuration(state.pattern.bpm)
        if lateness < math.min(0.08, Pattern.stepDuration(state.pattern.bpm) * 0.8) then
            for pad = 1, 16 do
                if state.pattern.rows[pad][step] and not state.pattern.muted[pad] then
                    audio:play(state.pattern.assignments[pad])
                    feedback:pulse(pad, state.station)
                end
            end
        end
        view:playhead(step)
    end
end)

script.Destroying:Connect(function()
    view:cancelInput(true)
    send("Release")
    for _, connection in connections do
        connection:Disconnect()
    end
    table.clear(connections)
    ContextActionService:UnbindAction("SamplerKeyboard")
    state = nil
    updateTouchControls()
    audio:destroy()
    listeningAudio:destroy()
    appearance:destroy()
    view.screen:Destroy()
end)
