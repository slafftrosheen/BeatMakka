local Panel = require(script.Parent.RecordPanel)
local View = {}
View.__index = View
function View.new(parent, send, mute)
    local self = setmetatable({ send = send }, View)
    local p = Panel.new(parent, "PrivateRecordListening", 70)
    self.panel = p
    self.heading, self.detail, self.notice = p:label("RecordHeading", 18), p:label("RecordCredits"), p:label("RecordNotice")
    local function command(action, extra)
        extra = extra or {}; extra.token = self.item.token; send(action, extra)
    end
    self.accept = p:button("AcceptRecordInvite", "ACCEPT / AUDITION UP TO 15 SECONDS", function() command("RecordAccept") end)
    self.stopOwn = p:button("StopOwnMusicBeforeAccept", "STOP MY PLAYBACK BEFORE ACCEPTING", function() send("Stop") end)
    self.decline = p:button("DeclineRecordInvite", "DECLINE / KEEP WORKING", function() command("RecordDecline") end)
    self.play = p:button("ReplayRecordAudition", "PLAY SHORT AUDITION", function() command("RecordPlay") end)
    self.full = p:button("PlayFullRecord", "PLAY FULL SONG", function() command("RecordPlay", { full = true }) end)
    self.stop = p:button("StopRecord", "STOP RECORD", function() command("RecordStop") end)
    self.mute = p:button("MuteRecord", "MUTE RECORD", mute)
    self.workbench = p:button("OpenWorkbenchForRecord", "STOP RECORD / OPEN MY WORKBENCH / KEEP INVITATION", function()
        command("RecordWorkbench")
    end)
    self.remix = p:button("KeepCreditedRemix", "CREATE SEPARATE CREDITED REMIX / UNSAVED", function()
        command("RecordRemix", { context = self.context })
    end)
    self.scope = p:label("RecordScope")
    self.close = p:button("LeaveRecord", "CLOSE RECORD / RETURN TO MY WORK", function() command("RecordLeave") end)
    return self
end
function View:update(state, muted, globalMuted, status)
    local records = state.records or {}
    local session, invite = records.session, records.invite
    self.item, self.context = session or invite, records.context
    self.panel:show(self.item ~= nil, if session then self.close else self.decline)
    if not self.item then return end
    local item = self.item
    self.heading.Text = item.title .. "\n" .. item.type .. (if item.temporary then " / PERSONAL PREVIEW" else " / RELEASE v1")
    self.detail.Text = Panel.credits(item) .. "\nPACK / " .. item.packLabel .. "\n"
        .. (if item.temporary then "TEMPORARY PREVIEW / NO RELEASE CREATED" else Panel.storage(item.storage))
    self.notice.Text = (state.notice or "") .. (if session then "\n" .. (status or "") else "\nINVITED BY / " .. item.owner.name .. " / expires after 45 seconds")
    self.accept.Visible, self.decline.Visible = session == nil, session == nil
    self.stopOwn.Visible = session == nil and state.station ~= nil and (state.playing or state.recording)
    for _, control in { self.play, self.stop, self.mute, self.close } do control.Visible = session ~= nil end
    self.full.Visible = session ~= nil and item.type ~= "Pattern/Loop"
    self.remix.Visible = session ~= nil and not item.own
    self.workbench.Visible = session ~= nil and not item.own and state.station == nil
    Panel.enable(self.remix, item.allowRemix == true and not item.remixed and state.station ~= nil and not state.saving)
    self.mute.Text = if globalMuted then "GLOBAL SOUND IS OFF / CHANGE IN SETTINGS"
        elseif muted then "RECORD MUTED / RESTORE RECORD SOUND" else "MUTE RECORD / KEEP MY SOUND PREFERENCE"
    Panel.enable(self.mute, not globalMuted)
    self.scope.Text = if item.remixed then "Your separate remix is open and UNSAVED. Close this panel, then Save explicitly. Its source and original credits remain intact."
        elseif item.allowRemix then "Remix creates a new owned project. Your current workspace is kept in Imports. Open your own workbench before making a copy. Future permission changes do not erase existing copies."
        else "LISTEN ONLY / remix is disabled by the author. Decline or close preserves your work and sound setting."
    if item.localOnly then self.scope.Text ..= "\nLOCAL AUDIO / listening review pending." end
end
return View
