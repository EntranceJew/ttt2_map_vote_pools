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

MapVotePools.FileCache = MapVotePools.FileCache or {}
MapVotePools.MapCache = MapVotePools.MapCache or {}

function MapVotePools.MakeDirs(path)
	local p = string.match(path, "(.-)([^\\/]-%.?([^%.\\/]*))$")
	if (not file.Exists(p, "DATA")) then
		file.CreateDir(p)
	end
end

function MapVotePools.WriteFile(write_file, default_data)
	write_file = "mapvotepools/" .. write_file
	MapVotePools.MakeDirs( write_file )

	local write_data = MapVotePools.ReadFile(write_file, default_data) or {}
	table.Merge(default_data or {}, write_data)
	file.Write(write_file, util.TableToJSON( write_data, true ))
end

function MapVotePools.ReadFile(read_file, default_data)
	read_file = "mapvotepools/" .. read_file

	if MapVotePools.FileCache[ read_file ] ~= nil then
		return MapVotePools.FileCache[ read_file ]
	end
	if file.Exists(read_file, "DATA") then
		local datum = table.Merge( default_data or {}, util.JSONToTable( file.Read(read_file, "DATA")  or "{}" ) or {} )
		MapVotePools.FileCache[ read_file ] = datum
	end
	return default_data
end

function MapVotePools.FlushCacheToDisk()
	-- print("flushing!!!")
	-- PrintTable(MapVotePools.MapCache)
	-- PrintTable(MapVotePools.FileCache)
	for file_name, file_data in pairs(MapVotePools.FileCache) do
		file.Write(file_name, util.TableToJSON( file_data, true ))
	end
end

function MapVotePools.CurrentMap()
	return MapVotePools.GetMapData( game.GetMap() )
end

function MapVotePools.GetMapData( map_name )
	map_name = MapVotePools.NormalizeMapName(map_name)
	if MapVotePools.MapCache[map_name] ~= nil then
		return MapVotePools.MapCache[map_name]
	end
	local datum = {}

	datum.name = map_name
	datum.stats = MapVotePools.ReadFile("maps/" .. map_name .. "/statistics.json", {
		SpawnPoints = 0,

		LifetimeNominations = 0,
		LifetimeTallies = 0,
		LifetimeVoteWins = 0,
		LifetimeRoundsPlayed = 0,
		LifetimeSessionStarts = 0,
		LifetimeSessionsCompleted = 0,

		LifetimeRTVAttempted = 0,
	})
	datum.config = MapVotePools.ReadFile("maps/" .. map_name .. "/config.json", {
		MinPlayers = 0,
		MaxPlayers = 0,
	})
	if datum.config.SpawnPoints ~= nil then
		datum.stats.SpawnPoints = datum.config.SpawnPoints
		datum.config.SpawnPoints = nil
	end
	MapVotePools.MapCache[ map_name ] = datum
	return datum
end

function MapVotePools.RecordStat(stat_name, delta, map_name)
	local the_map
	if map_name == nil then
		the_map = MapVotePools.CurrentMap()
	else
		the_map = MapVotePools.GetMapData( map_name )
	end
	the_map.stats[ stat_name ] = (the_map.stats[ stat_name ] or 0) + delta
	-- print("writing stat", stat_name, "for map", the_map.name, "to value", the_map.stats[ stat_name ])
	MapVotePools.WriteFile("maps/" .. the_map.name .. "/statistics.json", the_map.stats)
end

net.Receive("MVP_AdminRequestMapData", function(len, ply)
	local map_data = MapVotePools.CurrentMap()
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
	MapVotePools.WriteFile("maps/" .. map.name .. "/config.json", map.config)
end)

