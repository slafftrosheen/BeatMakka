-- Mutable EditableMeshes reserve maximum capacity. Only one local builder at a time.
local Queue = { waiting = {}, busy = false }
function Queue.acquire(cancelled)
    local ticket = {}
    table.insert(Queue.waiting, ticket)
    while Queue.busy or Queue.waiting[1] ~= ticket do
        if cancelled() then
            local index = table.find(Queue.waiting, ticket)
            if index then
                table.remove(Queue.waiting, index)
            end
            return nil
        end
        task.wait()
    end
    table.remove(Queue.waiting, 1)
    if cancelled() then
        return nil
    end
    Queue.busy = true
    local released = false
    return function()
        if released then
            return
        end
        released = true
        Queue.busy = false
    end
end
return Queue
