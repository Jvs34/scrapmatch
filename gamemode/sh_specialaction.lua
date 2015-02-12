--[[
	k so here's how it works
	when the player spawns he's automatically given a special action controller,
	it's an entity which can hold <SA.MaxSpecialActions> special actions, and will relay the hooks to them.
	obviously, you won't be able to spawn special actions if this entity somehow goes NULL
	the controller will also assign IN_ enums keys that the special actions will be able to use
	
	since some of the IN_ enums don't actually have a concommand associated to them , or at least most people don't
	I added a CreateMove implementation that triggers that IN_ enum and sends it to the server on the cusercmd if the user presses the sa_key0 ( number ) key

	new addition: sent_specialaction entities can now have custom handlers entities
	
	CODE CHANGE
	I added newsa:GetEntity() , and removed the whole ( entity , owner , ... ) kind of bullshit, to get the owner you have to go through newsa:GetEntity()
]]

IN_ATTACK3		= 2 ^ 25		-- Garry forgot to put this one in, considering tf2 brought this in, it's relatively new
IN_SA_ACTIVE	= 2 ^ 26	--we've got more space up to 31

--these are unused, they'll be renamed later on when they'll be actually used for something
IN_SA_CUSTOM1	= 2 ^ 27
IN_SA_CUSTOM2	= 2 ^ 28
IN_SA_CUSTOM3	= 2 ^ 29
IN_SA_CUSTOM4	= 2 ^ 30
IN_SA_CUSTOM5	= 2 ^ 31

if not SA then
	SA = {}
	SA.META = {}
	SA.salist = {}
	SA.DEFAULT=nil
end
local ID=1

SA.MaxSpecialActions = 5	--set here as some kind of constant, too much stuff relies on it and making it dynamic isn't worth it
SA.ScriptedDTVars = 2

SA.Slots = {
	UNDEFINED		= -1,
	
	LEFT_WEAPON 	= 0,
	RIGHT_WEAPON 	= 1,
	
	BODY 			= 2,
	PASSIVE			= 3,
	ACTIVE			= 4,
}

function SA:GetUniqueID(str)
	local id = 0
	for i=1,#str do
		id = id + string.byte(str,i) * i
	end
	return id
end

function SA:CreateController(owner)
	local en=ents.Create("sent_specialaction_controller")
	en:SetPos(owner:GetPos())
	en:SetParent(owner)
	en:SetOwner(owner)
	en:Spawn()
	owner:DeleteOnRemove( en )
	owner:SetSpecialActionController( en )
	return en
end

function SA:GetController( owner )
	if not IsValid( owner ) then return end
	if owner.dt then
		local ent = owner:GetSpecialActionController()
		return ( IsValid( ent ) and ent.dt ) and ent or nil
	end
end

function SA:RemoveController( owner )
	if not IsValid( owner ) then return end
	if owner.dt and IsValid( owner:GetSpecialActionController() ) then
		if SERVER then
			owner:GetSpecialActionController():Remove()
		end
		owner:SetSpecialActionController( NULL )
	end
end

function SA:GetSAById(id)
	return self.salist[id] or self.salist[self.DEFAULT]
end

function SA:GetIdByClass(saclass)
	local _sa=nil
	for i,v in pairs(self.salist) do
		if v:GetClass() == saclass then 
			_sa=v:GetID()
			break
		end
	end
	return _sa or self.DEFAULT
end

function SA:New( name , class , description )

	local specialact = {}
	
	setmetatable( specialact , {
		__index = SA.META,
	} )
	
	specialact:SetName( name	or	"No Name" )
	specialact:SetClass( class	or	"sa_noclass" )
	specialact:SetDescription( description or "" )
	specialact:SetID( self:GetUniqueID( specialact:GetClass() ) )
	self.salist[specialact:GetID()] = specialact
	
	return specialact
end

AccessorFunc( SA.META	, "_Entity" , "Entity" )
AccessorFunc( SA.META	, "_Class" , "Class" )
AccessorFunc( SA.META	, "_Name" , "Name" )
AccessorFunc( SA.META	, "_Description" , "Description" )
AccessorFunc( SA.META	, "_ID" , "ID" )

function SA.META:GetMethodByString(str)
	return ( type( self[str] ) == "function" ) and self[str] or nil
end

function SA.META:CanEquip( controller , owner , slot )
	return true
end

function SA.META:IsWeaponAction()
	return false
