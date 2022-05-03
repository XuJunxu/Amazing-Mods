local AutoOperationHelper = GameMain:NewMod("AutoOperationHelper");--先注册一个新的MOD模块

local SaveData = {};

function AutoOperationHelper:OnInit()
	self.auto_search = SaveData.auto_search or false;
	self.auto_slaughter = SaveData.auto_slaughter or false;
	self.lingzhi_remind = SaveData.lingzhi_remind or false;
	self.auto_get_product = SaveData.auto_get_product or false;
	self.auto_roll_label = SaveData.auto_roll_label or false;
	self.area_list = self:Table2List(SaveData.area_list or {});
	self.keys_locked = {};
	self.retry = {};
	
	self.mod_enable = true;
	self.areas_sorted = {};
	--print("AutoOperationHelper Init");
end

function AutoOperationHelper:OnEnter()
	if not self:CheckModLegal() or CS.XiaWorld.World.Instance.GameMode == CS.XiaWorld.g_emGameMode.Fight then
		self.mod_enable = false;
		return;
	end
	local Windows = GameMain:GetMod("Windows");
	self.SetAutoOperationWindow = Windows:GetWindow("SetAutoOperationWindow");
	self.SetAutoOperationWindow:Init();
	local Event = GameMain:GetMod("_Event");
	local g_emEvent = CS.XiaWorld.g_emEvent;
	Event:RegisterEvent(g_emEvent.NpcHealthStateChanged,  function(evt, npc, objs) self:AutoProcessNpc(evt, npc, objs); end, "AutoProcessNpc");
	Event:RegisterEvent(g_emEvent.NpcDeath,  function(evt, npc, objs) self:AutoProcessNpc(evt, npc, objs); end, "AutoProcessNpc");
	Event:RegisterEvent(g_emEvent.DayChange,  function(evt, thing, objs) self:CheckLingZhi(); end, "CheckLingZhi");
	Event:RegisterEvent(g_emEvent.DayChange,  function(evt, thing, objs) self:AutoGetProduct(); end, "AutoGetProduct");
	--Event:RegisterEvent(g_emEvent.WindowEvent, function(evt, thing, objs) self:RollAllLabel(evt, thing, objs); end, "RollAllLabel");
	self:InitAndCheck();
	print("AutoOperationHelper V3.20");
end

function AutoOperationHelper:AutoProcessNpc(evt, npc, objs)  --ThingUICommandDefine
	--print(npc:GetName(), evt);
	local g_emNpcRaceType = CS.XiaWorld.g_emNpcRaceType;
	if npc.IsSmartRace then
		if ((not npc.IsPlayerThing) or npc.IsCorpse) and (not npc.CanDoActionNoMagic) then
			--print(npc.ID);
			local target_area, target_key;
			if npc.IsCorpse then
				target_area, target_key = self:GetAvailableGrid(self.areas_sorted.corpse_areas);
			elseif npc.IsLingering then
				target_area, target_key = self:GetAvailableGrid(self.areas_sorted.dying_areas);
			else
				target_area, target_key = self:GetAvailableGrid(self.areas_sorted.unconscious_areas);
			end
			if target_area ~= nil and target_key ~= nil then
				--print(npc:GetName()..": "..target_key);
				if target_area:GridInArea(npc.Key) and self:CheckKey(npc.Key) <= 1 then
					return;
				end
				if npc:CheckCommandSingle("MoveNpc", false) ~= nil then
					npc:RemoveCommand("MoveNpc", false);
				end
				self.keys_locked[target_key] = npc.ID;
				local command = npc:AddCommand("MoveNpc", CS.XLua.Cast.Int32(target_key));
				if command ~= nil then
					command.EventOnFinished = function(del)
						self.keys_locked[target_key] = nil;
						if del then
							return;
						end
						local npcs = CS.XiaWorld.World.Instance.map.Things:GetNpcByKey(npc.Key);
						local num = 0;
						if npcs ~= nil and npcs.Count > 0 then
							for _, nc in pairs(npcs) do
								if nc.IsSmartRace and (not nc.IsPlayerThing) and (not nc.CanDoActionNoMagic) then
									num = num + 1;
								end
							end
						end
						if (not target_area:GridInArea(npc.Key)) or self:CheckKey(npc.Key) > 1 then
							table.insert(self.retry, npc);
						end
					end
				else
					self.keys_locked[target_key] = nil;
				end
			end
		end
		if self.auto_search and npc.CanSearch and npc.Equip:GetEquipAll() ~= nil and npc.IsDeath then
			npc:AddCommand("Seach");
		end
	elseif self.auto_slaughter and npc.CanBeSlaughter and (not npc.IsBoss) then
		npc:AddCommand("Slaughter");
	end
end

function AutoOperationHelper:InitAndCheck()
	self.keys_locked = {};
	self.retry = {};
	self:SortAreas();
	for _, npc in pairs(CS.XiaWorld.World.Instance.map.Things:GetNpcsLua()) do
		self:AutoProcessNpc(nil, npc, nil);
	end
end

