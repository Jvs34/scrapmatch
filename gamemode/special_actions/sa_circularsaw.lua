AddCSLuaFile()

local newsa = SA:New( "Circular saw" , "sa_circularsaw", "A quake style melee weapon" )

function newsa:Initialize()
	local weapon = self:GetEntity():GetCustomHandler()
	if IsValid( weapon ) then
		weapon:SetMaxClip( self:GetEntity():GetSlot() , -1 )	--infinite ammo
		weapon:SetClip( self:GetEntity():GetSlot() , -1 )		--infinite ammo
	end
end

function newsa:Attack( viewmodel )

	self:GetEntity():EmitPredictedSound( "Weapon_AR2.Single" )
	self:GetEntity():SetNextAction( CurTime() + 0.25 )
	
end

function newsa:IsWeaponAction()
	return true
end

function newsa:GetSlot()
	return SA.Slots.LEFT_WEAPON
end