-- Fixed duet channel strips and a paged guide, with one shared jam clock.
local W = require(script.Parent.DeviceWidgets)
local Digital = require(script.Parent.DigitalDisplay)
local GuiService = game:GetService("GuiService")
local TextService = game:GetService("TextService")
local Input = game:GetService("UserInputService")
local View = {}
View.__index = View
local Dim = Color3.fromRGB(112, 145, 117)
local function caption(key, value)
    W.set(key.Legend, "Text", value)
    W.set(key, "Text", value)
    key.TextTransparency = 1
    key:SetAttribute("AccessibleLabel", value)
end
local function label(parent, name, value, size, color)
    local item = W.label(parent, name, value, size, color)
    item.TextWrapped = false
    item.TextTruncate = Enum.TextTruncate.AtEnd
    return item
end
local function paginate(lines, width, height, size)
    local pages, current = {}, ""
    for _, paragraph in lines do
        local first = true
        for word in paragraph:gmatch("%S+") do
            local separator = if current == "" then "" elseif first then "\n" else " "
            local candidate = current .. separator .. word
            local bounds = TextService:GetTextSize(
                candidate,
                size,
                Enum.Font.Code,
                Vector2.new(math.max(1, width), 100000)
            )
            if current ~= "" and bounds.Y > height then
                table.insert(pages, current)
                current = word
            else
                current = candidate
            end
            first = false
        end
    end
    table.insert(pages, current)
    return pages
