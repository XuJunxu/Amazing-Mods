local MultiOperationHelper = GameMain:NewMod("MultiOperationHelper");--先注册一个新的MOD模块
local Windows = GameMain:GetMod("Windows");

function MultiOperationHelper:OnBeforeInit()	--这个会在所有初始化之前调用(包含MOD本身)，大量的对象都还不存在，用于处理一些与系统数据相关的逻辑，谨慎使用
	--print("MultiOperationHelper OnBeforeInit");
end

function MultiOperationHelper:OnInit()
	--print("MultiOperationHelper OnInit");
end

function MultiOperationHelper:OnEnter()
	self.shift = false;
	self.last_item = nil;
	self.last_npc = nil;
	self.mod_enable = true;
	ShowLingWindow = Windows:GetWindow("ShowLingWindow");
	OperationMsgWindow = Windows:GetWindow("OperationMsgWindow");
	MultiFuPainterWindow = Windows:GetWindow("MultiFuPainterWindow");
	MultiSelectWindow = Windows:GetWindow("MultiSelectWindow");
	MagicBtnWindow = Windows:GetWindow("MagicBtnWindow");
	ShowLingWindow:Init();
	OperationMsgWindow:Init();
	MultiFuPainterWindow:Init();
	MultiSelectWindow:Init();
	MagicBtnWindow:Init();
	local Event = GameMain:GetMod("_Event");
	Event:RegisterEvent(g_emEvent.SelectItem,  function(evt, item, objs) 
		if item ~= self.last_item then
			self.last_item = item;
			self:AddBtn2Item(evt, item, objs); 
		end
	end, "SelectItem");
	Event:RegisterEvent(g_emEvent.SelectNpc,  function(evt, npc, objs) 
--		if npc ~= self.last_npc then
--			self.last_npc = npc;
		self:AddBtn2Npc(evt, npc, objs); 
--		end
	end, "SelectNpc");
	if World.GameMode == CS.XiaWorld.g_emGameMode.Fight then
		self.mod_enable = false;
	end
	print("MultiOperationHelper OnEnter");
end

function MultiOperationHelper:OnSetHotKey()
	local tbHotKey = { {ID = "MultiSelect" , Name = "批量选择(批量操作)" , Type = "Mod", InitialKey1 = "LeftShift" },
						{ID = "ShowLing" , Name = "显示灵气浓度" , Type = "Mod", InitialKey1 = "RightControl+Semicolon", InitialKey2 = "LeftControl+Semicolon" }};
	return tbHotKey;
	--print("MultiOperationHelper OnSetHotKey");
end

function MultiOperationHelper:OnHotKey(ID, state)
	if ID == "MultiSelect" then 
		if state == "down" then
			self.shift = true;
		elseif state == "up" then
			self.shift = false;
		end
	end	 
	if ID == "ShowLing" and state == "down" and self.mod_enable then 
		if ShowLingWindow.window.isShowing then
			ShowLingWindow:Hide();
		else
			ShowLingWindow:Show();
		end
	end
end

function MultiOperationHelper:MultiFuPainter(item)  --选择画符的npc
	--self.item = item;
	CS.Wnd_SelectNpc.Instance:Select(
		WorldLua:GetSelectNpcCallback(function(rs)
			if (rs == nil or rs.Count == 0) then
				return;
			end
			local npc = ThingMgr:FindThingByID(rs[0]);
			MultiFuPainterWindow:Open(npc, item);
		end), 
	g_emNpcRank.Disciple, 1, 1, nil, nil, "指定画符的角色");
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
			MultiSelectWindow:Open("多人食用", nil, nil, nil, function(inputdata)
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
			MultiSelectWindow.window:Center();
		end), 
	g_emNpcRank.Normal, 1, 99, nil, nil, "指定食用的角色");	
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
		OperationMsgWindow:ShowMsg(nil, content, "是", "否", function()
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
		local npc = ThingMgr:FindThingByID(IDs[i]);
		local item = items[i];
		npc:AddCommand("EatItem", item);
		self:InterruptGetFun(npc);
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
	g_emNpcRank.Normal, 1, 99, nil, nil, "指定装备的角色");	
end

