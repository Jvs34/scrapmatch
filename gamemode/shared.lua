
--derive from sandbox if the server is really small, this is done because I need some sandbox features
--to develop shit ( such as multimodels ) and no, this is not a backdoor, shut up
--you're never going to have a deathmatch server with a player count smaller than 10 anyway, what's the point otherwise

if game.MaxPlayers() <= 4 then
	DeriveGamemode("sandbox")
	DEFINE_BASECLASS( "gamemode_sandbox" )
else
	DeriveGamemode("base")
	DEFINE_BASECLASS( "gamemode_base" )
end

include("sh_recipientfilter.lua")
include("sh_specialaction.lua")
include("sh_player_meta.lua")
include("sh_entity_meta.lua")
include("sh_player.lua")
include("shd_module_multimodel.lua")
include("sh_teamoverride.lua")

include( "special_actions/sa_chaingun.lua" )
include( "special_actions/sa_circularsaw.lua" )

GM.Name 			= "Scrap Match"
GM.Author 			= "Jvs"
GM.Email 			= "N/A"
GM.Website 		= "www.peniscorp.com"

GM.WorkshopID 	= "292157435"								--used by the report bug command which opens the game overlay to the scrapmatch's workshop discussion
GM.WorkshopBugThread = "35220951687232956"		--the thread to prompt users to

GM.WorkshopLinkDirect = "http://steamcommunity.com/sharedfiles/filedetails/?id=%s"
GM.WorkshopLinkForum = "http://steamcommunity.com/workshop/filedetails/discussion/%s/%s/"

GM.ConVars 		= {}
GM.ConCommands	= {}

if SERVER then

	--the convar index helps set that variable on the corresponding networkvar on the gamerules entity and the type at the start of the description helps for the conversion
	GM.ConVars["ArmorMode"] =		CreateConVar( "sm_armormode" , "0", FCVAR_SERVER_CAN_EXECUTE + FCVAR_ARCHIVE , "Int;The current armor mode, 0 for default behaviour, 1 for borderlands style." )
	
	
	GM.ConVars["NextMap"] =			CreateConVar( "sm_nextmap" , "gm_construct", FCVAR_SERVER_CAN_EXECUTE + FCVAR_ARCHIVE , "String;The map to switch to when the game is over , leave blank to just reload the current one or to load one from the mapcycle." )
	
	GM.ConVars["MovementSpeed"] =	CreateConVar( "sm_movementspeed" , "400", FCVAR_SERVER_CAN_EXECUTE + FCVAR_ARCHIVE , "Int;The base movement speed the players start with as they spawn." )
	GM.ConVars["MaxScore"] =		CreateConVar( "sm_maxscore" , "100", FCVAR_SERVER_CAN_EXECUTE + FCVAR_ARCHIVE , "Int;Maximum score to end the round at. Set to -1 to disable." )
	GM.ConVars["MaxRounds"] =		CreateConVar( "sm_maxrounds" , "3", FCVAR_SERVER_CAN_EXECUTE + FCVAR_ARCHIVE , "Int;Maximum rounds that have to be played until the next map change / team scramble. Set to -1 to disable." )
	GM.ConVars["RoundDuration"] =	CreateConVar( "sm_roundduration" , "300", FCVAR_SERVER_CAN_EXECUTE + FCVAR_ARCHIVE , "Int;Max time in seconds for a round to end and beginning another. Set to -1 to disable." )
	GM.ConVars["GameType"] =		CreateConVar( "sm_gametype" , "0", FCVAR_SERVER_CAN_EXECUTE + FCVAR_ARCHIVE , "Int;The current game type, 0 for deathmatch , 1 for team deathmatch , 2 for zombie mode." )
	GM.ConVars["RoundFlags"] =		CreateConVar( "sm_roundflags" , "0", FCVAR_SERVER_CAN_EXECUTE + FCVAR_ARCHIVE , "Int;The current round flags which will be modified with a clientside GUI. Set to 0 to disable." )
	GM.ConVars["RespawnTime"] =		CreateConVar( "sm_respawntime" , "2", FCVAR_SERVER_CAN_EXECUTE + FCVAR_ARCHIVE , "Float;The respawn time in seconds that a player can spawn after." )

	GM.ConVars["DebugMode"] =		CreateConVar( "sm_debugmode" , "0", FCVAR_SERVER_CAN_EXECUTE + FCVAR_ARCHIVE , "Bool;Debug mode allows to run commands such as sm_givespecialaction. Set to 0 to disable." )

