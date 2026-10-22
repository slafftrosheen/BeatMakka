-- Explicitly approved private upload batch: 32 mesh parts + 14 shared images.
-- __UPLOAD_SPEC__ is inserted from a local request. No automatic submission retry.
local spec = __UPLOAD_SPEC__
assert(game.PlaceId == 0, "Private import staging is the unpublished review place")
local assetService = game:GetService("AssetService")
local storage = game:GetService("ServerStorage")
local receipts = storage:FindFirstChild("AssetUploadReceipts") or Instance.new("Folder")
receipts.Name = "AssetUploadReceipts"
receipts.Parent = storage
local key = spec.key
local receipt = receipts:FindFirstChild(key)
if receipt then
    assert(receipt:GetAttribute("Status") == "Complete", "Submission already attempted; reconcile before resubmitting " .. key)
    return game:GetService("HttpService"):JSONEncode({key=key,assetId=receipt.Value,reused=true})
end
receipt = Instance.new("NumberValue")
receipt.Name = key
receipt:SetAttribute("Status", "Prepared")
receipt.Parent = receipts
local object
if spec.kind == "mesh" then
    local root = storage.AssetLibrary:FindFirstChild(spec.id)
    assert(root, "Missing library model")
    local part = root:FindFirstChild(spec.part, true)
    assert(part and part:IsA("MeshPart"), "Missing mesh part")
    object = assetService:CreateEditableMeshAsync(part.MeshContent, { FixedSize = true })
else
    local rs = game:GetService("ReplicatedStorage")
    local template = if spec.graphic then rs.UiImageLibrary:FindFirstChild(spec.template)
        else rs.AppearanceLibrary:FindFirstChild(spec.template)
    assert(template, "Missing image template")
    object = assetService:CreateEditableImageAsync(template[spec.property])
end
assert(object, "Could not read authored source content")
receipt:SetAttribute("Status", "Submitted")
receipt:SetAttribute("Source", spec.source)
local ok, result, assetId = pcall(function()
    return assetService:CreateAssetAsync(object, if spec.kind == "mesh" then Enum.AssetType.Mesh else Enum.AssetType.Image, {
        CreatorId = game:GetService("StudioService"):GetUserId(),
        CreatorType = Enum.AssetCreatorType.User,
        Name = spec.name,
        Description = "Frequency Zero / BeatMakka. Original project asset. " .. spec.source,
    })
end)
object:Destroy()
if not ok or result ~= Enum.CreateAssetResult.Success then
    receipt:SetAttribute("Status", "NeedsReconciliation")
    receipt:SetAttribute("Error", tostring(result) .. " / " .. tostring(assetId))
    error("Upload did not confirm success; no automatic retry: " .. key .. " / " .. tostring(result) .. " / " .. tostring(assetId))
end
receipt.Value = tonumber(assetId)
receipt:SetAttribute("Status", "Complete")
return game:GetService("HttpService"):JSONEncode({key=key,assetId=receipt.Value,creatorId=game:GetService("StudioService"):GetUserId(),result=tostring(result)})
