CLGAMEMODESUBMENU.base = "base_gamemodesubmenu"
CLGAMEMODESUBMENU.title = "map_vote_pools_addon_info"

local WriteMapData = function(wad)
	net.Start("MVP_AdminWriteMapData")
	net.WriteString(wad.map)
	net.WriteUInt(wad.min_players, 8)
	net.WriteUInt(wad.max_players, 8)
	net.SendToServer()
end

include("map_vote_pools/shared/sh_dtextentry_ttt2.lua")

local go_go_gadget_extendo_dick = vgui.GetControlTable("DFormTTT2")
if not go_go_gadget_extendo_dick then return end

local function MakeReset(parent)
	local reset = vgui.Create("DButtonTTT2", parent)

	reset:SetText("button_default")
	reset:SetSize(32, 32)

	reset.Paint = function(slf, w, h)
		derma.SkinHook("Paint", "FormButtonIconTTT2", slf, w, h)

		return true
	end

	reset.material = Material("vgui/ttt/vskin/icon_reset")

	return reset
end

local function getHighestParent(slf)
	local parent = slf
	local checkParent = slf:GetParent()

	while ispanel(checkParent) do
		parent = checkParent
		checkParent = parent:GetParent()
	end

	return parent
end

---
-- Adds a slider to the form
-- @param table data The data for the slider
-- @return Panel The created slider
-- @realm client
function go_go_gadget_extendo_dick:MakeTextEntry(data)
	local left = vgui.Create("DLabelTTT2", self)

	left:SetText(data.label)

	left.Paint = function(slf, w, h)
		derma.SkinHook("Paint", "FormLabelTTT2", slf, w, h)

		return true
	end

	local right = vgui.Create("DTextEntryTTT2", self)

	local reset = MakeReset(self)
	right:SetResetButton(reset)

	right:SetUpdateOnType(false)
	right:SetHeightMult(1)

	right.OnGetFocus = function(slf)
		getHighestParent(self):SetKeyboardInputEnabled(true)
	end

	right.OnLoseFocus = function(slf)
		getHighestParent(self):SetKeyboardInputEnabled(false)
	end



	right:SetPlaceholderText("")
	right:SetCurrentPlaceholderText("")

	-- Set default if possible even if the convar could still overwrite it
	right:SetDefaultValue(data.default)
	right:SetConVar(data.convar)
	right:SetServerConVar(data.serverConvar)
	-- right:SizeToContents()
	-- right:PerformLayout()

	if not data.convar and not data.serverConvar and data.initial then
		right:SetValue(data.initial)
	end

	right.OnValueChanged = function(slf, value)
		if isfunction(data.OnChange) then
			print("ovc:", slf, value)
			data.OnChange(slf, value)
		end
	end

	right:SetTall(32)
	right:Dock(TOP)


	self:AddItem(left, right, reset)

	if IsValid(data.master) and isfunction(data.master.AddSlave) then
		data.master:AddSlave(left)
		data.master:AddSlave(right)
		data.master:AddSlave(reset)
	end

	return left
end


