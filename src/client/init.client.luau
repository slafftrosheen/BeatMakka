local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local Workspace = game:GetService("Workspace")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Http = game:GetService("HttpService")
local Transport = require(Shared.MusicTransport)
local SchedulePlayback = require(script.SchedulePlayback)
local Catalog = require(Shared.SampleCatalog)
local PhysicalKeys = require(Shared.SamplerPadLayout).KeyboardKeys
local AudioEngine = require(script.AudioEngine)
local JamPlayback = require(script.JamPlayback)
local JamView = require(script.JamView)
local WorkshopView = require(script.DeviceGrooveboxView)
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
local interiorVisibility = require(script.QuayInteriorVisibility).new()
local neighbors = require(script.QuayNeighbors).new()
local skinnedNeighbors = require(script.SkinnedNeighbors).new()
local quayLife = require(script.QuayLife).new()
local quayGraphics = require(script.QuayGraphics).new()
local traffic = require(script.QuayTraffic).new()
local harborLife = require(script.QuayAmbientMotion).new()
local soundscape = require(script.QuaySoundscape).new()
local quayView = require(script.QuayDemoView).new()
local companionFollower = require(script.CompanionFollower).new()
local rewardRecognition = require(script.QuayRewardRecognition).new(companionFollower, neighbors)
local guideReaction = require(script.CompanionVoice).Reaction.Event:Connect(function()
    companionFollower:celebrate(1)
end)
local equippedPins = require(script.QuayEquippedPins).new()
local celebrations = require(script.QuayCelebrations).new(companionFollower, neighbors)
local command = network:WaitForChild("Command")
local stateEvent = network:WaitForChild("State")
local deltaEvent = network:WaitForChild("Delta")
local audio = AudioEngine.new(nil, { allowLocalPreview = true })
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

local listeningEpoch = -1
local appearance = DeviceAppearance.new()
local state
local streetPlayback = require(script.StreetMusicPlayback).new(function()
    return state
end)
local view
local lastClick = nil
local editorPlayback
local publicPlayback
local effects = true
local transportInterrupted = false
local feedback = WorldFeedback.new()
editorPlayback = SchedulePlayback.new(audio, function(event)
    feedback:pulse(event.pad, state and state.station)
    if view and view.pulsePad then
        view:pulsePad(event.absolutePad or event.pad, event.route)
    end
end)
publicPlayback = SchedulePlayback.new(listeningAudio, function(event)
    feedback:pulse(event.pad, "Courtyard")
end)
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
local promptService = game:GetService("ProximityPromptService")
local promptWasEnabled

local function ownsTouchControls()
    return state
        and (
            state.station
            or (state.concert and state.concert.open)
            or (state.stage and state.stage.open)
        )
end

local function updateTouchControls()
    if ownsTouchControls() then
        if promptWasEnabled == nil then
            promptWasEnabled = promptService.Enabled
            promptService.Enabled = false
        end
    elseif promptWasEnabled ~= nil then
        promptService.Enabled = promptWasEnabled
        promptWasEnabled = nil
    end
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
                schema = 3,
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
        elseif
            action == "Play"
            or action == "PlayStart"
            or action == "Record"
            or action == "Overdub"
            or action == "SongPlay"
            or action == "FinishedPlay"
        then
            transportInterrupted = false
        end
        command:FireServer(action, a, b)
    end
end

local function noteContext(pad)
    local m = state and state.music
    if not m or not m.program or not m.program.pads or type(pad) ~= "number" then
        return nil
    end
    local def = m.program.pads[tostring(pad)]
    return {
        projectId = m.projectId,
        sequenceId = m.sequenceId,
        trackId = m.trackId,
        absolutePad = pad,
        epoch = state.epoch,
        sampleId = def and def.sampleId,
        settings = def and def.settings,
        route = m.projectId .. ":" .. m.trackId .. ":" .. m.program.id .. ":" .. pad,
    }
