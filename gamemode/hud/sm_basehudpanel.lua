--this is the panel that all the components of SM_HUDPanel will derive from

local PANEL = {}

AccessorFunc(	PANEL	, "_HUDAnimations"	,	"HUDAnimations"	,	FORCE_BOOL	)
AccessorFunc(	PANEL	, "_HUDBits"	,	"HUDBits"	,	FORCE_NUMBER	)

--TODO: remove these accessors and just use the docking system

AccessorFunc(	PANEL	, "_SuggestedX"	,	"SuggestedX"	,	FORCE_NUMBER	)
AccessorFunc(	PANEL	, "_SuggestedY"	,	"SuggestedY"	,	FORCE_NUMBER	)
AccessorFunc(	PANEL	, "_SuggestedW"	,	"SuggestedW"	,	FORCE_NUMBER	)
AccessorFunc(	PANEL	, "_SuggestedH"	,	"SuggestedH"	,	FORCE_NUMBER	)

function PANEL:Init()
	self:SetHUDBits( 0 )
	self:LoadCvarSettings()
	
	self:SetSuggestedX( 0 )
	self:SetSuggestedY( 0 )
	self:SetSuggestedW( 0.3 )
	self:SetSuggestedH( 0.1 )
end

function PANEL:Spawn()
	self:PerformLayout()
end

function PANEL:SetHUDRenderInScreenshots( bool )
	self:SetRenderInScreenshots( bool )
end

function PANEL:LoadCvarSettings()
	
	for i , cvar_obj in pairs( GAMEMODE.ConVars ) do
	
		if self["Get"..i] and self["Set"..i] then
			
			self:LoadCvar( i , cvar_obj )
			
			cvars.AddChangeCallback( cvar_obj:GetName() , function( convar_name, value_old, value_new )
				if not IsValid( self ) then return end
				self:HandleCvarCallback( GetConVar( convar_name ), value_old , value_new )
			end, "CvarCallback:".. self:GetClassName() ..i )
			
		end
		
	end
	
end

function PANEL:GetCvarID( other_cvar_obj )
	for i , cvar_obj in pairs( GAMEMODE.ConVars ) do
		if other_cvar_obj:GetName() == cvar_obj:GetName() then return i end
	end
	
	return nil
end

function PANEL:HandleCvarCallback( cvar_obj , oldval , newval )
	local identifier = self:GetCvarID( cvar_obj )
	
	if not identifier then return end
	
	self:LoadCvar( identifier , cvar_obj , newval )
	
end

function PANEL:LoadCvar( i , cvar_obj , newval )
	--separate the type check from the actual help text
	local cvar_type = cvar_obj:GetHelpText():match("([^%;]+)")
	
	if cvar_type == "Int" then
		self["Set"..i](self , newval and tonumber( newval ) or cvar_obj:GetInt() )
	elseif cvar_type == "Float" then
		self["Set"..i](self , newval and tonumber( newval ) or cvar_obj:GetFloat() )
	elseif cvar_type == "String" then
		self["Set"..i](self , newval or cvar_obj:GetString() )
	elseif cvar_type == "Bool" then
		self["Set"..i](self , newval ~= nil and tobool( newval ) or cvar_obj:GetBool() )
	else
		ErrorNoHalt( "Could not set " .. i .. " as it did not have a type set in the help text!" )
		return
	end
	
	local message = "Client cvar \'"..cvar_obj:GetName() .."\' changed to " .. cvar_obj:GetString()
	
	MsgN( message )
end

function PANEL:PerformLayout( w , h )
end

function PANEL:SetMyPlayer( ply )
	self.Player = ply
	self.CustomPlayer = true
end

--return our custom player if it's been set once , otherwise keep the default behaviour of returning the main hud panel's player

function PANEL:GetMyPlayer()
	return ( self.CustomPlayer ) and self.Player or self:GetParent():GetMainPlayer()
end

--return to the default behaviour of returning our parent's player entity

function PANEL:RestorePlayer()
	self.CustomPlayer = false
end

--can be overridden
function PANEL:ShouldBeVisible()
	if not IsValid( self:GetMyPlayer() ) then return false end
	return bit.band( self:GetMyPlayer():GetHUDBits() , self:GetHUDBits() ) ~= 0
end

--associate this panel with specific GAMEMODE.HUDBits.* , this way we won't be shown if my self:GetMyPlayer():GetHUDBits() doesn't return that bits
function PANEL:AssociateHUDBits( bits )
	self:SetHUDBits( bits )
end


--override garry's setter for animation  , we're going to enable animations when we say so
function PANEL:SetAnimationEnabled( b )	
end

--nothing for now, there might be other stuff I want to call from this though
function PANEL:Think() 
end

--override garry's AnimationThink , we're only going to run animations when the player has the convar enabled

function PANEL:AnimationThink()
	if self:GetHUDAnimations() then
		self:AnimationThinkInternal()
	else	--end pending animations that were started when the user had the cvar enabled
		self:EndAnimations()
	end
end

function PANEL:EndAnimations()
	if not self.m_AnimList then return end

	for k, anim in pairs( self.m_AnimList ) do
		if anim.Think then
			anim:Think( self, 1 )
		end

		if anim.OnEnd then anim:OnEnd( self ) end
	
		self.m_AnimList[k] = nil				
	end
	
end

function PANEL:EndAnimation( name )
	if not self.m_AnimList then return end
	
	local foundanim = nil
	
	for k, anim in pairs( self.m_AnimList ) do
		if anim and anim.Name == name then
			foundanim = self.m_AnimList[k]
			self.m_AnimList[k] = nil
			break
		end
	end
	
	if not foundanim then return end
	
	if foundanim.Think then
		foundanim:Think( self, 1 )
	end

	if foundanim.OnEnd then foundanim:OnEnd( self ) end
	
end

function PANEL:IsAnimationRunning( name )
	if not self.m_AnimList then return false end
	
	for k, anim in pairs( self.m_AnimList ) do
		if anim and anim.Name == name then
			return true
		end
	end
	
	return false
end

--this used to be done in panel think, and it was a really dumb idea since the panel doesn't think if it's not visible
function PANEL:CheckVisibility()
	local visibility = self:ShouldBeVisible()
	if visibility ~= self:IsVisible() then
		self:SetVisible( visibility )
	end
end

--TODO: actually skin this
function PANEL:Paint( w , h )
	draw.RoundedBox( 8, 0, 0, w, h, Color( 0, 0, 0, 120 ) )
end

derma.DefineControl( "SM_BaseHUDPanel", "The base hud panel for all the components of SM_MainHUDPanel.", PANEL, "DPanel" )