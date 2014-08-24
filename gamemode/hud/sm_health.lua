local PANEL = {}

PANEL.Font = "SM_Font_Health"..CurTime()


function PANEL:Init()
	self.BaseClass.Init( self )
	
	surface.CreateFont( self.Font ,
	{
		font		= "HalfLife2",
		size		= ScreenScale( 30 ),
		antialias	= true,
		weight		= 300
	})

	self:AssociateHUDBits( GAMEMODE.HUDBits.HUD_HEALTH )
	
	self:SetSuggestedX( 0.06 )
	self:SetSuggestedY( 0.93 )
	self:SetSuggestedW( 0.1 )
	self:SetSuggestedH( 0.1 )
	
	self.HealthLabel = self:Add( "DLabel" )
	self.HealthLabel:Dock( FILL )
	self.HealthLabel:SetFont( self.Font )
	self.HealthLabel:SetContentAlignment( 5 )	--this apparently means center
	self.HealthLabel:SetText( "" )
	self.HealthLabel:SetTextColor( Color( 255 , 255 , 0 ) )
	self.HealthLabel.OriginalColor = self.HealthLabel:GetTextColor()
	
	self.LastHealth =	0
end

local function HealthChangedAnimationThink( self , panel , fraction )
	if not self.CalculatedColor then
		self.StartH , self.StartS , self.StartV = ColorToHSV( self.StartColor )
		self.EndH , self.EndS , self.EndV = ColorToHSV( self.EndColor )
		self.CalculatedColor = true
	end
	
	self.CurH = Lerp( fraction , self.StartH , self.EndH )
	self.CurS = Lerp( fraction , self.StartS , self.EndS )
	self.CurV = Lerp( fraction , self.StartV , self.EndV )
	
	panel.HealthLabel:SetTextColor( HSVToColor( self.CurH , self.CurS , self.CurV ) )
end

function PANEL:Think()
	
	self.BaseClass.Think( self )
	
	if IsValid( self:GetMyPlayer() ) then
	
		if self:GetMyPlayer():Health() ~= self.LastHealth then
			self.HealthLabel:SetText( tostring( self:GetMyPlayer():Health() ) )
			
			local healthpercent = math.abs( self.LastHealth - self:GetMyPlayer():Health() ) / self:GetMyPlayer():GetMaxHealth()
			
			self:EndAnimation( "HealthChanged" )	--end the other healthchanged animation
			
			local anim = self:NewAnimation( 2 )	--the higher damage you take, the longer the animation is gonna run for
			
			anim.Name = "HealthChanged"
			anim.Think = HealthChangedAnimationThink
			anim.StartColor = Color( 255 , 0 , 0 )
			anim.EndColor = self.HealthLabel.OriginalColor
			
			self.LastHealth = self:GetMyPlayer():Health()
		end
	end
end

derma.DefineControl( "SM_Health", "An ammo display panel.", PANEL, "SM_BaseHUDPanel" )