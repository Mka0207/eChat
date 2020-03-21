----// eChat //----
-- Author: Exho (obviously), Tomelyr, LuaTenshi, Mka0207
-- Version: 3/21/20

if SERVER then
	AddCSLuaFile()
	return
end

net.Receive( "NetWork_StoreText", function( len, pl )
	--print( "Message from server received. Its length is " .. len .. "." )
	net.ReadEntity().StoredText = net.ReadString()
end )

local function BetterScreenScale()
	return math.max(ScrH() / 1080, 0.851) * 1.0
end

--Clean up hooks not required for a custom chatbox.
timer.Simple(0.1, function()
	if GAMEMODE_NAME != 'terrortown' then
		hook.Remove( 'OnPlayerChat', 'FWKZT.ChatTags.AddTag' )
	else
		hook.Remove( 'OnPlayerChat', 'FWKZT.ChatTags.AddTag.TTT' )
	end
end )

eChat = {}

include( 'autorun/sh_chat.lua' )

eChat.config = {
	timeStamps = false,
	position = 1,
	fadeTime = 12,
	seeChatTags = true,
	seeAvatars = true
}

surface.CreateFont( "eChatFont", {
	font = "Verdana",
	size = 16,
	weight = 500,
	underline = false,
	antialias = false,
	shadow = false
} )

surface.CreateFont( "eChat_Links", {
	font = "Verdana",
	size = 16,
	weight = 500,
	underline = false,
	antialias = false,
	shadow = true
} )

surface.CreateFont( "eChat_18", {
	font = "Roboto Lt",
	size = 18,
	weight = 500,
	antialias = true,
	shadow = true
} )

surface.CreateFont( "eChat_16", {
	font = "Roboto Lt",
	size = 16,
	weight = 500,
	antialias = true,
} )

hook.Remove("InitPostEntity", "echat_init")
hook.Add("InitPostEntity", "echat_init", function()
	eChat.buildBox()
end)

