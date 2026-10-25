-- Explicit local Studio two-client integration. Excluded from the game build.
local test = game:GetService("StudioTestService")
local args = test:GetTestArgs()
if type(args) ~= "table" or args.suite ~= "JamAcceptance" then
    return
end
local control = Instance.new("Folder")
control.Name = "DocsQaControl"
for _, name in { "Ready", "Report", "Drive" } do
    local e = Instance.new("RemoteEvent")
    e.Name = name
    e.Parent = control
end
local ready, reports, checks, measurements = {}, {}, {}, {}
local phase, sequence, ended = "startup", 0, false
control.Ready.OnServerEvent:Connect(function(p)
    ready[p] = true
end)
control.Report.OnServerEvent:Connect(function(p, n, ok, result)
    reports[n] = { player = p, ok = ok, value = result }
end)
control.Parent = game.ReplicatedStorage
local function finish(result)
    if not ended then
        ended = true
        test:EndTest(result)
    end
end
task.delay(180, function()
    finish({
        passed = false,
        error = "Deadline: " .. phase,
        checks = checks,
        measurements = measurements,
    })
end)
local function waitFor(predicate, timeout)
    local deadline = os.clock() + timeout
    repeat
        if predicate() then
            return
        end
        task.wait(0.05)
    until os.clock() > deadline
    error("Timeout: " .. phase)
end
local function drive(p, action, a, b)
    sequence += 1
    local n = sequence
    phase = p.Name .. ":" .. action
    control.Drive:FireClient(p, n, action, a, b)
    waitFor(function()
        return reports[n] ~= nil
    end, 10)
    local r = reports[n]
    assert(r.player == p and r.ok, tostring(r.value))
    return r.value
end
local function check(name, condition)
    assert(condition, name)
    table.insert(checks, name)
end
local function paired(a,b,bpm)
    local count,maxSkew=0,0
    for _,x in a.onsets do
        if x.bpm~=bpm then continue end
        for _,y in b.onsets do
            if y.bpm==bpm and x.slot==y.slot and x.version==y.version and x.scheduledAt==y.scheduledAt then
                count+=1;maxSkew=math.max(maxSkew,math.abs(x.submittedAt-y.submittedAt)*1000)
            end
        end
    end
    return {count=count,maxSubmissionSkewMs=maxSkew}
end
local function settled(p)
    local result
    waitFor(function()
        result = drive(p, "Hello")
        return result.jam.session
            and next(result.jam.session.pending) == nil
            and result.jam.session.tempo == nil
    end, 7)
    return result