else
	--this pretty much works like createclientconvar or whatever the fuck it's called, except we're not gonna add FCVAR_USERINFO to the ones we
	--don't need accessible on the server
	
	GM.ConVars["ShowConnectMOTD"]	= CreateConVar( "sm_motd_showconnect" , "1", FCVAR_ARCHIVE , "Bool;Whether to show the motd / help screen on server join." )
	
	GM.ConVars["InputScoreboardKey"] =		CreateConVar( "sm_input_scoreboard" , "0", FCVAR_ARCHIVE + FCVAR_USERINFO , "Int;The key number to use the scoreboard for IN_SCORE." )
	GM.ConVars["InputGrenadeKey"] =		CreateConVar( "sm_input_grenade" , "0", FCVAR_ARCHIVE + FCVAR_USERINFO , "Int;The key number to use for IN_GRENADE1." )
	GM.ConVars["InputActiveActionKey"] =		CreateConVar( "sm_input_activeaction" , "0", FCVAR_ARCHIVE + FCVAR_USERINFO , "Int;The key number to use for IN_ATTACK3." )

	GM.ConVars["MaxGibs"] =		CreateConVar( "sm_gibs_max" , "15", FCVAR_ARCHIVE , "Int;The maximum amount of gibs displayed at any time. Set to -1 to disable the limit." )
	GM.ConVars["GibsFadeOut"] =		CreateConVar( "sm_gibs_fadeouttime" , "5", FCVAR_ARCHIVE , "Float;The time in seconds that gibs will stay on the ground. Set to -1 to never fade, NOT GOOD." )
	GM.ConVars["GibsPhysics"] =		CreateConVar( "sm_gibs_physics" , "1", FCVAR_ARCHIVE , "Bool;Whether gibs should collide with each other and other clientside stuff." )

	--this is clientside because each player has its own preference

	GM.ConVars["AnnouncerMute"] =		CreateConVar( "sm_announcer_mute" , "0", FCVAR_ARCHIVE + FCVAR_USERINFO , "Bool;Mutes the announcer" )
	GM.ConVars["AnnouncerVolume"] =		CreateConVar( "sm_announcer_volume" , "1", FCVAR_ARCHIVE , "Float;The volume the announcer should be played at" )

	--the convar index helps set that variable on the corresponding variable on the panel and the type at the start of the description helps for the conversion

	GM.ConVars["CrossHairR"] =			CreateConVar( "sm_crosshair_r" , "255", FCVAR_ARCHIVE , "Int;The red value of the crosshair color" )
	GM.ConVars["CrossHairG"] =			CreateConVar( "sm_crosshair_g" , "255", FCVAR_ARCHIVE , "Int;The green value of the crosshair color" )
	GM.ConVars["CrossHairB"] =			CreateConVar( "sm_crosshair_b" , "255", FCVAR_ARCHIVE , "Int;The blue value of the crosshair color" )
	GM.ConVars["CrossHairScale"] =		CreateConVar( "sm_crosshair_scale" , "0.5", FCVAR_ARCHIVE , "Float;The scale of the cursor. Set to -1 to automatically scale." )
	GM.ConVars["CrossHairShowAmmo"] =	CreateConVar( "sm_crosshair_ammo" , "1", FCVAR_ARCHIVE , "Bool;Whether to show the ammo on the left and right sides of the crosshair." )
	GM.ConVars["CrossHairHitSoundEnabled"] =	CreateConVar( "sm_crosshair_hitsound_enabled" , "0", FCVAR_ARCHIVE , "Bool;Whether to enable the hitsound." )
	GM.ConVars["CrossHairHitSoundPath"] =	CreateConVar( "sm_crosshair_hitsound_path" , "Buttons.snd10", FCVAR_ARCHIVE , "String;The hitsound to use." )
	GM.ConVars["CrossHairHitSoundDelay"] =	CreateConVar( "sm_crosshair_hitsound_delay" , "0.1", FCVAR_ARCHIVE , "Float;The minimum delay before emitting another hitsound. Set to 0 for no limit." )


	GM.ConVars["HUDAnimations"]	= CreateConVar( "sm_hud_animations" , "1", FCVAR_ARCHIVE , "Bool;Enables or disables ALL onscreen animations applied to hud, scoreboard and such." )
	GM.ConVars["HUDRenderInScreenshots"]	= CreateConVar( "sm_hud_renderinscreenshots" , "1", FCVAR_ARCHIVE , "Bool;Enables or disables whether to render the HUD in screenshots." )
	
	GM.ConVars["DamageTimeOnScreen"]	= CreateConVar( "sm_damageinfo_time" , "1", FCVAR_ARCHIVE , "Float;The time in seconds to how fast to decay the damage info." )
	
	
end

