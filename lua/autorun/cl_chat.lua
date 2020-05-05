----// eChat "FWKZT" edition //----
-- Author: Exho (obviously), Tomelyr, LuaTenshi
-- Contributor: Mka0207
-- Version: 3/25/20
-- Features: Emojis, Hyperlinks, Improved UI and more!

if SERVER then
	AddCSLuaFile()
	return
end

local DefaultTag = {}
DefaultTag["founder"]		= { "Founder",		Color(240,230,45) }
DefaultTag["super_admin"]	= { "Super Admin",	Color(240,230,45) }
DefaultTag["manager"]		= { "Manager",	Color(240,230,45) }
DefaultTag["admin"]			= { "Admin",		Color(240,230,45) }
DefaultTag["staff"]			= { "Staff",		Color(240,230,45) }
DefaultTag["owners"]		= { "Owner",		Color(0,255,0) }
DefaultTag["dedicated"]		= { "Dedicated",	Color(189, 195, 199) }
DefaultTag["member"]		= { "Member",		Color(189, 195, 199) }
DefaultTag["dev_team"]		= { "Dev Team",	Color(255, 0, 0) }
DefaultTag["dev_trainee"]		= { "Developer",	Color(255, 0, 0) }

-- Thanks jetboom
local function BetterScreenScale()
	return math.max(ScrH() / 1080, 0.851) * 1.0
end

eChat = {}

include( 'autorun/sh_chat.lua' )

--TODO: Setup client convars that persist so settings are saved.

eChat.config = {
	timeStamps = false,
	position = 1,
	fadeTime = 12,
	seeChatTags = true,
	seeAvatars = true
}

eChat.CreateFonts = function()
	local screenscale = BetterScreenScale()
	
	surface.CreateFont( "eChatFontText", {
		font = "Arial",
		size = 18,
		weight = 660,
		underline = false,
		antialias = true,
		shadow = false
	} )

	surface.CreateFont( "eChatFontHeader", {
		font = "Arial",
		size = 20,
		weight = 665,
		underline = false,
		antialias = true,
		shadow = false
	} )

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
end
eChat.CreateFonts()

local bar_spacing = 2
local x_spacing = 4

hook.Remove("InitPostEntity", "echat_init")
hook.Add("InitPostEntity", "echat_init", function()
	eChat.buildBox()
end)

--[[hook.Add("Think", "eChat.ClosePanelsOverTime", function()
	if eChat then
		if eChat.chatLog and eChat.chatLog:IsValid() then
			for _, panels in ipairs( eChat.chatLog:GetCanvas():GetChildren() ) do
				if eChat.entry:IsVisible() then
					if not panels:IsVisible() then
						panels:Show()
					end
				else
					if panels.SetTime == nil then
						panels:Hide()
					end
				end
			end
		end
	end
end )]]

