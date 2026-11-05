local Http = game:GetService("HttpService")
local Panel = require(script.Parent.RecordPanel)
local Sleeve = require(script.Parent.RecordSleeveView)
local Shared = game.ReplicatedStorage.Shared
local Activities = require(Shared.QuayActivities)
local Shelf = {}
Shelf.__index = Shelf
function Shelf.new(parent, callbacks)
    local self = setmetatable({ callbacks = callbacks, motif = 1, palette = 1, recipient = 1 }, Shelf)
    local p = Panel.new(parent, "RecordShelfDetails", 30)
    self.panel, self.root = p, p.root
    self.heading, self.detail = p:label("RecordTitle", 17), p:label("RecordDetails")
    self.notice = p:label("RecordSaveNotice")
    self.versions = p:button("ConfirmHistoricVersions", "USE CURRENT PACK VERSIONS / ARCHIVE HISTORIC REFERENCES", function()
        callbacks.command("RecordUseCurrentVersions", { context = self.state.records.context })
    end)
    self.art = p:add("Frame", { Name = "SleevePreview", Size = UDim2.fromOffset(92, 92),
        BackgroundColor3 = Color3.fromRGB(47, 92, 88), BorderSizePixel = 0 })
    self.sleeve = Sleeve.new(self.art, 34)
    self.continue = p:button("ContinueMusic", "CONTINUE", function() self:continueMusic() end)
    self.audition = p:button("AuditionRecord", "AUDITION / UP TO 15 SECONDS", function()
        if self.section == "Releases" then callbacks.command("RecordAudition", { id = self.item.id })
        else callbacks.command("RecordPreview", { ref = self:reference() }) end
    end)
    self.motifButton = p:button("ChooseMotif", "", function()
        self.motif = self.motif % #Activities.Motifs + 1; self:render()
    end)
    self.paletteButton = p:button("ChoosePalette", "", function()
        self.palette = self.palette % #Activities.Palettes + 1; self:render()
    end)
    self.keepCover = p:button("KeepPersonalSleeve", "KEEP SLEEVE ON THIS ITEM / UNSAVED", function()
        callbacks.command("RecordCover", { ref = self:reference(), context = self.state.records.context,
            cover = { motif = Activities.Motifs[self.motif].id, palette = Activities.Palettes[self.palette].id } })
    end)
    self.listenOnly = p:button("ReleaseListenOnly", "RELEASE A COPY / LISTEN ONLY", function() self:release(false) end)
    self.remixable = p:button("ReleaseRemix", "RELEASE A COPY / ALLOW REMIX", function() self:release(true) end)
    self.permission = p:button("ChangeRemixPermission", "", function()
        callbacks.command("RecordPermission", { id = self.item.id, permissionRevision = self.item.permissionRevision,
            allowRemix = not self.item.allowRemix })
    end)
    self.player = p:button("ChooseRecipient", "", function()
        local players = self.state.records.players
        if #players > 0 then self.recipient = self.recipient % #players + 1 end
        self:render()
    end)
    self.invite = p:button("InviteToRecord", "INVITE TO LISTEN / 45 SECONDS", function()
        local target = self.state.records.players[self.recipient]
        if target then callbacks.command("RecordInvite", { id = self.item.id, userId = target.userId,
            permissionRevision = self.item.permissionRevision }) end
    end)
    self.explanation = p:label("PermissionScope")
    self.close = p:button("CloseRecordDetails", "CLOSE", function() p:show(false) end)
    return self
end
function Shelf:reference()
    return { kind = if self.section == "Sections" then "sequence" elseif self.section == "Drafts" then "song" else "finished",
        id = self.item.id, revision = self.item.revision }
