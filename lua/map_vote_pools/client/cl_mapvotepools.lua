surface.CreateFont("MVP_VoteSysButton", {
	font = "Marlett",
	size = 13,
	weight = 0,
	symbol = true,
})

MapVotePools.Look = {
	countdown_reveal_duration = 0.9,
	countdown_text_size = 32,
	countdown_vertifcal_pos = 14,

	playercount_text_size = 24,
	playercount_vertical_pos = 8,

	avatar_size = 32,
	avatar_outline_size = 2,
	avatar_move_duration = 0.3,
	avatar_alpha = 153,

	ballot_header_button_width = 31,

		panel_use_image = true,
		panel_size = 256,
	panel_spacing = 4,
	panel_padding = 4,
	panel_reveal_duration = 0.9,
	panel_reveal_rate = 0.025,

	color_alpha = 64,
	render_bar_alpha = 128,
	render_bar_edge_rounding = 0, -- was 4

	text_pad = 6,
	text_height = 24,
	text_inset = 16,

	flash_count = 3,
	flash_interval = 0.2,

	canvas_header_size = 100,
	canvas_width = 640,
}
local look = MapVotePools.Look

surface.CreateFont("MVP_VoteFontCountdown", {
	font = "Tahoma",
	size = look.countdown_text_size,
	weight = 700,
	antialias = true,
	shadow = true
})

surface.CreateFont("MVP_VoteFont", {
	font = "Trebuchet MS",
	size = look.text_height,
	weight = 700,
	antialias = true,
	shadow = true
})

surface.CreateFont("MVP_VoteFontPlayercount", {
	font = "Tahoma",
	size = look.playercount_text_size,
	weight = 700,
	antialias = true,
	shadow = true
})

net.Receive("MVP_MapVotePoolsStart", function()
	MapVotePools.CurrentMaps = {}
	MapVotePools.Allow = true
	MapVotePools.Votes = {}

	local amt = net.ReadUInt(32)

	for i = 1, amt do
		local map = {
			name = net.ReadString(),
			config = {},
			stats = {},
		}
		map.config.MinPlayers = net.ReadUInt(32)
		map.config.MaxPlayers = net.ReadUInt(32)
		map.stats.SpawnPoints = net.ReadUInt(32)

		MapVotePools.CurrentMaps[i] = map
	end

	MapVotePools.EndTime = CurTime() + net.ReadUInt(32)

	if (IsValid(MapVotePools.Panel)) then
		MapVotePools.Panel:Remove()
	end

	MapVotePools.Panel = vgui.Create("MVP_VoteScreen")
	MapVotePools.Panel:SetMaps(MapVotePools.CurrentMaps)
end)

net.Receive("MVP_MapVotePoolsUpdate", function()
	local update_type = net.ReadUInt(3)

	if (update_type == MapVotePools.UPDATE_VOTE) then
		local ply = net.ReadEntity()

		if (IsValid(ply)) then
			local map_id = net.ReadUInt(32)
			MapVotePools.Votes[ply:SteamID()] = map_id

			if (IsValid(MapVotePools.Panel)) then
				MapVotePools.Panel:AddVoter(ply)
			end
		end
	elseif ( update_type == MapVotePools.UPDATE_WIN ) then
		if ( IsValid(MapVotePools.Panel) ) then
			MapVotePools.Panel:Flash(net.ReadUInt(32))
		end
	end
end)

net.Receive("MVP_MapVotePoolsCancel", function()
	if IsValid(MapVotePools.Panel) then
		MapVotePools.Panel:Remove()
	end
end)

MapVotePools.OpenBallot = function()
	if IsValid(MapVotePools.Panel) then
		MapVotePools.Panel:SetVisible(true)
	else
		chat.AddText(MapVotePools.COLORS.chat_highlight, "[MVP]", MapVotePools.COLORS.chat_text, " There is no ballot in progress.")
	end
end

concommand.Add("cl_mvp_ballot", MapVotePools.OpenBallot)
net.Receive("MVP_MapVotePoolsBallot", function()
	MapVotePools.OpenBallot()
end)