--// Builds the chatbox but doesn't display it
function eChat.buildBox()
	eChat.frame = vgui.Create("DFrame")
	eChat.frame:SetSize( ScrW()*0.360, 300*BetterScreenScale() )
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
	serverName:SetText( "FWKZT.com" )
	serverName:SetColor( color_white )
	serverName:SetFont( "eChatFontHeader")
	serverName:SizeToContents()
	serverName:SetPos( 5, 4 )
	
	local settings = vgui.Create("DButton", eChat.frame)
	settings:SetText("Settings")
	settings:SetFont( "eChatFontText")
	settings:SetTextColor( color_white )
	settings:SetSize( 70*BetterScreenScale(), 25 )
	settings:SetPos( eChat.frame:GetWide() - settings:GetWide(), 0 )
	settings.Paint = function( self, w, h )
		surface.SetDrawColor( Color( 245, 66, 66, 100 ) )
		surface.DrawRect( 0, 0, w, h )
	end
	settings.DoClick = function( self )
		eChat.openSettings()
	end
	
	eChat.entry = vgui.Create("DTextEntry", eChat.frame) 
	eChat.entry:SetSize( eChat.frame:GetWide() - 50, 20 )
	eChat.entry:SetTextColor( color_white )
	eChat.entry:SetFont("eChatFontText")
	eChat.entry:SetDrawBorder( false )
	eChat.entry:SetDrawBackground( false )
	eChat.entry:SetCursorColor( color_white )
	eChat.entry:SetHighlightColor( Color(52, 152, 219) )
	eChat.entry:SetPos( 45, eChat.frame:GetTall() - eChat.entry:GetTall() - 5 )
	eChat.entry.Paint = function( self, w, h )
		surface.SetDrawColor( Color( 30, 30, 30, 100 ) )
		surface.DrawRect( 0, 0, w, h )
		
		surface.SetDrawColor( Color( 245, 66, 66, 100 ) )
		surface.DrawOutlinedRect( 0, 0, w, h )
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
	local scrollbar = eChat.chatLog:GetChildren()[2]
	scrollbar.Paint = function(self,w,h)
	end
	local topbutton, bottom, grip = scrollbar:GetChildren()[1], scrollbar:GetChildren()[2], scrollbar:GetChildren()[3]
	topbutton.Paint = function(self,w,h)
		draw.RoundedBox( 0, 0, 0, w, h, Color( 245, 66, 66, 100 ) )
		surface.SetFont( "Default" )
		surface.SetTextColor( 255, 255, 255 )
		local message = "▲"
		local width, height = surface.GetTextSize(message)
		surface.SetTextPos( w/2-width/2, h/2-height/2 ) 
		surface.DrawText( message )
	end
	bottom.Paint = function(self,w,h)
		draw.RoundedBox( 0, 0, 0, w, h, Color( 245, 66, 66, 100 ) )
		surface.SetFont( "Default" )
		surface.SetTextColor( 255, 255, 255 )
		local message = "▼"
		local width, height = surface.GetTextSize(message)
		surface.SetTextPos( w*0.5-width*0.5, h*0.5-height*0.5 ) 
		surface.DrawText( message )
	end
	grip.Paint = function(self,w,h)
		draw.RoundedBox( 0, 0, 0, w, h, Color( 138, 138, 138, 100 ) )
	end
	
	eChat.chatLog:SetSize( eChat.frame:GetWide() - 10, eChat.frame:GetTall() - 60 )
	eChat.chatLog:SetPos( 5, 30 )
	eChat.chatLog.RowSpacing = 20
	
	eChat.chatLog.Paint = function( self, w, h )
		draw.RoundedBox( 0, 0, 0, w, h, Color( 30, 30, 30, 100 ) )
	end
	eChat.chatLog.Think = function( self )
		if not gui.IsGameUIVisible() then
			--[[if eChat.lastMessage then
				if CurTime() - eChat.lastMessage > eChat.config.fadeTime then
					self:SetVisible( false )
				else
					self:SetVisible( true )
					eChat.chatLog:GotoTextEnd()
				end
			end]]
		else
			eChat.hideBox()
		end
	end
	eChat.chatLog.PerformLayout = function( self )
		self:SetFontInternal("eChatFontText")
		self:SetFGColor( color_white )
	end
	eChat.oldPaint2 = eChat.chatLog.Paint

	local text = "Say :"

	local say = vgui.Create("DLabel", eChat.frame)
	say:SetText("")
	surface.SetFont( "eChatFontText")
	local w, h = surface.GetTextSize( text )
	say:SetSize( w + 5, 20 )
	say:SetPos( 5, eChat.frame:GetTall() - eChat.entry:GetTall() - 5 )
	
	say.Paint = function( self, w, h )
		--draw.RoundedBox( 0, 0, 0, w, h, Color( 30, 30, 30, 100 ) )
		draw.DrawText( text, "eChatFontText", 2, 1, color_white )
	end

	say.Think = function( self )
		if eChat.frame and eChat.frame:IsValid() then
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
	end	
	
	eChat.hideBox()
end

--// Hides the chat box but not the messages
function eChat.hideBox()
	if eChat.frame and eChat.frame:IsValid() then
		eChat.frame.Paint = function() end
		eChat.chatLog.Paint = function() end
		
		--eChat.chatLog:SetVerticalScrollbarEnabled( false )
		local scrollbar = eChat.chatLog:GetChildren()[2]
		scrollbar:Hide()
		
		--[[local topbutton, bottom, grip = scrollbar:GetChildren()[1], scrollbar:GetChildren()[2], scrollbar:GetChildren()[3]
		topbutton.Paint = function() end
		bottom.Paint = function() end
		grip.Paint = function() end]]
		
		--eChat.lastMessage = eChat.lastMessage or CurTime() - eChat.config.fadeTime
		
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
end

