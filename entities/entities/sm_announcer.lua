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
			KillsPercent = 1,	--he has to slay the entire enemy team
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

	}
end

function ENT:Initialize()
	
	if SERVER then
		self:SetNoDraw( true )
		self:SetName( self:GetClass() )
	end
	
end

function ENT:SetupDataTables()

end

--called when the round starts , not when it ends because a player might still go on a rampage

function ENT:RoundReset()
	self.PlayerInfo = {}
	for i , v in pairs( self.GlobalFlags ) do
		v.Achieved = false
	end
end

function ENT:Think()

end

if SERVER then

	function ENT:UpdateTransmitState()
		return TRANSMIT_ALWAYS
	end

end