net.Receive("MVP_RTV_Delay", function()
	chat.AddText(MapVotePools.COLORS.chat_highlight, "[RTV]", MapVotePools.COLORS.chat_text, " The vote has been rocked, map vote will begin on round end.")
end)
net.Receive("MVP_UNRTV_Delay", function()
	chat.AddText(MapVotePools.COLORS.chat_unhighlight, "[RTV]", MapVotePools.COLORS.chat_text, " The vote has been unrocked, map vote will no longer begin on round end." )
end)


local star_mat = Material("icon16/star.png")
-- local heart_mat = Material("icon16/heart.png")
-- local shield_mat = Material("icon16/shield.png")

MapVotePools.RenderBar = function(w, h, col, map)
	local edge = look.render_bar_edge_rounding

	local num_players = player.GetCount()
	local max_players = game.MaxPlayers()
	local nudge = (w / max_players) / 2
	local r_min = map.config.MinPlayers > 0 and ((w / max_players) * map.config.MinPlayers) or 0
	local r_max = map.config.MaxPlayers > 0 and ((w / max_players) * (map.config.MaxPlayers - map.config.MinPlayers)) or w
	-- draw: background fill
	draw.RoundedBox(edge, 0, 0, w, h, ColorAlpha(col, look.color_alpha))
	-- draw: metered edge
	draw.RoundedBox(edge, r_min - nudge, 0, r_max + nudge, h, ColorAlpha( col, look.render_bar_alpha ))
	local pip = (w * (num_players / max_players))

	draw.RoundedBox(edge, pip - nudge, 0, nudge, h, MapVotePools.COLORS.goal)
end

local PANEL = {}
function PANEL:Init()
	self:ParentToHUD()

	self.Canvas = vgui.Create("Panel", self)
	self.Canvas:MakePopup()
	self.Canvas:SetKeyboardInputEnabled(false)

	local strung_pos = look.countdown_vertifcal_pos

	self.countDown = vgui.Create("DLabel", self.Canvas)
	self.countDown:SetTextColor(color_white)
	self.countDown:SetFont("MVP_VoteFontCountdown")
	self.countDown:SetText("")
	self.countDown:SetPos(0, strung_pos)
	self.countDown:SetAlpha(0)
	self.countDown:AlphaTo(255, look.countdown_reveal_duration, 0)
	function self.countDown:PerformLayout()
		self:SizeToContents()
		self:CenterHorizontal()
	end

	strung_pos = strung_pos + look.countdown_text_size + look.playercount_vertical_pos
	self.playerCount = vgui.Create("DLabel", self.Canvas)
	self.playerCount:SetTextColor(color_white)
	self.playerCount:SetFont("MVP_VoteFontPlayercount")
	self.playerCount:SetText("")
	self.playerCount:SetPos(0, strung_pos)

	strung_pos = strung_pos + look.playercount_text_size
	self.mapList = vgui.Create("DPanelList", self.Canvas)
	self.mapList:SetPaintBackground(false)
	self.mapList:SetSpacing(look.panel_spacing)
	self.mapList:SetPadding(look.panel_padding)
	self.mapList:EnableHorizontal(true)
	self.mapList:EnableVerticalScrollbar()

	self.closeButton = vgui.Create("DButton", self.Canvas)
	self.closeButton:SetText("")
	self.closeButton.Paint = function(panel, w, h)
		derma.SkinHook("Paint", "WindowCloseButton", panel, w, h)
	end
	self.closeButton.DoClick = function()
		self:SetVisible(false)
		chat.AddText(MapVotePools.COLORS.chat_highlight, "[MVP]", MapVotePools.COLORS.chat_text, " You closed the ballot window. Use \"!ballot\" to reopen it.")
	end

	-- self.maximButton = vgui.Create("DButton", self.Canvas)
	-- self.maximButton:SetText("")
	-- self.maximButton:SetDisabled(true)

	-- self.maximButton.Paint = function(panel, w, h)
	-- 	derma.SkinHook("Paint", "WindowMaximizeButton", panel, w, h)
	-- end

	-- self.minimButton = vgui.Create("DButton", self.Canvas)
	-- self.minimButton:SetText("")
	-- self.minimButton:SetDisabled(true)

	-- self.minimButton.Paint = function(panel, w, h)
	-- 	derma.SkinHook("Paint", "WindowMinimizeButton", panel, w, h)
	-- end

	self.Voters = {}