end
local Book = require(game.ReplicatedStorage.Shared.BeatBook)
task.spawn(function()
    local ok, err = pcall(function()
        waitFor(function()
            local n = 0
            for p in ready do
                if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    n += 1
                end
            end
            return n == 2
        end, 75)
        local owners = {}
        for _, p in game.Players:GetPlayers() do
            local s = drive(p, "Hello")
            assert(s.room.stationId, "No owned sampler")
            table.insert(owners, { p = p, station = s.room.stationId })
        end
        table.sort(owners, function(a, b)
            return a.station < b.station
        end)
        local a, b = owners[1].p, owners[2].p
        for i, spec in owners do
            local x = if spec.station == "Station_1" then -8 else 8
            spec.p.Character:PivotTo(CFrame.new(x, 6.2, 10))
            spec.p.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
            task.wait(0.3)
            check(
                "participant " .. i .. " claims only own sampler",
                drive(spec.p, "Prompt", spec.station).station == spec.station
            )
            local pad = if i == 1 then 1 else 16
            drive(spec.p, "Assign", pad, if i == 1 then "style.triphop.01" else "style.triphop.09")
            for _, step in (if i == 1 then { 1, 5, 9, 13 } else { 3, 7, 11, 15 }) do
                drive(spec.p, "Step", pad, step)
            end
            drive(spec.p, "Bpm", if i == 1 then 120 else 90)
        end
        local beforeA, beforeB = drive(a, "Hello").pattern, drive(b, "Hello").pattern
        drive(a, "JamOpen")
        local first = drive(a, "JamJoin")
        check(
            "first owns track and keeps sampler; solo transport stopped",
            first.jam.active
                and first.station == owners[1].station
                and not first.playing
                and not first.recording
        )
        drive(b, "JamOpen")
        local second = drive(b, "JamJoin")
        measurements.join = {
            first = first.jam,
            second = second.jam,
            notice = second.notice,
            personalBpm = second.pattern.bpm,
        }
        check(
            "second queues on shared timeline with independent data",
            second.jam.active
                and second.jam.session.anchor == first.jam.session.anchor
                and second.jam.session.bpm == 120
                and second.pattern.bpm == 90
                and second.jam.session.pending["2"] ~= nil
        )
        check(
            "joining never rewrites either personal pattern",
            Book.samePattern(beforeA, drive(a, "Hello").pattern)
                and Book.samePattern(beforeB, second.pattern)
        )
        local edited = drive(a, "Step", 1, 2)
        check(
            "working edit does not mutate current shared snapshot",
            not edited.jam.session.tracks["1"].snapshot.pattern.rows[1][2]
        )
        local publish = drive(a, "JamPublish")
        check(
            "publish schedules only own immutable copy",
            publish.jam.session.pending["1"].snapshot.pattern.rows[1][2]
                and publish.jam.session.pending["2"].snapshot.pattern.rows[16][3]
        )
        local revision = publish.jam.revision
        local stale = drive(a, "JamRaw", "JamPublish", {
            generation = publish.jam.generation,
            revision = revision - 1,
            at = workspace:GetServerTimeNow(),
        })
        check("stale revision rejected without replacing proposals", stale.jam.revision == revision)
        local late = drive(a, "JamDelayed", "JamPublish")
        check(
            "delayed timestamp rejected; both memberships survive",
            late.jam.active
                and late._qa.lastNotice
                and late._qa.lastNotice:find("arrived late") ~= nil
        )
        local guest = drive(b, "JamTempo", 140)
        check("guest cannot change common BPM", guest.jam.session.tempo == nil)
        local unrelated = drive(a, "StageClose")
        check("unassociated mode close cannot evict jam", unrelated.jam.active)
        settled(a)
        settled(b)
        local playedA, playedB = drive(a, "JamProbe"), drive(b, "JamProbe")
        task.wait(6)
        local hotA, hotB = drive(a, "JamProbe"), drive(b, "JamProbe")
        measurements.warm120 = {
            a = hotA._qa,
            b = hotB._qa,
            anchorDriftMs = math.abs(hotA._qa.anchor - hotB._qa.anchor) * 1000,
        }
        measurements.warm120.paired=paired(hotA._qa,hotB._qa,120)
        check("same planned phrase submits on both clients",measurements.warm120.paired.count>=2 and measurements.warm120.paired.maxSubmissionSkewMs<80)
        check(
            "both clients render both known tracks locally",
            hotA._qa.submitted - playedA._qa.submitted >= 12
                and hotB._qa.submitted - playedB._qa.submitted >= 12
                and hotA._qa.readyBanks == 2
                and hotB._qa.readyBanks == 2
        )
        check(
            "steady playback has no per-hit state messages",
            hotA._qa.stateMessages == playedA._qa.stateMessages
                and hotB._qa.stateMessages == playedB._qa.stateMessages
        )
        check("shared logical anchor drift is zero", measurements.warm120.anchorDriftMs == 0)
        check(
            "sample buses obey authored voice/gain bound",
            hotA._qa.allocatedVoices <= 16
                and hotB._qa.allocatedVoices <= 16
                and hotA._qa.musicPeakBound == 0.56
        )
        for _, bpm in { 60, 96, 180 } do
            drive(a, "JamTempo", bpm)
            settled(a)
            settled(b)
            local beginA, beginB = drive(a, "JamProbe"), drive(b, "JamProbe")
            task.wait(6)
            local endA, endB = drive(a, "JamProbe"), drive(b, "JamProbe")
            measurements[tostring(bpm)] = {
                a = endA._qa,
                b = endB._qa,
                deltaA = endA._qa.submitted - beginA._qa.submitted,
                deltaB = endB._qa.submitted - beginB._qa.submitted,
            }
            measurements[tostring(bpm)].paired=paired(endA._qa,endB._qa,bpm)
            check("tempo "..bpm.." matches actual scheduled onset pairs",measurements[tostring(bpm)].paired.count>=2 and measurements[tostring(bpm)].paired.maxSubmissionSkewMs<80)
            local limit = math.min(80, (60 / bpm / 4) * 800)
            check(
                "tempo " .. bpm .. " rebase shared without changing personal BPM",
                endA._qa.bpm == bpm
                    and endB._qa.bpm == bpm
                    and endA._qa.anchor == endB._qa.anchor
                    and endB.pattern.bpm == 90
            )
            check(
                "tempo " .. bpm .. " submits musical hits within late cutoff",
                measurements[tostring(bpm)].deltaA >= 8
                    and measurements[tostring(bpm)].deltaB >= 8
                    and endA._qa.currentTempoLatenessMs.max < limit
                    and endB._qa.currentTempoLatenessMs.max < limit
            )
            check(
                "tempo " .. bpm .. " has no skipped transport steps in steady window",
                endA._qa.missedSteps == beginA._qa.missedSteps
                    and endB._qa.missedSteps == beginB._qa.missedSteps
            )
        end
        local survivorBefore = drive(b, "JamProbe")
        local anchor = survivorBefore.jam.session.anchor
        drive(a, "LeaveTest")
        waitFor(function()
            return #game.Players:GetPlayers() == 1
        end, 8)
        local survivor = drive(b, "Hello")
        check(
            "disconnect transfers conductor and preserves survivor timeline",
            survivor.jam.active
                and survivor.jam.conductor
                and survivor.jam.session.anchor == anchor
                and survivor.jam.session.tracks["1"] == nil
        )
        task.wait(3)
        local continued = drive(b, "JamProbe")
        measurements.survivor = continued._qa
        check(
            "survivor continues audible local submissions",
            continued._qa.submitted > survivorBefore._qa.submitted
        )
        check("survivor retains own pattern", Book.samePattern(beforeB, continued.pattern))
        drive(b, "JamLeave")
        local stopped = drive(b, "JamProbe")
        check(
            "last leave disposes all jam voices and membership",
            not stopped.jam.active
                and stopped._qa.allocatedVoices == 0
                and stopped._qa.playingVoices == 0
        )
    end)
    finish({
        passed = ok,
        error = if not ok then tostring(err) else nil,
        checks = checks,
        count = #checks,
        measurements = measurements,
        clients = 2,
        storage = "session only",
        measurement = "Studio clock and audio-submission timing; not physical/acoustic latency",
    })
end)
