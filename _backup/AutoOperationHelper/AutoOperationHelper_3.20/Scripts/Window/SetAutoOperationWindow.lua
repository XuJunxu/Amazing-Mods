local Windows = GameMain:GetMod("Windows");
local SetAutoOperationWindow = Windows:CreateWindow("SetAutoOperationWindow");
local AutoOperationHelper = GameMain:GetMod("AutoOperationHelper");

function SetAutoOperationWindow:OnInit()
	self.window.contentPane = CS.FairyGUI.UIPackage.CreateObject("AutoOperationHelper", "SetAutoOperationWindow");
	self.title = self:GetChild("title");
	self.tips = self:GetChild("tips");
	self.check1 = self:GetChild("check1");
	self.check2 = self:GetChild("check2");
	self.check3 = self:GetChild("check3");
	self.check4 = self:GetChild("check4");
	self.list = self:GetChild("list");
	self.btn1 = self:GetChild("btn1");
	self.btn2 = self:GetChild("btn2");
	
	self.title.title = XT("自动搬运设置")
	self.tips.title = XT("说明");
	self.check1.title = XT("自动搜身");
	self.check2.title = XT("自动屠宰");
	self.check3.title = XT("灵植成熟提醒");
	self.check4.title = XT("自动领取势力点储存");
	self.btn1.title = XT("确定");
	self.btn2.title = XT("取消");
	self.tips.tooltips = XT("按住左Shift键，鼠标左键点击仓库/农田/药田中的任意位置将该区域添加到设置面板，设置该区域作为弥留/尸体/昏迷小人的存放区以及使用优先级，当敌人变成弥留/尸体/昏迷时就会被自动搬运到对应区域。\n\n按住左Shift键，鼠标右键点击设置面板上的区域名，可以将该区域删除。\n\n如果出现不会自动搬运，可以打开设置面板后直接点确定。");
	self.check1.tooltips = XT("自动搜身弥留或尸体小人，对昏倒的小人无效。");
	self.check2.tooltips = XT("自动屠宰死亡的动物和妖兽。");
	self.check3.tooltips = XT("当各历练地点的灵植和造化玉籽成熟时，会弹出消息提醒。");
	self.check4.tooltips = XT("每天0点自动领取各势力点仓库的物资。");
	self.btn1.onClick:Add(function(context)
		self:Confirm();
		self:Hide();
	end);
	self.btn2.onClick:Add(function(context)
		self:Hide();
	end);
	self.list.onRightClickItem:Add(function(context)
		self:RemoveConfig(context);
	end);
	self.window:Center();
	--print("SetAutoOperationWindow Init");
end

function SetAutoOperationWindow:Confirm()
	AutoOperationHelper.auto_search = self.check1.selected;
	AutoOperationHelper.auto_slaughter = self.check2.selected;
	AutoOperationHelper.lingzhi_remind = self.check3.selected;
	AutoOperationHelper.auto_get_product = self.check4.selected;
	local area_list = {};
	for i=0, self.list.numItems-1 do
		local list_data = {};
		local list_item = self.list:GetChildAt(i);
		local item_priority = list_item:GetChild("priority");
		local item_corpse = list_item:GetChild("corpse");
		local item_dying = list_item:GetChild("dying");
		local item_unconscious = list_item:GetChild("unconscious");		
		
		list_data.id = list_item.data;
		list_data.priority = item_priority.selectedIndex;
		list_data.corpse = item_corpse.selected;
		list_data.dying = item_dying.selected;
		list_data.unconscious = item_unconscious.selected;
		table.insert(area_list, list_data);
	end
	AutoOperationHelper.area_list = area_list;
	AutoOperationHelper:InitAndCheck();
end

function SetAutoOperationWindow:RemoveConfig(context)
	if CS.UnityEngine.Input.GetKey(CS.UnityEngine.KeyCode.LeftShift) then
		local item = context.data;
		self.area_temp[item.data] = nil;
		self.list:RemoveChildToPool(item);
	end