function CLGAMEMODESUBMENU:Populate(parent)
	net.Receive("MVP_AdminReturnMapData", function(len, ply)
		local map_name = net.ReadString()
		local min_players = net.ReadUInt(8)
		local max_players = net.ReadUInt(8)

		local wad = {
			map = map_name,
			min_players = min_players,
			max_players = max_players,
		}

		local current_map = vgui.CreateTTT2Form(parent, "map_vote_pools_settings_current_map")
		current_map:MakeHelp({
			label = "help_ttt2_ep_current_map",
			params = map_name
		})

		current_map:MakeSlider({
			label = "label_ttt2_ep_current_map_min_players",
			min = 0,
			max = game.MaxPlayers(),
			initial = min_players,
			OnChange = function(slf, newVal)
				wad.min_players = newVal
				WriteMapData(wad)
			end,
			decimal = 0
		})
		current_map:MakeSlider({
			label = "label_ttt2_ep_current_map_max_players",
			min = 0,
			max = game.MaxPlayers(),
			initial = max_players,
			OnChange = function(slf, newVal)
				wad.max_players = newVal
				WriteMapData(wad)
				-- print("debug: menu changed from",oldVal,"to",newVal,"via",slf)
			end,
			decimal = 0
		})
	end)

	net.Start("MVP_AdminGetMapData")
	net.SendToServer()

	-- possession:MakeCheckBox({
	--     label = "label_ttt2_sv_psng_transparent_render_mode",
	--     serverConvar = "sv_psng_transparent_render_mode"
	-- })
	-- possession:MakeHelp({
	--     label = "help_ttt2_sv_psng_transparent_render_mode"
	-- })

	local general = vgui.CreateTTT2Form(parent, "map_vote_pools_settings_general")

	general:MakeHelp({
		label = "help_ttt2_sv_mvp_map_limit",
	})
	general:MakeSlider({
		label = "label_ttt2_sv_mvp_map_limit",
		serverConvar = "sv_mvp_map_limit",
		min = 0,
		max = 128,
		decimal = 0,
	})

	general:MakeHelp({
		label = "help_ttt2_sv_mvp_time_limit",
	})
	general:MakeSlider({
		label = "label_ttt2_sv_mvp_time_limit",
		serverConvar = "sv_mvp_time_limit",
		min = 0,
		max = 120,
		decimal = 0,
	})

	general:MakeHelp({
		label = "help_ttt2_sv_mvp_allow_current_map",
	})
	general:MakeCheckBox({
		label = "label_ttt2_sv_mvp_allow_current_map",
		serverConvar = "sv_mvp_allow_current_map"
	})

	general:MakeHelp({
		label = "help_ttt2_sv_mvp_enable_cooldown",
	})
	general:MakeCheckBox({
		label = "label_ttt2_sv_mvp_enable_cooldown",
		serverConvar = "sv_mvp_enable_cooldown"
	})

	general:MakeHelp({
		label = "help_ttt2_sv_mvp_maps_before_revote",
	})
	general:MakeSlider({
		label = "label_ttt2_sv_mvp_maps_before_revote",
		serverConvar = "sv_mvp_maps_before_revote",
		min = 0,
		max = 128,
		decimal = 0,
	})

	general:MakeHelp({
		label = "help_ttt2_sv_mvp_rtv_player_count",
	})
	general:MakeSlider({
		label = "label_ttt2_sv_mvp_rtv_player_count",
		serverConvar = "sv_mvp_rtv_player_count",
		min = 0,
		max = 128,
		decimal = 0,
	})

	general:MakeHelp({
		label = "help_ttt2_sv_mvp_rtv_ratio",
	})
	general:MakeSlider({
		label = "label_ttt2_sv_mvp_rtv_ratio",
		serverConvar = "sv_mvp_rtv_ratio",
		min = 0,
		max = 1,
		decimal = 2,
	})

	general:MakeHelp({
		label = "help_ttt2_sv_mvp_rtv_wait",
	})
	general:MakeSlider({
		label = "label_ttt2_sv_mvp_rtv_wait",
		serverConvar = "sv_mvp_rtv_wait",
		min = 0,
		max = 300,
		decimal = 0,
	})

	general:MakeHelp({
		label = "help_ttt2_sv_mvp_map_prefixes",
	})
	general:MakeTextEntry({
		label = "label_ttt2_sv_mvp_map_prefixes",
		serverConvar = "sv_mvp_map_prefixes",
		OnChange = function(...) print("g.mte.oc:", ...) end,
	})

	general:MakeHelp({
		label = "help_ttt2_sv_mvp_auto_gamemode",
	})
	general:MakeCheckBox({
		label = "label_ttt2_sv_mvp_auto_gamemode",
		serverConvar = "sv_mvp_auto_gamemode"
	})

	general:MakeHelp({
		label = "help_ttt2_sv_mvp_skip_sort",
	})
	general:MakeCheckBox({
		label = "label_ttt2_sv_mvp_skip_sort",
		serverConvar = "sv_mvp_skip_sort"
	})
end