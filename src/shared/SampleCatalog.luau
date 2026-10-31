-- Planned program-pad identities and admitted audio have deliberately separate states.
local Plan = require(script.Parent.FirstPackSlots)
local ContentIds = require(script.Parent.ContentIds)
local LocalContent = require(script.Parent.LocalContent)
local StudioRoles = require(script.Parent.StudioLocalMusicRoles)
local RunService = game:GetService("RunService")
local Catalog = {
    List = {},
    ById = {},
    DefaultPadIds = {},
    Packs = {},
    PackById = {},
    PlannedPacks = {},
    RetiredById = {},
    ByDiscoveryId = {},
    ByRole = {},
    LocalPacks = {},
    LocalPackById = {},
    LocalDiscoveryById = {},
    LocalDiscoveryBindings = {},
    LocalRoleById = {},
    BankLabels = {},
    PlannedDiscoveryBindings = Plan.discoveryRoleBindings or {},
}
for _, bank in Plan.banks or {} do
    Catalog.BankLabels[bank.id] = bank.label
end
local keys =
    { "One", "Two", "Three", "Four", "Q", "W", "E", "R", "A", "S", "D", "F", "Z", "X", "C", "V" }
for _, row in Plan.slots do
    local admission = Plan.admitted[row.sample_id]
    local preview = Plan.previews and Plan.previews[row.sample_id]
    local sample = {
        id = row.sample_id,
        label = row.label,
        key = keys[row.pad],
        pack = Plan.packId,
        bank = row.bank,
        pad = row.pad,
        absolutePad = row.absolute_pad,
        address = row.address,
        category = row.category,
        discovery = row.discovery_id,
        semanticRole = row.semantic_role,
        plannedPitch = row.planned_pitch,
        plannedChokeGroup = row.planned_choke_group,
        status = if admission
            then "admitted"
            elseif preview then "local_preview_pending_listening"
            else "pending_audio",
        audioApproved = admission ~= nil and admission.audio_approved == true,
        runtimeAdmitted = admission ~= nil and admission.runtime_admitted == true,
        chokeGroup = if admission
            then admission.choke_group
            elseif preview then row.planned_choke_group
            else nil,
        previewStatus = preview and preview.preview_status,
        previewSourceLabel = preview and preview.source_label,
        listeningReview = preview and preview.listening_review,
        technicalLocalReady = preview and preview.technical_local_ready == true,
        sourceKind = preview and preview.source_kind,
    }
    Catalog.List[row.absolute_pad] = sample
    Catalog.DefaultPadIds[row.absolute_pad] = sample.id
    Catalog.ById[sample.id] = sample
    if sample.discovery then
        Catalog.ByDiscoveryId[sample.discovery] = sample
    end
    if sample.semanticRole then
        Catalog.ByRole[sample.semanticRole] = sample
    end
end
for _, sample in require(script.Parent.RetiredSamples) do
    Catalog.RetiredById[sample.id] = sample
end
local aliases = Plan.roleBindings or {}
for role, id in aliases do
    Catalog.ByRole[role] = Catalog.ById[id]
end
Catalog.PlannedPack = {
    id = Plan.packId,
    label = "Harbour Pulse",
    key = "D natural minor",
    bpm = 174,
    samples = Catalog.List,
    planned = true,
    ready = false,
    selectable = false,
    banks = Plan.banks,
    mappingRevision = Plan.mappingRevision,
}
Catalog.PlannedPacks = { Catalog.PlannedPack }

function Catalog.isUnlocked(id, unlocked)
    local sample = Catalog.ById[id]
    return sample ~= nil
        and (
            sample.discovery == nil
            or (type(unlocked) == "table" and unlocked[sample.discovery] == true)
        )
end

function Catalog.isReady(id, unlocked)
    local sample = Catalog.ById[id]
    if not sample or not sample.audioApproved or not sample.runtimeAdmitted then
        return false
    end
    if unlocked ~= nil and not Catalog.isUnlocked(id, unlocked) then
        return false
    end
    local remote = ContentIds.Audio[id]
    if type(remote) == "number" and remote > 0 then
        return true
    end
    local localUri = LocalContent.Audio[id]
    return RunService:IsStudio() and type(localUri) == "string" and localUri ~= ""
end
Catalog.isPlayable = Catalog.isReady

