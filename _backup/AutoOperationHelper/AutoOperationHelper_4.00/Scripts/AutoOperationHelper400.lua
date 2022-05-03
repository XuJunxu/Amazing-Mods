local AutoOperationHelper = GameMain:NewMod("AutoOperationHelper");--先注册一个新的MOD模块

function Global_GetLanguageString(tb_str)
	return function(str)
		if tb_str ~= nil and CS.TFMgr.Instance.Language == "OfficialEnglish" then
			return tb_str[str] or str;
		end
		return str;
	end;
end
local LanStr = {
	["位于[color=#0000FF]%s[/color]的[color=#0000FF]%s[/color]已经成熟。"] = "In the [color=#0000FF]%s[/color], the [color=#0000FF]%s[/color] was ripe.",
	["位于[color=#0000FF]奇特空洞[/color]的[color=#0000FF]造化玉籽[/color]已经凝结。"] = "In the [color=#0000FF]Mystic Cavern[/color], the [color=#0000FF]Fortune Seed[/color] was condensing.",
	["自动搬运设置"] = "Auto Transporting",
	["飞云涧"] = "Nimbus Ravine",
	["神木林"] = "Mistwood Forest",
	["五龙池"] = "Five Dragons Pond",
	["凝碧崖"] = "Jadestone Cliff",
	["龙脉洞窟"] = "Drake Cave",
	["卢山"] = "Mt. Rue",
	["虫谷"] = "Wormwrought Valley",
	["玉晶潭"] = "Lake Jadestone",
	["火穴"] = "Blazenest",
	["炼丹峰"] = "Alchemist's Peak",
	["琅琊果"] = "Sage Fruit",
	["木枯藤"] = "Gnarled Vine",
	["五色金莲"] = "Prism Lotus",
	["朱果"] = "Crimson Fruit",
	["赭黄精"] = "Ocher Essence",
};
local GLS = Global_GetLanguageString(LanStr);

local SaveData = {};

function AutoOperationHelper:OnInit()
	self.auto_search = SaveData.auto_search or false;
	self.auto_slaughter = SaveData.auto_slaughter or false;
	self.lingzhi_remind = SaveData.lingzhi_remind or false;
	self.auto_get_product = SaveData.auto_get_product or false;
	self.auto_roll_label = SaveData.auto_roll_label or false;
	self.auto_yunyang = SaveData.auto_yunyang or false;
	self.area_list = self:Table2List(SaveData.area_list or {});
	self.yunyang_settings = SaveData.yunyang_settings or {};
	
	self.keys_locked = {};
	self.retry = {};
	
	self.mod_enable = true;
	self.areas_sorted = {};
	self.command_table = {};
	self.npcs_locked = {};
	self.yunyang_timer = 0;
	--print("AutoOperationHelper Init");
end

function AutoOperationHelper:OnEnter()
	local GameMode = CS.XiaWorld.World.Instance.GameMode;
	local g_emGameMode = CS.XiaWorld.g_emGameMode;
	if not self:CheckModLegal() or (GameMode ~= g_emGameMode.Normal and GameMode ~= g_emGameMode.HardCore) then
		--print(GameMode);
		self.mod_enable = false;
		return;
	end
	xlua.private_accessible(CS.XiaWorld.ThingMgr);
	xlua.private_accessible(CS.XiaWorld.CommandMgr);
	self:InitYunYangSettings();
	local Windows = GameMain:GetMod("Windows");
	self.SetAutoOperationWindow = Windows:GetWindow("AutoOperationHelper_SetAutoOperationWindow");
	self.SetAutoOperationWindow:Init();
	local Event = GameMain:GetMod("_Event");
	local g_emEvent = CS.XiaWorld.g_emEvent;
	Event:RegisterEvent(g_emEvent.NpcHealthStateChanged,  function(evt, npc, objs) self:AutoProcessNpc(evt, npc, objs); end, "AutoOperationHelper_AutoProcessNpc");
	Event:RegisterEvent(g_emEvent.NpcDeath,  function(evt, npc, objs) self:AutoProcessNpc(evt, npc, objs); end, "AutoOperationHelper_AutoProcessNpc");
	Event:RegisterEvent(g_emEvent.DayChange,  function(evt, thing, objs) self:CheckLingZhi(); end, "AutoOperationHelper_CheckLingZhi");
	Event:RegisterEvent(g_emEvent.DayChange,  function(evt, thing, objs) self:AutoGetProduct(); end, "AutoOperationHelper_AutoGetProduct");
	Event:RegisterEvent(g_emEvent.WindowEvent, function(evt, thing, objs) self:RollAllLabel(evt, thing, objs); end, "AutoOperationHelper_RollAllLabel");
	self:InitAndCheck();
	print("AutoOperationHelper V4.00");
