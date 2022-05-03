local CustomRomoteStorage = GameMain:NewMod("CustomRomoteStorage");--先注册一个新的MOD模块

function Global_GetLanguageString(tb_str)
	return function(str)
		if tb_str ~= nil and CS.TFMgr.Instance.Language == "OfficialEnglish" then
			return tb_str[str] or str;
		end
		return str;
	end;
end
local LanStr = {
	["材料"] = "Material",
	["食物"] = "Food",
	["药物"] = "Medicine",
	["布革"] = "Fabric",
	["灵丹"] = "Pill",
	["其他"] = "Misc",
	["符咒"] = "Talisman",
	["工具"] = "Tool",
	["宝物"] = "Treasure",
	["奇物"] = "Fortuitous Treasure",
	["衣服"] = "Coat",
	["法宝"] = "Artifact",
	["帽子"] = "Hat",
	["裤子"] = "Pants",
	["武器"] = "Weapon",
	["秘籍"] = "Manual",
	["垃圾"] = "Rubbish",
	["未知"] = "Unknown",
	["常用"] = "Common",
	["自定义"] = "Custom",
	["(原有) "] = "(ORG) ",
	["(模组) "] = "(MOD) ",
	["[color=#FF0000]乾坤界原有物品，可以修改分类，不可移除[/color]\n\n"] = "[color=#FF0000]It is the original item of the Mini Universe. You can modify its classification but not remove it.[/color]\n\n",
	["[color=#FF0000]被其他模组添加进乾坤界，可以修改分类，不可移除[/color]\n\n"] = "[color=#FF0000]It was added to the Mini Universe by other mods. You can modify its classification but not remove it.[/color]\n\n",
};
local GLS = Global_GetLanguageString(LanStr);

local SaveData = {};

function CustomRomoteStorage:OnInit()
	self.all_item_data = SaveData.all_item_data or {};
	self.common_items = SaveData.common_items or {};
	self.mod_enable = true;
	self.last_selected = nil;
	self.path = "Settings/ThingDef/RSThingType";
	self.org_RSThingType = {};
	self.mod_RSThingType = {};
	self.itemTypeTable = {};
	self.all_item_list = {};
	for _, type_ in pairs(self.itemTypeList) do
		self.itemTypeTable[type_] = type_;
	end
	--print("CustomRomoteStorage OnInit");
end

function CustomRomoteStorage:OnEnter()
	if not self:CheckModLegal() or CS.XiaWorld.World.Instance.GameMode == CS.XiaWorld.g_emGameMode.Fight then
		self.mod_enable = false;
		return;
	end	
	xlua.private_accessible(CS.Wnd_RemoteStorage);
	local Windows = GameMain:GetMod("Windows");
	self.StorageConfigWindow = Windows:GetWindow("CustomRomoteStorage_StorageConfigWindow");
	self.StorageConfigWindow:Init();
	local Event = GameMain:GetMod("_Event");
	local g_emEvent = CS.XiaWorld.g_emEvent;
	Event:RegisterEvent(g_emEvent.SelectBuilding, function(evt, build, objs) 
		self:AddBtn2Build(evt, build, objs); 
	end, "CustomRomoteStorage_AddBtn2Build");
	Event:RegisterEvent(g_emEvent.WindowEvent, function(evt, thing, objs) 
		self:RightClickItem(evt, thing, objs); 
	end, "CustomRomoteStorage_RightClickItem");
	Event:RegisterEvent(g_emEvent.WindowEvent, function(evt, thing, objs) 
		self:AddCommonClass(evt, thing, objs); 
	end, "CustomRomoteStorage_AddCommonClass");	
	self.SRC_RemoteItemType = {};
	for name, type_ in pairs(CS.XiaWorld.ThingMgr.RemoteItemType) do
		self.SRC_RemoteItemType[name] = type_;
	end
	self:GetOrgRSThingType();
	self:GetModRSThingType();
	self:GetAllItemData();
	self:ResetRemoteItemType();
	--self:OpenConfigWindow();
	print("CustomRomoteStorage V2.00");
end

function CustomRomoteStorage:AddBtn2Build(evt, thing, objs)  --向添加按键
	if thing == nil or thing == self.last_selected or not self.mod_enable then
		return;
	end
	self.last_selected = thing;
	thing:RemoveBtnData(GLS("自定义"));
	if thing.BuildingState == CS.XiaWorld.g_emBuildingState.Working and thing:IsSleeveSpace() then
		thing:AddBtnData(GLS("自定义"), "res/Sprs/ui/icon_huafu01", "GameMain:GetMod('CustomRomoteStorage'):OpenConfigWindow();", "");
	end
end

