util.AddNetworkString("MVP_MapVotePoolsStart")
util.AddNetworkString("MVP_MapVotePoolsUpdate")
util.AddNetworkString("MVP_MapVotePoolsCancel")
util.AddNetworkString("MVP_RTV_Delay")
util.AddNetworkString("MVP_UNRTV_Delay")
util.AddNetworkString("MVP_AdminRequestMapData")
util.AddNetworkString("MVP_AdminReturnMapData")
util.AddNetworkString("MVP_AdminWriteMapData")

function MapVotePools.NormalizeMapName(map_name)
	if string.EndsWith(map_name, ".bsp") then
		map_name = map_name:sub(1, -5)
	end

	return map_name:lower()
end

function MapVotePools.GetMapData(map_name)
	local datum = {}

	datum.name = MapVotePools.NormalizeMapName(map_name)
	datum.stats = MapVotePools.Data.MapStats[map_name] or {
		SpawnPoints = 0,

		LifetimeTallies = 0,
		LifetimeVoteWins = 0,
		LifetimeRoundsPlayed = 0,
		LifetimeSessionStarts = 0,
		LifetimeSessionsCompleted = 0,

		LifetimeRTVAttempted = 0,
	}
	datum.config = MapVotePools.Data.MapConfig[map_name] or {
		MinPlayers = 0,
		MaxPlayers = 0,
	}
	return datum
end

function MapVotePools.WriteData()
	file.Write("mapvotepools/recentmaps.txt", util.TableToJSON(MapVotePools.Data.RecentMaps, true))
end

net.Receive("MVP_AdminRequestMapData", function(len, ply)
	local map_data = MapVotePools.GetMapData(game.GetMap())
	net.Start("MVP_AdminReturnMapData")
		net.WriteString(map_data.name)
		net.WriteUInt(map_data.config.MinPlayers, 8)
		net.WriteUInt(map_data.config.MaxPlayers, 8)
	net.Send( ply )
end)

net.Receive("MVP_AdminWriteMapData", function(len, ply)
	local wad = {}
	wad.map = net.ReadString()
	wad.min_players = net.ReadUInt(8)
	wad.max_players = net.ReadUInt(8)

	local map = MapVotePools.GetMapData(wad.map)
	map.config.MinPlayers = wad.min_players
	map.config.MaxPlayers = wad.max_players
	MapVotePools.Data.MapConfig[ map.name ] = map.config
	file.Write("mapvotepools/mapconfig.txt", util.TableToJSON(MapVotePools.Data.MapConfig, true))
end)

net.Receive("MVP_MapVotePoolsUpdate", function(len, ply)
	if (MapVotePools.InProgress and IsValid(ply)) then
		local update_type = net.ReadUInt(3)

		if (update_type == MapVotePools.UPDATE_VOTE) then
			local map_id = net.ReadUInt(32)

			if (MapVotePools.CurrentMaps[map_id]) then
				MapVotePools.Votes[ply:SteamID()] = map_id

				net.Start("MVP_MapVotePoolsUpdate")
					net.WriteUInt(MapVotePools.UPDATE_VOTE, 3)
					net.WriteEntity(ply)
					net.WriteUInt(map_id, 32)
				net.Broadcast()

				--@DEBUG please remove this
				if true then
					for _, uply in pairs(player.GetAll()) do
						net.Start("MVP_MapVotePoolsUpdate")
							net.WriteUInt(MapVotePools.UPDATE_VOTE, 3)
							net.WriteEntity(uply)
							net.WriteUInt(map_id, 32)
						net.Broadcast()
					end
				end
			end
		end
	end
end)

