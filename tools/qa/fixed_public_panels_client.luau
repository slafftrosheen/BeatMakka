-- Opt-in Studio Client UI-model/layout probe. All payloads below are crafted
-- fixtures, not claims about a saved song, server eligibility or actual partners.
-- Disposable hosts exercise geometry; callbacks log locally and never use remotes.
local Player = game.Players.LocalPlayer
local Client = Player.PlayerScripts.Client
local Jam = require(Client.JamView)
local Concert = require(Client.ConcertView)
local GuiService = game:GetService("GuiService")
local Run = game:GetService("RunService")
local TextService = game:GetService("TextService")
local screen = Instance.new("ScreenGui")
screen.Name = "FixedPublicPanelsPrivateProbe"
screen.IgnoreGuiInset, screen.ResetOnSpawn = true, false
screen.Parent = Player.PlayerGui
local oldFocus = GuiService.SelectedObject
local callbacks, results, views, hosts = {}, {}, {}, {}
local function record(action, a, b)
    table.insert(callbacks, { action = action, a = a, b = b })
end
local function check(name, action)
    local ok, detail = xpcall(action, debug.traceback)
    table.insert(results, { name = name, passed = ok, detail = tostring(detail or "ok") })
end
local function countObjects()
    local count = 0
    for _, object in screen:GetDescendants() do
        if object:IsA("GuiObject") then
            count += 1
        end
    end
    return count
end
local function settle()
    Run.RenderStepped:Wait()
    Run.RenderStepped:Wait()
end
local function bounded(object, parent, minimum)
    local p, s, q, t =
        object.AbsolutePosition, object.AbsoluteSize, parent.AbsolutePosition, parent.AbsoluteSize
    assert(s.X >= minimum and s.Y >= minimum, object.Name .. " has an undersized target")
    assert(
        p.X >= q.X - 1
            and p.Y >= q.Y - 1
            and p.X + s.X <= q.X + t.X + 1
            and p.Y + s.Y <= q.Y + t.Y + 1,
        object.Name .. " escapes its panel"
    )
end
local function createHost(name)
    local host = Instance.new("Frame")
    host.Name, host.BackgroundTransparency = name, 1
    host.Size, host.Parent = UDim2.fromOffset(1539, 695), screen
    return host
end
hosts.jam, hosts.concert = createHost("PrivateJamHost"), createHost("PrivateConcertHost")
views.jam = Jam.new(hosts.jam, record, function()
    record("LOCAL_MUTE")
end)
views.concert = Concert.new(hosts.concert, record, function()
    record("LOCAL_MUTE")
end)
settle()
local viewport = screen.AbsoluteSize
local baseline = countObjects()
local created = 0
local added = screen.DescendantAdded:Connect(function(object)
    if object:IsA("GuiObject") then
        created += 1
    end
end)
local readySong = {
    id = "private_ui_song",
    title = "Private UI Song",
    revision = 1,
    duration = 32,
    ready = true,
    localOnly = true,
}
local idleConcert = {
    open = true,
    eligible = true,
    songs = { readySong },
    selectedFinishedSongId = readySong.id,
    position = 0,
    duration = 0,
    progress = 0,
    hint = "Choose a saved revision.",
}
local activeConcert = table.clone(idleConcert)
activeConcert.finishedSongId, activeConcert.title, activeConcert.revision =
    readySong.id, readySong.title, 1
