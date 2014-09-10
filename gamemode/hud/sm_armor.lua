
local PANEL = {}

PANEL.Font = "SM_Font_Armor"..CurTime()

function PANEL:Init()
	self.BaseClass.Init( self )
	self:AssociateHUDBits( GAMEMODE.HUDBits.HUD_ARMOR )
	
	surface.CreateFont( self.Font ,
	{
		font		= "HalfLife2",
		size		= ScreenScale( 30 ),
		antialias	= true,
		weight		= 300
	})
	
	self:SetSuggestedX( 0.17 )
	self:SetSuggestedY( 0.93 )
	self:SetSuggestedW( 0.1 )
	self:SetSuggestedH( 0.1 )
	
	self.ArmorLabel = self:Add( "DLabel" )
	self.ArmorLabel:Dock( FILL )
	self.ArmorLabel:SetText( "100" )
	self.ArmorLabel:SetFont( self.Font )
	self.ArmorLabel:SetContentAlignment( 5 )
	self.ArmorLabel:SetTextColor( Color( 70 , 70 , 220 ) )
	self.ArmorLabel.OriginalColor = self.ArmorLabel:GetTextColor()
	self.LastArmor =	0
end

--DISABLED FOR NOW , this will be the default behaviour later on, but now we just need to see all the HUD elements for debugging

--
--[[
function PANEL:ShouldBeVisible()
	if IsValid( self:GetMyPlayer() ) and self:GetMyPlayer():GetArmorBattery() <= 1 then
		return false
	end
	return self.BaseClass.ShouldBeVisible( self )
end
]]

local function ArmorChangedAnimationThink( self , panel , fraction )
	if not self.CalculatedColor then
		self.StartH , self.StartS , self.StartV = ColorToHSV( self.StartColor )
		self.EndH , self.EndS , self.EndV = ColorToHSV( self.EndColor )
		self.CalculatedColor = true
	end
	
	self.CurH = Lerp( fraction , self.StartH , self.EndH )
	self.CurS = Lerp( fraction , self.StartS , self.EndS )
	self.CurV = Lerp( fraction , self.StartV , self.EndV )
	
	panel.ArmorLabel:SetTextColor( HSVToColor( self.CurH , self.CurS , self.CurV ) )
end

function PANEL:Think()
	self.BaseClass.Think( self )
	if IsValid( self:GetMyPlayer() ) then
		
		if not self:GetMyPlayer():Alive() then
			self.LastArmor = -1
		end
		
		if self:GetMyPlayer():GetArmorBattery() ~= self.LastArmor then
			
			local val = math.Round( self:GetMyPlayer():GetArmorBattery() )
			
			self.ArmorLabel:SetText( tostring( val ) )
			
			self:EndAnimation( "ArmorChanged" )	--end the other healthchanged animation
			
			local anim = self:NewAnimation( 0.25 )	--the higher damage you take, the longer the animation is gonna run for
			
			anim.Name = "ArmorChanged"
			anim.Think = ArmorChangedAnimationThink
			anim.StartColor = Color( 120 , 255 , 0 )
			anim.EndColor = self.ArmorLabel.OriginalColor
			
			self.LastArmor = self:GetMyPlayer():GetArmorBattery()
		end
	end
end

derma.DefineControl( "SM_Armor", "An armor display panel", PANEL, "SM_BaseHUDPanel" )