--// Shows the chat box
function eChat.showBox()
	-- Draw the chat box again
	eChat.frame.Paint = eChat.oldPaint
	eChat.chatLog.Paint = eChat.oldPaint2
	
	eChat.chatLog:SetVerticalScrollbarEnabled( true )
	--eChat.lastMessage = nil
	
	-- Show any hidden children
	local children = eChat.frame:GetChildren()
	for _, pnl in pairs( children ) do
		if pnl == eChat.frame.btnMaxim or pnl == eChat.frame.btnClose or pnl == eChat.frame.btnMinim then continue end
		
		pnl:SetVisible( true )
	end
	
	-- MakePopup calls the input functions so we don't need to call those
	eChat.frame:MakePopup()
	eChat.entry:RequestFocus()
	
	eChat.chatLog:GotoTextEnd()
	
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

local matGradientLeft = CreateMaterial("gradient-l", "UnlitGeneric", {["$basetexture"] = "vgui/gradient-l", ["$vertexalpha"] = "1", ["$vertexcolor"] = "1", ["$ignorez"] = "1", ["$nomip"] = "1"})

--TODO: Setup support for appending html panels
--Allow emojis in tags.
--Trim spaces and fix text being inserted backwards etc.
	
local function EmojiCheck(text)
	for wrds, img in pairs( eChat.Emojis ) do
		if text == wrds then
			return true, wrds, img
		end
	end
	
	return false, "", nil
end

local function HidePanels(panel)
	if eChat.entry and eChat.entry:IsValid() then
		if panel.SetTime ~= nil and CurTime() > panel.SetTime then
			if not eChat.entry:IsVisible() then
				panel:Hide()
			end
			panel.SetTime = nil
		end
	end
end