end
function View.new(screen, command, mute)
    local self = setmetatable({ page = "session", channels = {}, connections = {} }, View)
    self.panel = W.frame(screen, "TwoPlayerJam", Color3.fromRGB(29, 48, 40))
    self.panel.AnchorPoint, self.panel.Position = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5)
    self.panel.Size, self.panel.Visible, self.panel.ZIndex = UDim2.new(1, -24, 1, -24), false, 20
    self.panel.ClipsDescendants = true
    W.make("UISizeConstraint", self.panel, { MaxSize = Vector2.new(960, 660) })
    W.make("UIStroke", self.panel, { Color = Dim, Thickness = 2 })
    self.heading = label(self.panel, "JamTitle", "QUAY / TWO PLAYER JAM", 16, W.amber)
    self.tempo = Digital.new(self.panel)
    W.make("UIScale", self.tempo.root, { Scale = 0.55 })
    self.tempoLabel = label(self.panel, "SharedTempo", "BPM", 11, W.amber)
    self.info = W.key(self.panel, "JamInfo", "hint", "PARTNER", function()
        self.copyConfirmation = nil
        self.page = if self.page == "session" then "partner"
            elseif self.page == "partner" then "info" else "session"
        self:paint()
    end)
    self.body = W.frame(self.panel, "Actions", W.ink)
    self.body.ClipsDescendants = true
    W.make("UIStroke", self.body, { Color = Color3.fromRGB(62, 90, 70), Thickness = 1 })
    self.channelPage = W.frame(self.body, "DuetChannelStrips")
    self.channelPage.Size = UDim2.fromScale(1, 1)
    self.partnerPage = W.make("ScrollingFrame", self.body, {
        Name = "JamInvitations", BackgroundTransparency = 1, BorderSizePixel = 0,
        CanvasSize = UDim2.fromOffset(0, 0), ScrollBarThickness = 4,
        ScrollingDirection = Enum.ScrollingDirection.Y,
    })
    for slot = 1, 2 do
        local channel = {}
        channel.root = W.frame(self.channelPage, "Player" .. slot, Color3.fromRGB(27, 51, 41))
        W.make("UIStroke", channel.root, { Color = Color3.fromRGB(59, 84, 66), Thickness = 1 })
        channel.number =
            label(channel.root, "PlayerNumber", string.format("PLAYER %02d", slot), 11, W.amber)
        channel.name = label(channel.root, "PlayerName", "OPEN SEAT", 16, W.text)
        channel.source = label(channel.root, "PinnedSequence", "BRING YOUR OWN SECTION", 11, Dim)
        channel.status = label(channel.root, "SnapshotStatus", "WAITING", 10, Dim)
        channel.lamp = W.line(channel.root, "PendingLight", Dim)
        W.make("UICorner", channel.lamp, { CornerRadius = UDim.new(1, 0) })
        self.channels[slot] = channel
    end
    self.label = W.label(self.body, "JamGuide", "", 12, W.text)
    self.label.TextYAlignment, self.label.TextTruncate =
        Enum.TextYAlignment.Top, Enum.TextTruncate.AtEnd
    self.label.Visible = false
    self.infoPageIndex = 1
    self.infoPrevious = W.key(self.body, "PreviousInfoPage", "undo", "BACK", function()
        self.infoPageIndex = math.max(1, self.infoPageIndex - 1)
        self:paintInfo()
    end)
    self.infoNext = W.key(self.body, "NextInfoPage", "redo", "MORE", function()
        self.infoPageIndex += 1
        self:paintInfo()
    end)
    self.infoCounter = label(self.body, "InfoPageCount", "1 / 1", 11, Dim)
    self.infoCounter.TextXAlignment = Enum.TextXAlignment.Center
    self.partnerIntro = W.label(self.partnerPage, "PartnerInfo",
        "Two separate owners. Nothing joins without an invitation.", 12, W.text)
    self.partnerIntro.TextWrapped = true
    self.copyStatus = W.label(self.partnerPage, "JointCopyStatus",
        "JOINT COPY / both contributors consent. No audio file or autosave.", 12, W.amber)
    self.copyStatus.TextWrapped = true
    local function partnerKey(name, title, callback)
        local button = W.key(self.partnerPage, name, "people", title, callback)
        button:SetAttribute("JamPartnerAction", true)
        return button
    end
    self.roleChoice = partnerKey("ChooseMusicRole", "ROLE / RHYTHM", function()
        local jam = self.jam or {}
        command("JamRole", if jam.preferredRole == "rhythm" then "hook" else "rhythm")
    end)
    self.candidate = partnerKey("ChooseInvitee", "CHOOSE MUSICIAN", function()
        local candidates = (self.jam and self.jam.candidates) or {}
        if #candidates > 0 then
            self.candidateIndex = ((self.candidateIndex or 1) % #candidates) + 1
            self:paint()
        end
    end)
    self.invite = partnerKey("SendInvite", "INVITE", function()
        local candidates = (self.jam and self.jam.candidates) or {}
        local player = candidates[self.candidateIndex or 1]
        if player then command("JamInvite", player.userId) end
    end)
    self.accept = partnerKey("AcceptInvite", "ACCEPT INVITE", function()
        command("JamAccept")
    end)
    self.decline = partnerKey("DeclineInvite", "DECLINE", function()
        command("JamDecline")
    end)
    self.leadOffer = partnerKey("OfferConductor", "PASS LEAD", function()
        command("JamLeadOffer")
    end)
    self.leadAccept = partnerKey("AcceptConductor", "ACCEPT LEAD", function()
        command("JamLeadAccept")
    end)
    self.leadDecline = partnerKey("DeclineConductor", "DECLINE LEAD", function()
        command("JamLeadDecline")
    end)
    self.swapOffer = partnerKey("OfferRoleExchange", "EXCHANGE ROLES", function()
        command("JamSwapOffer")
    end)
    self.swapAccept = partnerKey("AcceptRoleExchange", "ACCEPT ROLES", function()
        command("JamSwapAccept")
    end)
    self.swapDecline = partnerKey("DeclineRoleExchange", "KEEP ROLES", function()
        command("JamSwapDecline")
    end)
    self.tempoAccept = partnerKey("AcceptTempo", "ACCEPT BPM", function()
        command("JamTempoAccept")
    end)
    self.tempoDecline = partnerKey("DeclineTempo", "KEEP BPM", function()
        command("JamTempoDecline")
    end)
    self.copyOffer = partnerKey("OfferJointCopy", "OFFER JOINT COPY", function()
        command("JamCopyOffer")
    end)
    self.copyAccept = partnerKey("AcceptJointCopy", "ACCEPT JOINT COPY", function()
        command("JamCopyAccept")
    end)
    self.copyDecline = partnerKey("DeclineJointCopy", "DECLINE COPY", function()
        command("JamCopyDecline")
    end)
    local function confirmCopy(action)
        local take = self.jam and self.jam.copyPending
        if not take or take.imported then return end
        local context = take.context or {}
        local key = action .. ":" .. take.id .. ":" .. tostring(context.projectId)
            .. ":" .. tostring(context.projectRevision) .. ":" .. tostring(context.workspaceGeneration)
            .. ":" .. tostring(context.editVersion)
        local pending = self.copyConfirmation
        if pending and pending.key == key and os.clock() < pending.expiresAt then
            self.copyConfirmation = nil
            command(action, { id = take.id, context = context })
        else
            self.copyConfirmation = { key = key, action = action, expiresAt = os.clock() + 5 }
            self:paint()
        end
    end
    self.copyKeep = partnerKey("KeepJointDraft", "KEEP AS DRAFT", function()
        confirmCopy("JamCopyKeep")
    end)
    self.copyDiscard = partnerKey("DiscardJointCopy", "DISCARD TEMPORARY", function()
        confirmCopy("JamCopyDiscard")
    end)
    self.partnerKeys = { self.roleChoice, self.candidate, self.invite, self.accept,
        self.decline, self.leadOffer, self.leadAccept, self.leadDecline,
        self.swapOffer, self.swapAccept, self.swapDecline, self.tempoAccept, self.tempoDecline,
        self.copyOffer, self.copyAccept, self.copyDecline, self.copyKeep, self.copyDiscard }
    self.noticeLine = label(self.panel, "JamNotice", "", 11, Dim)
    self.keys = W.frame(self.panel, "JamHardwareKeys")
    local function key(name, icon, title, action, value)
        return W.key(self.keys, name, icon, title, function()
            command(action, value)
        end)
    end
    self.join = key("Join", "people", "START JAM", "JamJoin")
    self.publish = key("Publish", "save", "PUBLISH", "JamPublish")
    self.down = key("TempoDown", "undo", "BPM −", "JamTempo", -1)
    self.up = key("TempoUp", "redo", "BPM +", "JamTempo", 1)
    self.leave = key("Leave", "close", "LEAVE JAM", "JamLeave")
    self.mute = W.key(self.panel, "Sound", "sound", "SOUND ON", mute)
    self.close = W.key(self.panel, "Back", "pads", "SAMPLER", function()
        command("JamHide")
    end)
    table.insert(
        self.connections,
        self.panel:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            self:resize()
        end)
    )
    table.insert(self.connections, Input.WindowFocusReleased:Connect(function()
        self.copyConfirmation = nil
    end))
    table.insert(self.connections, Input.TextBoxFocused:Connect(function()
        self.copyConfirmation = nil
    end))
    self.panel.Destroying:Connect(function()
        for _, connection in self.connections do
            connection:Disconnect()
        end
    end)
    self:resize()
    self:paint()
    task.defer(function()
        if self.panel.Parent then
            self:resize()
        end
    end)
    return self
