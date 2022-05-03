local Windows = GameMain:GetMod("Windows");--先注册一个新的MOD模块
local MagicBtnWindow = Windows:CreateWindow("MagicBtnWindow");
local MultiOperationHelper = GameMain:GetMod("MultiOperationHelper");
local MagicDef = CS.XiaWorld.MagicDef;
local g_emIndividualCommandType = CS.XiaWorld.g_emIndividualCommandType;
local g_emSelectMode = CS.XiaWorld.g_emSelectMode;
local CommandMgr = CS.XiaWorld.CommandMgr.Instance;
--GameDefine.SOULCRYSTALYOU_BASE = 1;

MagicBtnWindow.magic_name_list = {
	"SeachSoul",
	"SoulCrystalYouPowerUp",
	"AbsorbGong_5",
	"AbsorbGong_6",
	"LingCrystalMake",
	"LingStoneMake",
	"Prophesy_MapStory",
	"FengshuiItemOpen",
	"FengshuiItemCreate"
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
	["FengshuiItemCreate"] = "风水凝练"
};

MagicBtnWindow.setMagic_tips = {
	["SoulCrystalYouPowerUp"] = "按住左Shift键选定物品。若物品的堆叠数=1，则可以设置幽淬的次数；若物品的堆叠数>1，则可以设置幽淬的个数。幽淬次数0--20，幽淬个数0--99。",
	["FengshuiItemOpen"] = "按住左Shift键选定物品。",
	["FengshuiItemCreate"] = "按住左Shift键选定物品。若物品的堆叠数>1，则可以设置凝练的个数。凝练个数0--99" 
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
			local magic_def = PracticeMgr:GetMagicDef(magic);
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
	local magic_def = PracticeMgr:GetMagicDef(magic);
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
		--local SetMagicCastWindow = Windows:GetWindow("SetMagicCastWindow");
		local input_item = {{
			title = "施展次数：", 
			name = "count", 
			data = "0", 
			desc = "重复施展神通的次数"
		}};
		SetMagicCastWindow:Open(self.magic_table[magic_def.Name], nil, nil, nil, function(inputdata)
			self:Magic2Cast(magic_def, npc, nil, inputdata["count"]);
		end,
		input_item, 220, true, nil);
		SetMagicCastWindow.window:Center();
	elseif magic_def.Name == "SoulCrystalYouPowerUp" or magic_def.Name == "FengshuiItemCreate" or magic_def.Name == "FengshuiItemOpen" then
		self.itemID_list = {};
		self.last_item = nil;
		--self.effects = {};
		--local SetMagicCastWindow = Windows:GetWindow("SetMagicCastWindow");
		if SetMagicCastWindow.window.isShowing then
			SetMagicCastWindow:Hide();
		end
		local tips = {
			title = "说明",
			content = self.setMagic_tips[magic_def.Name]
		};
		SetMagicCastWindow:Open(self.magic_table[magic_def.Name], nil, nil, tips, function(inputdata)
			Event:UnRegisterEvent(g_emEvent.SelectItem, magic_def.Name);
			local IDs = {};
			local index = 0;
			for id, num in pairs(inputdata) do
				local cnt = 0;
				local it = ThingMgr:FindThingByID(id);
				if self:CheckThing(magic_def.Name, it) then
					cnt = math.min(it.FreeCount, num);
					if magic_def.Name == "SoulCrystalYouPowerUp" and it.FreeCount == 1 and it.Count == 1 then
						cnt = math.min(20, num);
					end
				end
				if cnt == 0 and it ~= nil and it.View ~= nil then
					it.View:RemoveIcon();
				end
				for i=1, cnt do
					IDs[index] = id;
					index = index + 1;
				end
			end
			--print(index);
			self:Magic2Cast(magic_def, npc, IDs, index);
		end,
		nil, 300, false, function(inputdata)
			Event:UnRegisterEvent(g_emEvent.SelectItem, magic_def.Name);
			for id, _ in pairs(inputdata) do
				local it = ThingMgr:FindThingByID(id);
				if it ~= nil and it.View ~= nil then
					it.View:RemoveIcon();
				end
			end
			--for _, effect in pairs(self.effects) do
				--effect:Kill();
			--end
		end);
		SetMagicCastWindow.window:LeftTop();
		Event:RegisterEvent(g_emEvent.SelectItem, function(evt, item, objs) 
			self:MultiSelectItem(evt, item, objs); 
		end, 
		magic_def.Name);
	elseif magic_def.Name == "SeachSoul" then
		self.npcID_list = {};
		self.last_npc = nil;
		--local SetMagicCastWindow = Windows:GetWindow("SetMagicCastWindow");
		if SetMagicCastWindow.window.isShowing then
			SetMagicCastWindow:Hide();
		end
		SetMagicCastWindow:Open(self.magic_table[magic_def.Name], nil, nil, nil, function(inputdata)
			Event:UnRegisterEvent(g_emEvent.SelectNpc, magic_def.Name);
			local IDs = {};
			local index = 0;
			for id, _ in pairs(inputdata) do
				local it = ThingMgr:FindThingByID(id);
				if self:CheckThing(magic_def.Name, it) then
					IDs[index] = id;
					index = index + 1;
				elseif it.view ~= nil then
					it.view:RemoveIcon();
				end
			end
			self:Magic2Cast(magic_def, npc, IDs, index);
		end,
		nil, 300, false, function(inputdata)
			Event:UnRegisterEvent(g_emEvent.SelectNpc, magic_def.Name);
			for id, _ in pairs(inputdata) do
				local it = ThingMgr:FindThingByID(id);
				if it ~= nil and it.view ~= nil then
					it.view:RemoveIcon();
				end
			end
		end);
		SetMagicCastWindow.window:LeftTop();
		Event:RegisterEvent(g_emEvent.SelectNpc, function(evt, thing, objs) 
			self:MultiSelectNpc(evt, thing, objs); 
		end, 
		magic_def.Name);		
	end
end

function MagicBtnWindow:CheckThing(magic, thing)
	if thing ~= nil and thing.Lock.FreeCount > 0 then
		if (magic == "SoulCrystalYouPowerUp" and thing.Rate < 12) or 
		(magic == "FengshuiItemCreate" and thing.FSItemState == -1) or 
		(magic == "FengshuiItemOpen" and thing.FSItemState == 1) then
			return true;
		end
		if magic == "SeachSoul" and thing.CorpseTime > 0 and (not thing.IsCorpse) and 
		(not thing:HasSpecialFlag(g_emNpcSpecailFlag.FLAG_MAGIC)) and (not thing:HasSpecialFlag(g_emNpcSpecailFlag.FLAG_SeachSoul)) then
			return true;
		end
	end
	return false;
end

function MagicBtnWindow:MultiSelectItem(event, item, objs)
	if item ~= nil and item ~= self.last_item then
		self.last_item = item;
		if MultiOperationHelper.shift and self:CheckThing(event, item) then
			for _, id in pairs(self.itemID_list) do
				if item.ID == id then
					return;
				end
			end
			--local SetMagicCastWindow = Windows:GetWindow("SetMagicCastWindow");
			--local effect = world:PlayEffect(90002, item.Key, 0);
			--table.insert(self.effects, effect);
			item.View:SetIcon("res/Sprs/ui/icon_lingxi01");  --标记物品
			local item_data = {
				title = item:GetName(), 
				name = item.ID, 
				data = "1", 
				desc = string.format("品阶：%d\n堆叠数量：%d\n可操作数量：%d", item.Rate, item.Count, item.FreeCount)
			};
			table.insert(self.itemID_list, item.ID);
			SetMagicCastWindow:AddListItems({item_data});
			--print(item:GetName());
		end
	end
end

function MagicBtnWindow:MultiSelectNpc(event, npc, objs)
	if npc ~= nil and npc ~= self.last_npc then
		self.last_npc = npc;
		if MultiOperationHelper.shift and self:CheckThing(event, npc) then
			for _, id in pairs(self.npcID_list) do
				if npc.ID == id then
					return;
				end
			end
			--local SetMagicCastWindow = Windows:GetWindow("SetMagicCastWindow");
			npc.view:SetIcon("res/Sprs/ui/icon_lingxi01");  --标记物品
			local npc_data = {
				title = npc:GetName(), 
				name = npc.ID, 
				data = "1",
				desc = string.format("功法：%s\n境界：%s\n道行：%s", npc.PropertyMgr.Practice.Gong.DisplayName, 
				GameDefine.GongStageLevelTxt[npc.PropertyMgr.Practice.GongStateLevel], npc.PropertyMgr.Practice.DaoHang)
			};
			table.insert(self.npcID_list, npc.ID);
			SetMagicCastWindow:AddListItems({npc_data});
			--print(npc:GetName());
		end
	end
end

function MagicBtnWindow:Magic2Cast(magic_def, npc, targets, count)
	local re = self:CheckEnable(magic_def, npc, count);
	if re[2] < count then
		--local OperationMsgWindow = Windows:GetWindow("OperationMsgWindow");
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
				table.insert(text, string.format("%s不足", data.name));
			end
		end
	end
	text = table.concat(text, "、");
	return {text, valid_count}
end

function MagicBtnWindow:AddMagicCommand(magic_def, npc, targets, count)  
	if magic_def.CMD ~= nil then
		local CommandTypeDef = CommandMgr:GetDef(magic_def.CMD);
		CommandTypeDef.Single = 0;  --可添加多条command
		--print(magic_def.CMD)
	end
	for i=0, count-1 do  --参考NpcMagicBnt.GetBntData()
		if magic_def.Type == MagicDef.MagicType.Class then
			if magic_def.SelectMode ~= g_emSelectMode.None then  --参考UILogicMode_MagicCommand
				local thing = ThingMgr:FindThingByID(targets[i]);
				local command = npc:AddCommand("MagicNormal", nil, true, magic_def.Name);
				command.keys = {targets[i]};
				command.WorkParam3 = magic_def.Name;
				command.EventOnFinished = function() 
					if thing.View ~= nil then
						thing.View:RemoveIcon();
					end
				end
			else
				local command = npc:AddCommand("MagicNormal", nil, false, magic_def.Name);
				command.WorkParam3 = magic_def.Name;
			end
		elseif magic_def.SelectType ~= g_emIndividualCommandType.None then
			local thing = ThingMgr:FindThingByID(targets[i]);
			if magic_def.SelectType == g_emIndividualCommandType.SoulCrystalYouPowerUp then  --参考UILogicMode_IndividualCommand.Apply2Thing() case g_emIndividualCommandType.SoulCrystalYouPowerUp
				local cost_item = Map.Things:FindItem(nil, 9999, "Item_SoulCrystalYou", 0, false, nil, 0, 9999, nil, false);
				if cost_item == nil then
					world:ShowMsgBox("物品[color=#0000FF]幽珀[color]数量不足。请确认物品是否被禁用。");
					break;
				end
				local command = npc:AddCommand(magic_def.CMD, thing); 
				cost_item.Lock:Lock(command, 1);
				command.WorkParam2 = CS.XLua.Cast.Int32(cost_item.ID);  --不转换会报错
				command.WorkParam3 = magic_def.Name;
				command.EventOnFinished = function() 
					if thing.View ~= nil then
						thing.View:RemoveIcon();
					end
				end
				if thing.Lock.FreeCount < 1 then
					thing.Lock:UnLockAllByOwner(command);
				end
			elseif magic_def.SelectType == g_emIndividualCommandType.NormalNpcRace then 
				if thing:HasSpecialFlag(g_emNpcSpecailFlag.FLAG_MAGIC) then
					world:ShowMsgBox(string.format("[color=#0000FF]%s[color]已经是神通的施展对象，暂时无法成为神通对象。请取消神通或稍候再试。", thing:GetName()));
				else
					local command = npc:AddCommand(magic_def.CMD, thing);
					command.WorkParam3 = magic_def.Name;
				end
			elseif magic_def.SelectType == g_emIndividualCommandType.DieStay then
				local command = npc:AddCommand(magic_def.CMD, thing);
				command.WorkParam3 = magic_def.Name;
				command.EventOnFinished = function() 
					if thing.view ~= nil then
						thing.view:RemoveIcon();
					end
				end				
			end
		else
			local command = npc:AddCommand(magic_def.CMD, npc);
			command.WorkParam3 = magic_def.Name;
		end
	end
	MultiOperationHelper:InterruptGetFun(npc);
end

function MagicBtnWindow:CheckMagicCommand(npc)
	local cmd_all = {};
	for _, magic in pairs(self.magic_name_list) do
		local magic_def = PracticeMgr:GetMagicDef(magic);
		if magic_def ~= nil then
			local magic_type = magic_def.CMD;
			if magic_def.Type == MagicDef.MagicType.Class then
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