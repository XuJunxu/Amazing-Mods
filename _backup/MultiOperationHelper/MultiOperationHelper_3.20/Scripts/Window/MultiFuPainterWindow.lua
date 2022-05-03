local Windows = GameMain:GetMod("Windows");  --先注册一个新的MOD模块
local MultiFuPainterWindow = Windows:CreateWindow("MultiFuPainterWindow");

function MultiFuPainterWindow:OnInit()
	self.window.contentPane = CS.FairyGUI.UIPackage.CreateObject("MultiOperationHelper", "MultiFuPainterWindow");  --载入UI包里的窗口
	self.window.closeButton = self:GetChild("frame"):GetChild("n5");
	self.list = self:GetChild("list");
	self.btn1 = self:GetChild("btn1");
	self.btn2 = self:GetChild("btn2");
	self.btn1.onClick:Add(function(context)
		self.called = true;
		self:Hide();
	end);
	self.btn2.onClick:Add(function(context)
		self:Hide();
	end);
	self.window.modal = true;
	self.window:Center();
	--print("MultiFuPainterWindow OnInit");
end

function MultiFuPainterWindow:Open(npc, paper, callBack)
	--print("MultiFuPainterWindow Open1");
	self.npc = npc;
	self.paper = paper;
	self.called = false;
	self.callBack = callBack;
	if self.window.isShowing then
		self:OnShowUpdate();
	else
		self:Show();
	end
end

function MultiFuPainterWindow:OnShowUpdate()  --显示选中的npc可用的符咒数据
	--print("MultiFuPainterWindow OnShowUpdate");
	local PracticeMgr = CS.XiaWorld.PracticeMgr.Instance;
	self.window:BringToFront();
	self.list:RemoveChildrenToPool();
	for k, v in pairs(PracticeMgr.m_mapSpellDefs) do
		local spell_def = PracticeMgr:GetSpellDef(k);
		if spell_def.Name ~= "Spell_SYSLOST" and (spell_def.UnLock > 0 or self.npc.PropertyMgr.Practice.Spells:Contains(spell_def.Name)) then
			local fu_value = math.floor(CS.XiaWorld.GlobleDataMgr.Instance:GetFuValue(spell_def.Name) * 95 + 0.5);
			if fu_value == nil or fu_value <= 0 then
				fu_value = 100;
			end
			local item = self.list:AddItemFromPool();
			item.icon = "thing://2,Item_SpellLv3";
			item.title = spell_def.DisplayName;
			item.tooltips = string.format("品质：%d\n%s", fu_value, spell_def.Desc);
			item.data = spell_def.Name;
			local input = item:GetChild("input");
			input.title = "";
			if input.title ~= "" then  --问题：修改后点击取消，再打开窗体会保留上次修改后的数据
				input.title = "";
				--print(spell_def.DisplayName);
			end
		end
	end
	if not self.pause then
		self.pause = true;
		CS.XiaWorld.MainManager.Instance:Pause(true);
	end
end

function MultiFuPainterWindow:OnHide()
	local spell_name_list = {};
	for i=0, self.list.numItems-1 do
		local list_item = self.list:GetChildAt(i);
		local num = tonumber(list_item:GetChild("input").title) or 0;
		if num ~= nil and num > 0 then
			for i=1, num do
				table.insert(spell_name_list, list_item.data);
			end	
		end
	end
	if self.called and self.callBack ~= nil then
		self.callBack(self.npc, self.paper, spell_name_list);
	end
	self.list:RemoveChildrenToPool();
	self.npc = nil;
	self.paper = nil;
	self.callBack = nil;
	if self.pause then
		self.pause = false;
		CS.XiaWorld.MainManager.Instance:Play(0, true);
	end
end