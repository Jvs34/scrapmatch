AddCSLuaFile()

local newsa = SA:New( "Chain gun" , "sa_chaingun", "A quake style ranged weapon" )

function newsa:Initialize()
	
	local weapon = self:GetEntity():GetCustomHandler()
	if IsValid( weapon ) then
		weapon:SetMaxClip( self:GetEntity():GetSlot() , 100 )
		weapon:SetClip( self:GetEntity():GetSlot(), weapon:GetMaxClip( self:GetEntity():GetSlot() ) )
	end
end

function newsa:Attack( viewmodel )

	local tracedata = {}
	tracedata.start = self:GetEntity():GetOwner():GetShootPos()
	tracedata.endpos = tracedata.start + self:GetEntity():GetOwner():GetAimVector() * 1024
	tracedata.filter = self:GetEntity():GetOwner()
	tracedata.mins =  Vector( -8, -8, -8 )
	tracedata.maxs =  Vector( 8, 8, 8 )
	
	self:GetEntity():GetOwner():LagCompensation( true )
	
	local tr = util.TraceHull( tracedata )
	
	if tr.Hit then
	
		local dmg = DamageInfo()
		dmg:SetAttacker( self:GetEntity():GetOwner() )
		dmg:SetInflictor( self:GetEntity() )
		dmg:SetDamage( 10 + util.SharedRandom( self:GetClass() , 2 , 10 ) )

		dmg:SetDamageForce( self:GetEntity():GetOwner():GetAimVector() * dmg:GetDamage() * 500 )

		dmg:SetDamagePosition( tr.HitPos )
		dmg:SetDamageTypeFromName( "Bullet" )
		
		if tr.Entity then
			tr.Entity:DispatchTraceAttack(dmg, tr)
		end
    end
	
	self:GetEntity():GetOwner():LagCompensation( false ) 
	
	self:GetEntity():EmitPredictedSound( "Weapon_AR2.Single" )
	self:GetEntity():SetNextAction( CurTime() + 0.25 )
	
end

function newsa:HandleAmmoPickup( percent )
	
	local curammo = weapon:Clip( self:GetEntity():GetSlot()  )
	local maxammo = weapon:GetMaxClip( self:GetEntity():GetSlot()  )
	
	if curammo >= maxammo then return false end
	
	weapon:SetClip( self:GetEntity():GetSlot()  , math.Clamp( curammo + maxammo * percent , 1 , maxammo ) )
	return true
end

function newsa:IsWeaponAction()
	return true
end

function newsa:GetSlot()
	return SA.Slots.RIGHT_WEAPON
end