--// Builds the chatbox but doesn't display it
function eChat.buildBox()
	eChat.frame = vgui.Create("DFrame")
	eChat.frame:SetSize( ScrW()*0.375, ScrH()*0.25 )
	eChat.frame:SetTitle("")
	eChat.frame:ShowCloseButton( false )
	eChat.frame:SetDraggable( false )
	eChat.frame:SetPos( ScrW()*0.0116, (ScrH() - eChat.frame:GetTall()) - ScrH()*0.177)
	eChat.frame.Paint = function( self, w, h )
		eChat.blur( self, 10, 20, 255 )
		draw.RoundedBox( 0, 0, 0, w, h, Color( 30, 30, 30, 200 ) )
		
		draw.RoundedBox( 0, 0, 0, w, 25, Color( 80, 80, 80, 100 ) )
	end
	eChat.oldPaint = eChat.frame.Paint
	eChat.frame.Think = function()
		if input.IsKeyDown( KEY_ESCAPE ) then
			eChat.hideBox()
		end
	end
	
	local serverName = vgui.Create("DLabel", eChat.frame)
	serverName:SetText( GetHostName() )
	serverName:SetFont( "eChatFont")
	serverName:SizeToContents()
	serverName:SetPos( 5, 4 )
	
	local settings = vgui.Create("DButton", eChat.frame)
	settings:SetText("Settings")
	settings:SetFont( "eChatFont")
	settings:SetTextColor( Color( 230, 230, 230, 150 ) )
	settings:SetSize( 70*BetterScreenScale(), 25 )
	settings:SetPos( eChat.frame:GetWide() - settings:GetWide(), 0 )
	settings.Paint = function( self, w, h )
		draw.RoundedBox( 0, 0, 0, w, h, Color( 50, 50, 50, 200 ) )
	end
	settings.DoClick = function( self )
		eChat.openSettings()
	end
	
	eChat.entry = vgui.Create("DTextEntry", eChat.frame) 
	eChat.entry:SetSize( eChat.frame:GetWide() - 50, 20 )
	eChat.entry:SetTextColor( color_white )
	eChat.entry:SetFont("eChatFont")
	eChat.entry:SetDrawBorder( false )
	eChat.entry:SetDrawBackground( false )
	eChat.entry:SetCursorColor( color_white )
	eChat.entry:SetHighlightColor( Color(52, 152, 219) )
	eChat.entry:SetPos( 45, eChat.frame:GetTall() - eChat.entry:GetTall() - 5 )
	eChat.entry.Paint = function( self, w, h )
		draw.RoundedBox( 0, 0, 0, w, h, Color( 30, 30, 30, 100 ) )
		derma.SkinHook( "Paint", "TextEntry", self, w, h )
	end

	eChat.entry.OnTextChanged = function( self )
		if self and self.GetText then 
			gamemode.Call( "ChatTextChanged", self:GetText() or "" )
		end
	end

	eChat.entry.OnKeyCodeTyped = function( self, code )
		local types = {"", "teamchat", "console"}

		if code == KEY_ESCAPE then

			eChat.hideBox()
			gui.HideGameUI()

		elseif code == KEY_TAB then
			
			eChat.TypeSelector = (eChat.TypeSelector and eChat.TypeSelector + 1) or 1
			
			if eChat.TypeSelector > 3 then eChat.TypeSelector = 1 end
			if eChat.TypeSelector < 1 then eChat.TypeSelector = 3 end
			
			eChat.ChatType = types[eChat.TypeSelector]

			timer.Simple(0.001, function() eChat.entry:RequestFocus() end)

		elseif code == KEY_ENTER then
			-- Replicate the client pressing enter
			
			local txt = string.Trim( self:GetText() )
			if txt != "" then
				if eChat.ChatType == types[2] then
					LocalPlayer():ConCommand("say_team \"" .. (self:GetText() or "") .. "\"")
				elseif eChat.ChatType == types[3] then
					LocalPlayer():ConCommand(self:GetText() or "")
				else
					LocalPlayer():ConCommand("say \"" .. self:GetText() .. "\"")
				end
			end

			eChat.TypeSelector = 1
			eChat.hideBox()
		end
	end

	eChat.chatLog = vgui.Create("DFancyText", eChat.frame) 
	eChat.chatLog:SetSize( eChat.frame:GetWide() - 10, eChat.frame:GetTall() - 60 )
	eChat.chatLog:SetPos( 5, 30 )
	eChat.chatLog.Paint = function( self, w, h )
		draw.RoundedBox( 0, 0, 0, w, h, Color( 30, 30, 30, 100 ) )
	end
	eChat.chatLog.Think = function( self )
		if eChat.lastMessage then
			if CurTime() - eChat.lastMessage > eChat.config.fadeTime then
				self:SetVisible( false )
			else
				self:SetVisible( true )
			end
		end
	end
	eChat.chatLog.PerformLayout = function( self )
		self:SetFontInternal("ChatFont")
		self:SetFGColor( color_white )
	end
	eChat.oldPaint2 = eChat.chatLog.Paint

	local text = "Say :"

	local say = vgui.Create("DLabel", eChat.frame)
	say:SetText("")
	surface.SetFont( "eChatFont")
	local w, h = surface.GetTextSize( text )
	say:SetSize( w + 5, 20 )
	say:SetPos( 5, eChat.frame:GetTall() - eChat.entry:GetTall() - 5 )
	
	say.Paint = function( self, w, h )
		--draw.RoundedBox( 0, 0, 0, w, h, Color( 30, 30, 30, 100 ) )
		draw.DrawText( text, "eChatFont", 2, 1, color_white )
	end

	say.Think = function( self )
		local types = {"", "teamchat", "console"}
		local s = {}

		if eChat.ChatType == types[2] then 
			text = "Say (TEAM) :"	
		elseif eChat.ChatType == types[3] then
			text = "Console :"
		else
			text = "Say :"
			s.pw = 45
			s.sw = eChat.frame:GetWide() - 50
		end

		if s then
			if not s.pw then s.pw = self:GetWide() + 10 end
			if not s.sw then s.sw = eChat.frame:GetWide() - self:GetWide() - 15 end
		end

		local w, h = surface.GetTextSize( text )
		self:SetSize( w + 5, 20 )
		self:SetPos( 5, eChat.frame:GetTall() - eChat.entry:GetTall() - 5 )

		eChat.entry:SetSize( s.sw, 20 )
		eChat.entry:SetPos( s.pw, eChat.frame:GetTall() - eChat.entry:GetTall() - 5 )
	end	
	
	eChat.hideBox()
end

