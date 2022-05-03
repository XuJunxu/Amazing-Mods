local MultiChangeWork = GameMain:NewMod("MultiChangeWork");--先注册一个新的MOD模块

function MultiChangeWork:OnInit()
	self.check_table_y = 0;
	self.checkbox_added = false;
	--print("MultiChangeWork Init");
end

function MultiChangeWork:OnEnter()
	--print("MultiChangeWork Enter");
	local Event = GameMain:GetMod("_Event");
	local g_emEvent = CS.XiaWorld.g_emEvent;
	Event:RegisterEvent(g_emEvent.WindowEvent, function(evt, thing, objs) 
		self:AddSelectAllButtons(evt, thing, objs); 
	end, "AddSelectAllButtons");
--[[	Event:RegisterEvent(g_emEvent.WindowEvent, function(evt, thing, objs) 
		self:AddWorkKindCheckbox(evt, thing, objs); 
	end, "AddWorkKindCheckbox");
	Event:RegisterEvent(g_emEvent.WindowEvent, function(evt, thing, objs) 
		self:AddNpcCheckbox(evt, thing, objs); 
	end, "AddNpcCheckbox");]]--
end

function MultiChangeWork:AddSelectAllButtons(evt, thing, objs)
	local window = objs[0];	
	local Wnd_NpcWork = CS.Wnd_NpcWork.Instance;
	if window:GetType() ~= typeof(CS.Wnd_NpcWork) or Wnd_NpcWork == nil or Wnd_NpcWork.UIInfo == nil or not Wnd_NpcWork.isShowing then
		return;
	end
	local check_table = Wnd_NpcWork.UIInfo.m_n15;
	if check_table.numItems > 0 then
		local work_kind_list = Wnd_NpcWork.UIInfo.m_n42;
		if Wnd_NpcWork.UIInfo.m_lang.selectedIndex == 1 then
			work_kind_list = Wnd_NpcWork.UIInfo.m_n23;
		end
		for i=0, work_kind_list.numItems-1 do
			local work_kind = work_kind_list:GetChildAt(i);
			local button = work_kind:GetChild("work");
			if button == nil then
				button = CS.XiaWorld.UI.InGame.UI_Button_icon_text.CreateInstance();
				button.name = "work";
				button:SetSize(work_kind.width, work_kind.height);
				button:SetXY(0, 0);
				work_kind:AddChild(button);
			end
			button.data = i;
			button.onClick:Clear();
			button.onClick:Add(self.ChangeAllNpcOneWork);
		end
		for i=0, check_table.numItems-1 do
			local check_list = check_table:GetChildAt(i);
			local button = check_list:GetChild("npc");
			if button == nil then
				button = CS.XiaWorld.UI.InGame.UI_Button_icon_text.CreateInstance();
				button.name = "npc";
				button:SetSize(check_list.m_n14.width, check_list.m_n14.height);
				button:SetXY(check_list.m_n14.x, check_list.m_n14.y);
				check_list:AddChild(button);
			end
			button.onClick:Clear();
			button.onClick:Add(self.ChangeOneNpcAllWork);			
		end
	end
end

function MultiChangeWork.ChangeAllNpcOneWork(context);
	local button = context.sender;
	local index = button.data;
	local check_table = CS.Wnd_NpcWork.Instance.UIInfo.m_n15;
	local selected = true;
	for i=0, check_table.numItems-1 do
		local check_list = check_table:GetChildAt(i);
		local check_box = check_list.m_n13:GetChildAt(index);
		selected = (selected and check_box.selected);
	end
	selected = (not selected);
	for i=0, check_table.numItems-1 do
		local check_list = check_table:GetChildAt(i);
		local check_box = check_list.m_n13:GetChildAt(index);
		if check_box.selected ~= selected then
			check_box.onClick:Call();
		end
	end
end

function MultiChangeWork.ChangeOneNpcAllWork(context)
	local button = context.sender;
	local check_list = button.parent;
	local npc = check_list.m_n17.data;
	local selected = true;
	for i=0, check_list.m_n13.numItems-1 do
		local check_box = check_list.m_n13:GetChildAt(i);
		selected = (selected and check_box.selected);
	end
	selected = (not selected);
	for i=0, check_list.m_n13.numItems-1 do
		local check_box = check_list.m_n13:GetChildAt(i);
		if check_box.selected ~= selected then
			check_box.onClick:Call();
		end
	end
end



