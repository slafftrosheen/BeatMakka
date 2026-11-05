-- One optional prompt over the ordinary project/editor and saved-release systems.
local Panel = require(script.Parent.RecordPanel)
local VisualSteps = require(script.Parent.VisualSteps)
local Gui = require(script.Parent.GuiFactory)
local Theme = require(game.ReplicatedStorage.Shared.Theme)
local View = {}
View.__index = View
function View.new(parent, callbacks)
    local self = setmetatable({ callbacks = callbacks }, View)
    local p = Panel.new(parent, "SameCrateChallenge", 45)
    self.panel, self.root = p, p.root
    self.title, self.prompt = p:label("ChallengeTitle", 18), p:label("ChallengePrompt")
    self.title.Text = "SAME CRATE, DIFFERENT BEAT"
    self.prompt.Text = "A quiet dock wakes up. Six sounds. 174 BPM. Four quiet bars, then four arrival bars. Take your time."
    local guide = p:add("Frame", { Name = "ChallengeSteps", BackgroundTransparency = 1, Size = UDim2.new(1, -8, 0, 56) })
    self.steps = VisualSteps.new(guide, { { "SOUNDS", "pads" }, { "BUILD", "steps" }, { "LISTEN", "play" }, { "SHARE", "people" } }, p.z + 3)
    self.status = p:label("ChallengeStatus")
    local sections = p:add("Frame", { Name = "ChallengeContrast", BackgroundTransparency = 1, Size = UDim2.new(1, -8, 0, 80) })
    self.sections = {}
    for index, name in { "QUIET", "ARRIVAL" } do
        local part = Gui.make("Frame", sections, { Name = name, Position = UDim2.fromScale((index - 1) / 2, 0),
            Size = UDim2.new(0.5, -6, 1, 0), BackgroundTransparency = 1, ZIndex = p.z + 3 })
        local text = Gui.label(part, "", 12, Theme.Cream)
        text.Font, text.Size, text.ZIndex = Enum.Font.Code, UDim2.new(1, 0, 0, 54), p.z + 4
        for bar = 1, 4 do
            Gui.make("Frame", part, { Name = "Bar" .. bar, Position = UDim2.new((bar - 1) / 4, 0, 0, 64),
                Size = UDim2.new(0.25, -4, 0, 6), BackgroundColor3 = if index == 1 then Theme.FadedTeal else Theme.Amber,
                BorderSizePixel = 0, ZIndex = p.z + 4 })
        end
        self.sections[index] = text
    end
    self.palette = {}
    for index = 1, 6 do
        self.palette[index] = p:button("CrateSound" .. index, "", function()
            local item = self.state.challenge.review.palette[index]
            if item and callbacks.selectPad then callbacks.selectPad(item.pad) end
            p:show(false)
            callbacks.page("Sequence")
        end)
    end
    self.blank = p:button("StartBlankCrate", "START BLANK / ARCHIVE CURRENT WORK", function() self:start("blank") end)
    self.steady = p:button("StartSteadyCrate", "EXAMPLE / STEADY ARRIVAL", function() self:start("steady") end)
    self.offbeat = p:button("StartOffbeatCrate", "EXAMPLE / OFFBEAT FERRY", function() self:start("offbeat") end)
    self.quiet = p:button("EditQuietSection", "CONTINUE QUIET SECTION", function() self:edit("quietId") end)
    self.arrival = p:button("EditArrivalSection", "CONTINUE ARRIVAL SECTION", function() self:edit("arrivalId") end)
    self.song = p:button("EditCrateSong", "OPEN ORDINARY SONG DRAFT", function()
        callbacks.command("SongSelect", self.state.challenge.review.draftId)
        p:show(false); callbacks.page("Song")
    end)
    self.preview = p:button("PreviewCrateToEnd", "LISTEN FROM START TO END", function() self:command("ChallengePreview") end)
    self.stop = p:button("StopCratePreview", "STOP THIS PREVIEW", function() callbacks.command("ChallengeStop") end)
    self.review = p:button("ReviewCrateRequirements", "PROMPT CHECKLIST", function()
        self.detailsOpen = not self.detailsOpen
        self:update(self.state)
        if self.detailsOpen then self:command("ChallengeReview") end
    end)
    self.checklist = p:label("ChallengeChecklist")
    self.checklist.Visible = false
    self.present = p:button("PresentCrateSpotlight", "PREPARE A SHORT SHOW", function()
        self:command("ChallengePresent"); p:show(false)
    end)
    self.compare = p:button("CompareCrateRecords", "COMPARE / OPEN RELEASES", function()
        p:show(false); callbacks.compare()
    end)
    self.note = p:label("ChallengeScope")
    self.note.Text = "Save your Draft. Finish makes a Song. A full valid preview earns participation once; retries add no XP. A show starts by choice. Compare by releasing a copy and inviting a friend."
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
    self.steps:update(if challenge.previewing then 3 elseif challenge.previewCompleteExact then 4
        elseif review.passed then 3 elseif review.present then 2 else 1)
    self.sections[1].Text = "QUIET / 4 BARS\n" .. (review.quietSamples or 0) .. " / 1–2 SOUNDS"
    self.sections[2].Text = "ARRIVAL / 4 BARS\n" .. (review.arrivalSamples or 0) .. " / 3+ SOUNDS"
    local lines = { state.notice or "", if challenge.recognized then "PARTICIPATION / "
        .. (if challenge.recognitionSaved then "SAVE ACKNOWLEDGED" else "UNSAVED / SAVE EXPLICITLY")
        elseif challenge.previewCompleteExact then "THIS VERSION REACHED ITS END" elseif challenge.previewing then "PREVIEWING THIS EXACT DRAFT"
        else if review.present then review.hint else "Choose blank or an editable example." }
    local checks = {}
    if self.detailsOpen and review.present then
        for _, check in review.checks or {} do
            table.insert(checks, (if check.ok then "READY / " else "TRY / ") .. check.label .. (if check.ok then "" else " / " .. check.fix))
        end
    end
    self.checklist.Text, self.checklist.Visible = table.concat(checks, "\n"), self.detailsOpen == true and review.present
    self.review.Text = if self.detailsOpen then "HIDE CHECKLIST" else "PROMPT CHECKLIST"
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
