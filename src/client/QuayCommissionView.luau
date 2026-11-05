local Shared = game.ReplicatedStorage.Shared
local Catalog = require(Shared.QuayBeatCommissions)
local Recipes = require(Shared.QuayFxRecipes)
local Theme = require(Shared.Theme)
local Gui = require(script.Parent.GuiFactory)
local Voice = require(script.Parent.CompanionVoice)
local Mix = require(script.Parent.AudioMix)
local SchedulePlayback = require(script.Parent.SchedulePlayback)
local RunService = game:GetService("RunService")
local VisualChecklist = require(script.Parent.VisualChecklist)
local View = {}
View.__index = View
function View.new(parent, send)
    local self = setmetatable({ index = 1, send = send }, View)
    self.root = Gui.make("Frame", parent, {
        Name = "BeatCommission",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 9,
        Visible = false,
    })
    Gui.make(
        "UIListLayout",
        self.root,
        { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }
    )
    local function label(order)
        local l = Gui.label(self.root, "", 15, Theme.Cream)
        l.Size, l.AutomaticSize, l.LayoutOrder = UDim2.fromScale(1, 0), Enum.AutomaticSize.Y, order
        return l
    end
    self.title, self.brief, self.feedback = label(1), label(2), label(9)
    self.title.TextColor3 = Theme.Amber
    local function button(order, callback)
        local b = Gui.button(self.root, "", callback)
        b.Size, b.LayoutOrder = UDim2.new(1, 0, 0, 48), order
        return b
    end
    self.accept = button(3, function()
        if self.item then
            send("QuayCommissionAccept", self.item.id)
        end
    end)
    self.select = button(4, function()
        local sequences = self.q and self.q.commission and self.q.commission.sequences or {}
        if #sequences > 0 then
            self.index = self.index % #sequences + 1
        end
        self:update(self.q, self.host)
    end)
    self.checkSummary = label(5)
    self.checkSummary.TextColor3 = Theme.Amber
    self.checkToggle = button(6, function()
        self.showChecks = not self.showChecks
        self:update(self.q, self.host)
    end)
    self.checklist = VisualChecklist.new(self.root, 6)
    self.checklist.root.LayoutOrder = 7
    self.submit = button(8, function()
        local sequence = self.q and self.q.commission and self.q.commission.sequences[self.index]
        if sequence and self.submit.Active then
            send(
                "QuayCommissionSubmit",
                { kind = "sequence", id = sequence.id, revision = sequence.revision }
            )
        end
    end)
    self.cancel = button(10, function()
        send("QuayCommissionCancel")
    end)
    self.replay = button(11, function()
        if self.item then
            send("QuayCommissionBrief", self.item.id)
        end
    end)
    self.replay.Text = "HEAR REQUEST AGAIN"
    self.cancel.Text = "PAUSE REQUEST"
    self.accept:SetAttribute("UiIcon", "plus")
    self.select:SetAttribute("UiIcon", "steps")
    self.submit:SetAttribute("UiIcon", "play")
    self.checkToggle:SetAttribute("UiIcon", "check")
    self.replay:SetAttribute("UiIcon", "headphones")
    self.cancel:SetAttribute("UiIcon", "close")
    self.remote = game.ReplicatedStorage.MusicNetwork:WaitForChild("QuayCommissionPlayback", 10)
    if self.remote then
        self.connection = self.remote.OnClientEvent:Connect(function(pattern)
            self:play(pattern)
        end)
    end
    return self
end
function View:play(packet)
    if self.playback then
        self.playback:stop()
    end
    if self.playbackConnection then
        self.playbackConnection:Disconnect()
    end
    if self.audio then
        self.audio:destroy()
    end
    if type(packet) ~= "table" or type(packet.schedule) ~= "table" then
        return
    end
    self.audio = require(script.Parent.AudioEngine).new(
        "CommissionPreview",
        { musicOnly = true, strictSelection = true }
    )
    self.playback = SchedulePlayback.new(self.audio)
    self.playback:accept(packet)
    Voice.Cue:Fire("silence")
    local seconds =
        math.max(0, packet.startedAt + packet.schedule.completeAt - workspace:GetServerTimeNow())
    Mix.sampleAuditionUntil = os.clock() + seconds
    self.playbackConnection = RunService.Heartbeat:Connect(function()
        self.playback:step(workspace:GetServerTimeNow())
        if workspace:GetServerTimeNow() >= packet.startedAt + packet.schedule.completeAt then
            self.playback:stop()
            self.playbackConnection:Disconnect()
            self.playbackConnection = nil
            self.audio:destroy()
            self.audio = nil
        end
    end)
