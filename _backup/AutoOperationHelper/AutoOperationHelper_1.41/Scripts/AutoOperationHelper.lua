local AutoOperationHelper = GameMain:NewMod("AutoOperationHelper");--先注册一个新的MOD模块

local SaveData = {};

function AutoOperationHelper:OnInit()
	--print("AutoOperationHelper Init");
end

function AutoOperationHelper:OnEnter()
	self.auto_search = SaveData.auto_search or false;
	self.auto_slaughter = SaveData.auto_slaughter or false;
	self.lingzhi_remind = SaveData.lingzhi_remind or false;
	self.area_list = SaveData.area_list or {};
	self.keys_locked = SaveData.keys_locked or {};
	self.retry = SaveData.retry or {};
	SetAutoOperationWindow = GameMain:GetMod("Windows"):GetWindow("SetAutoOperationWindow");
	SetAutoOperationWindow:Init();
	local Event = GameMain:GetMod("_Event");
	local g_emEvent = CS.XiaWorld.g_emEvent;
	Event:RegisterEvent(g_emEvent.NpcHealthStateChanged,  function(evt, npc, objs) self:AutoProcessNpc(evt, npc, objs); end, "AutoProcessNpc");
	Event:RegisterEvent(g_emEvent.NpcDeath,  function(evt, npc, objs) self:AutoProcessNpc(evt, npc, objs); end, "AutoProcessNpc");
	Event:RegisterEvent(g_emEvent.DayChange,  function(evt, thing, objs) self:CheckLingZhi(); end, "CheckLingZhi");
	print("AutoOperationHelper OnEnter");
end

function AutoOperationHelper:AutoProcessNpc(evt, npc, objs)
	--print(npc:GetName(), evt);
	local g_emNpcRaceType = CS.XiaWorld.g_emNpcRaceType;
	if CS.XiaWorld.World.Instance.GameMode == CS.XiaWorld.g_emGameMode.Fight then
		return;
	end
	if npc.Race.RaceType == g_emNpcRaceType.Wisdom then
		if (not npc.IsPlayerThing) and npc.CorpseTime > 0 then
			--print(npc.ID);
			local target_area, target_key;
			if npc.IsCorpse then
				target_area, target_key = self:GetAvailableGrid("尸体");
			else
				target_area, target_key = self:GetAvailableGrid("弥留");
			end
			if target_key ~= nil then
				--print(npc:GetName()..": "..target_key);
				self.keys_locked[target_key] = npc.ID;
				local command = npc:AddCommand("MoveNpc", CS.XLua.Cast.Int32(target_key));
				if command ~= nil then
					command.EventOnFinished = function()
						if npc.Key ~= target_key then
							local npcs = CS.XiaWorld.World.Instance.map.Things:GetNpcByKey(npc.Key);
							if (not target_area:GridInArea(npc.Key)) or npcs.Count > 1 or self.keys_locked[npc.Key] ~= nil then
								table.insert(self.retry, {npc, target_key});
								return;
							end
						end
						self.keys_locked[target_key] = nil;
					end
				end
			end
		end
		if self.auto_search and npc.IsDeath and ((not npc.IsPlayerThing) or npc.IsVistor) and npc.Equip:GetEquipAll() ~= nil then
			npc:AddCommand("Seach");
		end
	else
		if self.auto_slaughter and npc.IsDeath and ((not npc.IsPlayerThing) or npc.Race.RaceType == g_emNpcRaceType.Animal) and npc.Race.RaceType ~= g_emNpcRaceType.Boss then
			npc:AddCommand("Slaughter");
		end
	end
end

function AutoOperationHelper:GetAvailableGrid(atype)
	if atype == nil then
		return nil, nil;
	end
	local list = {};
	for _, level in pairs({"高", "中", "低"}) do 
		for _, area in pairs(self.area_list) do
			if area.state == atype and area.level == level then
				table.insert(list, area);
			end
		end
	end
	if #list < 1 then
		return nil, nil;
	end
	for _, area in pairs(list) do
		local tg_area = CS.XiaWorld.AreaMgr.Instance:FindAreaByID(area.id);
		if tg_area ~= nil then		
			for i=tg_area.m_lisGrids.Count-1, 0, -1 do
				local key = tg_area.m_lisGrids[i];
				local npcs = CS.XiaWorld.World.Instance.map.Things:GetNpcByKey(key);
				if self.keys_locked[key] == nil and (npcs == nil or npcs.Count == 0) then
					return tg_area, key;
				end
			end
		end
	end
	return nil, nil;
end