end
function View:paint()
    local jam = self.jam or {}
    local session = jam.session
    self.tempo:set(session and session.bpm or 96)
    self.tempoLabel.Text = if jam.active and jam.conductor then "LEAD BPM" else "SHARED BPM"
    self.tempoLabel:SetAttribute("BPM", session and session.bpm or 96)
    local lines = {
        "TWO PLAYERS / 64-PAD PROGRAMS / ONE SHARED CLOCK",
        "Your project stays yours. Rhythm and Hook/Texture are musical roles, not sample-bank slots.",
        "Start a solo jam; invite a nearby sampler owner. They may accept or decline. The current lead proposes tempo, and the partner must agree.",
    }
    for slot, channel in self.channels do
        local track = session and session.tracks and session.tracks[tostring(slot)]
        local pending = session and session.pending and session.pending[tostring(slot)]
        local source = track and track.snapshot and track.snapshot.title
        W.set(channel.name, "Text", track and track.name or "OPEN SEAT")
        W.set(
            channel.source,
            "Text",
            source or (if track then "PINNED SEQUENCE" else "BRING YOUR OWN SECTION")
        )
        W.set(
            channel.status,
            "Text",
            if pending and pending.remove then "DEPARTING / NEXT BAR"
                elseif pending then "PART QUEUED / NEXT BAR"
                elseif track then "PLAYING / " .. (track.role or "LEGACY")
                else "WAITING FOR A PLAYER"
        )
        W.set(
            channel.lamp,
            "BackgroundColor3",
            if pending then W.amber elseif track then W.text else Dim
        )
        channel.root:SetAttribute("Occupied", track ~= nil)
        channel.root:SetAttribute("Pending", pending ~= nil)
        table.insert(
            lines,
            string.format(
                "PLAYER %d / %s%s%s",
                slot,
                track and track.name or "FREE",
                if source then " / " .. source else "",
                if pending then " / NEXT BAR QUEUED" else ""
            )
        )
    end
    table.insert(
        lines,
        if session
            then string.format(
                "%d BPM / %s",
                session.bpm,
                if jam.conductor then "YOU CONDUCT THE TEMPO" else "YOUR PARTNER CONDUCTS"
            )
            else "Select a named Sequence with available audio, then join."
    )
    if session and session.tempo then
        table.insert(lines, "TEMPO QUEUED / " .. session.tempo.bpm .. " BPM")
    elseif session and session.tempoOffer then
        table.insert(lines, "TEMPO PROPOSED / " .. session.tempoOffer.bpm .. " BPM / ACCEPT IN PARTNER")
    end
    if session and session.leadPending then
        table.insert(lines, "LEAD HANDOVER QUEUED FOR A SHARED BAR.")
    end
    if session and session.roleOffer then
        table.insert(lines, "ROLE EXCHANGE OFFERED / OPEN PARTNER TO ANSWER.")
    end
    table.insert(lines,
        "Edit your own Sequence in the sampler, then Publish only your chosen musical role at the next bar. A-D always selects sample banks.")
    local notice = if self.notice and os.clock() < self.untilAt then self.notice else nil
    if notice then
        table.insert(lines, notice)
    end
    self.infoLines = lines
    W.set(
        self.noticeLine,
        "Text",
        notice
            or (
                if session and session.tempo
                    then "NEXT BAR / " .. session.tempo.bpm .. " BPM QUEUED"
                    elseif jam.active then "EDIT YOUR SECTION → PUBLISH AT THE NEXT BAR"
                    else "SELECT YOUR SECTION IN THE SAMPLER → JOIN"
            )
    )
    self.join.Visible, self.publish.Visible = not jam.active and not jam.hasSession, jam.active == true
    W.legend(self.join, "START JAM")
    self.down.Visible, self.up.Visible =
        jam.active == true and jam.conductor == true, jam.active == true and jam.conductor == true
    self.leave.Visible = jam.active == true
    self.channelPage.Visible, self.label.Visible = self.page == "session", self.page == "info"
    self.partnerPage.Visible = self.page == "partner"
    self.infoPrevious.Visible, self.infoNext.Visible, self.infoCounter.Visible =
        self.page == "info", self.page == "info", self.page == "info"
    caption(self.info, if self.page == "info" then "DUET"
        elseif self.page == "partner" then "INFO" else "PARTNER")
    self.info:SetAttribute("Selected", self.page ~= "session")
    self:paintPartner()
    self:paintInfo()
