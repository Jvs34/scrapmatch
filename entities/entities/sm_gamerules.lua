AddCSLuaFile()

ENT.Type 			= "anim"
ENT.Base 			= "base_entity"

if SERVER then
	util.AddNetworkString("sm_gamerules_roundupdate")
end

function ENT:Initialize()
	if SERVER then
		self:SetNoDraw( true )
		self:SetName( self:GetClass() )
	end
end

function ENT:SetupDataTables()
	self:NetworkVar( "Bool"	, 0 , "DebugMode" )
	self:NetworkVar( "Int" , 0 , "MaxRounds" )			--maximum number of rounds after which map will change
	self:NetworkVar( "Int" , 1 , "CurrentRound" )		--the current round
	self:NetworkVar( "Int" , 2 , "RoundFlags" )		--the round flags, overtime, last man standing, shit like that
	self:NetworkVar( "Int" , 3 , "MaxScore" )			--the maximum score after which a round will be restarted
																	--if teambased it'll count the overall team score, otherwise the player's , -1 for no limit
	self:NetworkVar( "Int" , 4 , "RoundDuration" )	--the maximum duration of the round, RoundTime will be set to this when a round restarts
																	--set to -1 for no limit
	self:NetworkVar( "Int" , 5 , "GameType" )
	
	self:NetworkVar( "Int" , 6 , "MovementSpeed" )
	self:NetworkVar( "Int" , 7 , "CameraCount" )
	
	self:NetworkVar( "Float" , 0 , "RoundTime" )		--set at the start of the round, CurTime() + self:GetRoundDuration(), 
	self:NetworkVar( "Float" , 1 , "RespawnTime" )	--respawn time in seconds ( eg 2 ) for the player to respawn after dying
	
	self:NetworkVar( "String" , 0 , "NextMap" )			--the next map to switch when the game is over
	
	self:NetworkVar( "Entity" , 0 , "RoundWinner" )	--always a team entity, set when the round has ended and then set back to nil when the round starts
	
	for i = 1 , GAMEMODE.MAX_TEAMS do
		self:NetworkVar( "Entity" , i , "Team" .. i )	--the team entity for that team
	end
	
end

function ENT:GetTeamEntity( id )
	return self["GetTeam"..id] and self["GetTeam"..id](self)
end

function ENT:SetTeamEntity( id , ent )
	return self["SetTeam"..id] and self["SetTeam"..id](self , ent)
end

function ENT:IsRoundFlagOn( flag )
	return bit.band( self:GetRoundFlags() , flag ) ~= 0
end

function ENT:GetHighestScore()
	local score = -1
	local winnerteam = nil
		for i = 1 , GAMEMODE.MAX_TEAMS do
			local teament = self:GetTeamEntity( i )
			if not IsValid(teament) or teament:GetTeamDisabled() or teament:GetTeamID() == GAMEMODE.TEAM_SPECTATORS then continue end
			if teament:GetTeamScore() > score then
				score = teament:GetTeamScore()
				teamwinner = teament
			end
		end
	return score , teamwinner
end

function ENT:GetHighestScorerOnTeam( i )

	local teament = self:GetTeamEntity( i )
	
	if not IsValid(teament) or teament:GetTeamDisabled() or teament:GetTeamID() == GAMEMODE.TEAM_SPECTATORS then return end
	
	return teament:GetTeamMVP()
end

