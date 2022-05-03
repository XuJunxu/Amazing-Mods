local CustomRomoteStorage = GameMain:NewMod("CustomRomoteStorage");--先注册一个新的MOD模块

local SaveData = {};

function CustomRomoteStorage:OnInit()
	self.all_item_data = SaveData.all_item_data or {};
	self.mod_enable = true;
	self.last_selected = nil;
	self.path = "Settings/ThingDef/RSThingType/RSThingType.txt";
	self.org_RSThingType = {};
	self.mod_RSThingType = {};
	--print("CustomRomoteStorage OnInit");
end

function CustomRomoteStorage:OnEnter()
	if not self:CheckModLegal() or CS.XiaWorld.World.Instance.GameMode == CS.XiaWorld.g_emGameMode.Fight then
		self.mod_enable = false;
		return;
	end	
	self.StorageConfigWindow = GameMain:GetMod("Windows"):GetWindow("StorageConfigWindow");
	self.StorageConfigWindow:Init();
	local Event = GameMain:GetMod("_Event");
	local g_emEvent = CS.XiaWorld.g_emEvent;
	Event:RegisterEvent(g_emEvent.SelectBuilding,  function(evt, build, objs) 
		self:AddBtn2Build(evt, build, objs); 
	end, "AddBtn2Build");

	self:GetOrgRSThingType();
	self:GetModRSThingType();
	self:GetAllItemData();
	self:ResetRemoteItemType();
	--self:OpenConfigWindow();
	print("CustomRomoteStorage Enter");
end

function CustomRomoteStorage:AddBtn2Build(evt, thing, objs)  --向添加按键
	if thing == nil or thing == self.last_selected or not self.mod_enable then
		return;
	end
	self.last_selected = thing;
	thing:RemoveBtnData("自定义");
	if thing.BuildingState == CS.XiaWorld.g_emBuildingState.Working and thing:IsSleeveSpace() then
		thing:AddBtnData("自定义", "res/Sprs/ui/icon_huafu01", "GameMain:GetMod('CustomRomoteStorage'):OpenConfigWindow();", "");
	end
end

function CustomRomoteStorage:OpenConfigWindow()
	local show_data = {};
	local show_list_data = {};
	local temp = {};
	for name, data in pairs(self.all_item_data) do
		local def = CS.XiaWorld.ThingMgr.Instance:GetDef(CS.XiaWorld.g_emThingType.Item, name);
		show_data[name] = {
			name = name, 
			dspName = def.ThingName or name, 
			itemType = data.itemType,
			added = data.added,
			canChange = true,
			tooltips = def.Desc,		
		};
	end
	for name, _ in pairs(self.org_RSThingType) do
		if temp[name] == nil and show_data[name] ~= nil then
			show_data[name].dspName = "(原有) "..show_data[name].dspName;
			show_data[name].canChange = false;
			show_data[name].tooltips = "[color=#FF0000]乾坤界原有物品，可以修改分类，不可移除[/color]\n\n"..show_data[name].tooltips;
			table.insert(show_list_data, show_data[name]);
			temp[name] = name;
		end
	end
	for name, _ in pairs(self.org_RSThingType) do
		if temp[name] == nil and show_data[name] ~= nil then
			show_data[name].dspName = "(模组) "..show_data[name].dspName;
			show_data[name].canChange = false;
			show_data[name].tooltips = "[color=#FF0000]被其他模组添加进乾坤界，可以修改分类，不可移除[/color]\n\n"..show_data[name].tooltips;
			table.insert(show_list_data, show_data[name]);
			temp[name] = name;
		end
	end
	for name, data in pairs(show_data) do
		if temp[name] == nil then
			table.insert(show_list_data, data);
			temp[name] = name;
		end
	end
	self.StorageConfigWindow:Open(show_list_data);
end

function CustomRomoteStorage:GetItemType(name)
	local item_type = "其他";
	local def = CS.XiaWorld.ThingMgr.Instance:GetDef(CS.XiaWorld.g_emThingType.Item, name);
	if def ~= nil and def.Item ~= nil and def.Item.Lable ~= nil and self.itemType[def.Item.Lable] ~= nil then
		item_type = self.itemType[def.Item.Lable];
	end
	return item_type;
