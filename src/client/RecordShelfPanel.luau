local Http = game:GetService("HttpService")
local Panel = require(script.Parent.RecordPanel)
local Sleeve = require(script.Parent.RecordSleeveView)
local Shared = game.ReplicatedStorage.Shared
local Activities = require(Shared.QuayActivities)
local Shelf = {}
Shelf.__index = Shelf
function Shelf.new(parent, callbacks)
    local self = setmetatable({ callbacks = callbacks, motif = 1, palette = 1, tab = "music" }, Shelf)
    local p = Panel.new(parent, "RecordShelfDetails", 30)
    self.panel, self.root = p, p.root
    self.heading, self.status, self.notice = p:label("RecordTitle", 17), p:label("RecordState"), p:label("RecordSaveNotice")
    self.flow = p:steps({ { "MUSIC", "disc" }, { "SLEEVE", "sleeve" }, { "SHARE", "people" } })
    self.tabs = p:tabs({ { "music", "MUSIC", "disc" }, { "sleeve", "SLEEVE", "sleeve" }, { "share", "SHARE", "people" } }, function(tab)
        self.tab = tab
        self:render()
    end)
    self.versions = p:button("ConfirmHistoricVersions", "USE CURRENT VERSIONS / ARCHIVE ORIGINAL", function()
        callbacks.command("RecordUseCurrentVersions", { context = self.state.records.context })
    end)
    self.art = p:add("Frame", { Name = "SleevePreview", Size = UDim2.fromOffset(96, 96),
        BackgroundColor3 = Color3.fromRGB(47, 92, 88), BorderSizePixel = 0 })
    self.sleeve = Sleeve.new(self.art, 34)
    self.continue = p:button("ContinueMusic", "CONTINUE", function() self:continueMusic() end)
    self.audition = p:button("AuditionRecord", "LISTEN / UP TO 15 SECONDS", function()
        if self.section == "Releases" then callbacks.command("RecordAudition", { id = self.item.id })
        else callbacks.command("RecordPreview", { ref = self:reference() }) end
    end)
    self.motifButton = p:button("ChooseMotif", "", function()
        self.motif = self.motif % #Activities.Motifs + 1; self:render()
    end)
    self.paletteButton = p:button("ChoosePalette", "", function()
        self.palette = self.palette % #Activities.Palettes + 1; self:render()
    end)
    self.keepCover = p:button("KeepPersonalSleeve", "KEEP SLEEVE / UNSAVED", function()
        callbacks.command("RecordCover", { ref = self:reference(), context = self.state.records.context,
            cover = { motif = Activities.Motifs[self.motif].id, palette = Activities.Palettes[self.palette].id } })
    end)
    self.scope = p:label("CurrentPermission")
    self.listenOnly = p:button("ReleaseListenOnly", "SAVE RELEASE COPY / LISTEN ONLY", function() self:release(false) end)
    self.remixable = p:button("ReleaseRemix", "SAVE RELEASE COPY / ALLOW REMIX", function() self:release(true) end)
    self.openRelease = p:button("OpenLastRelease", "OPEN LAST SAVED RELEASE", function()
        if callbacks.openRelease and self.state.records.lastReleaseId then callbacks.openRelease(self.state.records.lastReleaseId) end
    end)
    self.permission = p:button("ChangeRemixPermission", "", function()
        callbacks.command("RecordPermission", { id = self.item.id, permissionRevision = self.item.permissionRevision,
            allowRemix = not self.item.allowRemix })
    end)
    self.player = p:button("ChooseRecipient", "", function()
        local players, index = self.state.records.players, 0
        for i, player in players do if player.userId == self.recipientId then index = i; break end end
        if #players > 0 then self.recipientId = players[index % #players + 1].userId end
        self:render()
    end)
    self.invite = p:button("InviteToRecord", "INVITE TO LISTEN / 45 SECONDS", function()
        local target = self:recipient()
        if target then callbacks.command("RecordInvite", { id = self.item.id, userId = target.userId,
            permissionRevision = self.item.permissionRevision }) end
    end)
    self.detailsToggle = p:button("RecordDetails", "CREDITS + DETAILS", function()
        self.detailsOpen = not self.detailsOpen; self:render()
    end)
    self.detail, self.explanation = p:label("FullRecordCredits"), p:label("PermissionScope")
    self.close = p:button("CloseRecordDetails", "CLOSE", function() p:show(false) end)
    return self
end
function Shelf:recipient()
    for _, player in self.state.records.players do if player.userId == self.recipientId then return player end end
    return nil
end
function Shelf:reference()
    return { kind = if self.section == "Sections" then "sequence" elseif self.section == "Drafts" then "song" else "finished",
        id = self.item.id, revision = self.item.revision }
end
function Shelf:continueMusic()
    if self.section == "Sections" then self.callbacks.command("SequenceSelect", self.item.id); self.callbacks.page("Sequence")
    elseif self.section == "Drafts" then self.callbacks.command("SongSelect", self.item.id); self.callbacks.page("Song")
    elseif self.section == "Finished" then self.callbacks.command("FinishedSelect", self.item.id); self.callbacks.command("FinishedPlay") end
    self.panel:show(false)
end
function Shelf:release(allow)
    local cover = { motif = Activities.Motifs[self.motif].id, palette = Activities.Palettes[self.palette].id }
    local context = self.state.records.context
    local key = self.item.id .. ":" .. self.item.revision .. ":" .. context.generation .. ":" .. context.editVersion
        .. ":" .. cover.motif .. ":" .. cover.palette .. ":" .. tostring(allow)
    if self.requestKey ~= key then self.requestKey, self.requestId = key, Http:GenerateGUID(false) end
    self.callbacks.command("RecordRelease", { ref = self:reference(), context = context,
        requestId = self.requestId, allowRemix = allow, cover = cover })