end
function View:paintPartner()
    local jam = self.jam or {}
    local session = jam.session or {}
    local me = game.Players.LocalPlayer
    local myId = me and me.UserId
    local candidates = jam.candidates or {}
    self.candidateIndex = math.clamp(self.candidateIndex or 1, 1, math.max(1, #candidates))
    local selected = candidates[self.candidateIndex]
    local invite = jam.invitation
    local take = jam.copyPending
    local offer = session.copyOffer
    local hasPartner = session.tracks and session.tracks["1"] and session.tracks["2"]
        and not session.pending["1"] and not session.pending["2"]
    local role = jam.preferredRole or "rhythm"
    local mine = jam.role
    W.set(self.partnerIntro, "Text", if invite then
        invite.from .. " invited you to play " .. string.upper(invite.suggestedRole)
            .. ". Accept by " .. string.format("%ds", math.max(0, math.ceil(invite.expiresAt - workspace:GetServerTimeNow())))
        elseif jam.active then
            "YOUR " .. string.upper(mine or role) .. " / "
                .. (if jam.conductor then "YOU LEAD" else "YOUR PARTNER LEADS")
                .. ". Publishing changes only your pinned role, never the other owner's music."
        else "Pick a musical role, then START JAM. After an invitation, your own notes must contain that role.")
    local credits = {}
    for _, contributor in (take and take.contributors) or {} do
        table.insert(credits, contributor.name .. " (" .. contributor.role .. ")")
    end
    W.set(self.copyStatus, "Text", if take and take.imported then
        "IMPORTED JOINT DRAFT / " .. (if take.inWorkspace then "OPEN SONG TO EDIT & SAVE"
            else "NOT IN CURRENT WORKSPACE / CHECK UNDO OR ARCHIVES")
        elseif take then
            "TEMPORARY JOINT PHRASE / " .. take.bars .. " BARS · " .. take.bpm
                .. " BPM / " .. table.concat(credits, " + ")
                .. "\nSESSION ONLY / leave jam before Keep. This is not saved or finished."
        elseif offer then
            "JOINT COPY OFFER / BOTH CREDITS / accept or decline; no save happens automatically."
        else "JOINT COPY / two consenting musicians. Keep later as an editable Draft; no autosave or publication.")
    caption(self.roleChoice, "NEXT ROLE / " .. string.upper(role))
    caption(self.candidate, if selected then "TO: " .. selected.name else "NO NEARBY MUSICIAN")
    local isGuestOffer = jam.active and not jam.conductor
    local lead = session.leadOffer
    local swap = session.roleOffer
    local tempo = session.tempoOffer
    local function active(button, ok)
        local enabled = ok == true
        button.Visible, button.Active, button.Selectable = enabled, enabled, enabled
    end
    active(self.roleChoice, not jam.active)
    active(self.candidate, jam.conductor and #candidates > 1)
    active(self.invite, jam.conductor and selected ~= nil and not hasPartner)
    active(self.accept, invite ~= nil)
    active(self.decline, invite ~= nil)
    active(self.leadOffer, jam.conductor and hasPartner and not lead and not session.leadPending)
    active(self.leadAccept, isGuestOffer and lead ~= nil and lead.to == myId)
    active(self.leadDecline, isGuestOffer and lead ~= nil and lead.to == myId)
    active(self.swapOffer, jam.active and hasPartner and not swap
        and not session.tempo and not session.leadPending)
    active(self.swapAccept, jam.active and swap ~= nil and swap.to == myId)
    active(self.swapDecline, jam.active and swap ~= nil and swap.to == myId)
    active(self.tempoAccept, isGuestOffer and tempo ~= nil and tempo.to == myId)
    active(self.tempoDecline, isGuestOffer and tempo ~= nil and tempo.to == myId)
    active(self.copyOffer, jam.active and hasPartner and not offer and not take
        and not next(session.pending or {}) and not session.tempo)
    active(self.copyAccept, jam.active and offer ~= nil and offer.to == myId)
    active(self.copyDecline, jam.active and offer ~= nil and offer.to == myId)
    active(self.copyKeep, take ~= nil and not take.imported and not jam.active)
    active(self.copyDiscard, take ~= nil and not take.imported and not jam.active)
    local confirm = self.copyConfirmation
    if confirm then
        local context = take and take.context or {}
        local copyKey = confirm.action .. ":" .. tostring(take and take.id)
            .. ":" .. tostring(context.projectId) .. ":" .. tostring(context.projectRevision)
            .. ":" .. tostring(context.workspaceGeneration) .. ":" .. tostring(context.editVersion)
        if copyKey ~= confirm.key or os.clock() >= confirm.expiresAt then
            self.copyConfirmation = nil
        end
    end
    confirm = self.copyConfirmation
    caption(self.copyKeep, if confirm and confirm.action == "JamCopyKeep"
        then "CONFIRM KEEP / UNSAVED DRAFT" else "KEEP AS DRAFT")
    caption(self.copyDiscard, if confirm and confirm.action == "JamCopyDiscard"
        then "CONFIRM DISCARD / TEMPORARY ONLY" else "DISCARD TEMPORARY")
    if tempo then
        caption(self.tempoAccept, "ACCEPT " .. tostring(tempo.bpm) .. " BPM")
    end
    if self.panel.AbsoluteSize.X > 0 then self:layoutPartner() end
end

function View:layoutPartner()
    local w = math.max(40, self.partnerPage.AbsoluteSize.X - 12)
    local y = 8
    W.place(self.partnerIntro, 4, y, w, 78)
    y += 86
    W.place(self.copyStatus, 4, y, w, 98)
    y += 106
    local paired = w >= 290
    local index = 1
    for _, button in self.partnerKeys do
        if button.Visible then
            local width = if paired then (w - 6) / 2 else w
            local x = if paired then ((index - 1) % 2) * (width + 6) else 0
            W.place(button, x, y, width, 48)
            if not paired or index % 2 == 0 then y += 54 end
            index += 1
        end
    end
    if paired and index % 2 == 0 then y += 54 end
    self.partnerPage.CanvasSize = UDim2.fromOffset(0, y + 6)
end

function View:paintInfo()
    local pages = paginate(
        self.infoLines or {},
        self.label.AbsoluteSize.X,
        math.max(1, self.label.AbsoluteSize.Y),
        self.label.TextSize
    )
    self.infoPageIndex = math.clamp(self.infoPageIndex, 1, #pages)
    W.set(self.label, "Text", pages[self.infoPageIndex])
    W.set(self.infoCounter, "Text", string.format("%d / %d", self.infoPageIndex, #pages))
    self.infoPrevious.Active, self.infoPrevious.Selectable =
        self.infoPageIndex > 1, self.infoPageIndex > 1
    self.infoNext.Active, self.infoNext.Selectable =
        self.infoPageIndex < #pages, self.infoPageIndex < #pages
end
function View:update(jam, muted, notice)
    local wasOpen = self.panel.Visible
    self.jam = jam
    self.panel.Visible = jam ~= nil and jam.open == true
    if wasOpen and not self.panel.Visible then self.copyConfirmation = nil end
    local newInvite = jam and jam.invitation and
        tostring(jam.invitation.generation) .. ":" .. tostring(jam.invitation.fromUserId)
    if newInvite and newInvite ~= self.lastInvite then
        self.page = "partner"
    end
    self.lastInvite = newInvite
    local newCopy = jam and jam.copyPending and jam.copyPending.id
    if newCopy and newCopy ~= self.lastCopy then self.page = "partner" end
    self.lastCopy = newCopy
    if notice then
        self.notice, self.untilAt = notice, os.clock() + 6
    end
    caption(self.mute, if muted then "SOUND MUTED" else "SOUND ON")
    self:paint()
    local selected = GuiService.SelectedObject
    if wasOpen and not self.panel.Visible and selected and selected:IsDescendantOf(self.panel) then
        local station = self.panel.Parent:FindFirstChild("Workstation")
        local navigation = station and station:FindFirstChild("Navigation", true)
        GuiService.SelectedObject = if station
                and station.Visible
                and navigation
            then navigation:FindFirstChild("Sequence")
            else nil
    elseif
        self.panel.Visible
        and (
            not wasOpen
            or (selected and selected:IsDescendantOf(self.panel) and not selected.Visible)
        )
    then
        GuiService.SelectedObject = if jam.invitation then self.accept
            elseif jam.active then self.publish else self.join
    end
end
function View:resize()
    local w, h = self.panel.AbsoluteSize.X, self.panel.AbsoluteSize.Y
    if w <= 0 or h <= 0 then
        return
    end
    local margin, gap = 10, 6
    local footerY, actionY = h - 54, h - 104
    W.place(self.heading, margin, 7, math.max(1, w - 208), 30)
    self.heading.TextSize = if w < 400 then 11 else 16
    W.place(self.tempo.root, w - 190, 7, 114, 48)
    W.place(self.tempoLabel, w - 121, 10, 57, 26)
    self.tempoLabel.TextSize = 9
    W.place(self.info, w - 60, 5, 50, 36)
    local bw, bh = w - margin * 2, math.max(1, actionY - 72)
    W.place(self.body, margin, 46, bw, bh)
    W.place(self.partnerPage, 0, 0, bw, bh)
    if (self.partnerWidth and self.partnerWidth ~= bw)
        or (self.partnerHeight and self.partnerHeight ~= bh) then
        self.copyConfirmation = nil
    end
    self.partnerWidth, self.partnerHeight = bw, bh
    local vertical = w < 450 and bh >= 170
    local cw, ch =
        if vertical then bw - 12 else (bw - 18) / 2, if vertical then (bh - 18) / 2 else bh - 12
    for slot, channel in self.channels do
        W.place(
            channel.root,
            if vertical then 6 else 6 + (slot - 1) * (cw + 6),
            if vertical then 6 + (slot - 1) * (ch + 6) else 6,
            cw,
            ch
        )
        W.place(channel.number, 8, 5, cw - 24, 15)
        W.place(channel.lamp, cw - 14, 9, 5, 5)
        W.place(channel.name, 8, 23, cw - 16, if ch < 100 then 21 else 30)
        W.place(channel.source, 8, if ch < 100 then 46 else 59, cw - 16, 17)
        W.place(channel.status, 8, ch - 22, cw - 16, 17)
        channel.name.TextSize = if cw < 200 then 12 else 16
        channel.source.Visible = ch >= 93
        channel.status.Visible = ch >= 60
    end
    local compactInfo = bh < 90
    local infoNavHeight = if compactInfo then 22 else 40
    local infoNavY = bh - infoNavHeight - (if compactInfo then 2 else 6)
    local infoTextY = if compactInfo then 1 else 6
    W.place(self.label, 8, infoTextY, bw - 16, math.max(1, infoNavY - infoTextY - 2))
    self.label.TextSize = if h < 330 then 10 else 12
    W.place(self.infoPrevious, 6, infoNavY, 58, infoNavHeight)
    W.place(self.infoNext, bw - 64, infoNavY, 58, infoNavHeight)
    W.place(self.infoCounter, 68, infoNavY, bw - 136, infoNavHeight)
    for _, key in { self.infoPrevious, self.infoNext } do
        key.Glyph.Visible = not compactInfo
        key.Legend.Position = if compactInfo then UDim2.fromScale(0, 0) else UDim2.fromOffset(2, 24)
        key.Legend.Size = if compactInfo then UDim2.fromScale(1, 1) else UDim2.new(1, -4, 1, -25)
    end
    W.place(self.noticeLine, margin, actionY - 22, w - margin * 2, 18)
    W.place(self.keys, margin, actionY, w - margin * 2, 44)
    local keyWidth = (w - margin * 2 - gap * 3) / 4
    W.place(self.join, 0, 0, keyWidth, 44)
    W.place(self.publish, 0, 0, keyWidth, 44)
    W.place(self.down, keyWidth + gap, 0, keyWidth, 44)
    W.place(self.up, (keyWidth + gap) * 2, 0, keyWidth, 44)
    W.place(self.leave, (keyWidth + gap) * 3, 0, keyWidth, 44)
    W.place(self.mute, margin, footerY, (w - margin * 2 - gap) / 2, 44)
    W.place(self.close, (w + gap) / 2, footerY, (w - margin * 2 - gap) / 2, 44)
    self:paintPartner()
    self:paintInfo()
end
return View
