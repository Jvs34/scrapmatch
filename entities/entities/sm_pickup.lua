AddCSLuaFile()

ENT.Type 			= "anim"
ENT.Base 			= "base_entity"

ENT.PickupType = {
	NONE 				= 0,
	
	SPECIAL_ACTION 		= 1,
	
	SMALL_REPAIR_KIT 	= 2,
	MEDIUM_REPAIR_KIT 	= 3,
	BIG_REPAIR_KIT 		= 4,
	
	SMALL_AMMO_KIT 		= 5,
	MEDIUM_AMMO_KIT 	= 6,
	BIG_AMMO_KIT		= 7,
	
	SMALL_BATTERY = 8,
	MEDIUM_BATTERY = 9,
	BIG_BATTERY = 10,
	
	LAST = 10,
}

--contains the default values for a certain pickup, usually respawn time, percentage replenished ( ammo or health ) and the effect to dispatch when applied
ENT.PickupValues = {
	[ENT.PickupType.SPECIAL_ACTION] 		= {
		Respawn = 30,
	--	Effect = nil,
	--	Sound = "Player.PickupWeapon",
		SoundOnPlayer = true,
	},
	
	[ENT.PickupType.SMALL_REPAIR_KIT] 		= {
		Respawn = 15,
		Percent = 0.25,
	--	MultiModel = nil,
		Effect = "sm_pickup_effect_repair",
		Sound = "npc_dog.servo_5",
	},
	[ENT.PickupType.MEDIUM_REPAIR_KIT] 	= {
		Respawn = 45,
		Percent = 0.50,
	--	MultiModel = nil,
		Effect = "sm_pickup_effect_repair",
		Sound = "npc_dog.servo_2",
	},
	[ENT.PickupType.BIG_REPAIR_KIT] 		= {
		Respawn = 60,
		Percent = 1.00,
	--	MultiModel = nil,
		Effect = "sm_pickup_effect_repair",
		Sound = "npc_dog.servo_1",
	},
	
	[ENT.PickupType.SMALL_AMMO_KIT] 		= {
		Respawn = 5,
		Percent = 0.25,
	--	MultiModel = nil,
		Effect = "sm_pickup_effect_ammo",
	},
	[ENT.PickupType.MEDIUM_AMMO_KIT] 		= {
		Respawn = 10,
		Percent = 0.50,
	--	MultiModel = nil,
		Effect = "sm_pickup_effect_ammo",
	},
	[ENT.PickupType.BIG_AMMO_KIT] 			= {
		Respawn = 20,
		Percent = 1.00,
	--	MultiModel = nil,
		Effect = "sm_pickup_effect_ammo",
	},
	
	[ENT.PickupType.SMALL_BATTERY] 		= {
		Respawn = 10,
		Percent = 0.25,
	--	MultiModel = nil,
		Effect = "sm_pickup_effect_battery",
	},
	[ENT.PickupType.MEDIUM_BATTERY] 		= {
		Respawn = 20,
		Percent = 0.50,
	--	MultiModel = nil,
		Effect = "sm_pickup_effect_battery",
	},
	[ENT.PickupType.BIG_BATTERY] 			= {
		Respawn = 30,
		Percent = 1.00,
	--	MultiModel = nil,
		Effect = "sm_pickup_effect_battery",
	},
}

function ENT:Initialize()
	if SERVER then
		--standard player bounds for testing
		self:SetMinBounds( Vector( 16 , 16 , 0 ) )
		self:SetMaxBounds( Vector( -16 , -16 , 64 ) )
		
		self:SetCollisionBounds( self:GetMinBounds() , self:GetMaxBounds() )
		self:SetMoveType( MOVETYPE_NONE )
		self:SetSolid( SOLID_BBOX )
		self:SetCollisionGroup( COLLISION_GROUP_WORLD )
		self:SetTrigger( true )
		self:SetNextRespawn( -1 )
	else
	
		self:SetRenderBounds( self:GetMinBounds() , self:GetMaxBounds() )
		self.OldAction			= -1
		self.SpecialAction		= nil
		self.CurrentRotation = Angle( 0 , 0 , 0 )
		self.CurrentOffset	= Vector( 0 , 0 , 0 )	--unused , self:SetRenderOrigin fucks up with self:GetPos() I think
		self.MultiModel			= nil
	end

end