end

function AutoOperationHelper:InitYunYangSettings()
	for _, plant in pairs(self.LingZhiList) do
		if self.yunyang_settings[plant] == nil then
			self.yunyang_settings[plant] = {};
		end
		for _, rela in pairs(self.RelationList) do
			if self.yunyang_settings[plant][rela] == nil then
				self.yunyang_settings[plant][rela] = false;
			end
		end
	end
end

function AutoOperationHelper:AutoProcessNpc(evt, npc, objs)  --ThingUICommandDefine
	--print(npc:GetName(), evt);
	if (not npc.IsValid) or npc.Hide or (not npc.AtG) then
		return;
	end
	local g_emNpcRaceType = CS.XiaWorld.g_emNpcRaceType;
	if npc.IsSmartRace then
		if ((not npc.IsPlayerThing) or npc.IsCorpse) and (not npc.CanDoActionNoMagic) then
			--print(npc:GetName());
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
				if not (target_area:GridInArea(npc.Key) and self:CheckKey(npc.Key) <= 1) then
					if npc:CheckCommandSingle("MoveNpc", false) ~= nil then
						npc:RemoveCommand("MoveNpc", false);
					end
					local command = npc:AddCommand("MoveNpc", CS.XLua.Cast.Int32(target_key));
					if command ~= nil then
						self.keys_locked[target_key] = npc.ID;
						self.command_table[command.ID] = command;
						command.EventOnFinished = self:MoveNpcFinished(target_area, target_key, npc, command);
					end
				end
			end
		end
		if self.auto_search and npc.CanSearch and npc.Equip:GetEquipAll() ~= nil and npc.IsDeath and npc:CheckCommandSingle("Seach", false) == nil then
			npc:AddCommand("Seach");
		end
	elseif self.auto_slaughter and npc.CanBeSlaughter and (not npc.IsBoss) and npc:CheckCommandSingle("Slaughter", false) == nil then
		npc:AddCommand("Slaughter");
	end
end

function AutoOperationHelper:MoveNpcFinished(target_area, target_key, npc, command)
	return function(del)
		self.command_table[command.ID] = nil;
		self.keys_locked[target_key] = nil;
		command.EventOnFinished = nil;
		if del then
			return;
		end
		if (not target_area:GridInArea(npc.Key)) or self:CheckKey(npc.Key) > 1 then
			table.insert(self.retry, npc);
		end
	end;
end

function AutoOperationHelper:InitAndCheck()
	self.keys_locked = {};
	self.retry = {};
	self:SortAreas();
	self.yunyang_timer = 0;
	self:GetYunYangCommandTargets();
	for _, npc in pairs(CS.XiaWorld.World.Instance.map.Things:GetNpcsLua()) do
		if self.npcs_locked[npc.ID] == nil then
			self:AutoProcessNpc(nil, npc, nil);
		end
	end
	self:AutoYunYang();
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
			world:ShowMsgBox(string.format(GLS("位于[color=#0000FF]%s[/color]的[color=#0000FF]%s[/color]已经成熟。"), place.DspName, place.Item));
		end
	end
	for _, place in pairs(self.LingYaoPlaces)do
		if world:GetWorldFlag(place.ValidFlag) == 1 and ((world:GetWorldFlag(place.FlagTime) == 0) or (world:GetWorldFlag(place.FlagTime) <= world.DayCount)) then
			world:ShowMsgBox(string.format(GLS("位于[color=#0000FF]%s[/color]的[color=#0000FF]%s[/color]已经成熟。"), place.DspName, place.Item));
		end
	end
	if world:GetWorldFlag(46) > 0 and (world:GetWorldFlag(46) + 112) < world.DayCount then
		world:ShowMsgBox(string.format(GLS("位于[color=#0000FF]奇特空洞[/color]的[color=#0000FF]造化玉籽[/color]已经凝结。")));
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

