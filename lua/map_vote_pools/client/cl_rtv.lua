MapVotePools.RTV.ClientRequestRocking = function()
	net.Start("MVP_ClientRequestRocking")
	net.SendToServer()
end

MapVotePools.RTV.ClientUnrequestRocking = function()
	net.Start("MVP_ClientUnrequestRocking")
	net.SendToServer()
end

concommand.Add( "cl_mvp_rtv",   MapVotePools.RTV.ClientRequestRocking   )
concommand.Add( "cl_mvp_unrtv", MapVotePools.RTV.ClientUnrequestRocking )