--// Overwrite chat.AddText to detour it into my chatbox
function chat.AddText(...)
	if not eChat.chatLog then
		eChat.buildBox()
	end
	
	local lastclr = color_white
	
	--Background gradient
	eChat.chatLog:AppendFunc(function(h)
		local panel = vgui.Create( "DPanel" )
		panel:SetSize(eChat.chatLog:GetCanvas():GetWide(), h)
		panel.Paint = function(self,w,h)
			surface.SetDrawColor(0, 0, 0, 100)
			surface.SetMaterial(matGradientLeft)
			surface.DrawTexturedRect(0, bar_spacing, w, h-bar_spacing)
		end
		panel.SetTime = CurTime() + eChat.config.fadeTime
		panel.Think = function() HidePanels(panel) end
		return {panel = panel, h = 0, w = x_spacing}
	end)
	
	-- Iterate through the strings and colors
	for _, obj in pairs( {...} ) do
		--print(obj)
		if IsColor(obj) then
			lastclr = Color( obj.r, obj.g, obj.b, obj.a )
			--print(lastclr)
			--eChat.chatLog:InsertColorChange( obj.r, obj.g, obj.b, obj.a )
		elseif type(obj) == "string"  then
			--eChat.chatLog:AppendText( language.GetPhrase( obj ) )
			
			for _, letter in ipairs( string.Explode( " ", obj ) ) do
				--fix the spacing
				if _ == 1 and letter == ":" then letter = ": " end
				
				--insert emojis
				local em_check, em_wrd, em_img = EmojiCheck(letter)
				if ( em_check == true ) then
					eChat.chatLog:AppendFunc(function(h)
						local panel = vgui.Create( "DImage" )
						panel:SetSize( 28, 28 )
						panel:SetImage(em_img)
						panel:SetTooltip(em_wrd)
						panel.SetTime = CurTime() + eChat.config.fadeTime
						panel.Think = function() HidePanels(panel) end

						return {panel = panel, h = -28/2+h/2+bar_spacing/2, w = 28}
					end)
					continue
				end
				
				--HTML Emojis
				--[[if letter == "html_test" then
					eChat.chatLog:AppendFunc(function(h)
						local panel = vgui.Create( "DHTML" )
						panel:SetSize( 28, h )
						panel:OpenURL("https://fwkzt.com/emojis/?emoji=hl2.png")
						panel.SetTime = CurTime() + eChat.config.fadeTime
						panel.Think = function() HidePanels(panel) end
				
						return {panel = panel, h = -28/2+h/2+bar_spacing/2, w = h}
					end)
					continue
				end]]
				
				if #letter == 0 then continue end
				
				--insert normal text
				eChat.chatLog:AppendFunc(function(h)
					--[[local bgpanel = vgui.Create( "DPanel" )
					bgpanel:SetSize( eChat.chatLog:GetCanvas():GetWide(), h )
					bgpanel.SetTime = CurTime() + eChat.config.fadeTime
					bgpanel.Think = function() HidePanels(bgpanel) end
					bgpanel.Paint = function() end]]
					
					local panel = vgui.Create( "DLabel" )
					panel:SetSize(eChat.chatLog:GetCanvas():GetWide(), h)
					panel:SetFont("eChatFontText")
					panel:SetColor(Color(0,0,0,0))
					panel.LastColor = lastclr
					panel:SetText(letter.." ")
					panel.SetTime = CurTime() + eChat.config.fadeTime
					panel.Think = function() HidePanels(panel) end
					
					panel.Paint = function(self,w,h)
						surface.SetFont("eChatFontText")

						local message = letter.." "
						local width, height = surface.GetTextSize(message)
						
						local elec = string.find( letter, '%[e]' )
						local glow = string.find( letter, '%[g]' )
						local bounce = string.find( letter, '%[b]' )
						local rainbow = string.find( letter, '%[r]' )
						local fade = string.find( letter, '%[f]' )
						
						if elec then
							DrawElectricText(2, string.sub( message, #'[b]'+1, #message ), "eChatFontText", 0, height/2, lastclr, Color(255,255,255,255), true, true)
						elseif glow then
							DrawGlowingText(2, string.sub( message, #'[g]'+1, #message ), "eChatFontText", 0, height/2, lastclr, Color(255,255,255,255), true, true)
						elseif bounce then
							DrawBouncingText(1, 2, string.sub( message, #'[g]'+1, #message ), "eChatFontText", 0, height/2, lastclr, true, true)
						elseif rainbow then
							DrawRainbowText(2, string.sub( message, #'[g]'+1, #message ), "eChatFontText", 0, height/2, true, true)
						elseif fade then
							DrawFadingText(2, string.sub( message, #'[g]'+1, #message ), "eChatFontText", 0, height/2, lastclr, Color(255,0,0,255), true, true)
						else
							surface.SetTextColor( panel.LastColor )
							surface.SetTextPos( 0, height/2 ) 
							surface.DrawText( message )	
						end
					end
	
					local w2, h2 = panel:GetTextSize()
					
					return {panel = panel, h = -h2+h/2+bar_spacing/2, w = w2}
				end)
			end
			
			--Only fwkzt clickable links.
			--[[local http_start, http_end = string.find( lastply.StoredText, "https://fwkzt.com" )
			if http_start then
				eChat.chatLog:AppendFunc(function(h)
					local panel = vgui.Create( "DLabel", eChat.chatLog )
					panel:SetFont( "eChat_Links" )
					local url = string.sub( lastply.StoredText, http_start )
					panel:SetText( url )
					panel:SetTextColor( Color( 66, 221, 245 ) )
					panel:SizeToContents()
					panel:Center()
					panel:SetMouseInputEnabled( true )
					panel.SetTime = CurTime() + eChat.config.fadeTime
					panel.Think = function() HidePanels(panel) end
					
					function panel:DoClick()
						gui.OpenURL( url )
					end
					return {panel = panel, h = h*0.5, w = h}
				end)
			end]]
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
			
			if ply and ply:IsValid() then
				--TODO: Add option for selecting 24hr or 12hr time formats.
				if eChat.config.timeStamps then
					local d = os.date("*t")
					local time_txt = ("%02d:%02d"):format(((d.hour % 24) - 1) % 12 + 1, d.min)
					
					eChat.chatLog:AppendFunc(function(h)
						local panel = vgui.Create( "DLabel" )
						panel:SetSize(eChat.chatLog:GetWide(), h*BetterScreenScale())
						panel:SetFont("eChatFontText")
						panel:SetColor( Color( 77, 255, 0, 255 ) )
						panel:Center()
						panel:SetText( "["..time_txt.." "..os.date("%p").."] " )
						panel.SetTime = CurTime() + eChat.config.fadeTime
						panel.Think = function() HidePanels(panel) end
						
						local w2, h2 = panel:GetTextSize()
						return {panel = panel, h = h2*0.5, w = w2}
					end)
					
					--eChat.chatLog:InsertColorChange( 77, 255, 0, 255 )
					--eChat.chatLog:AppendText( "["..time_txt.." "..os.date("%p").."] " )
				end
				
				if eChat.config.seeAvatars then
					eChat.chatLog:AppendFunc(function(h)
						local panel = vgui.Create( "AvatarImage" )
						panel:SetSize(28, 28)
						panel:SetPlayer( ply, 28 )
						panel.SetTime = CurTime() + eChat.config.fadeTime
						panel.Think = function() HidePanels(panel) end
						panel.PaintOver = function(self,w,h)
							if ply and ply:IsValid() then
								surface.SetDrawColor( team.GetColor(ply:Team()) )
								surface.DrawOutlinedRect( 0, 0, w, h )
							end
						end
						
						return {panel = panel, h=-28/2+h/2+bar_spacing/2, w = 32}
					end)
				end
				
				if eChat.config.seeChatTags then
					local col = ply:GetChatTagColor()
					local tbl = col:ToTable()

					eChat.chatLog:AppendFunc(function(h)
						local panel = vgui.Create( "DLabel" )
						panel:SetSize(eChat.chatLog:GetWide(), h)
						panel:SetFont("eChatFontText")
						panel:SetText("")
						panel.SetTime = CurTime() + eChat.config.fadeTime
						panel.Think = function() HidePanels(panel) end
						
						if ply:HasChatTag() then
							panel:SetColor( Color( tbl[1], tbl[2], tbl[3], tbl[4] ) )
							panel:SetText( "[ "..ply:GetChatTag().." ] " )
						else
							local DTag = DefaultTag[ string.lower( ply:GetUserGroup() ) ]
							if DTag then
								panel:SetColor( DTag[2] )
								panel:SetText( "["..DTag[1].."] " )
							end
						end
						local w2, h2 = panel:GetTextSize()
						return {panel = panel, h = -h2+h/2+bar_spacing/2, w = w2}
					end)
					
					--[[if ply:HasChatTag() then
						eChat.chatLog:InsertColorChange( tbl[1], tbl[2], tbl[3], tbl[4] )
						eChat.chatLog:AppendText( "["..ply:GetChatTag().."] " )
					else
						local DTag = DefaultTag[ string.lower( ply:GetUserGroup() ) ]
						if DTag then
							eChat.chatLog:InsertColorChange( DTag[2] )
							eChat.chatLog:AppendText( "["..DTag[1].."] " )
						end
					end]]
				end
				
				eChat.chatLog:AppendFunc(function(h)
					local panel = vgui.Create( "DLabel" )
					panel:SetSize(eChat.chatLog:GetWide(), h)
					panel:SetFont("eChatFontText")
					local col = GAMEMODE:GetTeamColor( obj )
					panel:SetColor( Color( col.r, col.g, col.b, 255 ) )
					panel:Center()
					panel:SetText( obj:Nick() )
					panel.SetTime = CurTime() + eChat.config.fadeTime
					panel.Think = function() HidePanels(panel) end
					local w2, h2 = panel:GetTextSize()
					return {panel = panel, h = -h2+h/2+bar_spacing/2, w = w2}
				end)
				
				--local col_tab = team.GetColor( ply:Team() )
				--eChat.chatLog:InsertColorChange( col_tab.r, col_tab.g, col_tab.b, col_tab.a )
				--eChat.chatLog:AppendText( obj:Nick() )

				lastply = obj
			end
		end
	end
	
	eChat.chatLog:AppendText("\n")
	eChat.chatLog:SetVisible( true )
	--eChat.lastMessage = CurTime()
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
		chat.AddText( Color( 255, 255, 255 ), text )
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

hook.Add("OnScreenSizeChanged", "eChat.ScreenResRebuild", function(oldWidth,oldHeight)
	if eChat and IsValid( eChat.frame ) then
		eChat.CreateFonts()
		local scrollbar = eChat.chatLog:GetChildren()[2]
		scrollbar:Remove()
		eChat.chatLog:Remove()
		for _, panels in ipairs( eChat.frame:GetChildren() ) do
			panels:Remove()
		end
		eChat.frame:Remove()
		timer.Simple(0,function()
			eChat.buildBox()
		end)
	end
end )