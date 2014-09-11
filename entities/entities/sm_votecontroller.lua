AddCSLuaFile()

if SERVER then
	util.AddNetworkString("sm_votecontroller_startvote")
	util.AddNetworkString("sm_votecontroller_castvote")
	util.AddNetworkString("sm_votecontroller_endvote")
end

ENT.Type 			= "anim"
ENT.Base 			= "base_entity"


ENT.VoteTypes = {
	NONE = 0,
	NEXTMAP = 1,
	MODECHANGE = 2,
	TEAMSCRAMBLE = 3,
	ROUNDFLAGS = 4,
	KICK = 5,
	LAST = 6,
}

ENT.VoteData = {
	[ENT.VoteTypes.NONE] = nil,
	[ENT.VoteTypes.NEXTMAP] = {
		Type = "String",	--contains the next map name
	--	MaxCharacters = 16,
	},
	[ENT.VoteTypes.MODECHANGE] = {
		Type = "Int",	--contains the id of the mode we want to play
		Min = 0,
		Max = 2,
		BitCounts = 16,
	},
	[ENT.VoteTypes.TEAMSCRAMBLE] = {
		--Type = "Bool", --not used for now
	},
	[ENT.VoteTypes.ROUNDFLAGS] = {
		Type = "Int",	--contains the id of the round flags we want to play with
		FromTable = GAMEMODE.RoundFlags,	--contains the table we should show stuff from
		Exclude = {
			GAMEMODE.RoundFlags.INTERMISSION,
			GAMEMODE.RoundFlags.GAMEOVER,
			GAMEMODE.RoundFlags.TEAM_SCRAMBLE,
		},
		BitCounts = 16,
	},
	[ENT.VoteTypes.KICK] = {
		Type = "Entity",
		ClassName = "player",	--can only cast this vote on entities of classname player
		CastOnSelf = false,		--the user can't kick himself ( in case the vote can be cast on players )
	},
	[ENT.VoteTypes.LAST] = nil,
}

function ENT:Initialize()

	if SERVER then
		self:SetNoDraw( true )
		self:ResetVote()
		self:SetName( self:GetClass() )
	end
end

function ENT:SetupDataTables()
	self:NetworkVar( "Int"	, 0 , "VoteType" )		--the votetype enum from self.VoteTypes
	self:NetworkVar( "Float"	, 0 , "VoteExpiresTime" )
	self:NetworkVar( "Float"	, 1 , "VoteDuration" )
	
	self:NetworkVar( "Int" , 1 , "VoteDataInt" )
	self:NetworkVar( "Float" , 2 , "VoteDataFloat" )
	self:NetworkVar( "Bool" , 0 , "VoteDataBool" )
	self:NetworkVar( "Entity" , 0 , "VoteDataEntity" )
	self:NetworkVar( "String" , 0 , "VoteDataString" )
	
	self:NetworkVar( "Int" , 2 , "VoteAgreeCount" )
	self:NetworkVar( "Int" , 3 , "VoteDisagreeCount" )
	
	self:NetworkVar( "Entity" , 1 , "VoteStarter" )
end

function ENT:IsVoteInProgress()
	return self:GetVoteType() ~= self.VoteTypes.NONE
end

function ENT:GetVoteData()
	if self.VoteData[self:GetVoteType()] then
		local typ = self.VoteData[self:GetVoteType()].Type
		if self["GetVoteData"..typ] then
			return self["GetVoteData"..typ]( self )
		end
	end
end

