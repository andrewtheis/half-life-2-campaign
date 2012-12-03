// Send the required resources to the client
resource.AddFile("materials/hl2c_nav_marker.vmt")
resource.AddFile("materials/hl2c_nav_marker.vtf")
resource.AddFile("materials/hl2c_nav_pointer.vmt")
resource.AddFile("materials/hl2c_nav_pointer.vtf")


// Send the required lua files to the client
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("cl_scoreboard.lua")
AddCSLuaFile("cl_scoreboard_playerlist.lua")
AddCSLuaFile("cl_scoreboard_playerrow.lua")
AddCSLuaFile("sh_config.lua")
AddCSLuaFile("sh_init.lua")
AddCSLuaFile("sh_player.lua")


// Include the required lua files
include("sh_init.lua")


// Include the configuration for this map
if file.Exists("../gamemodes/half-life_2_campaign/gamemode/maps/"..game.GetMap()..".lua") then
	include("maps/"..game.GetMap()..".lua")
end


// Create console variables to make these config vars easier to access
if !ConVarExists("hl2c_admin_physgun") then
	CreateConVar("hl2c_admin_physgun", ADMIN_NOCLIP, FCVAR_NOTIFY)
	CreateConVar("hl2c_admin_noclip", ADMIN_PHYSGUN, FCVAR_NOTIFY)
end


// Precache all the player models ahead of time
for _, playerModel in pairs(PLAYER_MODELS) do
	util.PrecacheModel(playerModel)
end


// Called when the player attempts to suicide
function GM:CanPlayerSuicide(pl)
	if pl:Team() == TEAM_COMPLETED_MAP then
		pl:ChatPrint("You cannot suicide once you've completed the map.")
		return false
	elseif pl:Team() == TEAM_DEAD then
		pl:ChatPrint("This may come as a suprise, but you are already dead.")
		return false
	end
	
	return true
end 


// Creates a spawn point
function GM:CreateSpawnPoint(pos, yaw)
	local ips = ents.Create("info_player_start")
	ips:SetPos(pos)
	ips:SetAngles(Vector(0, yaw, 0))
	ips:Spawn()
end


// Creates a trigger delaymapload
function GM:CreateTDML(min, max)
	tdmlPos = max - ((max - min) / 2)
	
	local tdml = ents.Create("trigger_delaymapload")
	tdml:SetPos(tdmlPos)
	tdml.min = min
	tdml.max = max
	tdml:Spawn()
end


// Called when the player dies
function GM:DoPlayerDeath(pl, attacker, dmgInfo)
	pl.deathPos = pl:EyePos()
	
	// Add to deadPlayers table to prevent respawning on re-connect
	if !table.HasValue(deadPlayers, pl:UniqueID()) then
		table.insert(deadPlayers, pl:UniqueID())
	end
	
	pl:RemoveVehicle()
	pl:Flashlight(false)
	pl:CreateRagdoll()
	pl:SetTeam(TEAM_DEAD)
	pl:AddDeaths(1)
end


// Called when map entities spawn
function GM:EntityKeyValue(ent, key, value)
	if ent:GetClass() == "trigger_changelevel" && key == "map" then
		ent.map = value
	end
end


// Called when an entity has received damage	  
function GM:EntityTakeDamage(ent, inflictor, attacker, amount, dmgInfo)
	if ent && ent:IsValid() && !ent:IsPlayer() && attacker && attacker:IsValid() && attacker:IsPlayer() && attacker:Alive() then
		if attacker:GetActiveWeapon() && attacker:GetActiveWeapon():IsValid() && attacker:GetActiveWeapon():GetClass() == "weapon_crowbar" then
			dmgInfo:ScaleDamage(0.4)
		elseif attacker:InVehicle() && attacker:GetVehicle() && attacker:GetVehicle():GetClass() == "prop_vehicle_airboat" then
			dmgInfo:SetDamage(1)
		end
	end
end


