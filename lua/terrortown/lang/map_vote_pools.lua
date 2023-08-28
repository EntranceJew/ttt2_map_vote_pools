L = LANG.GetLanguageTableReference("en")

L["map_vote_pools_addon_info"] = "Map Vote Pools"

L["map_vote_pools_settings_current_map"] = "Current Map"
L["help_ttt2_ep_current_map"] = "You're currently on: {map}"

L["label_ttt2_ep_current_map_min_players"] = "Minimum Players"
L["help_ttt2_ep_current_map_min_players"] = "The fewest amount of players that could still find each-other reasonably during play on this map."
L["label_ttt2_ep_current_map_max_players"] = "Maximum Players"
L["help_ttt2_ep_current_map_max_players"] = "The most amount of players that can comfortably play on this map."

L["map_vote_pools_settings_rtv"] = "Rock The Vote"

L["label_ttt2_sv_mvp_rtv_ratio"] = "RTV Ratio"
L["help_ttt2_sv_mvp_rtv_ratio"] = "The percentage of players that must RTV for one to pass."
L["label_ttt2_sv_mvp_rtv_wait"] = "RTV Wait"
L["help_ttt2_sv_mvp_rtv_wait"] = "The time one must wait before they may RTV on map load."
L["label_ttt2_sv_mvp_rtv_player_count"] = "RTV Player Count"
L["help_ttt2_sv_mvp_rtv_player_count"] = "The minimum number of players necessary for RTV."

L["map_vote_pools_settings_nominate"] = "Nominate"

L["label_ttt2_sv_mvp_nominate_limit_map_print"] = "Limit Map Print"
L["help_ttt2_sv_mvp_nominate_limit_map_print"] = "The max amount of maps to print when a user does an incomplete nomination."

L["map_vote_pools_settings_general"] = "General"

L["label_ttt2_sv_mvp_map_limit"] = "Map Limit"
L["help_ttt2_sv_mvp_map_limit"] = "The max number of maps that will appear on the ballot."
L["label_ttt2_sv_mvp_time_limit"] = "Time Limit"
L["help_ttt2_sv_mvp_time_limit"] = "The default duration of a map vote."
L["label_ttt2_sv_mvp_allow_current_map"] = "Allow Current Map"
L["help_ttt2_sv_mvp_allow_current_map"] = "Whether or not players may vote for the map currently being played on.\nEffectively, extends the map. Changelevel will still be called."
L["label_ttt2_sv_mvp_enable_cooldown"] = "Enable Cooldown"
L["help_ttt2_sv_mvp_enable_cooldown"] = "Prevent recently played maps from appearing on the ballot."
L["label_ttt2_sv_mvp_maps_before_revote"] = "Maps Before Revote"
L["help_ttt2_sv_mvp_maps_before_revote"] = "How many maps must be played before a map can reappear on the ballot with cooldowns enabled."
L["label_ttt2_sv_mvp_auto_gamemode"] = "Auto Gamemode"
L["help_ttt2_sv_mvp_auto_gamemode"] = "Determine if we need to change the current gamemode based on the map that won the vote."
L["label_ttt2_sv_mvp_map_prefixes"] = "Map Prefixes"
L["help_ttt2_sv_mvp_map_prefixes"] = "The prefixes to use to search for maps.\nSeparate each entry with a \"|\".\nIf empty, will check for a text file named after the gamemode."
L["label_ttt2_sv_mvp_map_whitelist_enabled"] = "Map Whitelist Enabled"
L["help_ttt2_sv_mvp_map_whitelist_enabled"] = "Only permit the following maps to be chosen. Should not be used in conjunction with blacklist."
L["label_ttt2_sv_mvp_map_whitelist"] = "Map Whitelist"
L["help_ttt2_sv_mvp_map_whitelist"] = "The names of maps to allow, verbatim.\nSeparate each entry with a \"|\"."
L["label_ttt2_sv_mvp_map_blacklist_enabled"] = "Map Blacklist Enabled"
L["help_ttt2_sv_mvp_map_blacklist_enabled"] = "Never permit the following maps to be chosen, despite other settings. Should not be used in conjunction with whitelist."
L["label_ttt2_sv_mvp_map_blacklist"] = "Map Blacklist"
L["help_ttt2_sv_mvp_map_blacklist"] = "The names of maps to deny, verbatim.\nSeparate each entry with a \"|\"."
L["label_ttt2_sv_mvp_skip_sort"] = "Skip Sort"
L["help_ttt2_sv_mvp_skip_sort"] = "Stay random. Do not attempt to sort maps based on player availability scores."

L["map_vote_pools_settings_interface"] = "Interface"

L["label_ttt2_sv_mvp_use_ulx_commands"] = "Use ULX Commands"
L["help_ttt2_sv_mvp_use_ulx_commands"] = "Whether to register short commands likely to collide in ULX's menus.\nDisable this and use chat for less compatibility but easier invocation."
L["label_ttt2_sv_mvp_use_chat_commands"] = "Use chat Commands"
L["help_ttt2_sv_mvp_use_chat_commands"] = "Whether to register plain-text chat listeners.\nDisable this and use ULX for greater compatability with chat widgets."

-- L["label_ttt2_sv_mvp_"] = ""
-- L["help_ttt2_sv_mvp_"] = ""