MapVotePools.RTV.Wipe = function()
	MapVotePools.RTV._WillBeRocked = false
	MapVotePools.RTV._Loaded = CurTime()
	MapVotePools.RTV.PlayersRequestedRocking = {}
end
MapVotePools.RTV.Wipe()


function MapVotePools.RTV.TotalRockingRequests()
	local sum = 0
	for steam64, vote in pairs(MapVotePools.RTV.PlayersRequestedRocking) do
		if vote then
			sum = sum + 1
		end
	end
	return sum
end

function MapVotePools.RTV.GetRockingGoal()
	return math.max(1,math.Round(player.GetCount() * MapVotePools.CVARS.rtv_ratio:GetFloat() ))
end

function MapVotePools.RTV.WillBeRocked()
	local thing = MapVotePools.RTV.TotalRockingRequests()
	local goal = MapVotePools.RTV.GetRockingGoal()
	local cond = thing >= goal
	MapVotePools.RTV._WillBeRocked = cond
	return cond
end

function MapVotePools.RTV.GetRockingRatioString()
	return "(" .. MapVotePools.RTV.TotalRockingRequests() .. "/" .. MapVotePools.RTV.GetRockingGoal() .. ")"
end

function MapVotePools.RTV.CanVote( ply )
	local plyCount = player.GetCount()

	if (MapVotePools.RTV._Loaded + MapVotePools.CVARS.rtv_wait:GetFloat()) >= CurTime() then
		return false, "You must wait a bit before voting!"
	end

	if GetGlobalBool( "In_Voting" ) then
		return false, "There is currently a vote in progress!"
	end

	if ply.RTVoted then
		return false, "You have already voted to Rock the Vote!"
	end

	if MapVotePools.RTV.ChangingMaps then
		return false, "There has already been a vote, the map is going to change!"
	end
	if plyCount < MapVotePools.CVARS.rtv_player_count:GetInt() then
		return false, "You need more players before you can rock the vote!"
	end

	return true
end

function MapVotePools.RTV.SetClientRockingStatus(ply, desired_rocking)
	MapVotePools.RTV.PlayersRequestedRocking[ ply:SteamID64() ] = desired_rocking
	MapVotePools.RTV.ProcessRockingRequests()
end

-- @TODO: localize
function MapVotePools.RTV.CanClientChangeRockingRequest(ply, desired_rocking)
	local plyCount = player.GetCount()
	if desired_rocking then
		if (MapVotePools.RTV._Loaded + MapVotePools.CVARS.rtv_wait:GetFloat()) >= CurTime() then
			return false, "You must wait a bit before rocking!"
		end

		if MapVotePools.RTV.PlayersRequestedRocking[ ply:SteamID64() ] then
			return false, "You have already requested rocking!"
		end

		if plyCount < MapVotePools.CVARS.rtv_player_count:GetInt() then
			return false, "Not enough players to begin rocking!"
		end

		-- if GetGlobalBool( "In_Voting" ) then
		-- 	return false, "There is currently a vote in progress!"
		-- end

		-- if MapVotePools.RTV.ChangingMaps then
		-- 	return false, "There has already been a vote, the map is going to change!"
		-- end

		-- if MapVotePools.InProgress then
		-- 	return false, "There is a ballot in progress, you can't rock now!"
		-- end
		return true
	else
		-- if (MapVotePools.RTV._Loaded + MapVotePools.CVARS.rtv_wait:GetFloat()) >= CurTime() then
		-- 	return false, "You must wait a bit before unrocking!"
		-- end

		if not MapVotePools.RTV.PlayersRequestedRocking[ ply:SteamID64() ] then
			return false, "You have not yet requested rocking!"
		end

		-- if plyCount < MapVotePools.CVARS.rtv_player_count:GetInt() then
		-- 	return false, "Not enough players to begin unrocking!"
		-- end

		-- if not GetGlobalBool( "In_Voting" ) then
			-- return false, "There is currently a ballot in progress, you can't unrock now!"
		-- end

		-- if MapVotePools.RTV.ChangingMaps then
		-- 	return false, "There has already been a ballot, the map is already going to change!"
		-- end

		if MapVotePools.InProgress then
			return false, "There is a ballot in progress, you can't unrock now!"
		end

		return true
	end
end

