local Windows = GameMain:GetMod("Windows");
local StorageConfigWindow = Windows:CreateWindow("CustomRomoteStorage_StorageConfigWindow");
local CustomRomoteStorage = GameMain:GetMod("CustomRomoteStorage");

local LanStr = {
	["自定义乾坤界"] = "Custom Mini Universe",
	["确定"] = "Comfirm",
	["取消"] = "Cancel",
	["说明"] = "Help",
	["全选"] = "Select All",
	["搜索"] = "Search",
	["常用"] = "Common",
	["在乾坤界窗口内按住左Shift键，鼠标右键点击物品，可以将该物品添加到（移除出）“常用”分类。"] = "Hold down the left Shift key. Use the right mouse button to click the item in the Mini Universe. The item will be add to (remove from) the \"Common\" classification.",
};
local GLS = Global_GetLanguageString(LanStr);

function StorageConfigWindow:OnInit()
	self.window.contentPane = CS.FairyGUI.UIPackage.CreateObject("CustomRomoteStorage", "StorageConfigWindow");--载入UI包里的窗口
	self.title = self:GetChild("title");
	self.list = self:GetChild("list");
	self.btn1 = self:GetChild("btn1");
	self.btn2 = self:GetChild("btn2");
	self.tips = self:GetChild("tips");
	self.all_selected = self:GetChild("allselected");
	self.input = self:GetChild("input");
	self.search = self:GetChild("search");
	self.sum = self:GetChild("sum");
	
	self.title.title = GLS("自定义乾坤界");
	self.btn1.title = GLS("确定");
	self.btn2.title = GLS("取消");
	self.tips.title = GLS("说明");
	self.all_selected.title = GLS("全选");
	self.search.title = GLS("搜索");
	self.tips.tooltips = GLS("在乾坤界窗口内按住左Shift键，鼠标右键点击物品，可以将该物品添加到（移除出）“常用”分类。");
	
	self.btn1.onClick:Add(self.ButtonClick1);
	self.btn2.onClick:Add(self.ButtonClick2);
	self.all_selected.onClick:Add(self.SelectAllClick);
	self.search.onClick:Add(self.SearchClick);
	self.list:SetVirtual();  --用虚拟列表，显示面板时才不卡
	self.list.itemRenderer = self.ItemRender;
	self.window.modal = true;
	self.window:Center();
	--print("StorageConfigWindow OnInit");
end

function StorageConfigWindow:Open(list_data)
	self.list_data = list_data;
	self.showing_items = {};
	self.search_text = nil;
	self.called = false;
	if self.window.isShowing then
		self:OnShowUpdate();
	else
		self:Show();
	end
end

function StorageConfigWindow:SelectAll()
	local selected = self.all_selected.selected;
	for _, list_item in pairs(self.showing_items) do
		if list_item.canChange then
			list_item.added = selected;
		end
	end
	self:ShowItems(self.search_text);
	self:UpdateSum();
end

function StorageConfigWindow:Search()
	self.search_text = self.input.title;
	self:ShowItems(self.search_text);
	self:CheckAllSelected();
end

function StorageConfigWindow:OnShowUpdate()
	self.window:BringToFront();
	self.input.title = "";
	self:ShowItems();
	self:CheckAllSelected();
	self:UpdateSum();
	if not self.pause then
		self.pause = true;
		CS.XiaWorld.MainManager.Instance:Pause(true);
	end
end

function StorageConfigWindow:ShowItems(text)
	self.showing_items = {};
	if text ~= nil and text ~= "" then
		for _, data in pairs(self.list_data) do
			local n, m = string.find(string.lower(data.dspName), string.lower(text))
			if n ~= nil then
				table.insert(self.showing_items, data);
			end
		end
	else
		for _, data in pairs(self.list_data) do
			table.insert(self.showing_items, data);
		end
	end
	self.list.numItems = #self.showing_items;
	self.list:ScrollToView(self.list.numItems-1);
