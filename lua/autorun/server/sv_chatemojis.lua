hook.Add( "PlayerSay", "FilterEmonjis", function( ply, text )
	local heckStart, heckEnd = string.find( text:lower(), "heck" )
	if heckStart then
		local civilText = string.sub( text, 1, heckStart - 1 ) .. "****" .. string.sub( text, heckEnd + 1 )
		return civilText
	end
	
	for wrds, img in pairs( eChat.Emojis ) do
		local e_st, e_en = string.find( text, wrds )
		if e_st then
			local clean_text = string.sub( text, 1, e_st - 1 ) .. " " .. string.sub( text, e_en + 1 )
			return clean_text
		end
	end
	
	--TODO: only pass non url text.
	--[[if string.match( text, "^[https//:]+%w+%.%w+[/%w%.]+$") then
		return " "
	end]]
end )