function AutoOperationHelper:CheckKey(key)
	local npcs = CS.XiaWorld.World.Instance.map.Things:GetNpcByKey(key);
	local num = 0;
	if npcs ~= nil and npcs.Count > 0 then
		for _, nc in pairs(npcs) do
			if nc.IsSmartRace and (not nc.IsPlayerThing) and (not nc.CanDoActionNoMagic) then
				num = num + 1;
			end
		end
	end
	return num;
end

function AutoOperationHelper:GetAvailableGrid(tb_areas)
	if tb_areas == nil or tb_areas == {} then
		return nil, nil;
	end
	for _, area in pairs(tb_areas) do
		local tg_area = CS.XiaWorld.AreaMgr.Instance:FindAreaByID(area.id);
		if tg_area ~= nil then		
			for i=tg_area.m_lisGrids.Count-1, 0, -1 do
				local key = tg_area.m_lisGrids[i];
				if self.keys_locked[key] == nil and self:CheckKey(key) == 0 then
					return tg_area, key;
				end
			end
		end
	end
	return nil, nil;
end

function AutoOperationHelper:SortAreas()
	self.areas_sorted = {};
	self.areas_sorted.corpse_areas = {};
	self.areas_sorted.dying_areas = {};
	self.areas_sorted.unconscious_areas = {};
	for _, area in pairs(self.area_list) do
		if area.corpse then
			table.insert(self.areas_sorted.corpse_areas, area);
		end
		if area.dying then
			table.insert(self.areas_sorted.dying_areas, area);
		end
		if area.unconscious then
			table.insert(self.areas_sorted.unconscious_areas, area);
		end
	end
	for atype, tb_areas in pairs(self.areas_sorted) do
		local areas_temp = {};
		for i=2, 0, -1 do
			for _, area in pairs(tb_areas) do
				if area.priority == i then
					table.insert(areas_temp, area)
				end
			end
		end
		self.areas_sorted[atype] = areas_temp;
	end
end

function AutoOperationHelper:CheckLingZhi()  --MapStory_FillingLv2.xml
	--print("day change");
	local SchoolMgr = CS.XiaWorld.SchoolMgr.Instance;
	local PlacesMgr = CS.XiaWorld.PlacesMgr.Instance;
	if not self.lingzhi_remind then
		return;
	end
	for _, place in pairs(self.SchoolPlaces) do
		if not PlacesMgr:IsLocked(place.Name) and SchoolMgr:GetSchoolRelation(place.School) > 600 and ((world:GetWorldFlag(place.FlagTime) == 0) or (world:GetWorldFlag(place.FlagTime) <= world.DayCount)) then
			world:ShowMsgBox(string.format(XT("位于[color=#0000FF]%s[/color]的[color=#0000FF]%s[/color]已经成熟。"), place.DspName, place.Item));
		end
	end
	for _, place in pairs(self.LingYaoPlaces)do
		if world:GetWorldFlag(place.ValidFlag) == 1 and ((world:GetWorldFlag(place.FlagTime) == 0) or (world:GetWorldFlag(place.FlagTime) <= world.DayCount)) then
			world:ShowMsgBox(string.format(XT("位于[color=#0000FF]%s[/color]的[color=#0000FF]%s[/color]已经成熟。"), place.DspName, place.Item));
		end
	end
	if world:GetWorldFlag(46) > 0 and (world:GetWorldFlag(46) + 112) < world.DayCount then
		world:ShowMsgBox(string.format(XT("位于[color=#0000FF]奇特空洞[/color]的[color=#0000FF]造化玉籽[/color]已经凝结。")));
	end
end

function AutoOperationHelper:AutoGetProduct()
	local OutspreadMgr = CS.XiaWorld.OutspreadMgr.Instance;
	if OutspreadMgr == nil or (not self.auto_get_product) then
		return;
	end
	for _, region_name in pairs(OutspreadMgr:GetAllRegionName()) do
		local region = OutspreadMgr:GetRegion(region_name);
		if region ~= nil and region.def ~= nil and region.def.Type == "Rural" and region.ProductStorage ~= nil and region.ProductStorage.Count > 0 then
			OutspreadMgr:TakeProductFromStorage(region);
		end
	end
end

function AutoOperationHelper:RollAllLabel(evt, thing, objs)
	local window = objs[0];
	if self.auto_roll_label and window ~= nil and window.isShowing and window:GetType() == typeof(CS.Wnd_BodyRollLabel) and window.contentPane ~= nil and window.contentPane.m_n71 ~= nil then
		local Pane = window.contentPane;
		for i=0, Pane.m_n71.numItems-1 do
			local label = Pane.m_n71:GetChildAt(i);
			if label.m_Show.selectedIndex == 0 then
				label.m_Show.selectedIndex = 1;
			end
		end
	end
end

function AutoOperationHelper:CheckModLegal()
	local mod_name = "StoreCorpseArea";
	local mod_display_name = "自动搬运尸体/弥留";
	for _, mod in pairs(CS.ModsMgr.Instance.AllMods) do
		if (mod.IsActive and mod.Name == mod_name and mod.Author == "枫轩" and (mod.ID == "1873789439" or mod.ID == "2199817102947260851")) then
			return true;
		end
	end
	print(string.format("The mod: '%s' is illegal", mod_display_name));
	return false