function ENT:SetupDataTables()
	self:NetworkVar( "Vector" , 0 , "MinBounds" )
	self:NetworkVar( "Vector" , 1 , "MaxBounds" )
	
	self:NetworkVar( "Float" , 0 , "RespawnTime" )	--the respawn time in seconds
	self:NetworkVar( "Float" , 1 , "NextRespawn" )	--the tracked time until we respawn
	--self:NetworkVar( "Float", 2 , "CurrentRotation" )	--the current rotation of this pickup, *180 to 180 obviously
	
	self:NetworkVar( "Int", 0 , "Action" )			--the special action to give and show on the pickup itself
	self:NetworkVar( "Int"	, 1 , "PickupType" )	--if Action is higher than 1 at least, this will be the pickup type, from 2 to 4 it's medkit, from 5 to 7 it's ammo
																--1 means special action.
end

function ENT:Think()
	if SERVER then
		
		self:CheckRespawn()
		
	else
		
		--moved to Think as it makes more sense, rotate around depending on the user's frame rate
		self.CurrentRotation.y = math.ApproachAngle( self.CurrentRotation.y , self.CurrentRotation.y + 90, 20 * FrameTime() )
		self.CurrentRotation.y = math.NormalizeAngle( self.CurrentRotation.y )	--normalize the angle so we don't get huge values and also to snap it perfectly
		
		--we check for changes to our special action, in case the map set it to another one and we have to update accordingly
		if self:GetAction() ~= 0 and self:GetAction() ~= self.OldAction then
			local sa = SA:GetSAById( self:GetAction() )
			
			if sa ~= self.SpecialAction then
				self.SpecialAction = sa
			end
			
			self.OldAction = self:GetAction()
		end
		
	end
end