end
local function tap(pad, captured)
    if not state or not state.ready or not state.station then
        return false
    end
    local context = captured or noteContext(pad)
    if not context then
        return false
    end
    if state.jam and state.jam.active then
        feedback:pulse(pad, state.station)
        return false
    end
    local submitted = false
    if
        not state.pattern.muted[pad] and Catalog.isLocallyPlayable(context.sampleId, state.unlocked)
    then
        submitted = audio:play(
            context.sampleId,
            context.settings,
            context.route,
            if state.music.fullLevel then 127 else state.music.velocity
        )
    end
    local submittedAt = os.clock()
    feedback:pulse(pad, state.station)
    if state.recording then
        local event = table.clone(context)
        event.at = Workspace:GetServerTimeNow()
        event.requestId = Http:GenerateGUID(false)
        send("Tap", pad, event)
    end
    return submitted, submittedAt
end

view = WorkshopView.new({
    command = send,
    tap = tap,
    noteContext = noteContext,
    sampleReady = function(id)
        local bank = audio.banks[id]
        return bank ~= nil and bank.state == "ready"
    end,
    signal = function()
        if audio.muted then
            return 0
        end
        local level = 0
        for _, bank in audio.banks do
            if bank.music then
                for _, voice in bank.voices do
                    if voice.IsPlaying then
                        level = math.max(level, voice.PlaybackLoudness / 500)
                    end
                end
            end
        end
        return math.clamp(level, 0, 1)
    end,
    preview = function(pad, settings)
        if state and state.station and state.pattern then
            local ctx = noteContext(pad)
            local played = Catalog.isLocallyPlayable(state.pattern.assignments[pad], state.unlocked)
                and audio:play(
                    state.pattern.assignments[pad],
                    settings,
                    ctx and ctx.route,
                    state.music.velocity
                )
            if not played then
                view:notice(
                    if audio.muted
                        then "Sound is muted. Unmute in Settings to audition."
                        elseif not Catalog.isLocallyPlayable(
                            state.pattern.assignments[pad],
                            state.unlocked
                        ) then "The harbour sounds are being prepared. You can edit and save drafts."
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
        celebrations:setEffects(value)
        rewardRecognition:setEffects(value)
        neighbors.enabled = value
        quayLife.enabled = value
        traffic.enabled = value
        harborLife.enabled = value
        companionFollower.enabled = value
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
    view:cancelInput(false)
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
    view:paintPads()
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
        listeningEpoch = if nextListening then nextListening.epoch else -1
    end
    playbackKind = nextKind
    state = nextState
    companionFollower:accept(nextState)
    rewardRecognition:accept(nextState)
    soundscape:accept(nextState)
    harborLife:accept(nextState)
    quayLife.progress = nextState.quay and nextState.quay.progress
    neighbors.state = nextState
    jamAudio:accept(state.jam, Workspace:GetServerTimeNow())
    local jamActive = state.jam and state.jam.active
    local soloMusic = state.station ~= nil and nextListening == nil and not jamActive
    audio.worldPreview = state.station == nil and nextListening == nil and not jamActive
    if soloMusic then
        audio:setSelection(state.music and state.music.program and state.music.program.pads or {})
        editorPlayback:accept(state.music and state.music.transport)
    else
        editorPlayback:stop()
        -- Warm the player's kit while exploring, before the first pad press.
        audio:setSelection(
            if nextListening == nil
                    and not jamActive
                    and state.music
                then state.music.program.pads
                else {}
        )
    end
    publicPlayback:accept(nextListening)
    if not state.playing then
        transportInterrupted = false
    end
    if state.station or state.listening or chapterPlayback then
        -- Do not let waterfront ambience bleed into an opted-in music session.
        audio:ambient(false) -- QuaySoundscape owns the neighborhood beds.
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
        view:cancelInput(false)
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
local deltaProjectId
local seenDeltaEvents = {}
local function mergeEvent(events, incoming)
    for index, existing in events do
        if existing.eventId == incoming.eventId then
            events[index] = incoming
            return false
        end
    end
    table.insert(events, incoming)
    return true
end
connect(deltaEvent.OnClientEvent, function(payload)
    local m = state and state.music
    if
        type(payload) ~= "table"
        or not m
        or payload.projectId ~= m.projectId
        or type(payload.projectRevision) ~= "number"
        or type(m.projectRevision) ~= "number"
        or payload.projectRevision < m.projectRevision
    then
        return
    end
    if deltaProjectId ~= m.projectId then
        deltaProjectId = m.projectId
        table.clear(seenDeltaEvents)
    end
    local sequenceAdds = {}
    local knownRevisions = {}
    for _, sequence in m.library and m.library.sequences or {} do
        knownRevisions[sequence.id] = sequence.revision
    end
    for _, detail in payload.events or {} do
        if
            detail.transportEpoch ~= nil
            and (not m.transport or detail.transportEpoch ~= m.transport.epoch)
        then
            continue
        end
        local event = detail.event
        if type(event) == "table" and type(event.eventId) == "string" then
            local key = tostring(detail.sequenceId)
                .. ":"
                .. tostring(detail.trackId)
                .. ":"
                .. event.eventId
            local first = not seenDeltaEvents[key]
            seenDeltaEvents[key] = true
            if detail.sequenceId == m.sequenceId then
                local events = m.sequence.trackEvents[detail.trackId] or {}
                m.sequence.trackEvents[detail.trackId] = events
                local added = mergeEvent(events, event)
                table.sort(events, function(a, b)
                    return if a.tick == b.tick then a.eventId < b.eventId else a.tick < b.tick
                end)
                if added then
                    sequenceAdds[detail.sequenceId] = (sequenceAdds[detail.sequenceId] or 0) + 1
                end
                if detail.trackId == m.trackId and state.pattern and state.pattern.rows then
                    local localTick = event.tick - (m.bar - 1) * 3840
                    local row = state.pattern.rows[event.pad]
                    if row and localTick >= 0 and localTick < 3840 then
                        row[math.floor(localTick / 240) + 1] = true
                    end
                end
            elseif
                first
                and (
                        payload.sequenceRevisions
                            and payload.sequenceRevisions[detail.sequenceId]
                        or 0
                    )
                    > (knownRevisions[detail.sequenceId] or 0)
            then
                sequenceAdds[detail.sequenceId] = (sequenceAdds[detail.sequenceId] or 0) + 1
            end
            local transport = m.transport
            local playback = detail.playbackEvent
            if
                transport
                and transport.schedule
                and transport.ref
                and transport.ref.kind == "sequence"
                and transport.ref.id == detail.sequenceId
                and type(playback) == "table"
                and playback.ready == true
                and Catalog.isLocallyPlayable(playback.sampleId, state.unlocked)
            then
                local schedule = transport.schedule
                if mergeEvent(schedule.events, playback) then
                    schedule.expandedEvents = (schedule.expandedEvents or 0) + 1
                end
                table.sort(schedule.events, function(a, b)
                    return if a.at == b.at then a.eventId < b.eventId else a.at < b.at
                end)
            end
        end
    end
    m.projectRevision = payload.projectRevision
    local sequenceRevisions, draftRevisions =
        payload.sequenceRevisions or {}, payload.draftRevisions or {}
    if m.sequence then
        m.sequence.revision = sequenceRevisions[m.sequenceId] or m.sequence.revision
    end
    if m.draft then
        m.draft.revision = draftRevisions[m.draftId] or m.draft.revision
    end
    if m.library then
        m.library.revision = payload.projectRevision
        for _, sequence in m.library.sequences or {} do
            sequence.revision = sequenceRevisions[sequence.id] or sequence.revision
            sequence.events = (sequence.events or 0) + (sequenceAdds[sequence.id] or 0)
        end
        for _, draft in m.library.drafts or {} do
            draft.revision = draftRevisions[draft.id] or draft.revision
        end
    end
    if m.transport and m.transport.schedule and m.transport.schedule.source then
        local source = m.transport.schedule.source
        if source.kind == "sequence" then
            source.revision = sequenceRevisions[source.id] or source.revision
        end
        source.projectRevision = payload.projectRevision
    end
    state.dirty = true
    state.editVersion = payload.editVersion or state.editVersion
    view:update(state)
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
    table.insert(keys, Enum.KeyCode[PhysicalKeys[pad]])
end
local padByKey = {}
for pad = 1, 16 do
    padByKey[Enum.KeyCode[PhysicalKeys[pad]]] = pad
end
-- Read physical pad keys directly. Core proximity bindings can consume E before
-- a context action sees it, even while its matching world prompt is hidden.
-- The context action still sinks movement keys while the instrument owns input.
connect(UserInputService.InputBegan, function(input)
    local pad = padByKey[input.KeyCode]
    if
        pad
        and not UserInputService:GetFocusedTextBox()
        and state
        and state.station
        and not (state.jam and state.jam.open)
        and not view:hasModal()
    then
        view:beginPad(pad, input)
    end
end)
connect(UserInputService.InputEnded, function(input)
    if padByKey[input.KeyCode] then
        view.padInput:finish(input)
    end
end)
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
    if view.hasModal and view:hasModal() then
        if inputState == Enum.UserInputState.Begin and input.KeyCode == Enum.KeyCode.Escape then
            view:closeModal()
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
    end
    return Enum.ContextActionResult.Sink
end, false, Enum.ContextActionPriority.High.Value + 1000, table.unpack(keys))

local refresh = 0
connect(RunService.Heartbeat, function(dt)
    jamAudio:step(Workspace:GetServerTimeNow())
    feedback:step()
    concertScene:step(effects)
    publicPlayback:step(Workspace:GetServerTimeNow())
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
        audio:ambient(false) -- Replaced by positional QuaySoundscape layers.
    end
    if state and state.playing and not transportInterrupted then
        editorPlayback:step(Workspace:GetServerTimeNow())
        view:tick()
        local m = state.music
        local t = m and m.transport
        if t and (m.metronome == "on" or (m.metronome == "record" and state.recording)) then
            local seconds = Workspace:GetServerTimeNow() - t.startedAt + (t.offset or 0)
            local initial = t.schedule and t.schedule.sections and t.schedule.sections[1]
            local initialBpm = initial and initial.bpm or m.sequence.bpm
            local beat = math.floor(seconds * initialBpm / 60)
            if seconds >= 0 and t.schedule and t.schedule.duration > 0 then
                local position = if t.loop
                    then seconds % t.schedule.duration
                    else math.min(seconds, t.schedule.duration)
                local cursor = Transport.cursor(t.schedule, position)
                beat = math.floor((cursor.tick or 0) / 960)
                if t.loop then
                    beat += math.floor(seconds / t.schedule.duration) * (t.schedule.totalBars or 0) * 4
                end
            end
            local clickKey = tostring(t.epoch) .. ":" .. beat
            if clickKey ~= lastClick then
                lastClick = clickKey
                if
                    (seconds >= 0 and (t.loop or not t.schedule or seconds < t.schedule.duration))
                    or (seconds < 0 and m.countIn and beat >= -4)
                then
                    audio:click()
                end
            end
        end
    end
end)

script.Destroying:Connect(function()
    interiorVisibility:destroy()
    localMaterials:destroy()
    streetPlayback:destroy()
    neighbors:destroy()
    quayLife:destroy()
    quayGraphics:destroy()
    traffic:destroy()
    harborLife:destroy()
    soundscape:destroy()
    celebrations:destroy()
    skinnedNeighbors:destroy()
    quayView:destroy()
    rewardRecognition:destroy()
    guideReaction:Disconnect()
    companionFollower:destroy()
    equippedPins:destroy()
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
    editorPlayback:stop()
    publicPlayback:stop()
    audio:destroy()
    listeningAudio:destroy()
    jamAudio:destroy()
    appearance:destroy()
    view.sampleEditor:destroy()
    view.screen:Destroy()
end)
