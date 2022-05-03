local Windows = GameMain:GetMod("Windows");
local tbWindow = Windows:CreateWindow("AmazingWorldOfFengXuan_EquipmentStorageWindow");
local AmazingWorldOfFengXuan = GameMain:GetMod("AmazingWorldOfFengXuan");

function tbWindow:OnInit()
	self.window.contentPane = CS.XiaWorld.UI.InGame.UI_RemoteStorage.CreateInstance();
	self.window.closeButton = self:GetChild("frame"):GetChild("n5");
	self.head = self:GetChild("Head");
	self.list = self:GetChild("n5");
	self.search = self:GetChild("n10");
	self.search_text = self:GetChild("n8");
	self.storage_sum = CS.XiaWorld.UI.InGame.UI_RichText.CreateInstance();
	self.only_special = CS.XiaWorld.UI.InGame.UI_Checkbox.CreateInstance();
	self.all_take = CS.XiaWorld.UI.InGame.UI_WndBnt3.CreateInstance();
	self.storage_sum:SetXY(20, 20);
	self.storage_sum:SetSize(80, self.storage_sum.height);
	self.window:AddChild(self.storage_sum);
	self.only_special:SetXY(20, 486);
	self.only_special.title = "只显示特殊物品";
	self.window:AddChild(self.only_special);
	self.all_take:SetXY(150, 484);
	self.all_take.title = "当前页全部取出";
	self.window:AddChild(self.all_take);
	
	self.head.onClickItem:Add(self.ClickTypeBtn);
	self.list:SetVirtual();
	self.list.itemRenderer = self.ItemRender;
	self.list.onClickItem:Add(self.ClickItemThing);
	self.list.onRightClickItem:Add(self.RightClickItemThing);
	self.search.onClick:Add(self.ClickSearch);
	self.only_special.onClick:Add(self.CheckSpecial);
	self.all_take.onClick:Add(self.ClickAllTake);
	
	self.window.modal = true;
	self.window:Center();
	
	self.all_items = {};
	self.type_items = {};
	self.search_key = nil;
	self.show_type = nil;
	self.showing_items = {};
	self.inited = true;
end

function tbWindow:OnShowUpdate()
	self.window:BringToFront();
	self.only_special.selected = false;
	self.search_text.text = "";
	self:RefreshData();
	self:ShowStorageType(nil);
	if not self.pause then
		self.pause = true;
		CS.XiaWorld.MainManager.Instance:Pause(true);
	end
end

function tbWindow:OnHide()
	self.building = nil;
	self.storage_list = nil;
	self.storage_items = nil;
	self.show_type = nil;
	if self.pause then
		self.pause = false;
		if CS.XiaWorld.MainManager.Instance ~= nil then
			CS.XiaWorld.MainManager.Instance:Play(0, true);
		end
	end
end

function tbWindow:Open(building, items)
	self.building = building;
	self.storage_list = items;
	self.storage_items = {};
	for _, item in pairs(self.storage_list) do
		self.storage_items[item.ID] = item;
	end
	if self.window.isShowing then
		self:OnShowUpdate();
	else
		self:Show();
	end
end

function tbWindow:RefreshData()
	self.all_items = {};
	self.type_items = {};
	for _, t in pairs(AmazingWorldOfFengXuan.storageTypes) do
		self.type_items[t] = {};
	end
	for _, item in pairs(self.storage_list) do
		if self.storage_items[item.ID] ~= nil and ((not self.only_special.selected) or (not (item.YouPower <= 0 and item.LingPower <= 0 and item.FSItemState <= 0 and item.HelianValue == nil))) then
			local type_ = AmazingWorldOfFengXuan.typeLable[item.def.Item.Lable] or ("其他");
			table.insert(self.all_items, item);
			table.insert(self.type_items[type_], item);
		end
	end
end

function tbWindow:ShowStorageType(type_)
	local selected = 0;
	self.head:RemoveChildrenToPool();
	local type_btn = self.head:AddItemFromPool();
	type_btn.title = ("全部");
	type_btn.data = nil;
	local num = 1;
	for _, t in pairs(AmazingWorldOfFengXuan.storageTypes) do
		if type_ == t then
			selected = num;
		end
		type_btn = self.head:AddItemFromPool();
		type_btn.title = t;
		type_btn.data = t;	
		num = num + 1;
	end
	self.head.selectedIndex = selected;
	self:ShowType(type_);
end

