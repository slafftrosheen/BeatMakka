local Panel = require(script.Parent.RecordPanel)
local Sleeve = require(script.Parent.RecordSleeveView)
local View = {}
View.__index = View
local function seconds(value)
    value = math.max(0, math.floor(value or 0))
    return string.format("%d:%02d", math.floor(value / 60), value % 60)
end
function View.new(parent, send, mute)
    local self = setmetatable({ send = send }, View)
    local p = Panel.new(parent, "PrivateRecordListening", 70)
    self.panel = p
    self.heading, self.summary, self.notice = p:label("RecordHeading", 18), p:label("RecordSummary"), p:label("RecordNotice")
    self.flow = p:steps({ { "INVITE", "people" }, { "LISTEN", "headphones" }, { "REMIX", "duplicate" } })
    self.scope = p:label("RecordScope")
    local function command(action, extra)
        if not self.item then return end
        extra = extra or {}; extra.token = self.item.token; send(action, extra)
    end
    self.accept = p:button("AcceptRecordInvite", "ACCEPT + LISTEN / UP TO 15 SECONDS", function() command("RecordAccept") end)
    self.stopOwn = p:button("StopOwnMusicBeforeAccept", "STOP MY PLAYBACK FIRST", function() send("Stop") end)
    self.decline = p:button("DeclineRecordInvite", "DECLINE / KEEP WORKING", function() command("RecordDecline") end)
    self.art = p:add("Frame", { Name = "SharedSleeve", Size = UDim2.fromOffset(96, 96),
        BackgroundColor3 = Color3.fromRGB(47, 92, 88), BorderSizePixel = 0 })
    self.sleeve = Sleeve.new(self.art, 74)
    self.clock = p:label("RecordPosition", 15)
    local rail = p:add("Frame", { Name = "RecordProgress", Size = UDim2.new(1, -8, 0, 6),
        BackgroundColor3 = Color3.fromRGB(44, 48, 49), BorderSizePixel = 0 })
    self.rail = rail
    self.fill = Instance.new("Frame")
    self.fill.Name, self.fill.BackgroundColor3, self.fill.BorderSizePixel = "Elapsed", Color3.fromRGB(243, 182, 95), 0
    self.fill.Size, self.fill.ZIndex, self.fill.Parent = UDim2.fromScale(0, 1), 74, rail
    self.play = p:button("ReplayRecordAudition", "LISTEN AGAIN / SHORT AUDITION", function() command("RecordPlay") end)
    self.full = p:button("PlayFullRecord", "PLAY FULL RECORD", function() command("RecordPlay", { full = true }) end)
    self.stop = p:button("StopRecord", "STOP RECORD", function() command("RecordStop") end)
    self.mute = p:button("MuteRecord", "MUTE RECORD", mute)
    self.workbench = p:button("OpenWorkbenchForRecord", "STOP RECORD + OPEN MY WORKBENCH", function() command("RecordWorkbench") end)
    self.remix = p:button("KeepCreditedRemix", "CREATE CREDITED COPY / UNSAVED", function() command("RecordRemix", { context = self.context }) end)
    self.detailsToggle = p:button("RecordDetails", "CREDITS + SOURCE DETAILS", function()
        self.detailsOpen = not self.detailsOpen; self:renderDetails()
    end)
    self.detail, self.policy = p:label("RecordCredits"), p:label("RemixPolicy")
    self.close = p:button("LeaveRecord", "CLOSE RECORD / RETURN TO MY WORK", function() command("RecordLeave") end)
    return self
end
function View:renderDetails()
    self.detail.Visible, self.policy.Visible = self.detailsOpen == true, self.detailsOpen == true
    self.detailsToggle.Text = if self.detailsOpen then "LESS DETAIL" else "CREDITS + SOURCE DETAILS"