end

function PANEL:PerformLayout()
	local cx, cy = chat.GetChatBoxPos()

	self:SetPos(0, 0)
	self:SetSize(ScrW(), ScrH())

	local space = GetConVar("sv_mvp_ui_icon_scale"):GetInt() + (look.panel_spacing * 2)
	local width = math.max(space * GetConVar("sv_mvp_ui_icon_tile_columns"):GetInt(), look.canvas_width)
	local extra = width % space
	local real_wide = width - extra
	self.Canvas:StretchToParent(0, 0, 0, 0)
	self.Canvas:SetWide(real_wide)
	self.Canvas:SetTall(ScrH() - look.canvas_header_size)
	self.Canvas:SetPos(0, 0)
	self.Canvas:CenterHorizontal()
	self.Canvas:SetZPos(0)

	self.mapList:StretchToParent(extra / 2, look.canvas_header_size, extra / 2, 0)

	local buttonPos = width - (look.ballot_header_button_width / 2)
	self.closeButton:SetPos(buttonPos - look.ballot_header_button_width * 1, look.canvas_header_size - look.ballot_header_button_width + 8)
	self.closeButton:SetSize(look.ballot_header_button_width, look.ballot_header_button_width)
	self.closeButton:SetVisible(true)

	-- self.maximButton:SetPos(buttonPos - look.ballot_header_button_width * 1, 4)
	-- self.maximButton:SetSize(look.ballot_header_button_width, look.ballot_header_button_width)
	-- self.maximButton:SetVisible(true)

	-- self.minimButton:SetPos(buttonPos - look.ballot_header_button_width * 2, 4)
	-- self.minimButton:SetSize(look.ballot_header_button_width, look.ballot_header_button_width)
	-- self.minimButton:SetVisible(true)
end

function PANEL:AddVoter(voter)
	for _, v in pairs(self.Voters) do
		if (v.Player and v.Player == voter) then
			return false
		end
	end

	local avatar_container = vgui.Create("Panel", self.mapList:GetCanvas())
	local avatar_image = vgui.Create("AvatarImage", avatar_container)
	avatar_container.Player = voter
	avatar_container:SetTooltip(voter:Nick())
	avatar_container:SetMouseInputEnabled(true)
	avatar_container:SetAlpha(look.avatar_alpha)
	avatar_container:SetSize(look.avatar_size, look.avatar_size)
	-- function avatar_container:Paint(w, h)
		-- draw.RoundedBox(4, 0, 0, w, h, Color(255, 0, 0, 80))
		-- draw.RoundedBox(4, look.avatar_outline_size, look.avatar_outline_size, w - (2 * look.avatar_outline_size), h - (2 * look.avatar_outline_size), Color(255, 0, 0, 80))
		-- if avatar_container.img then
		-- 	surface.SetMaterial(avatar_container.img)
		-- 	surface.SetDrawColor(Color(255, 255, 255))
		-- 	surface.DrawTexturedRect(look.avatar_outline_size, look.avatar_outline_size, look.avatar_size, look.avatar_size)
		-- end
	-- end

	avatar_image:SetSize(look.avatar_size, look.avatar_size)
	avatar_image:SetZPos(1000)
	avatar_image:SetTooltip(voter:Name())
	avatar_image:SetPlayer(voter, look.avatar_size)
	-- Make it look like the avatar is clickable (because it is)
	avatar_image:SetCursor("hand")
	-- Passthrough clicks from the avatar to the map button
	avatar_image.OnMousePressed = function()
		avatar_container.MapButton:OnMousePressed()
	end

	local compound = look.avatar_size + (look.avatar_outline_size * 2)
	avatar_container:SetSize(compound, compound)
	avatar_image:SetPos(look.avatar_outline_size, look.avatar_outline_size)
	avatar_image:SetAlpha(look.avatar_alpha)
	if MapVotePools.GetVotePower(voter) > 1 then
		local power_img = vgui.Create("DImage", avatar_image)	-- Add image to Frame
		local space = look.avatar_size / 2
		power_img:SetPos(space, space)
		power_img:SetSize(space, space)
		power_img:SetImage("icon16/star.png")
	end

	table.insert(self.Voters, avatar_container)
