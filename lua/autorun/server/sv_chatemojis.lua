util.AddNetworkString( "NetWork_StoreText" )

hook.Add( "PlayerSay", "FilterEmonjis", function( ply, text )

	net.Start("NetWork_StoreText")
		net.WriteEntity( ply )
		net.WriteString( text )
	net.Broadcast()
	
	local oldtext = text
	for wrds, img in pairs( eChat.Emojis ) do
		for s in string.gmatch(text, "[^%s,]+") do
			if s:match( wrds ) then
				return string.Replace( oldtext, s, " " )
			end
		end
	end
	
	--TODO: only pass non url text.
	--[[if string.match( text, "^[https//:]+%w+%.%w+[/%w%.]+$") then
		return " "
	end]]
end )