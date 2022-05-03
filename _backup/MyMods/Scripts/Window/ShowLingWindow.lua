local Windows = GameMain:GetMod("Windows");
local ShowLingWindow = Windows:CreateWindow("ShowLingValueWindow");

function ShowLingWindow:OnInit()	
	self.window.contentPane =  UIPackage.CreateObject("MyMods", "ShowLingValueWindow");
	self.label = self:GetChild("label");
	self.lastkey = 0;
	self.window:RightBottom();
	self.window.x = self.window.x - 200;
end

function ShowLingWindow:OnUpdate(dt)
	local gridkey = CS.UI_WorldLayer.Instance.MouseGridKey;	
	if gridkey == self.lastkey or (not GridMgr:KeyVaild(gridkey)) then
		return;
	end
	self.lastkey = gridkey;
	
	local ling = Map:GetLing(gridkey);
	local ling_addion = Map.Effect:GetEffect(gridkey, CS.XiaWorld.g_emMapEffectKind.LingAddion);
	local ling_addion_fact = Map.Effect:GetEffect(gridkey, CS.XiaWorld.g_emMapEffectKind.LingAddion, 0, true);
	local time_fact = 0;
	if ling_addion ~= ling_addion_fact then
		local MapEffectData = Map.Effect:GetEffectData(gridkey, CS.XiaWorld.g_emMapEffectKind.LingAddion);
		time_fact = MapEffectData.creattime + 3000 - TolSecond;
	end
	local time_str = "已达理论值";
	if time_fact ~= 0 then
		if time_fact > 600 then
			time_str = string.format("%.2f天", time_fact / 600);
		else
			time_str = string.format("%.0f秒", time_fact);
		end
	end
	
	local show_str = string.format("灵气浓度：%.2f\n理论聚灵值：%.2f\n实际聚灵值：%.2f\n生效时间：%s", ling, ling_addion, ling_addion_fact, time_str);	
	self.label.title = show_str;
end