end

function PANEL:Think()
	for _, v in pairs(self.mapList:GetItems()) do
		v.NumVotes = 0
	end

	local bar_size = look.text_height + (look.text_pad * 2)
	local StartPos = Vector(look.avatar_outline_size, bar_size)
	for _, v in pairs(self.Voters) do
		if ( not IsValid(v.Player) ) then
			v:Remove()
		else
			if (not MapVotePools.Votes[v.Player:SteamID()] ) then
				v:Remove()
			else
				local panel = self:GetMapButton(MapVotePools.Votes[v.Player:SteamID()])

				local avatar_bulk = look.avatar_size + (look.avatar_outline_size * 2)
				local votes_per_row = (GetConVar("sv_mvp_ui_icon_scale"):GetInt() - (GetConVar("sv_mvp_ui_icon_scale"):GetInt() % avatar_bulk)) / avatar_bulk
				local column = panel.NumVotes % votes_per_row
				local row = (panel.NumVotes - column) / votes_per_row
				-- print("little tyachy", votes_per_row, avatar_bulk, column, row)
				-- local layer = math.floor(row / 4)
				-- row = row - layer * 4;

				panel.NumVotes = panel.NumVotes + MapVotePools.GetVotePower(v.Player)

				local width = avatar_bulk
				local height = avatar_bulk
				if (IsValid(panel)) then
					local NewPos = Vector(panel.x + column * width, panel.y + row * height, 0) + StartPos
					-- local CurrentPos = Vector(v.x, v.y, 0)
					-- local NewPos = Vector((bar.x + bar:GetWide()) - 21 * bar.NumVotes - 2, bar.y + (bar:GetTall() * 0.5 - 10), 0)

					if (not v.CurPos or v.CurPos ~= NewPos) then
						v:MoveTo(NewPos.x, NewPos.y, look.avatar_move_duration)
						v.CurPos = NewPos
						v.MapButton = panel
					end
				end
			end
		end
	end

	local timeLeft = math.Round(math.Clamp(MapVotePools.EndTime - CurTime(), 0, math.huge))

	self.countDown:SetText(tostring(timeLeft or 0) .. " seconds")
	self.countDown:SizeToContents()
	self.countDown:CenterHorizontal()

	self.playerCount:SetText(player.GetCount() .. "/" .. game.MaxPlayers() .. " players")
	self.playerCount:SizeToContents()
	self.playerCount:CenterHorizontal()
end

