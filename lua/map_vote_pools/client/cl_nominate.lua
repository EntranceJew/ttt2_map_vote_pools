MapVotePools.Nominate.ClientNominateMap = function(desired_map)
	net.Start("MVP_ClientNominateMap")
	net.WriteString(desired_map)
	net.SendToServer()
end

MapVotePools.Nominate.ClientUnnominateMap = function()
	net.Start("MVP_ClientUnnominateMap")
	net.SendToServer()
end

concommand.Add( "cl_mvp_nominate",   MapVotePools.Nominate.ClientNominateMap   )
concommand.Add( "cl_mvp_unnominate", MapVotePools.Nominate.ClientUnnominateMap )