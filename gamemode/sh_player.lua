if SERVER then

	util.AddNetworkString("sm_damageinfo")

	function GM:PlayerInitialSpawn( ply )
		ply:InstallDataTable()
		ply:SetupDataTables()

		--initialize the one time variables here
		ply:SetHasVoted( false )
		ply:SetNextJoinTeam( CurTime() )
		ply:SetNextRespawn( CurTime() )
		if ply:IsBot() then
			self:JoinTeam( ply , team.BestAutoJoinTeam() , false )
		else
			self:JoinTeam( ply , self.TEAM_SPECTATORS , false )
		end
	end

	function GM:PlayerSpawn( ply )
		local teament = 	self:GetTeamEnt( ply:Team() )
		local gamerules = self:GetGameRules()

		if IsValid( teament ) then
			local col = teament:GetTeamColor()
			--wasn't there a Color:ToVector or some shit?
			ply:SetPlayerColor( Vector( col.r / 255 ,col.g / 255 , col.b / 255 ) )
		end
		
		ply:HUDResetBits()
		ply:SetNextJoinTeam( CurTime() + 2 )
		ply:SetLastDamageTaken( CurTime() )
		ply:RemoveSuit()								--we don't need the HEV suit, this will disable HL2 hud and zoom
																--we still have to disable some HUD elements ourselves , like the damage taken one
		ply:SetArmorBattery( 0 )					--let the gamerules decide how much battery to spawn him with?
		ply:SetMaxArmorBattery( 100 )
		ply:SetBatteryRechargeTime( 10 )
		ply:SetNextBatteryRecharge( CurTime() + engine.TickInterval() )
		ply:SetPlayedLeftFootstep( false )
		ply:SetPlayedRightFootstep( false )
		ply:SetModel("models/player/breen.mdl")		--base model
		ply:SetBloodColor( DONT_BLEED )
		ply:StripAmmo()
		ply:StripWeapons()

		SA:RemoveController( ply )

		if ply:Team() ~= self.TEAM_SPECTATORS then
			SA:CreateController( ply )
			local wep = ply:Give("sm_weapon")
			if IsValid( wep ) then
				ply:GiveSpecialAction( "sa_circularsaw" )
				ply:GiveSpecialAction( "sa_chaingun" )
			end
			ply:PlaySound( "SPAWN" )
		else
			ply:HUDRemoveBits( bit.bor( GAMEMODE.HUDBits.HUD_HEALTH ,GAMEMODE.HUDBits.HUD_ARMOR , GAMEMODE.HUDBits.HUD_AMMO , GAMEMODE.HUDBits.HUD_CROSSHAIR ) )
		end

		if IsValid( gamerules ) then
			ply:SetWalkSpeed( gamerules:GetMovementSpeed() )
			ply:SetRunSpeed( gamerules:GetMovementSpeed() )	--just in case
			ply:SetNextRespawn( CurTime() + gamerules:GetRespawnTime() )
		end

		--TEMPORARY , later on we'll make the player control cameras
		if IsValid(teament) and teament:GetTeamID() == self.TEAM_SPECTATORS then
			ply:Spectate( OBS_MODE_ROAMING )
			--TODO:Replace this with self:PlayerSpectateCameras( ply )
		else
			ply:UnSpectate()
		end
		
		local spawnpoint = team.GetSpawnPoint( ply:Team() )
		if IsValid( spawnpoint ) then
			ply:SetPos( spawnpoint:GetPos() )
			ply:SetEyeAngles( spawnpoint:GetAngles() )
		end
	end
	
	--we don't care about the default source engine behaviour , make the player respawn at its own position, we'll do the rest in PlayerSpawn
	
	function GM:PlayerSelectSpawn( ply )
		return ply
	end
	
	function GM:PlayerSpectateCameras( ply )
		if ply:GetObserverMode() ~= OBS_MODE_NONE then return end
		--find the first camera
		ply:Spectate( OBS_MODE_IN_EYE )
		
		local foundcamera = self:GetCameraInSequence( ply )
		
		if IsValid( foundcamera ) then
			ply:SpectateEntity( foundcamera )
		end
		
	end
	
	function GM:PlayerTakeDamage( ply , dmginfo )
		local attacker = dmginfo:GetAttacker()

		local damageallowed = true	--we always take damage from ourselves

		-- and from other players , if they're on my own team then ask if that friendly fire can pass on

		if IsValid( attacker ) and attacker:IsPlayer() and attacker ~= ply then
			if attacker:Team() == ply:Team() then
				local teament = self:GetTeamEnt( ply:Team() )
				if IsValid( teament ) then
					damageallowed = teament:GetTeamFriendlyFire()
				end
			end

			--only track the last attacker if the damage was allowed through, it being a friendly fire shot or an enemy one
			if damageallowed then
				ply.LastAttacker = attacker
			end
		end


		local dmgtype = dmginfo:GetDamageType()

		--battery damage reduction, also send a message to the client about the damage taken, player_hurt does that in a shitty way
		if damageallowed and self.DamageTypes[dmgtype] then

			local armorefficiency = self.DamageTypes[dmgtype].ArmorEfficiency	--hopefully this is a single damage type
			local currentbattery = ply:GetArmorBattery()

			local initialdamage = dmginfo:GetDamage()

			local damage = dmginfo:GetDamage()
			
			local damagedrained = damage * ( 1 - armorefficiency )		--damage to apply to health normally
			local batterydrained = damage * armorefficiency					--damage to apply to armor normally

			damage = damagedrained
			currentbattery = currentbattery - batterydrained
			
			--the armor couldn't absorb all of it , make it leak onto health damage now
			if currentbattery < 0 then
				damage = damage + math.abs( currentbattery )
				currentbattery = 0
			end
			
			--clamp negative damage or damage that is never supposed to damage health, such as shock drain
			
			if damage <= 0 or self.DamageTypes[dmgtype].NoDamageToHealth then
				damage = 0
			end
			
			dmginfo:SetDamage( damage )
			dmginfo:SetDamageType( self.DamageTypes[dmgtype].Flags )
			ply:SetArmorBattery( currentbattery )
			
			--we don't need to actually send a message to the attacker for hit sounds, we're gonna handle that with player_hurt
			--go trough all the players that are spectating this player and send this message
			local filter = LuaRecipientFilter()
			filter:AddPlayersByCallback( 
				function( self , v )
					if ply == v then return false end
					
					if v:GetObserverTarget() == ply then
						return true
					end
				end
			)
			filter:AddPlayer( ply )
			
			--this is pretty much a better version of player_hurt, we're going to send it only to this player and to players spectating him
			--this is used for the damage location hud , mostly to look like the one in tf2
			
			net.Start( "sm_damageinfo" )
				net.WriteBit( attacker == ply )
				net.WriteFloat( damage )
				net.WriteUInt( dmgtype , 32 )	--we send the pre converted damage type because it's easier to index on the client, plus we don't care about the other ones
				net.WriteVector( dmginfo:GetDamagePosition() )	--send the damage position so the client knows where it was attacked from and can show the damage marker
			net.Send( filter() )
			
			ply:PlaySound( "PAIN" )
		end

		--returning true here avoids the player from actually taking the damage
		return damageallowed == false
	end

	function GM:DoPlayerDeath( ply, attacker, dmginfo )
		local rules = self:GetGameRules()

		ply:HUDRemoveBits( bit.bor( GAMEMODE.HUDBits.HUD_HEALTH ,GAMEMODE.HUDBits.HUD_ARMOR , GAMEMODE.HUDBits.HUD_AMMO , GAMEMODE.HUDBits.HUD_CROSSHAIR ) )

		
		ply:StripAmmo()
		ply:StripWeapons()
		SA:RemoveController( ply )

		if ply:Team() ~= self.TEAM_SPECTATORS then
			if bit.band( dmginfo:GetDamageType() , DMG_ALWAYSGIB ) ~= 0 then
				ply:CreateGibs( dmginfo )	--create the gibs and supply it with the damage info, so the gibs can behave differently depending on the damage
			else
				ply:CreateRagdoll()				--we might override this at some point but it's ok for now
			end
			ply:AddDeaths( 1 )
		end

		ply:SetNextRespawn( CurTime() + rules:GetRespawnTime() )
	

		if not IsValid( attacker ) and IsValid( ply.LastAttacker ) then
			--check if someone hit us a few seconds before dying
			attacker = ply.LastAttacker
		end

		if IsValid( attacker ) and attacker:IsPlayer() then
			self:AddScore( attacker , ( attacker == ply ) and -1 or 1 )
		end

		--handle the Kill reasons here
		ply:PlaySound( "DEATH" )
		ply.LastAttacker = attacker
		
		local announcer = self:GetAnnouncer()
		
		if IsValid( announcer ) and IsValid( ply.LastAttacker ) and ply.LastAttacker:IsPlayer() then
			announcer:OnPlayerKill( ply.LastAttacker , ply , dmginfo )
		end
		
	end
	
	function GM:OnPlayerDisconnected( ply )
		local announcer = self:GetAnnouncer()
		
		if not ply:Alive() then
			local nextresp = ply:GetNextRespawn() - CurTime()
			if nextresp < 3 then
				if ply.LastAttacker == ply then return end
				if IsValid( announcer ) then
					announcer:OnPlayerRagequit( ply , ply.LastAttacker )
				end
			end
		end
	end
	
	--override it to remove the default killicons bullshit, AFAIK this is called from some bullshit game rules internal hook
	function GM:PlayerDeath( ply, inflictor, attacker ) end

	function GM:PlayerDeathThink( ply )
		if self:CanPlayerRespawn( ply ) then
			ply:Spawn()
		else
			--TODO: 1 second after death, put the player on the camera system
			--[[
				if ( ply:GetNextRespawn() - CurTime() ) > 1 then
					self:PlayerSpectateCameras( ply )
				end
			]]
			--self:PlayerSpectateCameras( ply )
		end
	end

	--fuck off ear ringing
	function GM:OnDamagedByExplosion( ply , dmginfo ) end

	--we don't even handle the death sounds here
	function GM:PlayerDeathSound( ply )
		return true
	end

	--we can't start votes if we just joined the server!
	function GM:CanStartVote( ply , voteentity )
		return ply:TimeConnected() >= self:GetVoteController():GetVoteDuration()
	end
	
	-- I already cast my vote or I connected too late to be able to vote
	
	function GM:CanCastVote( ply , voteentity )
		if ply:GetHasVoted() then return false end
		
		return ply:TimeConnected() >= self:GetVoteController():GetVoteDuration()
	end
	
	--TODO: can't suicide if we're using the Plan B
	
	function GM:CanPlayerSuicide( ply )
		if ply:HasStatus( self.PlayerStatus.PLANB ) then
			return false
		end
		return ply:Team() ~= self.TEAM_SPECTATORS
	end
	