GM.RoundFlags = {
	INTERMISSION			= 2 ^ 0,			--set as the round ended or we're about to change map
	TEAM_SCRAMBLE			= 2 ^ 1,			--this is checked at the end of the round
	INFINITE_AMMO			= 2 ^ 2,			--all weapons and items don't waste ammo, they're still subject to reload speeds though
	INSTAGIB 				= 2 ^ 3,			--any damage is fatal and gibs the user
	LASTMANSTANDING			= 2 ^ 4,			--once you die you won't respawn, the round ends only when one guy is alive, pretty much like tf2's arena mode or whatever
	GAMEOVER				= 2 ^ 5,			--the game is over, the level will be changed after the intermission is over , this also forces the scoreboard on and stops players' movement
}

GM.GameTypes = {
	DEATHMATCH			= 0,
	TEAM_DEATHMATCH		= 1,
	ZOMBIE				= 2,
}

GM.CustomInputs = {
--[[
	IN_DROP_LEFT_ACTION = {
		Value = 2 ^ 0,
		ConVar = convarobj,	--only on the client
	},
]]
}


for index , value in pairs( SA.Slots ) do

	--skip undefined, we don't want to add a binding for it
	if value ~= SA.Slots.UNDEFINED then
		local cv = nil

		if CLIENT then
			cv = CreateConVar( "sm_input_drop_"..index:lower() , "0", FCVAR_ARCHIVE + FCVAR_USERINFO , "Int;The key to use for this input." )
		end

		GM.ConVars["CustomInputDrop"..index] = cv
		GM.CustomInputs["IN_DROP_"..index] = {
			Value = 2 ^ value,
			ConVar = cv,
			Button = false,
			Command = "slot"..( value + 1 ),
		}
	end

end

GM.CustomInputs["IN_SHOW_SCOREBOARD"] = {
	Value = IN_SCORE,
	ConVar = GM.ConVars["InputScoreboardKey"],
	Command = "+showscores",
	Button = true,
}

GM.CustomInputs["IN_THROW_GRENADE1"] = {
	Value = IN_GRENADE1,
	ConVar = GM.ConVars["InputGrenadeKey"],
	Command = "+menu_context",
	Button = true,
}

GM.CustomInputs["IN_USE_ACTIVE"] = {
	Value = IN_ATTACK3,
	ConVar = GM.ConVars["InputActiveActionKey"],
	Command = "reload",
	Button = true,
}


--we index by the normal damage itself because it's easier than having to loop through the table and check for the name inside the value everytime
--this is probably going to change in the future
GM.DamageTypes = {
	[DMG_BULLET] = {
		Name = "Bullet",
		ArmorEfficiency = 0.5,
		Flags = bit.bor( DMG_BULLET , DMG_NEVERGIB ),
	},
	[DMG_SLASH] = {
		Name = "Slash",
		ArmorEfficiency = 0.25,
		Flags = bit.bor( DMG_SLASH , DMG_ALWAYSGIB ),
	},
	[DMG_SHOCK] = {
		Name = "Shock",
		ArmorEfficiency = 0.75,
		Flags = bit.bor( DMG_SHOCK , DMG_NEVERGIB ),
	},
	[DMG_ENERGYBEAM] = {
		Name = "Shock drain",
		ArmorEfficiency = 1,
		NoDamageToHealth = true,
		Flags = bit.bor( DMG_ENERGYBEAM , DMG_NEVERGIB ),
	},
	[DMG_BLAST] = {
		Name = "Explosive",
		ArmorEfficiency = 0.375,
		ForceMultiplier = 2,
		Flags = bit.bor( DMG_BLAST , DMG_ALWAYSGIB ),
	},
	[DMG_CLUB] = {
		Name = "Crush",
		ArmorEfficiency = 0,
		Flags = bit.bor( DMG_CLUB , DMG_PREVENT_PHYSICS_FORCE , DMG_NEVERGIB ),
	},
}


GM.HUDBits = {
	HUD_ALLBITS = 0,				--calculated afterwards
	HUD_HEALTH = 2 ^ 0,				--health , always shown unless dead or spectating
	HUD_ARMOR	= 2 ^ 1,				--armor , always shown with health unless armor is 0
	HUD_AMMO	= 2 ^ 2,					--same rules as health
	HUD_ROUNDSTATUS	= 2 ^ 3,		--always shows, it shows the current round, round timer, current score
	HUD_SCOREBOARD	= 2 ^ 4,		--shown when the user presses IN_SCORE or we're in intermission
	HUD_CROSSHAIR		= 2 ^ 5,		--always shown , unless dead
	HUD_ROUNDLOG		= 2 ^ 6,		--always shown, it shows not only
	HUD_PLAYERINFO	= 2 ^ 7,			--always set to be shown , but only actually shown when the player is looking at a player or that player killed us
}

for i , v in pairs( GM.HUDBits ) do
	if i ~= "HUD_ALLBITS" then
		GM.HUDBits.HUD_ALLBITS = bit.bor( GM.HUDBits.HUD_ALLBITS , v )
	end
end

