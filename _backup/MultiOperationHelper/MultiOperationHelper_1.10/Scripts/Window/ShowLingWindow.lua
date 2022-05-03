local Windows = GameMain:GetMod("Windows");
local ShowLingWindow = Windows:CreateWindow("ShowLingWindow");
local MultiOperationHelper = GameMain:GetMod("MultiOperationHelper");

function ShowLingWindow:OnInit()	
	self.window.contentPane = UIPackage.CreateObject("MultiOperationHelper", "ShowLingWindow");
	self.label = self:GetChild("label");
	self.last_key = 0;
	self.last_thing = nil
	self.window:RightBottom();
	self.window.x = self.window.x - 200;
end

function ShowLingWindow:OnUpdate(dt)
	local thing = world:GetSelectThing();
	if thing ~= self.last_thing then
		self.last_thing = thing;
		self:AddBtn2Item(thing);
		self:AddBtn2Npc(thing);
	end
	local gridkey = CS.UI_WorldLayer.Instance.MouseGridKey;
	if gridkey ~= nil and gridkey ~= self.last_key and GridMgr:KeyVaild(gridkey) then
		self.last_key = gridkey;
		self.label.text = "灵气浓度："..string.format("%.2f", Map:GetLing(gridkey));
	end
end

function ShowLingWindow:AddBtn2Item(thing)
	if thing ~= nil and thing.ThingType == g_emThingType.Item then 
		if thing.def.Item.Lable == g_emItemLable.SpellPaper then
			thing:RemoveBtnData("批量画符");
			thing:AddBtnData("批量画符", "res/Sprs/ui/icon_huafu01", "GameMain:GetMod('MultiOperationHelper'):MultiFuPainter(bind)", "使用同品阶同类型的符纸，进行批量画符。", nil);
		end
		if thing:EatAble() then
			thing:RemoveBtnData("多人食用");
			thing:AddBtnData("多人食用", "res/Sprs/ui/icon_shiyong01", "GameMain:GetMod('MultiOperationHelper'):MultiEatItem(bind)", "选择多人，食用同品阶同名称的物品。", nil);			
		end 
		if thing.def.Item.Lable ~= g_emItemLable.Esoterica and thing.def.Item.Lable ~= g_emItemLable.FightFabao and thing.def.Item.Lable ~= g_emItemLable.TreasureFabao and (not thing.IsMiBao) then
			thing:RemoveBtnData("多人装备");
			thing:AddBtnData("多人装备", "res/Sprs/ui/icon_zhuangbeidaoju01", "GameMain:GetMod('MultiOperationHelper'):MultiEquiptItem(bind)", "选择多人，装备同品阶同材料的物品。", nil);	
		end
	end
end

function ShowLingWindow:AddBtn2Npc(npc)
	if npc ~= nil and npc.ThingType == g_emThingType.Npc then
		npc:RemoveBtnData("神通");
		MultiOperationHelper:InterruptGetFun(npc);
		if MagicBtnWindow.window.isShowing then
			GRoot.inst:HidePopup(MagicBtnWindow.window.contentPane);
		end
		if npc.IsPlayerThing and npc.Rank == g_emNpcRank.Disciple and (not npc.IsVistor) and (not npc.IsGod) and npc.PropertyMgr.Practice.Magics.Count > 0 then  --参考Panel_ThingInfo.UpdateBnts()
			for _, magic in pairs(MagicBtnWindow.magic_name_list) do
				if npc.PropertyMgr.Practice.Magics:Contains(magic) then
					npc:AddBtnData("神通", "res/Sprs/ui/icon_sousuo01", "GameMain:GetMod('MultiOperationHelper'):ShowMagicBtns(bind)", "批量施展神通。", nil);
					return;
				end
			end	
		end
	end
end