end
function Shelf:continueMusic()
    if self.section == "Sections" then
        self.callbacks.command("SequenceSelect", self.item.id); self.callbacks.page("Sequence")
    elseif self.section == "Drafts" then
        self.callbacks.command("SongSelect", self.item.id); self.callbacks.page("Song")
    elseif self.section == "Finished" then
        self.callbacks.command("FinishedSelect", self.item.id); self.callbacks.command("FinishedPlay")
    end
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
function Shelf:open(item, section, state)
    self.item, self.section, self.state = item, section, state
    self.motif, self.palette = 1, 1
    for index, value in Activities.Motifs do if item.cover and value.id == item.cover.motif then self.motif = index end end
    for index, value in Activities.Palettes do if item.cover and value.id == item.cover.palette then self.palette = index end end
    self:render()
    self.panel:show(true, self.close)
end
function Shelf:update(state)
    self.state = state
    if not self.root.Visible then return end
    local m = state.music
    local entries = if self.section == "Sections" then m.library.sequences elseif self.section == "Drafts" then m.library.drafts
        elseif self.section == "Finished" then m.finishedSongs else state.records.releases
    for _, item in entries do
        if item.id == self.item.id then self.item = item; self:render(); return end
    end
    self.panel:show(false)
end
function Shelf:render()
    local item, p = self.item, self.panel
    if not item or not self.state.records then return end
    local released = self.section == "Releases"
    self.heading.Text = (item.title or item.name) .. "\n" .. item.type .. (if released then " / RELEASE v1" else "")
    local saved = released or self.section == "Finished" or item.savedRevision == item.revision
    self.detail.Text = Panel.credits(item) .. "\nPACK / " .. (item.packLabel or "Unavailable")
        .. "\n" .. (if self.state.saving then "SAVE IN PROGRESS" elseif saved then Panel.storage(self.state.saveMode) else "UNSAVED EDITS / save explicitly")
    if released then self.detail.Text ..= "\nCAPTURED FROM / " .. item.type .. " revision " .. item.source.revision end
    self.notice.Text = self.state.notice or ""
    self.versions.Visible = not released and self.section ~= "Finished" and self.state.music.unverifiedVersions == true
    Panel.enable(self.versions, not self.state.saving)
    if self.versions.Visible then self.notice.Text ..= "\nHistoric pack versions were not recorded. IDs and notes are preserved; choose current versions explicitly to play this workspace." end
    self.continue.Visible = not released
    self.continue.Text = if self.section == "Finished" then "PLAY FULL FINISHED SONG" else "CONTINUE " .. string.upper(item.type)
    self.keepCover.Visible = self.section == "Sections" or self.section == "Drafts"
    Panel.enable(self.keepCover, not self.state.saving)
    for _, control in { self.motifButton, self.paletteButton, self.listenOnly, self.remixable } do
        control.Visible = not released
        Panel.enable(control, not self.state.saving)
    end
    self.motifButton.Text = "COVER LAYOUT / " .. Activities.Motifs[self.motif].label
    self.paletteButton.Text = "COVER COLOUR / " .. Activities.Palettes[self.palette].label
    self.sleeve:update(if released then item.cover else { motif = Activities.Motifs[self.motif].id, palette = Activities.Palettes[self.palette].id })
    for _, control in { self.permission, self.player, self.invite } do control.Visible = released end
    self.permission.Text = (if item.allowRemix then "ALLOW REMIX / CHANGE TO LISTEN ONLY" else "LISTEN ONLY / ALLOW FUTURE REMIX COPIES")
    Panel.enable(self.permission, not self.state.saving)
    local players = self.state.records.players
    self.recipient = math.clamp(self.recipient, 1, math.max(1, #players))
    self.player.Text = if players[self.recipient] then "INVITE PLAYER / " .. players[self.recipient].name .. " / CHANGE" else "NO OTHER PLAYERS IN THIS SERVER"
    Panel.enable(self.player, #players > 0)
    Panel.enable(self.invite, #players > 0 and not self.state.saving)
    self.explanation.Text = if released
        then "Permission affects future remix copies. Copies already created keep their music and credits. Invitations start no audio until accepted."
        else "Keep a personal sleeve, then Save explicitly; Undo remains available. Release saves an exact musical copy and this sleeve. Later edits keep that release unchanged. Pattern/Loop and Draft Song stay unfinished; release does not Finish a Song."
    if item.localOnly then self.explanation.Text ..= "\nLOCAL AUDIO / listening review pending." end
end
return Shelf
