util.AddNetworkString("MVP_MapVotePoolsBallot")
function MapVotePools.Ballot.HandleClientBallot(ply)
	net.Start("MVP_MapVotePoolsBallot")
	net.Send(ply)
end