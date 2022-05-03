local Windows = GameMain:GetMod("Windows");  --先注册一个新的MOD模块
local MultiFuPainterWindow = Windows:CreateWindow("MultiFuPainterWindow");
local MultiOperationHelper = GameMain:GetMod("MultiOperationHelper");

function MultiFuPainterWindow:OnInit()
	self.window.contentPane = CS.FairyGUI.UIPackage.CreateObject("MultiOperationHelper", "MultiFuPainterWindow");  --载入UI包里的窗口
	self.window.closeButton = self:GetChild("frame"):GetChild("n5");
	self.frametitle = self:GetChild("frame"):GetChild("title");
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

function MultiFuPainterWindow:Open(npc, paper)
	--print("MultiFuPainterWindow Open1");
	self.npc = npc;
	self.paper = paper;
	self.called = false;
	if self.window.isShowing then
		self:OnShowUpdate();
	else
		self:Show();
	end
end

function MultiFuPainterWindow:OnShowUpdate()  --显示选中的npc可用的符咒数据
	--print("MultiFuPainterWindow OnShowUpdate");
	local PracticeMgr = CS.XiaWorld.PracticeMgr.Instance;
	self.list.selectionMode = CS.FairyGUI.ListSelectionMode.None;
	self.window:BringToFront();
	self.list:RemoveChildrenToPool();
	if self.npc == nil then
		return;
	end
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
	if self.called then
		MultiOperationHelper:AddPaintCharmCommand(self.npc, self.paper, spell_name_list);
	end
	self.list:RemoveChildrenToPool();
end