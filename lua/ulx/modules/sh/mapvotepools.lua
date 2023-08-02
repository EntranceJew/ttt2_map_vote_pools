local CATEGORY_NAME = "MapVotePools"
------------------------------ VoteMap ------------------------------
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