local Windows = GameMain:GetMod("Windows");--先注册一个新的MOD模块
local SearchThingWindow = Windows:CreateWindow("SearchThingWindow");

function SearchThingWindow:OnInit()
	self.window.contentPane = CS.FairyGUI.UIPackage.CreateObject("MyMods", "SearchThingWindow");--载入UI包里的窗口
	self.window.closeButton = self:GetChild("frame"):GetChild("n5");
	self.list = self:GetChild("list");
	self.sum = self:GetChild("sum");
	self.tips = self:GetChild("tips");
	self.input = self:GetChild("input");
	self.search = self:GetChild("search");
	self.tips.title = "说明";
	self.tips.tooltips = "说明";
	self.search.onClick:Add(function(context)
		self.search_text = self.input.title;
		self:ShowItems(self.search_text);
	end);
	self.list:SetVirtual();  --用虚拟列表，显示面板时才不卡
	self.list.itemRenderer = function(index, list_item) self:RenderListItem(index, list_item); end
	self.window:LeftTop();
	--print("SearchThingWindow OnInit");
end

function SearchThingWindow:Open()
	local ThingsData = CS.XiaWorld.World.Instance.map.Things;
	local g_emThingType = CS.XiaWorld.g_emThingType;
	xlua.private_accessible(CS.XiaWorld.ThingsData);
	local res, item_things = ThingsData.m_TypeThings:TryGetValue(g_emThingType.Item);
	if not res or item_things == nil then
		return;
	end
	self.list_data = item_things;
	self.showing_items = {};
	self.search_text = nil;
	self.called = false;
	if self.window.isShowing then
		self:OnShowUpdate();
	else
		self:Show();
	end
end

function SearchThingWindow:OnShowUpdate()
	self.window:BringToFront();
	self.input.title = "";
	self:ShowItems();
end

function SearchThingWindow:ShowItems(text)
	self.showing_items = {};
	if text ~= nil and text ~= "" then
		for _, data in pairs(self.list_data) do
			local n, m = string.find(data:GetName(), text)
			if n ~= nil then
				table.insert(self.showing_items, data);
			end
		end
	else
		for _, data in pairs(self.list_data) do
			table.insert(self.showing_items, data);
		end
	end
	self.sum.text = string.format("%d", #self.showing_items);
	self.list.numItems = #self.showing_items;
	--self.list:ScrollToView(self.list.numItems-1);
end

function SearchThingWindow:RenderListItem(index, list_item)
	local item_data = self.showing_items[index+1];
	local look_at = list_item:GetChild("look");
	list_item.data = item_data.ID;
	list_item.title = string.format("%s(%s个)", item_data:GetName(), item_data.Count);
	list_item.tooltips = string.format("品阶：%s", item_data.Rate);
	look_at.data = item_data.ID;
	look_at.onClick:Add(LookAtItem);
	--item_type.onChanged:Add(OnChangeType);
end

function LookAtItem(context)
	local item = context.sender;
	local thing = CS.XiaWorld.ThingMgr.Instance:FindThingByID(item.data);
	if thing ~= nil and CS.XiaWorld.World.Instance.GameMode ~= CS.XiaWorld.g_emGameMode.RPG then
		CS.MapCamera.Instance:LookKey(thing.Key);
		CS.XiaWorld.UILogicMode_Select.Instance:SelectThing(thing);
	end
end

function SearchThingWindow:OnHide()
	self.list_data = nil;
	self.showing_items = nil;
	self.search_text = nil;
	--print("SearchThingWindow OnHide");
end


