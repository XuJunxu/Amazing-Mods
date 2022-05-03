local tbTable = GameMain:GetMod("MagicHelper");--获取神通模块 这里不要动
local Custom2PowerUp = GameMain:GetMod("Custom2PowerUp");
local tbMagic = tbTable:GetMagic("Magic_Custom2LingPowerUp");--创建一个新的神通class

function tbMagic:Init()
end

function tbMagic:TargetCheck(k, t)
	if t.Accommodate <= 0 then
		return false;
	end
	return true;
end

function tbMagic:MagicEnter(IDs, IsThing)
	self.itemId = IDs[0];
	--print("ID "..self.itemId);
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
		local LuaHelper = self.bind.LuaHelper;
		local FS = LuaHelper:GetRoomFengshui();
		--print("RoomFengshui "..FS);
		local badd = 0;
		if FS >= 4 then
			badd = (FS - 3) * 0.01;
		end
		local rate = Custom2PowerUp.LingPowerUp_rate/100;
		local add = Custom2PowerUp.LingPowerUp_add;
		local item = ThingMgr:FindThingByID(self.itemId);
		if item ~= nil then
			for n=1, math.min(Custom2PowerUp.LingPowerUp_num, item.Count) do		
				local res = SoulCrystalLingPowerUp(item, badd, rate, add);
				if res then
					world:PlayEffect(10005, item.Pos);
				else
					world:PlayEffect(10006, item.Pos);
				end
			end
		end
	end
end

function SoulCrystalLingPowerUp(item, badd, rate, add)
	local a = 1; --= math.pow(GameDefine.SOULCRYSTALLING_BASE + badd, item.Rate);
	for n=1, item.Rate do
		a = a * GameDefine.SOULCRYSTALLING_BASE + badd;
	end
	if rate > 0 then
		a = rate;
	end
	--print("rate = "..a);
	if world:CheckRate(a) then
		--print("OnLingPowerUp")
		local itemThing = item;
		if item.Count > 1 then
			itemThing = item:Split(1);
			item.map:DropItem(itemThing, item.Key, true, true, true, false);
			world:FlyLineEffect(item.Pos, itemThing.Pos, 0.2);
		end
		itemThing.LingPower = itemThing.LingPower + add;
		if itemThing.IsFaBao then
			local g_emFaBaoP = CS.XiaWorld.Fight.g_emFaBaoP;
			local property = itemThing.Fabao.GetProperty(g_emFaBaoP.MaxLing);
			local addp = 1;
			for m=1, add do
				addp = addp * 1.05;
			end
			itemThing.Fabao.SetProperty(g_emFaBaoP.MaxLing, property * addp);
		else
			itemThing.AccommodateAddv = itemThing.AccommodateAddv + 5.0 * add;
		end
		world:PlayAudio("Sound/ding");
		return true;
	end
	return false;
end

function tbMagic:OnGetSaveData()
	return nil;
end

function tbMagic:OnLoadData(tbData,IDs, IsThing)	
	self.itemId = IDs[0];
end