end

function SetAutoOperationWindow:Open()
	if self.window.isShowing then
		self:OnShowUpdate();
	else
		self:Show();
	end
end

function SetAutoOperationWindow:OnShowUpdate()
	self.area_temp = {};
	self.window:BringToFront();
	self.check1.selected = AutoOperationHelper.auto_search;
	self.check2.selected = AutoOperationHelper.auto_slaughter;
	self.check3.selected = AutoOperationHelper.lingzhi_remind;
	self.check4.selected = AutoOperationHelper.auto_get_product;
	self.list:RemoveChildrenToPool();
	if AutoOperationHelper.area_list ~= nil then
		for k, area_set in pairs(AutoOperationHelper.area_list) do
			if area_set ~= nil and area_set.id ~= nil then
				local area = CS.XiaWorld.AreaMgr.Instance:FindAreaByID(area_set.id);
				self:AddSelectedArea(area, area_set);
			end
		end
	end
end

function SetAutoOperationWindow:AddSelectedArea(area, set_data)
	if area == nil or self:CheckAreaExist(area) then
		return;
	end
	self.area_temp[area.ID] = area.Name;
	local item = self.list:AddItemFromPool();
	local item_title = item:GetChild("title");
	local item_label = item:GetChild("label");
	local item_priority = item:GetChild("priority");
	local item_corpse = item:GetChild("corpse");
	local item_dying = item:GetChild("dying");
	local item_unconscious = item:GetChild("unconscious");
	
	item.data = area.ID;
	item_title.title = area.Name;
	item_title.tooltips = string.format(XT("ID：%d\n名称：%s\n类型：%s\n大小：%d"), area.ID, area.Name, self.area_type[area.def.Name], area.m_lisGrids.Count);
	item_label.text = XT("优先级");
	item_priority.items = self.level_list;
	item_corpse.title = XT("尸体");
	item_dying.title = XT("弥留");
	item_unconscious.title = XT("昏迷");
	
	if set_data == nil then
		set_data = {};
		set_data.priority = 0;
		set_data.corpse = false;
		set_data.dying = false;
		set_data.unconscious = false;
	end
	item_priority.selectedIndex = set_data.priority;
	item_corpse.selected = set_data.corpse or false;
	item_dying.selected = set_data.dying or false;
	item_unconscious.selected = set_data.unconscious or false;
	self.list:ScrollToView(self.list.numItems-1);
end

function SetAutoOperationWindow:CheckAreaExist(area)
	for i=0, self.list.numItems-1 do
		local list_item = self.list:GetChildAt(i);
		if list_item.data == area.ID then
			return true;
		end
	end
	return false;
end

function SetAutoOperationWindow:OnUpdate(dt)
	if CS.UnityEngine.Input.GetKey(CS.UnityEngine.KeyCode.LeftShift) and CS.UnityEngine.Input.GetKey(CS.UnityEngine.KeyCode.Mouse0) then
		local grid_key = CS.UI_WorldLayer.Instance.MouseGridKey;
		if grid_key ~= nil and CS.XiaWorld.GridMgr.Inst:KeyVaild(grid_key) then
			local area = nil;
			for _, name in pairs({"Storage", "Plant", "DisciplePlant"}) do
				area = CS.XiaWorld.AreaMgr.Instance:CheckArea(grid_key, name);
				if area ~= nil then
					break;
				end
			end
			self:AddSelectedArea(area, nil);
		end		
	end
end

function SetAutoOperationWindow:OnHide()
	self.list:RemoveChildrenToPool();
end

SetAutoOperationWindow.area_type = {
	["Storage"] = XT("仓库"),
	["Plant"] = XT("农田"),
	["DisciplePlant"] = XT("药田")
};
SetAutoOperationWindow.state_list = {XT("弥留"), XT("尸体"), XT("昏迷"), XT("无"),};
SetAutoOperationWindow.level_list = {XT("低"), XT("中"), XT("高"),};

