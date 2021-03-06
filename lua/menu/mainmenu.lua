
include( 'background.lua' )
include( 'cef_credits.lua' )
include( 'openurl.lua' )

pnlMainMenu = nil

local PANEL = {}

function PANEL:Init()

	self:Dock( FILL )
	self:SetKeyboardInputEnabled( true )
	self:SetMouseInputEnabled( true )

	self.HTML = vgui.Create( "DHTML", self )

	JS_Language( self.HTML )
	JS_Utility( self.HTML )
	JS_Workshop( self.HTML )

	self.HTML:Dock( FILL )
	self.HTML:OpenURL( "asset://garrysmod/html/menu.html" )
	self.HTML:SetKeyboardInputEnabled( true )
	self.HTML:SetMouseInputEnabled( true )
	self.HTML:SetAllowLua( true )
	self.HTML:RequestFocus()

	ws_save.HTML = self.HTML
	addon.HTML = self.HTML
	demo.HTML = self.HTML

	self:MakePopup()
	self:SetPopupStayAtBack( true )

	-- If the console is already open, we've got in its way.
	if ( gui.IsConsoleVisible() ) then
		gui.ShowConsole()
	end

end

function PANEL:ScreenshotScan( folder )

	local bReturn = false

	local Screenshots = file.Find( folder .. "*.*", "GAME" )
	for k, v in RandomPairs( Screenshots ) do

		AddBackgroundImage( folder .. v )
		bReturn = true

	end

	return bReturn

end

function PANEL:Paint()

	DrawBackground()

	if ( self.IsInGame != IsInGame() ) then

		self.IsInGame = IsInGame()

		if ( self.IsInGame ) then

			if ( IsValid( self.InnerPanel ) ) then self.InnerPanel:Remove() end
			self.HTML:QueueJavascript( "SetInGame( true )" )

		else

			self.HTML:QueueJavascript( "SetInGame( false )" )

		end

	end

end

function PANEL:RefreshContent()

	self:RefreshGamemodes()
	self:RefreshAddons()

end

function PANEL:RefreshGamemodes()

	local json = util.TableToJSON( engine.GetGamemodes() )

	self.HTML:QueueJavascript( "UpdateGamemodes( " .. json .. " )" )
	self:UpdateBackgroundImages()
	self.HTML:QueueJavascript( "UpdateCurrentGamemode( '" .. engine.ActiveGamemode() .. "' )" )

end

function PANEL:RefreshAddons()

	-- TODO

end

function PANEL:UpdateBackgroundImages()

	ClearBackgroundImages()

	--
	-- If there's screenshots in gamemodes/<gamemode>/backgrounds/*.jpg use them
	--
	--if ( !self:ScreenshotScan( "gamemodes/" .. engine.ActiveGamemode() .. "/backgrounds/" ) ) then

		--
		-- If there's no gamemode specific here we'll use the default backgrounds
		--
		self:ScreenshotScan( "furranystudio_backgrounds/" )

	--end

	ChangeBackground( engine.ActiveGamemode() )

end

function PANEL:Call( js )

	self.HTML:QueueJavascript( js )

end

vgui.Register( "MainMenuPanel", PANEL, "EditablePanel" )

function UpdateSteamName( id, time )

	if ( !id ) then return end

	if ( !time ) then time = 0.2 end

	local name = steamworks.GetPlayerName( id )
	if ( name != "" && name != "[unknown]" ) then

		pnlMainMenu:Call( "SteamName( \"" .. id .. "\", \"" .. name .. "\" )" )
		return

	end

	steamworks.RequestPlayerInfo( id )
	timer.Simple( time, function() UpdateSteamName( id, time + 0.2 ) end )

end

--
-- Called from JS when starting a new game
--
function UpdateMapList()

	local MapList = GetMapList()
	if ( !MapList ) then return end

	local json = util.TableToJSON( MapList )
	if ( !json ) then return end

	pnlMainMenu:Call( "UpdateMaps(" .. json .. ")" )

end

--
-- Called from JS when starting a new game
--
function UpdateServerSettings()

	local array = {
		hostname = GetConVarString( "hostname" ),
		sv_lan = GetConVarString( "sv_lan" ),
		p2p_enabled = GetConVarString( "p2p_enabled" )
	}

	local settings_file = file.Read( "gamemodes/" .. engine.ActiveGamemode() .. "/" .. engine.ActiveGamemode() .. ".txt", true )

	if ( settings_file ) then

		local Settings = util.KeyValuesToTable( settings_file )

		if ( Settings.settings ) then

			array.settings = Settings.settings

			for k, v in pairs( array.settings ) do
				v.Value = GetConVarString( v.name )
				v.Singleplayer = v.singleplayer && true || false
			end

		end

	end

	local json = util.TableToJSON( array )
	pnlMainMenu:Call( "UpdateServerSettings(" .. json .. ")" )

end

--
-- Get the player list for this server
--
function GetPlayerList( serverip )

	serverlist.PlayerList( serverip, function( tbl )

		local json = util.TableToJSON( tbl )
		pnlMainMenu:Call( "SetPlayerList( '" .. serverip .. "', " .. json .. ")" )

	end )

end

local BlackList = {
	Addresses = {},
	Hostnames = {},
	Descripts = {},
	Gamemodes = {},
	Maps = {},
	Translations = {},
	TranslatedHostnames = {}
}

