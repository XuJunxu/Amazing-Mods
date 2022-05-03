local Windows = GameMain:GetMod("Windows");
local NumberSettingWindow = Windows:CreateWindow("MultiOperationHelper_NumberSettingWindow");

local LanStr = {
	["确定"] = "Comfirm",
	["取消"] = "Cancel",
	["设置"] = "Settings",
	["说明"] = "Help",
};
local GLS = Global_GetLanguageString(LanStr);

function NumberSettingWindow:OnInit()
	self.window.contentPane = CS.FairyGUI.UIPackage.CreateObject("MultiOperationHelper", "MultiSelectWindow");--载入UI包里的窗口
	self.title = self:GetChild("title");
	self.list = self:GetChild("list");
	self.btn1 = self:GetChild("btn1");
	self.btn2 = self:GetChild("btn2");
	self.tips = self:GetChild("tips");
	self.btn1.title = GLS("确定");
	self.btn2.title = GLS("取消");
	
	self.btn1.onClick:Add(self.ButtonClick1);
	self.btn2.onClick:Add(self.ButtonClick2);
	self.window.modal = true;
	self.window:Center();
	--print("NumberSettingWindow OnInit");
end

function NumberSettingWindow:Open(title, bn1, bn2, tips, data, callback1)
	if self.window.isShowing then
		self:Hide();
	end
	self.called = false;
	self._title = title or GLS("设置");
	self._bn1 = bn1 or GLS("确定");
	self._bn2 = bn2 or GLS("取消");
	self._tips = tips;
	self._data = data or {};
	self.CallBack1 = callback1;
	if self.window.isShowing then
		self:OnShowUpdate();
	else
		self:Show();
	end
end

function NumberSettingWindow:OnShowUpdate()
	self.window:BringToFront();
	self.list:RemoveChildrenToPool();
	self.title.text = self._title;
	self.btn1.title = self._bn1;
	self.btn2.title = self._bn2;
	if self._tips == nil then
		self.tips.title = "";
		self.tips.tooltips = "";
	else
		self.tips.title = GLS("说明");
		self.tips.tooltips = self._tips;
	end
	if self._data ~= nil then
		for _, data in pairs(self._data) do
			self:AddListItem(data);
		end
	end
	if not self.pause then
		self.pause = true;
		CS.XiaWorld.MainManager.Instance:Pause(true);
	end
end

function NumberSettingWindow:AddListItem(data)
	local item = self.list:AddItemFromPool();
	item.title = data.name;
	item.data = data.id;
	item.tooltips = data.desc;
	local input = item:GetChild("input");
	input.title = data.data;
end

function NumberSettingWindow:OnHide()
	local list_data = {};
	for i=0, self.list.numItems-1 do
		local list_item = self.list:GetChildAt(i);
		local input = tonumber(list_item:GetChild("input").title) or 0;
		table.insert(list_data, {id = list_item.data, data = input});
	end
	if self.called and self.CallBack1 ~= nil then
		self.CallBack1(list_data);
	end
	self.list:RemoveChildrenToPool();
	self._tips = nil;
	self._data = nil;
	self.CallBack1 = nil;
	if self.pause then
		self.pause = false;
		if CS.XiaWorld.MainManager.Instance ~= nil then
			CS.XiaWorld.MainManager.Instance:Play(0, true);
		end
	end
	--print("NumberSettingWindow OnHide");
end

function NumberSettingWindow:RemoveCallback()
	self.btn1.onClick:Clear();
	self.btn2.onClick:Clear();
end

function NumberSettingWindow.ButtonClick1(context)
	NumberSettingWindow.called = true;
	NumberSettingWindow:Hide();
end

function NumberSettingWindow.ButtonClick2(context)
	NumberSettingWindow:Hide();
end