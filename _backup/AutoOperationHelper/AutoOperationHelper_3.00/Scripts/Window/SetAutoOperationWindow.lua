local Windows = GameMain:GetMod("Windows");--先注册一个新的MOD模块
local SetAutoOperationWindow = Windows:CreateWindow("SetAutoOperationWindow");
local AutoOperationHelper = GameMain:GetMod("AutoOperationHelper");

SetAutoOperationWindow.area_type = {
	["Storage"] = "仓库",
	["Plant"] = "农田",
	["DisciplePlant"] = "药田"
};

function SetAutoOperationWindow:OnInit()
	self.window.contentPane = CS.FairyGUI.UIPackage.CreateObject("AutoOperationHelper", "SetAutoOperationWindow");
	self.window.closeButton = self:GetChild("frame"):GetChild("n5");
	self.tips = self:GetChild("tips");
	self.check1 = self:GetChild("check1");
	self.check2 = self:GetChild("check2");
	self.check3 = self:GetChild("check3");
	self.check4 = self:GetChild("check4");
	self.check5 = self:GetChild("check5");
	self.list = self:GetChild("list");
	self.btn1 = self:GetChild("btn1");
	self.btn2 = self:GetChild("btn2");
	self.tips.title = "说明";
	self.tips.tooltips = "按住左Shift键，点击仓库/农田/药田中的任意位置将该区域添加到设置面板，设置该区域作为弥留/尸体/昏迷小人的存放区以及使用优先级，当敌人变成弥留/尸体/昏迷时就会被自动搬运到对应区域。\n按住左Shift键，鼠标右键点击设置面板上的区域名，可以将该区域删除。\n如果出现不会自动搬运，可以打开设置面板后直接点确定。";
	self.check1.tooltips = "自动搜身弥留或尸体小人，对昏倒的小人无效。";
	self.check2.tooltips = "自动屠宰死亡的动物和妖兽。";
	self.check3.tooltips = "当各历练地点的灵植和造化玉籽成熟时，会弹出消息提醒。";
	self.check4.tooltips = "每天0点自动领取各地区仓库的储存。";
	self.check5.tooltips = "体修选择淬体词条时自动翻开所有词条。";
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
	AutoOperationHelper.auto_roll_label = self.check5.selected;
	local area_list = {};
	for i=0, self.list.numItems-1 do
		local list_data = {};
		local list_item = self.list:GetChildAt(i);
		list_data.id = list_item.data;
		local state = list_item:GetChild("state").title;
		list_data.state = state;
		local level = list_item:GetChild("level").title;
		list_data.level = level;
		table.insert(area_list, list_data);
	end
	AutoOperationHelper.area_list = area_list;
	AutoOperationHelper:InitAndCheck();
end

function SetAutoOperationWindow:RemoveConfig(context)
	if CS.UnityEngine.Input.GetKey(CS.UnityEngine.KeyCode.LeftShift) then
		local item = context.data;
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
	self.window:BringToFront();
	self.check1.selected = AutoOperationHelper.auto_search;
	self.check2.selected = AutoOperationHelper.auto_slaughter;
	self.check3.selected = AutoOperationHelper.lingzhi_remind;
	self.check4.selected = AutoOperationHelper.auto_get_product;
	self.check5.selected = AutoOperationHelper.auto_roll_label;
	self.list:RemoveChildrenToPool();
	if AutoOperationHelper.area_list ~= nil then
		for _, area_set in pairs(AutoOperationHelper.area_list) do
			if area_set ~= nil and area_set.id ~= nil then
				local area = CS.XiaWorld.AreaMgr.Instance:FindAreaByID(area_set.id);
				self:AddSelectedArea(area, area_set);
			end
		end
	end
end

function SetAutoOperationWindow:AddSelectedArea(area, set_data)
	if area == nil then
		return;
	end
	local item = self.list:AddItemFromPool();
	local item_name = item:GetChild("name");
	local item_state = item:GetChild("state");
	local item_level = item:GetChild("level");
	item_state.items = self.state_list;
	item_level.items = self.level_list;
	item.data = area.ID;
	item_name.title = area.Name;
	item_name.tooltips = string.format("ID：%d\n名称：%s\n类型：%s\n大小：%d", area.ID, area.Name, self.area_type[area.def.Name], area.m_lisGrids.Count);
	if set_data == nil then
		set_data = {};
		set_data.state = "弥留";
		set_data.level = "低";
	end
	item_state.title = set_data.state;
	item_state.tooltips = "小人状态";
	item_level.title = set_data.level;
	item_level.tooltips = "优先级";
end

function SetAutoOperationWindow:OnUpdate(dt)
	if CS.UnityEngine.Input.GetKey(CS.UnityEngine.KeyCode.LeftShift) and CS.UnityEngine.Input.GetKey(CS.UnityEngine.KeyCode.Mouse0) then
		local grid_key = CS.UI_WorldLayer.Instance.MouseGridKey;
		if grid_key ~= nil and CS.XiaWorld.GridMgr.Inst:KeyVaild(grid_key) then
			local area;
			for _, name in pairs({"Storage", "Plant", "DisciplePlant"}) do
				area = CS.XiaWorld.AreaMgr.Instance:CheckArea(grid_key, name);
				if area ~= nil then
					break;
				end
			end
			if area == nil then
				return;
			end
			for i=0, self.list.numItems-1 do
				if area.ID == self.list:GetChildAt(i).data then
					return;
				end
			end
			self:AddSelectedArea(area, nil);
		end		
	end
end

function SetAutoOperationWindow:OnHide()
	self.list:RemoveChildrenToPool();
end

SetAutoOperationWindow.state_list = {"弥留", "尸体", "昏迷", "无",};
SetAutoOperationWindow.level_list = {"低", "中", "高",};