function AutoOperationHelper:AutoYunYang()
	local ThingMgr = CS.XiaWorld.ThingMgr.Instance;
	local g_emPlantKind = CS.XiaWorld.g_emPlantKind;
	local g_emElementRelation = CS.XiaWorld.g_emElementRelation;
	local g_emPlantState = CS.XiaWorld.g_emPlantState;
	local npc_list_inner = CS.XiaWorld.World.Instance.map.Things:GetNpcsLua(function(npc) 
		return npc.IsDisciple and (not npc.Hide) and npc.AtG and (not npc.IsPlayerThing) and npc.IsCorpse;
	end);
	local npc_list_outer = CS.XiaWorld.World.Instance.map.Things:GetNpcsLua(function(npc) 
		return (not npc.IsDisciple) and (not npc.Hide) and npc.AtG and (not npc.IsPlayerThing) and npc.IsCorpse;
	end);
	for _, rela in ipairs(self.RelationList) do
		local npc_list = npc_list_inner;
		local relation = self.RelationTable[rela];
		if rela == "outer" then
			npc_list = npc_list_outer;
		end
		for _, name in ipairs(self.LingZhiList) do
			local re, list = ThingMgr.m_mapLingPlant:TryGetValue(name);
			local setting = self.yunyang_settings[name][rela];
			if re and list ~= nil then
				for _, pid in pairs(list) do
					local plant = ThingMgr:FindThingByID(pid);
					if (setting and plant ~= nil and plant.IsValid and (not plant.IsHide) and plant.PlantState ~= g_emPlantState.HarvestedDie and plant.def.Plant.Kind ~= g_emPlantKind.Mine and 
						plant.def.Plant.Kind ~= g_emPlantKind.Object and plant.bLingPlant and plant:CanYunYang() and plant:CheckCommandSingle("YunYang", false) == nil) then
						local target_npc = self:GetYunYangTarget(plant, relation, npc_list);
						if target_npc ~= nil then
							if target_npc:CheckCommandSingle("MoveNpc", false) ~= nil then
								target_npc:RemoveCommand("MoveNpc", false);
							end
							local command = plant:AddCommand("YunYang", target_npc.ID, 1);
							if command ~= nil then
								self.npcs_locked[target_npc.ID] = target_npc.ID;
								self.command_table[command.ID] = command;
								command.EventOnFinished = self:YunYangFinished(target_npc.ID, command);
							end						
						end
					end
				end
			end
		end
	end
end

function AutoOperationHelper:YunYangFinished(target_ID, command)
	return function(del)
		self.npcs_locked[target_ID] = nil;
		self.command_table[command.ID] = nil;
		command.EventOnFinished = nil;
	end;
end

function AutoOperationHelper:GetYunYangTarget(plant, relation, npc_list)
	for _, npc in pairs(npc_list) do
		if self.npcs_locked[npc.ID] == nil and (relation == nil or CS.XiaWorld.GameDefine.CheckElementRelation(plant.ElementKind, npc.PropertyMgr.Practice.Gong.ElementKind) == relation) then
			return npc;
		end
	end
	return nil;
end

