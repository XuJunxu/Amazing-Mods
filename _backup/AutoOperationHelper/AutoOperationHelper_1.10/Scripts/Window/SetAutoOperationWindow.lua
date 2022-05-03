local Windows = GameMain:GetMod("Windows");--先注册一个新的MOD模块
local SetAutoOperationWindow = Windows:CreateWindow("SetAutoOperationWindow");
local AutoOperationHelper = GameMain:GetMod("AutoOperationHelper");

SetAutoOperationWindow.area_type = {
	["Storage"] = "仓库",
	["Plant"] = "农田",
	["DisciplePlant"] = "药田"
};

function SetAutoOperationWindow:OnInit()
	self.window.contentPane = UIPackage.CreateObject("AutoOperationHelper", "SetAutoOperationWindow");
	self.window.closeButton = self:GetChild("frame"):GetChild("n5");
	self.title = self:GetChild("frame"):GetChild("title");
	self.tips = self:GetChild("tips");
	self.check1 = self:GetChild("check1");
	self.check2 = self:GetChild("check2");
	self.list = self:GetChild("list");
	self.btn1 = self:GetChild("btn1");
	self.btn2 = self:GetChild("btn2");
	self.title.text = "自动搬运设置";
	self.tips.title = "说明";
	self.tips.tooltips = "按住左Shift键，点击仓库/农田/药田中的任意位置将该区域添加到设置面板，设置该区域作为弥留或尸体存放区以及使用优先级，当敌人变成弥留或尸体时就会被自动搬运到对应区域；\n按住左Shift键，鼠标右键点击设置面板上的设置项，可以将该区域删除。（建议更改区域的名字，以方便设置）";
	self.btn1.onClick:Add(function(context)
		AutoOperationHelper.auto_search = self.check1.selected;
		AutoOperationHelper.auto_slaughter = self.check2.selected;
		local area_list = {};
		for i=0, self.list.numItems-1 do
			local listdata = {};
			local listitem = self.list:GetChildAt(i);
			listdata.id = listitem.data;
			local state = listitem:GetChild("state").text;
			listdata.state = state;
			local level = listitem:GetChild("level").text;
			listdata.level = level;
			table.insert(area_list, listdata);
		end
		AutoOperationHelper.area_list = area_list;
		self:Hide();
	end);
	self.btn2.onClick:Add(function(context)
		self:Hide();
	end);
	self.list.onRightClickItem:Add(function(context)
		if AutoOperationHelper.shift then
			local item = context.data;
			self.list:RemoveChildToPool(item);
		end
	end);
	self.window:Center();
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
	self.list:RemoveChildrenToPool();
	if AutoOperationHelper.area_list ~= nil then
		for _, area_set in pairs(AutoOperationHelper.area_list) do
			local area = AreaMgr:FindAreaByID(area_set.id);
			self:AddSelectedArea(area, area_set);
		end
	end
end

function SetAutoOperationWindow:AddSelectedArea(area, set_data)
	if area == nil then
		return;
	end
	local item = self.list:AddItemFromPool();
	item.data = area.ID;
	item:GetChild("title").title = area.Name;
	item.tooltips = string.format("ID：%d\n类型：%s\n大小：%d", area.ID, self.area_type[area.def.Name], area.m_lisGrids.Count);
	if set_data == nil then
		set_data = {};
		set_data.state = "无";
		set_data.level = "低";
	end
	item:GetChild("state").text = set_data.state;
	item:GetChild("level").text = set_data.level;
end

function SetAutoOperationWindow:OnUpdate(dt)
	if AutoOperationHelper.shift and CS.UnityEngine.Input.GetKey(CS.UnityEngine.KeyCode.Mouse0) then
		local gridkey = CS.UI_WorldLayer.Instance.MouseGridKey;
		if gridkey ~= nil and GridMgr:KeyVaild(gridkey) then
			local area;
			for _, name in pairs({"Storage", "Plant", "DisciplePlant"}) do
				area = AreaMgr:CheckArea(gridkey, name);
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