end

function StorageConfigWindow:RenderListItem(index, list_item)
	local item_data = self.showing_items[index+1];
	local item_name = list_item:GetChild("title");
	local item_type = list_item:GetChild("type");
	local item_common = list_item:GetChild("common");
	list_item.data = item_data.canChange;
	item_name.title = item_data.dspName;
	item_name.selected = item_data.added;
	item_name.data = item_data.name;
	item_type.items = CustomRomoteStorage.itemTypeList;
	item_type.title = item_data.itemType;
	item_type.data = item_data.name;
	item_common.title = GLS("常用");
	item_common.selected = item_data.common;
	item_common.data = item_data.name;
	list_item.tooltips = item_data.tooltips;
	item_name.grayed = not item_data.canChange;
	item_name.enabled = item_data.canChange;
	item_name.onClick:Add(StorageConfigWindow_OnCheckItem);
	item_type.onChanged:Add(StorageConfigWindow_OnChangeType);
	item_common.onClick:Add(StorageConfigWindow_OnCheckCommon);
end

function StorageConfigWindow_OnCheckItem(context)
	local item = context.sender;
	StorageConfigWindow:UpdateItemData(item.data, nil, item.selected, nil);
	StorageConfigWindow:UpdateSum();
	StorageConfigWindow:CheckAllSelected(); 
end

function StorageConfigWindow_OnChangeType(context)
	local item = context.sender;
	StorageConfigWindow:UpdateItemData(item.data, item.title, nil, nil);
end

function StorageConfigWindow_OnCheckCommon(context)
	local item = context.sender;
	StorageConfigWindow:UpdateItemData(item.data, nil, nil, item.selected);
end

function StorageConfigWindow:UpdateItemData(name, type_, added, common)
	for _, data in pairs(self.showing_items) do
		if data.name == name then
			if type_ ~= nil then
				data.itemType = type_;
			end
			if added ~= nil then
				data.added = added;
			end
			if common ~= nil then
				data.common = common;
			end
			break;
		end
	end
end

function StorageConfigWindow:CheckAllSelected()
	local selected = true;
	for _, list_item in pairs(self.showing_items) do
		if list_item.canChange then
			selected = selected and list_item.added;
		end
	end
	self.all_selected.selected = selected;
end

function StorageConfigWindow:UpdateSum()
	local sum = 0;
	local add = 0;
	for _, data in pairs(self.list_data) do
		sum = sum + 1;
		if data.added then
			add = add + 1;
		end
	end
	self.sum.text = string.format("%d/%d", add, sum);
end

function StorageConfigWindow:OnHide()
	if self.called then 
		CustomRomoteStorage:UpdateAllItem(self.list_data);
	end
	self.list_data = nil;
	self.showing_items = nil;
	self.search_text = nil;
	if self.pause then
		self.pause = false;
		if CS.XiaWorld.MainManager.Instance ~= nil then
			CS.XiaWorld.MainManager.Instance:Play(0, true);
		end
	end
	--print("StorageConfigWindow OnHide");
end

function StorageConfigWindow:RemoveCallback()
	self.btn1.onClick:Clear();
	self.btn2.onClick:Clear();
	self.all_selected.onClick:Clear();
	self.search.onClick:Clear();
	self.list.itemRenderer = nil;
end

function StorageConfigWindow.ButtonClick1(context)
	StorageConfigWindow.called = true;
	StorageConfigWindow:Hide();
end

function StorageConfigWindow.ButtonClick2(context)
	StorageConfigWindow:Hide();
end

function StorageConfigWindow.SelectAllClick(context)
	StorageConfigWindow:SelectAll();
end

function StorageConfigWindow.SearchClick(context)
	StorageConfigWindow:Search();
end

function StorageConfigWindow.ItemRender(index, list_item)
	StorageConfigWindow:RenderListItem(index, list_item);
end