--// Hides the chat box but not the messages
function eChat.hideBox()
	eChat.frame.Paint = function() end
	eChat.chatLog.Paint = function() end
	
	eChat.chatLog:SetVerticalScrollbarEnabled( false )
	eChat.chatLog:GotoTextEnd()
	
	eChat.lastMessage = eChat.lastMessage or CurTime() - eChat.config.fadeTime
	
	-- Hide the chatbox except the log
	local children = eChat.frame:GetChildren()
	for _, pnl in pairs( children ) do
		if pnl == eChat.frame.btnMaxim or pnl == eChat.frame.btnClose or pnl == eChat.frame.btnMinim then continue end
		
		if pnl != eChat.chatLog then
			pnl:SetVisible( false )
		end
	end
	
	-- Give the player control again
	eChat.frame:SetMouseInputEnabled( false )
	eChat.frame:SetKeyboardInputEnabled( false )
	gui.EnableScreenClicker( false )
	
	-- We are done chatting
	gamemode.Call("FinishChat")
	
	-- Clear the text entry
	eChat.entry:SetText( "" )
	gamemode.Call( "ChatTextChanged", "" )
end

--// Shows the chat box
function eChat.showBox()
	-- Draw the chat box again
	eChat.frame.Paint = eChat.oldPaint
	eChat.chatLog.Paint = eChat.oldPaint2
	
	eChat.chatLog:SetVerticalScrollbarEnabled( true )
	eChat.lastMessage = nil
	
	-- Show any hidden children
	local children = eChat.frame:GetChildren()
	for _, pnl in pairs( children ) do
		if pnl == eChat.frame.btnMaxim or pnl == eChat.frame.btnClose or pnl == eChat.frame.btnMinim then continue end
		
		pnl:SetVisible( true )
	end
	
	-- MakePopup calls the input functions so we don't need to call those
	eChat.frame:MakePopup()
	eChat.entry:RequestFocus()
	
	-- Make sure other addons know we are chatting
	gamemode.Call("StartChat")
end

--// Opens the settings panel
function eChat.openSettings()
	eChat.hideBox()
	
	eChat.frameS = vgui.Create("DFrame")
	eChat.frameS:SetSize( 400, 300 )
	eChat.frameS:SetTitle("")
	eChat.frameS:MakePopup()
	eChat.frameS:SetPos( ScrW()/2 - eChat.frameS:GetWide()/2, ScrH()/2 - eChat.frameS:GetTall()/2 )
	eChat.frameS:ShowCloseButton( true )
	eChat.frameS.Paint = function( self, w, h )
		eChat.blur( self, 10, 20, 255 )
		draw.RoundedBox( 0, 0, 0, w, h, Color( 30, 30, 30, 200 ) )
		
		draw.RoundedBox( 0, 0, 0, w, 25, Color( 80, 80, 80, 100 ) )
	end
	
	eChat.paneList = vgui.Create("DPanelList", eChat.frameS)
	eChat.paneList:Dock(FILL)
	eChat.paneList.Paint = function( self, w, h )
	end
	
	local serverName = vgui.Create("DLabel", eChat.frameS)
	serverName:SetText( "Settings" )
	serverName:SetFont( "eChatFont")
	serverName:SizeToContents()
	serverName:SetPos( 5, 4 )
	
	local avatar_check = vgui.Create("DCheckBoxLabel", eChat.frameS)
	avatar_check:SetText("Avatars")
	avatar_check:SetValue(eChat.config.seeAvatars)
	avatar_check:SizeToContents()
	eChat.paneList:AddItem(avatar_check)
	
	local tags_check = vgui.Create("DCheckBoxLabel", eChat.frameS)
	tags_check:SetText("Tags")
	tags_check:SetValue(eChat.config.seeChatTags)
	tags_check:SizeToContents()
	eChat.paneList:AddItem(tags_check)
	
	local stamps_check = vgui.Create("DCheckBoxLabel", eChat.frameS)
	stamps_check:SetText("Time stamps")
	stamps_check:SetValue(eChat.config.timeStamps)
	stamps_check:SizeToContents()
	eChat.paneList:AddItem(stamps_check)
	
	local time_slider = vgui.Create("DNumSlider", eChat.frameS)
	time_slider:SetDecimals(0)
	time_slider:SetMinMax(1, 30)
	time_slider:SetValue(eChat.config.fadeTime)
	time_slider:SetText("Fade Time")
	time_slider:SizeToContents()
	eChat.paneList:AddItem(time_slider)
	
	local save = vgui.Create("DButton", eChat.frameS)
	save:SetText("Save")
	save:SetFont( "eChatFont")
	save:SetTextColor( Color( 230, 230, 230, 150 ) )
	save:SetSize( 70, 25 )
	save:SetPos( eChat.frameS:GetWide()/2 - save:GetWide()/2, eChat.frameS:GetTall() - save:GetTall() - 10)
	save.Paint = function( self, w, h )
		if self:IsDown() then
			draw.RoundedBox( 0, 0, 0, w, h, Color( 80, 80, 80, 200 ) )
		else
			draw.RoundedBox( 0, 0, 0, w, h, Color( 50, 50, 50, 200 ) )
		end
	end
	save.DoClick = function( self )
		eChat.frameS:Close()
		
		eChat.config.timeStamps = stamps_check:GetChecked()
		eChat.config.seeAvatars = avatar_check:GetChecked()
		eChat.config.seeChatTags = tags_check:GetChecked()
		eChat.config.fadeTime = tonumber(time_slider:GetValue()) or eChat.config.fadeTime
	end