function MultiOperationHelper:Select2Equipt(IDs, item)
	local item_list = self:GetActableItems(item, IDs.Count, function(it)
		if item.def.Item.Lable == g_emItemLable.Spell then
			return it:GetName() == item:GetName();
		end
		if it.StuffDef ~= nil then
			return it.StuffDef.Name == item.StuffDef.Name;
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
		OperationMsgWindow:ShowMsg(nil, content, "是", "否", function()
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
		local npc = ThingMgr:FindThingByID(IDs[i]);
		local item = items[i+1];
		local equipt_type = npc:CheckEquipCell(item);
		if equipt_type == CS.XiaWorld.g_emEquipType.None then
			world:ShowMsgBox(string.format("[color=#0000FF]%s[color]没有对应的装备槽了。", npc:GetName()));
		else
			npc:AddCommand("EquipItem", item);
		end
		self:InterruptGetFun(npc);
	end
end

function MultiOperationHelper:MultiPutItem(item) 
	MultiSelectWindow:Open("批量放置", nil, nil, nil, function(inputdata)
		local item_list = self:GetActableItems(item, #inputdata, nil);
		if #inputdata > #item_list then
			world:ShowMsgBox(string.format("物品数量不足[color=#0000FF]%d品阶%s[color]。请确认物品是否被禁用。", item.Rate, item:GetName()));
		end
		for i=1, math.min(#inputdata, #item_list) do
			local it = ThingMgr:FindThingByID(inputdata[i].id);
			it.Bag:AddBegItem(item_list[i], 1, "PutCarry");
		end
	end,
	nil, 300, false, nil, g_emThingType.Building, function(tg)
		return (tg.def.Name == "Building_ItemShelf" and tg.BuildingState == CS.XiaWorld.g_emBuildingState.Working);
	end);
	MultiSelectWindow.window:LeftTop();
end

function MultiOperationHelper:GetActableItems(item, count, condition)  --获取可操作的物品
	local item_list = {};
	local item_count = World.Warehouse:GetItemCount(item.def.Name);
	local item_all = Map.Things:FindItems(nil, 0, item_count, item.def.Name, 0, nil, 0, 9999, nil, false, false);
	if item_all ~= nil and item_all.Count > 0 then
		for _, it in pairs(item_all) do
			if it.Rate == item.Rate and (condition == nil or condition(it)) then
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

function MultiOperationHelper:ShowMagicBtns(npc)  --显示批量施展神通的面板
	if self.mod_enable then
		MagicBtnWindow:ShowBtns(npc);
	end
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

function MultiOperationHelper:AddBtn2Item(evt, thing, objs)
	--print(thing);
	if not self.mod_enable then
		return;
	end
	if thing ~= nil and thing.ThingType == g_emThingType.Item and thing.IsValid then 
		if thing.def.Item.Lable == g_emItemLable.SpellPaper then
			thing:RemoveBtnData("批量画符");
			thing:AddBtnData("批量画符", "res/Sprs/ui/icon_huafu01", "GameMain:GetMod('MultiOperationHelper'):MultiFuPainter(bind)", "使用同品阶同类型的符纸，进行批量画符。", nil);
		end
		if thing:EatAble() then
			thing:RemoveBtnData("多人食用");
			thing:AddBtnData("多人食用", "res/Sprs/ui/icon_shiyong01", "GameMain:GetMod('MultiOperationHelper'):MultiEatItem(bind)", "选择多人，食用同品阶同名称的物品。", nil);			
		end 
		if thing.def.Item.Lable ~= g_emItemLable.Esoterica and thing.def.Item.Lable ~= g_emItemLable.FightFabao and thing.def.Item.Lable ~= g_emItemLable.TreasureFabao and (not thing.IsMiBao) then
			thing:RemoveBtnData("多人装备");
			thing:AddBtnData("多人装备", "res/Sprs/ui/icon_zhuangbeidaoju01", "GameMain:GetMod('MultiOperationHelper'):MultiEquiptItem(bind)", "选择多人，装备同品阶同材料的物品。", nil);	
		end
		if thing.def.MaxStack <= 1 and (thing.def.Item.Lable == g_emItemLable.Dan or thing.def.Item.Lable == g_emItemLable.Drug) then
			thing:RemoveBtnData("批量放置");
			thing:AddBtnData("批量放置", "res/Sprs/ui/icon_fangzhiwupin01", "GameMain:GetMod('MultiOperationHelper'):MultiPutItem(bind)", "选择多个置物台，放置同品阶同名称的物品。", nil);			
		end
	end
end

function MultiOperationHelper:AddBtn2Npc(evt, npc, objs)
	--print(npc);
	if npc ~= nil and npc.ThingType == g_emThingType.Npc then
		npc:RemoveBtnData("神通");
		if not self.mod_enable then
			return;
		end
		MultiOperationHelper:InterruptGetFun(npc);
		if MagicBtnWindow.window.isShowing then
			GRoot.inst:HidePopup(MagicBtnWindow.window.contentPane);
		end
		if npc.IsPlayerThing and npc.Rank == g_emNpcRank.Disciple and (not npc.IsVistor) and (not npc.IsGod) and npc.PropertyMgr.Practice.Magics.Count > 0 then  --参考Panel_ThingInfo.UpdateBnts()
			for _, magic in pairs(MagicBtnWindow.magic_name_list) do
				if npc.PropertyMgr.Practice.Magics:Contains(magic) then
					npc:AddBtnData("神通", "res/Sprs/ui/icon_sousuo01", "GameMain:GetMod('MultiOperationHelper'):ShowMagicBtns(bind)", "批量施展神通。", nil);
					return;
				end
			end	
		end
	end
end

function MultiOperationHelper:OnLeave()
	print("MultiOperationHelper Leave");
end

function MultiOperationHelper:OnSave()--系统会将返回的table存档 table应该是纯粹的KV
	return nil;
end

function MultiOperationHelper:OnLoad(tbLoad)--读档时会将存档的table回调到这里

end



--参考UILogicMode_IndividualCommand.Apply2Thing()
--参考ThingUICommandDefine
--参考CommandMgr, CommandTypeDef
--参考Thing.AddBtnData()
--参考Panel_ThingInfo.UpdateBnts()
--参考EventMgr, g_emEvent
--参考MagicDef
--参考NpcMagicBnt.GetBntData()
--参考GObject, GComponent
--参考Wnd_SelectThing.OnShowUpdate()
--参考Npc.JobEngine.CurJob.GetDesc()
--参考Wnd_SelectNpc
--参考UILogicMode_IndividualCommand.CheckThing()