end

function CustomRomoteStorage:GetAllItemData()  --获取所有可以自行设置的物品，会过滤没有Def的物品
	local ThingMgr = CS.XiaWorld.ThingMgr;
	local thingType = CS.XiaWorld.g_emThingType.Item;
	local all_item_data = {};
	for name, tp in pairs(self.org_RSThingType) do
		if all_item_data[name] == nil and ThingMgr.Instance:GetDef(thingType, name, false) ~= nil then
			if self.all_item_data[name] ~= nil then
				all_item_data[name] = {added = true, itemType = self.all_item_data[name].itemType}; 
			else
				all_item_data[name] = {added = true, itemType = self:GetItemType(name)};
			end
		end
	end
	for name, tp in pairs(self.mod_RSThingType) do
		if all_item_data[name] == nil and ThingMgr.Instance:GetDef(thingType, name, false) ~= nil then			
			if self.all_item_data[name] ~= nil then
				all_item_data[name] = {added = true, itemType = self.all_item_data[name].itemType}; 
			else
				all_item_data[name] = {added = true, itemType = self:GetItemType(name)};
			end
		end
	end	
	for _, name in pairs(ThingMgr.s_AllItemNames) do
		if all_item_data[name] == nil then
			local def = ThingMgr.Instance:GetDef(thingType, name, false);
			local n, m = string.find(name, "Base", -4);
			if def ~= nil and def.Item ~= nil and def.Item.Lable ~= nil and self.banLable[def.Item.Lable] == nil and n == nil then
				if self.all_item_data[name] ~= nil then
					all_item_data[name] = self.all_item_data[name];
				else
					all_item_data[name] = {added = false, itemType = self:GetItemType(name)};
				end
			end
		end
	end
	xlua.private_accessible(CS.XiaWorld.RemoteStorage);
	for name, count in pairs(CS.XiaWorld.World.Instance.map.SpaceRing.Storage) do
		local def = ThingMgr.Instance:GetDef(thingType, name, false);
		if count > 0 and def ~= nil then
			if all_item_data[name] == nil then
				if self.all_item_data[name] ~= nil then
					all_item_data[name] = {added = true, itemType = self.all_item_data[name].itemType};
				else
					all_item_data[name] = {added = true, itemType = self:GetItemType(name)};
				end
			else
				all_item_data[name].added = true;
			end
		end
	end
	self.all_item_data = all_item_data;
end

function CustomRomoteStorage:GetRSThingType(path, full)  --获取乾坤界物品表格
	local result = {};
	local text = CS.GFileUtil.ReadTXT(path, full);
	if text ~= nil then
		local list = GameUlt.Split(text, "\n");
		for i=2, #list do
			local item = GameUlt.Split(list[i], "\t");
			if item[1] ~= nil and item[2] ~= nil then
				local type_, _ = string.gsub(item[2], "\r", "");
				result[item[1]] = type_;
			end
		end
	end
	return result;
end

function CustomRomoteStorage:GetOrgRSThingType()  --获取乾坤界原有的物品表格
	self.org_RSThingType = self:GetRSThingType(self.path, false);
end

function CustomRomoteStorage:GetModRSThingType()  --获取其他mod中的乾坤界物品表格
	local result = {};
	for _, mod in pairs(CS.ModsMgr.Instance.Mods) do
		local path = mod.Path.."/"..self.path
		for k, v in pairs(self:GetRSThingType(path, true)) do
			result[k] = v;
		end
	end
	self.mod_RSThingType = result;
end

function CustomRomoteStorage:UpdateAllItem(all_item_data)  --更新所有物品的设置数据
	local temp = {};
	local item_data = {};
	for _, data in pairs(all_item_data) do
		self.all_item_data[data.name].added = data.added;
		self.all_item_data[data.name].itemType = data.itemType;
	end
	self:ResetRemoteItemType();
