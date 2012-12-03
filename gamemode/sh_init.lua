// Include the required lua files
include("sh_config.lua")
include("sh_player.lua")


// General gamemode information
GM.Author = "AMT"


// Constants
FRIENDLY_NPCS = {
	"npc_citizen"
}
GODLIKE_NPCS = {
	"npc_alyx",
	"npc_barney",
	"npc_breen",
	"npc_dog",
	"npc_eli",
	"npc_fisherman",
	"npc_gman",
	"npc_kleiner",
	"npc_magnusson",
	"npc_monk",
	"npc_mossman",
	"npc_vortigaunt"
}


// Create the teams that we are going to use throughout the game
function GM:CreateTeams()
	TEAM_ALIVE = 1
	team.SetUp(TEAM_ALIVE, "", Color(81, 124, 199, 255))
	
	TEAM_COMPLETED_MAP = 2
	team.SetUp(TEAM_COMPLETED_MAP, "Completed Map", Color(81, 124, 199, 255))
	
	TEAM_DEAD = 3
	team.SetUp(TEAM_DEAD, "Dead", Color(81, 124, 199, 255))
end


// Called when map entities spawn
function GM:EntityKeyValue(ent, key, value)
	if ent:GetClass() == "trigger_changelevel" && key == "map" && SERVER then
		ent.map = key
	end
end


// Called when a gravity gun is attempting to punt something
function GM:GravGunPunt(pl, ent) 
 	if ent && ent:IsVehicle() && ent != pl.vehicle && ent.creator then
		return false
	end
	
	return true
end 


// Called when a physgun tries to pick something up
function GM:PhysgunPickup(pl, ent)
	if string.find(ent:GetClass(), "trigger_") || ent:GetClass() == "player" then
		return false
	end
	
	return true
end


// Called when a player entered a vehicle
function GM:PlayerEnteredVehicle(pl, vehicle, role)
	if pl.vehicle != vehicle then
		pl.vehicle = vehicle
		
		if vehicle.creator then
			vehicle.creator.vehicle = nil
		end
		
		vehicle.creator = pl
	end
end


// Players should never collide with each other or NPC's
function GM:ShouldCollide(entA, entB)
	if entA && entB && ((entA:IsPlayer() && (entB:IsPlayer() || table.HasValue(GODLIKE_NPCS, entB:GetClass()) || table.HasValue(FRIENDLY_NPCS, entB:GetClass()))) || (entB:IsPlayer() && (entA:IsPlayer() || table.HasValue(GODLIKE_NPCS, entA:GetClass()) || table.HasValue(FRIENDLY_NPCS, entA:GetClass())))) then
		return false
	else
		return true
	end
end


// Called when a player is being attacked
function GM:PlayerShouldTakeDamage(pl, attacker)
	if pl:Team() != TEAM_ALIVE || !pl.vulnerable || (attacker:IsPlayer() && attacker != pl) || (attacker:IsVehicle() && attacker:GetDriver():IsPlayer()) || table.HasValue(GODLIKE_NPCS, attacker:GetClass()) || table.HasValue(FRIENDLY_NPCS, attacker:GetClass()) then
		return false
	else
		return true
	end
end