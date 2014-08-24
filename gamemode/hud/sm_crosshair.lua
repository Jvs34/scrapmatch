local PANEL = {}

AccessorFunc(	PANEL	, "_CrossHairR"	,	"CrossHairR"	,	FORCE_NUMBER	)
AccessorFunc(	PANEL	, "_CrossHairG"	,	"CrossHairG"	,	FORCE_NUMBER	)
AccessorFunc(	PANEL	, "_CrossHairB"	,	"CrossHairB"	,	FORCE_NUMBER	)
AccessorFunc(	PANEL	, "_CrossHairScale"	,	"CrossHairScale"	,	FORCE_NUMBER	)
AccessorFunc(	PANEL	, "_CrossHairShowAmmo"	,	"CrossHairShowAmmo"	,	FORCE_BOOL	)
AccessorFunc(	PANEL	, "_CrossHairHitSoundEnabled"	,	"CrossHairHitSoundEnabled"	,	FORCE_BOOL	)
AccessorFunc(	PANEL	, "_CrossHairHitSoundPath"	,	"CrossHairHitSoundPath"	,	FORCE_STRING	)
AccessorFunc(	PANEL	, "_CrossHairHitSoundDelay"	,	"CrossHairHitSoundDelay"	,	FORCE_NUMBER	)

function PANEL:Init()
	self.BaseClass.Init( self )
	self:AssociateHUDBits( GAMEMODE.HUDBits.HUD_CROSSHAIR )

	
	self:SetSuggestedX( 0.5 )
	self:SetSuggestedY( 0.5 )
	
	--we're going to override these and make it so it's based on the convar itself
	self:SetSuggestedW( 0.06 * self:GetCrossHairScale() )
	self:SetSuggestedH( 0.1 * self:GetCrossHairScale() )
	
	self.NextSound = CurTime()
end


function PANEL:Think()
	
	self.BaseClass.Think( self )
	
	self:SetSuggestedW( 0.06 * self:GetCrossHairScale() )
	self:SetSuggestedH( 0.1 * self:GetCrossHairScale() )
end

function PANEL:HitPlayer( victim , attacker , health )
	if not IsValid( self:GetMyPlayer() ) then return end
	
	--don't care about hits we didn't do, or self damage
	if not IsValid( attacker ) or not IsValid( victim ) then return end
	
	if attacker:UserID() ~=  self:GetMyPlayer():UserID() or victim:UserID() == LocalPlayer():UserID() then return end
	--play a ding a ling sound
	if self:GetCrossHairHitSoundEnabled() then
		
		if self:CrossHairHitSoundDelay() <= 0 or self.NextSound <= CurTime() then
			self:GetMyPlayer():EmitSound( self:GetCrossHairHitSoundPath() )
			self.NextSound = CurTime() + self:CrossHairHitSoundDelay()
		end
		
	end
end

function PANEL:Paint( w , h )
	
	surface.SetDrawColor( self:GetCrossHairR(), self:GetCrossHairG(), self:GetCrossHairB(), 255 )
	
	surface.DrawLine( w / 2 , 0 , w / 2 , h / 3 )
	surface.DrawLine( 0, h / 2 , w / 3, h / 2 )
	
	surface.DrawLine( w / 2 , h , w / 2 , h / 1.5 )
	surface.DrawLine( w , h / 2 , w / 1.5 , h / 2 )
	
end

derma.DefineControl( "SM_Crosshair", "The player's crosshair.", PANEL, "SM_BaseHUDPanel" )