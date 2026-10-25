local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local Workspace = game:GetService("Workspace")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Pattern = require(Shared.Pattern)
local Catalog = require(Shared.SampleCatalog)
local AudioEngine = require(script.AudioEngine)
local JamPlayback = require(script.JamPlayback)
local JamView = require(script.JamView)
local WorkshopView = require(script.WorkshopView)
local Restoration = require(script.Restoration)
local DeviceAppearance = require(script.DeviceAppearance)
local ListeningView = require(script.ListeningView)
local StageView = require(script.StageView)
local ConcertView = require(script.ConcertView)
local ConcertScene = require(script.ConcertScene)
local canSend = require(script.CommandPolicy)
local WorldFeedback = require(script.WorldFeedback)
local GuiFactory = require(script.GuiFactory)
local network = ReplicatedStorage:WaitForChild("MusicNetwork", 120)
assert(network, "Needle Quay did not finish loading")
local localMaterials = require(script.LocalMaterials).new()
local neighbors = require(script.QuayNeighbors).new()
local skinnedNeighbors = require(script.SkinnedNeighbors).new()
local quayLife = require(script.QuayLife).new()
local quayView = require(script.QuayDemoView).new()
local command = network:WaitForChild("Command")
local stateEvent = network:WaitForChild("State")
local audio = AudioEngine.new()
local listeningAudio =
    AudioEngine.new("CourtyardListening", { musicOnly = true, strictSelection = true })
local jamAudio = JamPlayback.new()
local jamView
local listeningView
local stageView
local updateListeningUi
local concertView
local concertScene = ConcertScene.new()
local playbackKind
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

local function ownsTouchControls()
    return state
        and (
            state.station
            or (state.concert and state.concert.open)
            or (state.stage and state.stage.open)
        )
end

local function updateTouchControls()
    local current = playerGui:FindFirstChild("TouchGui")
    if ownsTouchControls() and current and current:IsA("ScreenGui") then
        if touchGui ~= current then
            if touchEnabledConnection then
                touchEnabledConnection:Disconnect()
            end
            touchGui = current
            touchWasEnabled = current.Enabled
            touchEnabledConnection = current:GetPropertyChangedSignal("Enabled"):Connect(function()
                if ownsTouchControls() and current.Enabled then
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
    if canSend(state, action) then
        if action == "JamJoin" or action == "JamPublish" or action == "JamTempo" then
            local jam = state and state.jam
            if not jam then
                return
            end
            a = {
                generation = jam.generation,
                revision = jam.revision,
                at = Workspace:GetServerTimeNow(),
                value = if action == "JamTempo" and jam.session
                    then math.clamp(jam.session.bpm + (a or 0), 60, 180)
                    else nil,
            }
        end
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
        if state.jam and state.jam.active then
            feedback:pulse(pad, state.station)
            return false
        end
        local submitted = false
        local hitAt = Workspace:GetServerTimeNow()
        if not state.pattern.muted[pad] then
            submitted = audio:play(
                state.pattern.assignments[pad],
                state.pattern.sounds and state.pattern.sounds[pad],
                pad
            )
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
    preview = function(pad, settings)
        if state and state.station and state.pattern then
            local played = audio:play(state.pattern.assignments[pad], settings, pad)
            if not played then
                view:notice(
                    if audio.muted
                        then "Sound is muted. Unmute in Settings to audition."
                        else "This sample is still loading. Try audition again in a moment."
                )
            end
            return played
        end
        return false
    end,
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
        jamAudio:setMuted(value)
        if jamView and state then
            jamView:update(state.jam, value)
        end
        if state then
            if updateListeningUi then
                updateListeningUi()
            end
        end
    end,
    effects = function(value)
        effects = value
        neighbors.enabled = value
        quayLife.enabled = value
        quayView:setEffects(value)
        feedback:setEnabled(value)
        if state then
            Restoration.update(state.restoration, effects, state.neighborhood)
        end
    end,
})
connect(UserInputService.WindowFocusReleased, function()
    view:cancelInput(true)
    if state and state.concert and state.concert.open then
        send("ChapterClose")
    end
    if state and (state.listening or (state.stage and state.stage.open)) then
        send("StageClose")
    end
    if state and state.jam and (state.jam.active or state.jam.open) then
        send("JamLeave")
    end
end)
connect(UserInputService.TextBoxFocused, function()
    view:cancelInput(true)
end)
listeningView = ListeningView.new(view.screen, function()
    send("LeaveListening")
end, function()
    view:setMuted(not view.muted)
end)
stageView = StageView.new(view.screen, send, function()
    view:setMuted(not view.muted)
end)
jamView = JamView.new(view.screen, send, function()
    view:setMuted(not view.muted)
end)
updateListeningUi = function(notice)
    if not state then
        return
    end
    local boardOpen = state.stage and state.stage.open
    listeningView:update(
        if boardOpen then nil else state.listening,
        if listeningAudio.muted
            then "MUTED / Sound control restores audio."
            else listeningAudio:status(),
        view.muted
    )
    stageView:update(state.stage, view.muted, notice, listeningAudio:status())
