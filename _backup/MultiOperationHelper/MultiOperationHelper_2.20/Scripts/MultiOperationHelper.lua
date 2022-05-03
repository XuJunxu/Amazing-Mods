local MultiOperationHelper = GameMain:NewMod("MultiOperationHelper");--先注册一个新的MOD模块

local SaveData = {};

function MultiOperationHelper:OnInit()
	self.refining_fabao_table = SaveData.refining_fabao or {};
	self.last_item_id = SaveData.last_item_id;
	self.last_npc_id = SaveData.last_npc_id;
	
	self.mod_enable = true;
	self.last_item = nil;
	self.last_npc = nil;
	--print("MultiOperationHelper OnInit");
end

function MultiOperationHelper:OnEnter()
	if not self:CheckModLegal() then
		self.mod_enable = false;
		return;
	end	
	local Windows = GameMain:GetMod("Windows");
	self.OperationMsgWindow = Windows:GetWindow("OperationMsgWindow");
	self.MultiSelectWindow = Windows:GetWindow("MultiSelectWindow");
	self.MagicBtnWindow = Windows:GetWindow("MagicBtnWindow");
	self.OperationMsgWindow:Init();
	self.MultiSelectWindow:Init();
	self.MagicBtnWindow:Init();
	
	local Event = GameMain:GetMod("_Event");
	local g_emEvent = CS.XiaWorld.g_emEvent;
	Event:RegisterEvent(g_emEvent.SelectItem,  function(evt, item, objs) 
		self:AddBtn2Item(evt, item, objs); 
	end, "AddBtn2Item");
	Event:RegisterEvent(g_emEvent.SelectNpc,  function(evt, npc, objs) 
		self:AddBtn2Npc(evt, npc, objs);
	end, "AddBtn2Npc");
	if CS.XiaWorld.World.Instance.GameMode == CS.XiaWorld.g_emGameMode.Fight then
		self.mod_enable = false;
	end
	local ThingMgr = CS.XiaWorld.ThingMgr.Instance;
	if self.last_item_id ~= nil and ThingMgr ~= nil then
		self:RemoveBtnFromItem(ThingMgr:FindThingByID(self.last_item_id));
	end
	if self.last_npc_id ~= nil and ThingMgr ~= nil then
		self:RemoveBtnFromNpc(ThingMgr:FindThingByID(self.last_npc_id));
	end
	print("MultiOperationHelper Entered");
end

function MultiOperationHelper:MultiFuPainter(paper)  --选择画符的npc
	--self.item = item;
	local MultiFuPainterWindow = GameMain:GetMod("Windows"):GetWindow("MultiFuPainterWindow");
	CS.Wnd_SelectNpc.Instance:Select(
		WorldLua:GetSelectNpcCallback(function(rs)
			if (rs == nil or rs.Count == 0) then
				return;
			end
			local npc = CS.XiaWorld.ThingMgr.Instance:FindThingByID(rs[0]);
			if npc ~= nil then
				MultiFuPainterWindow:Open(npc, paper);
			end
		end), 
	CS.XiaWorld.g_emNpcRank.Disciple, 1, 1, nil, nil, "指定画符的角色");
end

