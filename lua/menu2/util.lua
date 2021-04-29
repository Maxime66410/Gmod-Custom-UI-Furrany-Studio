hook.Add( "InGame", "OpenGizehMenu", function(is)
	if is and file.Exists("bonus_menu_onoff.txt","DATA") then
		RunConsoleCommand("executer", "open.lua")
	end
end)
do 
	local developer = GetConVar("developer")
	_G.DEVELOPER = developer:GetBool()

	function IsDeveloper(n)
		return developer:GetInt() >= (n or 1)
	end
end
--if IsDeveloper() then
	local function lua_run_menu(_,_,_,code)
		local func = CompileString(code,"",false)
		if isstring(func) then
			Msg"Invalid syntax> "print(func)
			return
		end
		MsgN("> ",code)
		xpcall(func,function(err)
			print(debug.traceback(err))
		end)
	end
	concommand.Add("lua_run_menu",lua_run_menu)
--end
function gamemenucommand(str)
	RunGameUICommand(str)
end
local function FindInTable( tab, find, parents, depth )
	depth = depth or 0
	parents = parents or ""
	if ( !istable( tab ) ) then return end
	if ( depth > 3 ) then return end
	depth = depth + 1
	for k, v in pairs ( tab ) do
		if ( type(k) == "string" ) then
			if ( k && k:lower():find( find:lower() ) ) then
				Msg("\t", parents, k, " - (", type(v), " - ", v, ")\n")
			end
			if ( istable(v) &&
				k != "_R" &&
				k != "_E" &&
				k != "_G" &&
				k != "_M" &&
				k != "_LOADED" &&
				k != "__index" ) then
				local NewParents = parents .. k .. ".";
				FindInTable( v, find, NewParents, depth )
			end
		end
	end
end
local function Find( ply, command, arguments )
	if ( IsValid(ply) && ply:IsPlayer() && !ply:IsAdmin() ) then return end
	if ( !arguments[1] ) then return end
	Msg("Finding '", arguments[1], "':\n\n") 
	FindInTable( _G, arguments[1] )
	FindInTable( debug.getregistry(), arguments[1] )
	Msg("\n\n")
end
concommand.Add( "lua_find_menu", Find, nil, "", { FCVAR_DONTRECORD } )
local iter iter=function(t,cb)
	for k,v in next,t do
		if istable(v) then
			iter(v,cb)
		else
			cb(v,k)
		end
	end
end
hook.Add( "MenuStart", "Menu2", function()
	print"MenuStart"
end )
hook.Add( "ConsoleVisible", "Menu2", function(is)
	print(is 
		and	'<console activé>'
		or	'<console désactivé>'
	)
end )
hook.Add( "InGame", "Menu2", function(is)
	print(is and "InGame" or "Out of game")
end )
hook.Add( "LoadingStatus", "Menu2", function(status)
	print("LoadingStatus",status)
end )
local isingame = IsInGame()
local wasingame = false
local status = GetLoadStatus()
local console
local alt
hook.Add( "Think", "Menu2", function()
	alt = not alt if alt then return end
	local is=IsInGame()
	if is~=isingame then
		isingame=is
		wasingame = wasingame or isingame
		hook.Call("InGame",nil,isingame)
	end
	local s=GetLoadStatus()
	if s~=status then
		status=s
		hook.Call("LoadingStatus",nil,status)
	end
	local s=gui.IsConsoleVisible()
	if s~=console then
		console=s
		hook.Call("ConsoleVisible",nil,console)
	end
end )
function WasInGame()
	return wasingame
end
local games = engine.GetGames()
local addons = engine.GetAddons()
hook.Add( "GameContentChanged", "Menu2", function()
	local games_new = engine.GetGames()
	local _ = games
	games = games_new
	local games = _
	local addons_new = engine.GetAddons()
	local _ = addons
	addons = addons_new
	local addons = _
	local wasmount = false
	local wasaddon = false
	for k,new in next,games_new do
		local old = games[k]
		assert(old.depot==new.depot)
		if old.mounted ~= new.mounted then
			print("MOUNT",new.title,new.mounted and "MOUNTED" or "UNMOUNTED")
			wasmount=true
		end
	end
	for k,new in next,addons_new do
		local old
		for k,v in next,addons do
			if v.file == new.file then
				old = v 
				break
			end
		end
		if not old then 
			print("ADDON CHARGÉ:",new.mounted and "(M)" or "  ",new.title)
			wasaddon=true
			continue
		end
		assert(old.depot==new.depot)
		if old.mounted ~= new.mounted then
			print("MOUNT",new.title,"\t",new.mounted and "MOUNTED" or "UNMOUNTED")
			wasaddon=true
		end
	end
	for k,old in next,addons do
		local new 
		for k,v in next,addons_new do
			if v.file == old.file then
				new = v
				break
			end
		end
		if not new then 
			MsgN("Removed ",old.title)
			nothing=false
			continue
		end
	end
	if IsDeveloper(2) then print("MENU: Unhandled GameContentChanged") end
	hook.Call("GameContentsChanged",nil,wasmount,wasaddon)
end )
SelectGamemode = function ( g )
	RunConsoleCommand( "gamemode", g )
end
function SetMounted(game,yesno)
	engine.SetMounted(game.depot,yesno==nil or yesno)
end
function SearchWorkshop(str)
	str = string.JavascriptSafe(str)
	str = "http://steamcommunity.com/workshop/browse?searchtext="..str.."&childpublishedfileid=0&section=items&appid=4000&browsesort=trend&requiredtags[]=-1"
	gui.OpenURL(str)
end
function CompileFile(path)
	local f = file.Open(path,'rb','LuaMenu')
	if not f then
		ErrorNoHalt("Could not open: "..path..'\n')
		return
	end	
	local str = f:Read(f:Size())
	f:Close()
	local func = CompileString(str,'@'..path,false)
	if isstring(func) then
		error(func)
	else
		return func
	end
end