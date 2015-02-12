AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "cl_hud.lua" )
AddCSLuaFile( "sh_recipientfilter.lua" )
AddCSLuaFile( "sh_player_meta.lua" )
AddCSLuaFile( "sh_entity_meta.lua" )
AddCSLuaFile( "sh_player.lua" )
AddCSLuaFile( "shd_module_multimodel.lua" )
AddCSLuaFile( "sh_teamoverride.lua" )
AddCSLuaFile( "sh_specialaction.lua" )

AddCSLuaFile( "special_actions/sa_chaingun.lua" )
AddCSLuaFile( "special_actions/sa_circularsaw.lua" )

AddCSLuaFile( "hud/sm_mainhudpanel.lua" )
AddCSLuaFile( "hud/sm_basehudpanel.lua" )
AddCSLuaFile( "hud/sm_health.lua" )
AddCSLuaFile( "hud/sm_armor.lua" )
AddCSLuaFile( "hud/sm_damageinfo.lua" )
AddCSLuaFile( "hud/sm_ammo.lua" )
AddCSLuaFile( "hud/sm_roundinfo.lua" )
AddCSLuaFile( "hud/sm_scoreboard.lua" )
AddCSLuaFile( "hud/sm_crosshair.lua" )
AddCSLuaFile( "hud/sm_roundlog.lua" )
AddCSLuaFile( "hud/sm_playerinfo.lua" )
AddCSLuaFile( "hud/sm_votemenu.lua" )


include("shared.lua")

GM.CleanupFilter = {
	"sent_specialaction",					--these two will be removed when the player respawns anyway
	"sent_specialaction_controller",
--	"sm_weapon",								--removed when the player spawns anyway
	"sm_gamerules",							--never should be deleted
	"sm_votecontroller",					--could be deleted in theory
	"sm_announcer",							--theorically it'd be good to have this be reset on a map cleanup
	"sm_team",
	"sm_camera",								--we don't want cameras to be cleaned up, as players need to always be able to interact with them
--	"sm_pickup",		--actually we do want this to be clean up
}

function GM:Initialize()
	--create a scrapmatch folder on the server's data folder
end