end

function CustomRomoteStorage:ResetRemoteItemType()  --重设乾坤界物品列表
	local SpaceRing = CS.XiaWorld.World.Instance.map.SpaceRing;
	local RemoteItemType = CS.XiaWorld.ThingMgr.RemoteItemType;
	RemoteItemType:Clear();
	for name, data in pairs(self.all_item_data) do
		if data.added then
			RemoteItemType:Add(name, data.itemType);
		else
			local count = SpaceRing:GetItemCount(name);
			if count > 0 then
				SpaceRing:TakeOut(name, count, 0);
			end
		end
	end
end

function CustomRomoteStorage:CheckModLegal()
	local mod_name = "CustomRomoteStorage";
	local mod_display_name = "自定义乾坤界";
	for _, mod in pairs(CS.ModsMgr.Instance.AllMods) do
		if (mod.IsActive and mod.Name == mod_name and mod.Author == "枫轩" and (mod.ID == "2112209838" or mod.ID == "2199817102947280319")) then
			return true;
		end
	end
	print(string.format("The mod: '%s' is illegal", mod_display_name));
	return false
end

function CustomRomoteStorage:OnLeave()
	print("CustomRomoteStorage Leave");
end

function CustomRomoteStorage:OnSave()--系统会将返回的table存档 table应该是纯粹的KV
	local save_data = {
		all_item_data = self.all_item_data,
	}
	return save_data;
end

function CustomRomoteStorage:OnLoad(tbLoad)--读档时会将存档的table回调到这里
	SaveData = tbLoad or {};
end

local g_emItemLable = CS.XiaWorld.g_emItemLable;

CustomRomoteStorage.itemTypeList = {"材料", "食物", "药物", "布革", "其他", "灵丹"};

CustomRomoteStorage.itemType = {
	[g_emItemLable.Bone] = "材料",
	[g_emItemLable.Dan] = "灵丹",
	[g_emItemLable.Drug] = "药物",
	[g_emItemLable.Food] = "食物",
	[g_emItemLable.SoulCrystal] = "其他",
	[g_emItemLable.SpellPaper] = "其他",
	[g_emItemLable.Ingredient] = "食物",
	[g_emItemLable.LeftoverMaterial] = "材料",
	[g_emItemLable.Meat] = "食物",
	[g_emItemLable.MetalBlock] = "材料",
	[g_emItemLable.RockBlock] = "材料",
	[g_emItemLable.WoodBlock] = "材料",
	[g_emItemLable.Cloth] = "布革",
	[g_emItemLable.Leather] = "布革",
	[g_emItemLable.Metal] = "材料",
	[g_emItemLable.Plant] = "材料",
	[g_emItemLable.PlantProduct] = "材料",
	[g_emItemLable.Rock] = "材料",
	[g_emItemLable.Wood] = "材料",
	[g_emItemLable.LingStone] = "其他",
};

CustomRomoteStorage.banLable = {
	[g_emItemLable.Spell] = "符咒",
	[g_emItemLable.Tool] = "工具",
	[g_emItemLable.Treasure] = "宝物",
	[g_emItemLable.Clothes] = "衣服",
	[g_emItemLable.FightFabao] = "法宝",
	[g_emItemLable.TreasureFabao] = "法宝",
	[g_emItemLable.Hat] = "帽子",
	[g_emItemLable.Trousers] = "裤子",
	[g_emItemLable.Weapon] = "武器",
	[g_emItemLable.Esoterica] = "秘籍",
	[g_emItemLable.Garbage] = "垃圾",
	[g_emItemLable.Influence] = "未知",
	[g_emItemLable.Other] = "其他",
	[g_emItemLable.None] = "未知",
	[g_emItemLable.SPStuffCategories] = "未知",
};

--[[
Thing:IsSleeveSpace()
CS.XiaWorld.ThingMgr.Instance:GetDef
CS.XiaWorld.World.Instance.map.SpaceRing:GetItemCount
CS.XiaWorld.World.Instance.map.SpaceRing:TakeOut
]]--

