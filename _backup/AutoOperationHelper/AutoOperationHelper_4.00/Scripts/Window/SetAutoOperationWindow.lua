local Windows = GameMain:GetMod("Windows");
local SetAutoOperationWindow = Windows:CreateWindow("AutoOperationHelper_SetAutoOperationWindow");
local AutoOperationHelper = GameMain:GetMod("AutoOperationHelper");
local SetYunYangWindow = {};

local LanStr = {
	["自动搬运设置"] = "Auto Transporting",
	["说明"] = "Help",
	["自动搜身"] = "Auto Searching",
	["自动屠宰"] = "Auto Butchering",
	["灵植成熟提醒"] = "Spiritual Plant Reminder",
	["自动领取势力点储存"] = "Auto Claiming",
	["淬体自动翻卡"] = "Auto Flipping",
	["自动蕴养"] = "Auto Nurturing",
	["确定"] = "Confirm",
	["取消"] = "Cancel",
	["按住左Shift键，鼠标左键点击仓库/农田/药田中的任意位置将该区域添加到设置面板，设置该区域作为弥留/尸体/昏迷小人的存放区以及使用优先级，当非玩家的小人变成弥留/尸体/昏迷时就会被自动搬运到对应区域。\n\n按住左Shift键，鼠标右键点击设置面板上的区域名，可以将该区域删除。\n\n如果出现不会自动搬运，可以打开设置面板后直接点确定。"] = "Hold down the left Shift key. Use the left mouse button to click anywhere in the Storage, Field or Herb Garden to add this area to the settings panel. Then set up this area as a storage area for corpses, dying characters or unconscious characters and set the priority of this area. Characters will automatically transport the non-player's roles that are dead, dying or unconscious to the corresponding area.\n\nHold down the left Shift key. Use the right mouse button to click the area name on the settings panel to delete the area.\n\nIf it appears that characters will not transport enemies automatically, you can open the settings panel and just click comfirm button.",
	["自动搜身弥留或尸体小人，对昏倒的小人无效。"] = "Characters will automatically search corpses or dying characters.",
	["自动屠宰死亡的动物和妖兽。"] = "Characters will automatically butcher dead animals and monsters.",
	["当各历练地点的灵植和造化玉籽成熟时，会弹出消息提醒。"] = "A message window will pop up when the Spiritual Plant or the Fortune Seed at each location is ripe.",
	["每天0点自动领取各势力点仓库的物资。"] = "Automatically claim all items in the storage at 0:00 every day.",
	["体修选择淬体词条时自动翻开所有词条。"] = "Flip all entries automatically when selecting an entry for Physical cultivation.",
	["自动使用非玩家的小人尸体蕴养灵植。\n\n可设置蕴养规则，优先级从左到右降低。"] = "Characters will automatically use the non-player's corpses to nurture spiritual plants.\n\nCan select rules for nurturing. The priority is reduced from left to right.",
	["ID：%d\n名称：%s\n类型：%s\n大小：%d"] = "ID: %d\nName: %s\nType: %s\nSize: %d",
	["优先级"] = "Priority",
	["尸体"] = "Corpse",
	["弥留"] = "Dying",
	["昏迷"] = "Unconscious",
	["仓库"] = "Storage",
	["农田"] = "Field",
	["药田"] = "Herb Garden",
	["高"] = "H",
	["中"] = "M",
	["低"] = "L",
	["相生"] = "Connective",
	["相克"] = "Counteractive",
	["相同"] = "Equivalent",
	["无关"] = "Irrelevant",
	["外门"] = "Outer",
	["全选/全不选"] = "Check all or uncheck all",
};
local GLS = Global_GetLanguageString(LanStr);