function MapVotePools.RTV.HandleClientRockingRequest(ply, desired_rocking)
	local can, err = MapVotePools.RTV.CanClientChangeRockingRequest(ply, desired_rocking)

	if not can then
		ply:PrintMessage( HUD_PRINTTALK, err .. " " .. MapVotePools.RTV.GetRockingRatioString() )
		return
	end

	MapVotePools.RTV.SetClientRockingStatus( ply, desired_rocking )

	-- @TODO: localize
	local say_all = ply:Nick()
	if desired_rocking then
		say_all = say_all .. " has requested rocking. Type \"!rtv\" to join. "
	else
		say_all = say_all .. " has unrequested rocking. Wack! "
	end
	PrintMessage( HUD_PRINTTALK, say_all .. " " .. MapVotePools.RTV.GetRockingRatioString() )
end

function MapVotePools.RTV.ProcessRockingRequests()
	local was = MapVotePools.RTV._WillBeRocked
	local now = MapVotePools.RTV.WillBeRocked()

	if not was and now then
		MapVotePools.RTV.QueueBallot()
	end

	if was and not now then
		MapVotePools.RTV.UnqueueBallot()
	end
end

function MapVotePools.RTV.QueueBallot()
	if GAMEMODE_NAME == "terrortown" then
		net.Start("MVP_RTV_Delay")
		net.Broadcast()

		hook.Add("TTTEndRound", "MapVotePoolsDelayed", function()
			MapVotePools.Start(nil, nil, nil, nil)
		end)
	-- elseif GAMEMODE_NAME == "deathrun" then
	-- 	net.Start("MVP_RTV_Delay")
	-- 	net.Broadcast()

	-- 	hook.Add("RoundEnd", "MapVotePoolsDelayed", function()
	-- 		MapVotePools.Start(nil, nil, nil, nil)
	-- 	end)
	-- else
	-- 	PrintMessage( HUD_PRINTTALK, "The vote has been rocked, map vote imminent")
	-- 	timer.Simple(4, function()
	-- 		MapVotePools.Start(nil, nil, nil, nil)
	-- 	end)
	end
end

function MapVotePools.RTV.UnqueueBallot()
	if GAMEMODE_NAME == "terrortown" then
		net.Start("MVP_UNRTV_Delay")
		net.Broadcast()

		hook.Remove("TTTEndRound", "MapVotePoolsDelayed")
		-- MapVotePools.Cancel()

	-- elseif GAMEMODE_NAME == "deathrun" then
	-- 	net.Start("MVP_RTV_Delay")
	-- 	net.Broadcast()

	-- 	hook.Add("RoundEnd", "MapVotePoolsDelayed", function()
	-- 		MapVotePools.Cancel(nil, nil, nil, nil)
	-- 	end)
	-- else
	-- 	PrintMessage( HUD_PRINTTALK, "The vote has been rocked, map vote imminent")
	-- 	timer.Simple(4, function()
	-- 		MapVotePools.Start(nil, nil, nil, nil)
	-- 	end)
	end
end

--region network
util.AddNetworkString("MVP_ClientRequestRocking")
util.AddNetworkString("MVP_ClientUnrequestRocking")

net.Receive( "MVP_ClientRequestRocking", function (len, ply)
	MapVotePools.RTV.HandleClientRockingRequest(ply, true)
	print("rtv")
end )

net.Receive( "MVP_ClientUnrequestRocking", function (len, ply)
	MapVotePools.RTV.HandleClientRockingRequest(ply, false)
	print("unrtv")
end )
--endregion network


--region hooks
hook.Remove( "PlayerDisconnected", "MVP_PlayerDisconnected")
hook.Add( "PlayerDisconnected", "MVP_PlayerDisconnected", function( ply )
	MapVotePools.RTV.HandleClientRockingRequest(ply, false)
end )

if MapVotePools.CVARS.use_chat_commands:GetBool() then
	hook.Remove( "PlayerSay", "MPV_PlayerSay" )
	hook.Add( "PlayerSay", "MPV_PlayerSay", function( ply, text )
		if table.HasValue( MapVotePools.RTV.RequestRockingChatCommands, string.lower(text) ) then
			MapVotePools.RTV.HandleClientRockingRequest(ply, true)
			return ""
		end

		if table.HasValue( MapVotePools.RTV.UnrequestRockingChatCommands, string.lower(text) ) then
			MapVotePools.RTV.HandleClientRockingRequest(ply, false)
			return ""
		end
	end )
end
--endregion hooks

