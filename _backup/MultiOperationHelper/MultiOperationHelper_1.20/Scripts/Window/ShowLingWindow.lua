local Windows = GameMain:GetMod("Windows");
local ShowLingWindow = Windows:CreateWindow("ShowLingWindow");
local MultiOperationHelper = GameMain:GetMod("MultiOperationHelper");

function ShowLingWindow:OnInit()	
	self.window.contentPane = UIPackage.CreateObject("MultiOperationHelper", "ShowLingWindow");
	self.label = self:GetChild("label");
	self.last_key = 0;
	self.window:RightBottom();
	self.window.x = self.window.x - 200;
end

function ShowLingWindow:OnUpdate(dt)
	local gridkey = CS.UI_WorldLayer.Instance.MouseGridKey;
	if gridkey ~= nil and gridkey ~= self.last_key and GridMgr:KeyVaild(gridkey) then
		self.last_key = gridkey;
		self.label.text = "灵气浓度："..string.format("%.2f", Map:GetLing(gridkey));
	end
end


