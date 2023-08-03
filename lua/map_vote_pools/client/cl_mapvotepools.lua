surface.CreateFont("MVP_VoteFont", {
	font = "Trebuchet MS",
	size = 19,
	weight = 700,
	antialias = true,
	shadow = true
})

surface.CreateFont("MVP_VoteFontCountdown", {
	font = "Tahoma",
	size = 32,
	weight = 700,
	antialias = true,
	shadow = true
})

surface.CreateFont("MVP_VoteFontPlayercount", {
	font = "Tahoma",
	size = 24,
	weight = 700,
	antialias = true,
	shadow = true
})

surface.CreateFont("MVP_VoteSysButton", {
	font = "Marlett",
	size = 13,
	weight = 0,
	symbol = true,
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

		MapVotePools.CurrentMaps[#MapVotePools.CurrentMaps + 1] = map
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

net.Receive("MVP_RTV_Delay", function()
	chat.AddText(MapVotePools.COLORS.chat_highlight, "[RTV]", MapVotePools.COLORS.chat_text, " The vote has been rocked, map vote will begin on round end.")
end)
net.Receive("MVP_UNRTV_Delay", function()
	chat.AddText(MapVotePools.COLORS.chat_unhighlight, "[RTV]", MapVotePools.COLORS.chat_text, " The vote has been unrocked, map vote will no longer begin on round end." )
end)


local star_mat = Material("icon16/star.png")
-- local heart_mat = Material("icon16/heart.png")
-- local shield_mat = Material("icon16/shield.png")

local PANEL = {}

function PANEL:Init()
	self:ParentToHUD()

	self.Canvas = vgui.Create("Panel", self)
	self.Canvas:MakePopup()
	self.Canvas:SetKeyboardInputEnabled(false)

	self.countDown = vgui.Create("DLabel", self.Canvas)
	self.countDown:SetTextColor(color_white)
	self.countDown:SetFont("MVP_VoteFontCountdown")
	self.countDown:SetText("")
	self.countDown:SetPos(0, 14)

	self.playerCount = vgui.Create("DLabel", self.Canvas)
	self.playerCount:SetTextColor(color_white)
	self.playerCount:SetFont("MVP_VoteFontPlayercount")
	self.playerCount:SetText("")
	self.playerCount:SetPos(0, 54)

	self.mapList = vgui.Create("DPanelList", self.Canvas)
	self.mapList:SetPaintBackground(false)
	self.mapList:SetSpacing(4)
	self.mapList:SetPadding(4)
	self.mapList:EnableHorizontal(true)
	self.mapList:EnableVerticalScrollbar()

	self.closeButton = vgui.Create("DButton", self.Canvas)
	self.closeButton:SetText("")

	self.closeButton.Paint = function(panel, w, h)
		derma.SkinHook("Paint", "WindowCloseButton", panel, w, h)
	end

	self.closeButton.DoClick = function()
		self:SetVisible(false)
	end

	self.maximButton = vgui.Create("DButton", self.Canvas)
	self.maximButton:SetText("")
	self.maximButton:SetDisabled(true)

	self.maximButton.Paint = function(panel, w, h)
		derma.SkinHook("Paint", "WindowMaximizeButton", panel, w, h)
	end

	self.minimButton = vgui.Create("DButton", self.Canvas)
	self.minimButton:SetText("")
	self.minimButton:SetDisabled(true)

	self.minimButton.Paint = function(panel, w, h)
		derma.SkinHook("Paint", "WindowMinimizeButton", panel, w, h)
	end

	self.Voters = {}
end

function PANEL:PerformLayout()
	local cx, cy = chat.GetChatBoxPos()

	self:SetPos(0, 0)
	self:SetSize(ScrW(), ScrH())

	local extra = math.Clamp(300, 0, ScrW() - 640)
	self.Canvas:StretchToParent(0, 0, 0, 0)
	self.Canvas:SetWide(640 + extra)
	self.Canvas:SetTall(cy -60)
	self.Canvas:SetPos(0, 0)
	self.Canvas:CenterHorizontal()
	self.Canvas:SetZPos(0)

	self.mapList:StretchToParent(0, 90, 0, 0)

	local buttonPos = 640 + extra - 31 * 3

	self.closeButton:SetPos(buttonPos - 31 * 0, 4)
	self.closeButton:SetSize(31, 31)
	self.closeButton:SetVisible(true)

	self.maximButton:SetPos(buttonPos - 31 * 1, 4)
	self.maximButton:SetSize(31, 31)
	self.maximButton:SetVisible(true)

	self.minimButton:SetPos(buttonPos - 31 * 2, 4)
	self.minimButton:SetSize(31, 31)
	self.minimButton:SetVisible(true)
end

function PANEL:AddVoter(voter)
	for k, v in pairs(self.Voters) do
		if (v.Player and v.Player == voter) then
			return false
		end
	end

	local icon_container = vgui.Create("Panel", self.mapList:GetCanvas())
	local icon = vgui.Create("AvatarImage", icon_container)
	icon:SetSize(16, 16)
	icon:SetZPos(1000)
	icon:SetTooltip(voter:Name())
	icon_container.Player = voter
	icon_container:SetTooltip(voter:Name())
	icon:SetPlayer(voter, 16)

	if MapVotePools.HasExtraVotePower(voter) then
		icon_container:SetSize(40, 20)
		icon:SetPos(21, 2)
		icon_container.img = star_mat
	else
		icon_container:SetSize(20, 20)
		icon:SetPos(2, 2)
	end

	icon_container.Paint = function(s, w, h)
		draw.RoundedBox(4, 0, 0, w, h, Color(255, 0, 0, 80))

		if ( icon_container.img ) then
			surface.SetMaterial(icon_container.img)
			surface.SetDrawColor(Color(255, 255, 255))
			surface.DrawTexturedRect(2, 2, 16, 16)
		end
	end

	table.insert(self.Voters, icon_container)
end

function PANEL:Think()
	for k, v in pairs(self.mapList:GetItems()) do
		v.NumVotes = 0
	end

	for k, v in pairs(self.Voters) do
		if ( not IsValid(v.Player) ) then
			v:Remove()
		else
			if (not MapVotePools.Votes[v.Player:SteamID()] ) then
				v:Remove()
			else
				local bar = self:GetMapButton(MapVotePools.Votes[v.Player:SteamID()])

				if ( MapVotePools.HasExtraVotePower(v.Player) ) then
					bar.NumVotes = bar.NumVotes + 2
				else
					bar.NumVotes = bar.NumVotes + 1
				end

				if (IsValid(bar)) then
					local CurrentPos = Vector(v.x, v.y, 0)
					local NewPos = Vector((bar.x + bar:GetWide()) - 21 * bar.NumVotes - 2, bar.y + (bar:GetTall() * 0.5 - 10), 0)

					if (not v.CurPos or v.CurPos ~= NewPos) then
						v:MoveTo(NewPos.x, NewPos.y, 0.3)
						v.CurPos = NewPos
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
	local num_players = player.GetCount()
	local max_players = game.MaxPlayers()

	for k, map in RandomPairs(maps) do
		local button = vgui.Create("DButton", self.mapList)
		button.ID = k

		local delta_low  = 0
		local delta_high = 0
		local delta = 0

		local min = 0
		local max = max_players

		if map.config.MinPlayers > 0 and num_players < map.config.MinPlayers then
			delta_low  = map.config.MinPlayers - num_players
		end
		min = string.format("%02d", map.config.MinPlayers > 0 and map.config.MinPlayers or 0)
		if map.config.MaxPlayers > 0 and num_players > map.config.MaxPlayers then
			delta_high = max_players - map.config.MaxPlayers
		end
		max = string.format("%02d", map.config.MaxPlayers > 0 and map.config.MaxPlayers or max_players)


		-- if c.MinPlayers > 0 and num_players < c.MinPlayers then
		-- 	delta_low  = c.MinPlayers - num_players
		-- end
		-- if c.MaxPlayers > 0 and num_players > c.MaxPlayers then
		-- 	delta_high = max_players - c.MaxPlayers
		-- end
		-- delta = math.max(delta_low, delta_high)


		-- if map.stats.SpawnPoints > 0 then
		-- 	spn = string.format("%02d", map.stats.SpawnPoints)
		-- end
		delta = math.max(delta_low, delta_high)

		-- local ratio = MapVotePools.Utils.Scale(num_players, map_data.MinPlayers, map_data.MaxPlayers, 0, 1)
		local ratio = MapVotePools.Utils.Scale(delta, 0, max_players / MapVotePools.CVAR.SEVERITY_SCALE, 0, 1)
		-- print("rat", min, max, delta, ratio, map.name)
		-- local ratio = (num_players / ((map_data.MinPlayers + map_data.MaxPlayers) / 2))
		-- if ratio < 0.5 then
			-- target_col = COLORS.amiss
		-- elseif ratio >= 0.5 then
			-- target_col = COLORS.amiss
		-- end

		-- button:SetText(min .. "-" .. max .. "/" .. spn .. " : "  .. math.Round(delta, 2) .. " | " .. map_data.MapName)
		local map_text = string.format(
			"%s:%s | %s",
			min,
			max,
			map.name
		)
		-- string.format("-%02d", delta),
		button:SetText(map_text)

		button.DoClick = function()
			net.Start("MVP_MapVotePoolsUpdate")
				net.WriteUInt(MapVotePools.UPDATE_VOTE, 3)
				net.WriteUInt(button.ID, 32)
			net.SendToServer()
		end

		do
			local Paint = button.Paint
			button.Paint = function(s, w, h)
				--  COLORS.normal
				-- local target_col = COLORS.amiss

				-- if map_data.SpawnPoints > 0 then
				--     col = COLORS.ideal
				-- end

				local col = ColorAlpha( MapVotePools.Utils.ColorSlerp(MapVotePools.COLORS.ideal, MapVotePools.COLORS.amiss, ratio), 64 )

				-- if delta > 0 then
				-- else
					-- col = COLORS.ideal
				-- end

				if (button.bgColor) then
					col = button.bgColor
				end

				draw.RoundedBox(4, 0, 0, w, h, col)
				local nudge = (w / max_players) / 2
				local r_min = 0
				if map.config.MinPlayers > 0 then
					r_min = ((w / max_players) * map.config.MinPlayers)
				end
				local r_max = w
				if map.config.MaxPlayers > 0 then
					r_max = ((w / max_players) * (map.config.MaxPlayers - map.config.MinPlayers))
				end
				draw.RoundedBox(4, r_min - nudge, 0, r_max + nudge, h, ColorAlpha( col, 128 ))
				local pip = (w * (num_players / max_players))

				draw.RoundedBox(4, pip - nudge, 0, nudge, h, MapVotePools.COLORS.goal)
				Paint(s, w, h)
			end
		end

		button:SetTextColor(color_white)
		button:SetContentAlignment(4)
		button:SetTextInset(8, 0)
		button:SetFont("MVP_VoteFont")

		local extra = math.Clamp(300, 0, ScrW() - 640)

		button:SetPaintBackground(false)
		button:SetTall(24)
		button:SetWide(285 + (extra / 2))
		button.NumVotes = 0

		self.mapList:AddItem(button)
	end
end

function PANEL:GetMapButton(id)
	for k, v in pairs(self.mapList:GetItems()) do
		if ( v.ID == id ) then return v end
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

		local flashes = 3
		local flash_interval = 0.2

		local t = 0.0

		for flash = 1, flashes do
			timer.Simple( t,  flash_func ) t = t + flash_interval
			timer.Simple( t,  unflash_func ) t = t + flash_interval
		end
		timer.Simple( t,  function() bar.bgColor = MapVotePools.COLORS.final end )
	end
end

derma.DefineControl("MVP_VoteScreen", "", PANEL, "DPanel")

--[[
concommand.Add("cl_mvp_genhelp", function()
	local L = LANG.GetLanguageTableReference("en")
	local out = "[table]\n[tr]\n\t[th]cvar[/th]\n\t[th]description[/th]\n[/tr]\n"
	for key, _ in pairs(MapVotePools.CVARS) do
		out = out .. "[tr]\n"
		out = out .. "\t[td][b]" .. "sv_mvp_" .. key .. "[/b] [i]value[/i][/td]\n"
		out = out .. "\t[td][b]" .. L["label_ttt2_sv_mvp_" .. key] .. ":[/b] " .. L["help_ttt2_sv_mvp_" .. key] .. "[/td]\n"
		out = out .. "[/tr]\n"
	end
	print(out)
end)
]]