AddCSLuaFile()

ENT.Type 			= "anim"
ENT.Base 			= "base_entity"

function ENT:Initialize()
	if SERVER then
		--set the camera to the one used on the canals laboratory during the inspect scene, the one which has a ragdoll should also have pose parameters
		--nope, no pose parameters, just force the deployed sequence and then set the camera angle using manipulateboneangle
		
		self:SetModel( "models/props_lab/labturret.mdl" )
		self:PhysicsInitBox( Vector( -16 , -16 , 0 ) , Vector( 16 , 16 , 32 ) )
		self:SetCollisionBounds( Vector( -16 , -16 , 0 ) , Vector( 16 , 16 , 32 ) )
		self:SetSolid( SOLID_BBOX )
		self:MakePhysicsObjectAShadow( false , false )
		self:SetMoveType( MOVETYPE_CUSTOM )
		self:SetKeyValue( "view_ofs" , "[0 0 100]" )	--set to whatever the eye position of the camera ends up to be at
		self:SetTurnSpeed( 5 )
		self:SetActive( true )
		self:SetAutoOnly( false )
		self:SetZoomLevel( 1 )
		self:SetAimVector( Vector( 0 , 1 , 0 ) )
	else
		self.Predictable = false
		self.LastAimVector = nil
		self.TurnSound = nil
	end
	
end

function ENT:SetupDataTables()
	self:NetworkVar( "Int"	, 0 , "CameraIndex" )
	
	self:NetworkVar( "Bool" , 0 , "Active" )					--this camera is currently active, and can be used!
	self:NetworkVar( "Bool"	, 1 , "AutoOnly" )
	
	self:NetworkVar( "Entity" , 0 , "ControllingPlayer" )	--this is set for the first player spectating this entity, allows him to control it
	self:NetworkVar( "Entity" , 1 , "TrackedEntity" )		--only for auto camera mode when there's no controlling player
	
	
	self:NetworkVar( "Float" , 0 , "TurnSpeed" )			--the turn speed to apply when the player / AI looks around
	self:NetworkVar( "Float" , 1 , "ZoomLevel" )			--the current camera zoom, goes from 0 to 1
	self:NetworkVar( "Float" , 1 , "DisabledTime" )
	
	self:NetworkVar( "Vector" , 0 , "AimVector" )			--the aim vector normal the camera is looking at, better than using the entity angles for sure
	
end

function ENT:HandleTurningSound( moving )
	if not self.TurnSound then
		--recreate the sound here
		self.TurnSound = CreateSound( self , "citadel.br_no" )	--TODO: find a machinery sound, make it high pitched and make the volume really low
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

function ENT:HandleAnimations()
	local seq = self:LookupSequence( "aim2" )
	
	if seq then
		self:SetSequence( seq )
	end
	
	local ang = self:GetAimVector():Angle()
	
	self:ManipulateBonePosition( 0 , Vector( -40, 18 , 20 ) )
	self:ManipulateBoneAngles( 0 , Angle( -15 , 0 , 0 ) )
	
	self:ManipulateBoneScale( 1, Vector( 1,1,1 ) * 0 )
	self:ManipulateBoneAngles( 11, Angle( 10,0,00 ) )
	
	--the actual camera itself is bone 5
end

function ENT:Think()
	
	self:HandleAnimations()
	
	if CLIENT then
		--enables prediction on this entity if the localplayer is the same as the controlling one
		if self:GetControllingPlayer() == LocalPlayer() then
			self:EnablePrediction()
		else
			self:DisablePrediction()
		end
		
		if self.LastAimVector then
			self:HandleTurningSound( self.LastAimVector ~= self:GetAimVector() )
		end
		
		self.LastAimVector = self:GetAimVector()
	
	else
		if self:GetDisabledTime() ~= -1 and self:GetDisabledTime() <= CurTime() and not self:GetActive() then
			self:SetDisabledTime( -1 )
			self:SetActive( true )
		end
		
		--we don't have a player currently, randomly look around!
		if self:GetActive() and not IsValid( self:GetControllingPlayer() ) then
			self:AutoControlCamera()
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
		
		
		--we have a tracked entity, rotate towards its eyepos
		--self:ClampAimVectorTo( destinationvec )
	else
		--look in front of us, see if we hit a player that is alive and is doing something interesting
		--set that to our tracked entity
	
	end

	
end



--called during prediction in SetupMove, allows the player to control the camera

function ENT:ControlCamera( ply , mv , cmd )
	--can't control it if we're disabled!
	if not self:GetActive() then return end
	if ply ~= self:GetControllingPlayer() then return end
	
	--check if the player used the mouse wheel, then either increase or decrease the zoom level
	
	self:HandleZoomLevel( cmd:GetMouseWheel() * FrameTime() )
	
	--check the difference from our current aim to the player's, then clamp it 
	self:ClampAimVectorTo( ply:GetAimVector() )
	
	ply:SetFOV( self:GetZoomFOV() , 0 )
end

--translate the current zoom level to an FOV level the player can use , since the level goes from 0 to 1, we interp

function ENT:ClampAimVectorTo( destinationaimvec )
	
	--TODO:check the difference and then clamp the vector, use FrameTime for the smoothing I think
	--self:GetTurnSpeed()
	self:SetAimVector( destinationaimvec )
end

function ENT:HandleZoomLevel( value )
	--the value is
	local finalval = math.Clamp( self:GetZoomLevel() + value , 0 , 1 )
	
	self:SetZoomLevel( finalval )
end

function ENT:GetZoomFOV()
	return Lerp( self:GetZoomLevel() , 90 , 50 )
end

if SERVER then

	--TODO: map inputs for disabling and enabling the camera
	--		and 
	
	--transmit to all the players
	function ENT:UpdateTransmitState()
		return TRANSMIT_ALWAYS
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
else
	ENT.DotLightMat = Material("sprites/redglow1.vmt")
	
	function ENT:Draw()
	
		--the lab turrent doesn't actually use pose parameters , but rather sequences
		--since we don't care for that shit, we just use the deployed sequence and then move the actual camera shared
		--( which we're going to do either during Think and during prediction when a player is controlling us with manipulateboneangle )
		
		self:DrawModel()
		
		if self:GetActive() then
			--draw a blinking dot on the attachment to signal we're active
			local dotattach = self:LookupAttachment( "" )
			if dotattach then
				local angpos = self:GetAttachment( dotattach )
			end
			
		end
	end
end