function CustomRomoteStorage:RightClickItem(evt, thing, objs)  --乾坤界添加右键点击回调
	local Event = GameMain:GetMod("_Event");
	if not self.mod_enable then
		Event:UnRegisterEvent(g_emEvent.WindowEvent, "CustomRomoteStorage_RightClickItem");
		return;
	end
	local window = objs[0];  --CS.Wnd_RemoteStorage.Instance
	if window ~= nil and window:GetType() == typeof(CS.Wnd_RemoteStorage) and window.contentPane ~= nil and window.contentPane.m_n5 ~= nil then
		window.contentPane.m_n5.onRightClickItem:Add(CustomRomoteStorage_AddCommonItem);
		Event:UnRegisterEvent(g_emEvent.WindowEvent, "CustomRomoteStorage_RightClickItem");
	end
end

function CustomRomoteStorage:AddCommonClass(evt, thing, objs)
	if not self.mod_enable then
		return;
	end
	local window = objs[0];  --CS.Wnd_RemoteStorage.Instance
	if window ~= nil and window:GetType() == typeof(CS.Wnd_RemoteStorage) and window.isShowing then
		self:UpdateRSCommonItems();
		CS.Wnd_RemoteStorage.Instance:ShowStorageType(nil);
	end
end

function CustomRomoteStorage_AddCommonItem(context)
	if not CS.UnityEngine.Input.GetKey(CS.UnityEngine.KeyCode.LeftShift) then
		return;
	end
	local item_name = context.data.data;
	CustomRomoteStorage:UpdateCommonItems(item_name);
end

function CustomRomoteStorage:UpdateCommonItems(item_name)
	if self.common_items[item_name] ~= nil then
		self.common_items[item_name] = nil;
	else
		self.common_items[item_name] = item_name;
	end
	self:UpdateRSCommonItems();
end

function CustomRomoteStorage:UpdateRSCommonItems()
	local re, item_list = CS.Wnd_RemoteStorage.Instance.kvs:TryGetValue(GLS("常用"));
	if not re then
		local List_String = CS.System.Collections.Generic.List(CS.System.String);
		item_list = List_String();
		CS.Wnd_RemoteStorage.Instance.kvs:Add(GLS("常用"), item_list);
	end
	item_list:Clear();
	for _, name in pairs(self.all_item_list) do
		if self.common_items[name] ~= nil then
			item_list:Add(name);
		end
	end
	if CS.Wnd_RemoteStorage.Instance._ShowType == GLS("常用") then
		CS.Wnd_RemoteStorage.Instance:ShowType(GLS("常用"));
	end
end

function CustomRomoteStorage:CheckCommonItems()
	for _, name in pairs(self.common_items) do
		if self.all_item_data[name] == nil or not self.all_item_data[name].added then
			self.common_items[name] = nil;
		end
	end
end

function CustomRomoteStorage:OpenConfigWindow()
	local show_data = {};
	local show_list_data = {};
	local temp = {};
	for name, data in pairs(self.all_item_data) do
		local def = CS.XiaWorld.ThingMgr.Instance:GetDef(CS.XiaWorld.g_emThingType.Item, name);
		local thing_name = def.ThingName or name;
		show_data[name] = {
			name = name, 
			dspName = thing_name, 
			itemType = data.itemType,
			added = data.added,
			canChange = true,
			tooltips = string.format("[color=#4169E1]%s[/color]\n\n%s", thing_name, def.Desc),
			common = false,
		};
		if self.common_items[name] ~= nil then
			show_data[name].common = true;
		end
	end
	for _, item in pairs(self.org_RSThingType) do
		local name = item[1];
		if temp[name] == nil and show_data[name] ~= nil then
			show_data[name].dspName = GLS("(原有) ")..show_data[name].dspName;
			show_data[name].canChange = false;
			show_data[name].tooltips = GLS("[color=#FF0000]乾坤界原有物品，可以修改分类，不可移除[/color]\n\n")..show_data[name].tooltips;
			table.insert(show_list_data, show_data[name]);
			temp[name] = name;
		end
	end
	for _, item in pairs(self.mod_RSThingType) do
		local name = item[1];
		if temp[name] == nil and show_data[name] ~= nil then
			show_data[name].dspName = GLS("(模组) ")..show_data[name].dspName;
			show_data[name].canChange = false;
			show_data[name].tooltips = GLS("[color=#FF0000]被其他模组添加进乾坤界，可以修改分类，不可移除[/color]\n\n")..show_data[name].tooltips;
			table.insert(show_list_data, show_data[name]);
			temp[name] = name;
		end
	end
	for _, name in pairs(self.all_item_list) do
		local data = show_data[name];
		if temp[name] == nil then
			table.insert(show_list_data, data);
			temp[name] = name;
		end
	end
	self.StorageConfigWindow:Open(show_list_data);
end

