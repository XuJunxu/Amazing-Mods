local AutoCloseWindow = GameMain:NewMod("AutoCloseWindow");--先注册一个新的MOD模块

function AutoCloseWindow:OnInit()
	self.auto_close_list = {};
	self.mod_enable = true;
	--print("AutoCloseWindow Init");
end

function AutoCloseWindow:OnEnter()
	--print("AutoCloseWindow Enter");
	self:GetAutoCloseList();
	local Event = GameMain:GetMod("_Event");
	local g_emEvent = CS.XiaWorld.g_emEvent;
	Event:RegisterEvent(g_emEvent.WindowEvent, function(evt, thing, objs) 
		self:WindowCheckAndClose(evt, thing, objs); 
	end, "WindowCheckAndClose");
end

function AutoCloseWindow:WindowCheckAndClose(evt, thing, objs)
	local window = objs[0];			
	if window ~= nil and window.isShowing and (window:GetType() == typeof(CS.Wnd_Message) or window:GetType() == typeof(CS.Wnd_StorySelect)) and 
		window.contentPane ~= nil and window.contentPane.m_frame ~= nil and window.contentPane.m_frame.title ~= nil then	
		local pane = window.contentPane;
		local title = pane.m_frame.title;
		local text = "";
		if self.auto_close_list[title] ~= nil then
			local config = self.message_config[self.auto_close_list[title]];
			if config.WndType == "MsgBox" and window:GetType() == typeof(CS.Wnd_Message) then  --屏蔽弹窗
				text = pane.m_text.text;						
				if config.Content ~= nil then
					local flag = true;
					for _, cont in pairs(config.Content) do
						local a, b = string.find(text, cont);
						if a ~= nil then
							flag = false;
							break;
						end
					end
					if flag then
						return;
					end
				end
				if pane.m_Btn.selectedIndex == 1 then
					pane.m_n27.onClick:Call();
				elseif pane.m_Btn.selectedIndex == 2 then
					pane.m_n30.onClick:Call();
				end			
			elseif config.WndType == "StoryBox" and window:GetType() == typeof(CS.Wnd_StorySelect) then
				text = pane.m_desc.text;
				local index = -1;
				if config.SelectIndex == nil or config.SelectIndex < 1 then
					if pane.m_selection.numItems < 2 then
						index = 0;
					end
				else
					if pane.m_selection.numItems >= config.SelectIndex then
						index = config.SelectIndex - 1;
						--print(index);
					end
				end
				if index >= 0 then
					pane.m_selection.onClickItem:Call(pane.m_selection:GetChildAt(index));
					if window.isShowing and pane.m_selection.numItems < 2 then
						text = pane.m_desc.text;
						pane.m_selection.onClickItem:Call(pane.m_selection:GetChildAt(0));
					end
				end
			end
			if config.LeftMsg and text ~= nil and text ~= "" then  --左侧显示消息
				local msg_id = config.MsgID;
				if config.Refresh then
					CS.XiaWorld.MessageMgr.Instance:RemoveMessageByOther(msg_id, msg_id);
				end
				local i, j = string.find(text, "%s+");
				if i == 1 and j ~= nil then
					text = string.sub(text, j+1, -1);
				end
				CS.XiaWorld.MessageMgr.Instance:AddMessage(msg_id, nil, text, -1, 0, msg_id, nil);
			end	
		end
	end
end

function AutoCloseWindow:GetAutoCloseList()
	self.auto_close_list = {};
	for mtype, config in pairs(self.message_config) do
		if config.AutoClose then
			for _, title in pairs(config.WndTitle) do
				self.auto_close_list[title] = mtype;
			end
		end
	end
end

function AutoCloseWindow:OnSetHotKey()
	local tbHotKey = { {ID = "AutoCloseConfig" , Name = "设置屏蔽弹窗" , Type = "Mod", InitialKey1 = "RightControl+I" }};
	return tbHotKey;
end

function AutoCloseWindow:OnHotKey(ID, state)
	if not self.mod_enable then
		return;
	end
	if ID == "AutoCloseConfig" and state == "down" then
		GameMain:GetMod("Windows"):GetWindow("AutoCloseConfigWindow"):Open();
	end
end

function AutoCloseWindow:OnSave()  --系统会将返回的table存档 table应该是纯粹的KV
	local save_data = {}
	for mtype, config in pairs(self.message_config) do
		save_data[mtype] = config.AutoClose;
	end
	return save_data;
end

function AutoCloseWindow:OnLoad(tbLoad)  --读档时会将存档的table回调到这里
	tbLoad = tbLoad or {};
	for mtype, config in pairs(self.message_config) do
		if tbLoad[mtype] ~= nil then
			config.AutoClose = tbLoad[mtype];
		end
	end
end

function AutoCloseWindow:CheckModLegal()
	return true;
end