function MapVotePools.ServerInit()
	if not file.Exists( "mapvotepools", "DATA") then
		file.CreateDir( "mapvotepools" )
	end

	if not file.Exists( "mapvotepools/mapconfig.txt", "DATA" ) then
		file.Write( "mapvotepools/mapconfig.txt", util.TableToJSON( {}, true ) )
	end
	if not file.Exists( "mapvotepools/mapstats.txt", "DATA" ) then
		file.Write( "mapvotepools/mapstats.txt", util.TableToJSON( {}, true ) )
	end

	if file.Exists( "mapvotepools/mapconfig.txt", "DATA" ) then
		MapVotePools.Data.MapConfig = util.JSONToTable(file.Read("mapvotepools/mapconfig.txt", "DATA"))
	else
		MapVotePools.Data.MapConfig = {}
	end

	if file.Exists( "mapvotepools/mapstats.txt", "DATA" ) then
		MapVotePools.Data.MapStats = util.JSONToTable(file.Read("mapvotepools/mapstats.txt", "DATA"))
	else
		MapVotePools.Data.MapStats = {}
	end

	if file.Exists( "mapvotepools/recentmaps.txt", "DATA" ) then
		MapVotePools.Data.RecentMaps = util.JSONToTable(file.Read("mapvotepools/recentmaps.txt", "DATA"))
	else
		MapVotePools.Data.RecentMaps = {}
	end
end

function MapVotePools.DetermineGameMode(map)
	-- check if map matches a gamemode's map pattern
	for k, gm in pairs(engine.GetGamemodes()) do
		-- ignore empty patterns
		if (gm.maps and gm.maps ~= "") then
			-- patterns are separated by "|"
			for k2, pattern in pairs(string.Split(gm.maps, "|")) do
				if (string.match(map, pattern)) then
					return gm.name
				end
			end
		end
	end
end

