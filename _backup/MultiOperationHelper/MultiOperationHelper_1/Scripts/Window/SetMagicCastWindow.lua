local Windows = GameMain:GetMod("Windows");--先注册一个新的MOD模块
local SetMagicCastWindow = Windows:CreateWindow("SetMagicCastWindow");

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

function SetMagicCastWindow:Open(title, bn1, bn2, tips, callback1, data, height, modal, callback2)
	self.called = false;
	self._title = title or "设置";
	self._bn1 = bn1 or "确定";
	self._bn2 = bn2 or "取消";
	self._tips = tips or {};
	self._data = data or {};
	self.CallBack1 = callback1;
	self.CallBack2 = callback2;
	self._height = height or 220;
	self._modal = modal or false;
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
			self:AddItem(data);
		end
	end
	if self._height ~= nil then
		self.window.height = self._height;
	end
end

function SetMagicCastWindow:AddListItems(listdata)
	for _, data in pairs(listdata) do
		table.insert(self._data, data);
		self:AddItem(data);
	end	
end

function SetMagicCastWindow:AddItem(data)
	local item = self.list:AddItemFromPool();
	item.title = data.title;
	item.data = data.name;
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
