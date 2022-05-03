local Windows = GameMain:GetMod("Windows");--先注册一个新的MOD模块
local SetMagicCastWindow = Windows:CreateWindow("SetMagicCastWindow");
local MultiOperationHelper = GameMain:GetMod("MultiOperationHelper");

function SetMagicCastWindow:OnInit()
	self.window.contentPane = UIPackage.CreateObject("MultiOperationHelper", "SetMagicCastWindow");--载入UI包里的窗口
	self.window.closeButton = self:GetChild("frame"):GetChild("n5");
	self.title = self:GetChild("title");
	self.list = self:GetChild("list");
	self.btn1 = self:GetChild("btn1");
	self.btn2 = self:GetChild("btn2");
	self.btn_name1 = self:GetChild("bname1");
	self.btn_name2 = self:GetChild("bname2");
	self.tips = self:GetChild("tips");
	self.btn1.onClick:Add(function(context)
		self.called = true;
		self:Hide();
	end);
	self.btn2.onClick:Add(function(context)
		self:Hide();
	end);
	self.window:Center();
	--print("SetMagicCastWindow OnInit");
end

function SetMagicCastWindow:Open(title, bn1, bn2, tips, callback1, data, height, modal, callback2, stype, magic)
	self.called = false;
	self.last_thing = nil;
	self._title = title or "设置";
	self._bn1 = bn1 or "确定";
	self._bn2 = bn2 or "取消";
	self._tips = tips or {};
	self._data = data or {};
	self.CallBack1 = callback1;
	self.CallBack2 = callback2;
	self._height = height or 220;
	self._modal = modal or false;
	self._stype = stype;
	self._magic = magic;
	self.window.modal = self._modal;  --锁定窗体
	if self.window.isShowing then
		self:OnShowUpdate();
	else
		self:Show();
	end
end

function SetMagicCastWindow:OnShowUpdate()
	self.window:BringToFront();
	self.list.selectionMode = CS.FairyGUI.ListSelectionMode.None;
	self.list:RemoveChildrenToPool();
	self.title.text = self._title;
	self.btn_name1.text = self._bn1;
	self.btn_name2.text = self._bn2;
	if self._tips ~= nil then
		self.tips.title = self._tips.title;
		self.tips.tooltips = self._tips.content;
	end
	if self._data ~= nil then
		for _, data in pairs(self._data) do
			self:AddListItem(data);
		end
	end
	if self._height ~= nil then
		self.window.height = self._height;
	end
end

function SetMagicCastWindow:OnUpdate(dt)
	local thing = world:GetSelectThing();
	if thing == self.last_thing  or self._stype == nil or self._magic == nil then
		return;
	end
	self.last_thing = thing;
	if self._stype == "Item" then
		self:MultiSelectItem(thing);
	elseif self._stype == "Npc" then
		self:MultiSelectNpc(thing);
	end
end

function SetMagicCastWindow:MultiSelectItem(item)
	if item ~= nil and item.ThingType == g_emThingType.Item and MultiOperationHelper.shift and MagicBtnWindow:CheckThing(self._magic, item) then
		for _, d in pairs(self._data) do
			if item.ID == d.id then
				return;
			end
		end
		--local effect = world:PlayEffect(90002, item.Key, 0);
		--table.insert(self.effects, effect);
		if item.View ~= nil then
			item.View:SetIcon("res/Sprs/ui/icon_lingxi01");  --标记物品
		end
		local item_data = {
			name = item:GetName(), 
			id = item.ID, 
			data = "1", 
			desc = string.format("品阶：%d\n堆叠数量：%d\n可操作数量：%d", item.Rate, item.Count, item.FreeCount)
		};
		table.insert(self._data, item_data);
		self:AddListItem(item_data);
		--print(item:GetName());
	end
end

function SetMagicCastWindow:MultiSelectNpc(npc)
	if npc ~= nil and npc.ThingType == g_emThingType.Npc and MultiOperationHelper.shift and MagicBtnWindow:CheckThing(self._magic, npc) then
		for _, d in pairs(self._data) do
			if npc.ID == d.id then
				return;
			end
		end
		if npc.view ~= nil then
			npc.view:SetIcon("res/Sprs/ui/icon_lingxi01");  --标记物品
		end
		local npc_data = {
			name = npc:GetName(), 
			id = npc.ID, 
			data = "1",
			desc = string.format("功法：%s\n境界：%s\n道行：%s", npc.PropertyMgr.Practice.Gong.DisplayName, 
			GameDefine.GongStageLevelTxt[npc.PropertyMgr.Practice.GongStateLevel], npc.PropertyMgr.Practice.DaoHang)
		};
		table.insert(self._data, npc_data);
		SetMagicCastWindow:AddListItem(npc_data);
		--print(npc:GetName());
	end
end

function SetMagicCastWindow:AddListItem(data)
	local item = self.list:AddItemFromPool();
	item.title = data.name;
	item.data = data.id;
	item.tooltips = data.desc;
	item:GetChild("input").title = data.data;
end

function SetMagicCastWindow:OnHide()
	local listdata = {};
	for i=0, self.list.numItems-1 do
		local listitem = self.list:GetChildAt(i);
		local input = tonumber(listitem:GetChild("input").title) or 0;
		listdata[listitem.data] = input;
	end
	if self.called then
		if self.CallBack1 ~= nil then
			self.CallBack1(listdata);
		end
	elseif self.CallBack2~= nil then
		self.CallBack2(listdata);
	end
	self.list:RemoveChildrenToPool();
	self.CallBack1 = nil;
	self.CallBack2 = nil;
	--print("SetMagicCastWindow OnHide");
end
