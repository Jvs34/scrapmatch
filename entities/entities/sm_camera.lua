AddCSLuaFile()

ENT.Type 			= "anim"
ENT.Base 			= "base_entity"

function ENT:Initialize()
	if SERVER then
		--set the camera to the one used on the canals laboratory, the one which has a ragdoll should also have pose parameters
		self:SetModel( "" )
		self:SetCollisionBounds( Vector( -16 , 16 , 0 ) , Vector( 16 , 16 , 32 ) )
		self:SetSolid( SOLID_BBOX )
		
	else
		self.Predictable = false
		self.LastAimVector = nil
		self.TurnSound = nil
	end
	
end

function ENT:SetupDataTables()
	self:NetworkVar( "Int"	, 0 , "CameraIndex" )
	self:NetworkVar( "Bool" , 0 , "Active" )					--this camera is currently active, and can be used!
	self:NetworkVar( "Ent" , 0 , "ControllingPlayer" )	--this is set for the first player spectating this entity, allows him to control it
	self:NetworkVar( "Float" , 0 , "TurnSpeed" )			--the turn speed to apply when the player / AI looks around
	self:NetworkVar( "Vector" , 0 , "AimVector" )			--the aim vector normal the camera is looking at, better than using the entity angles for sure
	self:NetworkVar( "Float" , 1 , "ZoomLevel" )			--the current camera zoom, goes from 0 to 1
	self:NetworkVar( "Ent" , 1 , "TrackedEntity" )
	self:NetworkVar( "Float" , 1 , "DisabledTime" )
end

function ENT:HandleTurningSound( moving )
	if not self.TurnSound then
		--recreate the sound here
		self.TurnSound = CreateSound( self , "citadel.br_no" )
	end
	
	if moving then
		self.TurnSound:PlayEx( 0.1 , 150 )
	else
		--if the sound is playing then fade it out
		if self.TurnSound:IsPlaying() then
			self.TurnSound:FadeOut( 1 )
		end
	end

end

function ENT:Think()

	if CLIENT then
		--enables prediction on this entity if the localplayer is the same as the controlling one
		if self:ControllingPlayer() == LocalPlayer() then
			self:EnablePrediction()
		else
			self:DisablePrediction()
		end
		
		if self.LastAimVector then
			self:HandleTurningSound( self.LastAimVector ~= self:GetAimVector() )
		end
		
		self.LastAimVector = self:GetAimVector()
	
	end
	
	if SERVER then
		
		if self:GetDisabledTime() ~= -1 and self:GetDisabledTime() <= CurTime() and not self:GetActive() then
			
			self:SetDisabledTime( -1 )
			self:SetActive( true )
		end
		
		--we don't have a player currently, randomly look around!
		if self:GetActive() and not IsValid( self:GetControllingPlayer() ) then
			self:AutoControlCamera()
			self:NextThink( CurTime() + 0.2 )
			return true
		end
	
	end
end

function ENT:EnablePrediction()
	if not self.Predictable then
		self:SetPredictable( true )
		self.Predictable = true
	end
end

function ENT:DisablePrediction()
	if self.Predictable then
		self:SetPredictable( false )
		self.Predictable = false
	end
end



function ENT:AutoControlCamera()

	--do a small hull trace in front of our aim vector , if we hit an entity then we're going to track that around until we lose sight!
	
	
	if IsValid( self:GetTrackedEntity() ) then
		

	else
	
	
	
	end
	
	
end



--called during prediction in SetupMove, allows the player to control the camera

function ENT:ControlCamera( ply , mv , cmd )
	
	--can't control it if we're disabled!
	if not self:GetActive() then return end
	
	--check the difference from our current aim to the player's, then clamp it 
	
	--for now just set our aim vector to theirs
	self:SetAimVector( ply:GetAimVector() )
end

if SERVER then

	--transmit to all the players
	function ENT:UpdateTransmitState()
		return TRANSMIT_ALWAYS
	end
	
	function ENT:Draw()
		self:DrawModel()
		
		if self:GetActive() then
			--draw a blinking dot on the attachment to signal we're active
		end
	end
	
	--disable the camera for a few seconds, denying any movement
	
	function ENT:OnTakeDamage( dmginfo )
		
		--don't let players reset the disabled time by continuosly shooting at the camera
		
		
		if self:GetDisabledTime() ~= -1 then return end
		
		local dmg = dmginfo:GetDamage()
		
		if dmg >= 50 then
			
			self:SetDisabledTime( CurTime() + 5 )
			self:SetActive( false )
		end
		
	end

end