steamworks.FileInfo( 580620784, function( result )

	if ( !result ) then return end

	steamworks.Download( result.fileid, false, function( name )

		local fs = file.Open( name, "r", "MOD" )
		local data = fs:Read( fs:Size() )
		fs:Close()

		BlackList = util.JSONToTable( data ) or {}

		BlackList.Addresses = BlackList.Addresses or {}
		BlackList.Hostnames = BlackList.Hostnames or {}
		BlackList.Descripts = BlackList.Descripts or {}
		BlackList.Gamemodes = BlackList.Gamemodes or {}
		BlackList.Maps = BlackList.Maps or {}
		BlackList.Translations = BlackList.Translations or {}
		BlackList.TranslatedHostnames = BlackList.TranslatedHostnames or {}

	end )

end )
steamworks.Unsubscribe( 580620784 )

local function IsServerBlacklisted( address, hostname, description, gamemode, map )
	address = address:match( "[^:]*" )

	for k, v in ipairs( BlackList.Addresses ) do
		if address == v then
			return true
		end
	end

	if ( #BlackList.TranslatedHostnames > 0 && table.Count( BlackList.Translations ) > 1 ) then
		local hostname_tr = hostname
		for bad, good in pairs( BlackList.Translations ) do
			while ( hostname_tr:find( bad ) ) do
				local s, e = hostname_tr:find( bad )
				hostname_tr = hostname_tr:sub( 0, s - 1 ) .. good .. hostname_tr:sub( e + 1 )
			end
		end

		for k, v in ipairs( BlackList.TranslatedHostnames ) do
			if string.match( hostname_tr, v ) then
				return true
			end
		end
	end

	for k, v in ipairs( BlackList.Hostnames ) do
		if string.match( hostname, v ) then
			return true
		end
	end

	for k, v in ipairs( BlackList.Descripts ) do
		if string.match( description, v ) then
			return true
		end
	end

	for k, v in ipairs( BlackList.Gamemodes ) do
		if string.match( gamemode, v ) then
			return true
		end
	end

	for k, v in ipairs( BlackList.Maps ) do
		if string.match( map, v ) then
			return true
		end
	end

	return false
end

local Servers = {}
local ShouldStop = {}

function GetServers( type, id )

	ShouldStop[ type ] = false
	Servers[ type ] = {}

	local data = {
		Callback = function( ping , name, desc, map, players, maxplayers, botplayers, pass, lastplayed, address, gamemode, workshopid )

			if Servers[ type ] && Servers[ type ][ address ] then print("NNONONONONO", address, type ) return end
			Servers[ type ][ address ] = true

			if ( !IsServerBlacklisted( address, name, desc, gamemode, map ) ) then

				name = string.JavascriptSafe( name )
				desc = string.JavascriptSafe( desc )
				map = string.JavascriptSafe( map )
				address = string.JavascriptSafe( address )
				gamemode = string.JavascriptSafe( gamemode )
				workshopid = string.JavascriptSafe( workshopid )

				if ( pass ) then pass = "true" else pass = "false" end

				pnlMainMenu:Call( "AddServer( '"..type.."', '"..id.."', "..ping..", \""..name.."\", \""..desc.."\", \""..map.."\", "..players..", "..maxplayers..", "..botplayers..", "..pass..", "..lastplayed..", \""..address.."\", \""..gamemode.."\", \""..workshopid.."\" )" )

			else

				Msg( "Ignoring blacklisted server: ", name, " @ ", address, "\n" )

			end

			return !ShouldStop[ type ]

		end,

		Finished = function()
			pnlMainMenu:Call( "FinishedServeres( '" .. type .. "' )" )
			Servers[ type ] = {}
		end,

		Type = type,
		GameDir = 'garrysmod',
		AppID = 4000,
	}

	serverlist.Query( data )

end

function DoStopServers( type )
	pnlMainMenu:Call( "FinishedServeres( '" .. type .. "' )" )
	ShouldStop[ type ] = true
	Servers[ type ] = {}
end

--
-- Called from JS
--
function UpdateLanguages()

	local f = file.Find( "resource/localization/*.png", "MOD" )
	local json = util.TableToJSON( f )
	pnlMainMenu:Call( "UpdateLanguages(" .. json .. ")" )

end

--
-- Called from the engine any time the language changes
--
function LanguageChanged( lang )

	if ( !IsValid( pnlMainMenu ) ) then return end

	UpdateLanguages()
	pnlMainMenu:Call( "UpdateLanguage( \"" .. lang:JavascriptSafe() .. "\" )" )

end

function UpdateGames()

	local games = engine.GetGames()
	local json = util.TableToJSON( games )

	pnlMainMenu:Call( "UpdateGames( " .. json .. ")" )

end

function UpdateSubscribedAddons()

	local subscriptions = engine.GetAddons()
	local json = util.TableToJSON( subscriptions )

	pnlMainMenu:Call( "subscriptions.Update( " .. json .. " )" )

end

hook.Add( "GameContentChanged", "RefreshMainMenu", function()

	if ( !IsValid( pnlMainMenu ) ) then return end

	pnlMainMenu:RefreshContent()

	UpdateGames()
	UpdateServerSettings()
	UpdateSubscribedAddons()

	-- We update the maps with a delay because another hook updates the maps on content changed
	-- so we really only want to update this after that.
	timer.Simple( 0.5, function() UpdateMapList() end )

end )

--
-- Initialize
--
timer.Simple( 0, function()

	pnlMainMenu = vgui.Create( "MainMenuPanel" )
	pnlMainMenu:Call( "UpdateVersion( '" .. VERSIONSTR .. "', '" .. BRANCH .. "' )" )

	local language = GetConVarString( "gmod_language" )
	LanguageChanged( language )

	hook.Run( "GameContentChanged" )

end )