function MultiOperationHelper:AddPaintCharmCommand(npc, paper, list)
	--获取添加任务所需的符咒name
	local spell_name_list = list or {};
	if #spell_name_list == 0 then
		return;
	end
	--获取添加任务所需的符纸Item
	local paper_list = {};
	--print(paper.def.Name);
	local paper_list = MultiOperationHelper:GetActableItems(paper, #spell_name_list, nil);
	if #paper_list == 0 then
		world:ShowMsgBox(string.format("没有可用的[color=#0000FF]%d品阶%s[color]。", paper.Rate, paper:GetName()));
		return;
	end
	--print(#spell_name_list.."  "..#paper_list);
	if #spell_name_list > #paper_list then  --提示符纸数量不足
		world:ShowMsgBox(string.format("计划添加%d个画符任务，缺少[color=#0000FF]%d品阶%s[color]%d张，已添加%d个任务。", #spell_name_list, paper.Rate, paper:GetName(), #spell_name_list-#paper_list, #paper_list));
	end
	local command_def = CS.XiaWorld.CommandMgr.Instance:GetDef("PaintCharm");
	command_def.Single = 0;
	for i=1, math.min(#spell_name_list, #paper_list) do  --UILogicMode_IndividualCommand.Apply2Thing() case g_emIndividualCommandType.PaintCharm
		local fu_value = CS.XiaWorld.GlobleDataMgr.Instance:GetFuValue(spell_name_list[i]) * 0.95;  --符咒品质
		if fu_value == nil or fu_value <= 0 then
			fu_value = 1;
		end
		--print(paper_list[i].def.Name.."  "..spell_name_list[i]);
		local item = CS.XiaWorld.PracticeMgr.Instance:RandomSpellItem(paper_list[i].def.Name, spell_name_list[i], fu_value, -1, -1, false, paper_list[i].Rate);--生成符咒Item
		npc.Bag:AddItem(item, nil);
		item.Author = npc:GetName();
		local command = npc:AddCommand("PaintCharm", paper_list[i], CS.XLua.Cast.Int32(item.ID));
		--print(command.def.Single);
		local dict = {};
		dict["Name"] = spell_name_list[i];
		dict["Value"] = item:GetQuality();
		CS.GameWatch.Instance:BuryingPoint(CS.XiaWorld.BuryingPointType.Fu, dict);
	end
	MultiOperationHelper:InterruptGetFun(npc);
end

function MultiOperationHelper:MultiEatItem(item)  --选择食用的npc
	CS.Wnd_SelectNpc.Instance:Select(
		WorldLua:GetSelectNpcCallback(function(rs)
			if (rs == nil or rs.Count == 0) then
				return;
			end
			local input_item = {{
				name = "食用次数：", 
				id = "count", 
				data = "1", 
				desc = "每个人重复食用物品的次数。"
			}};
			self.MultiSelectWindow:Open("多人食用", nil, nil, nil, function(inputdata)
				if inputdata[1].data == 0 then
					return;
				end
				local npc_ids = {};
				local num = inputdata[1].data;
				for _, id in pairs(rs) do
					for i=1, num do
						table.insert(npc_ids, id);
					end
				end
				self:Select2Eat(npc_ids, item);
			end,
			input_item, 220, true, nil, nil, nil);
			self.MultiSelectWindow.window:Center();
		end), 
	CS.XiaWorld.g_emNpcRank.Normal, 1, 99, nil, nil, "指定食用的角色");	
end

function MultiOperationHelper:Select2Eat(IDs, item)
	local item_list = self:GetActableItems(item, #IDs, nil);
	if #item_list == 0 then
		world:ShowMsgBox(string.format("没有可分配食用的[color=#0000FF]%d品阶%s[color]。请确认物品是否被禁用。", item.Rate, item:GetName()));
		return;
	end
	--print(#item_list);
	if #IDs > #item_list then  --提示物品数量不足
		local content = string.format("缺少[color=#0000FF]%d品阶%s[color]%d个。是否食用？", item.Rate, item:GetName(), #IDs-#item_list, #item_list);
		self.OperationMsgWindow:ShowMsg(nil, content, "是", "否", function()
			self:AddCommand2Eat(IDs, item_list);
		end);
	else
		self:AddCommand2Eat(IDs, item_list);
	end
end

function MultiOperationHelper:AddCommand2Eat(IDs, items)  --逐个添加食用命令
	if IDs == nil or items == nil or #IDs == 0 or #items == 0 then
		return;
	end
	for i=1, math.min(#IDs, #items) do
		local npc = CS.XiaWorld.ThingMgr.Instance:FindThingByID(IDs[i]);
		local item = items[i];
		if npc ~= nil then			
			npc:AddCommand("EatItem", item);
			self:InterruptGetFun(npc);
		end
	end
end

function MultiOperationHelper:MultiEquiptItem(item)  
	CS.Wnd_SelectNpc.Instance:Select(
		WorldLua:GetSelectNpcCallback(function(rs)
			if (rs == nil or rs.Count == 0) then
				return;
			end
			self:Select2Equipt(rs, item);
		end), 
	CS.XiaWorld.g_emNpcRank.Normal, 1, 99, nil, nil, "指定装备的角色");	
end

function MultiOperationHelper:Select2Equipt(IDs, item)
	local item_list = self:GetActableItems(item, IDs.Count, function(it)
		if item.def.Item.Lable == CS.XiaWorld.g_emItemLable.Spell then
			return (it:GetName() == item:GetName());
		end
		if it.StuffDef ~= nil then
			return (it.StuffDef.Name == item.StuffDef.Name);
		end
		return (item.Bind2Npc == 0);
	end);
	if #item_list == 0 then
		world:ShowMsgBox(string.format("没有可分配装备的[color=#0000FF]%d品阶%s[color]。请确认物品是否被禁用。", item.Rate, item:GetName()));
		return;
	end
	--print(#item_list);
	if IDs.Count > #item_list then--提示物品数量不足
		local content = string.format("缺少[color=#0000FF]%d品阶%s[color]%d个，只有前面%d人可分配装备。是否装备？", item.Rate, item:GetName(), IDs.Count-#item_list, #item_list);
		self.OperationMsgWindow:ShowMsg(nil, content, "是", "否", function()
			self:AddCommand2Equipt(IDs, item_list)
		end);
	else
		self:AddCommand2Equipt(IDs, item_list);
	end
end

function MultiOperationHelper:AddCommand2Equipt(IDs, items)  --逐个添加装备命令
	if IDs == nil or items == nil or IDs.Count == 0 or #items == 0 then
		return;
	end
	for i=0, math.min(IDs.Count, #items)-1 do
		local npc = CS.XiaWorld.ThingMgr.Instance:FindThingByID(IDs[i]);
		local item = items[i+1];
		if npc ~= nil then
			local equipt_type = npc:CheckEquipCell(item);
			if equipt_type == CS.XiaWorld.g_emEquipType.None then
				world:ShowMsgBox(string.format("[color=#0000FF]%s[color]没有对应的装备槽了。", npc:GetName()));
			else
				npc:AddCommand("EquipItem", item);
			end
			self:InterruptGetFun(npc);
		end
	end
end

function MultiOperationHelper:MultiPutItem(item) 
	local tips = {
		title = "说明",
		content = "按住左Shift键点选置物台。"
	};
	self.MultiSelectWindow:Open("批量放置", nil, nil, tips, function(inputdata)
		local item_list = self:GetActableItems(item, #inputdata, nil);
		if #inputdata > #item_list then
			world:ShowMsgBox(string.format("物品[color=#0000FF]%d品阶%s[color]数量不足。请确认是否被禁用。", item.Rate, item:GetName()));
		end
		for i=1, math.min(#inputdata, #item_list) do
			local it = CS.XiaWorld.ThingMgr.Instance:FindThingByID(inputdata[i].id);
			if it ~= nil then
				it.Bag:AddBegItem(item_list[i], 1, "PutCarry");
			end
		end
	end,
	nil, 300, false, nil, CS.XiaWorld.g_emThingType.Building, function(tg)
		return (tg.def.Name == "Building_ItemShelf" and tg.BuildingState == CS.XiaWorld.g_emBuildingState.Working);
	end);
	self.MultiSelectWindow.window:LeftTop();
end

function MultiOperationHelper:MultiRefiningFabao(npc)  --设置批量炼宝
	local g_emItemLable = CS.XiaWorld.g_emItemLable;
	if not self.mod_enable then
		return;
	end
	local tips = {
		title = "说明",
		content = "按住左Shift键点选物品；若物品的堆叠数>1，则可以设置个数。"
	};	
	self.MultiSelectWindow:Open("批量炼宝", nil, nil, tips, function(inputdata)
		self.refining_fabao_table = self.refining_fabao_table or {};
		self.refining_fabao_table[npc.ID] = nil;
		local items = {};
		for _, input in pairs(inputdata) do
			local cnt = 0;
			local it = CS.XiaWorld.ThingMgr.Instance:FindThingByID(input.id);
			if it ~= nil and it.FreeCount > 0 and input.data > 0 then
				cnt = math.min(it.FreeCount, input.data);
				for i=1, cnt do
					table.insert(items, input.id);
				end
			end
		end
		if #items > 0 then
			self.refining_fabao_table[npc.ID] = items;
			self:MultiRefiningFabaoBtn(npc, nil);
		end
	end,
	nil, 300, false, nil, CS.XiaWorld.g_emThingType.Item, function(tg)
		return (tg.def.Item.Lable ~= g_emItemLable.FightFabao and tg.def.Item.Lable ~= g_emItemLable.TreasureFabao and tg.def.Item.Lable ~= g_emItemLable.Esoterica and tg.Lock.FreeCount > 0);  --UILogicMode_IndividualCommand.CheckThing()
	end);
	self.MultiSelectWindow.window:LeftTop();
end

function MultiOperationHelper:CancelRefiningFabao(npc)  --取消批量炼宝
	if self.mod_enable and self.refining_fabao_table ~= nil and self.refining_fabao_table[npc.ID] ~= nil then
		self.refining_fabao_table[npc.ID] = nil;
		self:MultiRefiningFabaoBtn(npc, nil);
	end
end

function MultiOperationHelper:MultiRefiningFabaoBtn(npc, param)  --添加‘批量炼宝’或‘取消批量炼宝’按键
	npc:RemoveBtnData("批量炼宝");
	npc:RemoveBtnData("取消批量炼宝");
	if npc ~= self.last_npc then
		return;
	end
	if self.refining_fabao_table ~= nil and self.refining_fabao_table[npc.ID] ~= nil and #self.refining_fabao_table[npc.ID] > 0 then
		local txt = string.format("取消所有剩余的炼宝任务，正在炼制的法宝不会被取消。\n剩余炼宝任务：%d", #self.refining_fabao_table[npc.ID]);
		if param ~= nil then
			txt = txt.."\n"..param;
		end
		npc:AddBtnData("取消批量炼宝", "res/Sprs/ui/icon_lianbao01", self:GetBtnLua("CancelRefiningFabao", "取消批量炼宝"), txt, nil);
	else
		if (not npc.IsRent) and npc.GongKind ~= CS.XiaWorld.g_emGongKind.God and npc.EnemyType ~= CS.XiaWorld.Fight.g_emEnemyType.PlayerAttacker and npc:CanDoMagic() and (not npc.IsVistor) and
			(not npc.PropertyMgr:IsJobBan(CS.XiaWorld.g_emBehaviourWorkKind.Handwork)) and npc.IsPlayerThing and npc.Rank == CS.XiaWorld.g_emNpcRank.Disciple then  --ThingUICommandDefine
			npc:AddBtnData("批量炼宝", "res/Sprs/ui/icon_lianbao01", self:GetBtnLua("MultiRefiningFabao", "批量炼宝"), "选择多个物品，自动进行炼宝。", nil);
		end
	end
end

function MultiOperationHelper:AddRefiningFabao()  --检查并添加炼宝的命令
	local ThingMgr = CS.XiaWorld.ThingMgr.Instance;
	if self.mod_enable and self.refining_fabao_table ~= nil then
		for id, _ in pairs(self.refining_fabao_table) do
			local npc = ThingMgr:FindThingByID(id);
			if npc == nil or (not npc.IsDisciple) or npc.IsDeath or (not npc.IsPlayerThing) then
				self.refining_fabao_table[id] = nil;
			elseif npc:CheckCommandSingle("RefiningFabao", false) == nil and self.refining_fabao_table[id] ~= nil and #self.refining_fabao_table[id] > 0 and 
				(npc.JobEngine.CurJob ~= nil and npc.JobEngine.CurJob.jobdef ~= nil and npc.JobEngine.CurJob.jobdef.Name ~= "JobLeave2Explore") then
				local item = ThingMgr:FindThingByID(self.refining_fabao_table[id][1]);
				local flag = true;
				if item ~= nil then
					local need_ling = item.Rate * item.Rate * 500;
					if npc.LingV < need_ling then
						local txt = string.format("[color=#FF0000]灵气不足：%d[/color]", need_ling);
						self:MultiRefiningFabaoBtn(npc, txt);
						flag = false;
					else
						flag = true;
						if item.FreeCount > 0 and item.AtG and item.InWhoseBag <= 0 and item.InWhoseHand <= 0 then
							npc:AddCommand("RefiningFabao", CS.XiaWorld.g_emItemLable.FightFabao, item, CS.XLua.Cast.Int32(0));
							self:InterruptGetFun(npc);
							--print(npc.ID, item.ID);
						end
					end
				end
				if item == nil or flag then
					table.remove(self.refining_fabao_table[id], 1);
					if #self.refining_fabao_table[id] < 1 then
						self.refining_fabao_table[id] = nil;
					end
					self:MultiRefiningFabaoBtn(npc, nil);
				end
			end
		end
	end	
end

function MultiOperationHelper:GetActableItems(item, count, condition)  --获取可操作的物品
	local item_list = {};
	local item_count = CS.XiaWorld.World.Instance.Warehouse:GetItemCount(item.def.Name);
	local item_all = CS.XiaWorld.World.Instance.map.Things:FindItems(nil, 0, item_count, item.def.Name, 0, nil, 0, 9999, nil, false, false);
	if item_all ~= nil and item_all.Count > 0 then
		for _, it in pairs(item_all) do
			if it.Rate == item.Rate and (not it.TagData:CheckTagString("_Remote")) and (condition == nil or condition(it)) then
				for i=1, it.FreeCount do
					table.insert(item_list, it);
					count = count - 1;
					if count <= 0 then
						break;
					end
				end
			end
			if count <= 0 then
				break;
			end
		end	
	end	
	return item_list;
end

function MultiOperationHelper:InterruptGetFun(npc)  --打断当前的娱乐
	local job = npc.JobEngine.CurJob;
	if job ~= nil and job.jobdef ~= nil then
		local job_type = job.jobdef.Name;
		if job_type == "JobLookAtSky" or job_type == "JobPlayWithBuilding" then
			job:InterruptJob();
		end
	end
end

function MultiOperationHelper:AddBtn2Item(evt, thing, objs)  --向Item添加按键
	--print(thing);
	local g_emItemLable = CS.XiaWorld.g_emItemLable;
	if thing == self.last_item or not self.mod_enable then
		return;
	end
	self:RemoveBtnFromItem(self.last_item);
	self.last_item_id = thing.ID;
	self.last_item = thing;
	if thing ~= nil and thing.ThingType == CS.XiaWorld.g_emThingType.Item and thing.IsValid then
		self:RemoveBtnFromItem(thing);
		if thing.def.Item.Lable == g_emItemLable.SpellPaper then
			thing:AddBtnData("批量画符", "res/Sprs/ui/icon_huafu01", self:GetBtnLua("MultiFuPainter", "批量画符"), "使用同品阶同类型的符纸，进行批量画符，可设置画多种不同的符咒。", nil);
		end
		if thing:EatAble() then
			thing:AddBtnData("多人食用", "res/Sprs/ui/icon_shiyong01", self:GetBtnLua("MultiEatItem", "多人食用"), "选择多人，食用同品阶同名称的物品，并可设置连续食用多次。", nil);			
		end 
		if thing.def.Item.Lable ~= g_emItemLable.Esoterica and thing.def.Item.Lable ~= g_emItemLable.FightFabao and thing.def.Item.Lable ~= g_emItemLable.TreasureFabao and (not thing.IsMiBao) then
			thing:AddBtnData("多人装备", "res/Sprs/ui/icon_zhuangbeidaoju01", self:GetBtnLua("MultiEquiptItem", "多人装备"), "选择多人，装备同品阶同材料的物品。", nil);	
		end
--		if thing.def.MaxStack <= 1 and (thing.def.Item.Lable == g_emItemLable.Dan or thing.def.Item.Lable == g_emItemLable.Drug) then
--			thing:AddBtnData("批量放置", "res/Sprs/ui/icon_fangzhiwupin01", self:GetBtnLua("MultiPutItem", "批量放置"), "选择多个置物台，放置同品阶同名称的物品。", nil);			
--		end
	end
end

function MultiOperationHelper:AddBtn2Npc(evt, npc, objs)  --向NPC添加按键
	--print(npc);
	if npc ~= nil and npc.ThingType == CS.XiaWorld.g_emThingType.Npc then
		self:RemoveBtnFromNpc(npc);
		if not self.mod_enable then
			return;
		end
		if npc ~= self.last_npc then
			self:RemoveBtnFromNpc(self.last_npc);
			self.last_npc_id = npc.ID;
			self.last_npc = npc;
		end
		self:InterruptGetFun(npc);
		if self.MagicBtnWindow.window.isShowing then
			CS.FairyGUI.GRoot.inst:HidePopup(self.MagicBtnWindow.window.contentPane);
		end
		if npc.IsPlayerThing and npc.Rank == CS.XiaWorld.g_emNpcRank.Disciple and (not npc.IsVistor) and (not npc.IsGod) and npc.PropertyMgr.Practice.Magics.Count > 0 and
			(not npc.FightBody.IsFighting) and (not npc:HasSpecialFlag(CS.XiaWorld.g_emNpcSpecailFlag.FLAG_THUNDERING)) and npc.EnemyType ~= CS.XiaWorld.Fight.g_emEnemyType.PlayerAttacker then  --Panel_ThingInfo.UpdateBnts()
			for _, magic in pairs(self.magic_name_list) do
				if npc.PropertyMgr.Practice.Magics:Contains(magic) then
					npc:AddBtnData("批量神通", "res/Sprs/ui/icon_sousuo01", self:GetBtnLua("ShowMagicBtns", "批量神通"), "批量施展神通。", nil);
					break;
				end
			end	
		end
		self:MultiRefiningFabaoBtn(npc, nil);
	end
end

function MultiOperationHelper:RemoveBtnFromItem(item)  --移除Item上的按键
	if item ~= nil and item.IsValid then
		item:RemoveBtnData("批量画符");
		item:RemoveBtnData("多人食用");
		item:RemoveBtnData("多人装备");
		item:RemoveBtnData("批量放置");
	end
end

function MultiOperationHelper:RemoveBtnFromNpc(npc)  --移除NPC上的按键
	if npc ~= nil and npc.IsValid then
		npc:RemoveBtnData("神通");
		npc:RemoveBtnData("批量神通");
		npc:RemoveBtnData("批量炼宝");
		npc:RemoveBtnData("取消批量炼宝");
	end
end

function MultiOperationHelper:GetBtnLua(func_name, btn_name)  --点击按键时执行的lua
	return string.format(
		"local mod = GameMain:GetMod('MultiOperationHelper'); "..
		"if mod['%s'] ~= nil then "..
			"mod:%s(bind); "..
		"else "..
			"bind:RemoveBtnData('%s'); "..
		"end", func_name, func_name, btn_name);
--	return string.format("GameMain:GetMod('MultiOperationHelper'):%s(bind);", func_name);
end

function MultiOperationHelper:ShowMagicBtns(npc)  --显示批量施展神通的面板
	if self.mod_enable then
		self.MagicBtnWindow:ShowBtns(npc);
	end
end

function MultiOperationHelper:MagicEnter(npc, magic)  --点击某神通后进入对应的设置面板
	local ThingMgr = CS.XiaWorld.ThingMgr.Instance;
	local g_emThingType = CS.XiaWorld.g_emThingType;
	if npc == nil then
		return;
	end
	if magic == "CancelMagicAll" then
		self:CancelMagicAll(npc);
		return;
	end
	local magic_def = CS.XiaWorld.PracticeMgr.Instance:GetMagicDef(magic);
	if magic_def == nil then
		return;
	end
	if magic_def.Name == "AbsorbGong_5" or magic_def.Name == "AbsorbGong_6" then
		CS.Wnd_SelectNpc.Instance:Select(
			WorldLua:GetSelectNpcCallback(function(rs)
				if (rs == nil or rs.Count == 0) then
					return;
				end
				self:Magic2Cast(magic_def, npc, rs, rs.Count);
			end), 
		CS.XiaWorld.g_emNpcRank.Worker, 1, 99, nil, nil, magic_def.DisplayName);
	elseif magic_def.Name == "Prophesy_MapStory" or magic_def.Name == "LingCrystalMake" or magic_def.Name == "LingStoneMake" then
		local input_item = {{
			name = "施展次数：", 
			id = "count", 
			data = "", 
			desc = "重复施展神通的次数。"
		}};
		self.MultiSelectWindow:Open(magic_def.DisplayName, nil, nil, nil, function(inputdata)
			self:Magic2Cast(magic_def, npc, nil, inputdata[1].data);
		end,
		input_item, 220, true, nil, nil, nil);
		self.MultiSelectWindow.window:Center();
	elseif magic_def.Name == "SoulCrystalYouPowerUp" or magic_def.Name == "FengshuiItemOpen" or magic_def.Name == "AbsorbLing_Item" then
		local tips = {
			title = "说明",
			content = self.magic_tips[magic_def.Name]
		};
		self.MultiSelectWindow:Open(magic_def.DisplayName, nil, nil, tips, function(inputdata)
			local IDs = {};
			local index = 0;
			for _, input in pairs(inputdata) do
				local cnt = 0;
				local it = ThingMgr:FindThingByID(input.id);
				if self:CheckThing(npc, magic_def.Name, magic_def.SelectType, it) then
					cnt = math.min(it.FreeCount, input.data);
					if magic_def.Name == "SoulCrystalYouPowerUp" and it.FreeCount == 1 and it.Count == 1 then
						cnt = math.min(12, input.data);
					end
				end
				for i=1, cnt do
					IDs[index] = input.id;
					index = index + 1;
				end
			end
			self:Magic2Cast(magic_def, npc, IDs, index);
		end,
		nil, 300, false, nil, g_emThingType.Item, function(tg)
			return self:CheckThing(npc, magic_def.Name, magic_def.SelectType, tg);
		end);
		self.MultiSelectWindow.window:LeftTop();
	elseif magic_def.Name == "SeachSoul" or magic_def.Name == "PlantGrowUp" or magic_def.Name == "PlantGrowUp_Gong1" or 
	magic_def.Name == "PlantGrowUp_Gong9" or magic_def.Name == "MakeSoulCrystal" or magic_def.Name == "AbsorbLing_Body" or 
	magic_def.Name == "AbsorbGong_1" or magic_def.Name == "AbsorbGong_1_Gong9" or magic_def.Name == "AbsorbGong_2" or
	magic_def.Name == "AbsorbGong_2_Gong7" or magic_def.Name == "AbsorbGong_3" or magic_def.Name == "AbsorbGong_3_Gong11" or
	magic_def.Name == "AbsorbGong_7" then
		local thing_type = g_emThingType.Npc;
		if magic_def.SelectType == CS.XiaWorld.g_emIndividualCommandType.Plant then
			thing_type = g_emThingType.Plant;
		end
		self.MultiSelectWindow:Open(magic_def.DisplayName, nil, nil, nil, function(inputdata)
			local IDs = {};
			local index = 0;
			for _, input in pairs(inputdata) do
				local it = ThingMgr:FindThingByID(input.id);
				if self:CheckThing(npc, magic_def.Name, magic_def.SelectType, it) then
					IDs[index] = input.id;
					index = index + 1;
				end
			end
			self:Magic2Cast(magic_def, npc, IDs, index);
		end,
		nil, 300, false, nil, thing_type, function(tg)
			return self:CheckThing(npc, magic_def.Name, magic_def.SelectType, tg);
		end);
		self.MultiSelectWindow.window:LeftTop();	
	end
end

function MultiOperationHelper:CheckThing(npc, magic, stype, thing)  --检查thing是否可作为神通的对象  UILogicMode_IndividualCommand.CheckThing
	local g_emNpcSpecailFlag = CS.XiaWorld.g_emNpcSpecailFlag;
	local g_emPlantKind = CS.XiaWorld.g_emPlantKind;
	local CommandType = CS.XiaWorld.g_emIndividualCommandType;
	if magic ~= nil and thing ~= nil and thing.Lock.FreeCount > 0 then
		if (magic == "SoulCrystalYouPowerUp") or 
		(magic == "AbsorbLing_Item" and thing.LingV > 0) or
		(magic == "FengshuiItemOpen" and thing.FSItemState == 1) then
			return true;
		end
		if magic == "SeachSoul" and thing.CorpseTime > 0 and (not thing.IsCorpse) and 
		(not thing:HasSpecialFlag(g_emNpcSpecailFlag.FLAG_MAGIC)) and (not thing:HasSpecialFlag(g_emNpcSpecailFlag.FLAG_SeachSoul)) then
			return true;
		end
		if stype == CommandType.Plant and (thing.def.Plant.Kind == g_emPlantKind.HighPlant or thing.def.Plant.Kind == g_emPlantKind.LowPlant) then
			return true;
		end
		if magic == "MakeSoulCrystal" and thing.IsValid and (not thing.IsCorpse) and (not thing.IsPuppet) and (not thing.IsZombie) and
		(not thing.IsDisciple or thing.IsLingering) and (not thing:HasSpecialFlag(g_emNpcSpecailFlag.FLAG_CANTBEMAGIC)) and 
		(not thing:HasSpecialFlag(g_emNpcSpecailFlag.FLAG_MAGIC)) and (not thing:HasSpecialFlag(g_emNpcSpecailFlag.FLAG_DROPSOULCRYSTAL)) then
			return true;
		end
		if magic == "AbsorbLing_Body" and thing.IsCorpse and (not thing.IsBoss) and (not thing.IsPuppet) and (not thing.IsZombie) and 
		(not thing:HasSpecialFlag(g_emNpcSpecailFlag.FLAG_CANTBEMAGIC)) and (not thing:HasSpecialFlag(g_emNpcSpecailFlag.FLAG_MAGIC)) and
		(thing:CheckSpecialFlag(g_emNpcSpecailFlag.PuppetBindNpc) <= 0) then
			return true;
		end
		if (stype == CommandType.NormalNpc or stype == CommandType.NormalNpcRace or stype == CommandType.NormalRaceSexNpc) and
		thing.IsValid and (not thing.IsDeath) and (not thing.IsPuppet) and (not thing.IsZombie) and (not thing.IsDisciple) and
		((stype ~= CommandType.NormalNpcRace and stype ~= CommandType.NormalRaceSexNpc) or npc.Race == thing.Race) and 
		(stype ~= CommandType.NormalRaceSexNpc or npc.Sex ~= thing.Sex) and (not thing:HasSpecialFlag(g_emNpcSpecailFlag.FLAG_CANTBEMAGIC)) and 
		(not thing:HasSpecialFlag(g_emNpcSpecailFlag.FLAG_MAGIC)) then
			return true;
		end
	end
	return false;
end

function MultiOperationHelper:Magic2Cast(magic_def, npc, targets, count)  --设置后确定施展神通
	local OperationMsgWindow = GameMain:GetMod("Windows"):GetWindow("OperationMsgWindow");
	local re = self:CheckEnable(magic_def, npc, count);
	if re[2] < count then
		local content = string.format("只能施展神通%d次（%s）。是否施展神通？", re[2], re[1]);
		OperationMsgWindow:ShowMsg(nil, content, "是", "否", function() 
			self:AddMagicCommand(magic_def, npc, targets, re[2]); 
		end);
	else
		self:AddMagicCommand(magic_def, npc, targets, count);
	end
end

function MultiOperationHelper:CheckEnable(magic_def, npc, count)  --NpcMagicBnt.CheckEnable()  检查施展神通条件是否满足
	local World = CS.XiaWorld.World.Instance;
	local ThingMgr = CS.XiaWorld.ThingMgr.Instance;
	local g_emThingType = CS.XiaWorld.g_emThingType;
	local Map = CS.XiaWorld.World.Instance.map;
	local text = {};
	local valid_count = count;
	if npc.LingV < magic_def.CostLing * count then
		valid_count = math.min(valid_count, math.floor(npc.LingV / magic_def.CostLing));
		table.insert(text, "灵气不足");
	end
	if npc.MaxAge - npc.Age < magic_def.CostAge * count then
		valid_count = math.min(valid_count, math.floor((npc.MaxAge - npc.Age) / magic_def.CostAge));
		table.insert(text, "寿元不足");
	end
	if npc.PropertyMgr.Practice.StageValue < magic_def.CostGong * count then
		valid_count = math.min(valid_count, math.floor(npc.PropertyMgr.Practice.StageValue / magic_def.CostGong));
		table.insert(text, "修为不足");			
	end
	if magic_def.ItemCost ~= nil and magic_def.ItemCost.Count > 0 then
		for _, data in pairs(magic_def.ItemCost) do
			if World.Warehouse:GetItemCount(data.name) < data.count * count then
				valid_count = math.min(valid_count, math.floor(World.Warehouse:GetItemCount(data.name) / data.count));
				table.insert(text, string.format("%s不足", ThingMgr:GetDef(g_emThingType.Item, data.name).ThingName));
			end
		end
	end
	if magic_def.Name == "SoulCrystalYouPowerUp" then
		local item_count = World.Warehouse:GetItemCount("Item_SoulCrystalYou");
		local item_all = Map.Things:FindItems(nil, 0, item_count, "Item_SoulCrystalYou", 0, nil, 0, 9999, nil, false, false);
		local ct = 0;
		if item_all ~= nil and item_all.Count > 0 then
			for _, it in pairs(item_all) do
				if it.Actable then
					ct = ct + it.FreeCount;
					if ct >= count then
						break;
					end
				end
			end
		end
		if ct < count then
			valid_count = math.min(valid_count, ct);
			table.insert(text, string.format("%s不足", ThingMgr:GetDef(g_emThingType.Item, "Item_SoulCrystalYou").ThingName));
		end
	end
	text = table.concat(text, "、");
	return {text, valid_count}
end

function MultiOperationHelper:AddMagicCommand(magic_def, npc, targets, count)  --添加施展神通命令
	local ThingMgr = CS.XiaWorld.ThingMgr.Instance;
	local Map = CS.XiaWorld.World.Instance.map;
	local g_emIndividualCommandType = CS.XiaWorld.g_emIndividualCommandType;
	if magic_def.CMD ~= nil then
		local command_def = CS.XiaWorld.CommandMgr.Instance:GetDef(magic_def.CMD);
		command_def.Single = 0;
		--print(magic_def.CMD)
	end
	for i=0, count-1 do  --NpcMagicBnt.GetBntData()
		if magic_def.Type == CS.XiaWorld.MagicDef.MagicType.Class then
			if magic_def.SelectMode ~= CS.XiaWorld.g_emSelectMode.None then  --UILogicMode_MagicCommand
				local thing = ThingMgr:FindThingByID(targets[i]);
				local command = npc:AddCommand("MagicNormal", nil, true, magic_def.Name);
				if command ~= nil then
					self:ThingSetIcon(thing);
					command.keys = {targets[i]};
					command.WorkParam3 = magic_def.Name;
					command.EventOnFinished = function() 
						self:ThingRemoveIcon(thing);
					end
				end
			else
				local command = npc:AddCommand("MagicNormal", nil, false, magic_def.Name);
				if command ~= nil then
					command.WorkParam3 = magic_def.Name;
				end
			end
		elseif magic_def.SelectType ~= g_emIndividualCommandType.None then
			local thing = ThingMgr:FindThingByID(targets[i]);
			if magic_def.SelectType == g_emIndividualCommandType.SoulCrystalYouPowerUp then  --UILogicMode_IndividualCommand.Apply2Thing() case g_emIndividualCommandType.SoulCrystalYouPowerUp
				local cost_item = Map.Things:FindItem(nil, 9999, "Item_SoulCrystalYou", 0, false, nil, 0, 9999, nil, false);
				if cost_item == nil then
					world:ShowMsgBox("物品[color=#0000FF]幽珀[color]数量不足。请确认物品是否被禁用。");
					break;
				end
				local command = npc:AddCommand(magic_def.CMD, thing); 
				if command ~= nil then
					self:ThingSetIcon(thing);
					cost_item.Lock:Lock(command, 1);
					command.WorkParam2 = CS.XLua.Cast.Int32(cost_item.ID); 
					command.WorkParam3 = magic_def.Name;
					command.EventOnFinished = function() 
						self:ThingRemoveIcon(thing);
					end
					if thing.Lock.FreeCount < 1 then
						thing.Lock:UnLockAllByOwner(command);
					end
				end
			elseif magic_def.SelectType == g_emIndividualCommandType.NormalNpcRace and (magic_def.Name == "AbsorbGong_5" or magic_def.Name == "AbsorbGong_6") then 
				if thing:HasSpecialFlag(CS.XiaWorld.g_emNpcSpecailFlag.FLAG_MAGIC) then
					world:ShowMsgBox(string.format("[color=#0000FF]%s[color]已经是神通的施展对象，暂时无法成为神通对象。请取消神通或稍候再试。", thing:GetName()));
				else
					local command = npc:AddCommand(magic_def.CMD, thing);
					if command ~= nil then
						command.WorkParam3 = magic_def.Name;
					end
				end
			elseif magic_def.SelectType == g_emIndividualCommandType.DieStay or magic_def.SelectType == g_emIndividualCommandType.Plant or 
				magic_def.SelectType == g_emIndividualCommandType.AbsorbLing_Item or magic_def.SelectType == g_emIndividualCommandType.MakeSoulCrystal or
				magic_def.SelectType == g_emIndividualCommandType.AbsorbLing_Body or magic_def.SelectType == g_emIndividualCommandType.NormalNpc or 
				magic_def.SelectType == g_emIndividualCommandType.NormalNpcRace or magic_def.SelectType == g_emIndividualCommandType.NormalRaceSexNpc then
				local command = npc:AddCommand(magic_def.CMD, thing);
				if command ~= nil then
					self:ThingSetIcon(thing);
					command.WorkParam3 = magic_def.Name;
					command.EventOnFinished = function() 
						self:ThingRemoveIcon(thing);
					end	
				end
			end
		else
			local command = npc:AddCommand(magic_def.CMD, npc);
			if command ~= nil then
				command.WorkParam3 = magic_def.Name;
			end
		end
	end
	self:InterruptGetFun(npc);
end

function MultiOperationHelper:CheckMagicCommand(npc)  --获取npc所有待执行的神通命令
	local cmd_all = {};
	for _, magic in pairs(self.magic_name_list) do
		local magic_def = CS.XiaWorld.PracticeMgr.Instance:GetMagicDef(magic);
		if magic_def ~= nil then
			local magic_type = magic_def.CMD;
			if magic_def.Type == CS.XiaWorld.MagicDef.MagicType.Class then
				magic_type = "MagicNormal";
			end
			local cmd_list = npc:CheckCommand(magic_type, false);
			if cmd_list ~= nil and cmd_list.Count > 0 then
				for _, cmd in pairs(cmd_list) do
					if cmd.WorkParam3 == magic_def.Name then
						table.insert(cmd_all, cmd);
					end
				end
			end
		end
	end
	return cmd_all;
end

function MultiOperationHelper:CancelMagicAll(npc)  --取消npc所有待执行的神通命令
	local cmd_list = self:CheckMagicCommand(npc);
	for _, cmd in pairs(cmd_list) do
		--print(cmd.ID);
		cmd:FinishCommand(true, false);
	end
end

function MultiOperationHelper:SelectAllNpc()  --npc全选
	local Wnd_SelectNpc = CS.Wnd_SelectNpc.Instance;
	if Wnd_SelectNpc ~= nil and Wnd_SelectNpc.isShowing then
		xlua.private_accessible(CS.Wnd_SelectNpc);
		if Wnd_SelectNpc.MaxCount > 1 then
			local num = math.min(Wnd_SelectNpc.UIInfo.m_n25.numItems, Wnd_SelectNpc.MaxCount);
			for i=0, num-1 do
				local list_item = Wnd_SelectNpc.UIInfo.m_n25:GetChildAt(i);
				if not list_item.grayed then
					Wnd_SelectNpc.UIInfo.m_n25:AddSelection(i, false);
				end
			end
			local selection = Wnd_SelectNpc.UIInfo.m_n25:GetSelection();
			Wnd_SelectNpc.UIInfo.m_n27.enabled = true;
			Wnd_SelectNpc.UIInfo.m_n34.text = string.format("%d/(%d-%d)", selection.Count, Wnd_SelectNpc.MinCount, Wnd_SelectNpc.MaxCount);
		end
	end
end

function MultiOperationHelper:ThingSetIcon(thing)  --在thing上添加icon标记
	if thing ~= nil then
		local th_view;
		if thing.View ~= nil then
			th_view = thing.View;
		elseif thing.view ~= nil then
			th_view = thing.view;
		end
		if th_view ~= nil then
			th_view:SetIcon("res/Sprs/ui/icon_lingxi01");  --标记
		end		
	end
end

function MultiOperationHelper:ThingRemoveIcon(thing)  --移除thing上的icon标记
	if thing ~= nil then
		local th_view;
		if thing.View ~= nil then
			th_view = thing.View;
		elseif thing.view ~= nil then
			th_view = thing.view;
		end
		if th_view ~= nil then
			if thing.ThingType == CS.XiaWorld.g_emThingType.Item and not thing.Actable then  --Item上是否有禁用的标记
				th_view:SetIcon("res/Sprs/ui/icon_ban");
			else
				th_view:RemoveIcon();
			end
		end
	end
end

function MultiOperationHelper:CheckModLegal()
	local mod_name = "MultiOperationHelper";
--	local mod = CS.ModsMgr.Instance:FindMod(mod_name, nil, true);
	for _, mod in pairs(CS.ModsMgr.Instance.AllMods) do
		if (mod.IsActive and mod.Name == mod_name and mod.Author == "枫轩" and (mod.ID == "1866576765" or mod.ID == "2199817102947266095" or mod.ID == "2199817102947260321")) then
			return true;
		end
	end
	print(string.format("The mod: '%s' is illegal", mod_display_name));
	return false
end

function MultiOperationHelper:OnSetHotKey()
	local tbHotKey = { {ID = "SelectAllNpc" , Name = "全选(批量操作)" , Type = "Mod", InitialKey1 = "LeftControl+A" }};
	return tbHotKey;
end

function MultiOperationHelper:OnHotKey(ID, state)
	if not self.mod_enable then
		return;
	end
	if ID == "SelectAllNpc" and state == "down" then
		self:SelectAllNpc();
	end
end

function MultiOperationHelper:OnStep(dt)
	if not self.mod_enable then
		return;
	end
	self:AddRefiningFabao();
end

function MultiOperationHelper:OnLeave()
	print("MultiOperationHelper Leave");
end

function MultiOperationHelper:OnSave()--系统会将返回的table存档 table应该是纯粹的KV
	local save_data = {
		refining_fabao = self.refining_fabao_table,
		last_item_id = self.last_item_id,
		last_npc_id = self.last_npc_id,
	}
	return save_data;
end

function MultiOperationHelper:OnLoad(tbLoad)--读档时会将存档的table回调到这里
	SaveData = tbLoad or {};
end

MultiOperationHelper.magic_name_list = {
	"SeachSoul",				--搜魂
	"SoulCrystalYouPowerUp",	--幽淬
	"AbsorbGong_5",				--他化
	"AbsorbGong_6",				--寄生
	"LingCrystalMake",			--炼制灵晶
	"LingStoneMake",			--炼制灵石
	"Prophesy_MapStory",		--大衍神算
	"FengshuiItemOpen",			--风水鉴定
	"PlantGrowUp",				--御木诀
	"PlantGrowUp_Gong1",		--天霖诀
	"PlantGrowUp_Gong9",		--万木回春
	"AbsorbLing_Item",			--吸星掌
	"MakeSoulCrystal",			--凝珀诀
	"AbsorbLing_Body",			--天妖化血术
	"AbsorbGong_1",				--鼎炉吸真术
	"AbsorbGong_1_Gong9",		--元央归息法
	"AbsorbGong_2",				--风月幻境
	"AbsorbGong_2_Gong7",		--如意幻境
	"AbsorbGong_3",				--摄神御鬼大法
	"AbsorbGong_3_Gong11",		--九幽炼神
	"AbsorbGong_7",				--献祭
};

MultiOperationHelper.magic_tips = {
	["SeachSoul"] = "按住左Shift键点选小人",
	["SoulCrystalYouPowerUp"] = "按住左Shift键点选物品。若物品的堆叠数=1，则可以设置幽淬的次数；若物品的堆叠数>1，则可以设置幽淬的个数。幽淬次数范围0--12，幽淬个数范围0--99。",
	["FengshuiItemOpen"] = "按住左Shift键点选物品。",
	["AbsorbLing_Item"] = "按住左Shift键点选物品",
};


--UILogicMode_IndividualCommand.Apply2Thing()
--ThingUICommandDefine
--CommandMgr, CommandTypeDef
--Thing.AddBtnData()
--Panel_ThingInfo.UpdateBnts()
--EventMgr, g_emEvent
--MagicDef
--NpcMagicBnt.GetBntData()
--GObject, GComponent
--Wnd_SelectThing.OnShowUpdate()
--Npc.JobEngine.CurJob.GetDesc()
--Wnd_SelectNpc
--UILogicMode_IndividualCommand.CheckThing()