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
				if teament:GetTeamID() ~= GAMEMODE.TEAM_SPECTATORS then
					self.TeamColumns[i] = self.TeamsLayout:Add( "SM_ScoreBoard_TeamColumn" )
				else	--TODO: set the spectator panel to be small and attach it to the bottom
					self.TeamColumns[i] = self.TeamsLayout:Add( "SM_ScoreBoard_TeamColumn" )
				end
				
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
		if self:GetTeam():GetTeamRoundsWon() ~= -1 then
			self.TeamName:SetText( self.TeamName:GetText() .. " " ..self:GetTeam():GetTeamRoundsWon()  )
		end
	end
	
	for i , v in ipairs( self.PlayerRows ) do
		local ply = v:GetPlayer()
		
		--TODO: set the Z value like garry does on his scoreboard so we can order by score
		if not IsValid( ply ) then
			self.PlayerRows[i]:Remove()
			self.PlayerRows[i] = nil
		end
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

derma.DefineControl( "SM_ScoreBoard_TeamColumn", "Shows a specific team in this column", PANEL, "DPanel" )




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

derma.DefineControl( "SM_ScoreBoard_TeamLayout", "Sizes all the children to fit vertically in the scoreboard.", PANEL , "DPanel" )

local PANEL = {}
AccessorFunc(	PANEL	, "_Player"	,	"Player"	)

function PANEL:Init()
	--create avatar , dock to the left , increase the left margin
	--create name, dock to fill
	--create score label , dock to the right
	--create deaths label, dock to the right
	--create ping label, dock to the right
end

function PANEL:Think()
end

derma.DefineControl( "SM_ScoreBoard_PlayerRow", "A player row, shows name , avatar , score , deaths and ping", PANEL, "DPanel" )
