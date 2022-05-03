local Windows = GameMain:GetMod("Windows");--先注册一个新的MOD模块
local MagicBtnWindow = Windows:CreateWindow("MagicBtnWindow");
local MultiOperationHelper = GameMain:GetMod("MultiOperationHelper");

MagicBtnWindow.magic_name_list = {
	"SeachSoul",
	"SoulCrystalYouPowerUp",
	"AbsorbGong_5",
	"AbsorbGong_6",
	"LingCrystalMake",
	"LingStoneMake",
	"Prophesy_MapStory",
	"FengshuiItemOpen",
--	"FengshuiItemCreate",
	"PlantGrowUp",
	"PlantGrowUp_Gong1",
	"PlantGrowUp_Gong9",
	"AbsorbLing_Item",
};

MagicBtnWindow.magic_table = {
	["SeachSoul"] = "搜魂大法",
	["SoulCrystalYouPowerUp"] = "幽淬之法",
	["AbsorbGong_5"] = "他化自在大法",
	["AbsorbGong_6"] = "魂体寄生",
	["LingCrystalMake"] = "炼制灵晶",
	["LingStoneMake"] = "炼制灵石",
	["Prophesy_MapStory"] = "大衍神算",
	["FengshuiItemOpen"] = "风水鉴定",
--	["FengshuiItemCreate"] = "风水凝练",
	["PlantGrowUp"] = "御木诀",
	["PlantGrowUp_Gong1"] = "天霖诀",
	["PlantGrowUp_Gong9"] = "万木回春",
	["AbsorbLing_Item"] = "吸星掌",
};

MagicBtnWindow.setMagic_tips = {
	["SeachSoul"] = "按住左Shift键点选小人",
	["SoulCrystalYouPowerUp"] = "按住左Shift键点选物品。若物品的堆叠数=1，则可以设置幽淬的次数；若物品的堆叠数>1，则可以设置幽淬的个数。幽淬次数范围0--12，幽淬个数范围0--99。",
	["FengshuiItemOpen"] = "按住左Shift键点选物品。",
--	["FengshuiItemCreate"] = "按住左Shift键点选物品。若物品的堆叠数>1，则可以设置凝练的个数。凝练个数范围0--99",
	["AbsorbLing_Item"] = "按住左Shift键点选物品",
};

function MagicBtnWindow:OnInit()
	--print("MagicBtnWindow OnInit");
	self.window.contentPane = UIPackage.CreateObject("MultiOperationHelper", "MagicBtnWindow");--载入UI包里的窗口
	self.list = self:GetChild("list");
	self.list.onClickItem:Add(function(context)
		self:ClickBtn(context);
		GRoot.inst:HidePopup(self.window.contentPane);
	end);
end

function MagicBtnWindow:ShowBtns(npc)
	self.npc = npc;
	if self.window.isShowing then
		self:OnShowUpdate();
	else
		self:Show();
	end	
end

