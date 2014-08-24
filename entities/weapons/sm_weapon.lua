AddCSLuaFile()

SWEP.Author			= "Jvs"
SWEP.Contact		= ""
SWEP.Purpose		= "The scrapmatch weapon base, controls the two other weapon actions"
SWEP.Instructions	= "Left click to shoot left action, right to shoot the right one. Reload to do something I have not decided yet. Also how the fuck are you reading this, this is not sandbox."

SWEP.ViewModelFOV	= 54
SWEP.ViewModelFlip	= true
SWEP.ViewModelFlip1	= false
SWEP.ViewModel			= "models/weapons/v_pistol.mdl"
SWEP.WorldModel		= "models/weapons/w_pistol.mdl"

SWEP.Spawnable			= false
SWEP.AdminOnly				= false

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Automatic		= true
SWEP.Primary.Ammo			= -1

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic		= true
SWEP.Secondary.Ammo			= -1

if CLIENT then
	SWEP.PrintName			= "sm_weapon"
	SWEP.Slot					= 0
	SWEP.SlotPos				= 0
	SWEP.DrawAmmo			= false
	SWEP.DrawCrosshair		= false
	SWEP.SwayScale			= 1
	SWEP.BobScale			= 1
end

function SWEP:SetupDataTables()
	self:NetworkVar( "Int" , 0 , "MaxClip1" )
	self:NetworkVar( "Int" , 1 , "MaxClip2" )
	
	self:NetworkVar( "Float" , 0 , "DisabledTime" )
end

function SWEP:Initialize()
	self:SetHoldType( "duel" )
	self:SetDisabled( false )
end

function SWEP:SetDisabled( bool , seconds )
	seconds = seconds or 5
	self:SetDisabledTime( ( bool ) and CurTime() + seconds or -1 )
end

--we're considered disabled if the disabled time hasn't expired yet and it's different than -1

function SWEP:IsDisabled()
	return self:GetDisabledTime() >= CurTime() and self:GetDisabledTime() ~= -1
end

--we do this hacky stuff because we want to remain compatible with the normal hud stuff, plus it actually makes sense

function SWEP:Clip( i )
	return self["Clip"..i] and self["Clip"..i]( self ) or nil
end

function SWEP:SetClip( i , count )
	i = i + 1
	if self["SetClip"..i] then
		self["SetClip"..i]( self , count )
	end
end

function SWEP:GetMaxClip( i )
	i = i + 1
	return self["GetMaxClip"..i] and self["GetMaxClip"..i]( self ) or nil
end

function SWEP:SetMaxClip( i , count )
	i = i + 1
	if self["SetMaxClip"..i] then
		self["SetMaxClip"..i]( self , count )
	end
end

function SWEP:OnRemove()

end

function SWEP:GetActionEntity( slot )
	if not IsValid( self:GetOwner() ) then return end

	local controller = self:GetOwner():GetSpecialActionController()

	if not IsValid( controller ) then return end

	return controller:GetActionEntity( slot )
end

function SWEP:CanRunAction( actionentity , actionstring )
	--disable Attack if we've been attacked by an emp , let other actions pass through
	if self:IsDisabled() and actionstring == "Attack" then
		return false
	end
	
	return true
end

function SWEP:GetController()
	if not IsValid( self:GetOwner() ) then return end

	local controller = self:GetOwner():GetSpecialActionController()

	return controller
end

function SWEP:PrimaryAttack()
	local ent = self:GetActionEntity( SA.Slots.LEFT_WEAPON )
	if IsValid( ent ) then
		if ent:GetNextAction() < CurTime() then
			ent:DoSpecialAction( "Attack" , self:GetOwner():GetViewModel( 0 ) )
			
			--these are going to be moved to the action itself , so they can be prevented and shit
			
			self:SendVMAnim( self:GetOwner():GetViewModel( 0 ) , "fire" , 2 )
			self:GetOwner():DoCustomAnimEvent( PLAYERANIMEVENT_ATTACK_PRIMARY , 0 )
		end
	end
end

function SWEP:SecondaryAttack()
	local ent = self:GetActionEntity( SA.Slots.RIGHT_WEAPON )
	if IsValid( ent ) then
		if ent:GetNextAction() < CurTime() then
			ent:DoSpecialAction( "Attack" , self:GetOwner():GetViewModel( 1 ) )
			self:SendVMAnim( self:GetOwner():GetViewModel( 1 ) , "fire" , 0.1 )
			self:GetOwner():DoCustomAnimEvent( PLAYERANIMEVENT_ATTACK_SECONDARY , 0 )
		end
	end
end

function SWEP:Think()

	local controller = self:GetController()

	for i = SA.Slots.LEFT_WEAPON , SA.Slots.RIGHT_WEAPON do
		local ent = self:GetActionEntity( i )

		if IsValid( ent ) then
			ent:DoSpecialAction( "Think" , self:GetOwner():GetViewModel( i ) )
		end

	end

	--bring our think speed in line with the action controller
	if IsValid( controller ) then
		if SERVER then
			self:NextThink( CurTime() + controller:GetTickRate() )
		else
			self:SetNextClientThink( CurTime() + controller:GetTickRate() )
		end
		return true
	end
end

function SWEP:SendVMAnim( vm , seqstr , rate )
	if IsValid( vm ) then
		local seq=vm:LookupSequence( seqstr )
		vm:SendViewModelMatchingSequence( seq )
		vm:SetPlaybackRate( rate or 1 )
	end
end

--what could we allow the reload key to be used for? all the special actions only have an automatic reload animation ala quake
--so this could be used to toggle something else , in the old scrapmatch concept this would just switch the left and right keys
--but I think that doesn't make sense , this should probably be bound to the special action on the active slot instead of +use

function SWEP:Reload()

end

function SWEP:Deploy()
	if IsValid( self:GetOwner() ) then
		for i = 0 , 1 do
			local vm = self:GetOwner():GetViewModel( i )
			if IsValid( vm ) then
				--sets up the viewmodel to be used on this weapon, this is needed
				vm:SetNoDraw( false )
				vm:SetWeaponModel( self.ViewModel , self )
				self:SendVMAnim( vm , "draw" )
			end
		end

	end
	return true
end

function SWEP:Holster()
	if IsValid( self:GetOwner() ) then
		for i = 0 , 1 do
			local vm = self:GetOwner():GetViewModel( i )
			if IsValid( vm ) then
				self:SendVMAnim( vm , "holster" )
			end
		end
	end
	return true
end

if SERVER then


else

	function SWEP:CalcViewModelView( vm , oldpos , oldang , newpos , newang )
		--newpos and newang contain the viewbob shit
		local p = oldpos
		local a = oldang

		p , a = LocalToWorld( Vector( 0 , -2 , 3 ) , Angle( 0 , -5 , 0) , p , a )

		return p , a
	end

	function SWEP:FireAnimationEvent( pos, ang, event, name )
		return true
	end

	function SWEP:PreDrawViewModel( vm )
		if not IsValid( self:GetOwner() ) or not self:GetOwner():Alive() then
			return true
		end
	end

	function SWEP:ViewModelDrawn( vm )

	end

end