else

	function GM:PrePlayerDraw( ply )
		--TODO: render the player's multimodel here instead, then force the drawing of his weapon a
	end

	function GM:PostPlayerDraw( ply )
	
	end
	
end

function GM:StartCommand( ply , cmd )
	
	--if we're spectating and the camera we're looking through is not active or we're not the controlling player, lock our eye angles on the usercmd to the aim vector of the camera
	
	local camera = ply:GetObserverTarget()
	if IsValid( camera ) and camera:GetClass() == "sm_camera" then
		if not camera:GetActive() or camera:GetControllingPlayer() ~= ply then
			cmd:SetViewAngles( camera:GetAimVector():Angle() )
			ply:SetFOV( camera:GetZoomFOV() , 0 )
		end
	end
	
	if not IsValid( camera ) then
		ply:SetFOV( 0 , 0 )
	end
	
	--[[
		cmd's impulse is actually used for the flashlight and noclip inputs, and a few others, but we don't care about neither
		we're going to use this as another means of networking input bits to the server, one that is actually reliable
		since impulse is an unsigned byte, it can only contain up to 8 bits, 0 to 255
	]]

	if CLIENT then

		--TODO: convert stuff like the flashlight impulse or the IN_USE one 
		cmd:SetImpulse( 0 )	-- prevents the user from manually calling impulse through the command
		
		--don't do anything if the user is in the menu or the cursor is visible

		--changed this check because it wouldn't allow people to move around / or even open the scoreboard if their mouse was showing
		--if not ( gui.IsGameUIVisible() or vgui.CursorVisible() ) then
		if not ( gui.IsGameUIVisible() or ply:IsTyping() ) then
		
			local impulsebits = cmd:GetImpulse()	--doing it like this because we may want to translate the old flashlight impulses to other stuff or idk
			local buttonbits = cmd:GetButtons()	--unlike the impulse bits, we actually want to keep the previous ones, otherwise it's gonna break shit
			
			for i , v in pairs( self.CustomInputs ) do
				
				local button = v.Value
				local cvar_obj = v.ConVar
				
				--this should never happen but there might be some errors in shared and we don't want to spam this
				if not cvar_obj or not button then continue end

				--this is used for both the bindings that have to be put into the impulse flags and the ones that just go on the button ones
				
				if input.IsButtonDown( cvar_obj:GetInt() ) then
					if v.Button then
						buttonbits = bit.bor( buttonbits , button )
					else
						impulsebits = bit.bor( impulsebits , button )
					end
				end

			end
			
			cmd:SetImpulse( impulsebits )
			cmd:SetButtons( buttonbits )

		end
	end

	--we do this shared because people might override this and also bots wouldn't care otherwise
	
	if bit.band( cmd:GetButtons() , IN_WALK ) ~= 0 then
		cmd:SetButtons( bit.bxor( cmd:GetButtons() , IN_WALK ) )
	end

	if bit.band( cmd:GetButtons() , IN_DUCK ) ~= 0 then
		cmd:SetButtons( bit.bxor( cmd:GetButtons() , IN_DUCK ) )
		cmd:SetButtons( bit.bor( cmd:GetButtons() , IN_BULLRUSH ) )		--convert duck into this unused flag which we might use later on
	end

