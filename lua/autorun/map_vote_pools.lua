MapVotePools = MapVotePools or {}
MapVotePools.UPDATE_VOTE = 1
MapVotePools.UPDATE_WIN = 3

MapVotePools.Data = {}
MapVotePools.Data.Config = {}
MapVotePools.Data.MapConfig = {}
MapVotePools.Data.MapStats = {}
MapVotePools.Data.RecentMaps = {}

-- loose vars
MapVotePools.CurrentMaps = {}
MapVotePools.Votes = {}
MapVotePools.Allow = false
MapVotePools.EndTime = 0
MapVotePools.Panel = false
MapVotePools.Continued = false

-- TODO: reroll map pool, extend voting if playercount slips past a breakpoint

MapVotePools.CVAR = MapVotePools.CVAR or {}
MapVotePools.CVAR.SEVERITY_SCALE = 3
MapVotePools.CVAR.WEIGHT_BONUSES = {
	uninducted = 500,
	map_too_big = -200,
	insufficient_spawns = -100,
}

MapVotePools.COLORS = {
	normal = Color(128,128,128,32),
	ideal = Color(0,255,0,64),
	amiss = Color(255,0,0,16),
	goal = Color( 0, 0, 255, 192 ),

	flash = Color( 0, 255, 255 ),
	final = Color( 100, 100, 100 ),

	chat_highlight = Color( 102,255,51 ),
	chat_text = Color( 255,255,255 ),

	button = Color(0, 0, 0, 200),
}


MapVotePools.Utils = {}
MapVotePools.Utils.Scale = function(valueIn, baseMin, baseMax, limitMin, limitMax)
	return ( limitMax - limitMin ) * ( valueIn - baseMin ) / ( baseMax - baseMin ) + limitMin
end
MapVotePools.Utils.ColorSlerp = function(from,to,transition)
	local f_h, f_s, f_v = from:ToHSV()
	local f_a = from.a

	local t_h, t_s, t_v = to:ToHSV()
	local t_a = to.a

	local out = HSVToColor(
		MapVotePools.Utils.Scale(transition, 0, 1, f_h, t_h),
		MapVotePools.Utils.Scale(transition, 0, 1, f_s, t_s),
		MapVotePools.Utils.Scale(transition, 0, 1, f_v, t_v)
	)
	out.a = MapVotePools.Utils.Scale(transition, 0, 1, f_a, t_a)
	return out
end


function MapVotePools.HasExtraVotePower(ply)
	return false
end

if SERVER then
	AddCSLuaFile()
	AddCSLuaFile("map_vote_pools/client/cl_mapvotepools.lua")
	AddCSLuaFile("map_vote_pools/shared/sh_rtv.lua")
	AddCSLuaFile("map_vote_pools/shared/sh_dtextentry_ttt2.lua")

	include("map_vote_pools/server/sv_mapvotepools.lua")
	include("map_vote_pools/server/sv_autovote.lua")
	include("map_vote_pools/shared/sh_rtv.lua")
else
	include("map_vote_pools/client/cl_mapvotepools.lua")
	include("map_vote_pools/shared/sh_rtv.lua")
	-- include("map_vote_pools/shared/sh_dtextentry_ttt2.lua")
end
