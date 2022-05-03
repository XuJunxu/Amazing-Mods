local Windows = GameMain:GetMod("Windows");
local OperationMsgWindow = Windows:CreateWindow("MultiOperationHelper_OperationMsgWindow");

local LanStr = {
	["确定"] = "Comfirm",
	["取消"] = "Cancel",
	["消息"] = "Message",
};
local GLS = Global_GetLanguageString(LanStr);

function OperationMsgWindow:OnInit()
	self.window.contentPane = CS.FairyGUI.UIPackage.CreateObject("MultiOperationHelper", "OperationMsgWindow");--载入UI包里的窗口
	self.title = self:GetChild("title");
	self.content = self:GetChild("content");
	self.btn1 = self:GetChild("btn1");
	self.btn2 = self:GetChild("btn2");
	self.btn1.title = GLS("确定");
	self.btn2.title = GLS("取消");
	
	self.btn1.onClick:Add(self.ButtonClick1);
	self.btn2.onClick:Add(self.ButtonClick2);
	self.window.modal = true;
	self.inited = true;
	--print("OperationMsgWindow OnInit");
end

function OperationMsgWindow:ShowMsg(title, content, bn1, bn2, callback)
	self.called = false;
	self._title = title or GLS("消息");
	self._content = content;
	self._bn1 = bn1 or GLS("确定");
	self._bn2 = bn2 or GLS("取消");
	self.CallBack = callback;
	if self.window.isShowing then
		self:OnShowUpdate();
	else
		self:Show();
	end
end

function OperationMsgWindow:OnShowUpdate()
	self.window:BringToFront();
	self.title.text = self._title;
	self.content.text = self._content;
	self.btn1.title = self._bn1;
	self.btn2.title = self._bn2;
	self.window:Center();
	if not self.pause then
		self.pause = true;
		CS.XiaWorld.MainManager.Instance:Pause(true);
	end
end

function OperationMsgWindow:OnHide()
	if self.called and self.CallBack ~= nil then
		self.CallBack();
	end
	self.CallBack = nil;
	if self.pause then
		self.pause = false;
		if CS.XiaWorld.MainManager.Instance ~= nil then
			CS.XiaWorld.MainManager.Instance:Play(0, true);
		end
	end
end

function OperationMsgWindow:RemoveCallback()
	if self.inited then
		self.btn1.onClick:Clear();
		self.btn2.onClick:Clear();
	end
end

function OperationMsgWindow.ButtonClick1(context)
	OperationMsgWindow.called = true;
	OperationMsgWindow:Hide();
end

function OperationMsgWindow.ButtonClick2(context)
	OperationMsgWindow:Hide();
end