local Windows = GameMain:GetMod("Windows");--先注册一个新的MOD模块
local OperationMenuWindow = Windows:CreateWindow("OperationMenuWindow");

function OperationMenuWindow:OnInit()
	self.window.contentPane = CS.FairyGUI.UIPackage.CreateObject("MultiOperationHelper", "OperationMenuWindow");--载入UI包里的窗口
	self.list = self:GetChild("list");
	self.list.onClickItem:Add(function(context)
		self:ClickBtn(context);
		CS.FairyGUI.GRoot.inst:HidePopup(self.window.contentPane);
	end);
	--print("OperationMenuWindow OnInit");
end

function OperationMenuWindow:ShowMenu(thing, menu, callBack)
	self.thing = thing;
	self.menu = menu;
	self.callBack = callBack;
	if self.window.isShowing then
		self:OnShowUpdate();
	else
		self:Show();
	end
end

function OperationMenuWindow:OnShowUpdate()
	self.window:BringToFront();
	self.list:RemoveChildrenToPool();
	for _, memu_item in pairs(self.menu) do
		local button = self.list:AddItemFromPool();
		local bg = button:GetController("bg");
		bg.selectedIndex = memu_item.bg or 0;
		button.title = memu_item.dspName;
		button.icon = memu_item.icon;
		button.data = memu_item.data;
		button.tooltips = memu_item.tooltips;
		button.grayed = memu_item.grayed == nil or memu_item.grayed;
		button.enabled = memu_item.enabled == nil or memu_item.enabled;
	end
	CS.FairyGUI.GRoot.inst:ShowPopup(self.window.contentPane);  --Wnd_SelectThing.OnShowUpdate()
	self.window.contentPane.onRemovedFromStage:Add(function() self.window:Hide(); end);
end

function OperationMenuWindow:ClickBtn(context)
	local data = context.data.data;
	self.callBack(self.thing, data)
end

function OperationMenuWindow:OnHide()
	self.list:RemoveChildrenToPool();
	self.thing = nil;
	self.menu = nil;
	self.callBack = nil;
	--print("OperationMenuWindow OnHide");
end
