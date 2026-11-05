-- One optional prompt over the ordinary project/editor and saved-release systems.
local Panel = require(script.Parent.RecordPanel)
local View = {}
View.__index = View
function View.new(parent, callbacks)
    local self = setmetatable({ callbacks = callbacks }, View)
    local p = Panel.new(parent, "SameCrateChallenge", 45)
    self.panel, self.root = p, p.root
    self.title, self.prompt, self.status = p:label("ChallengeTitle", 18), p:label("ChallengePrompt"), p:label("ChallengeStatus")
    self.title.Text = "SAME CRATE, DIFFERENT BEAT"
    self.prompt.Text = "A quiet dock wakes up. Choose from these six harbour sounds at 174 BPM. Make four quiet bars and four contrasting arrival bars. Start blank or change either example. There is no timer, winner or artistic-quality score."
    self.palette = {}
    for index = 1, 6 do
        self.palette[index] = p:button("CrateSound" .. index, "", function()
            local item = self.state.challenge.review.palette[index]
            if item and callbacks.selectPad then callbacks.selectPad(item.pad) end
            p:show(false)
            callbacks.page("Sequence")
        end)
    end
    self.blank = p:button("StartBlankCrate", "START BLANK / KEEP CURRENT WORK IN IMPORTS", function() self:start("blank") end)
    self.steady = p:button("StartSteadyCrate", "TRY EXAMPLE / STEADY ARRIVAL", function() self:start("steady") end)
    self.offbeat = p:button("StartOffbeatCrate", "TRY EXAMPLE / OFFBEAT FERRY", function() self:start("offbeat") end)
    self.quiet = p:button("EditQuietSection", "CONTINUE QUIET SECTION", function() self:edit("quietId") end)
    self.arrival = p:button("EditArrivalSection", "CONTINUE ARRIVAL SECTION", function() self:edit("arrivalId") end)
    self.song = p:button("EditCrateSong", "OPEN ORDINARY SONG DRAFT", function()
        callbacks.command("SongSelect", self.state.challenge.review.draftId)
        p:show(false); callbacks.page("Song")
    end)
    self.preview = p:button("PreviewCrateToEnd", "PREVIEW MY DRAFT TO ITS END", function() self:command("ChallengePreview") end)
    self.stop = p:button("StopCratePreview", "STOP THIS PREVIEW", function() callbacks.command("ChallengeStop") end)
    self.review = p:button("ReviewCrateRequirements", "CHECK THE PROMPT", function() self:command("ChallengeReview") end)
    self.present = p:button("PresentCrateSpotlight", "PREPARE SHORT COURTYARD SHOW / START BY CHOICE", function()
        self:command("ChallengePresent"); p:show(false)
    end)
    self.compare = p:button("CompareCrateRecords", "COMPARE WITH A FRIEND / OPEN RELEASES", function()
        p:show(false); callbacks.compare()
    end)
    self.note = p:label("ChallengeScope")
    self.note.Text = "Your music stays a Pattern/Loop or Draft Song until you deliberately Finish it. Save explicitly. A full valid preview earns one bounded participation recognition; retries and audience reactions earn no extra points. Compare by releasing an exact copy and inviting a listener; no audio or invitation is automatic."
    self.close = p:button("CloseCrateChallenge", "CLOSE / KEEP MY WORK", function() p:show(false) end)
    return self
end
function View:command(action)
    self.callbacks.command(action, { context = self.state.challenge.context })
end
function View:start(mode)
    self.callbacks.command("ChallengeStart", { mode = mode, context = self.state.challenge.context })
end
function View:edit(key)
    self.callbacks.command("SequenceSelect", self.state.challenge.review[key])
    self.panel:show(false); self.callbacks.page("Sequence")
end
function View:open(state)
    self:update(state)
    self.panel:show(true, self.close)
end
function View:update(state)
    self.state = state
    local challenge = state and state.challenge
    if not challenge then self.panel:show(false); return end
    local review = challenge.review
    local lines = { state.notice or "", if challenge.recognized then "PARTICIPATION RECOGNIZED / one time / "
        .. (if challenge.recognitionSaved then "SAVE ACKNOWLEDGED" else "UNSAVED / SAVE EXPLICITLY")
        elseif challenge.previewCompleteExact then "THIS VERSION REACHED ITS END" elseif challenge.previewing then "PREVIEWING THIS EXACT DRAFT"
        else "Create, listen, change, save when ready." }
    if review.present then
        for _, check in review.checks or {} do
            table.insert(lines, (if check.ok then "READY / " else "TRY / ") .. check.label .. (if check.ok then "" else " / " .. check.fix))
        end
    end
    if state.saveMode == "session" then table.insert(lines, "Saves last for this Studio session only.") end
    self.status.Text = table.concat(lines, "\n")
    local allReady = true
    for index, button in self.palette do
        local item = review.palette[index]
        button.Text = if item then item.address .. " / " .. item.label .. (if item.ready then " / AVAILABLE" else " / UNAVAILABLE") else "MISSING CRATE IDENTITY"
        Panel.enable(button, item ~= nil and review.present)
        allReady = allReady and item ~= nil and item.ready
    end
    for _, button in { self.quiet, self.arrival, self.song, self.preview, self.review } do
        button.Visible = review.present
        Panel.enable(button, review.present and not state.saving)
    end
    self.stop.Visible = challenge.previewing == true
    self.present.Visible = review.present
    Panel.enable(self.present, review.passed == true and not state.saving)
    Panel.enable(self.blank, not state.saving)
    Panel.enable(self.steady, not state.saving and allReady)
    Panel.enable(self.offbeat, not state.saving and allReady)
end
return View
