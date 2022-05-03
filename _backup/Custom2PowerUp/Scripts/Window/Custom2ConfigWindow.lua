local Windows = GameMain:GetMod("Windows");--先注册一个新的MOD模块
local Custom2PowerUp = GameMain:GetMod("Custom2PowerUp");
local Custom2ConfigWindow = Windows:CreateWindow("Custom2ConfigWindow");

function Custom2ConfigWindow:OnInit()
	self.window.contentPane =  UIPackage.CreateObject("Custom2PowerUp", "Custom2ConfigWindow");--载入UI包里的窗口
	self.window.closeButton = self:GetChild("frame"):GetChild("n5");
	self.window:Center();
	self.title = self:GetChild("title");
	self.input1 = self:GetChild("input_1");
	self.input2 = self:GetChild("input_2");
	self.input3 = self:GetChild("input_3");
	self.input4 = self:GetChild("input_4");
	self.input5 = self:GetChild("input_5");
	self.input6 = self:GetChild("input_6");
	self.bnt1 = self:GetChild("bnt_1");
	self.bnt2 = self:GetChild("bnt_2");
	self.title.text = "自定义幽淬灵淬";
	self.bnt1.onClick:Add(ConfirmClick);
	self.bnt2.onClick:Add(CancelClick);
	--print("Custom2ConfigWindow OnInit");
end

function ConfirmClick(context)
	local YouRate = tonumber(Custom2ConfigWindow.input1.title) or 100;
	local YouAdd = tonumber(Custom2ConfigWindow.input2.title) or 1;
	local YouNum = tonumber(Custom2ConfigWindow.input3.title) or 1;
	local LingRate = tonumber(Custom2ConfigWindow.input4.title) or 100;
	local LingAdd = tonumber(Custom2ConfigWindow.input5.title) or 1;
	local LingNum = tonumber(Custom2ConfigWindow.input6.title)or 1;
	Custom2PowerUp.YouPowerUp_rate = math.min(YouRate, 100);
	Custom2PowerUp.YouPowerUp_add = math.max(1, math.min(YouAdd, 12));
	Custom2PowerUp.YouPowerUp_num = math.max(1, YouNum);
	Custom2PowerUp.LingPowerUp_rate = math.min(LingRate, 100);
	Custom2PowerUp.LingPowerUp_add = math.max(1, LingAdd);
	Custom2PowerUp.LingPowerUp_num = math.max(1, LingNum);
	Custom2ConfigWindow:Hide();
	--print("Custom2ConfigWindow ConfirmButton");	
end

function CancelClick(context)	
	Custom2ConfigWindow:Hide();
	--print("Custom2ConfigWindow CancelButton");
end

function Custom2ConfigWindow:OnShown()	
	self.input1.title = tostring(Custom2PowerUp.YouPowerUp_rate);
	self.input2.title = tostring(Custom2PowerUp.YouPowerUp_add);
	self.input3.title = tostring(Custom2PowerUp.YouPowerUp_num);
	self.input4.title = tostring(Custom2PowerUp.LingPowerUp_rate);
	self.input5.title = tostring(Custom2PowerUp.LingPowerUp_add);
	self.input6.title = tostring(Custom2PowerUp.LingPowerUp_num);
	--print("Custom2ConfigWindow OnShown");
end
--print("Custom2ConfigWindow");