end
concertView = ConcertView.new(view.screen, send, function()
    view:setMuted(not view.muted)
end)
connect(listeningAudio.Changed.Event, function()
    if state then
        updateListeningUi()
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
    local chapterPlayback = nextState.concert and nextState.concert.playback
    local nextListening = chapterPlayback or nextState.listening
    local nextKind = if chapterPlayback then "chapter" else "listening"
    if not nextListening or nextListening.epoch ~= listeningEpoch or playbackKind ~= nextKind then
        listeningAudio:stop()
        listeningAbsolute = -1
        listeningEpoch = if nextListening then nextListening.epoch else -1
    end
    playbackKind = nextKind
    state = nextState
    quayLife.progress = nextState.quay and nextState.quay.progress
    jamAudio:accept(state.jam, Workspace:GetServerTimeNow())
    audio:setSelection(state.pattern.assignments)
    listeningAudio:setSelection(if nextListening then nextListening.pattern.assignments else {})
    if not state.playing then
        transportInterrupted = false
    end
    if state.station or state.listening or chapterPlayback then
        -- Do not let waterfront ambience bleed into an opted-in music session.
        audio:ambient(false)
    end
    feedback:update(state)
    updateTouchControls()
    concertView:update(
        state.concert,
        state.saveMode,
        view.muted,
        state.notice,
        state.saving,
        state.dirty
    )
    view:update(state)
    if state.jam and state.jam.open then
        view.panel.Visible = false
    end
    jamView:update(state.jam, view.muted, state.notice)
    concertScene:update(state.concert)
    updateListeningUi(state.notice)
    view.audioStatus.Text = audio:status()
    Restoration.update(state.restoration, effects, state.neighborhood)
    appearance:apply(state)
    view.appearanceStatus.Text = appearance.status or ""
    if state.preview and not (state.jam and state.jam.active) then
        local sample = Catalog.ById[state.preview]
        if sample and sample.discovery then
            feedback:discovery(sample.discovery)
            audio:play("ui_collect")
        end
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
    Enum.KeyCode.J,
    Enum.KeyCode.ButtonR2,
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
    if state.jam and state.jam.open then
        if
            inputState == Enum.UserInputState.Begin
            and (input.KeyCode == Enum.KeyCode.J or input.KeyCode == Enum.KeyCode.ButtonR2)
        then
            send("JamHide")
            return Enum.ContextActionResult.Sink
        end
        if
            inputState == Enum.UserInputState.Begin
            and (input.KeyCode == Enum.KeyCode.ButtonB or input.KeyCode == Enum.KeyCode.Escape)
        then
            send("JamHide")
            return Enum.ContextActionResult.Sink
        end
        return Enum.ContextActionResult.Pass
    end
    if inputState ~= Enum.UserInputState.Begin then
        view.padInput:finish(input)
        return Enum.ContextActionResult.Sink
    end
    if input.KeyCode == Enum.KeyCode.J or input.KeyCode == Enum.KeyCode.ButtonR2 then
        send("JamOpen")
    elseif input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonX then
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
    jamAudio:step(Workspace:GetServerTimeNow())
    feedback:step()
    concertScene:step(effects)
    local session = state and ((state.concert and state.concert.playback) or state.listening)
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
                        listeningAudio:play(
                            session.pattern.assignments[pad],
                            session.pattern.sounds and session.pattern.sounds[pad],
                            pad
                        )
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
            jamView:update(state.jam, view.muted)
            stageView:update(state.stage, view.muted, nil, listeningAudio:status())
            concertView:update(
                state.concert,
                state.saveMode,
                view.muted,
                nil,
                state.saving,
                state.dirty
            )
        end
        if state then
            Restoration.update(state.restoration, effects, state.neighborhood)
        end
        if state then
            appearance:apply(state)
            view.appearanceStatus.Text = appearance.status or ""
        end
        local character = game:GetService("Players").LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        audio:ambient(
            root ~= nil
                and ((root.Position.X > 220 and root.Position.Z > 65) or (root.Position.X < 220 and root.Position.Z < -20))
                and (
                    not state
                    or (
                        not state.station
                        and not state.listening
                        and not (state.concert and state.concert.playback)
                    )
                )
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
                    audio:play(
                        state.pattern.assignments[pad],
                        state.pattern.sounds and state.pattern.sounds[pad],
                        pad
                    )
                    feedback:pulse(pad, state.station)
                end
            end
        end
        view:playhead(step)
    end
end)

script.Destroying:Connect(function()
    localMaterials:destroy()
    neighbors:destroy()
    quayLife:destroy()
    skinnedNeighbors:destroy()
    quayView:destroy()
    view:cancelInput(true)
    send("Release")
    send("ChapterClose")
    send("StageClose")
    concertScene:destroy()
    for _, connection in connections do
        connection:Disconnect()
    end
    table.clear(connections)
    ContextActionService:UnbindAction("SamplerKeyboard")
    state = nil
    updateTouchControls()
    audio:destroy()
    listeningAudio:destroy()
    jamAudio:destroy()
    appearance:destroy()
    view.sampleEditor:destroy()
    view.screen:Destroy()
end)
