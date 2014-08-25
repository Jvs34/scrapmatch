local PANEL = {}

PANEL.Font = "SM_Font_ScoreBoard"..CurTime()

PANEL.TeamColumns = {}

function PANEL:Init()
	self.BaseClass.Init( self )
	self:AssociateHUDBits( GAMEMODE.HUDBits.HUD_SCOREBOARD )
	
	surface.CreateFont( self.Font ,
	{
		font		= "Roboto",
		size		= ScreenScale( 10 ),
		antialias	= true,
		weight		= 300
	})
	
	self:SetSuggestedX( 0.5 )
	self:SetSuggestedY( 0.5 )
	
	self:SetSuggestedW( 0.6 )
	self:SetSuggestedH( 0.7 )
	
	self.TeamsLayout = self:Add( "SM_ScoreBoard_TeamLayout" )
	self.TeamsLayout:Dock( FILL )
	
	
end


function PANEL:Think()
	
	self.BaseClass.Think( self )
	
	for i = 1 , GAMEMODE.MAX_TEAMS do
		local teament = GAMEMODE:GetTeamEnt( i )
		
		if IsValid( teament ) and not teament:GetTeamDisabled() then
			if not IsValid( self.TeamColumns[i] ) then
				--create the team column here
				self.TeamColumns[i] = self.TeamsLayout:Add( "SM_ScoreBoard_TeamColumn" )
				self.TeamColumns[i]:SetTeam( teament )
			end
		else
			if IsValid( self.TeamColumns[i] ) then
				self.TeamColumns[i]:Remove()
				self.TeamColumns[i] = nil
			end
		end
	end
	
	for i , v in pairs( player.GetAll() ) do
		local plyteamid = v:Team()
		if self.TeamColumns[plyteamid] then
			self.TeamColumns[plyteamid]:HandlePlayer( v )
		end
	end
	self.TeamsLayout:InvalidateLayout()
end

derma.DefineControl( "SM_ScoreBoard", "Scoreboard containing all teams.", PANEL, "SM_BaseHUDPanel" )

local PANEL = {}
AccessorFunc(	PANEL	, "_Team"	,	"Team"	)
PANEL.PlayerRows = {}
function PANEL:Init()
	self.TeamName = self:Add( "DLabel" )
	self.TeamName:Dock( TOP )
	self.TeamName:DockMargin( 10 , 10 , 0 , 10 )
	self.TeamName:SetFont( self:GetParent():GetParent().Font )
	self.TeamName:SetText( "Team" )
	self.TeamName:SetContentAlignment( 5 )
end

function PANEL:Think()
	if IsValid( self:GetTeam() ) then
		self.TeamName:SetText( self:GetTeam():GetTeamName() )
	end
end

function PANEL:HandlePlayer( ply )
	if not self.PlayerRows[ply:UserID()] then
		self.PlayerRows[ply:UserID()] = self:Add( "SM_ScoreBoard_PlayerRow" )
		self.PlayerRows[ply:UserID()]:Dock( TOP )
		self.PlayerRows[ply:UserID()]:SetPlayer( ply )
	end
end

function PANEL:Paint()

end

derma.DefineControl( "SM_ScoreBoard_TeamColumn", "Scoreboard containing all teams.", PANEL, "DPanel" )




local PANEL = {}

function PANEL:Init()
	
end

function PANEL:PerformLayout( w , h )
	
	local children = self:GetChildren()
	local nchildren = #children
	
	for i , v in pairs( children ) do
		v:SetTall( h )
		v:SetWide( w / nchildren )
		v:SetPos( (w / nchildren ) * ( i - 1 ), 0 )
	end
	
end

function PANEL:Paint()

end

derma.DefineControl( "SM_ScoreBoard_TeamLayout", "A scoreboard layout.", PANEL, "DPanel" )

local PANEL = {}
AccessorFunc(	PANEL	, "_Player"	,	"Player"	)
function PANEL:Init()
	
end

function PANEL:Think()
	if self:IsMarkedForDeletion() then return end
	if not IsValid( self:GetPlayer() ) then 
		self:Remove()
		return
	end
	
	if IsValid( self:GetParent():GetTeam() ) then
		if self:GetPlayer():Team() ~= self:GetParent():GetTeam():GetTeamID() then
			self:Remove()
			return
		end
	end
end

derma.DefineControl( "SM_ScoreBoard_PlayerRow", "A player row", PANEL, "DPanel" )


