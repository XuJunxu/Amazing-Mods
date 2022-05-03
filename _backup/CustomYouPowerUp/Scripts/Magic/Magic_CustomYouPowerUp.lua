local tbTable = GameMain:GetMod("MagicHelper");--获取神通模块 这里不要动
local CustomYouPowerUp = GameMain:GetMod("CustomYouPowerUp");
local tbMagic = tbTable:GetMagic("Magic_CustomYouPowerUp");--创建一个新的神通class

function tbMagic:Init()
end

function tbMagic:TargetCheck(k, t)
	--print("TargetCheck");
	return true;
end

function tbMagic:MagicEnter(IDs, IsThing)
	self.itemId = IDs[0];
	--print("MagicEnter");
end

function tbMagic:MagicStep(dt, duration)	
	self:SetProgress(duration/self.magic.Param1);
	if duration >= self.magic.Param1 then
		return 1;	
	end
	return 0;
end

function tbMagic:MagicLeave(success)
	if success == true then	
		local item = ThingMgr:FindThingByID(self.itemId);
		if item ~= nil then	
			local LuaHelper = self.bind.LuaHelper;
			local FS = LuaHelper:GetRoomFengshui();
			--print("RoomFengshui "..FS);
			local badd = 0;
			if FS >= 4 then
				badd = (FS - 3) * 0.01;
			end
			local rate = CustomYouPowerUp.YouPowerUp_rate/100;
			local add = CustomYouPowerUp.YouPowerUp_add;	
			local res = item:SoulCrystalYouPowerUp(badd, rate, add);
			if res then
				world:PlayEffect(10005, item.Pos);
			else
				world:PlayEffect(10006, item.Pos);
			end
		end
	end
end

function tbMagic:OnGetSaveData()
	return nil;
end

function tbMagic:OnLoadData(tbData,IDs, IsThing)	
	self.itemId = IDs[0];
end


