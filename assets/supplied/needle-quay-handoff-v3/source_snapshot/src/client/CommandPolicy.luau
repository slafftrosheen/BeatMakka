-- Client affordance only; MusicService remains the authoritative permission check.
return function(state, action)
    return action == "Release"
        or action == "LeaveListening"
        or action == "ChapterClose"
        or action == "StageClose"
        or (
            state ~= nil
            and state.ready
            and (
                state.station ~= nil
                or (type(action) == "string" and action:sub(1, 7) == "Chapter" and state.concert ~= nil and state.concert.open)
                or (
                    type(action) == "string"
                    and action:sub(1, 5) == "Stage"
                    and state.stage ~= nil
                    and state.stage.open
                )
            )
        )
end
