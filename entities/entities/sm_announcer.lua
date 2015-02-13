AddCSLuaFile()

ENT.Type 			= "anim"
ENT.Base 			= "base_entity"

ENT.Notices = {
	FIRSTBLOOD	= 2 ^ 0,
	DOUBLEKILL	= 2 ^ 1,
	TRIPLEKILL	= 2 ^ 2,
	MULTIKILL	= 2 ^ 3,
	GODLIKE 	= 2 ^ 4,
	UNSTOPPABLE	= 2 ^ 5,
	RAMPAGE		= 2 ^ 6,
	RAGEQUIT	= 2 ^ 7,
}

if SERVER then
	util.AddNetworkString( "sm_announcer_message" )
	
	ENT.GlobalFlags = {
		[ENT.Notices.FIRSTBLOOD] = {
			AchievedOnce = true,	--can only be achieved once, if this is true Achieved will be set to true when that happens
			Achieved = false,
			Kills = 1,
			KillsPercent = 0,
			SameFrame = false,
		},
		[ENT.Notices.MULTIKILL] = {
			Kills = 2,
			KillsPercent = 0,
			SameFrame = true,
		},
		[ENT.Notices.RAMPAGE] = {
			Kills = 0,
			KillsPercent = 1,	--he has to slay an amount of players equal to their ( in case of deathmatch, his ) team size
			SameFrame = false
		},
	}
	
	ENT.PlayerInfo = {
		--[[
		[ply:UserID()] = {
			Flags = ENT.Notices.FIRSTBLOOD + ENT.Notices.DOUBLEKILL,
			LastKill = CurTime(),
			CurrentKills = 2,	--reset when the player dies
			SameFrameKills = 0, --set when the player kills two ore more players in the same LastKill frame
		},
		
		]]
	}
else
	ENT.Sounds = {
		[ENT.Notices.FIRSTBLOOD] = {
			SoundPath = "https://dl.dropboxusercontent.com/u/20140357/filessharex/announcer_1stblood_01.mp3",
			SoundChannel = nil,	--the sound channel will be created and stored here
			SoundType = "url",	--either "url" or "file"
		},
		[ENT.Notices.DOUBLEKILL] = {
			SoundPath = "https://dl.dropboxusercontent.com/u/20140357/filessharex/announcer_kill_double_01.mp3",
			SoundChannel = nil,	--the sound channel will be created and stored here
			SoundType = "url",	--either "url" or "file"
		}
	}
	
	ENT.CurrentChannel = nil	--stores the currently playing channel, which will be then stopped and replaced with another one to play
end

function ENT:Initialize()
	
	if SERVER then
		self:SetNoDraw( true )
		self:SetName( self:GetClass() )
	else
		--cache all the bass sounds here and store them on the same table
		self:CacheSounds()
	end
	
end

function ENT:SetupDataTables()

end

function ENT:Think()

end

if SERVER then

	function ENT:UpdateTransmitState()
		return TRANSMIT_ALWAYS
	end
	
	--called when the round starts , not when it ends because a player might still go on a rampage

	function ENT:RoundReset()
		self.PlayerInfo = {}
		for i , v in pairs( self.GlobalFlags ) do
			v.Achieved = false
		end
	end
	
	--called from DoPlayerDeath
	function ENT:OnPlayerKill( ply , victim , dmginfo )
		
	end

	--called from OnPlayerDisconnected , we keep track of the attacker so we can track ragequits
	function ENT:OnPlayerRagequit( ply , attacker )
	
		--bots will be added/removed at anytime, so don't spam shit when they leave
		if ply:IsBot() then 
			return 
		end
		
		if not IsValid( attacker ) or not attacker:IsPlayer() then 
			return 
		end
		
		--the ragequit must be real! it's only considered a ragequit if that attacker had a spree which would've been worth recording
		
		if not self.PlayerInfo[attacker:UserID()] then 
			return 
		end
		
		if self.PlayerInfo[attacker:UserID()].Flags < self.Notices.FIRSTBLOOD then 
			return 
		end
		
		local message = {
			Notice = self.Notices.RAGEQUIT,
			Player = ply,
		}
		
		--self:SendMessage( message )
	end
	
	function ENT:SendMessage( contentstab )
	
		if not contentstab or not IsValid( contentstab.Player ) or not contentstab.Notice then
			return
		end
		
		--[[
			{
				Notices = the notice
				Player = player entity that caused this notice, nil if it's not valid
				Duration = duration of the notice in seconds, uses the duration of the kill reasons by default
			}
		]]
		local filter = LuaRecipientFilter()
		filter:AddAllPlayers()
		
		net.Start( "sm_announcer_message" )
			net.WriteUInt( contentstab.Notice , 16 )
			net.WriteEntity( contentstab.Player )
			net.WriteFloat( contentstab.Duration or 0 )
		net.Send( filter() )
	end
else
	
	function ENT:ReceiveMessage( len )
		if GAMEMODE.ConVars["AnnouncerMute"]:GetBool() then
			return
		end
		
		if IsValid( self.CurrentChannel ) then
			self.CurrentChannel:Stop()
			self.CurrentChannel = nil
		end
		
		--TODO
	end
	
	net.Receive( "sm_announcer_message" , function( len )
		local announcer = GAMEMODE:GetAnnouncer()
		if not IsValid( announcer ) then return end
		
		announcer:ReceiveMessage( len )
	end)
	
	function ENT:CacheSounds()
		for i , v in pairs( self.Sounds ) do
			if not IsValid( v.SoundChannel ) then
				local functouse = sound.PlayURL
				
				if v.SoundType == "file" then
					functouse = sound.PlayFile
				end
				
				functouse( v.SoundPath , "noplay mono" , function( channel , errorid )
					
					if not IsValid( channel ) then 
						return 
					end
					
					v.SoundChannel = channel
				end)
			end
		end
	end
end