function MapVotePools.CoolDownDoStuff()
	local cooldownnum = MapVotePools.CVARS.maps_before_revote:GetInt()

	while (#MapVotePools.Data.RecentMaps >= cooldownnum) do
		table.remove(MapVotePools.Data.RecentMaps)
	end

	local curmap = MapVotePools.GetMapData(game.GetMap())

	if not table.HasValue(MapVotePools.Data.RecentMaps, curmap.name) then
		table.insert(MapVotePools.Data.RecentMaps, 1, curmap.name)
	end

	MapVotePools.WriteData()
end

function MapVotePools.PlainMapList(prefix)
	prefix = prefix or MapVotePools.CVARS.map_prefixes:GetString()
	local is_expression = false

	if not prefix then
		local info = file.Read(GAMEMODE.Folder .. "/" .. GAMEMODE.FolderName .. ".txt", "GAME")

		if (info) then
			local _info = util.KeyValuesToTable(info)
			prefix = _info.maps
		else
			error("MapVotePools Prefix can not be loaded from gamemode")
		end

		is_expression = true
	else
		if prefix and type(prefix) ~= "table" then
			prefix = string.Split(prefix, "|")
		end
	end
	local whitelist = string.Split(MapVotePools.CVARS.map_whitelist:GetString(), "|")
	local blacklist = string.Split(MapVotePools.CVARS.map_blacklist:GetString(), "|")

	local maps = file.Find("maps/*.bsp", "GAME")
	-- table.sort( maps ) -- there's really no reason to sort this right here but it brings me peace

	local plain_maps = {}
	for _, map_path in pairs(maps) do
		local map_name = MapVotePools.NormalizeMapName(map_path)

		-- eliminate via strict filtering, this determines the effective map pool
		if MapVotePools.CVARS.map_blacklist_enabled:GetBool() and table.HasValue(blacklist, map_name) then continue end
		if MapVotePools.CVARS.map_whitelist_enabled:GetBool() and not table.HasValue(whitelist, map_name) then continue end
		if is_expression and not string.find(map_name, prefix) then
			continue
		else
			local found = false
			for _, v in pairs(prefix) do
				if string.find(map_name, "^" .. v) then
					found = true
				end
			end
			if not found then continue end
		end

		-- map wasn't filtered, we are good
		table.insert(plain_maps, map_name)
	end
	table.sort( plain_maps )

	return plain_maps
end

function MapVotePools.CollectMaps(prefix, current, limit)
	current = current or MapVotePools.CVARS.allow_current_map:GetBool()
	limit = limit or MapVotePools.CVARS.map_limit:GetInt()

	local cooldown = MapVotePools.CVARS.enable_cooldown:GetBool()
	local autoGamemode = autoGamemode or MapVotePools.CVARS.auto_gamemode:GetBool()

	local maps = MapVotePools.PlainMapList(prefix)

	local this_map = MapVotePools.GetMapData( game.GetMap() )
	-- local spawns = plyspawn.GetPlayerSpawnPoints()

	-- local map_meta = MapVotePools.GetMapData(this_map)
	-- update metadata
	-- map_meta.stats.SpawnPoints = #spawns

	local num_players = player.GetCount()
	local max_players = game.MaxPlayers()
	local bonus = MapVotePools.CVAR.WEIGHT_BONUSES

	local scored_maps = {}
	local scored_map_index = {}

	for _, map_path in RandomPairs(maps) do
		local map = MapVotePools.GetMapData(map_path)
		map.score = 0

		-- eliminate via temporal preferences
		if (not current and this_map.name == map.name) then continue end
		if (cooldown and table.HasValue(MapVotePools.Data.RecentMaps, map.name)) then continue end
		-- if (MapVotePools.MapData[map] and MapVotePools.MapData[map].SpawnPoints > 0) then continue end

		-- @TODO: delete, debug only
		-- map = table.Copy(map or {})
		local c = map.config
		-- c.MinPlayers = math.random(1,max_players)
		-- c.MaxPlayers = math.random(c.MinPlayers,max_players)

		local delta_low  = 0
		local delta_high = 0
		local delta = 0
		-- @TODO: implement tracking this stat
		if map.stats.LifetimeSessionStarts <= 0 then
			map.score = map.score + bonus.uninducted
		else
			if c.MinPlayers > 0 and num_players < c.MinPlayers then
				delta_low  = c.MinPlayers - num_players
			end
			if c.MaxPlayers > 0 and num_players > c.MaxPlayers then
				delta_high = max_players - c.MaxPlayers
			end
			delta = math.max(delta_low, delta_high)

			map.score = map.score + (bonus.map_too_big * delta_low)
			map.score = map.score + (bonus.insufficient_spawns * delta_high)
		end

		-- nomination bonus
		if MapVotePools.Nominate.MapNominationCounts[ map.name ] then
			map.score = map.score + (bonus.nomination_value * MapVotePools.Nominate.MapNominationCounts[ map.name ])
		end

		scored_map_index[map.name] = map
		table.insert(scored_maps, map)
	end

	local vote_maps = {}
	local vote_map_index = {}

	if not MapVotePools.CVARS.skip_sort:GetBool() then
		table.sort( scored_maps, function(a, b) return a.score > b.score end )
	else
		-- we only need to override the maps if there is no nomination bonus score
		MapVotePools.HandleNominationsOverrides(scored_map_index, vote_maps, vote_map_index, limit)
	end

	for _, map in pairs(scored_maps) do
		-- if the nomination step already got to this map, skip it
		if vote_map_index[map.name] then continue end
		vote_maps[#vote_maps + 1] = map
		vote_map_index[map.name] = true
		if (limit and #vote_maps >= limit) then break end
	end

	return vote_maps
end

function MapVotePools.HandleNominationsOverrides(scored_map_index, vote_maps, vote_map_index, limit)
	local _, nominations = MapVotePools.Nominate.TotalNominations()

	-- ensure the ones with the most suggestions get priority
	local sorted_nominations = table.SortByKey(nominations)
	for _, nomination_name in ipairs(sorted_nominations) do
		vote_maps[#vote_maps + 1] = scored_map_index[nomination_name]
		vote_map_index[nomination_name] = true
		if (limit and #vote_maps >= limit) then break end
	end

	-- literally what was i smoking
	--[[
	local i = 1
	for _, nominated_map in pairs(nominations) do
		if scored_map_index[nominated_map] then
			if not vote_map_index[nominated_map] then
				print(
					i,
					"replacing",
					vote_maps[i].name,
					"with",
					nominated_map
				)
				vote_maps[i] = scored_map_index[nominated_map]
				vote_map_index[ vote_maps[i].name ] = nil
				vote_map_index[ nominated_map ] = true
				i = i + 1
			else
				print(
					i,
					"not replacing, nominated map rolled naturally:",
					vote_maps[i].name
				)
			end
		else
			print(
				i,
				"did not nominate map because it did not exist",
				nominated_map
			)
		end
	end
	]]
end

function MapVotePools.Cancel()
	if MapVotePools.InProgress then
		MapVotePools.InProgress = false

		net.Start("MVP_MapVotePoolsCancel")
		net.Broadcast()

		timer.Remove("MVP_MapVotePools")
	end
end

function MapVotePools.Start(length, current, limit, prefix, callback)
	length = length or MapVotePools.CVARS.time_limit:GetInt()
	local vote_maps = MapVotePools.CollectMaps(prefix, current, limit)

	local map_count = #vote_maps
	-- print(map_count, "maps to choose from")

	-- PrintTable(vote_maps)
	net.Start("MVP_MapVotePoolsStart")
		net.WriteUInt(map_count, 32)

		for i = 1, map_count do
			-- print(i, "index")
			local voted_map = vote_maps[i]

			net.WriteString(voted_map.name)
			net.WriteUInt(voted_map.config.MinPlayers, 32)
			net.WriteUInt(voted_map.config.MaxPlayers, 32)
			net.WriteUInt(voted_map.stats.SpawnPoints, 32)
		end

		net.WriteUInt(length, 32)
	net.Broadcast()

	MapVotePools.InProgress = true
	MapVotePools.CurrentMaps = vote_maps
	MapVotePools.Votes = {}

	-- FEATURE: Anti-BlueBalls
	if GAMEMODE_NAME == "terrortown" then
		timer.Stop("wait2prep")
		timer.Stop("prep2begin")
		timer.Stop("end2prep")
		timer.Stop("winchecker")
	end

	timer.Create("MVP_MapVotePools", length, 1, function()
		MapVotePools.InProgress = false
		local map_results = {}

		for k, v in pairs(MapVotePools.Votes) do
			if (not map_results[v]) then
				map_results[v] = 0
			end

			for k2, v2 in pairs(player.GetAll()) do
				if (v2:SteamID() == k) then
					if (MapVotePools.HasExtraVotePower(v2)) then
						map_results[v] = map_results[v] + 2
					else
						map_results[v] = map_results[v] + 1
					end
				end
			end
		end

		MapVotePools.CoolDownDoStuff()

		local winner = table.GetWinningKey(map_results) or 1

		net.Start("MVP_MapVotePoolsUpdate")
			net.WriteUInt(MapVotePools.UPDATE_WIN, 3)

			net.WriteUInt(winner, 32)
		net.Broadcast()

		local map = MapVotePools.CurrentMaps[winner].name

		local newGamemode = nil

		if autoGamemode then
			newGamemode = MapVotePools.DetermineGameMode(map)
		end

		timer.Simple(4, function()
			if (hook.Run("MapVotePoolsChange", map) ~= false) then
				if (callback) then
					callback(map)
				else
					-- if map requires another gamemode then switch to it
					if (newGamemode and newGamemode ~= engine.ActiveGamemode()) then
						RunConsoleCommand("gamemode", newGamemode)
					end
					RunConsoleCommand("changelevel", map)
				end
			end
		end)
	end)
end

hook.Add( "Initialize", "MapVotePoolsConfigSetup", function()
	MapVotePools.ServerInit()
end )

hook.Add( "Shutdown", "RemoveRecentMaps", function()
	if file.Exists( "mapvotepools/recentmaps.txt", "DATA" ) then
		file.Delete( "mapvotepools/recentmaps.txt" )
	end
end )