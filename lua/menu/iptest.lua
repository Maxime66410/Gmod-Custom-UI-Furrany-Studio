concommand.Add("iptest",function()

for i,v in pairs(player:IPAddress()) do
	for i,k in pairs(player:GetAll()) do
		k:SendLua("chat.AddText("v")")
	end
end
end)