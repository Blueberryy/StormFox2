--[[-------------------------------------------------------------------------
Creates or finds map entities
	Hook:
		StormFox.PostEntityScan 			Gets called after StormFox have located the map entities.
	Convar:
		sf_enable_mapsupport
---------------------------------------------------------------------------]]
StormFox.Ent = {}
CreateConVar("sf_enable_mapsupport","1",{FCVAR_REPLICATED,FCVAR_ARCHIVE},"stormfox.setting.mapsupport")
-- Find or creat entities
	local function GetOrCreate(str,only_get)
		local l = ents.FindByClass(str)
		local con = GetConVar("sf_enable_mapsupport")
		if #l > 0 then
			local s = string.rep(" ",24 - #str)
			MsgC( "	", Color(255,255,255), str, s, Color(55,255,55), "Found", Color( 255, 255, 255), "\n" )
			return l
		end
		if not con:GetBool() or only_get then -- Disabled mapsupport or don't create
			local s = string.rep(" ",24 - #str)
			MsgC( "	", Color(255,255,255), str, s, Color(255,55,55), "Not found", Color( 255, 255, 255), "\n" )
			return
		end
		local ent = ents.Create(str)
		ent:Spawn();
		ent:Activate();
		ent._sfcreated = true
		local s = string.rep(" ",24 - #str)
		MsgC( "	", Color(255,255,255), str, s, Color(155,155,255), "Created", Color( 255, 255, 255), "\n" )
		return {ent}
	end
	local function findEntities()
		StormFox.Msg( "Scanning mapentities ..." )
		local tSunlist = ents.FindByClass( "env_sun" )
		for i = 1, #tSunlist do -- Remove any env_suns, there should be only one but who knows
			tSunlist[ i ]:Fire( "TurnOff" )
		end
		StormFox.Ent.env_skypaints = GetOrCreate( "env_skypaint" )
		StormFox.Ent.light_environments = GetOrCreate( "light_environment", true)
		StormFox.Ent.env_fog_controllers = GetOrCreate( "env_fog_controller" )
		StormFox.Ent.shadow_controls = GetOrCreate( "shadow_control", true )
		StormFox.Ent.env_tonemap_controllers = GetOrCreate("env_tonemap_controller", true )
		StormFox.Ent.env_winds = GetOrCreate("env_wind", true ) -- Can't spawn the wind controller without problems
		--[[-------------------------------------------------------------------------
		Gets called when StormFox has handled map-entities.
		---------------------------------------------------------------------------]]
		hook.Run( "StormFox.PostEntityScan" )
	end
-- If this is first run, wait for InitPostEntity.
	if _STORMFOX_FOUND then
		timer.Simple(0,findEntities)
	else
		hook.Add("InitPostEntity","StormFox.Entities",function()
			_STORMFOX_FOUND = true
			findEntities()
		end)
	end
-- Tell clients about explosions
	util.AddNetworkString("stormfox.entity.explosion")
	hook.Add("EntityRemoved","StormFox.Entitys.Explosion",function(ent)
		if ent:GetClass() ~= "env_explosion" then return end
		local t = ent:GetKeyValues()
		net.Start("stormfox.entity.explosion")
			net.WriteVector(ent:GetPos())
			net.WriteUInt(t.iRadiusOverride or t.iMagnitude, 16)
			net.WriteUInt(t.iMagnitude, 16)
		net.SendPVS(ent:GetPos())
	end)