end

--// Panel based blur function by Chessnut from NutScript
local blur = Material( "pp/blurscreen" )
function eChat.blur( panel, layers, density, alpha )
	-- Its a scientifically proven fact that blur improves a script
	local x, y = panel:LocalToScreen(0, 0)

	surface.SetDrawColor( 255, 255, 255, alpha )
	surface.SetMaterial( blur )

	for i = 1, 3 do
		blur:SetFloat( "$blur", ( i / layers ) * density )
		blur:Recompute()

		render.UpdateScreenEffectTexture()
		surface.DrawTexturedRect( -x, -y, ScrW(), ScrH() )
	end
end

local oldAddText = chat.AddText

--// Overwrite chat.AddText to detour it into my chatbox
function chat.AddText(...)
	if not eChat.chatLog then
		eChat.buildBox()
	end

	local lastply = nil
	
	-- Iterate through the strings and colors
	for _, obj in pairs( {...} ) do
		if IsColor(obj) then
			eChat.chatLog:InsertColorChange( obj.r, obj.g, obj.b, obj.a )
		elseif type(obj) == "string"  then
			eChat.chatLog:AppendText( language.GetPhrase( obj ) )
		elseif type(obj) == "table"  then
			if obj[1] == "image" then
				eChat.chatLog:AppendImage({mat = Material(obj[2].img), w = obj[2].w, h = obj[2].h})
			end
		elseif obj:IsPlayer() then
			local ply = obj
			
			--[[if ply:IsDonator() then
				eChat.chatLog:AppendImage( {mat = Material( "icon16/heart.png" ), w = 18*BetterScreenScale(), h = 18*BetterScreenScale()})
			end
			if ply:IsGoldPassHolder() then
				eChat.chatLog:AppendImage( {mat = Material( "fwkzt/hud_icons/hexagon_gold_v2" ), w = 18*BetterScreenScale(), h = 18*BetterScreenScale()})
			end
			if ply:IsSilverPassHolder() then
				eChat.chatLog:AppendImage( {mat = Material( "fwkzt/hud_icons/hexagon_silver_v2" ), w = 18*BetterScreenScale(), h = 18*BetterScreenScale()})
			end
			if ply:IsBronzePassHolder() then
				eChat.chatLog:AppendImage( {mat = Material( "fwkzt/hud_icons/hexagon_bronze_v2" ), w = 18*BetterScreenScale(), h = 18*BetterScreenScale()})
			end]]
			
			--TODO: Add option for selecting 24hr or 12hr time formats.
			if eChat.config.timeStamps then
				local d = os.date("*t")
				local time_txt = ("%02d:%02d"):format(((d.hour % 24) - 1) % 12 + 1, d.min)
				eChat.chatLog:InsertColorChange( 77,255,0, 255 )
				eChat.chatLog:AppendText( "["..time_txt.." "..os.date("%p").."] ")
			end
			
			if eChat.config.seeAvatars then
				eChat.chatLog:AppendFunc(function(h)
					local panel = vgui.Create( "AvatarImage", eChat.chatLog )
					panel:SetSize(18*BetterScreenScale(), 16*BetterScreenScale())
					panel:Center()
					panel:SetPlayer( ply, 32 )
					return {panel = panel, h = 20*BetterScreenScale(), w = 21*BetterScreenScale()}
				end)
			end
			
			if eChat.config.seeChatTags and ply:HasChatTag() then
				local col = ply:GetChatTagColor()
				local tbl = col:ToTable()
				eChat.chatLog:InsertColorChange( tbl[1], tbl[2], tbl[3], tbl[4] )
				eChat.chatLog:AppendText( "["..ply:GetChatTag().."] ")
			end
			
			local col = GAMEMODE:GetTeamColor( obj )
			eChat.chatLog:InsertColorChange( col.r, col.g, col.b, 255 )
			eChat.chatLog:AppendText( obj:Nick() )
			
			lastply = obj
		end
	end
	
	if ( lastply and lastply:IsValid() ) and lastply.StoredText ~= nil then
		--Check and add emojis
		--TODO: Setup support for appending html panels
		for wrds, img in pairs( eChat.Emojis ) do
			str = lastply.StoredText
			for s in string.gmatch(str, "[^%s,]+") do
				if s:match( wrds ) then
					eChat.chatLog:AppendImage( {mat = Material(img), w = 16*BetterScreenScale(), h = 16*BetterScreenScale()})
				end
			end
		end
		--Only fwkzt clickable links.
		local http_start, http_end = string.find( lastply.StoredText, "https://fwkzt.com" )
		if http_start then
			eChat.chatLog:AppendFunc(function(h)
				local panel = vgui.Create( "DLabel" )
				panel:SetFont( "eChat_Links" )
				local url = string.sub( lastply.StoredText, http_start )
				panel:SetText( url )
				panel:SetTextColor( Color( 66, 221, 245 ) )
				panel:SizeToContents()
				panel:Center()
				panel:SetMouseInputEnabled( true )
				function panel:DoClick()
					gui.OpenURL( url )
				end
				return {panel = panel, h = h, w = h}
			end)
		end
		--HTML Emojis
		--[[eChat.chatLog:AppendFunc(function(h)
			local panel = vgui.Create( "DHTML" )
			panel:SetSize( 16, h )
			panel:OpenURL("https://cdn.discordapp.com/attachments/256233839658139648/690832036235051028/halo-icon2.png")
	
			return {panel = panel, h = h, w = h}
		end)]]
		lastply.StoredText = nil
	end
	
	eChat.chatLog:AppendText("\n")
	
	eChat.chatLog:SetVisible( true )
	eChat.lastMessage = CurTime()
	eChat.chatLog:GotoTextEnd()