end

function GM:SetupMove( ply , mv , cmd )

	--we can't do this on StartCommand because that would prevent the client impulse from going to the server , and that'd be lame
	ply:SetExtraButtons( cmd:GetImpulse() )
	cmd:SetImpulse( 0 )				--we want to reset these here to avoid the default engine behaviour , might be too late though?
	mv:SetImpulseCommand( 0 )	--if it's too late it doesn't matter, we have hooks to disable most of the impulse behaviour
	
	--add or remove the bits used to show the scoreboard to the player, so the panel will automatically pop up
	
	--TODO: also force the scoreboard on if the game is over
	
	if mv:KeyDown( IN_SCORE ) then
		ply:HUDAddBits( GAMEMODE.HUDBits.HUD_SCOREBOARD )
	else
		ply:HUDRemoveBits( GAMEMODE.HUDBits.HUD_SCOREBOARD )
	end
	
	--disabled for now, this spams quite a bit
	--[[
	for i , v in pairs( self.CustomInputs ) do
		local button = v.Value

		if not button then continue end

		--handle dropping special actions here! we just want to delete them during prediction, or at least remove their entity serverside
		--and reset the DT vars containing that entity shared

		if bit.band( ply:GetExtraButtons() , button ) ~= 0 then

			MsgN( ply:Nick().." pressed "..i )

		end

	end
	]]

	--handle the player looking around cameras
	if not ply:Alive() or ply:Team() == self.TEAM_SPECTATORS then
		
		local currentcamera = ply:GetObserverTarget()
		
		if IsValid( currentcamera ) and currentcamera:GetClass() == "sm_camera" then
			mv:SetOrigin( currentcamera:EyePos() )
			currentcamera:ControlCamera( ply , mv , cmd )
		end
		
		if mv:KeyPressed( IN_ATTACK ) or mv:KeyPressed( IN_ATTACK2 ) then
			local incr = 0

			if mv:KeyPressed( IN_ATTACK ) and not mv:KeyPressed( IN_ATTACK2 ) then
				incr = 1
			elseif mv:KeyPressed( IN_ATTACK2 ) and not mv:KeyPressed( IN_ATTACK ) then
				incr = -1
			end

			--self:GetCameraInSequence( ply , incr )
		end
		return true
	end
