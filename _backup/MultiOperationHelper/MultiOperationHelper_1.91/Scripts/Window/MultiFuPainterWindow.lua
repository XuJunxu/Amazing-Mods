local Windows = GameMain:GetMod("Windows");  --先注册一个新的MOD模块
local MultiOperationHelper = GameMain:GetMod("MultiOperationHelper");
local MultiFuPainterWindow = Windows:CreateWindow("MultiFuPainterWindow");

function MultiFuPainterWindow:OnInit()
	self.window.contentPane =  UIPackage.CreateObject("MultiOperationHelper", "MultiFuPainterWindow");  --载入UI包里的窗口
	self.window.closeButton = self:GetChild("frame"):GetChild("n5");
	self.frametitle = self:GetChild("frame"):GetChild("title");
	self.list = self:GetChild("list");
	self.btn1 = self:GetChild("btn1");
	self.btn2 = self:GetChild("btn2");
	self.btn1.onClick:Add(function(context)
		self:AddPaintCharmCommand();
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
	if self.window.isShowing then
		self:OnShowUpdate();
	else
		self:Show();
	end
end

function MultiFuPainterWindow:OnShowUpdate()  --显示选中的npc可用的符咒数据
	--print("MultiFuPainterWindow OnShowUpdate");
	self.list.selectionMode = CS.FairyGUI.ListSelectionMode.None;
	self.window:BringToFront();
	self.list:RemoveChildrenToPool();
	if self.npc == nil or self.paper == nil then
		return;
	end
	local all_def = CS.XiaWorld.PracticeMgr.Instance.m_mapSpellDefs;
	for k, v in pairs(all_def) do
		local spell_def = CS.XiaWorld.PracticeMgr.Instance:GetSpellDef(k);
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

function MultiFuPainterWindow:AddPaintCharmCommand(context)
	--self.list:SelectAll();
	--获取添加任务所需的符咒name
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
	if #spell_name_list == 0 then
		return;
	end
	--获取添加任务所需的符纸Item
	local paper_list = {};
	--print(self.paper.def.Name);
	local paper_list = MultiOperationHelper:GetActableItems(self.paper, #spell_name_list, nil);
	if #paper_list == 0 then
		world:ShowMsgBox(string.format("没有可用的[color=#0000FF]%d品阶%s[color]。", self.paper.Rate, self.paper:GetName()));
		return;
	end
	--print(#spell_name_list.."  "..#paper_list);
	if #spell_name_list > #paper_list then  --提示符纸数量不足
		world:ShowMsgBox(string.format("计划添加%d个画符任务，缺少[color=#0000FF]%d品阶%s[color]%d张，已添加%d个任务。", #spell_name_list, self.paper.Rate, self.paper:GetName(), #spell_name_list-#paper_list, #paper_list));
	end
	local command_def = CS.XiaWorld.CommandMgr.Instance:GetDef("PaintCharm");
	command_def.Single = 0;  --可添加多条command
	for i=1, math.min(#spell_name_list, #paper_list) do  --参考UILogicMode_IndividualCommand.Apply2Thing() case g_emIndividualCommandType.PaintCharm
		local fu_value = CS.XiaWorld.GlobleDataMgr.Instance:GetFuValue(spell_name_list[i]) * 0.95;  --符咒品质
		if fu_value == nil or fu_value <= 0 then
			fu_value = 1;
		end
		--print(paper_list[i].def.Name.."  "..spell_name_list[i]);
		local item = CS.XiaWorld.PracticeMgr.Instance:RandomSpellItem(paper_list[i].def.Name, spell_name_list[i], fu_value, -1, -1, false, paper_list[i].Rate);--生成符咒Item
		self.npc.Bag:AddItem(item, nil);
		item.Author = self.npc:GetName();
		local command = self.npc:AddCommand("PaintCharm", paper_list[i], CS.XLua.Cast.Int32(item.ID));
		--print(command.def.Single);
		local dict = {};
		dict["Name"] = spell_name_list[i];
		dict["Value"] = item:GetQuality();
		CS.GameWatch.Instance:BuryingPoint(CS.XiaWorld.BuryingPointType.Fu, dict);
	end
	MultiOperationHelper:InterruptGetFun(self.npc);
end

function MultiFuPainterWindow:OnHide()
	self.list:RemoveChildrenToPool();
end