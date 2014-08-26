include( "hud/sm_mainhudpanel.lua" )
include( "hud/sm_basehudpanel.lua" )
include( "hud/sm_health.lua" )
include( "hud/sm_armor.lua" )
include( "hud/sm_damageinfo.lua" )
include( "hud/sm_ammo.lua" )
include( "hud/sm_roundinfo.lua" )
include( "hud/sm_scoreboard.lua" )
include( "hud/sm_crosshair.lua" )
include( "hud/sm_roundlog.lua" )
include( "hud/sm_playerinfo.lua" )
include( "hud/sm_votemenu.lua" )

GM.HUDDisable = {
	CHudDeathNotice = false,			--this isn't even used normally in gmod
--	CHudChat = false,					--still need this until I make an actual custom chat , I think the default one is fine, I just don't want having to deal with the hacky shit of chat hooks
	CHudWeaponSelection = false,	--duh , we only have one weapon anyway
	CHudHealth	= false,					--duh
	CHudBattery = false,				--duh
	CHudSecondaryAmmo = false,	--duh
	CHudAmmo	= false,					--duh
	CHudTrain = false,					--hl1 train hud , it's in source because of hl1 source
--	CHudMessage = false,				--used for PrintMessage( messagetype , str ) and a few map entities, we might still need this for debugging
	CHudMenu = false,					--used for tf2's and css' voice menu when you press z x c
	CHudWeapon = false,				--allows the weapon to draw stuff on the HUD, not used at all in gmod
	CHudHintDisplay = false,			--garry disabled hints anyway
	CHudCrosshair = false,				--we'll replace this later on
	CHudDamageIndicator = false,	--we have our own, we don't need this , well, we don't have it yet but we don't want the hl2 one because without the hev suit it always shows critical damage
}

function GM:CreateHUD()
	--autorefresh support
	if IsValid( self.HUDPanel ) then
		self.HUDPanel:Remove()
		self.HUDPanel = nil
	end

	self.HUDPanel = vgui.Create( "SM_MainHUDPanel" )
	self.HUDPanel:ParentToHUD()
	self.HUDPanel:Dock(FILL)
	
	net.Receive("sm_damageinfo", function( len ) 
		self:OnLocalPlayerTakeDamage( len )
	end)
	
	hook.Add( "player_hurt" , "Scrapmatch" , function( data )
		self:OnOtherPlayerTakeDamage( data )
	end)
end

function GM:GetMainHUD()
	return self.HUDPanel
end

function GM:HUDShouldDraw( element )
	if self.HUDDisable[element] ~= nil then
		return self.HUDDisable[element]
	end
	
	return true
end

--relay the damage we've taken to the effect panel , and color the damage direction depending on the damage type

function GM:OnLocalPlayerTakeDamage( len )

	local selfdamage = tobool( net.ReadBit() )
	local dmg = net.ReadUInt( 16 )
	local dmgtype = net.ReadUInt( 16 )
	local damagepos = net.ReadVector()
	
	local hudpanel = self:GetMainHUD()
	
	if not IsValid( hudpanel ) then return end
	
	local dmgpanel = hudpanel:GetHUDPanel( "SM_DamageInfo" )
	
	if not IsValid( dmgpanel ) then return end
	
	dmgpanel:ReceiveDamage( selfdamage , dmg , dmgtype , damagepos )
	
end

function GM:OnOtherPlayerTakeDamage( data )
	
	local victim = Player( data.userid )	--player.GetByID( data.userid )
	local attacker = Player( data.attacker )
	local health = data.health
	local hudpanel = self:GetMainHUD()
	
	if not IsValid( hudpanel ) then return end
	
	local dmgpanel = hudpanel:GetHUDPanel( "SM_Crosshair" )
	
	if not IsValid( dmgpanel ) then return end
	
	--the victim might be nil because it could be out of our PVS , pass it anyway
	dmgpanel:HitPlayer( victim , attacker , health )
end