end

function AutoOperationHelper:OnSetHotKey()
	local tbHotKey = { {ID = "AutoOperationConfig" , Name = XT("自动搬运设置") , Type = "Mod", InitialKey1 = "RightControl+L", InitialKey2 = "LeftControl+L"}};
	return tbHotKey;
end

function AutoOperationHelper:OnHotKey(ID, state)
	if not self.mod_enable then
		return;
	end
	if ID == "AutoOperationConfig" and state == "down" and not self.SetAutoOperationWindow.window.isShowing then
		self.SetAutoOperationWindow:Open();
	end
end

function AutoOperationHelper:OnStep(dt)--请谨慎处理step的逻辑，可能会影响游戏效率
	if not self.mod_enable then
		return;
	end
	if self.retry ~= nil and #self.retry > 0 then
		local npc = self.retry[1];
		self:AutoProcessNpc(nil, npc, nil);
		table.remove(self.retry, 1);
	end
end

function AutoOperationHelper:OnLeave()
	print("AutoOperationHelper Leave");
end

function AutoOperationHelper:OnSave()--系统会将返回的table存档 table应该是纯粹的KV
	local save_data = {
		auto_search = self.auto_search,
		auto_slaughter = self.auto_slaughter,
		lingzhi_remind = self.lingzhi_remind,
		auto_get_product = self.auto_get_product,
		auto_roll_label = self.auto_roll_label,
		area_list = self:List2Table(self.area_list),
	}
	return save_data;
end

function AutoOperationHelper:OnLoad(tbLoad)--读档时会将存档的table回调到这里
	SaveData = tbLoad or {};
end

function AutoOperationHelper:List2Table(s_list)
	local t_table = {};
	for key, value in pairs(s_list) do
		t_table[tostring(key)] = value;
	end
	return t_table;
end

function AutoOperationHelper:Table2List(t_table)
	local s_list = {};
	for key, value in pairs(t_table) do
		s_list[tonumber(key)] = value;
	end
	return s_list;
end

AutoOperationHelper.SchoolPlaces = {
	{
		Name="Place_TianJi1",
		DspName = XT("飞云涧"),
		FlagTime = 71,
		Item = XT("琅琊果"),
		School = 3,
	},
	{
		Name="Place_LongHu2",
		DspName = XT("神木林"),
		FlagTime = 72,
		Item = XT("木枯藤"),
		School = 5,
	},
	{
		Name="Place_DanXia3",
		DspName = XT("五龙池"),
		FlagTime = 73,
		Item = XT("五色金莲"),
		School = 1,
	},
	{
		Name="Place_Shu1",
		DspName = XT("凝碧崖"),
		FlagTime = 74,
		Item = XT("朱果"),
		School = 6,
	},
	{
		Name="Place_KunLun2",
		DspName = XT("龙脉洞窟"),
		FlagTime = 75,
		Item = XT("赭黄精"),
		School = 2,
	},
};

AutoOperationHelper.LingYaoPlaces = {
	{
		Name="Place_FertileField5",
		DspName = XT("卢山"),
		ValidFlag = 56,
		FlagTime = 57,
		FlagCover = 58,
		Item = XT("琅琊果"),
	},
	{
		Name="Place_SouthForest3",
		DspName = XT("虫谷"),
		ValidFlag = 59,
		FlagTime = 60,
		FlagCover = 61,
		Item = XT("木枯藤"),
	},
	{
		Name="Place_Snowfield2",
		DspName = XT("玉晶潭"),
		ValidFlag = 62,
		FlagTime = 63,
		FlagCover = 64,
		Item = XT("五色金莲"),
	},
	{
		Name="Place_Desert3",
		DspName = XT("火穴"),
		ValidFlag = 65,
		FlagTime = 66,
		FlagCover = 67,
		Item = XT("朱果"),
	},
	{
		Name="Place_CentralPlains2",
		DspName = XT("炼丹峰"),
		ValidFlag = 68,
		FlagTime = 69,
		FlagCover = 70,
		Item = XT("赭黄精"),
	},
};

--[[
CS.XiaWorld.World.Instance.map.Things:GetNpcsLua
CS.XiaWorld.AreaMgr.Instance:FindAreaByID
CS.XiaWorld.GridMgr.Inst:KeyVaild
CS.XiaWorld.AreaMgr.Instance:CheckArea
CS.XiaWorld.World.Instance.map.Things:GetNpcByKey
CS.XiaWorld.AreaMgr.Instance:FindAreaByID
CS.XiaWorld.SchoolMgr.Instance:GetSchoolRelation
CS.XiaWorld.OutspreadMgr.Instance:GetAllRegionName
CS.XiaWorld.OutspreadMgr.Instance:GetRegion
CS.XiaWorld.OutspreadMgr.Instance:TakeProductFromStorage
CS.XiaWorld.AreaBase:GridInArea
Npc.Equip:GetEquipAll
Npc:AddCommand
]]--