if SERVER then

	function ENT:CreateTeamEntity( i , name , disabled , spawnpoint , color )
		local teament = ents.Create( "sm_team" )
		if not IsValid( teament ) then return end
		teament:SetTeamID( i )
		teament:SetTeamName( name or "Team "..i )
		teament:SetTeamDisabled( false )
		teament:SetTeamSpawnPoint( spawnpoint or "info_player_start" )
		teament:SetTeamColor( color or Color( 255 , 255 , 255 ) )
		teament:Spawn()
		self:SetTeamEntity( i , teament )
		return teament
	end

	function ENT:ToggleRoundFlag( flag )
		if bit.band( self:GetRoundFlags() , flag ) ~= 0 then
			self:SetRoundFlags( bit.bxor( self:GetRoundFlags() , flag ) )
		else
			self:SetRoundFlags( bit.bor( self:GetRoundFlags() , flag ) )
		end
	end
	
	--always transmit, make sure that the client knows about us!
	function ENT:UpdateTransmitState()
		return TRANSMIT_ALWAYS
	end

	function ENT:LoadCvarSettings()
		
		for i , cvar_obj in pairs( GAMEMODE.ConVars ) do
		
			if self["Get"..i] and self["Set"..i] then
				
				self:LoadCvar( i , cvar_obj )
				
				cvars.AddChangeCallback( cvar_obj:GetName() , function( convar_name, value_old, value_new )
					self:HandleCvarCallback( GetConVar( convar_name ), value_old , value_new )
				end, "Callback:"..i )
				
			end
			
		end
		
	end
	
	function ENT:RemoveCvarCallbacks()
		for i , cvar_obj in pairs( GAMEMODE.ConVars ) do
		
			if self["Get"..i] and self["Set"..i] then
				
				cvars.RemoveChangeCallback( cvar_obj:GetName() , "Callback:"..i )
				
			end
			
		end
	
	end
	
	function ENT:GetCvarID( other_cvar_obj )
		for i , cvar_obj in pairs( GAMEMODE.ConVars ) do
			if other_cvar_obj:GetName() == cvar_obj:GetName() then return i end
		end
		
		return nil
	end
	
	function ENT:HandleCvarCallback( cvar_obj , oldval , newval )
		local identifier = self:GetCvarID( cvar_obj )
		
		if not identifier then return end
		
		self:LoadCvar( identifier , cvar_obj , newval )
		
	end
	
	function ENT:LoadCvar( i , cvar_obj , newval )
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
		
		local message = "Server cvar \'"..cvar_obj:GetName() .."\' changed to " .. cvar_obj:GetString()
		
		MsgN( message )
		PrintMessage( HUD_PRINTTALK , message )
	end
	
	-- we'll just send net messages to the client to notify 
	function ENT:RoundThink()
		
		--we don't check if roundduration is -1 here because intermissions always have a round duration
		if self:IsRoundFlagOn( GAMEMODE.RoundFlags.INTERMISSION ) and self:GetRoundTime() <= CurTime() then
			
			if self:IsRoundFlagOn( GAMEMODE.RoundFlags.GAMEOVER ) then
				self:GameOver()
			else
				self:StartRound()
			end
			
			return
		end
		
		if not self:IsRoundFlagOn( GAMEMODE.RoundFlags.GAMEOVER ) and self:GetMaxRounds() ~= - 1 and self:GetCurrentRound() > self:GetMaxRounds() then
			self:ToggleRoundFlag( GAMEMODE.RoundFlags.GAMEOVER )
			self:GoToIntermission( GAMEMODE:GetVoteController():GetVoteDuration() * 1.5 )
			return
		end
		
		if not self:IsRoundFlagOn( GAMEMODE.RoundFlags.INTERMISSION ) and self:GetRoundDuration() ~= -1 and self:GetRoundTime() <= CurTime() then
			self:GoToIntermission()
			return
		end
		
		if self:GetMaxScore() ~= -1 and self:GetHighestScore() >= self:GetMaxScore() then
			self:GoToIntermission()
			return
		end
		
	end
	
	function ENT:GameOver()
		--prompt for changelevel
		self:SetCurrentRound( 0 )
		gamemode.Call( "GameOver" )
		--don't even bother sending a net message to the clients, GAMEMODE:GameOver changes the map straight away
	end
	
	function ENT:StartRound()
		--remove the intermission flag, call RoundStart
		self:ToggleRoundFlag( GAMEMODE.RoundFlags.INTERMISSION )
		self:SetCurrentRound( self:GetCurrentRound() + 1 )
		
		if self:GetRoundDuration() == -1 then
			self:SetRoundTime( 0 )
		else
			self:SetRoundTime( CurTime() + self:GetRoundDuration() )
		end
		
		gamemode.Call( "RoundStart" )
		
		net.Start("sm_gamerules_roundupdate")
			net.WriteUInt( self:GetRoundFlags() , 32 )
		net.Broadcast()
	end
	
	function ENT:GoToIntermission( intermissiontime , silent )
		if self:IsRoundFlagOn( GAMEMODE.RoundFlags.INTERMISSION ) then return end
		
		self:SetRoundTime( CurTime() + ( intermissiontime or 5 ) )
		self:ToggleRoundFlag( GAMEMODE.RoundFlags.INTERMISSION )
		if not silent then
			gamemode.Call( "RoundEnd" )
			
			net.Start("sm_gamerules_roundupdate")
				net.WriteUInt( self:GetRoundFlags() , 32 )
			net.Broadcast()
		end
	end
	
	function ENT:OnRemove()
		self:RemoveCvarCallbacks()
	end
	
else

	net.Receive( "sm_gamerules_roundupdate" , function( len )
		
		local roundflags = net.ReadUInt( 32 )
		
		if bit.band( roundflags , GAMEMODE.RoundFlags.INTERMISSION ) ~= 0 then
			gamemode.Call( "RoundEnd" )
		else	
			gamemode.Call( "RoundStart" )
		end
		
	end)
	
end


