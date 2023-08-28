local CATEGORY_NAME = "MapVotePools"

local function MVP_mapvotepools( calling_ply, votetime, should_cancel )
	if not should_cancel then
		MapVotePools.Start(votetime, nil, nil, nil)
		ulx.fancyLogAdmin( calling_ply, "#A called a mapvote pools!" )
	else
		MapVotePools.Cancel()
		ulx.fancyLogAdmin( calling_ply, "#A canceled the mapvote pools." )
	end
end

local mapvotepoolscmd = ulx.command( CATEGORY_NAME, "ulx mapvotepools", MVP_mapvotepools, "!mapvotepools" )
mapvotepoolscmd:addParam({
	type = ULib.cmds.NumArg,
	min = 0,
	default = 28,
	hint = "time",
	ULib.cmds.optional,
	ULib.cmds.round
})
mapvotepoolscmd:addParam({
	type = ULib.cmds.BoolArg,
	invisible = true
})
mapvotepoolscmd:defaultAccess( ULib.ACCESS_ADMIN )
mapvotepoolscmd:help( "Invokes the map vote pools logic." )
mapvotepoolscmd:setOpposite( "ulx unmapvotepools", {_, _, true}, "!unmapvotepools" )


if MapVotePools.CVARS.use_ulx_commands:GetBool() then
	local function MVP_requestrocking( calling_ply, should_cancel )
		if not should_cancel then
			if SERVER then
				MapVotePools.RTV.HandleClientRockingRequest(calling_ply, true)
			end
			ulx.fancyLogAdmin( calling_ply, "#A rocked the vote!" )
		else
			if SERVER then
				MapVotePools.RTV.HandleClientRockingRequest(calling_ply, false)
			end
			ulx.fancyLogAdmin( calling_ply, "#A unrocked the vote." )
		end
	end

	local requestrockingcmd = ulx.command( CATEGORY_NAME, "ulx rtv", MVP_requestrocking, "!rtv", true )
	requestrockingcmd.hide = true
	requestrockingcmd:addParam({
		type = ULib.cmds.BoolArg,
		invisible = true
	})
	requestrockingcmd:defaultAccess( ULib.ACCESS_ALL )
	requestrockingcmd:help( "Request to rock the vote, and begin a vote for changing the map at the end of the round." )
	requestrockingcmd:setOpposite( "ulx unrtv", {_, true}, "!unrtv", true )

	local function MVP_nominatemap( calling_ply, map_name, should_cancel )
		local succ = false
		if not should_cancel then
			if SERVER then
				succ = MapVotePools.Nominate.HandleClientNominateMap(calling_ply, map_name)
			end
			if succ then ulx.fancyLogAdmin( calling_ply, "#A nominated a map!" ) end
		else
			if SERVER then
				succ = MapVotePools.Nominate.HandleClientNominateMap(calling_ply, nil)
			end
			if succ then ulx.fancyLogAdmin( calling_ply, "#A unnominated their map." ) end
		end
	end

	local nominatemapcmd = ulx.command( CATEGORY_NAME, "ulx nominate", MVP_nominatemap, "!nominate", true )
	nominatemapcmd.hide = true
	nominatemapcmd:addParam({
		type = ULib.cmds.StringArg,
	})
	nominatemapcmd:addParam({
		type = ULib.cmds.BoolArg,
		invisible = true
	})
	nominatemapcmd:defaultAccess( ULib.ACCESS_ALL )
	nominatemapcmd:help( "Nominate a map name to appear on the next map vote ballot." )
	nominatemapcmd:setOpposite( "ulx unnominate", {_, "", true}, "!unnominate", true )
end