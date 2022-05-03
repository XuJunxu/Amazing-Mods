local UnlockAllIll = GameMain:NewMod("UnlockAllIllustratedHand");--先注册一个新的MOD模块

function UnlockAllIll:OnInit()
	--print("UnlockAllIll Init");
end

function UnlockAllIll:OnEnter()
	--print("UnlockAllIll Enter");
	if not self:CheckModLegal() then
		self.mod_enable = false;
		return;
	end
	
	local AllIllMgr = CS.AllIllustratedHandMgr;
	xlua.private_accessible(AllIllMgr);
	for kind, data1 in pairs(AllIllMgr.m_IllDatas) do
		for lable, data2 in pairs(data1) do
			for name, data3 in pairs(data2) do
				AllIllMgr.Instance:SetLighten(kind, lable, name, 1);
			end
		end
	end
end

function UnlockAllIll:CheckModLegal()
	local mod_name = "MyMods";
	local mod = CS.ModsMgr.Instance:FindMod(mod_name, nil, true);
	if (mod ~= nil and mod.Author == "枫轩" and (mod.ID == nil or mod.ID == "123456789" or mod.ID == "9876543211")) then
		return true;
	end
	local mod_display_name = (mod and mod.DisplayName) or mod_name;
	print(string.format("The mod: '%s' is illegal", mod_display_name));
	return false
end

