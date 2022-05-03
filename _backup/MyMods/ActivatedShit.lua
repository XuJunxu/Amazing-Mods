local ActivatedShit = GameMain:NewMod("ActivatedShit");--先注册一个新的MOD模块

function ActivatedShit:OnInit()
	--print("ActivatedShit Init");
end

function ActivatedShit:OnEnter()
	if World.GameMode == CS.XiaWorld.g_emGameMode.Fight then
		return;
	end
	local Event = GameMain:GetMod("_Event");
	Event:RegisterEvent(g_emEvent.ThingUpdate, function(evt, item, objs) 
		local item_all = CS.XiaWorld.World.Instance.map.Things:FindItems(nil, 0, 999, "Item_Shit", 0, nil, 0, 9999, nil, false, true);
		if item_all ~= nil and item_all.Count > 0 then
			for _, it in pairs(item_all) do
				it:SetActable(true);
			end
		end
		--print("thing update");
		--if item.def.Name == "Item_Shit" then
		--	item:SetActable(true);
		--end
	end, "SetActable");
	print("ActivatedShit Enter");
end