end

--// Write any server notifications
hook.Remove( "ChatText", "echat_joinleave")
hook.Add( "ChatText", "echat_joinleave", function( index, name, text, type )
	if not eChat.chatLog then
		eChat.buildBox()
	end
	
	if type != "chat" then
		if ( type == "joinleave" ) then return true end
		
		eChat.chatLog:InsertColorChange( 0, 128, 255, 255 )
		eChat.chatLog:AppendText( text.."\n" )
		eChat.chatLog:SetVisible( true )
		eChat.lastMessage = CurTime()
		eChat.chatLog:GotoTextEnd()
		return true
	end
end)

--// Stops the default chat box from being opened
hook.Remove("PlayerBindPress", "echat_hijackbind")
hook.Add("PlayerBindPress", "echat_hijackbind", function(ply, bind, pressed)
	if string.sub( bind, 1, 11 ) == "messagemode" then
		if bind == "messagemode2" then 
			eChat.ChatType = "teamchat"
		else
			eChat.ChatType = ""
		end
		
		if IsValid( eChat.frame ) then
			eChat.showBox()
		else
			eChat.buildBox()
			eChat.showBox()
		end
		return true
	end
end)

--// Hide the default chat too in case that pops up
hook.Remove("HUDShouldDraw", "echat_hidedefault")
hook.Add("HUDShouldDraw", "echat_hidedefault", function( name )
	if name == "CHudChat" then
		return false
	end
end)

 --// Modify the Chatbox for align.
local oldGetChatBoxPos = chat.GetChatBoxPos
function chat.GetChatBoxPos()
	return eChat.frame:GetPos()
end

function chat.GetChatBoxSize()
	return eChat.frame:GetSize()
end

chat.Open = eChat.showBox
function chat.Close(...) 
	if IsValid( eChat.frame ) then 
		eChat.hideBox(...)
	else
		eChat.buildBox()
		eChat.showBox()
	end
end
