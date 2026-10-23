local p=game.Players.LocalPlayer;local result={pads=0,labels=0};local camera=workspace.CurrentCamera
for _,model in workspace.NeedleQuay:GetChildren() do
 if model:GetAttribute('StationId')=='Station_1' then
  local label=model.Interaction.StatusLabel;assert(label.StudsOffset.Y==4,'Label still obscures controls');result.labels+=1
  for _,part in model:GetDescendants() do if part:IsA('BasePart') and part:GetAttribute('PadId') then
   result.pads+=1;assert(part.CanQuery and not part.CanCollide,'Functional pad flags changed');local point,visible=camera:WorldToViewportPoint(part.Position);assert(visible,'Pad is outside inspection frame')
  end end
 end
end
assert(result.pads==16,'Not all 16 world pads remain');return game.HttpService:JSONEncode(result)
