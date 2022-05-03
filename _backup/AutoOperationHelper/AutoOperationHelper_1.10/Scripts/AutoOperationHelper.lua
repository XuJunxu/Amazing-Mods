local AutoOperationHelper = GameMain:NewMod("AutoOperationHelper");--先注册一个新的MOD模块
local SetAutoOperationWindow = GameMain:GetMod("Windows"):CreateWindow("SetAutoOperationWindow");

AutoOperationHelper.shift = false;
AutoOperationHelper.savedata = {};

function AutoOperationHelper:OnInit()
	print("AutoOperationHelper Init");
end

function AutoOperationHelper:OnEnter()
	self.auto_search = self.savedata.auto_search or false;
	self.auto_slaughter = self.savedata.auto_slaughter or false;
	self.area_list = self.savedata.area_list or {};
	self.keys_locked = self.savedata.keys_locked or {};
	self.retry = self.savedata.retry or {};
	SetAutoOperationWindow:Init();
	local Event = GameMain:GetMod("_Event");
	Event:RegisterEvent(g_emEvent.NpcHealthStateChanged,  function(evt, npc, objs) self:AutoProcessNpc(evt, npc, objs); end, "NpcHealthStateChanged");
	Event:RegisterEvent(g_emEvent.NpcDeath,  function(evt, npc, objs) self:AutoProcessNpc(evt, npc, objs); end, "NpcDeath");
end

function AutoOperationHelper:AutoProcessNpc(evt, npc, objs)
	--print(npc:GetName(), evt);
	if World.GameMode == CS.XiaWorld.g_emGameMode.Fight then
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
				command.EventOnFinished = function()
					if npc.Key ~= target_key then
						local npcs = Map.Things:GetNpcByKey(npc.Key);
						if (not target_area:GridInArea(npc.Key)) or npcs.Count > 1 or self.keys_locked[npc.Key] ~= nil then
							table.insert(self.retry, {npc, target_key});
							return;
						end
					end
					self.keys_locked[target_key] = nil;
				end
			end
		end
		if self.auto_search and npc.IsDeath and ((not npc.IsPlayerThing) or npc.IsVistor) and npc.Equip:GetEquipAll() ~= nil then
			npc:AddCommand("Seach");
		end
	else
		if self.auto_slaughter and npc.IsDeath and ((not npc.IsPlayerThing) or npc.Race.RaceType == g_emNpcRaceType.Animal) then
			npc:AddCommand("Slaughter");
		end
	end
end

function AutoOperationHelper:GetAvailableGrid(atype)
	if atype == nil then
		return nil;
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
		return nil;
	end
	for _, area in pairs(list) do
		local tg_area = AreaMgr:FindAreaByID(area.id);
		if tg_area ~= nil then		
			for i=tg_area.m_lisGrids.Count-1, 0, -1 do
				local key = tg_area.m_lisGrids[i];
				local npcs = Map.Things:GetNpcByKey(key);
				if self.keys_locked[key] == nil and (npcs == nil or npcs.Count == 0) then
					return tg_area, key;
				end
			end
		end
	end
	return nil;
end

function AutoOperationHelper:OnSetHotKey()
	local tbHotKey = { 
		{ID = "SelectArea" , Name = "选择区域(自动搬运)" , Type = "Mod", InitialKey1 = "LeftShift"}, 
		{ID = "ConfigArea" , Name = "设置区域(自动搬运)" , Type = "Mod", InitialKey1 = "RightControl+L", InitialKey2 = "LeftControl+L"}};
	return tbHotKey;
end

function AutoOperationHelper:OnHotKey(ID, state)
	if ID == "SelectArea" then
		if state == "down" then 
			AutoOperationHelper.shift = true;
		elseif state == "up" then 
			AutoOperationHelper.shift = false;
		end   
    end
	if ID == "ConfigArea" and state == "down" and World.GameMode ~= CS.XiaWorld.g_emGameMode.Fight then
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
	local savedata = {
		auto_search = self.auto_search,
		auto_slaughter = self.auto_slaughter,
		area_list = self.area_list,
		keys_locked = self.keys_locked,
		retry = self.retry
	}
	return savedata
end

function AutoOperationHelper:OnLoad(tbLoad)--读档时会将存档的table回调到这里
	self.savedata = tbLoad or {};
end



