local Windows = GameMain:GetMod("Windows");--先注册一个新的MOD模块
local MagicBtnWindow = Windows:CreateWindow("MagicBtnWindow");
local MultiOperationHelper = GameMain:GetMod("MultiOperationHelper");

function MagicBtnWindow:OnInit()
	--print("MagicBtnWindow OnInit");
	self.window.contentPane = CS.FairyGUI.UIPackage.CreateObject("MultiOperationHelper", "MagicBtnWindow");--载入UI包里的窗口
	self.list = self:GetChild("list");
	self.list.onClickItem:Add(function(context)
		self:ClickBtn(context);
		CS.FairyGUI.GRoot.inst:HidePopup(self.window.contentPane);
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
	for _, magic in pairs(MultiOperationHelper.magic_name_list) do  --Panel_ThingInfo.UpdateBnts()
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
					local str = string.format("\n寿元：%.0f(%.0f)", magic_def.CostAge, self.npc.MaxAge - self.npc.Age);
					if magic_def.CostAge > self.npc.MaxAge - self.npc.Age then
						str = "[color=#FF0000]"..str.."[/color]";
						flag = true;
					end
					text = text..str;
				end
				if magic_def.ItemCost ~= nil and magic_def.ItemCost.Count > 0 then
					for _, item_data in pairs(magic_def.ItemCost) do
						local item = CS.XiaWorld.ThingMgr.Instance:GetDef(CS.XiaWorld.g_emThingType.Item, item_data.name);
						local count = CS.XiaWorld.World.Instance.Warehouse:GetItemCount(item_data.name);
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
	local cmd_list = MultiOperationHelper:CheckMagicCommand(self.npc);
	magic_btn.grayed = (#cmd_list < 1);
	magic_btn.enabled = not (#cmd_list < 1);
	for mg, name in pairs(MultiOperationHelper.magic_table) do
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
	CS.FairyGUI.GRoot.inst:ShowPopup(self.window.contentPane);  --Wnd_SelectThing.OnShowUpdate()
	self.window.contentPane.onRemovedFromStage:Add(function() self.window:Hide(); end);
end

function MagicBtnWindow:ClickBtn(context)
	local magic = context.data.data;
	local npc = self.npc;
	MultiOperationHelper:MagicEnter(npc, magic)
end

function MagicBtnWindow:OnHide()
	self.list:RemoveChildrenToPool();
	--print("MagicBtnWindow OnHide");
end

--UILogicMode_IndividualCommand.CheckThing()