
local meta = FindMetaTable( "Player" )

if not meta then return end


function meta:SetupDataTables()
	self:NetworkVar( "Entity"	, 0 , "SpecialActionController" )	--our special action controller
	
	self:NetworkVar( "Int"		, 0 , "MaxArmorBattery" )	--the max battery we can hold
	self:NetworkVar( "Int"		, 1 , "ExtraButtons" )	--even though this is an int it can only hold 8 buttons, what a shame , more than enough
	self:NetworkVar( "Int"		, 2 , "HUDBits" )			--the hud bits to show, this is predicted in some cases, like for the scoreboard
	self:NetworkVar( "Int"		, 3 , "Status" )			--weapons disrupted, slowed, etc etc
	
	self:NetworkVar( "Bool"		, 0 , "PlayedLeftFootstep" )			--played the left footstep, used in the move hook
	self:NetworkVar( "Bool"		, 1 , "PlayedRightFootstep" )		--played the right footstep, used in the move hook
	self:NetworkVar( "Bool"		, 2 , "HasVoted" )				--this player has already voted and won't be able to cast more votes
	
	self:NetworkVar( "Float"	, 0 , "NextJoinTeam" )				--we won't be able to change team until this expires
	self:NetworkVar( "Float" , 1 , "NextRespawn" )				--we won't be able to respawn until this expires
	self:NetworkVar( "Float"	, 2 , "LastDamageTaken" )		--this is the last time we took damage
	self:NetworkVar( "Float" , 3 , "NextBatteryRecharge" )	--we won't be able to recharge the battery until this expires
	self:NetworkVar( "Float" , 4 , "BatteryRechargeTime" )	--the time in seconds for the battery to fully recharge from 0 to 100
	self:NetworkVar( "Float" , 5 , "ArmorBattery" )				--our current armor battery
	
end

if SERVER then

	--creates a special action from the given string / id , returns the special action entity afterwards
	function meta:GiveSpecialAction( action_id )

		if type( action_id ) == "string" then
			action_id = SA:GetIdByClass( action_id )
		end
		
		local sa = SA:GetSAById( action_id )
		local slot = sa:GetSlot()
		
		
		local controller = SA:GetController( self )
			
		if not IsValid( controller ) then return end
		
		return controller:CreateSpecialaction( action_id , slot )
	end
	
	--applies a repair pickup to the player , returns true or false whether it could be applied
	function meta:HandleHealthPickup( percent )
		local curhealth = self:Health()
		local maxhealth = self:GetMaxHealth()

		if curhealth >= maxhealth then return false end
		
		self:SetHealth( math.Clamp( curhealth + maxhealth * percent , 1 , maxhealth ) )
		
		local controller = SA:GetController( self )
		
		if IsValid( controller ) then
			controller:DoSpecialAction( "HandleHealthPickup" , percent )
		end
		
		return true
	end
	
	function meta:HandleBatteryPickup( percent )
		local curbattery = self:GetArmorBattery()
		local maxbattery = self:GetMaxArmorBattery()
		
		if curbattery >= maxbattery then return false end
		
		--prevent the user from regenerating armor after getting this applied
		
		self:SetArmorBattery( math.Clamp( curbattery + maxbattery * percent , 1 , maxbattery ) )
		self:SetNextBatteryRecharge( CurTime() + 5 )
		return true
	end
	
	function meta:HandleAmmoPickup( percent )
		local controller = SA:GetController( self )
		
		if IsValid( controller ) then
			v:DoSpecialAction( "HandleAmmoPickup" , percent )
		end
		
		return true	--always return true for now, we're gonna need a way to return values from a special action later on
	end
	
end

--allow the weapon to have a way to stop weapon actions from running

function meta:CanRunAction( actionent , actionstring )
	local weapon = self:GetActiveWeapon()
	
	if IsValid( weapon ) and actionent:GetCurSA():IsWeaponAction() and weapon.CanRunAction then
		return weapon:CanRunAction( actionent , actionstring )
	end
	
	return true
end

function meta:HUDAddBits( bits )
	if bit.band( self:GetHUDBits() , bits ) == 0 then
		self:SetHUDBits( bit.bor( self:GetHUDBits() , bits ))
	end
end 

function meta:HUDRemoveBits( bits )
	if bit.band( self:GetHUDBits() , bits ) ~= 0 then
		self:SetHUDBits( bit.bxor( self:GetHUDBits() , bits ))
	end
end 

function meta:HUDResetBits()
	self:SetHUDBits( GAMEMODE.HUDBits.HUD_ALLBITS )
end

--unused but might be useful later on
function meta:GetTeamEnt()
	return GAMEMODE:GetTeamEnt( self:Team() )
end