function GM:InitPostEntity()

	--these entities are never going to be deleted, so it's safe to create them in InitPostEntity
	local camera = ents.Create( "sm_camera" )
	camera:SetPos( vector_origin )
	camera:SetActive( true )
	camera:Spawn()
	
	--create the game rules entity
	local rules = ents.Create( "sm_gamerules" )
	rules:LoadCvarSettings()
	rules:SetCameraCount( #ents.FindByClass( "sm_camera" ) )
	rules:Spawn()

	--create the announcer entity
	local announcer = ents.Create( "sm_announcer" )
	announcer:Spawn()

	--create the votecontroller
	local votecontroller = ents.Create( "sm_votecontroller" )
	votecontroller:SetVoteDuration( 15 )
	votecontroller:Spawn()

	--setup the team entities
	local spectators = rules:CreateTeamEntity( "Spectators" , false , "worldspawn" , Color( 80 , 80 , 80 ) )
	spectators:SetTeamSpectators( true )
	spectators:SetTeamRoundsWon( -1 )
	
	local deathmatch = rules:CreateTeamEntity( "Deathmatch" , false , nil , Color( 120 , 255 , 120 ) )
	deathmatch:SetTeamDeathmatch( true )
	deathmatch:SetTeamFriendlyFire( true )
	
	local red = rules:CreateTeamEntity( "Red" , false , nil , Color( 255 , 120 , 120 ) )
	red:SetTeamFriendlyFire( false )
	
	local blu = rules:CreateTeamEntity( "Blu" , false , nil , Color( 120 , 120 , 255 ) )
	blu:SetTeamFriendlyFire( false )
	--configure your custom teams here
	
	--debugging shit
	if self.ConVars["DebugMode"]:GetBool() then
		for i = 1 , self.MAX_TEAMS do
			local teament = self:GetTeamEnt( i )
			if IsValid( teament ) then
				local col = teament:GetTeamColor()
				MsgC( col, "[" .. teament:EntIndex() .. "]" .. teament:GetTeamID() .. ": " , col , teament:GetTeamName() , col , "\n" )
			end
		end
	end

	--this forces an intermission check and starts the round right away
	rules:GoToIntermission( 1 , true )


end


function GM:VoteConcluded( voteentity , votetype , votedata )
	
	if voteentity:GetAgreeCount() > voteentity:GetDisagreeCount() then
		ErrorNoHalt( "Vote succeeded" )
		--TODO: apply the vote, change whatever flags it needed to
	else
		ErrorNoHalt( "Vote failed, either the vote tied or not enough agrees" )
	end

	for i , v in pairs( player.GetAll() ) do
		if IsValid( v ) then
			v:SetHasVoted( false )
		end
	end

end

function GM:Think()

	if IsValid( self:GetGameRules() ) then

		self:GetGameRules():RoundThink()

	end

end

function GM:RoundStart()

	local announcer = self:GetAnnouncer()
	if IsValid( announcer ) then
		announcer:RoundReset()
	end
	
	--cleanup the whole map, ignore the entities in the cleanupfilter
	if self.ConVars["DebugMode"]:GetBool() then
		MsgN( "Round started" )
	end
	
	self:GetGameRules():SetRoundWinner( nil )
	game.CleanUpMap( true , self.CleanupFilter )

	--enable or disable the teams depending on the game type, also reset their score

	for i = 1 , self.MAX_TEAMS do

		local teament = self:GetTeamEnt( i )

		if not IsValid( teament ) then continue end

		if teament:GetTeamSpectators() then 
			continue 
		end

		teament:SetTeamScore( 0 )

		if teament:GetTeamDeathmatch() then
			teament:SetTeamDisabled( self:GetGameRules():GetGameType() ~= self.GameTypes.DEATHMATCH )
		else
			teament:SetTeamDisabled( self:GetGameRules():GetGameType() == self.GameTypes.DEATHMATCH )
		end

	end

	--force all the players to respawn , even spectators just in case , put players on the correct team if the mode changed or the team got removed

	for i , v in pairs( player.GetAll() ) do
		local teament = self:GetTeamEnt( v:Team() )
		if not IsValid( teament ) or teament:GetTeamDisabled() then
			self:JoinTeam( v , team.BestAutoJoinTeam( true ) , false )
		else
			v:Spawn()
		end
		
		v:SetFrags( 0 )
		v:SetDeaths( 0 )
	end
	
	--scramble the teams if we had the flag previously set

	if self:GetGameRules():IsRoundFlagOn( self.RoundFlags.TEAM_SCRAMBLE ) then
		self:ScrambleTeams()
		self:GetGameRules():ToggleRoundFlag( self.RoundFlags.TEAM_SCRAMBLE )
	end

end

function GM:RoundEnd()
	--get the team with the highest score, increase their round wins, and set their team entity on the game rules' roundwinner
	local score , winnerteam = self:GetGameRules():GetHighestScore()
	
	--NOTE: during deathmatch this is always going to be the deathmatch team, the client will get the MVP's name instead of the team name for the round info winner
	if IsValid( winnerteam ) then
		self:GetGameRules():SetRoundWinner( winnerteam )
		winnerteam:AddScore( 1 )
	end
	
	if self:GetGameRules():IsRoundFlagOn( self.RoundFlags.GAMEOVER ) then
		--force a changelevel vote here
		self:GetVoteController():ResetVote() --TOO BAD, FUCK YOUR IN PROGRESS VOTE IF YOU HAD ANY
		if self.ConVars["DebugMode"]:GetBool() then
			MsgN( "Game Over after intermission" )
		end
	end

end

--called after the game is over and the intermission ended
function GM:GameOver()
	--get the map that was voted previously , otherwise just use the one in mapcycle.txt
	
	game.ConsoleCommand( "changelevel gm_construct\n" )
	--game.LoadNextMap()
end

function GM:AddScore( ply , score )
	if self:GetGameRules():IsRoundFlagOn( self.RoundFlags.INTERMISSION ) then return end

	local teament = self:GetTeamEnt( ply:Team() )

	if not IsValid( teament ) then return end


	if teament:GetTeamDeathmatch() then
		score = math.Clamp( ply:Frags() + score , 0 , math.huge )
		ply:SetFrags( score )
	else
		--don't let suicides decrease the teamscore
		local teamscore = score
		if score < 0 then teamscore = 0 end

		teament:AddScore( teamscore )

		score = math.Clamp( ply:Frags() + score , 0 , math.huge )

		ply:AddFrags( score )
	end

end

--[[
	called after a team scramble vote or the match has ended , can only be applied during an intermission
]]

function GM:ScrambleTeams()
	if self:GetGameRules():GetGameType() ~= self.GameTypes.TEAM_DEATHMATCH then 
		return false
	end

	local plys = {}

	--loop through all the players that are not spectators , add them to the table and then force them to spectate
	
	for i , v in pairs( player.GetAll() ) do
		if IsValid( v ) then	--don't add spectators to scramble list , they'll join when they want to
			local teament = self:GetTeamEnt( v:Team() )
			
			if IsValid( teament ) and not teament:GetTeamSpectators() then
				table.insert( plys , v )
				self:JoinTeam( v , nil , false )
			end
		end
	end

	--sort them by score

	table.sort( plys , function( a , b )
		return b:Frags() > a:Frags()
	end)

	--now make each one join the smallest team
	for i , ply in pairs( plys ) do
		self:JoinTeam( ply , team.BestAutoJoinTeam( true ) , false )
	end

	return true
end

function GM:JoinTeam( ply , teament , fromcommand )
	
	--check if the player doesn't have a team join cooldown, game logic skips this check

	if ply:GetNextJoinTeam() > CurTime() and fromcommand then
		return false
	end

	ply:SetNextJoinTeam( CurTime() + 0.1 )	--just so people don't spam the join team command and expect to get away with it
	
	--teament NULL / nil means that we're joining spectators
	if not IsValid( teament ) then
		for i = 0 , self.MAX_TEAMS do
			local te = self:GetTeamEnt( i )
			if IsValid( te ) and te:GetTeamSpectators() then
				teament = te
			end
		end
	end
	
	if not IsValid( teament ) or teament:GetTeamID() == ply:Team() then 
		return false 
	end

	--check if that team is actually valid or disabled

	if teament:GetTeamDisabled() then
		if not fromcommand then	--don't show this message if the invalid team was set from the game logic, it probably tried to autobalance this
			ErrorNoHalt( tostring( ply ) .. " tried to join an invalid or disabled team!" )
		end
		return false
	end

	--only kill the player when, he's alive , and he issued the command himself
	--otherwise respawn him instantly on that team

	ply:SetTeam( teament:GetTeamID() )

	if ply:Alive() then
		if fromcommand then
			ply:Kill()
		else
			ply:Spawn()
		end
	end

	ply:SetNextJoinTeam( CurTime() + 5 )	--we successfully set the player on this team, increase the cooldown further
	return true
end

--always override the damage calculation and relay this damage to sh_player.lua

function GM:EntityTakeDamage( ent , info )

	if ent:IsPlayer() and ent:Alive() then

		return self:PlayerTakeDamage( ent , info )

	end

end

GM:RegisterCommand("sm_jointeam", function(ply,command,args)
	if not IsValid( ply ) then 
		return 
	end

	local teament = Entity( tonumber( args[1] ) )
	
	if not IsValid( teament ) or teament:GetClass() ~= "sm_team" then
		return
	end

	gamemode.Call( "JoinTeam" , ply , teament , true )
end,function() end, "Makes the player using this command join a team. Usage sm_jointeam <team entindex>" , 0 )

GM:RegisterCommand("sm_takedamage", function( ply , command , args )
	if not GAMEMODE.ConVars["DebugMode"]:GetBool() or not IsValid( ply ) then 
		return 
	end
	
	local dmgname = args[1]
	
	if not dmgname then 
		return 
	end
	
	ply:SetHealth( 100 )
	ply:SetArmorBattery( 100 )
	
	local dmginfo = DamageInfo()
	dmginfo:SetDamage( 100 )
	dmginfo:SetDamageTypeFromName( dmgname )
	if not dmginfo:IsDamageType( DMG_PREVENT_PHYSICS_FORCE ) then
		dmginfo:SetDamageForce( Vector( 0 , 0 , 600 ) )
	else
		dmginfo:SetDamageForce( vector_origin )
	end
	dmginfo:SetDamagePosition( ply:WorldSpaceCenter() )
	dmginfo:SetAttacker( ply )
	dmginfo:SetInflictor( ply )

	ply:TakeDamageInfo( dmginfo )
end,
function( command , args )
	args = args:Trim():lower()

	local rettbl = {}
	for i , v in pairs( GAMEMODE.DamageTypes ) do
		if #args <= 0 or string.find( v.Name:lower() , args ) then
			table.insert( rettbl , command.." "..v.Name )
		end
	end
	return rettbl
end, "Testing command, take 100 damage from the inputted damage type. Usage sm_takedamage Crush", 0 )

GM:RegisterCommand("sm_endround",
function( ply , command , args )
	local rules = GAMEMODE:GetGameRules()
	if not IsValid( rules ) then return end
	rules:GoToIntermission()
end,
function( command , args )
end, "Forces the current round to end.", FCVAR_SERVER_CAN_EXECUTE )

GM:RegisterCommand("sm_gameover", function(ply,command,args)
	local rules = GAMEMODE:GetGameRules()
	
	if not IsValid( rules ) then
		return
	end

	--lame ass duplicated code!!!!!

	if rules:IsRoundFlagOn( GAMEMODE.RoundFlags.GAMEOVER ) then
		return
	end

	rules:ToggleRoundFlag( GAMEMODE.RoundFlags.GAMEOVER )
	rules:GoToIntermission( GAMEMODE:GetVoteController():GetVoteDuration() * 1.5 )
end,function() end, "Forces the game to be over.", FCVAR_SERVER_CAN_EXECUTE )