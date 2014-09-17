AddCSLuaFile()

--[[
	this is a glorified net message , we're going to call setupbones on the player ,
	get the shatter percentage and then spawn as many sm_player_gibs as computed
	and associate them to a
]]

function EFFECT:Init( data )
	self.OverKill = data:GetMagnitude()
	self.OverKill = math.Clamp( self.OverKill , 0.1 , 1 )
	
	self.Direction = data:GetAngles()
	self.Speed = data:GetScale()
	
	self.Owner = data:GetEntity()
	if not IsValid( self.Owner ) then return end
	
	self.Owner:SetupBones()

	
	local bones = self.Owner:GetHitBoxCount( 0 ) - 1
	local gibs = math.Roubones * self.OverKill
	local bonespergib = math.Round( ( self.Owner:GetHitBoxCount( 0 ) ) / gibs )
	local currentgib = nil

	local bonecount = 0

	for i = 0 , bones do
		bonecount = bonecount + 1
		
		if not currentgib then
			currentgib = EffectData()
			currentgib:SetEntity( self.Owner )
			currentgib:SetAngles( self.Direction )
			currentgib:SetScale( self.Speed )
			currentgib:SetDamageType( 0 )
			
		end
		
		currentgib:SetDamageType( bit.bor( currentgib:GetDamageType() , 2 ^ i ) )
		
		if bonecount >= bonespergib or ( i == bones and currentgib ) then
			util.Effect( "sm_player_gib" , currentgib )
			currentgib = nil
			bonecount = 0
		end
		
		--we reached the gib count, don't spawn anymore
		if GAMEMODE.ConVars["MaxGibs"]:GetFloat() ~= 0 and GAMEMODE:GetGibCount() >= GAMEMODE.ConVars["MaxGibs"]:GetFloat() then
			break
		end
		
	end
end

function EFFECT:Think()
	return false
end