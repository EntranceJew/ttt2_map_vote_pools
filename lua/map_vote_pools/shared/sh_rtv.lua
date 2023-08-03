-- if RTV then
-- 	print("[EJEW:] RTV already existed and that makes me greatly unhappy")
-- else
-- 	print("[EJEW:] RTV did not exist and that makes me greatly unhappy")
-- end
local RTV = RTV or {}


MapVotePools.RTV = RTV

MapVotePools.RTV.ChatCommandsVote = {
	"!rtv",
	"/rtv",
	"rtv"
}

MapVotePools.RTV.ChatCommandsUnvote = {
	"!unrtv",
	"/unrtv",
	"unrtv"
}

MapVotePools.RTV.TotalVotes = 0
MapVotePools.RTV._VoteWillPass = false

MapVotePools.RTV._Loaded = CurTime()

function MapVotePools.RTV.GetGoal()
	return math.Round(player.GetCount() * MapVotePools.CVARS.rtv_ratio:GetFloat() )
end

function MapVotePools.RTV.GetRatioString()
	return "(" .. MapVotePools.RTV.TotalVotes .. "/" .. MapVotePools.RTV.GetGoal() .. ")"
end

function MapVotePools.RTV.VoteWillPass()
	local thing = MapVotePools.RTV.TotalVotes
	local goal = MapVotePools.RTV.GetGoal()
	-- print("considering", thing, goal)
	local cond = thing >= goal
	MapVotePools.RTV._VoteWillPass = cond
	return cond
end



function MapVotePools.RTV.ProcessVotes()
	local was = MapVotePools.RTV._VoteWillPass
	local now = MapVotePools.RTV.VoteWillPass()

	if not was and now then
		MapVotePools.RTV.Start()
	end

	if was and not now then
		MapVotePools.RTV.Stop()
	end
end

function MapVotePools.RTV.Start()
	if GAMEMODE_NAME == "terrortown" then
		net.Start("MVP_RTV_Delay")
		net.Broadcast()

		hook.Add("TTTEndRound", "MapVotePoolsDelayed", function()
			MapVotePools.Start(nil, nil, nil, nil)
		end)
	elseif GAMEMODE_NAME == "deathrun" then
		net.Start("MVP_RTV_Delay")
		net.Broadcast()

		hook.Add("RoundEnd", "MapVotePoolsDelayed", function()
			MapVotePools.Start(nil, nil, nil, nil)
		end)
	else
		PrintMessage( HUD_PRINTTALK, "The vote has been rocked, map vote imminent")
		timer.Simple(4, function()
			MapVotePools.Start(nil, nil, nil, nil)
		end)
	end
end

function MapVotePools.RTV.Stop()
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

function MapVotePools.RTV.AddVote( ply )
	if MapVotePools.RTV.CanVote( ply ) then
		MapVotePools.RTV.TotalVotes = MapVotePools.RTV.TotalVotes + 1
		ply.RTVoted = true
		-- MsgN( ply:Nick() .. " has voted to Rock the Vote." )
		PrintMessage( HUD_PRINTTALK, ply:Nick() .. " has voted to Rock the Vote. " .. MapVotePools.RTV.GetRatioString()  )

		MapVotePools.RTV.ProcessVotes()
	end
end

function MapVotePools.RTV.RemoveVote( ply )
	if ply.RTVoted then
		MapVotePools.RTV.TotalVotes = math.Clamp( MapVotePools.RTV.TotalVotes - 1, 0, math.huge )
		ply.RTVoted = false
		-- MsgN( ply:Nick() .. " has unvoted. Wack!" )
		PrintMessage( HUD_PRINTTALK, ply:Nick() .. " has unvoted. Wack! " .. MapVotePools.RTV.GetRatioString()  )

		MapVotePools.RTV.ProcessVotes()
	end
end

hook.Remove( "PlayerDisconnected", "Remove RTV")
hook.Add( "PlayerDisconnected", "Remove RTV", function( ply )
	MapVotePools.RTV.RemoveVote(ply)

	timer.Simple( 0.1, function()
		MapVotePools.RTV.ProcessVotes()
	end )
end )

function MapVotePools.RTV.CanVote( ply )
	local plyCount = player.GetCount()

	if (MapVotePools.RTV._Loaded + MapVotePools.CVARS.rtv_wait:GetFloat()) >= CurTime() then
		return false, "You must wait a bit before voting! " .. MapVotePools.RTV.GetRatioString()
	end

	if GetGlobalBool( "In_Voting" ) then
		return false, "There is currently a vote in progress! " .. MapVotePools.RTV.GetRatioString()
	end

	if ply.RTVoted then
		return false, "You have already voted to Rock the Vote! " .. MapVotePools.RTV.GetRatioString()
	end

	if MapVotePools.RTV.ChangingMaps then
		return false, "There has already been a vote, the map is going to change! " .. MapVotePools.RTV.GetRatioString()
	end
	if plyCount < MapVotePools.CVARS.rtv_player_count:GetInt() then
		return false, "You need more players before you can rock the vote! " .. MapVotePools.RTV.GetRatioString()
	end

	return true

end

function MapVotePools.RTV.CanUnvote( ply )
	-- local plyCount = player.GetCount()

	-- if (MapVotePools.RTV._Loaded + MapVotePools.CVARS.rtv_wait:GetFloat()) >= CurTime() then
	-- 	return false, "You must wait a bit before unvoting! " .. MapVotePools.RTV.GetRatioString()
	-- end

	-- if not GetGlobalBool( "In_Voting" ) then
		-- return false, "There is currently a vote in progress! " .. MapVotePools.RTV.GetRatioString()
	-- end

	if not ply.RTVoted then
		return false, "You have not yet voted to Rock the Vote! " .. MapVotePools.RTV.GetRatioString()
	end

	if MapVotePools.RTV.ChangingMaps then
		return false, "There has already been a vote, the map is going to change! " .. MapVotePools.RTV.GetRatioString()
	end

	if MapVotePools.Allow then
		return false, "There is a vote in progress, your choice doesn't matter anymore! " .. MapVotePools.RTV.GetRatioString()
	end

	-- if plyCount < MapVotePools.CVARS.rtv_player_count:GetInt() then
	-- 	return false, "You need more players before you can rock the vote!" .. MapVotePools.RTV.GetRatioString()
	-- end

	return true

end

function MapVotePools.RTV.StartVote( ply )
	local can, err = MapVotePools.RTV.CanVote(ply)

	if not can then
		ply:PrintMessage( HUD_PRINTTALK, err )
		return
	end

	MapVotePools.RTV.AddVote( ply )

end

function MapVotePools.RTV.StopVote( ply )
	local can, err = MapVotePools.RTV.CanUnvote(ply)

	if not can then
		ply:PrintMessage( HUD_PRINTTALK, err )
		return
	end

	MapVotePools.RTV.RemoveVote( ply )

end

concommand.Add( "sh_mvp_rtv_vote", MapVotePools.RTV.StartVote )
concommand.Add( "sh_mvp_rtv_unvote", MapVotePools.RTV.StopVote )

hook.Remove( "PlayerSay", "MPV_RTV_ChatCommands" )
hook.Add( "PlayerSay", "MPV_RTV_ChatCommands", function( ply, text )

	if table.HasValue( MapVotePools.RTV.ChatCommandsVote, string.lower(text) ) then
		MapVotePools.RTV.StartVote( ply )
		return ""
	end

	if table.HasValue( MapVotePools.RTV.ChatCommandsUnvote, string.lower(text) ) then
		MapVotePools.RTV.StopVote( ply )
		return ""
	end

end )