if SERVER then
	--TODO: add support for map inputs

	function ENT:Think()
		if not self:IsVoteInProgress() then return end
		
		--vote expired! get the results and ask the gamemode to do whatever before we reset
		if self:GetVoteExpiresTime() ~= -1 and self:GetVoteExpiresTime() < CurTime() then
			gamemode.Call( "VoteConcluded" , self , self:GetVoteType() , self:GetVoteData() )
			self:ResetVote()
		end
		
	end

	function ENT:UpdateTransmitState()
		return TRANSMIT_ALWAYS
	end
	
	function ENT:ResetVote()
		self:SetVoteType( self.VoteTypes.NONE )
		self:SetVoteExpiresTime( -1 )
		self:SetVoteStarter( nil )
		
		self:SetVoteDataInt( 0 )
		self:SetVoteDataFloat( 0 )
		self:SetVoteDataEntity( nil )
		self:SetVoteDataString( "" )
		
		self:SetVoteDisagreeCount( 0 )
		self:SetVoteAgreeCount( 0 )
		
	end
	
	function ENT:IncreaseAgree()
		self:SetVoteAgreeCount( self:GetVoteAgreeCount() + 1 )
	end
	
	function ENT:IncreaseDisagree()
		self:SetVoteDisagreeCount( self:GetVoteDisagreeCount() + 1 )
	end
	
	--called when the player asks to start for a new vote , this is called from a net message
	
	function ENT:StartVote( ply )
		if self:IsVoteInProgress() then return end
		
		--read the vote type
		local votetype = net.ReadUInt( 8 )	--one unsigned byte is enough
		if votetype > self.VoteTypes.NONE and votetype < self.VoteTypes.LAST then
			
			if self.VoteData[votetype] and self.VoteData[votetype].Type then
				local typ = self.VoteData[votetype].Type
				if typ == "Int" then
					local value = net.ReadInt( self.VoteData[votetype].BitCounts or 32 )
					if self.VoteData[votetype].Min and self.VoteData[votetype].Max then
						value = math.Clamp( value , self.VoteData[votetype].Min , self.VoteData[votetype].Max )
					end
					
					if self.VoteData[votetype].Exclude then
						--remove excluded flags here, because some cheeky bastards might still add them manually and fuck shit up
						for i , v in pairs( self.VoteData[votetype].Exclude ) do
							if bit.band( value , v ) ~= 0 then
								value = bit.bxor( value , v )
							end
						end
					end
					
					self:SetVoteDataInt( value )
				elseif typ == "String" then
					local value = net.ReadString()
					
					if self.VoteData[votetype].MaxCharacters then
						value = value:Left( self.VoteData[votetype].MaxCharacters )
					end
					
					self:SetVoteDataString( value )
				elseif typ == "Bool" then
					local value = tobool( net.ReadBit() )
					
					self:SetVoteDataBool( value )
				elseif typ == "Float" then
					local value = net.ReadFloat()
					if self.VoteData[votetype].Min and self.VoteData[votetype].Max then
						value = math.Clamp( value , self.VoteData[votetype].Min , self.VoteData[votetype].Max )
					end
					self:SetVoteDataFloat( value )
				elseif typ == "Entity" then
					local value = net.ReadEntity()
					
					--the user gave us something that is clientside only (like gibs that he can fire trace on?) or that was deleted soon before he sent the message
					if not IsValid( value ) then
						return
					end
					
					if self.VoteData[votetype].ClassName and value:GetClass():lower() ~= self.VoteData[votetype].ClassName then
						return
					end
					
					if value == ply and not self.VoteData[votetype].CastOnSelf then
						return
					end
					
					self:SetVoteDataEntity( value )
				end
								
			end

			self:SetVoteStarter( ply )
			self:SetVoteType( votetype )
			self:SetVoteExpiresTime( CurTime() + self:GetVoteDuration() )
			
			--this is the player that started the vote, always make him agree with his vote, duh
			if IsValid( ply ) then
				ply:SetHasVoted( true )
				self:IncreaseAgree()
			end
			
		end
	end
	
	--called when the player wants to express his vote
	
	function ENT:CastVote( ply )
		if not self:IsVoteInProgress() or not gamemode.Call("CanCastVote", ply ) then return end
		
		local vote = tobool( net.ReadBit() )
		
		if vote == nil then return end
		
		if vote then
			self:IncreaseAgree()
		else
			self:IncreaseDisagree()
		end
		
		ply:SetHasVoted( true )
	end

	net.Receive("sm_votecontroller_startvote", function( len , ply )
		if not IsValid( ply ) then return end
		local votecontroller = GAMEMODE:GetVoteController()
		if IsValid( votecontroller ) then
			votecontroller:StartVote( ply )
		end
	end)
	
	net.Receive("sm_votecontroller_castvote", function( len , ply )
		if not IsValid( ply ) then return end
		local votecontroller = GAMEMODE:GetVoteController()
		if IsValid( votecontroller ) then
			votecontroller:CastVote( ply )
		end
	end)
	
end