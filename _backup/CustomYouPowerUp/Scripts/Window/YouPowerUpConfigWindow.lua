local Windows = GameMain:GetMod("Windows");--先注册一个新的MOD模块
local CustomYouPowerUp = GameMain:GetMod("CustomYouPowerUp");
local YouPowerUpConfigWindow = Windows:CreateWindow("YouPowerUpConfigWindow");

function YouPowerUpConfigWindow:OnInit()
	self.window.contentPane =  UIPackage.CreateObject("CustomYouPowerUp", "CustomYouPowerUp");--载入UI包里的窗口
	self.window.closeButton = self:GetChild("frame"):GetChild("n5");
	self.title = self:GetChild("frame"):GetChild("title");
	self.input1 = self:GetChild("input1");
	self.input2 = self:GetChild("input2");
	self.bnt1 = self:GetChild("bnt1");
	self.bnt2 = self:GetChild("bnt2");
	self.title.text = "自定义幽淬";
	self.bnt1.onClick:Add(ConfirmClick);
	self.bnt2.onClick:Add(CancelClick);
	self.input1.tooltips = "设置值范围0--100；设置值=0时，使用游戏内的成功率（可以被其它Mod修改）。";
	self.input2.tooltips = "设置值范围1--12，表示幽淬一次提升的品阶，但品阶不会超过12。";
	self.window:Center();
	--print("YouPowerUpConfigWindow OnInit");
end

function ConfirmClick(context)
	local YouRate = tonumber(YouPowerUpConfigWindow.input1.title) or 100;
	local YouAdd = tonumber(YouPowerUpConfigWindow.input2.title) or 1;
	CustomYouPowerUp.YouPowerUp_rate = math.min(YouRate, 100);
	CustomYouPowerUp.YouPowerUp_add = math.max(1, math.min(YouAdd, 12));
	YouPowerUpConfigWindow:Hide();
	--print("YouPowerUpConfigWindow ConfirmButton");	
end

function CancelClick(context)
	YouPowerUpConfigWindow:Hide();
	--print("YouPowerUpConfigWindow CancelButton");
end

function YouPowerUpConfigWindow:OnShown()	
	self.input1.title = tostring(CustomYouPowerUp.YouPowerUp_rate);
	self.input2.title = tostring(CustomYouPowerUp.YouPowerUp_add);
	--print("YouPowerUpConfigWindow OnShown");
end
--print("YouPowerUpConfigWindow");