GM.PlayerStatus = {
	FROZEN_MOVEMENT 	= 2 ^ 0,
	SLOWED_MOVEMENT 	= 2 ^ 1,
	WEAPONS_DISABLED 	= 2 ^ 2,
	ACTIONS_DISABLED 	= 2 ^ 3,
	PLANB				= 2 ^ 4,
}

--[[
	you can have up to GMOD_MAX_DTVARS teams ( obviously limited to DT var entities , but please don't )
	you can safely increase this without adding a tied GM.TEAM_ enum, you'll need to create the team yourself with that ID during GM:InitPostEntity()
]]
GM.MAX_TEAMS = 4

--TODO: a way to keep track of the commands we register in the gamemode

function GM:RegisterCommand( str , ... )
	self.ConCommands[str] = true
	concommand.Add( str , ... )
end

--this is called even before GM:Initialize() , plus we don't initialize the teams the normal way, so buzz off
function GM:CreateTeams()

end

function GM:GetGameRules()
	if self.GameRules and self.GameRules.dt then return self.GameRules end

	for i,v in pairs( ents.FindByClass( "sm_gamerules" ) ) do
		if IsValid( v ) then
			self.GameRules = v
			break
		end
	end
	
	if self.GameRules and self.GameRules.dt then
		return self.GameRules
	end
end

function GM:GetVoteController()
	if self.VoteController and self.VoteController.dt then return self.VoteController end

	for i,v in pairs( ents.FindByClass( "sm_votecontroller" ) ) do
		if IsValid( v ) then
			self.VoteController = v
			break
		end
	end

	return self.VoteController
end

function GM:GetAnnouncer()
	if self.Announcer and self.Announcer.dt then return self.Announcer end

	for i,v in pairs( ents.FindByClass( "sm_announcer" ) ) do
		if IsValid( v ) then
			self.Announcer = v
			break
		end
	end

	return self.Announcer
end

function GM:GetTeamEnt( id )
	if not IsValid( self:GetGameRules() ) then return end

	return self:GetGameRules():GetTeamEntity( id )
end

function GM:GetCamera( index )
	for i,v in pairs( ents.FindByClass( "sm_camera" ) ) do
		if IsValid( v ) and v:GetCameraIndex() == index then
			return v
		end
	end
end

function GM:GetCameraInSequence( ply , i )
	local currentcamera = ply:GetObserverTarget()

	local index = 1

	if IsValid( currentcamera ) and currentcamera:GetClass() == "sm_camera" then
		index = currentcamera:GetCameraIndex()
	end

	if i then
		index = index + i
	else
		index = math.random( 1 , self:GetGameRules():GetCameraCount() )
	end
	
	if index < 1 then
		index = self:GetGameRules():GetCameraCount()
	end

	if index > self:GetGameRules():GetCameraCount() then
		index = 1
	end

	local newcam = self:GetCamera( index )

	--this is serverside only? fuck off, I want prediction on this shit FFS
	--VINH'LL FIX IT @@@@@
	
	if IsValid( newcam ) then
		
		if currentcamera:GetControllingPlayer() == ply then
			currentcamera:SetControllingPlayer( nil )
		end
		
		if not IsValid( newcam:GetControllingPlayer() ) and not newcam:GetAutoOnly() then
			newcam:SetControllingPlayer( ply )
		end
		
		if SERVER then
			ply:SpectateEntity( newcam )
		end
	end
end


if CLIENT then
	GM:RegisterCommand("sm_reportbug", function(ply,command,args)
		local url = Format( GAMEMODE.WorkshopLinkForum , GAMEMODE.WorkshopID , GAMEMODE.WorkshopBugThread )
		gui.OpenURL( url )
	end,function() end, "Opens the steam overlay to report a bug." , FCVAR_CLIENTCMD_CAN_EXECUTE )
else

end

--TODO: MOVE THIS SHIT TO UTIL AAAAAAAAAAAAAAAAAAH

--thanks vinh cunt
local colormeta = FindMetaTable("Color")

function colormeta:FromHex( hexcol )
	self.r = bit.band(bit.rshift(hexcol, 16), 0xff)
	self.g = bit.band(bit.rshift(hexcol, 8), 0xff)
	self.b = bit.band(hexcol, 0xff)
end

function colormeta:ToHex()
	return bit.bor(bit.bor(bit.lshift(self.r, 16), bit.lshift(self.g, 8)), self.b)
end

local dmginfometa = FindMetaTable( "CTakeDamageInfo" )

--used by special actions when constructing a new damage info
--note, we don't set the actual damage type flags here , but just the index because we want an easier time at checking the damage type in EntityTakeDamage
function dmginfometa:SetDamageTypeFromName( name )
	
	for i,v in pairs( GAMEMODE.DamageTypes ) do
		if name:lower() == v.Name:lower() then
			self:SetDamageType( i )
			return
		end
	end
	
end