end
function View:tick()
    local item = self.item
    if not item or not self.panel.root.Visible then return end
    local playback = self.session and item.playback
    self.clock.Visible, self.rail.Visible = self.session ~= nil, playback ~= nil
    if playback then
        local schedule = playback.schedule
        local elapsed = math.max(0, workspace:GetServerTimeNow() - playback.startedAt + (playback.offset or 0))
        local duration = schedule.duration
        local ended = elapsed >= (schedule.completeAt or duration)
        self.clock.Text = (if ended then "ENDED" elseif workspace:GetServerTimeNow() < playback.startedAt then "STARTING"
            elseif elapsed >= duration then "TAIL" elseif playback.audition then "AUDITION" else "FULL RECORD")
            .. " / " .. seconds(math.min(elapsed, duration)) .. " / " .. seconds(duration)
        self.fill.Size = UDim2.fromScale(if duration > 0 then math.clamp(elapsed / duration, 0, 1) else 0, 1)
    else self.clock.Text = "RECORD STOPPED" end
end
function View:update(state, muted, globalMuted, status)
    local records = state.records or {}
    local session, invite = records.session, records.invite
    local item = session or invite
    if (self.item and self.item.token) ~= (item and item.token) then self.detailsOpen = false end
    self.item, self.session, self.context = item, session, records.context
    self.panel:show(item ~= nil, if session then self.stop else self.decline)
    if not item then return end
    local creator = item.attribution and item.attribution.creator
    self.heading.Text = item.title .. "\n" .. item.type .. (if item.temporary then " / PREVIEW" else " / RELEASE v1")
    self.summary.Text = (if creator then "BY / " .. creator.name else "Creator credit unavailable") .. "\n"
        .. (if item.temporary then "PERSONAL PREVIEW / NO RELEASE" else Panel.storage(item.storage))
        .. (if item.localOnly then "\nLOCAL PREVIEW / listening approval pending" else "")
    self.notice.Text = (state.notice or "") .. (if session then "\n" .. (status or "")
        else "\nFROM / " .. item.owner.name .. " / invitation expires after 45 seconds")
    self.flow:update(if item.remixed then 3 elseif session then 2 else 1)
    self.accept.Visible, self.decline.Visible = session == nil, session == nil
    self.stopOwn.Visible = session == nil and state.station ~= nil and (state.playing or state.recording)
    Panel.enable(self.accept, not state.playing and not state.recording)
    for _, control in { self.play, self.stop, self.mute, self.close, self.clock } do control.Visible = session ~= nil end
    self.full.Visible = session ~= nil and item.type ~= "Pattern/Loop"
    self.full.Text = if item.type == "Finished Song" then "PLAY FULL FINISHED SONG" else "PLAY FULL DRAFT / UNFINISHED"
    self.remix.Visible = session ~= nil and not item.own and item.allowRemix == true and not item.remixed
    self.workbench.Visible = self.remix.Visible and state.station == nil
    Panel.enable(self.remix, item.allowRemix == true and not item.remixed and state.station ~= nil and not state.saving)
    self.mute.Text = if globalMuted then "GLOBAL SOUND OFF / SETTINGS"
        elseif muted then "RESTORE RECORD SOUND" else "MUTE THIS RECORD"
    Panel.enable(self.mute, not globalMuted)
    self.scope.Text = if item.remixed then "REMIX OPEN / UNSAVED / SAVE AT YOUR INSTRUMENT"
        elseif item.allowRemix then "REMIX ALLOWED / NEW OWNED COPY\nYour current workspace is archived first."
        else "LISTEN ONLY / REMIX DISABLED BY AUTHOR"
    if session == nil then self.scope.Text ..= "\nAccept starts a short audition. Decline keeps your work." end
    self.sleeve:update(item.cover)
    self.detail.Text = Panel.credits(item) .. "\nPACK / " .. (item.packLabel or "Unavailable")
    self.policy.Text = if item.remixed then "Your separate remix is unsaved. Close this panel and Save explicitly. The source and original credits remain intact."
        elseif item.allowRemix then "Remix creates a separate owned project at your own workbench. Your current workspace is retained in Imports. Future permission changes do not erase existing copies."
        else "The author permits listening only. Decline or close preserves your work and sound preference."
    self:renderDetails()
    self:tick()
    self.panel:ensureFocus(if session then self.stop else self.decline)
end
return View
