AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "cl_hud.lua" )
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

	--why are these loaded in the first place , buzz off, these would be good if there was a way to configure them properly without having to remove and readding them
	--but no, not even worth it
	concommand.Remove( "gmod_cleanup" )
	concommand.Remove( "gmod_admin_cleanup" )

	--version check maybe?
end

function GM:InitPostEntity()

	--these entities are never going to be deleted, so it's safe to create them in InitPostEntity

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
	votecontroller:Spawn()

	--setup the team entities

	local spectatorteam = self:GetTeamEnt( self.TEAM_SPECTATORS	)
	spectatorteam:SetTeamName( "Spectators" )
	spectatorteam:SetTeamColor( Color( 80 , 80 , 80 ) )
	spectatorteam:SetTeamDisabled( false )
	spectatorteam:SetTeamSpawnPoint( "worldspawn" )	--this will be changed into the camera entity class soon

	local deathmatch = self:GetTeamEnt( self.TEAM_DEATHMATCH )
	deathmatch:SetTeamName( "Deathmatch" )
	deathmatch:SetTeamFriendlyFire( true )
	deathmatch:SetTeamColor( Color( 120 , 255 , 120 ) )
	deathmatch:SetTeamDisabled( false )

	local redteam = self:GetTeamEnt( self.TEAM_RED )
	redteam:SetTeamName( "Red" )
	redteam:SetTeamFriendlyFire( false )
	redteam:SetTeamColor( Color( 255 , 120 , 120 ) )
	redteam:SetTeamDisabled( false )

	local bluteam = self:GetTeamEnt( self.TEAM_BLU )
	bluteam:SetTeamName( "Blu" )
	bluteam:SetTeamFriendlyFire( false )
	bluteam:SetTeamColor( Color( 120 , 120 , 255 ) )
	bluteam:SetTeamDisabled( false )

	--configure your custom teams here

	--debugging shit
	for i = 1 , self.MAX_TEAMS do
		local teament = self:GetTeamEnt( i )
		if IsValid( teament ) then
			local col = teament:GetTeamColor()
			MsgC( col, teament:GetTeamID() .. ": " , col , teament:GetTeamName() , col , "\n" )
		end
	end

	--this forces an intermission check and starts the round right away
	rules:GoToIntermission( nil , true )
	--rules:ToggleRoundFlag( self.RoundFlags.INTERMISSION )

end


function GM:VoteConcluded( voteentity , votetype , votedata )
	if not IsValid( voteentity ) then return end	--this should never happen since we got this called from the vote entity itself!

	if voteentity:GetAgreeCount() > voteentity:GetDisagreeCount() then
		ErrorNoHalt( "Vote succeeded" )
		--TODO: apply the vote, change whatever flags it needed to
	else
		ErrorNoHalt( "Vote failed" )
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

function GM:RoundStart( )

	--cleanup the whole map, ignore the entities in the cleanupfilter
	MsgN( "Round started" )

	game.CleanUpMap( true , self.CleanupFilter )

	--enable or disable the teams depending on the game type, also reset their score

	for i = 1 , self.MAX_TEAMS do

		local teament = self:GetTeamEnt( i )

		if not IsValid( teament ) then continue end

		if teament:GetTeamID() == self.TEAM_SPECTATORS then continue end

		teament:SetTeamScore( 0 )

		if teament:GetTeamID() == self.TEAM_DEATHMATCH then
			teament:SetTeamDisabled( self:GetGameRules():GetGameType() ~= self.GameTypes.DEATHMATCH )
		else
			teament:SetTeamDisabled( self:GetGameRules():GetGameType() == self.GameTypes.DEATHMATCH )
		end

	end

	--force all the players to respawn , even spectators just in case

	for i , v in pairs( player.GetAll() ) do
		local teament = self:GetTeamEnt( v:Team() )
		if IsValid( teament ) and teament:GetTeamDisabled() then
			self:JoinTeam( v , team.BestAutoJoinTeam() , false )
		else
			v:Spawn()
		end
	end
	--scramble the teams if we had the flag previously set

	if self:GetGameRules():IsRoundFlagOn( self.RoundFlags.TEAM_SCRAMBLE ) then
		self:ScrambleTeams()
		self:GetGameRules():ToggleRoundFlag( self.RoundFlags.TEAM_SCRAMBLE )
	end

end

function GM:RoundEnd( )
	if self:GetGameRules():IsRoundFlagOn( self.RoundFlags.GAMEOVER ) then
		--force a changelevel vote here
		self:GetVoteController():ResetVote() --TOO BAD, FUCK YOUR IN PROGRESS VOTE IF YOU HAD ANY
		MsgN( "Game Over after intermission" )
	end