net.Receive("MVP_MapVotePoolsUpdate", function(len, ply)
	if (MapVotePools.InProgress and IsValid(ply)) then
		local update_type = net.ReadUInt(3)

		if (update_type == MapVotePools.UPDATE_VOTE) then
			local map_id = net.ReadUInt(32)

			if (MapVotePools.ServerCurrentMaps[map_id]) then
				MapVotePools.Votes[ply:SteamID()] = map_id

				net.Start("MVP_MapVotePoolsUpdate")
					net.WriteUInt(MapVotePools.UPDATE_VOTE, 3)
					net.WriteEntity(ply)
					net.WriteUInt(map_id, 32)
				net.Broadcast()

				if MapVotePools.CVARS.debug:GetBool() and MapVotePools.CVARS.bots_follow_vote_lead:GetBool() then
					for _, uply in pairs(player.GetBots()) do
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

function MapVotePools.SyncWhitelist(new_value)
	if not MapVotePools.CVARS.sync_with_rsm:GetBool() then return end
	local cvar = GetConVar("rsm_map_whitelist")
	if cvar ~= nil then
		cvar:SetString( table.concat(string.Split(new_value, "|"), ",") )
	end
end
function MapVotePools.SyncBlacklist(new_value)
	if not MapVotePools.CVARS.sync_with_rsm:GetBool() then return end
	local cvar = GetConVar("rsm_map_blacklist")
	if cvar ~= nil then
		cvar:SetString( table.concat(string.Split(new_value, "|"), ",") )
	end
end

function MapVotePools.SetupRSMSync()
	cvars.AddChangeCallback("sv_mvp_map_prefixes", function(_,_,n)
		if not MapVotePools.CVARS.sync_with_rsm:GetBool() then return end
		local cvar = GetConVar("rsm_map_prefixes")
		if cvar ~= nil then
			cvar:SetString( table.concat(string.Split(n, "|"), ",") )
		end
	end, "mvp_rsm_sync")
	cvars.AddChangeCallback("sv_mvp_map_whitelist_enabled", function(_,_,n)
		if tonumber(n) == 1 then
			MapVotePools.SyncWhitelist(MapVotePools.CVARS.map_whitelist:GetString())
		elseif tonumber(n) == 0 then
			MapVotePools.SyncWhitelist("")
		end
	end, "mvp_rsm_sync")
	cvars.AddChangeCallback("sv_mvp_map_whitelist", function(_,_,n)
		if not MapVotePools.CVARS.sync_with_rsm:GetBool() then return end
		MapVotePools.SyncWhitelist(n)
	end, "mvp_rsm_sync")
	cvars.AddChangeCallback("sv_mvp_map_blacklist_enabled", function(_,_,n)
		if tonumber(n) == 1 then
			MapVotePools.SyncBlacklist(MapVotePools.CVARS.map_blacklist:GetString())
		elseif tonumber(n) == 0 then
			MapVotePools.SyncBlacklist("")
		end
	end, "mvp_rsm_sync")
	cvars.AddChangeCallback("sv_mvp_map_blacklist", function(_,_,n)
		if not MapVotePools.CVARS.sync_with_rsm:GetBool() then return end
		MapVotePools.SyncBlacklist(n)
	end, "mvp_rsm_sync")
end
MapVotePools.FirstRoundLatch = true
function MapVotePools.SetupStatHooks()
	hook.Add("TTTPrepareRound", "MVP_TTTPrepareRound", function()
		if MapVotePools.FirstRoundLatch then
			MapVotePools.FirstRoundLatch = false
			MapVotePools.RecordStat("LifetimeSessionStarts", 1)
		end
	end)
	hook.Add("TTT2LoadNextMap", "MVP_TTT2LoadNextMap", function()
		MapVotePools.RecordStat("LifetimeSessionsCompleted", 1)
	end)

	hook.Add("TTTBeginRound", "MVP_TTTBeginRound", function()
		MapVotePools.RecordStat("LifetimeRoundsBegan", 1)
	end)
	hook.Add("TTTEndRound", "MVP_TTTEndRound", function()
		MapVotePools.RecordStat("LifetimeRoundsPlayed", 1)
	end)
end

function MapVotePools.MigrateFiles()
	-- initial version
	local attempt_file = "mapvotepools/config.txt"
	if file.Exists( attempt_file, "DATA" ) then
		local config = util.JSONToTable( file.Read(attempt_file, "DATA") or "{}" )

		if config.RTVPlayerCount ~= MapVotePools.CVARS.rtv_player_count:GetInt() then
			MapVotePools.CVARS.rtv_player_count:SetInt(config.RTVPlayerCount)
		end
		if config.MapLimit ~= MapVotePools.CVARS.map_limit:GetInt() then
			MapVotePools.CVARS.map_limit:SetInt(config.MapLimit)
		end
		if config.TimeLimit ~= MapVotePools.CVARS.time_limit:GetInt() then
			MapVotePools.CVARS.time_limit:SetInt(config.TimeLimit)
		end
		if config.AllowCurrentMap ~= MapVotePools.CVARS.allow_current_map:GetBool() then
			MapVotePools.CVARS.allow_current_map:SetBool(config.AllowCurrentMap)
		end
		if config.MapsBeforeRevote ~= MapVotePools.CVARS.maps_before_revote:GetInt() then
			MapVotePools.CVARS.maps_before_revote:SetInt(config.MapsBeforeRevote)
		end
		if config.EnableCooldown ~= MapVotePools.CVARS.enable_cooldown:GetBool() then
			MapVotePools.CVARS.enable_cooldown:SetBool(config.EnableCooldown)
		end
		if config.SkipSort ~= MapVotePools.CVARS.skip_sort:GetBool() then
			MapVotePools.CVARS.skip_sort:SetBool(config.SkipSort)
		end
		if table.concat(config.MapPrefixes, "|") ~= MapVotePools.CVARS.map_prefixes:GetString() then
			MapVotePools.CVARS.map_prefixes:SetString( table.concat(config.MapPrefixes, "|") )
		end

		file.Delete( attempt_file, "DATA" )
	end

	-- 18.09.23 - folder_based
	attempt_file = "mapvotepools/mapconfig.txt"

	if file.Exists( attempt_file, "DATA" ) then
		local map_config = util.JSONToTable( file.Read( attempt_file, "DATA") or "{}" )
		for map_name, config in pairs( map_config ) do
			MapVotePools.WriteFile( "maps/" .. map_name .. "/config.json", config )
		end
		file.Delete( attempt_file, "DATA" )
	end

	attempt_file = "mapvotepools/mapstats.txt"

	if file.Exists( attempt_file, "DATA" ) then
		local mapstats = util.JSONToTable( file.Read( attempt_file, "DATA") or "{}" )
		for map_name, stats in pairs( mapstats ) do
			MapVotePools.WriteFile( "maps/" .. map_name .. "/statistics.json", stats )
		end
		file.Delete( attempt_file, "DATA" )
	end

	attempt_file = "mapvotepools/recentmaps.txt"

	if file.Exists( attempt_file, "DATA" ) then
		local recentmaps = util.JSONToTable( file.Read(attempt_file, "DATA") or "[]" )
		MapVotePools.WriteFile( "recent_maps.json", recentmaps )
		file.Delete( attempt_file, "DATA" )
	end
end

function MapVotePools.ServerInit()
	MapVotePools.SetupStatHooks()
	MapVotePools.MigrateFiles()
	MapVotePools.SetupRSMSync()
end

function MapVotePools.DetermineGameMode(map_name)
	-- check if map matches a gamemode's map pattern
	for _, gm in pairs(engine.GetGamemodes()) do
		-- ignore empty patterns
		if (gm.maps and gm.maps ~= "") then
			-- patterns are separated by "|"
			for _, pattern in pairs(string.Split(gm.maps, "|")) do
				if (string.match(map_name, pattern)) then
					return gm.name
				end
			end
		end
	end
end

function MapVotePools.CoolDownDoStuff()
	local recent_maps = MapVotePools.ReadFile("recent_maps.json", {})
	-- PrintTable(recent_maps)
	while (#recent_maps > (MapVotePools.CVARS.maps_before_revote:GetInt() or 0)) do
		table.remove(recent_maps)
	end

	local curmap = MapVotePools.CurrentMap()

	if not table.HasValue(recent_maps, curmap.name) then
		table.insert(recent_maps, 1, curmap.name)
	end

	MapVotePools.WriteFile("recent_maps.json", recent_maps)
	-- MapVotePools.FlushCacheToDisk()
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

local MapCloneSetScore = function(self, score_change, reason)
	local init_score = (self.score or 0)
	self.score = init_score + score_change
	-- if self.score ~= init_score then
	-- 	print(self.name, "changed score from", init_score, "to", self.score, "(" .. (score_change > 0 and "+" or "") .. score_change .. ") because", reason)
	-- end
end
function MapVotePools.CollectMaps(prefix, current, limit)
	current = current or MapVotePools.CVARS.allow_current_map:GetBool()
	limit = limit or MapVotePools.CVARS.map_limit:GetInt()

	local cooldown_stopall = MapVotePools.CVARS.enable_cooldown:GetBool() and not MapVotePools.CVARS.cooldown_use_penalty:GetBool()
	local cooldown_penalty = MapVotePools.CVARS.enable_cooldown:GetBool() and MapVotePools.CVARS.cooldown_use_penalty:GetBool()

	local maps = MapVotePools.PlainMapList(prefix)

	local this_map = MapVotePools.CurrentMap()
	-- local spawns = plyspawn.GetPlayerSpawnPoints()

	-- local map_meta = MapVotePools.GetMapData(this_map)
	-- update metadata
	-- map_meta.stats.SpawnPoints = #spawns

	local num_players = player.GetCount()
	local max_players = game.MaxPlayers()

	local scored_maps = {}
	local scored_map_index = {}

	local cooldown_file = MapVotePools.ReadFile("recent_maps.json", {})
	local cooldown_counts = {}
	if cooldown_penalty then
		for _, map_name in ipairs(cooldown_file) do
			cooldown_counts[map_name] = (cooldown_counts[map_name] or 0) + 1
		end
	end

	for _, map_path in RandomPairs(maps) do
		local map = table.Copy( MapVotePools.GetMapData(map_path) )
		map.SetScore = MapCloneSetScore
		map:SetScore(0, "init")

		-- eliminate via temporal preferences
		if (not current and this_map.name == map.name) then continue end
		if (cooldown_stopall and table.HasValue(cooldown_file, map.name)) then continue end
		-- if (MapVotePools.MapData[map] and MapVotePools.MapData[map].SpawnPoints > 0) then continue end

		if cooldown_penalty then
			map:SetScore((cooldown_counts[map.name] or 0) * MapVotePools.CVARS.score_cooldown_penalty:GetInt(), "cooldown_penalty")
		end

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
			map:SetScore(MapVotePools.CVARS.score_uninducted:GetInt(), "uninducted")
		else
			map:SetScore( ( map.stats.LifetimeSessionStarts or 0 ) * MapVotePools.CVARS.score_play_count_penalty:GetInt(), "play_count_penalty" )
		end
		if c.MinPlayers > 0 and num_players < c.MinPlayers then
			delta_low  = c.MinPlayers - num_players
		end
		if c.MaxPlayers > 0 and num_players > c.MaxPlayers then
			delta_high = max_players - c.MaxPlayers
		end
		delta = math.max(delta_low, delta_high)

		map:SetScore(MapVotePools.CVARS.score_map_too_big:GetInt() * ( delta_low or 0 ), "map_too_big")
		map:SetScore(MapVotePools.CVARS.score_insufficient_spawns:GetInt() * ( delta_high or 0 ), "insufficient_spawns")
		-- print("delta debug", map.name, map.stats.LifetimeSessionStarts, delta_low, delta_high, delta, c.MinPlayers, c.MaxPlayers)

		-- nomination bonus
		local nomination_count = MapVotePools.Nominate.MapNominationCounts[ map.name ]
		if nomination_count then
			map:SetScore( MapVotePools.CVARS.score_nomination_value:GetInt() * (nomination_count or 0), "nomination_value" )
			MapVotePools.RecordStat("LifetimeNominations", nomination_count, map.name)
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
	-- print("this shouldn't be on")
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

	MapVotePools.ServerCurrentMaps = {}

	net.Start("MVP_MapVotePoolsStart")
		net.WriteUInt(map_count, 32)

		for i = 1, map_count do
			local voted_map = vote_maps[i]
			MapVotePools.ServerCurrentMaps[i] = voted_map.name
			-- print(i, voted_map.name, voted_map.score)
			net.WriteString(voted_map.name)
			net.WriteUInt(voted_map.config.MinPlayers, 32)
			net.WriteUInt(voted_map.config.MaxPlayers, 32)
			net.WriteUInt(voted_map.stats.SpawnPoints, 32)
		end

		net.WriteUInt(length, 32)
	net.Broadcast()

	MapVotePools.InProgress = true
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

		-- PrintTable(MapVotePools.ServerCurrentMaps)
		-- PrintTable(MapVotePools.Votes)
		-- print("guhunka!!!")
		for voter_steam_id, map_id in pairs(MapVotePools.Votes) do
			for _, ply in pairs(player.GetAll()) do
				if (ply:SteamID() == voter_steam_id) then
					map_results[map_id] = (map_results[map_id] or 0) + MapVotePools.GetVotePower(ply)
				end
			end
		end
		-- PrintTable(map_results)
		-- print("nobunga!!!")

		local winner = table.GetWinningKey(map_results) or 1
		local winner_map_name = MapVotePools.ServerCurrentMaps[winner]
		MapVotePools.RecordStat("LifetimeVoteWins", 1, winner_map_name)

		net.Start("MVP_MapVotePoolsUpdate")
		net.WriteUInt(MapVotePools.UPDATE_WIN, 3)
		net.WriteUInt(winner, 32)
		net.Broadcast()

		for map_index, votes in pairs(map_results) do
			MapVotePools.RecordStat("LifetimeTallies", votes, MapVotePools.ServerCurrentMaps[map_index])
		end

		MapVotePools.CoolDownDoStuff()

		local newGamemode = nil
		if MapVotePools.CVARS.auto_gamemode:GetBool() then
			newGamemode = MapVotePools.DetermineGameMode(winner_map_name)
		end

		timer.Simple(4, function()
			if (hook.Run("MapVotePoolsChange", winner_map_name) ~= false) then
				if (callback) then
					callback(winner_map_name)
				else
					-- if map requires another gamemode then switch to it
					if (newGamemode and newGamemode ~= engine.ActiveGamemode()) then
						RunConsoleCommand("gamemode", newGamemode)
					end
					RunConsoleCommand("changelevel", winner_map_name)
				end
			end
		end)
	end)
end

hook.Add( "Initialize", "MapVotePoolsConfigSetup", function()
	MapVotePools.ServerInit()
end )