if SERVER then

	function ENT:CheckRespawn( force )
		
		if ( self:GetNextRespawn() <= CurTime() and self:GetNextRespawn() ~= -1 ) or force then

			self:EmitSound( "Item.Materialize" )			--we have respawned, also emit some fancy effects
			
			local effect = EffectData()
			effect:SetEntity( self )							--this may or may not be available yet on the client before we refresh the network data
			effect:SetOrigin( self:GetPos() )
			util.Effect( "sm_pickup_effect_respawn" , effect )
			
			self:SetNextRespawn( -1 )
			--to actually make the engine call UpdateTransmitState we need to add this flag
			self:AddEFlags( EFL_FORCE_CHECK_TRANSMIT )
		end
		
	end
	
	--UGHHHH duplicated coooode I'll fix this someday I swear
	
	function ENT:KeyValue( key, value )
		
		if key == "SpecialAction" then
			self:SetSpecialAction( value )
		end
		
		if key == "OverrideRespawnTime" then
			local respawntime = tonumber( value )
			if respawntime then
				self:SetRespawnTime( respawntime )
			end
		end
		
		if key == "PickupType" then
			local ptype = tonumber( value or "0" )
			
			if ptype <= self.PickupType.NONE or ptype > self.PickupType.LAST then
				ErrorNoHalt( "Map tried to set the PickupType to an invalid one!" )
				return
			end
			
			if ptype == self.PickupType.SPECIAL_ACTION then
				ErrorNoHalt( "Map tried to set a special action via PickupType! Use SetSpecialAction instead" )
				return
			end
			
			self:SetPickupType( ptype )
		end
		
	end
	
	function ENT:AcceptInput( inputName, activator, called, data )
	
		if inputName == "SetRespawnTime" then
			local respawntime = tonumber( data )
			if respawntime then
				self:SetRespawnTime( respawntime )
				return true
			end
			return false
		end
		
		if inputName == "SetSpecialAction" then
			self:SetSpecialAction( data )
			return true
		end
		
		if inputName == "SetPickupType" then
			local ptype = tonumber( data ) or 0
			
			if ptype <= self.PickupType.NONE or ptype > self.PickupType.LAST then
				ErrorNoHalt( "Map tried to set the PickupType to an invalid one!" )
				return false
			end
			
			if ptype == self.PickupType.SPECIAL_ACTION then
				ErrorNoHalt( "Map tried to set a special action via SetPickupType! Use SetSpecialAction instead" )
				return false
			end
			
			self:SetPickupType( ptype )
			return true
		end
		
		if inputName == "ForceRespawn" then
			self:CheckRespawn( true )
			return true
		end
		
	end
	
	function ENT:SetSpecialAction( action_id , respawntime )
	
		if not action_id then
			ErrorNoHalt( "Tried to set an invalid action!" )
			return
		end
		
		--it's obviously easier on the mapping side to set a string instead of an ID
		if type( action_id ) == "string" then
			action_id = SA:GetIdByClass( action_id )
		end
		
		if action_id == SA.DEFAULT then 
			ErrorNoHalt( "Tried to set default special action to sm_pickup!" )
			return 
		end
		
		self:SetAction( action_id )
		if respawntime then
			self:SetRespawnTime( respawntime )
		end
		
		self:SetPickupType( self.PickupType.SPECIAL_ACTION )
		
	end
	
	function ENT:Touch( ent )
		if self:GetNextRespawn() > CurTime() then return end
		
		if not IsValid( ent ) or not ent:IsPlayer() then return end
		
		if not ent:Alive() then return end
		
		local ret = nil
		
		if self:GetPickupType() == self.PickupType.SPECIAL_ACTION then
			ret = self:GiveItemTo( ent )
		elseif self:GetPickupType() ~= self.PickupType.NONE then
			ret = self:GiveConsumableTo( ent )
		else
			ErrorNoHalt( "sm_pickup:Touch called with no defined pickuptype!" )
			ret = false
		end
		
		if ret then
			local nextrespawn = 0
			
			local sound = self.PickupValues[self:GetPickupType()] and self.PickupValues[self:GetPickupType()].Sound or nil
			--if the nextrespawn wasn't set, then check our default PickupValues table for that
			
			
			--try to get the respawn time from the default ones
			if self.PickupValues[self:GetPickupType()] then
				nextrespawn = self.PickupValues[self:GetPickupType()].Respawn
			end
			
			if type( ret ) == "Entity" and IsValid( ret ) then
				--if we actually got returned an entity from self:GiveItemTo( ent ) try to get the respawn time
				if ret:GetCurSA():GetRespawnTime() ~= 0 then
					nextrespawn = ret:GetCurSA():GetRespawnTime()
				end
			end
			
			--fuck all the above, looks like something wants to respawn this entity with another time
			
			if self:GetRespawnTime() ~= 0 then
				nextrespawn = self:GetRespawnTime()
			end
			
			--if this happens it means that self.PickupValues doesn't have the respawn time for that item, is this a new item or an invalid one?
			
			if nextrespawn == 0 then
				nextrespawn = 3
			end
			
			if sound then
				if self.PickupValues[self:GetPickupType()].SoundOnPlayer then
					ent:PlaySound( "ITEMPICKUP" )
				else
					self:EmitSound( sound )
				end
			end
			
			self:SetNextRespawn( CurTime() + nextrespawn )
			--to actually make the engine call UpdateTransmitState we need to add this flag
			self:AddEFlags( EFL_FORCE_CHECK_TRANSMIT )
		end

		
	end
	
	--give special action to player
	function ENT:GiveItemTo( ply )
	
		return ply:GiveSpecialAction( self:GetAction() )
		
	end
	
	function ENT:GiveConsumableTo( ply )
		
		--Dispatch an effect from the table when we pickup this
		local ptype = self:GetPickupType()
		
		if not self.PickupValues[ptype] then return false end
		
		local effectstr = self.PickupValues[ptype].Effect
		
		local ret = false
		
		if ptype >= self.PickupType.SMALL_REPAIR_KIT and ptype <= self.PickupType.BIG_REPAIR_KIT then
			--heal the player, and fix his special actions
			ret = ply:HandleHealthPickup( self.PickupValues[ptype].Percent )
		elseif ptype >= self.PickupType.SMALL_BATTERY and ptype <= self.PickupType.BIG_BATTERY then
			--apply the battery
			ret = ply:HandleBatteryPickup( self.PickupValues[ptype].Percent )
		elseif ptype >= self.PickupType.SMALL_AMMO_KIT and ptype <= self.PickupType.BIG_AMMO_KIT then
			--give the player ammo to all his special actions
			ret = ply:HandleAmmoPickup( self.PickupValues[ptype].Percent )
		end
		
		--the handlers returned false, means we can't pick this up or they failed to
		
		if not ret then return false end
		
		if effectstr then
			local effect = EffectData()
			effect:SetOrigin( self:GetPos() )
			effect:SetScale( self.PickupValues[ptype].Percent )
			util.Effect( effectstr , effect )
		end
		
		return true
	end
	
	--don't transmit to the client at all if we've not respawned yet, bit of a cheeky optimisation,
	--still better than setting EF_NODRAW on anything the player can't see
	
	function ENT:UpdateTransmitState()
		if self:GetNextRespawn() > CurTime() then
			return TRANSMIT_NEVER
		end
		
		return TRANSMIT_PVS
	end

else

	function ENT:Draw()
		--draw our particle effects
		
		self:SetRenderAngles( self.CurrentRotation )
		self:DrawModel()
		
		--call the special action's DrawPickup function here
		if self:GetPickupType() == self.PickupType.SPECIAL_ACTION then
			self:DrawSpecialAction()
		elseif self:GetPickupType() ~= self.PickupType.NONE then
			self:DrawPickup()
		end
		
	end
	
	--let the special action handle that
	function ENT:DrawSpecialAction()
		if self.SpecialAction then
			self.SpecialAction:SetEntity( self )
			self.SpecialAction:DrawPickup( self )
		end
	end
	
	function ENT:DrawPickup()
		
	end
	
end