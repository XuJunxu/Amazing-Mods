local CustomYouPowerUp = GameMain:NewMod("CustomYouPowerUp");--先注册一个新的MOD模块
local SaveData = {};

function CustomYouPowerUp:OnInit()
	self.YouPowerUp_rate = SaveData.YouRate or 100;
	self.YouPowerUp_add = SaveData.YouAdd or 1;		
	--print("CustomYouPowerUp OnInit");
end

function CustomYouPowerUp:OnEnter()
	CS.XiaWorld.GameDefine.SOULCRYSTALLING_BASE = 1;
	--print("CustomYouPowerUp OnEnter");
end

function CustomYouPowerUp:OnSetHotKey()
	local tbHotKey = { {ID = "YouPowerUpConfigWindow" , Name = "自定义幽淬" , Type = "Mod", InitialKey1 = "RightControl+P" } };	
	return tbHotKey;
end

function CustomYouPowerUp:OnHotKey(ID, state)
	if ID == "YouPowerUpConfigWindow" and state == "down" then
		local YouPowerUpConfigWindow = GameMain:GetMod("Windows"):GetWindow("YouPowerUpConfigWindow");
		if YouPowerUpConfigWindow.window.isShowing then
			YouPowerUpConfigWindow:Hide();
		else
			YouPowerUpConfigWindow:Show();
		end
	end	   
	
end

function CustomYouPowerUp:OnSave()--系统会将返回的table存档 table应该是纯粹的KV	
	local tbSave = {
		YouRate = self.YouPowerUp_rate,
		YouAdd = self.YouPowerUp_add,
	};
	--print("CustomYouPowerUp OnSave");
	return tbSave;
end

function CustomYouPowerUp:OnLoad(tbLoad)--读档时会将存档的table回调到这里
	SaveData = tbLoad or {};
	--print("CustomYouPowerUp OnLoad");
end
--print("CustomYouPowerUp");