end

function SA.META:CanDrop()
	if self:GetSlot() == SA.Slots.BODY then
		return false
	end
	return true
end

function SA.META:GetSlot()
	return SA.Slots.UNDEFINED
end

function SA.META:GetRespawnTime()
	return 0
end

function SA.META:AttackThink( mv )
	if entity:IsKeyDown( mv ) and entity:GetNextAction() < CurTime() then
		entity:DoSpecialAction("Attack" , mv )
	end
end

function SA.META:__tostring()
	return self:GetClass().." ["..self:GetID().."]["..self:GetName().."]["..self:GetDescription().."]"
end

--ported by _Kilburn, I just made a few adjustments

function SA.META:FormatViewModelAttachment(pos, eyepos, eyeang, fovsrc, fovdst,invertsources)

	fovsrc=(fovsrc) and fovsrc or LocalPlayer():GetFOV()
	fovdst=(fovdst) and fovdst or wepfov
	if invertsources then
		fovsrc,fovdst=fovdst,fovsrc
	end
	
	local srcx = math.tan(math.rad(fovsrc/2))
	local dstx = math.tan(math.rad(fovdst/2))
	
	local factor = srcx / dstx
	
	local viewForward, viewRight, viewUp = eyeang:Forward(), eyeang:Right(), eyeang:Up()
	local tmp = pos - eyepos
	
	local transformed = Vector(viewRight:Dot(tmp), viewUp:Dot(tmp), viewForward:Dot(tmp))
	
	if dstx == 0 then
		transformed.x = 0
		transformed.y = 0
	else
		transformed.x = transformed.x * factor
		transformed.y = transformed.y * factor
	end
	
	local out = viewRight * transformed.x + viewUp * transformed.y + viewForward * transformed.z
	out:Add(eyepos)
	
	return out
end

if CLIENT then
	
	local font_name = "SpecialActionFont"
	
	surface.CreateFont( font_name,
	{
		font		= "Helvetica",
		size		= ScreenScale( 6 ),
		antialias	= true,
		weight		= 800
	})
	
	local baseposx=10
	local baseposy=10
	local ystackincrease = nil
	
	local function DrawDebugText(text,x,y)
		surface.SetFont( font_name )
		surface.SetTextColor( 255, 255, 255, 255 )
		surface.SetTextPos( x,y ) 
		surface.DrawText( text )
		
		if not ystackincrease then
			local _ , h = surface.GetTextSize("w")
			ystackincrease = h
		end
		
		return surface.GetTextSize( text )
	end

	
	--TODO: convert this into a proper overlay panel which can respond to clicks
	
	hook.Add("HUDPaint", "SpecialAction", function()
		local ply = LocalPlayer()
		local ent=SA:GetController( ply ) 
		if not IsValid( ent ) then return end
		
		local gamerules = GAMEMODE:GetGameRules()
		if not IsValid( gamerules ) then return end
		
		if gamerules:GetDebugMode() then
			local ystack=0
			DrawDebugText("Special actions:" , baseposx , baseposy + ystack )
			
			for i = 0 , SA.MaxSpecialActions - 1 do
				ystack=ystack+ystackincrease
				
				if IsValid( ent:GetActionEntity( i ) ) then
					
					DrawDebugText( i..") "..ent:GetActionEntity(i):GetType().." "..tostring( ent:GetActionEntity( i ) ).." "..ent:GetStringKey( i ),baseposx,baseposy+ystack)
					
					local debugtab = ent:GetDebugInfo(i)
					
					for i,v in pairs( debugtab )  do
						ystack=ystack+ystackincrease
						
						DrawDebugText("           "..i..": "..v,baseposx,baseposy+ystack)
						
					end
				
				else
					
					DrawDebugText(i..") nil [NULL Entity] "..ent:GetStringKey(i),baseposx,baseposy+ystack)
				end
				
			end
		end
	end)
	
end

if SERVER then
	hook.Add("EntityTakeDamage", "SpecialAction", function(ply,dmginfo)
		if not ply:IsPlayer() then return end
		if not IsValid(SA:GetController( ply )) then return end
		SA:GetController( ply ):DoSpecialAction("OnOwnerTakesDamage",dmginfo)
	end)
	
	hook.Add("PlayerUse", "SpecialAction", function(ply,ent)
		if not ply:IsPlayer() then return end
		if not IsValid(SA:GetController( ply )) then return end
		SA:GetController( ply ):DoSpecialAction("PlayerUse",ent)
	end)