function CustomRomoteStorage:GetItemType(name)
	local item_type = GLS("其他");
	local def = CS.XiaWorld.ThingMgr.Instance:GetDef(CS.XiaWorld.g_emThingType.Item, name);
	if def ~= nil and def.Item ~= nil and def.Item.Lable ~= nil and self.itemType[def.Item.Lable] ~= nil then
		item_type = self.itemType[def.Item.Lable];
	end
	return item_type;
end

function CustomRomoteStorage:CheckItemType(item_type)
	if self.itemTypeTable[item_type] == nil then
		return false;
	else
		return true;
	end
end

function CustomRomoteStorage:GetAllItemData()  --获取所有可以自行设置的物品，会过滤没有Def的物品
	local ThingMgr = CS.XiaWorld.ThingMgr;
	local thingType = CS.XiaWorld.g_emThingType.Item;
	local all_item_data = {};
	self.all_item_list = {};
	for _, item in pairs(self.org_RSThingType) do
		local name = item[1];
		if all_item_data[name] == nil and ThingMgr.Instance:GetDef(thingType, name, false) ~= nil then
			local item_data = nil;
			if self.all_item_data[name] ~= nil then
				item_data = {added = true, itemType = self.all_item_data[name].itemType}; 
			else
				item_data = {added = true, itemType = self:GetItemType(name)};
			end
			all_item_data[name] = item_data;
			table.insert(self.all_item_list, name);
		end
	end
	for _, item in pairs(self.mod_RSThingType) do
		local name = item[1];
		if all_item_data[name] == nil and ThingMgr.Instance:GetDef(thingType, name, false) ~= nil then	
			local item_data = nil;
			if self.all_item_data[name] ~= nil then
				item_data = {added = true, itemType = self.all_item_data[name].itemType}; 
			else
				item_data = {added = true, itemType = self:GetItemType(name)};
			end
			all_item_data[name] = item_data;
			table.insert(self.all_item_list, name);
		end
	end	
	for _, name in pairs(ThingMgr.s_AllItemNames) do
		if all_item_data[name] == nil then
			local def = ThingMgr.Instance:GetDef(thingType, name, false);
			local n, m = string.find(name, "Base", -4);
			if def ~= nil and def.Item ~= nil and def.Item.Lable ~= nil and self.banLable[def.Item.Lable] == nil and n == nil then
				local item_data = nil;
				if self.all_item_data[name] ~= nil then
					item_data = self.all_item_data[name];
				else
					item_data = {added = false, itemType = self:GetItemType(name)};
				end
				all_item_data[name] = item_data;
				table.insert(self.all_item_list, name);
			end
		end
	end
	xlua.private_accessible(CS.XiaWorld.RemoteStorage);
	for name, count in pairs(CS.XiaWorld.World.Instance.map.SpaceRing.Storage) do
		local def = ThingMgr.Instance:GetDef(thingType, name, false);
		if count > 0 and def ~= nil then
			if all_item_data[name] == nil then
				local item_data = nil;
				if self.all_item_data[name] ~= nil then
					item_data = {added = true, itemType = self.all_item_data[name].itemType};
				else
					item_data = {added = true, itemType = self:GetItemType(name)};
				end
				all_item_data[name] = item_data;
				table.insert(self.all_item_list, name);
			else
				all_item_data[name].added = true;
			end
		end
	end
	for name, data in pairs(all_item_data) do
		if not self:CheckItemType(data.itemType) then
			data.itemType = self:GetItemType(name);
		end
	end
	self.all_item_data = all_item_data;
end

function CustomRomoteStorage:GetRSThingType(path, func)  --获取乾坤界物品表格
	if not CS.System.IO.Directory.Exists(path) then
		return;
	end
	local files = CS.System.IO.Directory.GetFiles(path, "*.txt", CS.System.IO.SearchOption.AllDirectories);
	for i=0, files.Length-1 do
		local file_path, _ = string.gsub(files[i], "\\", "/");
		local text = CS.GFileUtil.ReadTXT(file_path, true);
		if text ~= nil then
			local list = GameUlt.Split(text, "\n");
			for i=2, #list do
				local item = GameUlt.Split(list[i], "\t");
				if #item == 2 and item[1] ~= nil and item[2] ~= nil then
					local type_, _ = string.gsub(item[2], "\r", "");
					func(item[1], type_);
				end
			end
		end
	end
end

function CustomRomoteStorage:GetOrgRSThingType()  --获取乾坤界原有的物品表格
	self.org_RSThingType = {};
	local local_path = CS.GFileUtil.LocateFile(self.path);
	self:GetRSThingType(local_path, function(item_name, item_type)
		table.insert(self.org_RSThingType, {item_name, item_type});
		--self.org_RSThingType[item_name] = item_type;
	end);
end