AutoCloseWindow.message_config = {
	Aa_LearnEsoterica = {MsgType = "习得秘籍", MsgID = 5751, LeftMsg = true, AutoClose = true, Refresh = false, WndType = "MsgBox",
						Tooltips = "所有方式在习得秘籍时的消息弹窗",
						WndTitle = {"秘籍"}},  --ShowMsgBox
	Ab_SkillUpgrade = {MsgType = "需确定的消息", MsgID = 5752, LeftMsg = true, AutoClose = false, Refresh = true, WndType = "MsgBox",
						Tooltips = "提高技能等级、领取各地仓库储存时的确认弹窗",
						WndTitle = {"消息"}, 
						Content = {"参悟值提高.+等级", "确认领取仓库所有储存"}},
	Ac_MagicMapStory = {MsgType = "大衍神算", MsgID = 5761, LeftMsg = true, AutoClose = true, Refresh = true, WndType = "StoryBox",
						Tooltips = "大衍神算成功或失败时的消息弹窗",
						WndTitle = {"大衍神算"}},  --ShowStoryBox	
	Ad_EventItemDrop = {MsgType = "宝物事件", MsgID = 5762, LeftMsg = false, AutoClose = false, Refresh = false, WndType = "StoryBox",
						Tooltips = "宝物坠落时的消息弹窗",
						WndTitle = {"宝物"}},
	Ae_EventSecret = {MsgType = "秘闻事件", MsgID = 5763, LeftMsg = true, AutoClose = false, Refresh = false, WndType = "StoryBox", 
						Tooltips = "秘闻事件出现或消失时的消息弹窗，包括法宝出土、洞府现世、古书踪迹、秘籍出土、神通现世、邪派行踪、正派行踪、道统现世",
						WndTitle = {"法宝出土", "洞府现世", "古书踪迹", "秘籍出土", "神通现世", "邪派行踪", "正派行踪", "道统现世",}},
	Af_LingWu = {MsgType = "领悟事件", MsgID = 5764, LeftMsg = true, AutoClose = false, Refresh = false, WndType = "StoryBox", 
					Tooltips = "领悟事件的消息弹窗，包括灵光一闪、发现符咒、领悟秘籍、突破感悟、炼丹感悟、炼器感悟",
					WndTitle = {"领悟", "发现", "感悟", "炼丹感悟", "炼器感悟", }},					
	Ag_Weather = {MsgType = "普通天气事件", MsgID = 5765, LeftMsg = true, AutoClose = false, Refresh = false, WndType = "StoryBox", 
					Tooltips = "普通天气事件来临时的消息弹窗，包括晴天、阴天、小雨、大雨、大雾、冰雹、小雪、大雪",
					WndTitle = {"晴天", "阴天", "小雨", "大雨", "大雾", "冰雹", "小雪", "大雪", }}, --EventList.xml	
	Ah_WeatherHigh = {MsgType = "高级天气事件", MsgID = 5766, LeftMsg = true, AutoClose = false, Refresh = true, WndType = "StoryBox", 
						Tooltips = "高级天气事件来临时的消息弹窗，包括愁绪弥漫、暧昧的气息、浮躁之风、暴雨、焚风、尘暴、灵气枯潮、瘟气、雷暴、灵气爆发",
						WndTitle = {"愁绪弥漫", "暧昧的气息", "浮躁之风", "暴雨", "焚风", "尘暴", "灵气枯潮", "瘟气", "雷暴", "灵气爆发",}},
	Ai_WeatherLong = {MsgType = "高强度天气事件", MsgID = 5767, LeftMsg = true, AutoClose = false, Refresh = true, WndType = "StoryBox", 
						Tooltips = "高强度天气事件来临时的消息弹窗，包括梅雨、干旱、酷暑、凛冬、永夜、暖流、凉风、丰收的气息、春天的气息",
						WndTitle = {"梅雨", "干旱", "酷暑", "凛冬", "永夜", "暖流", "凉风", "丰收的气息", "春天的气息", }},	
	Aj_EventWalker = {MsgType = "路人事件", MsgID = 5768, LeftMsg = true, AutoClose = false, Refresh = false, WndType = "StoryBox", 
						Tooltips = "路人事件的消息弹窗，包括难民路过、迷路的路人、好奇的路人、受伤的路人",
						WndTitle = {"难民路过", "迷路的路人", "好奇的路人", "受伤的路人", }},	
	Az_EventOther = {MsgType = "其他事件消息", MsgID = 5769, LeftMsg = true, AutoClose = false, Refresh = false, WndType = "StoryBox", 
						Tooltips = "其他事件消息的消息弹窗，包括时代开启、观察者",
						WndTitle = {"时代开启", "观察者", }},		
	Ak_EventLingZhi = {MsgType = "灵植事件", MsgID = 5770, LeftMsg = true, AutoClose = false, Refresh = false, WndType = "StoryBox", 
						Tooltips = "灵植事件的消息弹窗，包括灵性偶发",
						WndTitle = {"灵性偶发", }},
	Al_EventOutspread = {MsgType = "势力事件", MsgID = 5771, LeftMsg = true, AutoClose = false, Refresh = false, WndType = "StoryBox", 
						Tooltips = "势力事件的消息弹窗，包括劳作事件、寻珍事件、布施事件、特殊事件、传道事件、密谋事件、受戒事件、神迹事件、收集天道事件",
						WndTitle = {"劳作事件", "寻珍事件", "布施事件", "特殊事件", "传道事件", "密谋事件", "受戒事件", "神迹事件", "收集天道事件"}},		
	Am_EventMapStory1 = {MsgType = "历练事件1", MsgID = 5772, LeftMsg = true, AutoClose = false, Refresh = false, WndType = "StoryBox", 
						Tooltips = "历练事件的消息弹窗，包括收集资源",
						WndTitle = {"收集资源",}},
	An_EventMapStory2 = {MsgType = "历练事件2", MsgID = 5773, LeftMsg = true, AutoClose = false, Refresh = false, WndType = "StoryBox", 
						Tooltips = "历练事件的消息弹窗，包括寻觅宝物",
						WndTitle = {"寻觅宝物",},
						SelectIndex = 1, },
}