function SetAutoOperationWindow:OnInit()
	self.window.contentPane = CS.FairyGUI.UIPackage.CreateObject("AutoOperationHelper", "SetAutoOperationWindow");
	self.title = self:GetChild("title");
	self.tips = self:GetChild("tips");
	self.check1 = self:GetChild("check1");
	self.check2 = self:GetChild("check2");
	self.check3 = self:GetChild("check3");
	self.check4 = self:GetChild("check4");
	self.check5 = self:GetChild("check5");
	self.check6 = self:GetChild("check6");
	self.list = self:GetChild("list");
	self.btn1 = self:GetChild("btn1");
	self.btn2 = self:GetChild("btn2");
	
	self.title.title = GLS("自动搬运设置");
	self.tips.title = GLS("说明");
	self.check1.title = GLS("自动搜身");
	self.check2.title = GLS("自动屠宰");
	self.check3.title = GLS("灵植成熟提醒");
	self.check4.title = GLS("自动领取势力点储存");
	self.check5.title = GLS("淬体自动翻卡");
	self.check6.title = GLS("自动蕴养");
	self.btn1.title = GLS("确定");
	self.btn2.title = GLS("取消");
	self.tips.tooltips = GLS("按住左Shift键，鼠标左键点击仓库/农田/药田中的任意位置将该区域添加到设置面板，设置该区域作为弥留/尸体/昏迷小人的存放区以及使用优先级，当非玩家的小人变成弥留/尸体/昏迷时就会被自动搬运到对应区域。\n\n按住左Shift键，鼠标右键点击设置面板上的区域名，可以将该区域删除。\n\n如果出现不会自动搬运，可以打开设置面板后直接点确定。");
	self.check1.tooltips = GLS("自动搜身弥留或尸体小人，对昏倒的小人无效。");
	self.check2.tooltips = GLS("自动屠宰死亡的动物和妖兽。");
	self.check3.tooltips = GLS("当各历练地点的灵植和造化玉籽成熟时，会弹出消息提醒。");
	self.check4.tooltips = GLS("每天0点自动领取各势力点仓库的物资。");
	self.check5.tooltips = GLS("体修选择淬体词条时自动翻开所有词条。");
	self.check6.tooltips = GLS("自动使用非玩家的小人尸体蕴养灵植。\n\n可设置蕴养规则，优先级从左到右降低。");
	
	self.btn1.onClick:Add(self.ButtonClick1);
	self.btn2.onClick:Add(self.ButtonClick2);
	self.list.onRightClickItem:Add(self.ListRightClickItem);
	self.check6.onClick:Add(self.CheckClick);
	
	self.yunyang = self.window.contentPane:GetController("yunyang");
	self.yunyang.selectedIndex = 0;
	SetYunYangWindow:OnInit();
	self.window:Center();
	self.inited = true;
	--print("SetAutoOperationWindow Init");
end

function SetAutoOperationWindow:Confirm()
	AutoOperationHelper.auto_search = self.check1.selected;
	AutoOperationHelper.auto_slaughter = self.check2.selected;
	AutoOperationHelper.lingzhi_remind = self.check3.selected;
	AutoOperationHelper.auto_get_product = self.check4.selected;
	AutoOperationHelper.auto_roll_label = self.check5.selected;
	AutoOperationHelper.auto_yunyang = self.check6.selected;
	SetYunYangWindow:comfirm();
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
	self.check5.selected = AutoOperationHelper.auto_roll_label;
	self.check6.selected = AutoOperationHelper.auto_yunyang;
	self.list:RemoveChildrenToPool();
	if AutoOperationHelper.area_list ~= nil then
		for k, area_set in pairs(AutoOperationHelper.area_list) do
			if area_set ~= nil and area_set.id ~= nil then
				local area = CS.XiaWorld.AreaMgr.Instance:FindAreaByID(area_set.id);
				self:AddSelectedArea(area, area_set);
			end
		end
	end
	self.yunyang.selectedIndex = 1;
	SetYunYangWindow:OnShowUpdate();
	if not self.check6.selected then
		self.yunyang.selectedIndex = 0;
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
	item_title.tooltips = string.format(GLS("ID：%d\n名称：%s\n类型：%s\n大小：%d"), area.ID, area.Name, self.area_type[area.def.Name], area.m_lisGrids.Count);
	item_label.text = GLS("优先级");
	item_priority.items = self.level_list;
	item_corpse.title = GLS("尸体");
	item_dying.title = GLS("弥留");
	item_unconscious.title = GLS("昏迷");
	
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

function SetAutoOperationWindow:RemoveCallback()
	if self.inited then
		self.btn1.onClick:Clear();
		self.btn2.onClick:Clear();
		self.list.onRightClickItem:Clear();
		self.check6.onClick:Clear();
	end
end

function SetAutoOperationWindow.ButtonClick1(context)
	SetAutoOperationWindow:Confirm();
	SetAutoOperationWindow:Hide();
end

function SetAutoOperationWindow.ButtonClick2(context)
	SetAutoOperationWindow:Hide();
