hook.Add( "Initialize", "AutoTTTMapVotePools", function()
			if GAMEMODE_NAME == "terrortown" then
				function CheckForMapSwitch()
					 -- Check for mapswitch
					 local rounds_left = math.max(0, GetGlobalInt("ttt_rounds_left", 6) - 1)
					 SetGlobalInt("ttt_rounds_left", rounds_left)

					 local time_left = math.max(0, (GetConVar("ttt_time_limit_minutes"):GetInt() * 60) - CurTime())
					 local switchmap = false
					 local nextmap = string.upper(game.GetMapNext())

						if rounds_left <= 0 then
							LANG.Msg("limit_round", {mapname = nextmap})
							switchmap = true
						elseif time_left <= 0 then
							LANG.Msg("limit_time", {mapname = nextmap})
							switchmap = true
						end
						if switchmap then
							timer.Stop("wait2prep")
							timer.Stop("prep2begin")
							-- the above two are for anti-blueballs, but,
							-- do not seem to do anything when invoked in this timeframe
							timer.Stop("end2prep")
							MapVotePools.Start(nil, nil, nil, nil)
						end
				end
			end

			if GAMEMODE_NAME == "deathrun" then
					function RTV.Start()
						MapVotePools.Start(nil, nil, nil, nil)
					end
			end

			if GAMEMODE_NAME == "zombiesurvival" then
				hook.Add("LoadNextMap", "MAPVOTEZS_LOADMAP", function()
					MapVotePools.Start(nil, nil, nil, nil)
					return true
				end )
			end
end )


