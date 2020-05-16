resource.AddFile( "materials/fwkzt/emojis/blue_shift.png" )
resource.AddFile( "materials/fwkzt/emojis/rofl_stare.png" )
resource.AddFile( "materials/fwkzt/emojis/hl2.png" )
resource.AddFile( "materials/fwkzt/emojis/isaac.png" )
resource.AddFile( "materials/fwkzt/emojis/jim_smile.png" )
resource.AddFile( "materials/fwkzt/emojis/lenny.png" )
resource.AddFile( "materials/fwkzt/emojis/lennycry.png" )
resource.AddFile( "materials/fwkzt/emojis/ogkleiner.png" )
resource.AddFile( "materials/fwkzt/emojis/kleiner.png" )
resource.AddFile( "materials/fwkzt/emojis/omegalol.png" )
resource.AddFile( "materials/fwkzt/emojis/rofl_laugh.png" )
resource.AddFile( "materials/fwkzt/emojis/steve_smug.png" )
resource.AddFile( "materials/fwkzt/emojis/poggers.png" )
resource.AddFile( "materials/fwkzt/emojis/pat_eyes.png" )
resource.AddFile( "materials/fwkzt/emojis/thonk.png" )
resource.AddFile( "materials/fwkzt/emojis/headcrab.png" )
resource.AddFile( "materials/fwkzt/emojis/gmod.png" )
resource.AddFile( "materials/fwkzt/emojis/pat_evil.png" )

--TODO: loop through emojis folder and resource add all jpeg/pngs.

hook.Add( "PlayerSay", "FilterEmonjis", function( ply, text )

	if ply.HasChatTag and ply:HasChatTag() then
		PrintMessage(HUD_PRINTCONSOLE, "("..ply:SteamID()..") ".."["..ply:GetChatTag().."] "..ply:Nick().. ": "..text)
	else
		PrintMessage(HUD_PRINTCONSOLE, "("..ply:SteamID()..") "..ply:Nick().. ": "..text)
	end
	
	--TODO: only pass non url text.
	--[[if string.match( text, "^[https//:]+%w+%.%w+[/%w%.]+$") then
		return " "
	end]]
end )