end

function SetAutoOperationWindow.ListRightClickItem(context)
	SetAutoOperationWindow:RemoveConfig(context);
end

function SetAutoOperationWindow.CheckClick(context)
	if context.sender.selected then
		SetAutoOperationWindow.yunyang.selectedIndex = 1;
	else
		SetAutoOperationWindow.yunyang.selectedIndex = 0;
	end
end

SetAutoOperationWindow.area_type = {
	["Storage"] = GLS("仓库"),
	["Plant"] = GLS("农田"),
	["DisciplePlant"] = GLS("药田")
};

SetAutoOperationWindow.state_list = {GLS("弥留"), GLS("尸体"), GLS("昏迷"), GLS("无"),};
SetAutoOperationWindow.level_list = {GLS("低"), GLS("中"), GLS("高"),};

function SetYunYangWindow:OnInit()
	self.contentPane = SetAutoOperationWindow:GetChild("SetYunYangWindow");
	self.list = self.contentPane:GetChild("list");
	self.inited = true;
	--print("SetYunYangWindow Init");
end

function SetYunYangWindow:OnShowUpdate()
	if not self.inited then
		self:OnInit();
	end
	self.list:RemoveChildrenToPool();
	for _, plant in pairs(AutoOperationHelper.LingZhiList) do
		local item = self.list:AddItemFromPool();
		local item_title = item:GetChild("title");
		local check_born = item:GetChild("born");
		local check_contrary = item:GetChild("contrary");
		local check_same = item:GetChild("same");
		local check_none = item:GetChild("none");
		local check_outer = item:GetChild("outer");
		local plant_def = CS.XiaWorld.ThingMgr.Instance:GetDef(CS.XiaWorld.g_emThingType.Plant, plant);
		item.data = plant;
		item_title.title = plant_def.ThingName;
		item_title.tooltips = GLS("全选/全不选");
		local settings = AutoOperationHelper.yunyang_settings[plant];
		check_born.selected = settings["born"];
		check_contrary.selected = settings["contrary"];
		check_same.selected = settings["same"];
		check_none.selected = settings["none"];
		check_outer.selected = settings["outer"];
		if CS.TFMgr.Instance.Language == "OfficialEnglish" then
			self.contentPane.width = 400;
			check_born:GetChild("title").fontsize = 9;
			check_contrary:GetChild("title").fontsize = 9;
			check_same:GetChild("title").fontsize = 9;
			check_none:GetChild("title").fontsize = 9;
			check_outer:GetChild("title").fontsize = 9;
		end
		check_born.title = GLS("相生");
		check_contrary.title = GLS("相克");
		check_same.title = GLS("相同");
		check_none.title = GLS("无关");
		check_outer.title = GLS("外门");
		item_title.onClick:Add(self.YunYangSelectAll);
	end
end

function SetYunYangWindow.YunYangSelectAll(context)
	local item = context.sender.parent;
	local check_born = item:GetChild("born");
	local check_contrary = item:GetChild("contrary");
	local check_same = item:GetChild("same");
	local check_none = item:GetChild("none");
	local check_outer = item:GetChild("outer");
	if check_born.selected and check_contrary.selected and check_same.selected and check_none.selected and check_outer.selected then
		check_born.selected = false;
		check_contrary.selected = false;
		check_same.selected = false;
		check_none.selected = false;
		check_outer.selected = false;	
	else
		check_born.selected = true;
		check_contrary.selected = true;
		check_same.selected = true;
		check_none.selected = true;
		check_outer.selected = true;		
	end
end

function SetYunYangWindow:comfirm()
	local settings = {};
	for i=0, self.list.numItems-1 do
		local item = self.list:GetChildAt(i);
		local check_born = item:GetChild("born");
		local check_contrary = item:GetChild("contrary");
		local check_same = item:GetChild("same");
		local check_none = item:GetChild("none");
		local check_outer = item:GetChild("outer");
		local plant_settings = {}
		plant_settings["born"] = check_born.selected;
		plant_settings["contrary"] = check_contrary.selected;
		plant_settings["same"] = check_same.selected;
		plant_settings["none"] = check_none.selected;
		plant_settings["outer"] = check_outer.selected;
		settings[item.data] = plant_settings;
	end
	AutoOperationHelper.yunyang_settings = settings;
end
