
local meta = FindMetaTable( "Entity" )

if not meta then return end

if SERVER then
	util.AddNetworkString("sm_predicted_sound")
end

--what this whole thing does is to simulate the recipient filter prediction, which excludes serverside the currently predicting player
--I have to do this because it's the cleanest way to do it, and since EmitSound checks for an hardcoded variable in the entity itself to apply the prediction filter
--I created a Lua recipient filter, so this is all nice and dandy in the end

if CLIENT then
	net.Receive("sm_predicted_sound", function( len )
		local ent = net.ReadEntity()
		if not IsValid( ent ) then return end
		local soundstring = net.ReadString()
		local level = net.ReadInt( 16 )
		local pitch = net.ReadInt( 16 )
		local volume = net.ReadInt( 16 )
		local channel = net.ReadInt( 16 )
		
		if level == -1 then
			level = nil
		end
		
		if pitch == -1 then
			pitch = nil
		end
		
		if volume == -1 then
			volume = nil
		end
		
		if channel == -1 then
			channel = nil
		end
		
		ent:EmitSound( soundstring , level , pitch , volume , channel )
	end)
	
	function meta:EmitPredictedSound( ... )
		if IsFirstTimePredicted() then
			self:EmitSound( ... )
		end
	end
else
	function meta:EmitPredictedSound( soundstring , level , pitch , volume , channel )
		local owner = self:GetOwner()
		
		if self:IsPlayer() then
			owner = self
		end
		
		if not IsValid( owner ) or not owner:IsPlayer() then
			self:EmitSound( soundstring , level , pitch , volume , channel )
			return
		end
		
		local filter = LuaRecipientFilter( owner )
		filter:AddAllPlayers()
		
		net.Start("sm_predicted_sound")
			net.WriteEntity( self )
			net.WriteString( soundstring )
			net.WriteInt( level or -1 , 16 )
			net.WriteInt( pitch or -1 , 16 )
			net.WriteInt( volume or -1 , 16 )
			net.WriteInt( channel or -1 , 16 )
		net.Send( filter() )
	end
	
end