MapVotePools.Nominate.Wipe = function()
	MapVotePools.Nominate._Loaded = CurTime()
	MapVotePools.Nominate.PlayerMapNominations = {}
	MapVotePools.Nominate.MapNominationCounts = {}
end
MapVotePools.Nominate.Wipe()

function MapVotePools.Nominate.TotalNominations()
	local total_nominations = 0
	MapVotePools.Nominate.MapNominationCounts = {}
	for steam64, map_name in pairs(MapVotePools.Nominate.PlayerMapNominations) do
		local nominations = MapVotePools.Nominate.MapNominationCounts[map_name] or 0
		MapVotePools.Nominate.MapNominationCounts[map_name] = nominations + 1
		total_nominations = total_nominations + 1
	end
	return total_nominations, MapVotePools.Nominate.MapNominationCounts
end

function MapVotePools.Nominate.SetClientNominatedMap(ply, desired_map)
	MapVotePools.Nominate.PlayerMapNominations[ ply:SteamID64() ] = desired_map
	MapVotePools.Nominate.TotalNominations()
end

-- @TODO: localize
function MapVotePools.Nominate.CanClientNominateMap(ply, desired_map)
	if desired_map == nil then
		-- if (MapVotePools.Nominate._Loaded + MapVotePools.CVARS.rtv_wait:GetFloat()) >= CurTime() then
		-- 	return false, "You must wait a bit before unrocking!"
		-- end

		if not MapVotePools.Nominate.PlayerMapNominations[ ply:SteamID64() ] then
			return false, "You have not yet nominated anything! Irritating!"
		end

		-- if plyCount < MapVotePools.CVARS.rtv_player_count:GetInt() then
		-- 	return false, "Not enough players to begin unrocking!"
		-- end

		-- if not GetGlobalBool( "In_Voting" ) then
			-- return false, "There is currently a ballot in progress, you can't unrock now!"
		-- end

		-- if MapVotePools.Nominate.ChangingMaps then
		-- 	return false, "There has already been a ballot, the map is already going to change!"
		-- end

		if MapVotePools.InProgress then
			return false, "There is a ballot in progress, you should have unnominated sooner!"
		end

		return true, nil
	end

	if MapVotePools.InProgress then
		return false, "There is a ballot in progress, you should have nominated sooner!"
	end

	local maps = MapVotePools.PlainMapList()
	local hits = {}
	for _, map_name in ipairs(maps) do
		--[[
		-- we can't break early because some maps are substrings of others :(
		if desired_map == map_name then
			hit_count = 1
			hits = {map_name}
			break
		end
		]]
		if string.find(map_name, desired_map, 0, true) then
			table.insert(hits, map_name)
		end
	end
	local hit_count = #hits
	local full_map_name

	if hit_count == 0 then
		return false, "There are no maps named like \"" .. desired_map .. "\"!"
	elseif hit_count == 1 then
		full_map_name = hits[1]
		if MapVotePools.Nominate.MapNominationCounts[ ply:SteamID64() ] == full_map_name then
			return false, "You have already nominated that map! Stop it!"
		else
			return true, full_map_name
		end
	else
		if hit_count >= MapVotePools.CVARS.nominate_limit_map_print:GetInt() then
			return false, "There were too many maps (" .. hit_count .. ") named like \"" .. desired_map .. "\" to display suggestions for your nomination. Try to be more specific."
		else
			return false, "Please specify nomination, valid map names are: \"" .. table.concat(hits, "\", \"") .. "\""
		end
	end

	return false, "I don't know what you did to break this, stop it."
end

function MapVotePools.Nominate.HandleClientNominateMap(ply, desired_map)
	local can, map_fullname_or_err = MapVotePools.Nominate.CanClientNominateMap(ply, desired_map)

	if not can then
		ply:PrintMessage( HUD_PRINTTALK, map_fullname_or_err )
		return false
	end

	MapVotePools.Nominate.SetClientNominatedMap( ply, map_fullname_or_err )

	-- @TODO: localize
	local say_all = ply:Nick()

	if map_fullname_or_err then
		say_all = say_all .. " has nominated \"" .. map_fullname_or_err .. "\"! Use \"!nominate\" to suggest your own."
	else
		say_all = say_all .. " has unnominated their map. Wack! "
	end

	PrintMessage( HUD_PRINTTALK, say_all )
	return true
end

--region network
util.AddNetworkString("MVP_ClientNominateMap")
util.AddNetworkString("MVP_ClientUnnominateMap")

net.Receive( "MVP_ClientNominateMap", function (len, ply)
	local user_suggestion = net.ReadString()
	MapVotePools.Nominate.HandleClientNominateMap(ply, user_suggestion)
end )

net.Receive( "MVP_ClientUnnominateMap", function (len, ply)
	MapVotePools.Nominate.HandleClientNominateMap(ply, nil)
end )
--endregion network


--region hooks
hook.Remove( "PlayerDisconnected", "MVP_NominatePlayerDisconnected")
hook.Add( "PlayerDisconnected", "MVP_NominatePlayerDisconnected", function( ply )
	MapVotePools.Nominate.HandleClientNominateMap(ply, nil)
end )

if MapVotePools.CVARS.use_chat_commands:GetBool() then
	hook.Remove( "PlayerSay", "MPV_NominatePlayerSay" )
	hook.Add( "PlayerSay", "MPV_NominatePlayerSay", function( ply, text )
		local user_msg = string.Split(text, " ")

		local cmd = table.remove(user_msg, 1)
		local map_name = table.concat(user_msg, " ")
		if table.HasValue( MapVotePools.Nominate.NominateMapChatCommands, cmd) then
			return MapVotePools.Nominate.HandleClientNominateMap(ply, map_name)
		end

		if table.HasValue( MapVotePools.Nominate.UnnominateMapChatCommands, cmd ) then
			return MapVotePools.Nominate.HandleClientNominateMap(ply, nil)
		end
	end )
end
--endregion hooks