-- Local technical playback has no bearing on approved musical readiness.
-- The same Studio-only source may be auditioned, saved in a Finished Song and
-- performed locally without changing its pending human listening review.
function Catalog.isPreviewAvailable(id, unlocked)
    local sample = Catalog.ById[id]
    local preview = Plan.previews and Plan.previews[id]
    if
        not RunService:IsStudio()
        or not sample
        or not preview
        or preview.audio_approved ~= false
        or preview.runtime_admitted ~= false
        or preview.listening_review ~= "pending"
        or preview.technical_local_ready ~= true
    then
        return false
    end
    if unlocked ~= nil and not Catalog.isUnlocked(id, unlocked) then
        return false
    end
    local uri = LocalContent.PreviewAudio and LocalContent.PreviewAudio[id]
    return type(uri) == "string" and uri ~= ""
end

function Catalog.isPlaybackReady(id, unlocked)
    if Catalog.isReady(id, unlocked) then
        return true
    end
    if not Catalog.isPreviewAvailable(id, unlocked) then
        return false
    end
    local uri = LocalContent.PreviewAudio[id]
    return uri:match("^rbxasset://needle%-quay/preview%-audio/") ~= nil
end
Catalog.isLocallyPlayable = Catalog.isPlaybackReady

-- Explicit substitutes keep the authored discovery IDs usable in the local
-- demo. They neither relabel the canonical source nor lock the free native kit.
-- ByDiscoveryId and sample.discovery retain approved discovery-binding truth.
if RunService:IsStudio() then
    for _, binding in StudioRoles.bindings or {} do
        local sample = Catalog.ById[binding.sample_id]
        if
            sample
            and binding.audio_approved == false
            and binding.runtime_admitted == false
            and binding.recording_equivalence == false
            and binding.listening_review == "pending"
            and Catalog.isPlaybackReady(sample.id)
        then
            sample.localDiscovery = binding.discovery_id
            sample.localDiscoveryLabel = (binding.gameplay_label or binding.label)
                .. " / "
                .. binding.address
            sample.sourceSubstitute = true
            sample.sourceSubstituteLabel = binding.label
            Catalog.LocalDiscoveryById[binding.discovery_id] = sample
            Catalog.LocalDiscoveryBindings[binding.discovery_id] = binding
            Catalog.LocalRoleById[binding.role] = sample
        end
    end
    for role, id in StudioRoles.lesson_roles or {} do
        if Catalog.isPlaybackReady(id) then
            Catalog.LocalRoleById[role] = Catalog.ById[id]
        end
    end
end

function Catalog.discoveryFor(id)
    return Catalog.ByDiscoveryId[id] or Catalog.LocalDiscoveryById[id]
end

function Catalog.discoveryLabel(id, fallback)
    local sample = Catalog.discoveryFor(id)
    return if sample and sample.localDiscovery
        then sample.localDiscoveryLabel
        else fallback or (sample and sample.label) or id
end

function Catalog.localDiscoveryText(value)
    if type(value) ~= "string" then
        return value
    end
    for _, binding in Catalog.LocalDiscoveryBindings do
        value = value:gsub(binding.substitute_for, function()
            return (binding.gameplay_label or binding.label) .. " / " .. binding.address
        end)
    end
    return value
end

function Catalog.plannedForRole(role)
    return Catalog.ByRole[role] or Catalog.ByDiscoveryId[role]
end

function Catalog.sampleForRole(role, unlocked)
    local sample = Catalog.plannedForRole(role) or Catalog.LocalRoleById[role]
    return if sample and Catalog.isPlaybackReady(sample.id, unlocked) then sample.id else nil
end
Catalog.resolveRole = Catalog.sampleForRole

function Catalog.label(id)
    local active = Catalog.ById[id]
    if active then
        return active.label
    end
    local retired = Catalog.RetiredById[id]
    return if retired then retired.label .. " / unavailable" else "Unavailable sound"
end

function Catalog.packFor(id)
    local sample = Catalog.ById[id]
    return if sample then Catalog.PackById[sample.pack] else nil
end

-- A pack enters the selectable roster only when all 64 actual samples are ready.
local complete = #Catalog.List == 64
for _, sample in Catalog.List do
    if not Catalog.isReady(sample.id) then
        complete = false
        break
    end
end
if complete then
    local pack = table.clone(Catalog.PlannedPack)
    pack.planned, pack.ready, pack.selectable = false, true, true
    Catalog.Packs = { pack }
    Catalog.PackById[pack.id] = pack
end
local locallyComplete = #Catalog.List == 64
for _, sample in Catalog.List do
    if not Catalog.isLocallyPlayable(sample.id) then
        locallyComplete = false
        break
    end
end
if RunService:IsStudio() and locallyComplete then
    local pack = table.clone(Catalog.PlannedPack)
    pack.localOnly, pack.technicalLocalReady, pack.localSelectable = true, true, true
    pack.listeningReview, pack.audioApproved = "pending", false
    Catalog.LocalPack = pack
    Catalog.LocalPacks, Catalog.LocalPackById = { pack }, { [pack.id] = pack }
end
return Catalog