end

function GM:Move( ply , mv )
end

function GM:PlayerTick( ply , mv )
end

function GM:FinishMove( ply , mv )
	--there's currently a bug with this , where the sound gets cut if you go outside of the main pvs area
	--ply:HandleFootsteps()
end

function GM:PlayerDriveAnimate( ply )
end

function GM:PlayerPostThink( ply , mv )

	--handle the player's battery recharge
	if SERVER and ply:Alive() then
		if ply:GetLastDamageTaken() < CurTime() - ply:GetBatteryRechargeTime() then

			local quarter = ply:GetMaxArmorBattery() / 4

			local canrecharge = math.floor( ply:GetArmorBattery() ) % quarter ~= 0

			--super shield case, allow recharging with no quarter limit
			if ply:GetMaxArmorBattery() > 100 then
				canrecharge = true
			end

			if canrecharge and ply:GetArmorBattery() < ply:GetMaxArmorBattery() and ply:GetNextBatteryRecharge() < CurTime() then
				local charge = ply:GetMaxArmorBattery()  / ( ply:GetBatteryRechargeTime() / engine.TickInterval() )
				local amount = math.Clamp( ply:GetArmorBattery() + charge , 0 , ply:GetMaxArmorBattery() )
				ply:SetArmorBattery( amount )
				ply:SetNextBatteryRecharge( CurTime() + engine.TickInterval() )
			end
		end

		--forget our last attacker after 5 seconds that we've been hit

		if IsValid( ply.LastAttacker ) and ply:GetLastDamageTaken() < CurTime() - 5 then
			ply.LastAttacker = nil
		end
	end

