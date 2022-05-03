local ObsessionMindRemind = GameMain:NewMod("ObsessionMindRemind");--先注册一个新的MOD模块
local SaveData = {};

function ObsessionMindRemind:OnInit()
	self.npc_obsession_minds = SaveData.minds or {};
	--print("ObsessionMindRemind Init");
end

function ObsessionMindRemind:OnEnter()
	self.mod_enable = true;
	
	if not self:CheckModLegal() then
		self.mod_enable = false;
		return;
	end
	local Event = GameMain:GetMod("_Event");
	local g_emEvent = CS.XiaWorld.g_emEvent;
	Event:RegisterEvent(g_emEvent.NpcPropertyChange,  function(evt, npc, objs) 
		self:CheckObsessionMind(evt, npc, objs); 
	end, "CheckObsessionMind");
	print("ObsessionMindRemind Enter");
end

function ObsessionMindRemind:CheckObsessionMind(evt, npc, objs)	
	if npc == nil and npc.IsPuppet or npc.IsZombie or npc.IsDeath or npc.IsLingering or (not npc.IsPlayerThing) or (not npc.IsDisciple) then
		return;
	end
	xlua.private_accessible(CS.XiaWorld.NpcPractice);
	if npc.PropertyMgr.Practice.ObsessionMinds == nil then
		return;
	end
	for index, value in pairs(npc.PropertyMgr.Practice.ObsessionMinds) do
		local obsessionMindData = CS.XiaWorld.GameDefine.sObsessionMindDatas[index];
		local num0 = value[0];
		local num1 = value[1];
		local total = obsessionMindData.Count[num1];
		if num1 ~= 4 and num0 < total then			
			self.npc_obsession_minds[index] = self.npc_obsession_minds[index] or {};						
			for i, id in pairs(self.npc_obsession_minds[index]) do
				if npc.ID == id then
					if num0 < 1 then
						table.remove(self.npc_obsession_minds[index], i);
						world:ShowMsgBox(string.format("[color=#0000FF]%s[color]的[color=#0000FF]%s[color]执念已经消除。", npc:GetName(), obsessionMindData.Name));
					end
					return;
				end					
			end
			local num4 = num0 / total;
			if num4 > 0.8 then
				table.insert(self.npc_obsession_minds[index], npc.ID);
				world:ShowMsgBox(string.format("[color=#0000FF]%s[color]的[color=#0000FF]%s[color]执念即将显现。", npc:GetName(), obsessionMindData.Name));
			end
		end
	end
	--print("ObsessionMindRemind");
end

function ObsessionMindRemind:CheckModLegal()
	local mod_name = "MyMods";
	local mod = CS.ModsMgr.Instance:FindMod(mod_name, nil, true);
	if (mod ~= nil and mod.Author == "枫轩" and (mod.ID == nil or mod.ID == "123456789" or mod.ID == "9876543211")) then
		return true;
	end
	local mod_display_name = (mod and mod.DisplayName) or mod_name;
	print(string.format("The mod: '%s' is illegal", mod_display_name));
	return false
end

function ObsessionMindRemind:OnSave()--系统会将返回的table存档 table应该是纯粹的KV
	data = {
		minds = self.npc_obsession_minds,
	}
	return data;
end

function ObsessionMindRemind:OnLoad(tbLoad)--读档时会将存档的table回调到这里
	SaveData = tbLoad or {};
end