end

--TODO: find a better way to handle these two, ugh
--[[
hook.Add("CalcMainActivity","SpecialAction",function( ply, velocity )	
	if not IsValid(SA:GetController( ply )) then return end
	SA:GetController( ply ):DoSpecialAction("CalcMainActivity",velocity)
	
	
	if ply.SA_CalcIdeal and ply.SA_CalcSeqOverride then
		local calcideal=ply.SA_CalcIdeal
		local seqoverride=ply.SA_CalcSeqOverride
		ply.SA_CalcIdeal=nil
		ply.SA_CalcSeqOverride=nil
		return calcideal, seqoverride
	end

end)

hook.Add("DoAnimationEvent","SpecialAction",function( ply, event, data )
	if event == PLAYERANIMEVENT_CUSTOM then
		if not IsValid(SA:GetController( ply )) then return end
		SA:GetController( ply ):DoSpecialAction("DoAnimationEvent", event, data)
		return ACT_INVALID
	end
end)
]]

hook.Add("UpdateAnimation","SpecialAction",function( ply, velocity, maxseqgroundspeed )
	if not IsValid(SA:GetController( ply )) then return end
	SA:GetController( ply ):DoSpecialAction("UpdateAnimation",velocity, maxseqgroundspeed)
end)

hook.Add("PlayerTick", "SpecialAction", function(ply,mv)
	if not IsValid(SA:GetController( ply )) then return end
	if SA:GetController( ply ):GetNextTick() < CurTime() then
		SA:GetController( ply ):DoSpecialAction("AttackThink",mv)
		SA:GetController( ply ):DoSpecialAction("Think",mv)
		SA:GetController( ply ):SetNextTick( CurTime() + SA:GetController( ply ):GetTickRate() ) --engine.TickInterval())--
	end
end)

hook.Add("SetupMove", "SpecialAction", function(ply,mv,cm)
	if not IsValid(SA:GetController( ply )) then return end
	if ply:InVehicle() or ply:IsDrivingEntity() then return end
	SA:GetController( ply ):DoSpecialAction("SetupMove",mv,cm)
end)

hook.Add("Move", "SpecialAction", function(ply,mv)
	if not IsValid(SA:GetController( ply )) then return end
	if ply:InVehicle() or ply:IsDrivingEntity() then return end
	SA:GetController( ply ):DoSpecialAction("Move",mv)
end)

hook.Add("FinishMove", "SpecialAction", function(ply,mv)
	if not IsValid(SA:GetController( ply )) then return end
	if ply:InVehicle() or ply:IsDrivingEntity() then return end
	SA:GetController( ply ):DoSpecialAction("FinishMove",mv)
end)



if SERVER then
	
	--debug commands to give a special action to the player, these can only be enabled if sm_debugmode is 1
	
	local function GiveSpecialAction( ply , args )
		
		local said = tonumber( args[1] )
		if not said then
			said = SA:GetIdByClass( args[1] )
		end
		
		said = said or SA.DEFAULT
		
		ply:GiveSpecialAction( said )
		
	end
	
	hook.Add( "Initialize" , "ScrapMatch Add SA commands" , function()
		GAMEMODE:RegisterCommand("sm_givesa", function(ply,command,args)
			if not GAMEMODE.ConVars["DebugMode"]:GetBool() then return end
			
			if not IsValid(ply) or not ply:Alive() then return end
			
			GiveSpecialAction( ply , args )
		end,
		function( command , args )
		args = args:Trim():lower()

		local rettbl = {}
		for i , v in pairs( SA.salist ) do
			if #args <= 0 or string.find( v:GetClass():lower() , args ) then
				table.insert( rettbl , command.." "..v:GetClass() )
			end
		end
		return rettbl
		end, nil, FCVAR_REPLICATED )

		GAMEMODE:RegisterCommand("sm_removeallsa", function(ply,command,args)
			if not GAMEMODE.ConVars["DebugMode"]:GetBool() then return end
			
			if not IsValid(ply) then return end
			
			if IsValid( SA:GetController( ply ) ) then
				SA:GetController( ply ):RemoveAllSA()
			end
			
		end,
		function()
		
		end, nil, FCVAR_REPLICATED )
	end )
else
	

end

SA.DEFAULT = SA:New("Base Special Action","sa_base","The base special action, this is here as a fallback"):GetID()