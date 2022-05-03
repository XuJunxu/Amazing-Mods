local Windows = GameMain:GetMod("Windows");--先注册一个新的MOD模块
local AutoCloseConfigWindow = Windows:CreateWindow("AutoCloseConfigWindow");
local AutoCloseWindow = GameMain:GetMod("AutoCloseWindow");

function AutoCloseConfigWindow:OnInit()
	self.window.contentPane = CS.FairyGUI.UIPackage.CreateObject("AutoCloseWindow", "AutoCloseConfigWindow");
	self.window.closeButton = self:GetChild("frame"):GetChild("n5");
	self.list = self:GetChild("list");
	self.btn1 = self:GetChild("btn1");
	self.btn2 = self:GetChild("btn2");
	self.btn1.onClick:Add(function(context)
		self:Confirm();
		self:Hide();
	end);
	self.btn2.onClick:Add(function(context)
		self:Hide();
	end);
	self.window:Center();
end

function AutoCloseConfigWindow:Confirm()
	for i=0, self.list.numItems-1 do
		local checkbox = self.list:GetChildAt(i);
		AutoCloseWindow.message_config[checkbox.data].AutoClose = checkbox.selected;
	end
	AutoCloseWindow:GetAutoCloseList();
end

function AutoCloseConfigWindow:Open()
	if self.window.isShowing then
		self:OnShowUpdate();
	else
		self:Show();
	end
end

function AutoCloseConfigWindow:OnShowUpdate()
	self.window:BringToFront();
	self.list:RemoveChildrenToPool();
	if AutoCloseWindow.message_config ~= nil then
		local mtype_list = {};
		for mtype, _ in pairs(AutoCloseWindow.message_config) do
			table.insert(mtype_list, mtype);
		end
		table.sort(mtype_list);
		for _, mtype in pairs(mtype_list) do
			local config = AutoCloseWindow.message_config[mtype];
			local checkbox = self.list:AddItemFromPool();
			checkbox.data = mtype;
			checkbox.title = config.MsgType;
			checkbox.tooltips = config.Tooltips;
			checkbox.selected = config.AutoClose;
		end
	end
end

function AutoCloseConfigWindow:OnHide()
	self.list:RemoveChildrenToPool();
end