function tbWindow:ShowType(type_)
	self.show_type = type_;
	local items = nil;
	if type_ == nil then
		items = self.all_items;
	else
		items = self.type_items[type_];
	end
	if self.search_key == nil or self.search_key == "" then
		self.showing_items = items;
	else
		self.showing_items = {};
		for _, it in pairs(items) do
			local n, m = string.find(it:GetName(), self.search_key)
			if n ~= nil then
				table.insert(self.showing_items, it);
			end
		end
	end
	self.list.numItems = #self.showing_items;
	self.storage_sum.title = string.format("%d/%d", #self.showing_items, #self.all_items);
	--print(#self.showing_items);
end

function tbWindow.ClickTypeBtn(context)
	tbWindow:ShowType(context.data.data);
end

function tbWindow:RenderListItem(index, list_item)
	local item_thing = self.showing_items[index+1];
	local def = item_thing.def;
	--list_item.icon = string.format("thing://2,%s", def.Name);
	list_item.icon = string.format("thingid://%d", item_thing.ID);
	list_item.data = item_thing;
	list_item.title = item_thing:GetName();
	list_item.onRollOver:Clear();
	list_item.onRollOut:Clear();	
	list_item.onRollOver:Add(self.RollOver);
	list_item.onRollOut:Add(self.RollOut);
	local count = list_item:GetChild("count");
	count.visible = false;
end

function tbWindow.ItemRender(index, list_item)
	tbWindow:RenderListItem(index, list_item);
end

function tbWindow:DropItem(item)
	if item ~= nil and AmazingWorldOfFengXuan:DropItem(item, self.building.Key) then
		self.storage_items[item.ID] = nil;
		self:RefreshData();
		self:ShowStorageType(self.show_type);
	end
end

function tbWindow.ClickItemThing(context)
	local item = context.data.data;
	tbWindow:DropItem(item)
	CS.Wnd_TipPopPanel.Instance:Hide();
end

function tbWindow:EquipItem(item)
	CS.Wnd_SelectNpc.Instance:Select(
		WorldLua:GetSelectNpcCallback(function(npcs)
			self:Select2Equipt(npcs, item);
		end), 
	CS.XiaWorld.g_emNpcRank.Normal, 1, 1, nil, nil, ("指定装备的角色"));	
end

function tbWindow:Select2Equipt(npcs, item)
	if npcs ~= nil and npcs.Count > 0 then
		local npc = CS.XiaWorld.ThingMgr.Instance:FindThingByID(npcs[0]);
		if npc ~= nil then
			self:DropItem(item);
			npc:AddCommand("EquipItem", item);
		end
	end
end

function tbWindow.RightClickItemThing(context)
	local item = context.data.data;
	tbWindow:EquipItem(item)
	CS.Wnd_TipPopPanel.Instance:Hide();
end

function tbWindow:Search()
	self.search_key = self.search_text.text;
	self:ShowStorageType(nil);
	self.search_key = nil;
end

function tbWindow.ClickSearch(context)
	tbWindow:Search();
end

function tbWindow:ShowSpecial()
	self:RefreshData();
	self:ShowStorageType(self.show_type);
end

function tbWindow.CheckSpecial(context)
	tbWindow:ShowSpecial();
end

function tbWindow:AllTakeOut()
	for _, item in pairs(self.showing_items) do
		if AmazingWorldOfFengXuan:DropItem(item, self.building.Key) then
			self.storage_items[item.ID] = nil;
		end
	end
	self:RefreshData();
	self:ShowStorageType(self.show_type);
end

function tbWindow.ClickAllTake(context)
	tbWindow:AllTakeOut();
end

function tbWindow.RollOver(context)
	if not CS.Wnd_TipPopPanel.Instance.visible then
		return;
	end
	--print(context.sender.data);
	CS.Wnd_TipPopPanel.Instance:ShowOrUpdate(context.sender.data, nil, true, false);
end

function tbWindow.RollOut(context)
	if not CS.Wnd_TipPopPanel.Instance.visible then
		return;
	end
	CS.Wnd_TipPopPanel.Instance:Hide();
end

function tbWindow:RemoveCallback()
	if self.inited then
		self.head.onClickItem:Clear();
		self.search.onClick:Clear();
		self.list.itemRenderer = nil;
		self.list.onClickItem:Clear();
		self.list.onRightClickItem:Clear();
		self.only_special.onClick:Clear();
		self.all_take.onClick:Clear();
	end
end

