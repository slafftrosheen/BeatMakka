return function()
    local Pattern = require(game.ReplicatedStorage.Shared.Pattern)
    local checks = 0
    local function check(value, message)
        assert(value, message)
        checks += 1
    end
    for _, bpm in { 60, 96, 180 } do
        local duration = Pattern.stepDuration(bpm)
        check(Pattern.recordStep(bpm, 100, 99.99, nil, 3) == nil, "Pre-roll recorded")
        check(Pattern.recordStep(bpm, 100, 100, nil, 3) == 1, "First step missing")
        check(
            Pattern.recordStep(bpm, 100, 100 + duration * 0.6, nil, 3) == 2,
            "Nearest-step quantization failed"
        )
        check(Pattern.recordStep(bpm, 100, 100 + duration * 15.8, nil, 3) == 1, "Loop wrap failed")
        local hit = 100 + duration * 1.1
        local arrival = hit + 0.2
        check(
            Pattern.recordStep(bpm, 100, arrival, { at = hit, epoch = 3 }, 3) == 2,
            "Arrival jitter shifted note"
        )
        check(
            Pattern.recordStep(bpm, 100, arrival, { at = hit, epoch = 2 }, 3) == nil,
            "Old transport accepted"
        )
    end
    for _, event in
        {
            { at = 99, epoch = 3 },
            { at = 101, epoch = 3 },
            { at = 0 / 0, epoch = 3 },
            { at = math.huge, epoch = 3 },
            { at = "100", epoch = 3 },
            { at = 100, epoch = "3" },
        }
    do
        check(Pattern.recordStep(96, 99, 100, event, 3) == nil, "Forged timestamp accepted")
    end
    check(
        Pattern.recordStep(96, 100, 100.01, { at = 99.99, epoch = 3 }, 3) == nil,
        "Timestamp before start accepted"
    )
    return { passed = true, checks = checks, bpms = { 60, 96, 180 }, maximumPastSeconds = 0.35 }
end
