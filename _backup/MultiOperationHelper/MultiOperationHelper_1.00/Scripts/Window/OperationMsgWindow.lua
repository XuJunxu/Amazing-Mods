local Windows = GameMain:GetMod("Windows");--先注册一个新的MOD模块
local OperationMsgWindow = Windows:CreateWindow("OperationMsgWindow");

function OperationMsgWindow:OnInit()
	self.window.contentPane = UIPackage.CreateObject("MultiOperationHelper", "OperationMsgWindow");--载入UI包里的窗口
	self.title = self:GetChild("frame"):GetChild("title");
	self.content = self:GetChild("content");
	self.btn1 = self:GetChild("btn1");
	self.btn2 = self:GetChild("btn2");
	self.btn_name1 = self:GetChild("bname1");
	self.btn_name2 = self:GetChild("bname2");
	self.btn1.onClick:Add(function(context)
		if self.CallBack ~= nil then
			self.CallBack();
		end
		self:Hide();
	end);	
	self.btn2.onClick:Add(function(context)
		self:Hide();
	end);
	self.window:Center();
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
	self.btn_name1.text = self._bn1;
	self.btn_name2.text = self._bn2;
end

function OperationMsgWindow:OnHide()
	self.CallBack = nil;
end