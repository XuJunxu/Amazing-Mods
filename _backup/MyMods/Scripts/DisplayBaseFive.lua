local DisplayBaseFive = GameMain:NewMod("DisplayBaseFive");--先注册一个新的MOD模块

function DisplayBaseFive:OnInit()
	--print("DisplayBaseFive Init");
end

function DisplayBaseFive:OnEnter()
	--print("DisplayBaseFive Enter");
	if not self:CheckModLegal() then
		self.mod_enable = false;
		return;
	end
	xlua.private_accessible(CS.Wnd_NpcInfo);
	xlua.private_accessible(CS.Panel_NpcInfoPanel);
	xlua.private_accessible(CS.XiaWorld.NpcBaseProperty);
	local Event = GameMain:GetMod("_Event");
	local g_emEvent = CS.XiaWorld.g_emEvent;
	Event:RegisterEvent(g_emEvent.ShowNpcInfoUI,  function(evt, npc, objs) 
		self:ShowBaseFiveInfo(evt, npc, objs); 
	end, "ShowBaseFiveInfo");
	Event:RegisterEvent(g_emEvent.NpcPropertyChange,  function(evt, npc, objs) 
		self:ShowBaseFiveInfo(evt, npc, objs); 
	end, "ShowBaseFiveInfo");
end

function DisplayBaseFive:ShowBaseFiveInfo(evt, npc, objs)
	local g_emNpcBasePropertyType = CS.XiaWorld.g_emNpcBasePropertyType;
	local Wnd_NpcInfo = CS.Wnd_NpcInfo.Instance;
	if Wnd_NpcInfo == nil or not Wnd_NpcInfo.isShowing or Wnd_NpcInfo.npc ~= npc or npc == nil then
		return;
	end
	local GameDefine = CS.XiaWorld.GameDefine;
	local info_panel = Wnd_NpcInfo.PropertyPanel;
	local npc = Wnd_NpcInfo.npc;
	local property_array = {
		g_emNpcBasePropertyType.Perception, 
		g_emNpcBasePropertyType.Physique, 
		g_emNpcBasePropertyType.Charisma, 
		g_emNpcBasePropertyType.Intelligence, 
		g_emNpcBasePropertyType.Luck,
	}
	local ui_array = {
		info_panel.Panel.m_n89.m_n91,
		info_panel.Panel.m_n89.m_n92,
		info_panel.Panel.m_n89.m_n93,
		info_panel.Panel.m_n89.m_n94,
		info_panel.Panel.m_n89.m_n95,
	}
	for i=1, 5 do
		local property_type = property_array[i];
		local property_data = npc.PropertyMgr.BaseData.m_mapData[i-1];
		local value = npc.PropertyMgr.BaseData:GetValue(property_type);
		local base_value = property_data.basevalue;
		local addv = property_data.addv;
		local addp = math.floor(property_data.addp * 100 + 0.5);
		local t_value = property_data:GetValue(property_type);  --base_value * (1 + property_data.addp) + addv;
		local tooltips = string.format("%s:%.2f\n基础值:%.2f  理论值:%.2f\n加值:%.2f  加成:%.0f%%\n%s", GameDefine.GetBasePropertyName(property_type), value, base_value, t_value, addv, addp, GameDefine.BasePDesc[i-1]);
		ui_array[i].tooltips = tooltips;
		--print(property_data);
	end
	--print("DisplayBaseFive");
end

function DisplayBaseFive:CheckModLegal()
	local mod_name = "MyMods";
	local mod = CS.ModsMgr.Instance:FindMod(mod_name, nil, true);
	if (mod ~= nil and mod.Author == "枫轩" and (mod.ID == nil or mod.ID == "123456789" or mod.ID == "9876543211")) then
		return true;
	end
	local mod_display_name = (mod and mod.DisplayName) or mod_name;
	print(string.format("The mod: '%s' is illegal", mod_display_name));
	return false
end