function AutoOperationHelper:GetYunYangCommandTargets()
	local re, command_list = CS.XiaWorld.CommandMgr.Instance.m_mapCommands:TryGetValue("YunYang")
	self.npcs_locked = {};
	if re and command_list ~= nil then
		for _, command in pairs(command_list) do
			local target_ID = command.STargetId;
			self.npcs_locked[target_ID] = target_ID;
			self.command_table[command.ID] = command;
			command.EventOnFinished = self:YunYangFinished(target_ID, command);
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
	if not self.mod_enable then
		return {};
	end
	local tbHotKey = { {ID = "AutoOperationConfig" , Name = GLS("自动搬运设置") , Type = "Mod", InitialKey1 = "RightControl+L", InitialKey2 = "LeftControl+L"}};
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
	if self.auto_yunyang then
		self.yunyang_timer = self.yunyang_timer + 1;
		if self.yunyang_timer > 99 then
			self.yunyang_timer = 0;
			self:AutoYunYang();
		end
	end
	if self.retry ~= nil and #self.retry > 0 then
		local npc = self.retry[1];
		self:AutoProcessNpc(nil, npc, nil);
		table.remove(self.retry, 1);
	end
end

function AutoOperationHelper:OnLeave()
	if not self.mod_enable then
		return;
	end
	local i = 0;
	for _, command in pairs(self.command_table) do
		command.EventOnFinished = nil;
		i = i + 1;
	end
	self.SetAutoOperationWindow:RemoveCallback();
	print(string.format("AutoOperationHelper Leave: %d", i));
end

function AutoOperationHelper:OnSave()--系统会将返回的table存档 table应该是纯粹的KV
	local save_data = {
		auto_search = self.auto_search,
		auto_slaughter = self.auto_slaughter,
		lingzhi_remind = self.lingzhi_remind,
		auto_get_product = self.auto_get_product,
		auto_roll_label = self.auto_roll_label,
		auto_yunyang = self.auto_yunyang,
		area_list = self:List2Table(self.area_list),
		yunyang_settings = self.yunyang_settings,
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
	{Name="Place_TianJi1", DspName = GLS("飞云涧"), FlagTime = 71, Item = GLS("琅琊果"), School = 3,}, 
	{Name="Place_LongHu2", DspName = GLS("神木林"), FlagTime = 72, Item = GLS("木枯藤"), School = 5,}, 
	{Name="Place_DanXia3", DspName = GLS("五龙池"), FlagTime = 73, Item = GLS("五色金莲"), School = 1,}, 
	{Name="Place_Shu1", DspName = GLS("凝碧崖"), FlagTime = 74, Item = GLS("朱果"), School = 6,},
	{Name="Place_KunLun2", DspName = GLS("龙脉洞窟"), FlagTime = 75, Item = GLS("赭黄精"), School = 2,},
};

AutoOperationHelper.LingYaoPlaces = {
	{Name="Place_FertileField5", DspName = GLS("卢山"), ValidFlag = 56, FlagTime = 57, FlagCover = 58, Item = GLS("琅琊果"),},
	{Name="Place_SouthForest3", DspName = GLS("虫谷"), ValidFlag = 59, FlagTime = 60, FlagCover = 61, Item = GLS("木枯藤"),},
	{Name="Place_Snowfield2", DspName = GLS("玉晶潭"), ValidFlag = 62, FlagTime = 63, FlagCover = 64, Item = GLS("五色金莲"),},
	{Name="Place_Desert3", DspName = GLS("火穴"), ValidFlag = 65, FlagTime = 66, FlagCover = 67, Item = GLS("朱果"),},
	{Name="Place_CentralPlains2", DspName = GLS("炼丹峰"), ValidFlag = 68, FlagTime = 69, FlagCover = 70, Item = GLS("赭黄精"),},
};

AutoOperationHelper.LingZhiList = {
	"LingZhi_Jin", "LingZhi_Mu", "LingZhi_Shui", "LingZhi_Huo", "LingZhi_Tu",
};

AutoOperationHelper.RelationList = {
	"born", "contrary", "same", "none", "outer",
};

AutoOperationHelper.RelationTable = {
	["born"] = CS.XiaWorld.g_emElementRelation.Born, 
	["contrary"] = CS.XiaWorld.g_emElementRelation.Contrary, 
	["same"] = CS.XiaWorld.g_emElementRelation.Same, 
	["none"] = CS.XiaWorld.g_emElementRelation.None,
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