end

--we don't even care about who hits who here, we're going to do this check in EntityTakeDamage

function GM:PlayerShouldTakeDamage()
	return true
end

function GM:PlayerTraceAttack()
	return false
end

function GM:CanPlayerRespawn( ply )
	local rules = self:GetGameRules()
	
	if ply:Team() == GAMEMODE.TEAM_SPECTATORS then return true end	--this might get exploited I think
	
	if IsValid( rules ) and ( rules:IsRoundFlagOn( self.RoundFlags.LASTMANSTANDING ) or rules:IsRoundFlagOn( GAMEMODE.RoundFlags.INTERMISSION )  ) then return false end

	return ply:GetNextRespawn() <= CurTime()
end

--return true to override the view punch bullshit and default fall damage, and handle it ourselves here
function GM:OnPlayerHitGround( ply , inwater , onfloater , speed )
	if speed >= 600 then
		local mult = speed / 100

		local dmginfo = DamageInfo()
		dmginfo:SetDamage( mult * 2 )
		dmginfo:SetDamageTypeFromName( "Crush" )
		dmginfo:SetDamageForce( vector_origin )
		dmginfo:SetDamagePosition( ply:GetPos() )
		dmginfo:SetAttacker( game.GetWorld() )
		dmginfo:SetInflictor( game.GetWorld() )
		if SERVER then
			ply:TakeDamageInfo( dmginfo )
		end
		ply:PlaySound( "FALLDAMAGE" )
		ply:ViewPunchReset()
		ply:ViewPunch( Angle( 1 * mult , 0 , 0 ) )
		--ply:DoCustomAnimEvent( PLAYERANIMEVENT_JUMP , 0 )	--this only triggers the jump animation, not the landing one , gotta look into it
	end
	return true
end

--I may end up actually using this hook due to the problems I'm having right now
--this is also temporary

function GM:PlayerFootstep( ply , pos , foot , sound , volume, filter )
	ply:PlaySound( ( foot == 0 ) and "LEFTFOOT" or "RIGHTFOOT" , true )
	return true
end

function GM:DoAnimationEvent( ply , event , data )
	--handle the dual wielding animations of the base weapon
	if event == PLAYERANIMEVENT_ATTACK_PRIMARY then
		local seq = ply:LookupSequence( "range_dual_l" )
		ply:AddVCDSequenceToGestureSlot( GESTURE_SLOT_ATTACK_AND_RELOAD , seq , 0 , true )
		return ACT_INVALID
	elseif event == PLAYERANIMEVENT_ATTACK_SECONDARY then
		local seq = ply:LookupSequence( "range_dual_r" )
		ply:AddVCDSequenceToGestureSlot( GESTURE_SLOT_ATTACK_AND_RELOAD , seq , 0 , true )
		return ACT_INVALID
	end

	return self.BaseClass.DoAnimationEvent( self , ply , event , data )
end