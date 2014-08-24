AddCSLuaFile()

local newsa = SA:New( "Chain gun" , "sa_chaingun", "A quake style ranged weapon" )

function newsa:Initialize()
	
	local weapon = self:GetEntity():GetCustomHandler()
	if IsValid( weapon ) then
		--I GOTTA FIX THIS +1 BULLFUCKING SHIT
		weapon:SetMaxClip( self:GetEntity():GetSlot() , 100 )
		weapon:SetClip( self:GetEntity():GetSlot(), weapon:GetMaxClip( self:GetEntity():GetSlot() ) )
	end
end

function newsa:Attack( viewmodel )

	self:GetEntity():EmitSound( "Weapon_AR2.Single" )
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