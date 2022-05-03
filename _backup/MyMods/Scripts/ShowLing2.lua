local ShowLing = GameMain:NewMod("ShowLing");--先注册一个新的MOD模块

function ShowLing:OnBeforeInit()
	print("ShowLing BeforeInit");
end

function ShowLing:OnInit()
	print("ShowLing Init");
end

function ShowLing:OnEnter()
	if not self:CheckModLegal() then
		self.mod_enable = false;
		--return;
	end
	self.ShowLingValue = GameMain:GetMod("Windows"):GetWindow("ShowLingValueWindow");
	self.SearchItemThing = GameMain:GetMod("Windows"):GetWindow("SearchThingWindow");
	if World.GameMode == CS.XiaWorld.g_emGameMode.Fight then
		Map:SetNoFog();
	end
	
	CS.MapCamera.Instance.MainCamera.orthographicSize = 20;  --视野最大 UILogicMode_Global.OnScroll
	
	local Event = GameMain:GetMod("_Event");
	Event:RegisterEvent(g_emEvent.DayChange,  function(evt, thing, objs) 
		if Map:IsSpaceRingOpen() then
			Map:CollectToRemoteStorage(0); 
		end
	end, "AutoCollectToRemoteStorage");

--[[
	xlua.private_accessible(CS.XiaWorld.RemoteStorage);
	xlua.private_accessible(CS.XiaWorld.World);
	xlua.private_accessible(CS.XiaWorld.ThingMgr);
	xlua.private_accessible(CS.XiaWorld.Map);
	xlua.private_accessible(CS.ModsMgr);
	xlua.private_accessible(CS.XiaWorld.ThingsData);
	xlua.private_accessible(CS.XiaWorld.AreaMgr);
	xlua.private_accessible(CS.XiaWorld.SchoolMgr);
	xlua.private_accessible(CS.XiaWorld.OutspreadMgr);
	xlua.private_accessible(CS.UI_WorldLayer);
	xlua.private_accessible(CS.XiaWorld.GridMgr);
	xlua.private_accessible(CS.XiaWorld.PracticeMgr);
	xlua.private_accessible(CS.XiaWorld.GlobleDataMgr);
	xlua.private_accessible(CS.XiaWorld.GameDefine);
	xlua.private_accessible(CS.XiaWorld.PropertyMgr);
	xlua.private_accessible(CS.XiaWorld.NpcPropertyMgr);
	xlua.private_accessible(CS.XiaWorld.NpcPractice);
	xlua.private_accessible(CS.XiaWorld.WorldWarehouse);
	xlua.private_accessible(CS.Wnd_RemoteStorage);
	xlua.private_accessible(CS.Wnd_SelectNpc);
	xlua.private_accessible(CS.XiaWorld.CommandMgr);
	xlua.private_accessible(CS.GameWatch);
	xlua.private_accessible(CS.XiaWorld.MagicDef);
	xlua.private_accessible(CS.XiaWorld.Thing);
	xlua.private_accessible(CS.XiaWorld.Npc);
	xlua.private_accessible(CS.XiaWorld.BuildingThing);
	xlua.private_accessible(CS.XiaWorld.ItemThing);
	xlua.private_accessible(CS.XiaWorld.PlantThing);
	xlua.private_accessible(CS.XiaWorld.AreaBase);
	xlua.private_accessible(CS.XiaWorld.NpcEquipData);
	xlua.private_accessible(CS.XiaWorld.ThingsBag);
	xlua.private_accessible(CS.XiaWorld.TagData);
	xlua.private_accessible(CS.XiaWorld.LockTool);
	xlua.private_accessible(CS.XiaWorld.Command);
	xlua.private_accessible(CS.ThingViewBase);
]]--
	--self.ShowLingValue:Show();
	print("ShowLing Enter");
end

function ShowLing:OnSetHotKey()
	local tbHotKey = { {ID = "ShowLingValue" , Name = "显示灵气浓度" , Type = "Mod", InitialKey1 = "RightControl+Quote" } ,
						{ID = "NoFog" , Name = "去除迷雾" , Type = "Mod", InitialKey1 = "RightControl+O" },
						{ID = "AutoSave" , Name = "真仙保存" , Type = "Mod", InitialKey1 = "LeftControl+S" },
						{ID = "SearchItemThing" , Name = "地图物品搜索" , Type = "Mod", InitialKey1 = "RightControl+F" }};
	return tbHotKey;
end

function ShowLing:OnHotKey(ID, state)
	if ID == "ShowLingValue" and state == "down" and self.ShowLingValue ~= nil and self.ShowLingValue.window ~= nil  and World.GameMode ~= CS.XiaWorld.g_emGameMode.Fight then 
		if self.ShowLingValue.window.isShowing then
			self.ShowLingValue:Hide();
		else
			self.ShowLingValue:Show();
			self.ShowLingValue.window:BringToFront();
		end
	end
	if ID == "NoFog" and state == "down" then
		Map:SetNoFog();
	end
	if ID == "AutoSave" and state == "down" then
		if World.GameMode == CS.XiaWorld.g_emGameMode.HardCore then
			CS.XiaWorld.MainManager.Instance:DoAutoSave(0, false);
		end
	end
	if ID == "SearchItemThing" and state == "down" then
		self.SearchItemThing:Open();
	end
end

function ShowLing:CheckModLegal()
	local mod_name = "MyMods";
	local mod = CS.ModsMgr.Instance:FindMod(mod_name, nil, true);
	if (mod ~= nil and mod.Author == "枫轩" and (mod.ID == nil or mod.ID == "123456789" or mod.ID == "9876543211")) then
		return true;
	end
	local mod_display_name = (mod and mod.DisplayName) or mod_name;
	print(string.format("The mod: '%s' is illegal", mod_display_name));
	return false
end