end
function Shelf:open(item, section, state, tab)
    self.item, self.section, self.state, self.tab = item, section, state, tab or "music"
    self.detailsOpen, self.recipientId, self.motif, self.palette = false, nil, 1, 1
    for index, value in Activities.Motifs do if item.cover and value.id == item.cover.motif then self.motif = index end end
    for index, value in Activities.Palettes do if item.cover and value.id == item.cover.palette then self.palette = index end end
    self:render()
    self.panel:show(true, self.tabs.buttons[self.tab])
end
function Shelf:update(state)
    self.state = state
    if not self.root.Visible then return end
    local m = state.music
    local entries = if self.section == "Sections" then m.library.sequences elseif self.section == "Drafts" then m.library.drafts
        elseif self.section == "Finished" then m.finishedSongs else state.records.releases
    for _, item in entries do if item.id == self.item.id then self.item = item; self:render(); return end end
    self.panel:show(false)
end
function Shelf:render()
    local item, state = self.item, self.state
    if not item or not state.records then return end
    local released, music, cover, share = self.section == "Releases", self.tab == "music", self.tab == "sleeve", self.tab == "share"
    self.tabs:select(self.tab)
    self.flow:update(if share then 3 elseif cover then 2 else 1)
    self.heading.Text = (item.title or item.name) .. "\n" .. item.type .. (if released then " / RELEASE v1" else "")
    local saved = released or self.section == "Finished" or item.savedRevision == item.revision
    local creator = item.attribution and item.attribution.creator
    self.status.Text = (if creator then "BY / " .. creator.name else "Creator credit unavailable") .. "\n"
        .. (if state.saving then "SAVING" elseif saved then Panel.storage(state.saveMode) else "UNSAVED / SAVE EXPLICITLY")
        .. (if item.localOnly then "\nLOCAL PREVIEW / listening approval pending" else "")
    self.notice.Text = state.notice or ""
    self.versions.Visible = music and not released and self.section ~= "Finished" and state.music.unverifiedVersions == true
    Panel.enable(self.versions, not state.saving)
    if self.versions.Visible then self.notice.Text ..= "\nHistoric versions are unverified. This action archives the original before choosing current versions." end
    self.art.Visible, self.continue.Visible, self.audition.Visible = music or cover, music and not released, music
    self.continue.Text = if self.section == "Finished" then "PLAY FULL FINISHED SONG" else "CONTINUE"
    for _, control in { self.motifButton, self.paletteButton } do control.Visible = cover and not released; Panel.enable(control, not state.saving) end
    self.keepCover.Visible = cover and (self.section == "Sections" or self.section == "Drafts")
    Panel.enable(self.keepCover, not state.saving)
    self.motifButton.Text = "LAYOUT / " .. Activities.Motifs[self.motif].label
    self.paletteButton.Text = "COLOUR / " .. Activities.Palettes[self.palette].label
    self.sleeve:update(if released then item.cover else { motif = Activities.Motifs[self.motif].id, palette = Activities.Palettes[self.palette].id })
    for _, control in { self.listenOnly, self.remixable } do control.Visible = share and not released; Panel.enable(control, not state.saving) end
    self.openRelease.Visible = share and not released and state.records.lastReleaseId ~= nil and self.callbacks.openRelease ~= nil
    self.scope.Visible = share
    self.scope.Text = if released then (if item.allowRemix then "REMIX ALLOWED / FUTURE COPIES" else "LISTEN ONLY / REMIX DISABLED")
        .. "\nExisting copies keep their music and credits.\nInvites start no audio until accepted."
        else "Release saves an exact copy. It does not Finish a Song.\nChoose who may remix before saving this copy."
    for _, control in { self.permission, self.player, self.invite } do control.Visible = share and released end
    self.permission.Text = if item.allowRemix then "CHANGE TO LISTEN ONLY" else "ALLOW FUTURE REMIX COPIES"
    Panel.enable(self.permission, not state.saving)
    local target = self:recipient()
    self.player.Text = if target then "TO / " .. target.name .. " / CHANGE"
        elseif #state.records.players == 0 then "NO OTHER PLAYERS HERE" else "CHOOSE A LISTENER"
    self.invite.Text = if target then "INVITE " .. target.name .. " / 45 SECONDS" else "INVITE TO LISTEN"
    Panel.enable(self.player, #state.records.players > 0)
    Panel.enable(self.invite, target ~= nil and not state.saving)
    self.detailsToggle.Text = if self.detailsOpen then "LESS DETAIL" else "CREDITS + DETAILS"
    self.detail.Visible, self.explanation.Visible = self.detailsOpen == true, self.detailsOpen == true
    self.detail.Text = Panel.credits(item) .. "\nPACK / " .. (item.packLabel or "Unavailable")
        .. (if released then "\nCAPTURED FROM / " .. item.type .. " revision " .. item.source.revision else "")
    self.explanation.Text = if released
        then "Permission affects future remix copies. Existing copies keep their music and credits. An invitation starts no audio until accepted."
        else "Keep Sleeve is unsaved until Save. Undo is available. Release saves an exact musical copy and this sleeve; later edits do not change it. Pattern/Loop and Draft Song remain unfinished."
    self.panel:ensureFocus(self.tabs.buttons[self.tab])
end
return Shelf
