AddCSLuaFile()

ENT.Type 			= "anim"
ENT.Base             = "base_anim"

--what the fuck am I even doing here, this is only called for ENT:GetStringKey( i ) which is used in the debug stuff for sh_specialaction.lua

ENT.KeysToString={
	[16384]="IN_ALT1",
	[32768]="IN_ALT2",
	[1]="IN_ATTACK",
	[2048]="IN_ATTACK2",
	[33554432]="IN_ATTACK3", 
	[16]="IN_BACK",	 
	[4194304]="IN_BULLRUSH",	
	[64]="IN_CANCEL",	 
	[4]="IN_DUCK",	 
	[8]="IN_FORWARD",
	[8388608]="IN_GRENADE1",	 
	[16777216]="IN_GRENADE2",
	[2]="IN_JUMP",	 
	[128]="IN_LEFT",	 
	[512]="IN_MOVELEFT",	 
	[1024]="IN_MOVERIGHT",	 
	[8192]="IN_RELOAD",	 
	[256]="IN_RIGHT",	 
	[4096]="IN_RUN", 
	[65536]="IN_SCORE",	 
	[131072]="IN_SPEED",	 
	[32]="IN_USE",	 
	[262144]="IN_WALK",	 
	[1048576]="IN_WEAPON1",	 
	[2097152]="IN_WEAPON2",	 
	[524288]="IN_ZOOM",	 

}

ENT.DefaultKeys={
	IN_ATTACK,	--left weapon	, these are checked manually in sm_weapon anyway
	IN_ATTACK2,	--right weapon, same here
	
	IN_GRENADE1,	--doesn't matter even if it's used, we're never going to fill in the Attack on those actions
	IN_GRENADE2,	--same here
	IN_ATTACK3,	--this the only one we care about keys wise, since this is the active slot
}


ENT.Actions = {}
ENT.DebugKeys = {}

function ENT:Initialize()
	
	if ( SERVER ) then

		self:DrawShadow(false)
		self:SetNoDraw(true)
		for i = 0 , SA.MaxSpecialActions - 1 do
			self:SetAvailableKey( i , self.DefaultKeys[i+1] or 0 )
		end
		
		self:SetNextTick( CurTime() )
		
		--so we don't stress out too much shit in the playerTick hook, can be increased , of course the minimum value on this will be dependant on what hook it's run in
		
		self:SetTickRate( 0.1 )
		
	else
		--mark this entity as predictable
		if LocalPlayer() == self:GetOwner() then
			self:SetPredictable(true)
		end
		
	end
	
	self:SetTransmitWithParent( true )
	
end

function ENT:CreateSpecialaction( id , slot )
	
	--ok here's the deal, this slot is the same as the ones defined in SA.Slots
	--if this is a weapon action and the slot is UNDEFINED, then look at LEFT_WEAPON and RIGHT_WEAPON
	--if they're valid and their CurSa slots are also those, they can be replaced with this UNDEFINED one
	
	if type( id ) == "string" then
		id = SA:GetIdByClass( id )
	end
	
	local sa = SA:GetSAById( id )
	
	--this weapon action has no prefered slot, try to look for one,
	if sa:IsWeaponAction() and slot == SA.Slots.UNDEFINED then
		
		for i = SA.Slots.LEFT_WEAPON , SA.Slots.RIGHT_WEAPON do
			local theirent = self:GetActionEntity( i )
			if IsValid( theirent ) then
				local theirsa = theirent:GetCurSA()
				--what this does is to check if this weapon action has a prefered slot,
				--if it does it means that it's a default weapon action and can be replaced
				--I'll have to move away from this check once I implement sa:IsDefaultAction()
				if theirsa:GetSlot() == i then
					slot = i
					break
				end
			else
				--the special action weapon in this slot is invalid, we're the first ones to occupy it
				slot = i
				break
			end
		end
		
		--if the slot is still undefined it means we can't equip this automatically, all the slots are full
		if slot == SA.Slots.UNDEFINED then return end
		
	end
	
	--MsgN("SLOT " .. slot)
	
	if not sa:CanEquip( self , self:GetOwner() , slot ) then return end
	
	
	local en = ents.Create( "sent_specialaction" )
	if not IsValid(en) then return nil end
	en:SetSlot( slot )
	en:SetPos( self:GetPos() )
	en:SetParent( self:GetOwner() )
	en:SetOwner( self:GetOwner() )
	--sethandledmanually prevents the action from receiving the base hooks
	en:SetHandledManually( sa:IsWeaponAction() )
	
	if sa:IsWeaponAction() then
		en:SetCustomHandler( self:GetOwner():GetActiveWeapon() )
	end
	
	en:SetAction( id )
	en:SetSaController( self )
	en:Spawn()
	self:ReplaceAction(en , slot )
	
	return en