function CustomRomoteStorage:GetModRSThingType()  --获取其他mod中的乾坤界物品表格
	self.mod_RSThingType = {};
	for _, mod in pairs(CS.ModsMgr.Instance.Mods) do
		local path = mod.Path.."/"..self.path;
		self:GetRSThingType(path, function(item_name, item_type)
			table.insert(self.mod_RSThingType, {item_name, item_type});
			--self.mod_RSThingType[item_name] = item_type;
		end);
	end
end

function CustomRomoteStorage:UpdateAllItem(all_item_data)  --更新所有物品的设置数据
	local temp = {};
	local item_data = {};
	self.common_items = {};
	for _, data in pairs(all_item_data) do
		self.all_item_data[data.name].added = data.added;
		self.all_item_data[data.name].itemType = data.itemType;
		if data.common then
			self.common_items[data.name] = data.name;
		end
	end
	self:ResetRemoteItemType();
end

function CustomRomoteStorage:ResetRemoteItemType()  --重设乾坤界物品列表
	local SpaceRing = CS.XiaWorld.World.Instance.map.SpaceRing;
	local RemoteItemType = CS.XiaWorld.ThingMgr.RemoteItemType;
	RemoteItemType:Clear();
	for _, name in pairs(self.all_item_list) do
		local data = self.all_item_data[name];
		if data.added then
			RemoteItemType:Add(name, data.itemType);
		else
			local count = SpaceRing:GetItemCount(name);
			if count > 0 then
				SpaceRing:TakeOut(name, count, 0);
			end
		end
	end
	self:CheckCommonItems();
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
	self.StorageConfigWindow:RemoveCallback()
	print("CustomRomoteStorage Leave");
end

function CustomRomoteStorage:OnSave()--系统会将返回的table存档 table应该是纯粹的KV
	local save_data = {
		all_item_data = self.all_item_data,
		common_items = self.common_items,
	}
	return save_data;
end

function CustomRomoteStorage:OnLoad(tbLoad)--读档时会将存档的table回调到这里
	SaveData = tbLoad or {};
end

local g_emItemLable = CS.XiaWorld.g_emItemLable;

CustomRomoteStorage.itemTypeList = {GLS("材料"), GLS("食物"), GLS("药物"), GLS("布革"), GLS("灵丹"), GLS("其他")};

CustomRomoteStorage.itemType = {
	[g_emItemLable.Bone] = GLS("材料"),
	[g_emItemLable.Dan] = GLS("灵丹"),
	[g_emItemLable.Drug] = GLS("药物"),
	[g_emItemLable.Food] = GLS("食物"),
	[g_emItemLable.SoulCrystal] = GLS("其他"),
	[g_emItemLable.SpellPaper] = GLS("其他"),
	[g_emItemLable.Ingredient] = GLS("食物"),
	[g_emItemLable.LeftoverMaterial] = GLS("材料"),
	[g_emItemLable.Meat] = GLS("食物"),
	[g_emItemLable.MetalBlock] = GLS("材料"),
	[g_emItemLable.RockBlock] = GLS("材料"),
	[g_emItemLable.WoodBlock] = GLS("材料"),
	[g_emItemLable.Cloth] = GLS("布革"),
	[g_emItemLable.Leather] = GLS("布革"),
	[g_emItemLable.Metal] = GLS("材料"),
	[g_emItemLable.Plant] = GLS("材料"),
	[g_emItemLable.PlantProduct] = GLS("材料"),
	[g_emItemLable.Rock] = GLS("材料"),
	[g_emItemLable.Wood] = GLS("材料"),
	[g_emItemLable.LingStone] = GLS("其他"),
	[g_emItemLable.BambooBlock] = GLS("材料"),
};

CustomRomoteStorage.banLable = {
	[g_emItemLable.Spell] = GLS("符咒"),
	[g_emItemLable.Tool] = GLS("工具"),
	[g_emItemLable.Treasure] = GLS("宝物"),
	[g_emItemLable.Clothes] = GLS("衣服"),
	[g_emItemLable.FightFabao] = GLS("法宝"),
	[g_emItemLable.TreasureFabao] = GLS("法宝"),
	[g_emItemLable.Hat] = GLS("帽子"),
	[g_emItemLable.Trousers] = GLS("裤子"),
	[g_emItemLable.Weapon] = GLS("武器"),
	[g_emItemLable.Esoterica] = GLS("秘籍"),
	[g_emItemLable.Garbage] = GLS("垃圾"),
	[g_emItemLable.Influence] = GLS("未知"),
	[g_emItemLable.Other] = GLS("其他"),
	[g_emItemLable.None] = GLS("未知"),
	[g_emItemLable.SPStuffCategories] = GLS("未知"),
};

--[[
Thing:IsSleeveSpace()
CS.XiaWorld.ThingMgr.Instance:GetDef
CS.XiaWorld.World.Instance.map.SpaceRing:GetItemCount
CS.XiaWorld.World.Instance.map.SpaceRing:TakeOut
]]--