end

--called after the game is over and the intermission ended
function GM:GameOver()
	--get the map that was voted previously , otherwise just use the one in mapcycle.txt
	
	--game.LoadNextMap( )
end

function GM:AddScore( ply , score )
	if self:GetGameRules():IsRoundFlagOn( self.RoundFlags.INTERMISSION ) then return end

	local teament = self:GetTeamEnt( ply:Team() )

	if not IsValid( teament ) then return end


	if teament:GetTeamID() == self.TEAM_DEATHMATCH then
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
	if self:GetGameRules():GetGameType() ~= self.GameTypes.TEAM_DEATHMATCH then return false end

	local plys = {}

	--loop through all the players that are not spectators , add them to the table and then force them to spectate
	
	for i,v in pairs( player.GetAll() ) do
		if IsValid( v ) and v:Team() ~= self.TEAM_SPECTATORS then	--don't add spectators to scramble list , they'll join when they want to
			table.insert( plys , v )
			self:JoinTeam( v , self.TEAM_SPECTATORS , false )
		end
	end

	--sort them by score

	table.sort( plys , function( a , b )
		return b:Frags() > a:Frags()
	end)

	--now make each one join the smallest team
	for i , ply in pairs( plys ) do
		self:JoinTeam( ply , team.BestAutoJoinTeam() , false )
	end

	return true
end

function GM:JoinTeam( ply , id , fromcommand )

	--check if the player doesn't have a team join cooldown, game logic skips this check

	if ply:GetNextJoinTeam() > CurTime() and fromcommand then
		return false
	end

	ply:SetNextJoinTeam( CurTime() + 2 )	--just so people don't spam the join team command and expect to get away with it

	if id == ply:Team() then return false end	--you wot

	local teament = self:GetTeamEnt( id )

	--check if that team is actually valid or disabled

	if not IsValid( teament ) or teament:GetTeamDisabled() then
		ErrorNoHalt( tostring( ply ) .. " tried to join an invalid or disabled team!" )
		return false
	end

	--only kill the player when, he's alive , and he issued the command himself
	--otherwise respawn him instantly on that team

	ply:SetTeam( teament:GetTeamID() )

	if ply:Alive() then
		if fromcommand then	--I asked this!
			ply:Kill()
		else							--I never asked for this!
			ply:Spawn()
		end
	end

	ply:SetNextJoinTeam( CurTime() + 5 )	--we successfully set the player on this team, increase the cooldown further
	return true
end

--relay this damage to sh_player.lua

function GM:EntityTakeDamage( ent , info )

	if ent:IsPlayer() and ent:Alive() then

		return self:PlayerTakeDamage( ent , info )

	end

end

concommand.Add("sm_jointeam", function(ply,command,args)
	if not IsValid( ply ) then return end

	local team = tonumber( args[1] )

	if not team then
		return
	end

	--TODO: replace this with a gamemode.Call so people can hook into it
	GAMEMODE:JoinTeam( ply , team , true )
end,function() end, "Makes the player using this command join a team. Usage sm_jointeam <teamid>" , 0 )

concommand.Add("sm_takedamage", function(ply,command,args)
	if not GAMEMODE.ConVars["DebugMode"]:GetBool() then return end
	if not IsValid( ply ) then return end
	local dmgname = args[1]
	--[[
	ply:SetHealth( 100 )
	ply:SetArmorBattery( 100 )
	]]
	local dmginfo = DamageInfo()
	dmginfo:SetDamage( 100 )
	dmginfo:SetDamageTypeFromName( dmgname )
	dmginfo:SetDamageForce( vector_origin )
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

concommand.Add("sm_endround",
function(ply,command,args)
	local rules = GAMEMODE:GetGameRules()
	if not IsValid( rules ) then return end
	rules:GoToIntermission()
end,
function( command , args )
end, "Forces the current round to end.", FCVAR_SERVER_CAN_EXECUTE )

concommand.Add("sm_gameover", function(ply,command,args)
	local rules = GAMEMODE:GetGameRules()
	if not IsValid( rules ) then return end

	--lame ass duplicated code!!!!!

	if rules:IsRoundFlagOn( GAMEMODE.RoundFlags.GAMEOVER ) then return end

	rules:ToggleRoundFlag( GAMEMODE.RoundFlags.GAMEOVER )
	rules:GoToIntermission( GAMEMODE:GetVoteController():GetVoteDuration() * 1.5 )
end,function() end, "Forces the game to be over.", FCVAR_SERVER_CAN_EXECUTE )