function meta:HandleFootsteps()
	if not self:Alive() then return end
	if self:GetObserverMode() ~ OBS_MODE_NONE then return end
	
	self:SetupBones()
	
	local leftfootbonename = ""	--whatever
	local rightfootbonename	= ""	--
	
	local leftfootbone = self:LookupBone( leftfootbonename )
	local rightfootbone = self:LookupBone( rightfootbonename )
	
	local leftfoottrace = nil
	local rightfoottrace = nil
	
	local leftfoottraceresult = nil
	local rightfoottraceresult = nil
	
	
	local leftfootbonematrix = self:GetBoneMatrix( leftfootbone )
	local rightfootbonematrix = self:GetBoneMatrix( rightfootbone )
	
	if not leftfootbonematrix or not rightfootbonematrix then return end
	
	leftfoottrace = {
		startpos = leftfootbonematrix:GetTranslation(),
		endpos = leftfootbonematrix:GetTranslation() - Vector( 0 , 0 , 5 ),
		filter = self,
	}
	
	rightfoottrace = {
		startpos = rightfootbonematrix:GetTranslation(),
		endpos = rightfootbonematrix:GetTranslation() - Vector( 0 , 0 , 5 ),
		filter = self,
	}
	
	leftfoottraceresult = util.TraceLine( leftfoottrace )
	rightfoottraceresult = util.TraceLine( rightfoottrace )
	
	if leftfoottraceresult.Hit then
		if not self:GetPlayedLeftFootstep() then
			self:PlaySound( "LEFTFOOT" )
			self:SetPlayedLeftFootstep( true )
		end
	else
		self:SetPlayedLeftFootstep( false )
	end
	
	if rightfoottraceresult.Hit then
		if not self:GetPlayedRightFootstep() then
			self:PlaySound( "RIGHTFOOT" )
			self:SetPlayedRightFootstep( true )
		end
	else
		self:SetPlayedRightFootstep( false )
	end
end

meta.SoundInfos = {
	SPAWN = {
		SoundName = "citadel.br_youneedme",
		SoundChannel = CHAN_BODY,
	}
	PAIN = {
		SoundName = "citadel.br_ohshit",	--replace this with a generic metal noise sound
		SoundChannel = CHAN_VOICE,
	},
	DEATH = {
		SoundName = "citadel.br_youneedme",	--replace this with one of the scanner's death sounds
		SoundChannel = CHAN_VOICE,
	},
	ITEMPICKUP = {
		SoundName = "citadel.br_no",				--replace this with a generic ammo pickup sound
		SoundChannel = CHAN_ITEM,
	},
	LEFTFOOT = {
		SoundName = "NPC_CombineS.RunFootstepLeft",			--fine for now
		SoundChannel = CHAN_BODY,
	}
	RIGHTFOOT = {
		SoundName = "NPC_CombineS.RunFootstepRight",		--fine for now
		SoundChannel = CHAN_BODY,
	}
	FALLDAMAGE = {
		SoundName = "Player.FallDamage",		--fine for now
		SoundChannel = CHAN_BODY,
	}
}

function meta:PlaySound( soundtype )
	local tb = self.SoundInfos[soundtype]
	--everything but the sound name is optional
	if tb and tb.SoundName then
		self:EmitSound( tb.SoundName , tb.SoundLevel , tb.SoundPitch , tb.SoundVolume , tb.SoundChannel )
	end
end

function meta:CreateGibs( dmginfo )
	--we don't really need to send the sequence / cycle to the client when dispatching the gib effect
	--the client can just call SetupBones once on that entity and then do everything on those bones
	
	--this shatter percentage will be sent clientside and will be used when creating the gibs, a higher one means that
	--the body parts will be shattered more ( for instance, 1 means that we're going to create a gib for each physics bone the player has )
	--( while 0 means that there's going to be like 5 gibs , 4 for each limb and 1 for the torso + head )
	local shatterperc = dmginfo:GetDamage() / self:GetMaxHealth()
	
	local effect = EffectData()
	effect:SetEntity( self )
	effect:SetScale( shatterperc )
	util.Effect( "sm_player_gib_main" , effect )
	--sm_player_gib_main
		--call setupbones on the player
		--check the percentage of shattering , get the max number of physical bones that player model has ( example, 15 )
		--depending on the percentage, ( 15 * 0.5 ) , each gib will contain N bones ( 8 in this case )
		--check the convar if we can create that gib
		--loop trough all the bones , collect them into a bitflag container and feed it to the gib and relay the entity
			--sm_player_gib
				--get the bones we're going to get the mesh of from the bitflag
				--add all the meshes into a table, then use the physicsinitmulticonvexes or whatever the fuck it's called to initialize our physics
				--set our collision group depending on the cvar
				--increase our render bounds depending on our actual mesh size
				--set our despawn rate depending on the cvar
				--
		
	ErrorNoHalt( "IMPLEMENT GIBS!!" )
end