// Called by GoToNextLevel
function GM:GrabAndSwitch()
	for _, pl in pairs(player.GetAll()) do
		local plInfo = {}
		local plWeapons = pl:GetWeapons()
		
		plInfo.predicted_map = NEXT_MAP
		plInfo.health = pl:Health()
		plInfo.armor = pl:Armor()
		plInfo.score = pl:Frags()
		plInfo.deaths = pl:Deaths()
		plInfo.model = pl.modelName
		
		if plWeapons && #plWeapons > 0 then
			plInfo.loadout = {}
			
			for _, wep in pairs(plWeapons) do
				plInfo.loadout[wep:GetClass()] = {pl:GetAmmoCount(wep:GetPrimaryAmmoType()), pl:GetAmmoCount(wep:GetSecondaryAmmoType())}
			end
		end
		
		file.Write("half-life_2_campaign/"..pl:UniqueID()..".txt", util.TableToKeyValues(plInfo))
	end
	
	// Switch maps
	game.ConsoleCommand("changelevel "..NEXT_MAP.."\n")
end


// Called immediately after starting the gamemode  
function GM:Initialize()
	deadPlayers = {}
	difficulty = 1
	changingLevel = false
	checkpointPositions = {}
	nextAreaOpenTime = 0
	startingWeapons = {}
	
	// We want regular fall damage and the ai to attack players and stuff
	game.ConsoleCommand("ai_disabled 0\n")
	game.ConsoleCommand("ai_ignoreplayers 0\n")
	game.ConsoleCommand("hl2_episodic 0\n")
	game.ConsoleCommand("mp_falldamage 1\n")
	game.ConsoleCommand("physgun_limited 1\n")
	if string.find(game.GetMap(), "ep1_") || string.find(game.GetMap(), "ep2_") then
		game.ConsoleCommand("hl2_episodic 1\n")
	end
	
	// Jeep
	local jeep = {
		Name = "Jeep",
		Class = "prop_vehicle_jeep_old",
		Model = "models/buggy.mdl",
		KeyValues = {	
			vehiclescript =	"scripts/vehicles/jeep_test.txt",
		}
	}
	list.Set("Vehicles", "Jeep", jeep)
	
	// Airboat
	local airboat = {
		Name = "Airboat Gun",
		Class = "prop_vehicle_airboat",
		Category = Category,
		Model = "models/airboat.mdl",
		KeyValues = {
			vehiclescript = "scripts/vehicles/airboat.txt",
			EnableGun = 0
		}
	}
	list.Set("Vehicles", "Airboat", airboat)
	
	// Airboat w/gun
	local airboatGun = {
		Name = "Airboat Gun",
		Class = "prop_vehicle_airboat",
		Category = Category,
		Model = "models/airboat.mdl",
		KeyValues = {
			vehiclescript = "scripts/vehicles/airboat.txt",
			EnableGun = 1
		}
	}
	list.Set("Vehicles", "Airboat Gun", airboatGun)
	
	// Jalopy
	local jalopy = {
		Name = "Jalopy",
		Class = "prop_vehicle_jeep",
		Model = "models/vehicle.mdl",
		KeyValues = {	
			vehiclescript =	"scripts/vehicles/jalopy.txt",
		}
	}
	list.Set("Vehicles", "Jalopy", jalopy)
end