function PANEL:SetMaps(maps)
	self.mapList:Clear()
	local transCounter = 0
	local num_players = player.GetCount()
	local max_players = game.MaxPlayers()

	for k, map in RandomPairs(maps) do
		transCounter = transCounter + 1

		local delta_low  = 0
		local delta_high = 0
		local delta = 0

		local min = 0
		local max = max_players

		if MapVotePools.CVARS.debug_random_min_max:GetBool() then
			map.config.MinPlayers = math.random(0, game.MaxPlayers())
			map.config.MaxPlayers = math.random(map.config.MinPlayers, game.MaxPlayers())
		end

		if map.config.MinPlayers > 0 and num_players < map.config.MinPlayers then
			delta_low  = map.config.MinPlayers - num_players
		end
		min = string.format("%02d", map.config.MinPlayers > 0 and map.config.MinPlayers or 0)
		if map.config.MaxPlayers > 0 and num_players > map.config.MaxPlayers then
			delta_high = max_players - map.config.MaxPlayers
		end
		max = string.format("%02d", map.config.MaxPlayers > 0 and map.config.MaxPlayers or max_players)
		delta = math.max(delta_low, delta_high)
		local ratio = MapVotePools.Utils.Scale(delta, 0, max_players / GetConVar("sv_mvp_ui_severity_scale"):GetFloat(), 0, 1)

		---@type Color
		-- local bar_color = ColorAlpha( MapVotePools.Utils.ColorSlerp(MapVotePools.COLORS.ideal, MapVotePools.COLORS.amiss, ratio), 64 )
		local bar_color = MapVotePools.Utils.ColorSlerp(MapVotePools.COLORS.ideal, MapVotePools.COLORS.amiss, ratio)

		--#region panel
		local panel = vgui.Create("DLabel", self.mapList)
		local button = vgui.Create("DImageButton", panel)
		panel.ID = k

		panel.NumVotes = 0
		panel:SetTooltip(map.name)
		panel:SetMouseInputEnabled(true)
		panel:SetSize(GetConVar("sv_mvp_ui_icon_scale"):GetInt(), GetConVar("sv_mvp_ui_icon_scale"):GetInt())
		panel:SetText("")
		panel:SetPaintBackgroundEnabled(false)
		panel:SetAlpha(0)
		panel:AlphaTo(255, look.panel_reveal_duration, transCounter * look.panel_reveal_rate)
		function panel:PerformLayout()
			---@diagnostic disable-next-line: missing-parameter
			self:SetBGColor(self.bgColor)
		end
		function panel:OnMousePressed()
			-- If the panel is clicked, click the button instead
			button:OnMousePressed()
		end
		function panel:Paint(w, h)
			draw.RoundedBox(0, 0, 0, w, h, ColorAlpha(bar_color, look.color_alpha))
		end
		--#endregion panel

		--#region button
		button:SetImage(self:GetMapThumbnail(map.name))
		function button:OnMousePressed()
			net.Start("MVP_MapVotePoolsUpdate")
				net.WriteUInt(MapVotePools.UPDATE_VOTE, 3)
				net.WriteUInt(panel.ID, 32)
			net.SendToServer()
		end
		button:SetPos(look.panel_padding, look.panel_padding)
		button:SetSize(GetConVar("sv_mvp_ui_icon_scale"):GetInt() - (look.panel_padding * 2), GetConVar("sv_mvp_ui_icon_scale"):GetInt() - (look.panel_padding * 2))
		--#endregion button

		local raw_depth = MapVotePools.Utils.LogRamp(delta, max_players, GetConVar("sv_mvp_ui_icon_blackout_rate"):GetFloat())
		local hard_alpha = math.Round(raw_depth * 255)

		local image = button:GetChild(0)
		local imagePaint = image.Paint
		function image:Paint(w, h)
			-- surface.SetAlphaMultiplier(1-raw_depth)
			imagePaint(self, w, h)
			local icon_color = ColorAlpha( MapVotePools.COLORS.bad_map, hard_alpha )
			surface.SetAlphaMultiplier(1)
			surface.SetDrawColor(panel.bgColor or icon_color)
			surface.DrawRect(0, 0, w, h)
			-- draw.RoundedBox(0, 0, 0, w, h, Color(255, 0, 0, 255))
		end

		local bar_size = look.text_height + (look.text_pad * 2)
		local bottom_bar = vgui.Create("Panel", button)
		bottom_bar:SetPos(0, GetConVar("sv_mvp_ui_icon_scale"):GetInt() - (look.panel_padding * 2) - bar_size + look.text_pad)
		bottom_bar:SetSize(GetConVar("sv_mvp_ui_icon_scale"):GetInt() - (look.panel_padding * 2), bar_size)
		-- bottom_bar:SetPaintBackgroundEnabled(true)
		function bottom_bar:Paint(w, h)
			MapVotePools.RenderBar(w, h, bar_color, map)
		end


		local text_min = vgui.Create("DLabel", bottom_bar)
		text_min:StretchToParent(0, 0, 0, 0)
		local map_text = string.format(
			"%s:%s | %s",
			min,
			max,
			map.name
		)
		text_min:SetText(min)
		text_min:SetTextInset(look.text_inset, 0)
		text_min:SetContentAlignment(4)
		text_min:SetFont("MVP_VoteFont")

		local text_max = vgui.Create("DLabel", bottom_bar)
		text_max:StretchToParent(0, 0, 0, 0)
		-- text_max:SetPos(0, GetConVar("sv_mvp_ui_icon_scale"):GetInt() - (look.panel_padding * 2) - bar_size + look.text_pad)
		-- text_max:SetSize(GetConVar("sv_mvp_ui_icon_scale"):GetInt() - (look.panel_padding * 2), bar_size)
		text_max:SetText(max)
		text_max:SetTextInset(look.text_inset, 0)
		text_max:SetContentAlignment(6)
		text_max:SetFont("MVP_VoteFont")

		local text2 = vgui.Create("DLabel", button)
		-- local bar_size = look.text_height + (look.text_pad * 2)
		text2:SetPos(0, 0)
		text2:SetSize(GetConVar("sv_mvp_ui_icon_scale"):GetInt() - (look.panel_padding * 2), bar_size)
		local map_text = string.format(
			"%s:%s | %s",
			min,
			max,
			map.name
		)
		text2:SetText(map.name)
		text2:SetTextInset(8, 0)
		text2:SetContentAlignment(4)
		text2:SetFont("MVP_VoteFont")
		text2:SetPaintBackgroundEnabled(true)
		function text2:PerformLayout()
			self:SetBGColor(ColorAlpha(MapVotePools.COLORS.bad_map, 128))
		end
		-- function text2:Paint(w, h)
		-- 	-- draw.
		-- 	surface.SetAlphaMultiplier(0.25)
		-- 	-- surface.SetDrawColor(ColorAlpha(MapVotePools.COLORS.bad_map, 64))
		-- 	surface.SetDrawColor(MapVotePools.COLORS.bad_map)
		-- 	surface.DrawRect(0, 0, w, h)
		-- 	surface.SetAlphaMultiplier(1)
		-- 	-- draw.RoundedBox(4, 0, 0, w, h, ColorAlpha(MapVotePools.COLORS.bad_map, 16))
		-- 	-- MapVotePools.RenderBar(w, h, bar_color, map)
		-- end


		self.mapList:AddItem(panel)
	end
