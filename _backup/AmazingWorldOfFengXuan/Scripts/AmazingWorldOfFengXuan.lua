local tbMod = GameMain:NewMod("AmazingWorldOfFengXuan");--先注册一个新的MOD模块

local SaveData = {};

function tbMod:OnBeforeInit()
	xlua.private_accessible(CS.XLua.LuaEnv);
	xlua.private_accessible(CS.XLua.ObjectTranslator);
	local assemblies = CS.XiaWorld.LuaMgr.Instance.Env.translator.assemblies;
	for i=0, assemblies.Count-1 do
		if assemblies[i]:GetName().Name == "AmazingWorldOfFengXuan" then
			return;
		end
	end
	local mod_path = CS.ModsMgr.Instance:FindMod("AmazingWorldOfFengXuan", nil, true).Path;
	local file_path = CS.System.IO.Path.Combine(CS.System.IO.Path.Combine(mod_path, "Assemblies"), "AmazingWorldOfFengXuan.dll");
	local assembly = CS.System.Reflection.Assembly.LoadFrom(file_path);
	assemblies:Add(assembly);
	print("AmazingWorldOfFengXuan before inited.")
end

function tbMod:OnInit()
	CS.AmazingWorldOfFengXuan.Main.Init();
	local item_list = SaveData.storage_items or {};
	self.storage_items = CS.AmazingWorldOfFengXuan.EquipmentStorage.Instance;
	self.storage_items:Load(item_list);
	self.store_types = SaveData.store_types or {};
	for _, t in pairs(self.storageTypes) do
		if self.store_types[t] == nil then
			self.store_types[t] = true;
		end
	end
	if SaveData.can_trade ~= nil then
		self.storage_items.canTrade = SaveData.can_trade;
	else
		self.storage_items.canTrade = true;
	end
	self.add_special = SaveData.add_special or false;
	self.auto_collect = SaveData.auto_collect or false;
	self.last_collect_time = 0;
end

function tbMod:OnEnter()
	
	local Windows = GameMain:GetMod("Windows");
	self.EquipmentStorageWindow = Windows:GetWindow("AmazingWorldOfFengXuan_EquipmentStorageWindow");
	self.StorageSettingsWindow = Windows:GetWindow("AmazingWorldOfFengXuan_StorageSettingsWindow");
	xlua.private_accessible(CS.XiaWorld.ThingsData);
	
	print("tbMod OnEnter");
end

function tbMod:OnSetHotKey()
	local tbHotKey = { {ID = "Test" , Name = "Mod测试按键" , Type = "Mod", InitialKey1 = "LeftShift+A" , InitialKey2 = "Equals" } };
	
	return tbHotKey;
end

function tbMod:OnHotKey(ID,state)
	if ID == "Test" and state == "down" then 
 
    end
end

function tbMod:OnStep(dt)
	if self.auto_collect then
		local T = CS.XiaWorld.World.Instance.TolSecond;
		if T - self.last_collect_time >= 25 then
			self.last_collect_time = T;
			local building = CS.XiaWorld.World.Instance.map.Things:FindBuilding(nil, 9999, nil, 0, false, false, 0, 9999, nil, "Building_SleeveSpace2", false);
			self:CollectToStorage(building);
		end
	end
end

function tbMod:OnLeave()
	self.EquipmentStorageWindow:RemoveCallback();
	self.StorageSettingsWindow:RemoveCallback();
	print("tbMod OnLeave");
end

function tbMod:OnSave()--系统会将返回的table存档 table应该是纯粹的KV
	local item_list = {};
	for _, id in pairs(self.storage_items:GetIDList()) do
		table.insert(item_list, id)
	end
	local tbSave = {
		storage_items = item_list;
		store_types = self.store_types;
		can_trade = self.storage_items.canTrade;
		add_special = self.add_special;
		auto_collect = self.auto_collect;
	};
	return tbSave;
end

function tbMod:OnLoad(tbLoad)--读档时会将存档的table回调到这里
	SaveData = tbLoad or {};
end

function tbMod:NeedSyncData()--切换地图的时候是否会同步数据，请谨慎使用
	 return true;
end

function tbMod:OnSyncLoad(tbData)	--切换地图的时候载入的数据
	print("tbMod OnSyncLoad");
	self.syncdata = tbData;
end

