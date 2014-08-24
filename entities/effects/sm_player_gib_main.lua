AddCSLuaFile()


--[[
	this is a glorified net message , we're going to call setupbones on the player ,
	get the shatter percentage and then spawn as many sm_player_gibs as computed
	and associate them to a
]]

function EFFECT:Init( data )
	local owner = data:GetEntity()
	
	--the player might not be valid or simply outside of our PVS, early out
	if not IsValid( owner ) then return end
	
	local shatterperc = math.Clamp( data:GetScale() , 0 , 1 )	--clamp the percentage because stuff might do overkill damage

	
	owner:SetupBones()
	
	
	
	local physbonecount = 0
	
	for i = 0 , owner:GetBoneCount() - 1 do
		local physbone = owner:TranslateBoneToPhysBone( i )
		if physbone ~= -1 then
			physbonecount = physbonecount + 1
		end
	end
	
	--we should create these many gibs
	
	local bonespergib = math.floor( physbonecount * shatterperc )
	
	local currentgib = nil
	
	local bonecount = 0
	
	local gibcount = 0
	
	for i = 0 , owner:GetBoneCount() - 1 do
		
		local bm = owner:GetBoneMatrix( i )
	
		--this bone is valid
		if bm then
		
			local physbone = owner:TranslateBoneToPhysBone( i )
			
			--this bone doesn't have a physics bone associated to it, don't care
			
			if physbone == -1 then continue end

			if not currentgib then
				currentgib = EffectData()
				currentgib:SetAttachment( 0 )
				currentgib:SetEntity( owner )
				bonecount = 0
			end
			
			currentgib:SetAttachment( bit.bor( currentgib:GetAttachment() , 2 ^ physbone ) )
			
			bonecount = bonecount + 1
			
			if bonecount >= bonespergib then
				
				util.Effect( "sm_player_gib" , currentgib )
				MsgN("CREATED GIB")
				
				currentgib = nil
			end
			
		end
	
	end
	
end

--don't care about this, just remove the entity right away
function EFFECT:Think()
	return false
end

function EFFECT:Render()
end