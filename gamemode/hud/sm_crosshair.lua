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
	
	self._MainColor = Color( self:GetCrossHairR(), self:GetCrossHairG(), self:GetCrossHairB() , 255 )
	self._Color = self:GetMainColor()
end


function PANEL:Think()
	
	self.BaseClass.Think( self )
	
	self:SetSuggestedW( 0.06 * self:GetCrossHairScale() )
	self:SetSuggestedH( 0.1 * self:GetCrossHairScale() )
end

local function CrossHairHitThink( self , panel , fraction )
	if not self.CalculatedColor then
		self.StartH , self.StartS , self.StartV = ColorToHSV( self.StartColor )
		self.EndH , self.EndS , self.EndV = ColorToHSV( self.EndColor )
		self.CalculatedColor = true
	end
	
	self.CurH = Lerp( fraction , self.StartH , self.EndH )
	self.CurS = Lerp( fraction , self.StartS , self.EndS )
	self.CurV = Lerp( fraction , self.StartV , self.EndV )
	
	panel:SetColor( HSVToColor( self.CurH , self.CurS , self.CurV ) )
end

function PANEL:HitPlayer( victim , attacker , health )
	if not IsValid( self:GetMyPlayer() ) then return end
	
	--don't care about hits we didn't do, or self damage
	if not IsValid( attacker ) or not IsValid( victim ) then return end
	
	if attacker:UserID() ~=  self:GetMyPlayer():UserID() or victim:UserID() == LocalPlayer():UserID() then return end
	--play a ding a ling sound
	if self:GetCrossHairHitSoundEnabled() then
		
		if self:GetCrossHairHitSoundDelay() <= 0 or self.NextSound <= CurTime() then
			self:GetMyPlayer():EmitSound( self:GetCrossHairHitSoundPath() )
			self.NextSound = CurTime() + self:GetCrossHairHitSoundDelay()
		end
		
	end
	
	self:EndAnimation( "CrosshairHitMarker" )

	local anim = self:NewAnimation( 1 )

	anim.Name = "CrosshairHitMarker"
	anim.Think = CrossHairHitThink
	anim.StartColor = Color( 255 , 0 , 0 )
	anim.EndColor = self:GetMainColor()
end

function PANEL:GetMainColor()
	self._MainColor.r = self:GetCrossHairR()
	self._MainColor.g = self:GetCrossHairG()
	self._MainColor.b = self:GetCrossHairB()
	return self._MainColor
end

function PANEL:SetColor( col )
	self._Color.r = col.r
	self._Color.g = col.g
	self._Color.b = col.b
end

function PANEL:GetColor()
	return self._Color
end

function PANEL:Paint( w , h )
	
	surface.SetDrawColor( self:IsAnimationRunning( "CrosshairHitMarker" ) and self:GetColor() or self:GetMainColor() )
	
	surface.DrawLine( w / 2 , 0 , w / 2 , h / 3 )
	surface.DrawLine( 0, h / 2 , w / 3, h / 2 )
	
	surface.DrawLine( w / 2 , h , w / 2 , h / 1.5 )
	surface.DrawLine( w , h / 2 , w / 1.5 , h / 2 )
	
end

derma.DefineControl( "SM_Crosshair", "The player's crosshair.", PANEL, "SM_BaseHUDPanel" )