function MultiChangeWork:AddWorkKindCheckbox(evt, thing, objs)
	local window = objs[0];	
	local Wnd_NpcWork = CS.Wnd_NpcWork.Instance;
	if window:GetType() ~= typeof(CS.Wnd_NpcWork) or Wnd_NpcWork == nil or Wnd_NpcWork.UIInfo == nil or not Wnd_NpcWork.isShowing then
		return;
	end
	local check_table = Wnd_NpcWork.UIInfo.m_n15;
	local work_kind_list = Wnd_NpcWork.UIInfo.m_n42;
	if Wnd_NpcWork.UIInfo.m_lang.selectedIndex == 1 then
		work_kind_list = Wnd_NpcWork.UIInfo.m_n23;
	end
	if check_table.numItems > 0 then
		for i=0, work_kind_list.numItems-1 do
			local checkbox = nil;
			local work_kind = work_kind_list:GetChildAt(i);
			if Wnd_NpcWork.UIInfo:GetChild(work_kind.title) == nil then
				checkbox = CS.XiaWorld.UI.InGame.UI_Checkbox.CreateInstance();
				if self.check_table_y == 0 then
					local checkbox_height = checkbox.height;
					local work_kind_y = work_kind_list.y;
					self.check_table_y = check_table.y + checkbox_height;
					check_table.y = self.check_table_y;
					check_table.height = check_table.height - checkbox_height;
					work_kind_list.y = work_kind_y;
				end
				checkbox.name = work_kind.title;
				Wnd_NpcWork.UIInfo:AddChild(checkbox);
				checkbox.onClick:Add(ChangeAllNpcOneWork);
				--self.checkbox_added = true;
			else 
				checkbox = Wnd_NpcWork.UIInfo:GetChild(work_kind.title);
			end
			checkbox:SetXY(3 + work_kind_list.x + work_kind.x * work_kind_list.scaleX, check_table.y - checkbox.height);
			local selected = true;
			for j=0, check_table.numItems-1 do
				local list = check_table:GetChildAt(j);
				local box = list.m_n13:GetChildAt(i);
				selected = selected and box.selected;
			end			
			checkbox.data = i;
			checkbox.selected = selected;
		end	
	end
end

function MultiChangeWork:AddNpcCheckbox(evt, thing, objs)
	local window = objs[0];	
	local Wnd_NpcWork = CS.Wnd_NpcWork.Instance;
	if window:GetType() ~= typeof(CS.Wnd_NpcWork) or Wnd_NpcWork == nil or Wnd_NpcWork.UIInfo == nil or not Wnd_NpcWork.isShowing then
		return;
	end
	local check_table = Wnd_NpcWork.UIInfo.m_n15;
	if check_table.numItems > 0 then
		for i=0, check_table.numItems-1 do
			local checkbox = nil;
			local check_list = check_table:GetChildAt(i);
			if check_list:GetChild("CheckAllWork") == nil then
				checkbox = CS.XiaWorld.UI.InGame.UI_Checkbox.CreateInstance();
				checkbox.name = "CheckAllWork";
				check_list:AddChild(checkbox);
				checkbox:LeftBottom();
				checkbox.onClick:Add(ChangeOneNpcAllWork);				
			else
				checkbox = check_list:GetChild("CheckAllWork");
			end
			local selected = true;
			for j=0, check_list.m_n13.numItems-1 do
				local box = check_list.m_n13:GetChildAt(j);
				selected = selected and box.selected;
			end
			checkbox.data = i;
			checkbox.selected = selected;
		end		
	end
end

function ChangeOneNpcAllWork(context)	
	local checkbox = context.sender;
	local selected = checkbox.selected;
	local check_list = checkbox.parent;
	local npc = check_list.m_n17.data;
	for i=0, check_list.m_n13.numItems-1 do
		local bn = check_list.m_n13:GetChildAt(i);
		bn.selected = selected;
		if npc ~= nil and npc.IsValid and npc.Rank == g_emNpcRank.Worker then
			npc.JobEngine:ChangeBehaviourEnable(bn.data2, bn.selected);
			if bn.data2 == CS.XiaWorld.g_emBehaviourWorkKind.Carry then
				npc.JobEngine:ChangeBehaviourEnable(CS.XiaWorld.g_emBehaviourWorkKind.Clean, bn.selected);
			end
		end
	end	
end

function ChangeAllNpcOneWork(context);
	local checkbox = context.sender;
	local selected = checkbox.selected;
	local index = checkbox.data;
	local check_table = CS.Wnd_NpcWork.Instance.UIInfo.m_n15;
	for i=0, check_table.numItems-1 do
		local check_list = check_table:GetChildAt(i);
		local bn = check_list.m_n13:GetChildAt(index);
		bn.selected = selected;
		local npc = bn.data;
		if npc ~= nil and npc.IsValid and npc.Rank == g_emNpcRank.Worker then
			npc.JobEngine:ChangeBehaviourEnable(bn.data2, bn.selected);
			if bn.data2 == CS.XiaWorld.g_emBehaviourWorkKind.Carry then
				npc.JobEngine:ChangeBehaviourEnable(CS.XiaWorld.g_emBehaviourWorkKind.Clean, bn.selected);
			end
		end
	end
end

function MultiChangeWork:OnRender111(dt)
	if self.checkbox_added then
		if CS.Wnd_NpcWork.Instance == nil or CS.Wnd_NpcWork.Instance.UIInfo == nil then
			return;
		end 
		local Wnd_NpcWork = CS.Wnd_NpcWork.Instance;
		local work_kind_list = Wnd_NpcWork.UIInfo.m_n42;
		local check_table = Wnd_NpcWork.UIInfo.m_n15;
		if Wnd_NpcWork.UIInfo.m_lang.selectedIndex == 1 then
			work_kind_list = Wnd_NpcWork.UIInfo.m_n23;
		end
		local second_item = work_kind_list:GetChildAt(1);
		if second_item.x > 0 then
			for i=0, work_kind_list.numItems-1 do
				local work_kind = work_kind_list:GetChildAt(i);
				local checkbox = Wnd_NpcWork.UIInfo:GetChild(work_kind.title);
				if checkbox ~= nil and work_kind ~= nil then
					checkbox:SetXY(3 + work_kind_list.x + work_kind.x * work_kind_list.scaleX, check_table.y - checkbox.height);
				end
			end
			self.checkbox_added = false;
		end	
	end
end