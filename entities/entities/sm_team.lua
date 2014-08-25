AddCSLuaFile()

ENT.Type 			= "anim"
ENT.Base 			= "base_entity"
ENT.TeamColor = Color( 255 , 255 , 255 , 255 )

function ENT:Initialize()
	if SERVER then
		self:SetNoDraw( true )
	end
end

function ENT:SetupDataTables()

	self:NetworkVar( "Int"		, 0 , "TeamID" )					--the team id
	self:NetworkVar( "Int" 		, 1 , "TeamScore" )				--the team score
	self:NetworkVar( "Int"		, 2 , "TeamColorHEX" )			--the team color in hex , thanks vinh dick
	
	self:NetworkVar( "Bool"		, 0 , "TeamFriendlyFire" )		--whether this team allows friendly fire
	self:NetworkVar( "Bool"		, 1 , "TeamDisabled" )
	
	self:NetworkVar( "String" 	, 0 , "TeamName" )
	self:NetworkVar( "String"	, 1 , "TeamSpawnPoint" )
	self:NetworkVar( "String"	, 2 , "TeamLogo" )				--this is the workshop id for this team , which will be downloaded with steamworks.Download and applied with AddonMaterial
	
	self:NetworkVar( "Entity"	, 0 , "TeamMVP" )				--the player with the highest score
end

function ENT:Think()
	if self:GetTeamDisabled() then return end
	
	if SERVER then
		--calculate the MVP for this team
		
		local plys = team.GetPlayers( self:GetTeamID() )
		
		table.sort( plys , function( a , b )
			return b:Frags() > a:Frags()
		end)
		
		self:SetTeamMVP( plys[1] )
		
		self:NextThink( CurTime() + 1 )	--update the mvp every second
		return true
	end
	
end

if SERVER then
	
	--always network to everyone
	function ENT:UpdateTransmitState()
		return TRANSMIT_ALWAYS
	end

	function ENT:AddScore( score )
		self:SetTeamScore( self:GetTeamScore() + score )
	end
	
end

function ENT:GetTeamColor()
	self.TeamColor:FromHex( self:GetTeamColorHEX() )
	return self.TeamColor
end

function ENT:SetTeamColor( col )
	self.TeamColor.r = col.r
	self.TeamColor.g = col.g
	self.TeamColor.b = col.b
	
	self:SetTeamColorHEX( self.TeamColor:ToHex() )
end
