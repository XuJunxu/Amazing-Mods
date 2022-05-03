local Windows = GameMain:GetMod("Windows");--先注册一个新的MOD模块
local StorageConfigWindow = Windows:CreateWindow("StorageConfigWindow");
local CustomRomoteStorage = GameMain:GetMod("CustomRomoteStorage");

function StorageConfigWindow:OnInit()
	self.window.contentPane = CS.FairyGUI.UIPackage.CreateObject("CustomRomoteStorage", "StorageConfigWindow");--载入UI包里的窗口
	self.window.closeButton = self:GetChild("frame"):GetChild("n5");
	self.title = self:GetChild("title");
	self.list = self:GetChild("list");
	self.btn1 = self:GetChild("btn1");
	self.btn2 = self:GetChild("btn2");
	self.tips = self:GetChild("tips");
	self.all_selected = self:GetChild("allselected");
	self.input = self:GetChild("input");
	self.search = self:GetChild("search");
	self.sum = self:GetChild("sum");
	self.title.text = "乾坤界物品设置";
	self.tips.title = "说明";
	self.tips.tooltips = "说明";
	self.btn1.onClick:Add(function(context)
		self.called = true;
		self:Hide();
	end);
	self.btn2.onClick:Add(function(context)
		self:Hide();
	end);
	self.all_selected.onClick:Add(function(context)
		local selected = self.all_selected.selected;
		for _, list_item in pairs(self.showing_items) do
			if list_item.canChange then
				list_item.added = selected;
			end
		end
		self:ShowItems(self.search_text);
		self:UpdateSum();
	end);
	self.search.onClick:Add(function(context)
		self.search_text = self.input.title;
		self:ShowItems(self.search_text);
		self:CheckAllSelected();
	end);
	self.list:SetVirtual();  --用虚拟列表，显示面板时才不卡
	self.list.itemRenderer = function(index, list_item) self:RenderListItem(index, list_item); end
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

function StorageConfigWindow:OnShowUpdate()
	self.window:BringToFront();
	self.input.title = "";
	self:ShowItems();
	self:CheckAllSelected();
	self:UpdateSum();
end

function StorageConfigWindow:ShowItems(text)
	self.showing_items = {};
	if text ~= nil and text ~= "" then
		for _, data in pairs(self.list_data) do
			local n, m = string.find(data.dspName, text)
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
	local item_name = list_item:GetChild("name");
	local item_type = list_item:GetChild("type");
	list_item.data = item_data.canChange;
	item_name.title = item_data.dspName;
	item_name.selected = item_data.added;
	item_name.data = item_data.name;
	item_type.items = CustomRomoteStorage.itemTypeList;
	item_type.title = item_data.itemType;
	item_type.data = item_data.name;
	list_item.tooltips = item_data.tooltips;
	item_name.grayed = not item_data.canChange;
	item_name.enabled = item_data.canChange;
	item_name.onClick:Add(OnCheckItem);
	item_type.onChanged:Add(OnChangeType);
end

function OnCheckItem(context)
	local item = context.sender;
	StorageConfigWindow:UpdateItemData(item.data, nil, item.selected);
	StorageConfigWindow:UpdateSum();
	StorageConfigWindow:CheckAllSelected(); 
end

function OnChangeType(context)
	local item = context.sender;
	StorageConfigWindow:UpdateItemData(item.data, item.title, nil);
end

function StorageConfigWindow:UpdateItemData(name, type_, added)
	for _, data in pairs(self.showing_items) do
		if data.name == name then
			if type_ ~= nil then
				data.itemType = type_;
			end
			if added ~= nil then
				data.added = added;
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
	--print("StorageConfigWindow OnHide");
end


