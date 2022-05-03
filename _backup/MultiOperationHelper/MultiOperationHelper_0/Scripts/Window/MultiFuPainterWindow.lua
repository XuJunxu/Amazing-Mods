local Windows = GameMain:GetMod("Windows");  --先注册一个新的MOD模块
local MultiOperationHelper = GameMain:GetMod("MultiOperationHelper");
local MultiFuPainterWindow = Windows:CreateWindow("MultiFuPainterWindow");
local GlobleDataMgr = CS.XiaWorld.GlobleDataMgr.Instance;
local CommandMgr = CS.XiaWorld.CommandMgr.Instance;

function MultiFuPainterWindow:OnInit()
	self.window.contentPane =  UIPackage.CreateObject("MultiOperationHelper", "MultiFuPainterWindow");  --载入UI包里的窗口
	self.window.closeButton = self:GetChild("frame"):GetChild("n5");
	self.frametitle = self:GetChild("frame"):GetChild("title");
	self.list = self:GetChild("list");
	self.btn1 = self:GetChild("btn1");
	self.btn2 = self:GetChild("btn2");
	self.btn1.onClick:Add(function(context)
		self:OnClick(context);
		self:Hide();
	end);
	self.btn2.onClick:Add(function(context)
		self:Hide();
	end);
	self.window.modal = true;  --锁定窗体
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
	--self.list.selectionMode = CS.FairyGUI.ListSelectionMode.Multiple_SingleClick;
	self.window:BringToFront();
	self.list:RemoveChildrenToPool();
	if self.npc == nil or self.paper == nil then
		return;
	end
	local all_def = PracticeMgr.m_mapSpellDefs;
	for k, v in pairs(all_def) do
		local spellDef = PracticeMgr:GetSpellDef(k);
		if spellDef.Name ~= "Spell_SYSLOST" and (spellDef.UnLock > 0 or self.npc.PropertyMgr.Practice.Spells:Contains(spellDef.Name)) then
			local FuValue = math.floor(GlobleDataMgr:GetFuValue(spellDef.Name) * 95 + 0.5);
			if FuValue == nil or FuValue <= 0 then
				FuValue = 100;
			end
			local item = self.list:AddItemFromPool();
			item.icon = "thing://2,Item_SpellLv3";
			item.title = spellDef.DisplayName;
			item:GetChild("input").title = "0";
			item.tooltips = string.format("品质：%d\n%s", FuValue, spellDef.Desc);
			item.data = spellDef.Name;
		end
	end		
end

function MultiFuPainterWindow:OnClick(context)
	--self.list:SelectAll();
	--获取添加任务所需的符咒name
	local spell_name_list = {};
	for i=0, self.list.numItems-1 do
		local listitem = self.list:GetChildAt(i);
		local num = tonumber(listitem:GetChild("input").title);
		if num ~= nil and num > 0 then
			for i=1, num do
				table.insert(spell_name_list, listitem.data);
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
	local CommandTypeDef = CommandMgr:GetDef("PaintCharm");
	CommandTypeDef.Single = 0;  --可添加多条command
	for i=1, math.min(#spell_name_list, #paper_list) do  --参考UILogicMode_IndividualCommand.Apply2Thing() case g_emIndividualCommandType.PaintCharm
		local FuValue = GlobleDataMgr:GetFuValue(spell_name_list[i]) * 0.95;  --符咒品质
		if FuValue == nil or FuValue <= 0 then
			FuValue = 1;
		end
		--print(paper_list[i].def.Name.."  "..spell_name_list[i]);
		local item = PracticeMgr:RandomSpellItem(paper_list[i].def.Name, spell_name_list[i], FuValue, -1, -1, false, paper_list[i].Rate);--生成符咒Item
		self.npc.Bag:AddItem(item, null);
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