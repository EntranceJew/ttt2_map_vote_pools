---@diagnostic disable: missing-parameter
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
	nomination_value = 1000,
}

MapVotePools.CVARS = MapVotePools.CVARS or {
	rtv_player_count = CreateConVar(
		"sv_mvp_rtv_player_count",
		"3",
		{FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}
	),
	rtv_ratio = CreateConVar(
		"sv_mvp_rtv_ratio",
		"0.66",
		{FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}
	),
	rtv_wait = CreateConVar(
		"sv_mvp_rtv_wait",
		"60",
		{FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}
	),

	nominate_limit_map_print = CreateConVar(
		"sv_mvp_nominate_limit_map_print",
		"32",
		{FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}
	),

	map_limit = CreateConVar(
		"sv_mvp_map_limit",
		"24",
		{FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}
	),
	time_limit = CreateConVar(
		"sv_mvp_time_limit",
		"28",
		{FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}
	),
	allow_current_map = CreateConVar(
		"sv_mvp_allow_current_map",
		"0",
		{FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}
	),
	enable_cooldown = CreateConVar(
		"sv_mvp_enable_cooldown",
		"1",
		{FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}
	),
	maps_before_revote = CreateConVar(
		"sv_mvp_maps_before_revote",
		"3",
		{FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}
	),
	map_prefixes = CreateConVar(
		"sv_mvp_map_prefixes",
		"ttt_",
		{FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}
	),
	map_whitelist_enabled = CreateConVar(
		"sv_mvp_map_whitelist_enabled",
		"0",
		{FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}
	),
	map_whitelist = CreateConVar(
		"sv_mvp_map_whitelist",
		"",
		{FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}
	),
	map_blacklist_enabled = CreateConVar(
		"sv_mvp_map_blacklist_enabled",
		"0",
		{FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}
	),
	map_blacklist = CreateConVar(
		"sv_mvp_map_blacklist",
		"",
		{FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}
	),
	auto_gamemode = CreateConVar(
		"sv_mvp_auto_gamemode",
		"0",
		{FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}
	),
	skip_sort = CreateConVar(
		"sv_mvp_skip_sort",
		"0",
		{FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}
	),
	use_ulx_commands = CreateConVar(
		"sv_mvp_use_ulx_commands",
		"0",
		{FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}
	),
	use_chat_commands = CreateConVar(
		"sv_mvp_use_chat_commands",
		"1",
		{FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}
	),
	-- debug_print = CreateConVar(
	--     "sv_psng_debug_print",
	--     "0",
	--     {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}
	-- ),
}

MapVotePools.COLORS = {
	normal = Color(128,128,128,255),
	ideal = Color(0,255,0,255),
	amiss = Color(255,0,0,255),
	goal = Color( 0, 0, 255, 255 ),

	flash = Color( 0, 255, 255 ),
	final = Color( 100, 100, 100, 100 ),

	chat_highlight = Color( 102,255,51 ),
	chat_unhighlight = Color( 255,102,51 ),
	chat_text = Color( 255,255,255 ),

	-- bad_map = Color(64, 64, 64),
	bad_map = Color(0, 0, 0, 255),

	button = Color(0, 0, 0, 200),
}


MapVotePools.Utils = {}
MapVotePools.Utils.Scale = function(valueIn, baseMin, baseMax, limitMin, limitMax)
	return ( limitMax - limitMin ) * ( valueIn - baseMin ) / ( baseMax - baseMin ) + limitMin
end

MapVotePools.Utils.LogRamp = function(x, n, b)
	return math.pow(x / n, b)
end

MapVotePools.Utils.GentleLogRamp = function(x, n, b)
	n = n or 1
	b = b or 1
	return math.log10((b * x) + 1) / math.log10((b * n) + 1)
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

local RTV = RTV or {}

MapVotePools.RTV = RTV

MapVotePools.RTV.RequestRockingChatCommands = {
	"!rtv",
	"/rtv",
	"rtv"
}

MapVotePools.RTV.UnrequestRockingChatCommands = {
	"!unrtv",
	"/unrtv",
	"unrtv"
}

MapVotePools.Nominate = MapVotePools.Nominate or {}
MapVotePools.Nominate.NominateMapChatCommands = {
	"!nominate",
	"/nominate",
	"nominate"
}

MapVotePools.Nominate.UnnominateMapChatCommands = {
	"!unnominate",
	"/unnominate",
	"unnominate"
}

MapVotePools.Ballot = MapVotePools.Ballot or {}
MapVotePools.Ballot.BallotChatCommands = {
	"!ballot",
	"/ballot",
	"ballot"
}

function MapVotePools.HasExtraVotePower(ply)
	return false
end

if SERVER then
	AddCSLuaFile()
	AddCSLuaFile("map_vote_pools/client/cl_mapvotepools.lua")
	AddCSLuaFile("map_vote_pools/client/cl_nominate.lua")
	AddCSLuaFile("map_vote_pools/client/cl_rtv.lua")
	AddCSLuaFile("map_vote_pools/client/cl_ballot.lua")

	include("map_vote_pools/server/sv_mapvotepools.lua")
	include("map_vote_pools/server/sv_autovote.lua")
	include("map_vote_pools/server/sv_nominate.lua")
	include("map_vote_pools/server/sv_rtv.lua")
	include("map_vote_pools/server/sv_ballot.lua")
else
	include("map_vote_pools/client/cl_mapvotepools.lua")
	include("map_vote_pools/client/cl_nominate.lua")
	include("map_vote_pools/client/cl_rtv.lua")
	include("map_vote_pools/client/cl_ballot.lua")
end