function tbMod:OnSyncSave()	--切换地图时传输的数据
	print("tbMod OnSyncSave");
	return {a=1,b=2};
end

function tbMod:OnAfterLoad()	--读档且所有系统准备完毕后，切换地图后也会调用
	print("tbMod OnAfterLoad");
end

function tbMod:OpenSettings(building)
	self.StorageSettingsWindow:Open(building);
end

function tbMod:OpenStorage(building)
	self.storage_items:CheckItems();
	local items = {};
	for _, item in pairs(self.storage_items:GetItemList(true)) do
		table.insert(items, item);
	end
	self.EquipmentStorageWindow:Open(building, items);
end

function tbMod:CanCollect(item)
	if item ~= nil and item.def ~= nil and item.def.Item ~= nil and item.def.Item.Lable ~= nil then
		local type_ = self.typeLable[item.def.Item.Lable];
		return (self:CanStore(item) and item.InWhoseBag <= 0 and item.InWhoseHand <= 0 and item.AtG and item.Actable and (not item.InDark) and item.FreeCount > 0 and 
				CS.XiaWorld.TongLingMgr.Instance:GetTongLingData(item.ID) == nil and item.def.MaxStack == 1 and item.pAnimal == nil and item.NoStackFlag == 0);
	end
	return false;
end

function tbMod:CanStore(item)
	local type_ = self.typeLable[item.def.Item.Lable];
	return (type_ ~= nil and self.store_types[type_] and ((item.YouPower <= 0 and item.LingPower <= 0 and item.FSItemState <= 0 and item.HelianValue == nil) or self.add_special));
end

function tbMod:CollectToStorage(building)
	if building.BuildingState ~= CS.XiaWorld.g_emBuildingState.Working then
		return;
	end
	local res, item_things = CS.XiaWorld.World.Instance.map.Things.m_TypeThings:TryGetValue(CS.XiaWorld.g_emThingType.Item);
	if res and item_things ~= nil then
		local item_list = {};
		for _, item in pairs(item_things) do
			if self:CanCollect(item) then
				table.insert(item_list, item);
			end
		end
		local num = 0;
		local pos = CS.XiaWorld.GridMgr.Inst:Grid2Pos(building.Key);
		if CS.XiaWorld.GridMgr.Inst:KeyVaild(building.Key) then
			num = 30;
		end
		for _, item in pairs(item_list) do
			self:AddItem(item);
			if num > 0 then
				CS.FlyLineRender.Fly(item.Pos, pos, CS.XiaWorld.World.RandomRange(0.2, 1, CS.GMathUtl.RandomType.emNone), nil, nil, nil, "Effect/System/FlyLine");
				num = num - 1;
			end		
		end
	end	
end

function tbMod:UpdateStorage(key)
	self.storage_items:CheckItems();
	for _, item in pairs(self.storage_items:GetItemList()) do
		if not self:CanStore(item) then
			self:DropItem(item, key);
		end
	end	
end

function tbMod:AddItem(item)	--ThingsBag.AddItem
	if self.storage_items:AddItem(item.ID) then
		item:PickUp();
	end
end

function tbMod:DropItem(item, key)	--ThingsBag.DropItem
	if self.storage_items:RemoveItem(item.ID) and key ~= nil and key > 0 then
		CS.XiaWorld.World.Instance.map:DropItem(item, key, true, true, true, false, 0, false, false, nil)
		return true;
	end
	return false;
end

tbMod.storageTypes = {("衣物"), ("武器"), ("工具"), ("符咒"), ("宝物"), ("法宝"), ("其他")};
local g_emItemLable = CS.XiaWorld.g_emItemLable;
tbMod.typeLable = {
	[g_emItemLable.Clothes] = ("衣物"),
	[g_emItemLable.Trousers] = ("衣物"),
	[g_emItemLable.Weapon] = ("武器"),
	[g_emItemLable.Spell] = ("符咒"),
	[g_emItemLable.Tool] = ("工具"),
	[g_emItemLable.Treasure] = ("宝物"),
	[g_emItemLable.FightFabao] = ("法宝"),
	[g_emItemLable.TreasureFabao] = ("法宝"),
	[g_emItemLable.Other] = ("其他"),
	[g_emItemLable.Cape] = ("衣物"),
	[g_emItemLable.Horse] = ("其他"),
};