function MagicBtnWindow:OnShowUpdate()
	--print("MagicBtnWindow OnShowUpdate");
	self.window:BringToFront();
	self.list:RemoveChildrenToPool();
	if self.npc == nil then
		return;
	end
	for _, magic in pairs(self.magic_name_list) do  --参考Panel_ThingInfo.UpdateBnts()
		if self.npc.PropertyMgr.Practice.Magics:Contains(magic) then
			local magic_def = CS.XiaWorld.PracticeMgr.Instance:GetMagicDef(magic);
			if magic_def ~= nil then
				local flag = false;
				local magic_btn = self.list:AddItemFromPool();
				magic_btn.title = magic_def.DisplayName;
				magic_btn.icon = magic_def.Icon;
				magic_btn.data = magic_def.Name;
				magic_btn.tooltips = magic_def.Desc;
				local text = "";
				if magic_def.CostLing > 0 then
					local str = string.format("\n灵气：%.0f(%.0f)", magic_def.CostLing, self.npc.LingV);
					if magic_def.CostLing > self.npc.LingV then
						str = "[color=#FF0000]"..str.."[/color]";
						flag = true;
					end
					text = text..str;
				end
				if magic_def.CostAge > 0 then
					local str = string.format("\n寿元：%.0f(%.0f)", magic_def.CostAge, self.npc.MaxAge-self.npc.Age);
					if magic_def.CostAge > self.npc.MaxAge - self.npc.Age then
						str = "[color=#FF0000]"..str.."[/color]";
						flag = true;
					end
					text = text..str;
				end
				if magic_def.ItemCost ~= nil and magic_def.ItemCost.Count > 0 then
					for _, item_data in pairs(magic_def.ItemCost) do
						local item = ThingMgr:GetDef(g_emThingType.Item, item_data.name);
						local count = World.Warehouse:GetItemCount(item_data.name);
						local str = string.format("\n%s：%d/%d", item.ThingName, item_data.count, count);
						if item_data.count > count then
							str = "[color=#FF0000]"..str.."[/color]";
							flag = true;
						end
						text = text..str;
					end
				end
				if magic_def.CostGong > 0 then
					local str = string.format("\n修为：%.0f(%.0f)", magic_def.CostGong, self.npc.PropertyMgr.Practice.StageValue);
					if magic_def.CostGong > self.npc.PropertyMgr.Practice.StageValue then
						str = "[color=#FF0000]"..str.."[/color]";
						flag = true;
					end
					text = text..str;
				end
				if text ~= "" then
					magic_btn.tooltips = magic_btn.tooltips.."\n"..text;
				end
				magic_btn.grayed = flag;
				magic_btn.enabled = not flag;
			end
		end
	end
	local magic_btn = self.list:AddItemFromPool();  --添加取消全部神通
	magic_btn.title = "取消全部神通";
	magic_btn.icon = "res/Sprs/ui/icon_lingxi01";
	magic_btn.data = "CancelMagicAll";
	magic_btn.tooltips = "取消该NPC所有批量施展的神通。\n";
	local cmd_list = self:CheckMagicCommand(self.npc);
	magic_btn.grayed = (#cmd_list < 1);
	magic_btn.enabled = not (#cmd_list < 1);
	for mg, name in pairs(self.magic_table) do
		local num = 0;
		for _, cmd in pairs(cmd_list) do
			if cmd.WorkParam3 == mg then
				num = num + 1;
			end
		end
		if num > 0 then
			magic_btn.tooltips = magic_btn.tooltips..string.format("\n%s：%d", name, num);
		end
	end
	GRoot.inst:ShowPopup(self.window.contentPane);  --参考Wnd_SelectThing.OnShowUpdate()
	self.window.contentPane.onRemovedFromStage:Add(function() self.window:Hide(); end);
end

function MagicBtnWindow:ClickBtn(context)
	local magic = context.data.data;
	local npc = self.npc;
	local Event = GameMain:GetMod("_Event");
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
		g_emNpcRank.Worker, 1, 99, nil, nil, self.magic_table[magic_def.Name]);
	elseif magic_def.Name == "Prophesy_MapStory" or magic_def.Name == "LingCrystalMake" or magic_def.Name == "LingStoneMake" then
		local input_item = {{
			name = "施展次数：", 
			id = "count", 
			data = "", 
			desc = "重复施展神通的次数。"
		}};
		MultiSelectWindow:Open(self.magic_table[magic_def.Name], nil, nil, nil, function(inputdata)
			self:Magic2Cast(magic_def, npc, nil, inputdata[1].data);
		end,
		input_item, 220, true, nil, nil, nil);
		MultiSelectWindow.window:Center();
	elseif magic_def.Name == "SoulCrystalYouPowerUp" or magic_def.Name == "FengshuiItemCreate" or magic_def.Name == "FengshuiItemOpen" or magic_def.Name == "AbsorbLing_Item" then
		local tips = {
			title = "说明",
			content = self.setMagic_tips[magic_def.Name]
		};
		MultiSelectWindow:Open(self.magic_table[magic_def.Name], nil, nil, tips, function(inputdata)
			local IDs = {};
			local index = 0;
			for _, input in pairs(inputdata) do
				local cnt = 0;
				local it = ThingMgr:FindThingByID(input.id);
				if self:CheckThing(magic_def.Name, it) then
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
			return self:CheckThing(magic_def.Name, tg);
		end);
		MultiSelectWindow.window:LeftTop();
	elseif magic_def.Name == "SeachSoul" or magic_def.Name == "PlantGrowUp" or magic_def.Name == "PlantGrowUp_Gong1" or magic_def.Name == "PlantGrowUp_Gong9" then
		local thing_type = g_emThingType.Plant;
		if magic_def.Name == "SeachSoul" then
			thing_type = g_emThingType.Npc;
		end
		MultiSelectWindow:Open(self.magic_table[magic_def.Name], nil, nil, nil, function(inputdata)
			local IDs = {};
			local index = 0;
			for _, input in pairs(inputdata) do
				local it = ThingMgr:FindThingByID(input.id);
				if self:CheckThing(magic_def.Name, it) then
					IDs[index] = input.id;
					index = index + 1;
				end
			end
			self:Magic2Cast(magic_def, npc, IDs, index);
		end,
		nil, 300, false, nil, thing_type, function(tg)
			return self:CheckThing(magic_def.Name, tg);
		end);
		MultiSelectWindow.window:LeftTop();	
	end
end

function MagicBtnWindow:CheckThing(magic, thing)
	if magic ~= nil and thing ~= nil and thing.Lock.FreeCount > 0 then
		if (magic == "SoulCrystalYouPowerUp") or 
		(magic == "AbsorbLing_Item" and thing.LingV > 0) or
		(magic == "FengshuiItemCreate" and thing.FSItemState == -1) or 
		(magic == "FengshuiItemOpen" and thing.FSItemState == 1) then
			return true;
		end
		if magic == "SeachSoul" and thing.CorpseTime > 0 and (not thing.IsCorpse) and 
		(not thing:HasSpecialFlag(g_emNpcSpecailFlag.FLAG_MAGIC)) and (not thing:HasSpecialFlag(g_emNpcSpecailFlag.FLAG_SeachSoul)) then
			return true;
		end
		if (magic == "PlantGrowUp" or magic == "PlantGrowUp_Gong1" or magic == "PlantGrowUp_Gong9") and 
		(thing.def.Plant.Kind == g_emPlantKind.HighPlant or thing.def.Plant.Kind == g_emPlantKind.LowPlant) then
			return true;
		end
	end
	return false;
end

function MagicBtnWindow:Magic2Cast(magic_def, npc, targets, count)
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

function MagicBtnWindow:CheckEnable(magic_def, npc, count)  --参考NpcMagicBnt.CheckEnable()
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

function MagicBtnWindow:AddMagicCommand(magic_def, npc, targets, count)  
	if magic_def.CMD ~= nil then
		local command_def = CS.XiaWorld.CommandMgr.Instance:GetDef(magic_def.CMD);
		command_def.Single = 0;  --可添加多条command
		--print(magic_def.CMD)
	end
	for i=0, count-1 do  --参考NpcMagicBnt.GetBntData()
		if magic_def.Type == CS.XiaWorld.MagicDef.MagicType.Class then
			if magic_def.SelectMode ~= CS.XiaWorld.g_emSelectMode.None then  --参考UILogicMode_MagicCommand
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
		elseif magic_def.SelectType ~= CS.XiaWorld.g_emIndividualCommandType.None then
			local thing = ThingMgr:FindThingByID(targets[i]);
			if magic_def.SelectType == CS.XiaWorld.g_emIndividualCommandType.SoulCrystalYouPowerUp then  --参考UILogicMode_IndividualCommand.Apply2Thing() case g_emIndividualCommandType.SoulCrystalYouPowerUp
				local cost_item = Map.Things:FindItem(nil, 9999, "Item_SoulCrystalYou", 0, false, nil, 0, 9999, nil, false);
				if cost_item == nil then
					world:ShowMsgBox("物品[color=#0000FF]幽珀[color]数量不足。请确认物品是否被禁用。");
					break;
				end
				local command = npc:AddCommand(magic_def.CMD, thing); 
				if command ~= nil then
					self:ThingSetIcon(thing);
					cost_item.Lock:Lock(command, 1);
					command.WorkParam2 = CS.XLua.Cast.Int32(cost_item.ID);  --不转换会报错
					command.WorkParam3 = magic_def.Name;
					command.EventOnFinished = function() 
						self:ThingRemoveIcon(thing);
					end
					if thing.Lock.FreeCount < 1 then
						thing.Lock:UnLockAllByOwner(command);
					end
				end
			elseif magic_def.SelectType == CS.XiaWorld.g_emIndividualCommandType.NormalNpcRace then 
				if thing:HasSpecialFlag(g_emNpcSpecailFlag.FLAG_MAGIC) then
					world:ShowMsgBox(string.format("[color=#0000FF]%s[color]已经是神通的施展对象，暂时无法成为神通对象。请取消神通或稍候再试。", thing:GetName()));
				else
					local command = npc:AddCommand(magic_def.CMD, thing);
					if command ~= nil then
						command.WorkParam3 = magic_def.Name;
					end
				end
			elseif magic_def.SelectType == CS.XiaWorld.g_emIndividualCommandType.DieStay or 
			magic_def.SelectType == CS.XiaWorld.g_emIndividualCommandType.Plant or 
			magic_def.SelectType == CS.XiaWorld.g_emIndividualCommandType.AbsorbLing_Item then
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
	MultiOperationHelper:InterruptGetFun(npc);
end

function MagicBtnWindow:ThingSetIcon(thing)
	if thing ~= nil then
		local th_view;
		if thing.View ~= nil then
			th_view = thing.View;
		elseif thing.view ~= nil then
			th_view = thing.view;
		end
		if th_view ~= nil then
			th_view:SetIcon("res/Sprs/ui/icon_lingxi01");  --标记物品
		end		
	end
end

function MagicBtnWindow:ThingRemoveIcon(thing)
	if thing ~= nil then
		local th_view;
		if thing.View ~= nil then
			th_view = thing.View;
		elseif thing.view ~= nil then
			th_view = thing.view;
		end
		if th_view ~= nil then
			if thing.ThingType == g_emThingType.Item and not thing.Actable then
				th_view:SetIcon("res/Sprs/ui/icon_ban");
			else
				th_view:RemoveIcon();
			end
		end
	end
end

function MagicBtnWindow:CheckMagicCommand(npc)
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

function MagicBtnWindow:CancelMagicAll(npc)
	local cmd_list = self:CheckMagicCommand(npc);
	for _, cmd in pairs(cmd_list) do
		--print(cmd.ID);
		cmd:FinishCommand(true, false);
	end
end

function MagicBtnWindow:OnHide()
	self.list:RemoveChildrenToPool();
	--print("MagicBtnWindow OnHide");
end

--参考UILogicMode_IndividualCommand.CheckThing()