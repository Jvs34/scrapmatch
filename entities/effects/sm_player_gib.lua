AddCSLuaFile()

--TODO: from the bitflags passed from sm_player_gib_main get the hitbox bounds of the player
--and use them for the physics instead of the convex meshes of the ragdoll
--then rotate the bounds by that bone matrix angle and then construct the physics mesh we're going to use

function EFFECT:Init( data )

	self.LifeTime = CurTime() + 1	--TODO: check from the convar
	
	self.ConvexMesh = {}
	
	self.Owner = data:GetEntity()
	self.BoneMask = data:GetAttachment()	-- up to 32 bones in this mask , and these are the actual bone indexes, not the physics bones one
	
	--go through all the player's bones , see if that bone is in the bone mask and that bone has
	--hitboxes
	--if that bone has a physics bone associated and it's not in the bone mask, shrink it
	--otherwise leave it as it is ( this is mainly for finger bones )
	
end

function EFFECT:Think()
	
	
	if self.LifeTime <= CurTime() then
		return false
	end
	
	return true
end

function EFFECT:Render()
	
	self:DrawModel()
end