activeConcert.position, activeConcert.duration, activeConcert.progress = 8, 32, 0.25
activeConcert.section, activeConcert.cue = { name = "Private section", repetition = 2 }, "Rhythm"
local idleJam = { open = true, active = false }
local activeJam = {
    open = true,
    active = true,
    conductor = true,
    session = {
        bpm = 120,
        tracks = {
            ["1"] = { name = "Private player one", snapshot = { title = "Private rhythm" } },
            ["2"] = { name = "Private player two", snapshot = { title = "Private melody" } },
        },
        pending = { ["1"] = { fixture = true } },
        tempo = { bpm = 121 },
    },
}
check("Concert crafted empty/ready/active/paused/ended/closed states", function()
    local view = views.concert
    view:update(
        { open = true, eligible = false, songs = {}, hint = "Private empty fixture" },
        "session",
        false,
        nil,
        false,
        false
    )
    assert(
        not view.start.Active and not view.select.Active and not view.pause.Visible,
        "Empty state enabled performance"
    )
    view:update(idleConcert, "session", false, "PRIVATE SAVE NOTICE", false, true)
    assert(
        view.start.Active and view.select.Active and view.songTitle.Text == readySong.title,
        "Ready selected revision was not represented"
    )
    assert(view.noticeLine.Text:find("PRIVATE SAVE NOTICE", 1, true), "Save notice disappeared")
    view:update(activeConcert, "session", false, nil, true, true)
    assert(
        view.pause.Visible and view.pause.Active and not view.save.Active,
        "Active/saving controls are incorrect"
    )
    assert(
        view.clock.Text == "00:08" and view.section.Text:find("Private section", 1, true),
        "Position/section labels are missing"
    )
    local paused = table.clone(activeConcert)
    paused.paused = true
    view:update(paused, "session", true, nil, false, false)
    assert(
        view.pause.Legend.Text == "RESUME" and view.mute.Text:find("MUTED", 1, true),
        "Pause/mute labels are incorrect"
    )
    local ended = table.clone(activeConcert)
    ended.ended = true
    view:update(ended, "session", false, nil, false, false)
    assert(not view.pause.Visible, "Ended performance kept pause enabled")
    view:update(nil, "session", false)
    assert(not view.panel.Visible, "Nil concert state did not close")
end)
check("Jam crafted idle/active/conductor handoff/closed states", function()
    local view = views.jam
    view:update(idleJam, false)
    assert(
        view.join.Visible and not view.publish.Visible and GuiService.SelectedObject == view.join,
        "Idle join/focus is incorrect"
    )
    view:update(activeJam, false, "PRIVATE JAM NOTICE")
    assert(
        view.publish.Visible and view.down.Visible and view.up.Visible and view.leave.Visible,
        "Conductor controls are missing"
    )
    assert(
        view.channels[1].root:GetAttribute("Pending")
            and view.channels[1].source.Text == "Private rhythm",
        "Pinned/pending channel labels are incorrect"
    )
    assert(
        view.tempoLabel:GetAttribute("BPM") == 120 and view.noticeLine.Text == "PRIVATE JAM NOTICE",
        "Tempo/notice labels are missing"
    )
    GuiService.SelectedObject = view.up
    local partner = table.clone(activeJam)
    partner.conductor = false
    view:update(partner, true)
    assert(
        not view.up.Visible and not view.down.Visible and GuiService.SelectedObject == view.publish,
        "Conductor handoff focus is incorrect"
    )
    assert(view.mute.Text:find("MUTED", 1, true), "Mute label is incorrect")
    view:update(nil, false)
    assert(not view.panel.Visible, "Nil jam state did not close")
end)
for _, size in { Vector2.new(1539, 695), Vector2.new(627, 252), Vector2.new(401, 720) } do
    for name, view in views do
        check(
            string.format(
                "%s fixed geometry and stable widgets at %dx%d host",
                name,
                size.X,
                size.Y
            ),
            function()
                hosts[name].Size = UDim2.fromOffset(size.X, size.Y)
                view.page = if name == "jam" then "session" else "song"
                if name == "jam" then
                    view:update(activeJam, false)
                else
                    view:update(activeConcert, "session", false, nil, false, false)
                end
                settle()
                view:resize()
                settle()
                bounded(view.mute, view.panel, 44)
                bounded(view.close, view.panel, 44)
                for _, object in view.panel:GetDescendants() do
                    assert(not object:IsA("ScrollingFrame"), "Scrolling surface remains")
                end
                for _ = 1, 8 do
                    if name == "jam" then
                        view:update(activeJam, false)
                    else
                        view:update(activeConcert, "session", false, nil, false, false)
                    end
                end
                assert(
                    countObjects() == baseline and created == 0,
                    "State update created or replaced GUI objects"
                )
                return string.format(
                    "Panel %.0fx%.0f; footer targets >=44; GUI count %d",
                    view.panel.AbsoluteSize.X,
                    view.panel.AbsoluteSize.Y,
                    baseline
                )
            end
        )
        check(
            string.format("%s bounded INFO pagination at %dx%d host", name, size.X, size.Y),
            function()
                view.page, view.infoPageIndex = "info", 1
                if name == "jam" then
                    view:paint()
                else
                    view:refresh()
                end
                settle()
                local pageCount = tonumber(view.infoCounter.Text:match("/ (%d+)"))
                assert(pageCount and pageCount >= 1 and pageCount < 250, "Invalid INFO page bounds")
                for index = 1, pageCount do
                    view.infoPageIndex = index
                    view:paintInfo()
                    local bounds = TextService:GetTextSize(
                        view.label.Text,
                        view.label.TextSize,
                        view.label.Font,
                        Vector2.new(view.label.AbsoluteSize.X, 100000)
                    )
                    assert(
                        bounds.Y <= view.label.AbsoluteSize.Y + 1,
                        "INFO page exceeds its fixed label height"
                    )
                    assert(view.label.Text ~= "", "INFO page is empty")
                end
                assert(not view.infoNext.Active, "INFO next page is unbounded")
                assert(
                    countObjects() == baseline and created == 0,
                    "INFO paging created GUI objects"
                )
                return tostring(pageCount) .. " readable fixed pages"
            end
        )
    end
end
check("UI-model updates have no command, storage or audio side effect", function()
    assert(#callbacks == 0, "A state update invoked an action callback")
    return "Callbacks were local log functions; no action was synthesized"
end)
added:Disconnect()
screen:Destroy()
GuiService.SelectedObject = if oldFocus and oldFocus.Parent then oldFocus else nil
local passed = 0
for _, result in results do
    passed += if result.passed then 1 else 0
end
return {
    passed = passed,
    failed = #results - passed,
    checks = results,
    actualViewport = { x = viewport.X, y = viewport.Y },
    uiObjects = baseline,
    createdAcrossUpdates = created,
    callbackCalls = #callbacks,
    scope = "Crafted UI states and disposable fixed-size host geometry only; no server, acoustic, physical-input or multiplayer acceptance",
}
