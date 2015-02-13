AddCSLuaFile()

ENT.Type 			= "anim"
ENT.Base 			= "base_entity"

function ENT:Initialize()
	if SERVER then
		self:SetLagCompensated( true )	--so people can shoot us down with traces or other hitscan stuff ( like the magnetic shield )
		self:SetProjectileGravity( Vector( 0, 0 , -600 ) )
		self:SetLifeTime( -1 )
		
		if self:GetMinBounds() == vector_origin or self:GetMaxBounds() == vector_origin then
			self:SetMinBounds( Vector( -16 , -16 , -16 ) )
			self:SetMaxBounds( Vector( 16 , 16 , 16 ) )
		end
		
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:PhysicsInitBox( self:GetMinBounds() , self:GetMaxBounds() )
		self:SetCollisionBounds( self:GetMinBounds() , self:GetMaxBounds() )
		
		local physobj = self:GetPhysicsObject()
		if IsValid( physobj ) then
			physobj:EnableGravity( false )
			physobj:EnableDrag( false )
			
			physobj:Wake()
		end
	else
		self:SetRenderBounds( self:GetMinBounds() , self:GetMaxBounds() )
	end
end

function ENT:SetupDataTables()
	self:NetworkVar( "Float" , 0 , "LifeTime" )
	self:NetworkVar( "Vector" , 0 , "MinBounds" )
	self:NetworkVar( "Vector" , 1 , "MaxBounds" )
	self:NetworkVar( "Vector" , 2 , "ProjectileGravity" )
end

function ENT:Think()
	if self:IsEFlagSet( EFL_KILLME ) then
		return
	end
	
	if SERVER then
		if self:GetLifeTime() ~= -1 then
			if self:GetLifeTime() <= CurTime() then
				self:OnExpired()
				self:Destroy()
			end
		end
	end
end

if SERVER then
	function ENT:Destroy()
		self:SetLifeTime( -1 )
		self:Remove()
	end
	
	--simulate the projectile physics here
	function ENT:PhysicsUpdate( physobj )
	
		local endvel = physobj:GetVelocity()
		
		local gravity = self:GetProjectileGravity() * FrameTime()
		
		endvel = endvel + gravity
		
		physobj:SetVelocity( endvel )
		physobj:SetAngles( endvel:Angle() )
	end
	
	function ENT:PhysicsCollide( physobj, event )
		self:OnImpact( event.HitEntity , event )
	end
	
	function ENT:OnExpired()

	end
	
	--ent might be invalid too
	function ENT:OnImpact( ent , event )
		self:Destroy()
	end
end