end
function View:update(q, host)
    local previousHost = self.host
    self.q, self.host = q, host
    self.item = nil
    for _, item in Catalog.List do
        if item.host == host then
            if q and q.commission and q.commission.active == item.id then
                self.item = item
                break
            end
            if
                not self.item
                or (
                    q
                    and q.progress
                    and q.progress.commissions[self.item.id]
                    and Catalog.available(q.progress, item)
                    and not q.progress.commissions[item.id]
                )
            then
                self.item = item
            end
        end
    end
    self.root.Visible = self.item ~= nil and q ~= nil
    if not self.root.Visible then
        return
    end
    local item, c = self.item, q.commission
    if previousHost ~= host then
        self.send("QuayCommissionBrief", item.id)
    end
    if not c then
        self.root.Visible = false
        return
    end
    local recipe = Recipes.find(item.fx)
    local earned, active = Catalog.available(q.progress, item), c.active == item.id
    self.title.Text = string.upper(item.title) .. (if c.completed[item.id] then " / KEPT" else "")
    self.brief.Text = recipe.label
        .. "  •  "
        .. item.low
        .. "–"
        .. item.high
        .. " BPM\n2 pads + 4 FX hits → Save Sequence"
        .. (
            if item.tone == "warm"
                then "\nWARM TONE: -30% or lower"
                elseif item.tone == "drive" then "\nDRIVE: 20% or higher"
                else ""
        )
    self.accept.Visible = not active
    self.accept.Text = if earned
        then (if c.completed[item.id] then "MAKE AN ENCORE" else "TAKE REQUEST")
        else recipe.hint
    self.accept.Active, self.accept.Interactable, self.accept.Selectable = earned and not c.busy, earned and not c.busy, earned and not c.busy
    self.select.Visible, self.submit.Visible, self.cancel.Visible, self.checkSummary.Visible =
        active, active, active, active
    self.checkToggle.Visible = active
    self.replay.Active, self.replay.Interactable, self.replay.Selectable = not c.busy, not c.busy, not c.busy
    if self.index > #c.sequences then
        self.index = 1
    end
    local selected = c.sequences[self.index]
    self.select.Text = if selected
        then "LOOP / " .. selected.title .. " / CHANGE"
        else "Save a loop in your Roamer first"
    self.submit.Text = if c.busy then "LISTENING…" else "PLAY FOR " .. string.upper(item.name)
    local canSubmit = not c.busy and selected ~= nil
    self.submit.Active, self.submit.Interactable, self.submit.Selectable = canSubmit, canSubmit, canSubmit
    local review = selected and selected.review
    local ready, count = 0, 0
    for _, check in review and review.checks or {} do
        count += 1
        if check.ok then ready += 1 end
    end
    self.checkSummary.Text = if review then ready .. "/" .. count .. " READY" else "CHOOSE A SAVED LOOP"
    self.checkToggle.Text = if self.showChecks then "LESS" else "REQUEST CHECKLIST"
    self.checklist:update(review and review.checks)
    self.checklist.root.Visible = active and self.showChecks == true and review ~= nil
    self.feedback.Text = if active and review and not review.passed and not c.busy then review.hint
        else c.feedback or (if active and review then review.hint else "")
end
function View:destroy()
    if self.playbackConnection then
        self.playbackConnection:Disconnect()
    end
    if self.playback then
        self.playback:stop()
    end
    if self.connection then
        self.connection:Disconnect()
    end
    if self.audio then
        self.audio:destroy()
    end
    self.root:Destroy()
end
return View