// Called as soon as all map entities have been spawned 
function GM:InitPostEntity()
	if !NEXT_MAP then
		game.ConsoleCommand("changelevel d1_trainstation_01\n")
		return
	end
	
	// Remove old spawn points
	for _, ips in pairs(ents.FindByClass("info_player_start")) do
		if !ips:HasSpawnFlags(1) || INFO_PLAYER_SPAWN then
			ips:Remove()
		end
	end
	
	// Setup INFO_PLAYER_SPAWN
	if INFO_PLAYER_SPAWN then
		GAMEMODE:CreateSpawnPoint(INFO_PLAYER_SPAWN[1], INFO_PLAYER_SPAWN[2])
	end
	
	// Setup TRIGGER_CHECKPOINT
	if TRIGGER_CHECKPOINT then
		for _, tcpInfo in pairs(TRIGGER_CHECKPOINT) do
			local tcp = ents.Create("trigger_checkpoint")
			
			tcp.min = tcpInfo[1]
			tcp.max = tcpInfo[2]
			tcp.pos = tcp.max - ((tcp.max - tcp.min) / 2)
			tcp.skipSpawnpoint = tcpInfo[3]
			tcp.OnTouchRun = tcpInfo[4]
			
			tcp:SetPos(tcp.pos)
			tcp:Spawn()
			
			table.insert(checkpointPositions, tcp.pos)
		end
	end
	
	// Setup TRIGGER_DELAYMAPLOAD
	if TRIGGER_DELAYMAPLOAD then
		GAMEMODE:CreateTDML(TRIGGER_DELAYMAPLOAD[1], TRIGGER_DELAYMAPLOAD[2])
		
		for _, tcl in pairs(ents.FindByClass("trigger_changelevel")) do
			tcl:Remove()
		end
	else
		for _, tcl in pairs(ents.FindByClass("trigger_changelevel")) do
			if tcl.map == NEXT_MAP then			
				local tclMin, tclMax = tcl:WorldSpaceAABB()
				GAMEMODE:CreateTDML(tclMin, tclMax)
			end
			tcl:Remove()
		end
	end
	table.insert(checkpointPositions, tdmlPos)
	
	umsg.Start("SetCheckpointPosition", RecipientFilter():AddAllPlayers())
	umsg.Vector(checkpointPositions[#checkpointPositions])
	umsg.End()
	
	// Remove all triggers that cause the game to "end"
	local triggerMultiples = ents.FindByClass("trigger_multiple")
	for _, tm in pairs(triggerMultiples) do
		if tm:GetName() == "fall_trigger" then
			tm:Remove()
		end
	end
end 


// Called automatically or by the console command
function GM:NextMap()
	if changingLevel then
		return
	end
	
	changingLevel = true
	
	umsg.Start("NextMap", RecipientFilter():AddAllPlayers())
	umsg.Long(CurTime())
	umsg.End()
	
	timer.Simple(NEXT_MAP_TIME, GAMEMODE.GrabAndSwitch)
end
concommand.Add("hl2c_next_map", function(pl) if pl:IsAdmin() then GAMEMODE:NextMap() end end)


// Called when an NPC dies
function GM:OnNPCKilled(npc, killer, weapon)
	if killer && killer:IsValid() && killer:IsVehicle() && killer:GetDriver():IsPlayer() then
		killer = killer:GetDriver()
	end
	
	// If the killer is a player then decide what to do with their points
	if killer && killer:IsValid() && killer:IsPlayer() && npc && npc:IsValid() then
		if table.HasValue(GODLIKE_NPCS, npc:GetClass()) then
			game.ConsoleCommand("kickid "..killer:UserID().." \"Killed an important NPC actor!\"\n")
			GAMEMODE:RestartMap()
		elseif NPC_POINT_VALUES[npc:GetClass()] then
			killer:AddFrags(NPC_POINT_VALUES[npc:GetClass()])
		else
			killer:AddFrags(1)
		end
	end
	
	// Convert the inflictor to the weapon that they're holding if we can. 
 	if weapon && weapon != NULL && killer == weapon && (weapon:IsPlayer() || weapon:IsNPC()) then 
 		weapon = weapon:GetActiveWeapon() 
 		if killer == NULL then weapon = killer end 
 	end 
 	
	// Defaults
 	local weaponClass = "World" 
 	local killerClass = "World" 
 	
	// Change to actual values if not default
 	if weapon && weapon != NULL then weaponClass = weapon:GetClass() end 
 	if killer && killer != NULL then killerClass = killer:GetClass() end 
	
	// Send a message
 	if killer && killer != NULL && killer:IsPlayer() then 
 		umsg.Start("PlayerKilledNPC") 
 		umsg.String(npc:GetClass()) 
 		umsg.String(weaponClass) 
 		umsg.Entity(killer) 
 		umsg.End() 
 	end
end


// Called when a player tries to pickup a weapon
function GM:PlayerCanPickupWeapon(pl, weapon) 
	if pl:Team() != TEAM_ALIVE || weapon:GetClass() == "weapon_stunstick" || (weapon:GetClass() == "weapon_physgun" && !pl:IsAdmin()) then
		weapon:Remove()
		return false
	end
	
	return true
end


// Called when a player disconnects
function GM:PlayerDisconnected(pl)
	if file.Exists("half-life_2_campaign/"..pl:UniqueID()..".txt") then
		file.Delete("half-life_2_campaign/"..pl:UniqueID()..".txt")
	end
	
	pl:RemoveVehicle()
	
	if isDedicatedServer() && #player.GetAll() == 1 then
		game.ConsoleCommand("changelevel "..game.GetMap().."\n")
	end
end


// Called just before the player's first spawn 
function GM:PlayerInitialSpawn(pl)
	pl.startTime = CurTime()
	pl:SetTeam(TEAM_ALIVE)
	
	// Grab previous map info
	local plUniqueId = pl:UniqueID()
	if file.Exists("half-life_2_campaign/"..plUniqueId..".txt") then
		pl.info = util.KeyValuesToTable(file.Read("half-life_2_campaign/"..plUniqueId..".txt"))
		
		if pl.info.predicted_map != game.GetMap() || RESET_PL_INFO then
			file.Delete("half-life_2_campaign/"..plUniqueId..".txt")
			pl.info = nil
		elseif RESET_WEAPONS then
			pl.info.loadout = nil
		end
	end
	
	// Set current checkpoint
	umsg.Start("PlayerInitialSpawn", pl)
	umsg.Vector(checkpointPositions[1])
	umsg.End()
end 


// Called by GM:PlayerSpawn
function GM:PlayerLoadout(pl)
	if pl.info && pl.info.loadout then
		for wep, ammo in pairs(pl.info.loadout) do
			pl:Give(wep)
		end
		
		pl:RemoveAllAmmo()
		
		for _, wep in pairs(pl:GetWeapons()) do
			local wepClass = wep:GetClass()
			
			if pl.info.loadout[wepClass] then
				pl:GiveAmmo(tonumber(pl.info.loadout[wepClass]["1"]), wep:GetPrimaryAmmoType())
				pl:GiveAmmo(tonumber(pl.info.loadout[wepClass]["2"]), wep:GetSecondaryAmmoType())
			end
		end
	elseif startingWeapons && #startingWeapons > 0 then
		for _, wep in pairs(startingWeapons) do
			pl:Give(wep)
		end
	end
	
	// Lastly give physgun to admins
	if GetConVarNumber("hl2c_admin_physgun") == 1 && pl:IsAdmin() then
		pl:Give("weapon_physgun")
	end
end


// Called when the player attempts to noclip
function GM:PlayerNoClip(pl)
	if pl:IsAdmin() && GetConVarNumber("hl2c_admin_noclip") == 1 then
		return true
	end
	
	return false
end 


// Select the player spawn
function GM:PlayerSelectSpawn(pl)
	local spawnPoints = ents.FindByClass("info_player_start")
	return spawnPoints[#spawnPoints]
end 


// Set the player model
function GM:PlayerSetModel(pl)
	if pl.info && pl.info.model then
		pl.modelName = pl.info.model
	else
		local modelName = player_manager.TranslatePlayerModel(pl:GetInfo("cl_playermodel"))
		
		if modelName && table.HasValue(PLAYER_MODELS, string.lower(modelName)) then
			pl.modelName = modelName
		else
			pl.modelName = PLAYER_MODELS[math.random(1, #PLAYER_MODELS)]
		end
	end
	
	util.PrecacheModel(pl.modelName)
	pl:SetModel(pl.modelName)
end


// Called when a player spawns 
function GM:PlayerSpawn(pl)
	if pl:Team() == TEAM_DEAD then
		pl:Spectate(OBS_MODE_ROAMING)
		pl:SetPos(pl.deathPos)
		pl:SetNoTarget(true)
		
		return
	end
	
	// Player vars
	pl.energy = 100
	pl.givenWeapons = {}
	pl.healthRemoved = 0
	pl.nextEnergyCycle = 0
	pl.nextSetHealth = 0
	pl.sprintDisabled = false
	pl.vulnerable = false
	timer.Simple(VULNERABLE_TIME, function(pl) if pl && pl:IsValid() then pl.vulnerable = true end end, pl)
	
	// Speed, loadout, and model
	GAMEMODE:SetPlayerSpeed(pl, 190, 320)
	GAMEMODE:PlayerSetModel(pl)
	GAMEMODE:PlayerLoadout(pl)
	
	// Set stuff from last level
	if pl.info then
		if pl.info.health > 0 then
			pl:SetHealth(pl.info.health)
		end
		
		if pl.info.armor > 0 then
			pl:SetArmor(pl.info.armor)
		end
		
		pl:SetFrags(pl.info.score)
		pl:SetDeaths(pl.info.deaths)
	end
	
	// Players should avoid players
	pl:SetAvoidPlayers(true)
	pl:SetNoTarget(false)
	
	// If the player died before, kill them again
	if table.HasValue(deadPlayers, pl:UniqueID()) then
		pl:PrintMessage(HUD_PRINTTALK, "You may not respawn until the next map. Nice try though.")
		
		pl.deathPos = pl:EyePos()
		
		pl:RemoveVehicle()
		pl:Flashlight(false)
		pl:SetTeam(TEAM_DEAD)
		pl:AddDeaths(1)
		
		pl:KillSilent()
	end
end


// Called when a player uses their flashlight
function GM:PlayerSwitchFlashlight(pl, on)
	if pl:Team() != TEAM_ALIVE then
		return false
	end
	
	return true
end


// Called when a player uses something
function GM:PlayerUse(pl, ent)
	if ent:GetName() == "telescope_button" || pl:Team() != TEAM_ALIVE then
		return false
	end
	
	return true
end


// Called automatically and by the console command
function GM:RestartMap()
	if changingLevel then
		return
	end
	
	changingLevel = true
	
	umsg.Start("RestartMap", RecipientFilter():AddAllPlayers())
	umsg.Long(CurTime())
	umsg.End()
	
	for _, pl in pairs(player.GetAll()) do
		pl:SendLua("GAMEMODE.ShowScoreboard = true")
	end
	
	timer.Simple(RESTART_MAP_TIME, game.ConsoleCommand, "changelevel "..game.GetMap().."\n")
end
concommand.Add("hl2c_restart_map", function(pl, command, arguments) if pl:IsAdmin() then GAMEMODE:RestartMap() end end)


// Called every time a player does damage to an npc
function GM:ScaleNPCDamage(npc, hitGroup, dmgInfo)
	local attacker = dmgInfo:GetAttacker()
	
	// If a friendly/godlike npc do no damage
	if table.HasValue(GODLIKE_NPCS, npc:GetClass()) || (attacker:IsPlayer() && table.HasValue(FRIENDLY_NPCS, npc:GetClass())) then
		dmgInfo:SetDamage(0)
		return
	end
	
	// Fix airboat doing no damage/gravity gun punt should kill NPC's
	if attacker && attacker:IsValid() && attacker:IsPlayer() then
		if attacker:InVehicle() && attacker:GetVehicle() && attacker:GetVehicle():GetClass() == "prop_vehicle_airboat" then
			dmgInfo:SetDamage(1)
		elseif SUPER_GRAVITY_GUN && attacker:GetActiveWeapon() && attacker:GetActiveWeapon():GetClass() == "weapon_physcannon" then
			dmgInfo:SetDamage(100)
		end
	end
	
	// Where are we hitting?
	if hitGroup == HITGROUP_HEAD then
		hitGroupScale = 2
	else
		hitGroupScale = 1
	end
	
	// Calculate the damage
	dmgInfo:ScaleDamage(hitGroupScale / difficulty)
end


// Scale the damage based on being shot in a hitbox 
function GM:ScalePlayerDamage(pl, hitGroup, dmgInfo)
	if hitGroup == HITGROUP_HEAD then
		hitGroupScale = 2
	else
		hitGroupScale = 1
	end
	
	// Calculate the damage
	dmgInfo:ScaleDamage(hitGroupScale * difficulty)
end 


// Called when player presses their help key
function GM:ShowHelp(pl)
	umsg.Start("ShowHelp", pl)
	umsg.End()
end


// Called when a player presses their show team key
function GM:ShowTeam(pl)
	umsg.Start("ShowTeam", pl)
	umsg.End()
end


// Called when player wants a vehicle
function GM:ShowSpare1(pl)
	if pl:Team() != TEAM_ALIVE || pl:InVehicle() then
		return
	end
	
	pl:RemoveVehicle()
	
	// Spawn the vehicle
	if ALLOWED_VEHICLE then
		local vehicleList = list.Get("Vehicles")
		local vehicle = vehicleList[ALLOWED_VEHICLE]
		
		if !vehicle then
			return
		end
		
		// Create the new entity
		pl.vehicle = ents.Create(vehicle.Class)
		pl.vehicle:SetModel(vehicle.Model)
		
		// Set keyvalues
		for a, b in pairs(vehicle.KeyValues) do
			pl.vehicle:SetKeyValue(a, b)
		end
		
		// Enable gun on jeep
		if ALLOWED_VEHICLE == "Jeep" then
			pl.vehicle:Fire("enablegun", 1)
		end
		
		// Set pos/angle and spawn
		local plAngle = pl:GetAngles()
		pl.vehicle:SetPos(pl:GetPos() + Vector(0, 0, 48) + plAngle:Forward() * 100)
		pl.vehicle:SetAngles(Angle(0, plAngle.y + 180, 0))
		pl.vehicle:Spawn()
		pl.vehicle:Activate()
		pl.vehicle.creator = pl
	else
		pl:PrintMessage(HUD_PRINTTALK, "You may not spawn a vehicle at this time.")
	end
end


// Called when player wants to remove their vehicle
function GM:ShowSpare2(pl)
	pl:RemoveVehicle()
end


// Called every frame 
function GM:Think()
	if #player.GetAll() > 0 && #team.GetPlayers(TEAM_ALIVE) + #team.GetPlayers(TEAM_COMPLETED_MAP) <= 0 then
		GAMEMODE:RestartMap()
	end
	
	// For each player
	for _, pl in pairs(player.GetAll()) do
		if !pl:Alive() || pl:Team() != TEAM_ALIVE then
			return
		end
		
		// Give them weapons they don't have
		for _, pl2 in pairs(player.GetAll()) do
			if pl != pl2 && pl2:Alive() && !pl:InVehicle() && !pl2:InVehicle() && pl2:GetActiveWeapon():IsValid() && !pl:HasWeapon(pl2:GetActiveWeapon():GetClass()) && !table.HasValue(pl.givenWeapons, pl2:GetActiveWeapon():GetClass()) && pl2:GetActiveWeapon():GetClass() != "weapon_physgun" then
				pl:Give(pl2:GetActiveWeapon():GetClass())
				table.insert(pl.givenWeapons, pl2:GetActiveWeapon():GetClass())
			end
		end
		
		// Sprinting and water level
		if pl.nextEnergyCycle < CurTime() then
			if !pl:InVehicle() && ((pl:GetVelocity():Length() > 315 && pl:KeyDown(IN_SPEED)) || pl:WaterLevel() == 3) && pl.energy > 0 then
				pl.energy = pl.energy - 1
			elseif pl.energy < 100 then
				pl.energy = pl.energy + .5
			end
			
			umsg.Start("UpdateEnergy", pl)
			umsg.Short(pl.energy)
			umsg.End()
			
			pl.nextEnergyCycle = CurTime() + 0.1
		end
		
		// Now check if they have enough energy 
		if pl.energy < 2 then
			if !pl.sprintDisabled then
				pl.sprintDisabled = true
				GAMEMODE:SetPlayerSpeed(pl, 190, 190)
			end
			
			// Now remove health if underwater
			if pl:WaterLevel() == 3 && pl.nextSetHealth < CurTime() then
				pl.nextSetHealth = CurTime() + 1
				pl:SetHealth(pl:Health() - 10)
				
				umsg.Start("DrowningEffect", pl)
				umsg.End()
				
				if pl:Alive() && pl:Health() < 1 then
					pl:Kill()
				else
					pl.healthRemoved = pl.healthRemoved + 10
				end
			end				
		elseif pl.energy >= 15 && pl.sprintDisabled then
			pl.sprintDisabled = false
			GAMEMODE:SetPlayerSpeed(pl, 190, 320)
		end
		
		// Give back health if we can
		if pl:WaterLevel() <= 2 && pl.nextSetHealth < CurTime() && pl.healthRemoved > 0 then
			pl.nextSetHealth = CurTime() + 1
			pl:SetHealth(pl:Health() + 10)
			pl.healthRemoved = pl.healthRemoved - 10
		end
	end
	
	// Change the difficulty according to number of players
	difficulty = math.Clamp((#player.GetAll() + 1) / 3, DIFFICULTY_RANGE[1], DIFFICULTY_RANGE[2])
	
	// Open area portals
	if nextAreaOpenTime <= CurTime() then
		for _, fap in pairs(ents.FindByClass("func_areaportal")) do
			fap:Fire("Open")
		end
		
		nextAreaOpenTime = CurTime() + 3
	end
end


// Player just picked up or was given a weapon
function GM:WeaponEquip(weapon)
	if weapon && weapon:IsValid() && weapon:GetClass() && !table.HasValue(startingWeapons, weapon:GetClass()) then
		table.insert(startingWeapons, weapon:GetClass())
	end
end