// Entity information
ENT.Base = "base_anim"
ENT.Type = "anim"


// Called when the entity first spawns
function ENT:Initialize()
	local w = self.max.x - self.min.x
	local l = self.max.y - self.min.y
	local h = self.max.z - self.min.z
	
	local min = Vector(0 - (w / 2), 0 - (l / 2), 0 - (h / 2))
	local max = Vector(w / 2, l / 2, h / 2)
	
	self:DrawShadow(false)
	self:SetCollisionBounds(min, max)
	self:SetSolid(SOLID_BBOX)
	self:SetCollisionGroup(COLLISION_GROUP_WORLD)
	self:SetMoveType(0)
	self:SetTrigger(true)
end


// Called when an entity touches me :D
function ENT:StartTouch(ent)
	if ent && ent:IsValid() && ent:IsPlayer() && ent:Team() == TEAM_ALIVE then
		ent:SetTeam(TEAM_COMPLETED_MAP)
		
		// Remove their vehicle
		if ent:GetVehicle() && ent:GetVehicle():IsValid() then
			ent:GetVehicle():Remove()
		end
		
		// Freeze them and make sure they don't push people away
		ent:Lock()
		ent:SetMoveType(0)
		ent:SetAvoidPlayers(false)
		
		// Let everyone know that someone entered the loading section
		PrintMessage(HUD_PRINTTALK, Format("%s completed the map (%s) [%i of %i].", ent:Nick(), string.ToMinutesSeconds(CurTime() - ent.startTime), team.NumPlayers(TEAM_COMPLETED_MAP), self.playersAlive))
	end
end


// Checks to see if we should go to the next map
function ENT:Think()
	self.playersAlive = team.NumPlayers(TEAM_ALIVE) + team.NumPlayers(TEAM_COMPLETED_MAP)
	
	if self.playersAlive > 0 && team.NumPlayers(TEAM_COMPLETED_MAP) >= (self.playersAlive * (NEXT_MAP_PERCENT / 100)) then
		GAMEMODE:NextMap()
	end
end