end

function PANEL:GetMapThumbnail(name)
	if file.Exists("maps/thumb/" .. name .. ".png", "GAME") then
		return "maps/thumb/" .. name .. ".png"
	elseif file.Exists("maps/" .. name .. ".png", "GAME") then
		return "maps/" .. name .. ".png"
	else
		return "maps/thumb/noicon.png"
	end
end
function PANEL:GetMapButton(id)
	for _, v in pairs(self.mapList:GetItems()) do
		if v.ID == id then return v end
	end

	return false
end

function PANEL:Paint()
	surface.SetDrawColor(MapVotePools.COLORS.button:Unpack())
	surface.DrawRect(0, 0, ScrW(), ScrH())
end

function PANEL:Flash(id)
	self:SetVisible(true)

	local bar = self:GetMapButton(id)

	if ( IsValid(bar) ) then
		local flash_func = function() bar.bgColor = MapVotePools.COLORS.flash surface.PlaySound( "hl1/fvox/blip.wav" ) end
		local unflash_func = function() bar.bgColor = nil end

		local t = 0.0
		for _ = 1, look.flash_count do
			timer.Simple( t,  flash_func ) t = t + look.flash_interval
			timer.Simple( t,  unflash_func ) t = t + look.flash_interval
		end
		timer.Simple( t,  function() bar.bgColor = MapVotePools.COLORS.final end )
	end
end

derma.DefineControl("MVP_VoteScreen", "", PANEL, "DPanel")

--[[
concommand.Add("cl_mvp_genhelp", function()
	local L = LANG.GetLanguageTableReference("en")
	local out = "[table]\n[tr]\n\t[th]cvar[/th]\n\t[th]description[/th]\n[/tr]\n"
	for key, _ in pairs(ExtraLootableProps.CVARS) do
		out = out .. "[tr]\n"
		out = out .. "\t[td][b]" .. "sv_elp_" .. key .. "[/b] [i]value[/i][/td]\n"
		out = out .. "\t[td][b]" .. L["label_ttt2_sv_elp_" .. key] .. ":[/b] " .. L["help_ttt2_sv_elp_" .. key] .. "[/td]\n"
		out = out .. "[/tr]\n"
	end
	out = out .. "[/table]\n"
	print(out)
end)
]]