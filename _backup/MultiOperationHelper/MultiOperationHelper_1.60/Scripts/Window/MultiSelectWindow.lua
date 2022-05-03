local Windows = GameMain:GetMod("Windows");--先注册一个新的MOD模块
local MultiSelectWindow = Windows:CreateWindow("MultiSelectWindow");
local MultiOperationHelper = GameMain:GetMod("MultiOperationHelper");

function MultiSelectWindow:OnInit()
	self.window.contentPane = UIPackage.CreateObject("MultiOperationHelper", "MultiSelectWindow");--载入UI包里的窗口
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
	--print("MultiSelectWindow OnInit");
end

function MultiSelectWindow:Open(title, bn1, bn2, tips, callback1, data, height, modal, callback2, stype, condition)
	if self.window.isShowing then
		self:Hide();
	end
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
	self.condition = condition;
	self.window.modal = self._modal;  --锁定窗体
	if self.window.isShowing then
		self:OnShowUpdate();
	else
		self:Show();
	end
end

function MultiSelectWindow:OnShowUpdate()
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

function MultiSelectWindow:OnUpdate(dt)
	if self._stype ~= nil and MultiOperationHelper.shift and CS.UnityEngine.Input.GetKey(CS.UnityEngine.KeyCode.Mouse0) then
		local gridkey = CS.UI_WorldLayer.Instance.MouseGridKey;
		if gridkey ~= nil and GridMgr:KeyVaild(gridkey) then
			if self._stype == g_emThingType.Npc then
				local things = Map.Things:GetNpcByKey(gridkey);
				if things ~= nil and things.Count > 0 then
					for _, thing in pairs(things) do
						self:MultiSelectThing(thing);
					end
				end
			else
				local thing = Map.Things:GetThingAtGrid(gridkey, self._stype);
				self:MultiSelectThing(thing);
			end
		end
	end
end

function MultiSelectWindow:MultiSelectThing(thing)
	if thing ~= nil and self.condition ~= nil and self.condition(thing) then
		for _, d in pairs(self._data) do
			if thing.ID == d.id then
				return;
			end
		end
		--local effect = world:PlayEffect(90002, thing.Key, 0);
		--table.insert(self.effects, effect);
		MagicBtnWindow:ThingSetIcon(thing);  --标记
		local thing_desc = "";
		if thing.ThingType == g_emThingType.Item then
			thing_desc = string.format("品阶：%d\n堆叠数量：%d\n可操作数量：%d", thing.Rate, thing.Count, thing.FreeCount);
		elseif thing.ThingType == g_emThingType.Npc then
			thing_desc = string.format("功法：%s\n境界：%s\n道行：%s", thing.PropertyMgr.Practice.Gong.DisplayName, 
						GameDefine.GongStageLevelTxt[thing.PropertyMgr.Practice.GongStateLevel], thing.PropertyMgr.Practice.DaoHang);
		elseif thing.ThingType == g_emThingType.Plant then
			thing_desc = string.format("生长效率：%.1f%%\n生长百分比：%.1f%%\n成熟百分比：%.1f%%", thing.GrowEfficiency*100, thing.GrowProgress, thing.HarvestProgress);
		end
		local thing_data = {
			name = thing:GetName(), 
			id = thing.ID, 
			data = "1", 
			desc = thing_desc,
		};
		table.insert(self._data, thing_data);
		self:AddListItem(thing_data);
		--print(thing:GetName());
	end
end

function MultiSelectWindow:AddListItem(data)
	local item = self.list:AddItemFromPool();
	item.title = data.name;
	item.data = data.id;
	item.tooltips = data.desc;
	item:GetChild("input").title = data.data;
end

function MultiSelectWindow:OnHide()
	local listdata = {};
	for i=0, self.list.numItems-1 do
		local listitem = self.list:GetChildAt(i);
		local input = tonumber(listitem:GetChild("input").title) or 0;
		table.insert(listdata, {id = listitem.data, data = input});
		if self._stype ~= nil then
			local thing = ThingMgr:FindThingByID(listitem.data);
			MagicBtnWindow:ThingRemoveIcon(thing);
		end
	end
	if self.called then
		if self.CallBack1 ~= nil then
			self.CallBack1(listdata);
		end
	elseif self.CallBack2 ~= nil then
		self.CallBack2(listdata);
	end
	self.list:RemoveChildrenToPool();
	self.CallBack1 = nil;
	self.CallBack2 = nil;
	--print("MultiSelectWindow OnHide");
end
