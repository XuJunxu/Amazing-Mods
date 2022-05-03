local Windows = GameMain:GetMod("Windows");--先注册一个新的MOD模块
local OperationMsgWindow = Windows:CreateWindow("OperationMsgWindow");

function OperationMsgWindow:OnInit()
	self.window.contentPane = CS.FairyGUI.UIPackage.CreateObject("MultiOperationHelper", "OperationMsgWindow");--载入UI包里的窗口
	self.window.closeButton = self:GetChild("frame"):GetChild("n5");
	self.title = self:GetChild("frame"):GetChild("title");
	self.content = self:GetChild("content");
	self.btn1 = self:GetChild("btn1");
	self.btn2 = self:GetChild("btn2");
	self.btn1.onClick:Add(function(context)
		if self.CallBack ~= nil then
			self.CallBack();
		end
		self:Hide();
	end);	
	self.btn2.onClick:Add(function(context)
		self:Hide();
	end);
	self.window.modal = true;
	--print("OperationMsgWindow OnInit");
end

function OperationMsgWindow:ShowMsg(title, content, bn1, bn2, callback)
	self._title = title or "消息";
	self._content = content;
	self._bn1 = bn1 or "确定";
	self._bn2 = bn2 or "取消";
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
	self.CallBack = nil;
	if self.pause then
		self.pause = false;
		CS.XiaWorld.MainManager.Instance:Play(0, true);
	end
end