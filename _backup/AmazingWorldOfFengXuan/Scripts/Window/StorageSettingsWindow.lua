local Windows = GameMain:GetMod("Windows");
local tbWindow = Windows:CreateWindow("AmazingWorldOfFengXuan_StorageSettingsWindow");
local AmazingWorldOfFengXuan = GameMain:GetMod("AmazingWorldOfFengXuan");

function tbWindow:OnInit()
	self.window.contentPane = CS.FairyGUI.UIPackage.CreateObject("AmazingWorldOfFengXuan", "StorageSettingsWindow");
	self.title = self:GetChild("title");
	self.tips = self:GetChild("tips");
	self.label = self:GetChild("label");
	self.list = self:GetChild("list");
	self.check1 = self:GetChild("check1");
	self.check2 = self:GetChild("check2");
	self.check3 = self:GetChild("check3");
	self.btn1 = self:GetChild("btn1");
	self.btn2 = self:GetChild("btn2");
	
	self.title.title = ("设置");
	self.label.text = ("存放物品类型：");
	self.check1.title = ("可交易");
	self.check2.title = ("可存放特殊物品");
	self.check3.title = ("自动收集");
	self.btn1.title = ("确定");
	self.btn2.title = ("取消");

	self.btn1.onClick:Add(self.Comfirm);
	self.btn2.onClick:Add(self.Cancel);
	self.window.modal = true;
	self.window:Center();
	self.inited = true;
end

function tbWindow:OnShowUpdate()
	self.window:BringToFront();
	for _, t in pairs(AmazingWorldOfFengXuan.storageTypes) do
		local selected = AmazingWorldOfFengXuan.store_types[t];
		local btn = self.list:AddItemFromPool();
		btn.title = t;
		btn.data = t;
		btn.selected = selected;
	end
	self.check1.selected = AmazingWorldOfFengXuan.storage_items.canTrade;
	self.check2.selected = AmazingWorldOfFengXuan.add_special;
	self.check3.selected = AmazingWorldOfFengXuan.auto_collect;
	if not self.pause then
		self.pause = true;
		CS.XiaWorld.MainManager.Instance:Pause(true);
	end
end

function tbWindow:OnHide()
	if self.called then
		self:UpdateSettings();
	end
	self.list:RemoveChildrenToPool();
	self.building = nil;
	if self.pause then
		self.pause = false;
		if CS.XiaWorld.MainManager.Instance ~= nil then
			CS.XiaWorld.MainManager.Instance:Play(0, true);
		end
	end
end

function tbWindow:Open(building)
	self.called = false;
	self.building = building;
	if self.window.isShowing then
		self:OnShowUpdate();
	else
		self:Show();
	end
end

function tbWindow:UpdateSettings()
	for i=0, self.list.numItems-1 do
		local btn = self.list:GetChildAt(i);
		AmazingWorldOfFengXuan.store_types[btn.data] = btn.selected;
	end
	AmazingWorldOfFengXuan.storage_items.canTrade = self.check1.selected;
	AmazingWorldOfFengXuan.add_special = self.check2.selected;
	AmazingWorldOfFengXuan.auto_collect = self.check3.selected;
	AmazingWorldOfFengXuan:UpdateStorage(self.building.Key);
end

function tbWindow.Comfirm(context)
	tbWindow.called = true;
	tbWindow:Hide();
end

function tbWindow.Cancel(context)
	tbWindow:Hide();
end

function tbWindow:RemoveCallback()
	if self.inited then
		self.btn1.onClick:Clear();
		self.btn2.onClick:Clear();
	end
end

