--the main HUD panel , will automatically handle the positioning of the children , which can also be influenced by convars
local PANEL = {}

PANEL.HUDPanels = {}

function PANEL:Init()
	
	--[[
	self.TileLayout = self:Add( "DTileLayout" )
	self.TileLayout:Dock( FILL )
	self.TileLayout:SetSpaceX( 16 )
	self.TileLayout:SetSpaceY( 16 )
	
	for i = 0 , 10 do
		local dpanel = self.TileLayout:Add( "DPanel" )
		dpanel:SetSize( 128 , 64 )
	end
	]]
	
	--create all the other HUD panels
	self:CreateElements()
end

function PANEL:CreateElements()
	self:AddHudPanel( "SM_Health" )
	self:AddHudPanel( "SM_Armor" )
	self:AddHudPanel( "SM_DamageInfo" )
	self:AddHudPanel( "SM_Ammo" )
	self:AddHudPanel( "SM_RoundInfo" )
	self:AddHudPanel( "SM_ScoreBoard" )
	self:AddHudPanel( "SM_Crosshair" )
	self:AddHudPanel( "SM_RoundLog" )
	self:AddHudPanel( "SM_PlayerInfo" )
	self:AddHudPanel( "SM_VoteMenu" )
end

--TODO, add them to a custom layout instead of directly onto the panel

function PANEL:AddHudPanel( name )
	local panel = self:Add( name )
	if not IsValid( panel ) then return end
	self.HUDPanels[name] = panel
	return panel
end

function PANEL:Spawn()
	self:PerformLayout( ScrW() , ScrH() )
end

function PANEL:SetMainPlayer( ply )
	self.Player = ply
end

function PANEL:GetMainPlayer()
	return self.Player
end


function PANEL:PerformLayout( w , h )
	
	--perform our custom layout here based on the suggested positions of our hud elements
	--remember that they have to be dynamically scaled , so scale them on our size ( since it should be the same as the whole screen )
	
	--TODO: should this even use the docking system? goddamnit
	--		also this shouldn't be called every frame like it currently is, otherwise animations involving movement are gonna fuck up
	
	for i , v in pairs( self.HUDPanels ) do
		if IsValid( v ) then
			local w = self:GetWide() * v:GetSuggestedW()
			local h = self:GetTall() * v:GetSuggestedH()
			
			--TODO: use the actual dock margin and padding functions instead of this hacky mess!
			--at least it's going to be hacky on the engine side that way
			
			v:SetWide( w )
			v:SetTall( h )
			v:SetPos( self:GetWide() * v:GetSuggestedX(), self:GetTall() * v:GetSuggestedY())
			local x , y = v:GetPos()
			x = x - v:GetWide() / 2
			y = y - v:GetTall() / 2
			
			v:SetPos( x , y )
		end
	end
end

function PANEL:GetHUDPanel( name )
	return self.HUDPanels[name]
end

function PANEL:Think()

	if IsValid( LocalPlayer() ) and LocalPlayer().dt then
		local spent = LocalPlayer():GetObserverTarget()
		--the local player is spectating someone , tell the hud elements to track that player instead
		if IsValid( spent ) and spent:IsPlayer() and spent.dt then
			self:SetMainPlayer( spent )
		else
			self:SetMainPlayer( LocalPlayer() )
		end
		
	end
	
	for i , v in pairs( self.HUDPanels ) do	--self:GetChildren()	--can't use this function since we might have other elements in the panel we don't want to index
		if not IsValid( v ) then continue end
		--calls the visibility check , this automatically sets v:SetVisible in it, checking if the current player can see that actual panel
		v:CheckVisibility()
	end
	
end

function PANEL:Paint( w , h ) 
	surface.SetDrawColor( color_black )
	surface.DrawOutlinedRect( 0,0, w , h )
end

derma.DefineControl( "SM_MainHUDPanel", "The main HUD panel of scrapmatch , handles all the components such as health, armor and etc.", PANEL, "DPanel" )