function AutoOperationHelper:CheckLingZhi()
	--print("day change");
	local World = CS.XiaWorld.World.Instance;
	local SchoolMgr = CS.XiaWorld.SchoolMgr.Instance;
	if (not self.lingzhi_remind) or World.GameMode == CS.XiaWorld.g_emGameMode.Fight then
		return;
	end
	for _, place in pairs(self.SchoolPlaces) do
		if SchoolMgr:GetSchoolRelation(place.School) > 600 and ((world:GetWorldFlag(place.FlagTime) == 0) or (world:GetWorldFlag(place.FlagTime) <= world.DayCount)) then
			world:ShowMsgBox(string.format("位于[color=#0000FF]%s[color]的[color=#0000FF]%s[color]已经成熟。", place.Name, place.Item));
		end
	end
	for _, place in pairs(self.LingYaoPlaces)do
		if world:GetWorldFlag(place.ValidFlag) == 1 and ((world:GetWorldFlag(place.FlagTime) == 0) or (world:GetWorldFlag(place.FlagTime) <= world.DayCount)) then
			world:ShowMsgBox(string.format("位于[color=#0000FF]%s[color]的[color=#0000FF]%s[color]已经成熟。", place.Name, place.Item));
		end
	end
	if world:GetWorldFlag(46) > 0 and (world:GetWorldFlag(46) + 336) < world.DayCount then
		world:ShowMsgBox(string.format("位于[color=#0000FF]奇特空洞[color]的[color=#0000FF]造化玉籽[color]已经凝结。"));
	end
end

function AutoOperationHelper:OnSetHotKey()
	local tbHotKey = { {ID = "AutoOperationConfig" , Name = "自动搬运设置" , Type = "Mod", InitialKey1 = "RightControl+L", InitialKey2 = "LeftControl+L"}};
	return tbHotKey;
end

function AutoOperationHelper:OnHotKey(ID, state)
	if ID == "AutoOperationConfig" and state == "down" and CS.XiaWorld.World.Instance.GameMode ~= CS.XiaWorld.g_emGameMode.Fight then
		SetAutoOperationWindow:Open();
	end
end

function AutoOperationHelper:OnStep(dt)--请谨慎处理step的逻辑，可能会影响游戏效率
	if self.retry ~= nil and #self.retry > 0 then
		local npc = self.retry[1][1];
		local key = self.retry[1][2];
		self:AutoProcessNpc(nil, npc, nil);
		self.keys_locked[key] = nil;
		table.remove(self.retry, 1);
	end
end

function AutoOperationHelper:OnLeave()
	if SetAutoOperationWindow.window.isShowing then
		SetAutoOperationWindow:Hide();
	end
	print("AutoOperationHelper Leave");
end

function AutoOperationHelper:OnSave()--系统会将返回的table存档 table应该是纯粹的KV
	local data = {
		auto_search = self.auto_search,
		auto_slaughter = self.auto_slaughter,
		lingzhi_remind = self.lingzhi_remind,
		area_list = self.area_list,
		keys_locked = self.keys_locked,
		retry = self.retry
	}
	return data;
end

function AutoOperationHelper:OnLoad(tbLoad)--读档时会将存档的table回调到这里
	SaveData = tbLoad or {};
end

AutoOperationHelper.SchoolPlaces = {
	{
		Name = "飞云涧",
		FlagTime = 71,
		Item = "琅琊果",
		School = 3,
	},
	{
		Name = "神木林",
		FlagTime = 72,
		Item = "木枯藤",
		School = 5,
	},
	{
		Name = "五龙池",
		FlagTime = 73,
		Item = "五色金莲",
		School = 1,
	},
	{
		Name = "凝碧崖",
		FlagTime = 74,
		Item = "朱果",
		School = 6,
	},
	{
		Name = "龙脉洞窟",
		FlagTime = 75,
		Item = "赭黄精",
		School = 2,
	},
};

AutoOperationHelper.LingYaoPlaces = {
	{
		Name = "卢山",
		ValidFlag = 56,
		FlagTime = 57,
		FlagCover = 58,
		Item = "琅琊果",
	},
	{
		Name = "虫谷",
		ValidFlag = 59,
		FlagTime = 60,
		FlagCover = 61,
		Item = "木枯藤",
	},
	{
		Name = "玉晶潭",
		ValidFlag = 62,
		FlagTime = 63,
		FlagCover = 64,
		Item = "五色金莲",
	},
	{
		Name = "火穴",
		ValidFlag = 65,
		FlagTime = 66,
		FlagCover = 67,
		Item = "朱果",
	},
	{
		Name = "炼丹峰",
		ValidFlag = 68,
		FlagTime = 69,
		FlagCover = 70,
		Item = "赭黄精",
	},
};

