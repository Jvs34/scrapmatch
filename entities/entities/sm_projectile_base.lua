AddCSLuaFile()

ENT.Type 			= "anim"
ENT.Base 			= "base_entity"

function ENT:Initialize()
	if SERVER then
		self:SetLagCompensated( true )	--so people can shoot us down with traces or other hitscan stuff ( like the magnetic shield )
		self:SetProjectileGravity( Vector( 0, 0 , -600 ) )
		self:SetLifeTime( -1 )
	end
end

function ENT:SetupDataTables()
	self:NetworkVar( "Float" , 0 , "LifeTime" )
end

function ENT:Think()
	if self:IsEFlagSet( EFL_KILLME ) then return end
	
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
	
	function ENT:PhysicsUpdate( physobj )

	end
	
	function ENT:PhysicsCollide( physobj, event )
		if IsValid( event.HitEntity ) then
			self:OnImpact( event.HitEntity , event )
		end
	end
	
	function ENT:OnExpired()

	end

	function ENT:OnImpact( ent , event )
		self:Destroy()
	end
end