end

function ENT:GetAllActions()
	for i = 0 , SA.MaxSpecialActions - 1 do
		self.Actions[i] = self:GetActionEntity(i)
	end
	
	return self.Actions
end

function ENT:GetStringKey( id )
	if self:GetAvailableKey( id ) then
		return self.KeysToString[self:GetAvailableKey( id )] or tostring(self:GetAvailableKey( id ))
	end
end

function ENT:SetupDataTables()

	self:NetworkVar( "Float", 0, "NextTick")
	self:NetworkVar( "Float", 1, "TickRate",{ KeyName = "TickRate", Edit = { type = "Float", min = engine.TickInterval(), max = 1, category = "Special action", order = 1 } })

	for i = 0 , SA.MaxSpecialActions - 1 do
		self:NetworkVar( "Int", i, "AvailableKey"..i,{ KeyName = "AvailableKey"..i, Edit = { type = "Generic", category = "Special action", order = i + 2 } })
		self:NetworkVar( "Entity", i, "ActionEntity"..i )	
	end
	
end

function ENT:SetAvailableKey( id , key )
	if self["SetAvailableKey"..id] then
		self["SetAvailableKey"..id]( self , key )
	end
end

function ENT:GetAvailableKey( id )
	return self["GetAvailableKey"..id] and self["GetAvailableKey"..id](self) or nil
end

function ENT:SetActionEntity( id , ent )
	if self["SetActionEntity"..id] then
		self["SetActionEntity"..id]( self , ent )
	end
end

function ENT:GetActionEntity( id )
	return self["GetActionEntity"..id] and self["GetActionEntity"..id](self) or nil
end

function ENT:GetDebugInfo(actionid)
	if IsValid(self:GetActionEntity(actionid)) then
		return self:GetActionEntity(actionid):GetDebugInfo()
	end
end

function ENT:GetActionByClass(classname)
	for i=0, SA.MaxSpecialActions - 1 do	
		if IsValid(self:GetActionEntity(i)) then
			if self:GetActionEntity(i):GetType() == classname then
				return self:GetActionEntity(i)
			end
		end
	end
end

function ENT:ReplaceAction(ent,number)
	if not number then	number = 0 end
	if not self:GetActionEntity(number) then
		MsgN("can't find function GetActionEntity"..number.." ! Gee I wonder why")
		return
	end
	
	if IsValid(self:GetActionEntity(number)) then
		MsgN("replacing "..self:GetActionEntity(number):GetType().." with "..ent:GetType().." on slot "..number)
		self:GetActionEntity(number):Remove()
	end
	
	self:SetAvailableKey( number , self.DefaultKeys[number+1] )
	self:SetActionEntity( number, ent )
end

function ENT:GetKey(ent)
	return self:GetAvailableKey( ent:GetSlot() )
end

function ENT:GetSaAndKeys()
	
	for i=0,SA.MaxSpecialActions - 1 do	
		if IsValid(self:GetActionEntity(i)) then
			if not self.DebugKeys[i] then self.DebugKeys[i] = {} end
			self.DebugKeys[i][1] = self:GetActionEntity( i )
			self.DebugKeys[i][2] = self:GetAvailableKey( i )
		end
	end
	
	return self.DebugKeys
end

function ENT:ResetKeys()
	for i = 0 , SA.MaxSpecialActions - 1 do
		self:SetAvailableKey( i , self.DefaultKeys[i+1] or 0 )
	end
end

function ENT:SetKey(ent,key_enum)
	self:SetAvailableKey( ent:GetSlot() , key_enum )
end

function ENT:ResetKey(ent)
	self:SetAvailableKey( ent:GetSlot() , self.DefaultKeys[i+1] or 0 )
end

function ENT:OnRemove()
	if SERVER then
		self:RemoveAllSA()
	end
end

function ENT:RemoveAllSA()
	for i=0,SA.MaxSpecialActions - 1 do	
		if IsValid(self:GetActionEntity(i)) then
			self:GetActionEntity( i ):Remove()
		end
	end
end

function ENT:DoSpecialAction(actionstring , ... )
	for i=0, SA.MaxSpecialActions - 1 do	
		if IsValid(self:GetActionEntity(i)) and self:GetActionEntity(i).dt and not self:GetActionEntity(i):GetHandledManually() then
			self:GetActionEntity(i):DoSpecialAction(actionstring, ...)
		end
	end
end

function ENT:CalcAbsolutePosition()
	if IsValid( self:GetOwner() ) then
		return self:GetOwner():WorldSpaceCenter() , self:GetOwner():EyeAngles()
	end
end