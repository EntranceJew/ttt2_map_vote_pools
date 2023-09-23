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
L["label_ttt2_sv_mvp_cooldown_use_penalty"] = "Cooldown Use Penalty"
L["help_ttt2_sv_mvp_cooldown_use_penalty"] = "Instead of cooldown preventing items from appearing on the ballot, it penalizes them per appearance, temporarily deranking them strongly so they less likely to occur again."
L["label_ttt2_sv_mvp_maps_before_revote"] = "Maps Before Revote"
L["help_ttt2_sv_mvp_maps_before_revote"] = "How many maps must be played before a map can reappear on the ballot with cooldowns enabled."
L["label_ttt2_sv_mvp_auto_gamemode"] = "Auto Gamemode"
L["help_ttt2_sv_mvp_auto_gamemode"] = "Determine if we need to change the current gamemode based on the map that won the vote."
L["label_ttt2_sv_mvp_sync_with_rsm"] = "Sync With Random Starting Map"
L["help_ttt2_sv_mvp_sync_with_rsm"] = [[If enabled, will also update the convars for Random Starting Map by The Stig, thes include:
- rsm_map_prefixes
- rsm_map_blacklist
- rsm_map_whitelist
Additionally, it will exclude the map specifided by 'rsm_map_to_switch_from'
NOTE: This will *never* read the values from RSM, so changes to RSM will be lost if not migrated manually.]]
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


L["map_vote_pools_settings_score"] = "Score / Sort"
L["label_ttt2_sv_mvp_skip_sort"] = "Skip Sort"
L["help_ttt2_sv_mvp_skip_sort"] = "Stay random. Do not attempt to sort maps based on player availability scores."
L["label_ttt2_sv_mvp_score_uninducted"] = "Uninducted"
L["help_ttt2_sv_mvp_score_uninducted"] = "The score to apply to maps that have no min/max player defined, assuming that they have not been configured yet."
L["label_ttt2_sv_mvp_score_play_count_penalty"] = "Play Count"
L["help_ttt2_sv_mvp_score_play_count_penalty"] = "A score to apply per time the map has been played, lifetime.\nKeep this small to make the un-stale effect only marginal."
L["label_ttt2_sv_mvp_score_cooldown_penalty"] = "Cooldown Penalty"
L["help_ttt2_sv_mvp_score_cooldown_penalty"] = "A score to apply per time the map appears in the 'recent map cooldown' list.\nThis should prevent a map from appearing too frequently, because the penalty stacks for as wide as the 'Maps Before Revote' option is set."
L["label_ttt2_sv_mvp_score_map_too_big"] = "Map Too Big"
L["help_ttt2_sv_mvp_score_map_too_big"] = "A score to apply per difference from the maps configured Max Players and the current player count.\nThis causes fewer red frames from appearing."
L["label_ttt2_sv_mvp_score_insufficient_spawns"] = "Insufficient Spawns"
L["help_ttt2_sv_mvp_score_insufficient_spawns"] = "A score to apply per difference from the map's configured Min Players and the current player count.\nThis causes fewer hour long empty rounds."
L["label_ttt2_sv_mvp_score_nomination_value"] = "Nomination Value"
L["help_ttt2_sv_mvp_score_nomination_value"] = "A score to apply per nomination a map receives, which can potentially allow players to play on a heavily deranked map anyway."
-- L["label_ttt2_sv_mvp_"] = ""
-- L["help_ttt2_sv_mvp_"] = ""

L["map_vote_pools_settings_interface"] = "Interface"

L["label_ttt2_sv_mvp_use_ulx_commands"] = "Use ULX Commands"
L["help_ttt2_sv_mvp_use_ulx_commands"] = "Whether to register short commands likely to collide in ULX's menus.\nDisable this and use chat for less compatibility but easier invocation."
L["label_ttt2_sv_mvp_use_chat_commands"] = "Use chat Commands"
L["help_ttt2_sv_mvp_use_chat_commands"] = "Whether to register plain-text chat listeners.\nDisable this and use ULX for greater compatability with chat widgets."
-- L["label_ttt2_sv_mvp_ui_panel_use_image"] = "Use Map Icon"
-- L["help_ttt2_sv_mvp_ui_panel_use_image"] = "Whether to show map icons, or just the classic enhanced bar style."
L["label_ttt2_sv_mvp_ui_severity_scale"] = "Severity Scale"
L["help_ttt2_sv_mvp_ui_severity_scale"] = "How quickly the frames turn from green to red based on the distance from the current player count."
L["label_ttt2_sv_mvp_ui_icon_blackout_rate"] = "Icon Blackout Rate"
L["help_ttt2_sv_mvp_ui_icon_blackout_rate"] = "How quickly icons that are in red frames are pitched down and darkened to de-emphasize their selection."
L["label_ttt2_sv_mvp_ui_icon_tile_columns"] = "Icon Tile Columns"
L["help_ttt2_sv_mvp_ui_icon_tile_columns"] = "How many columns of maps to show to the user at once.\nAffects whether or not you may need to scroll by default."
L["label_ttt2_sv_mvp_ui_icon_scale"] = "Icon Scale"
L["help_ttt2_sv_mvp_ui_icon_scale"] = "The resolution of the map thumbnails to draw at."
L["label_ttt2_sv_mvp_ui_avatar_alpha"] = "Avatar Alpha"
L["help_ttt2_sv_mvp_ui_avatar_alpha"] = "The transparency of the users's avatars on the map thumbnails."
-- L["label_ttt2_sv_mvp_"] = ""
-- L["help_ttt2_sv_mvp_"] = ""

L["map_vote_pools_settings_debug"] = "Debug"

L["label_ttt2_sv_mvp_debug"] = "Debug Mode"
L["help_ttt2_sv_mvp_debug"] = "Enables misc debug prints and features, like bots glomming on to player votes.\nDo not use in production."
L["label_ttt2_sv_mvp_debug_random_min_max"] = "Random Min/Max"
L["help_ttt2_sv_mvp_debug_random_min_max"] = "Whether or not the map's configured min/max is used or if a random value is drawn instead.\nOnly visual, for testing appearances."