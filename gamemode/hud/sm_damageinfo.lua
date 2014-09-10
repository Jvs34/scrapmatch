local PANEL = {}

PANEL.DamageList = {}

AccessorFunc(	PANEL	, "_DamageTimeOnScreen"	,	"DamageTimeOnScreen"	,	FORCE_NUMBER	)
AccessorFunc(	PANEL	, "_DamageStartRadius"	,	"DamageStartRadius"	,	FORCE_NUMBER	)
AccessorFunc(	PANEL	, "_DamageEndRadius"	,	"DamageEndRadius"	,	FORCE_NUMBER	)


function PANEL:Init()
	self.BaseClass.Init( self )
	self:AssociateHUDBits( GAMEMODE.HUDBits.HUD_HEALTH )
end

function PANEL:ShouldBeVisible()
	
	if #self.DamageList <= 0 then
		return false
	end
	
	return self.BaseClass.ShouldBeVisible( self )
end

function PANEL:ReceiveDamage( wasselfdamage , dmg , dmgtype , damagepos )
	--ignore self damage to avoid noise
	if wasselfdamage then return end
	
	local dmginfo = {
		Damage = dmg,
		DamageType = dmgtype,
		Position = damagepos,
		StartTime = CurTime(),
		EndTime = CurTime() + self:GetDamageTimeOnScreen(),
	}
	table.insert( self.DamageList , dmginfo )
	
end

function PANEL:Paint( w , h )

end


derma.DefineControl( "SM_DamageInfo", "Show the direction the player was hit from.", PANEL, "SM_BaseHUDPanel" )