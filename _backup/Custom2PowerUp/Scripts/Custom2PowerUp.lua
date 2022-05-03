local Custom2PowerUp = GameMain:NewMod("Custom2PowerUp");--先注册一个新的MOD模块
local Custom2ConfigWindow;
local SaveData = {};

function Custom2PowerUp:OnInit()
	self.YouPowerUp_rate = SaveData.YouRate or 100;
	self.YouPowerUp_add = SaveData.YouAdd or 1;
	self.YouPowerUp_num = SaveData.YouNum or 1;
	self.LingPowerUp_rate = SaveData.LingRate or 100;
	self.LingPowerUp_add = SaveData.LingAdd or 1;
	self.LingPowerUp_num = SaveData.LingNum or 1;		
	Custom2ConfigWindow = GameMain:GetMod("Windows"):GetWindow("Custom2ConfigWindow");
	--print("Custom2PowerUp OnInit");
end

function Custom2PowerUp:OnEnter()
	--print("Custom2PowerUp OnEnter");
end

function Custom2PowerUp:OnSetHotKey()
	local tbHotKey = { {ID = "Custom2ConfigWindowShow" , Name = "自定义幽淬灵淬" , Type = "Mod", InitialKey1 = "RightControl+P" } };	
	return tbHotKey;
end

function Custom2PowerUp:OnHotKey(ID, state)
	if ID == "Custom2ConfigWindowShow" and state == "down" then
		if Custom2ConfigWindow.window.isShowing then
			Custom2ConfigWindow:Hide();
		else
			Custom2ConfigWindow:Show();
		end
	end	   
	
end

function Custom2PowerUp:OnSave()--系统会将返回的table存档 table应该是纯粹的KV	
	local tbSave = {
		YouRate = self.YouPowerUp_rate,
		YouAdd = self.YouPowerUp_add,
		YouNum = self.YouPowerUp_num,
		LingRate = self.LingPowerUp_rate,
		LingAdd = self.LingPowerUp_add,
		LingNum = self.LingPowerUp_num
	};
	--print("Custom2PowerUp OnSave");
	return tbSave;
end

function Custom2PowerUp:OnLoad(tbLoad)--读档时会将存档的table回调到这里
	SaveData = tbLoad or {};
	--print("Custom2PowerUp OnLoad");
end
--print("Custom2PowerUp");

