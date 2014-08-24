AddCSLuaFile()

ENT.Type 			= "anim"
ENT.Base             = "base_anim"

--only useful for debugging mode, but you never know, might use this for something else too
ENT.TrackedDtVars = {
	--[name] = { id = 0 , val = nil },
}

function ENT:Initialize()

	if ( SERVER ) then
		self:DrawShadow(false)
		self:SetNoDraw(true)
		self:SetNextAction( CurTime() + 1 )
	else
		if LocalPlayer() == self:GetOwner() then
			self:SetPredictable(true)
		end
	end
	self:SetTransmitWithParent( true )
	self:DoSpecialAction("SetupDTVars")
	self:DoSpecialAction("Initialize")
end

function ENT:SetupDataTables()
	self:NetworkVar( "Bool"	, 0 , "HandledManually" )	--we won't receive hooks from our controller directly anymore, we're handled by some other entity instead!
	self:TrackNetworkVar( false , "Float", 0, "NextAction")		--like a nextprimaryfire
	self:TrackNetworkVar( false, "Int", 0, "Action")			--my special action is 696969 ( converted to whatever like sa_penis )
	self:NetworkVar( "Int", 1, "Slot")				--hi I'm special action ID 0/1/2/3/4/5/6 etc etc

	self:NetworkVar( "Entity", 0, "SaController")		--this is my controller!
	self:NetworkVar( "Entity" , 1 , "CustomHandler" )	--this is my custom handler, if we have one
	self:NetworkVar( "Vector", 0, "ReservedVector")	--for future use
	self:NetworkVar( "Angle", 0, "ReservedAngle")		--for future use
	self:NetworkVar( "String", 0, "ReservedString")	--for future use
	--self:TrackNetworkVar( false, "Bool", 0, "IsDropped")			--am I dropped or not, don't know if this is ever going to be used

	for i = 1 , SA.ScriptedDTVars do
		self:TrackNetworkVar( true , "Float", i , "ActionFloat"..i)
		self:TrackNetworkVar( true , "Bool", i, "ActionBool"..i)
		self:TrackNetworkVar( true , "Int", i + 1, "ActionInt"..i)
		self:TrackNetworkVar( true , "Entity", i + 1, "ActionEntity"..i)
		self:TrackNetworkVar( true , "Vector", i, "ActionVector"..i)
		self:TrackNetworkVar( true , "Angle", i, "ActionAngle"..i)
	end

	--we're not going to network strings yet plus there's only 4 of them, gotta use them sparingly
end

function ENT:TrackNetworkVar( scriptable , nvtype , id , name , ... )

	self.TrackedDtVars[name] = {
		scriptable = scriptable,
		scriptedname = nil,
		nvtype = nvtype,
		id = id,
	}

	self:NetworkVar( nvtype , id , name , ... )
end

function ENT:CreateDTVar( dttype , name )
	for i , v in pairs( self.TrackedDtVars ) do
		if v.scriptable and not v.scriptedname and v.nvtype == dttype then
			self["Get"..name] = self["Get"..i]
			self["Set"..name] = self["Set"..i]
			v.scriptedname = name
			return true
		end
	end
	return false
end

function ENT:GetDebugInfo()

	--we can't use self:GetNetworkVars() since it doesn't return entities because the duplicator code would conflict otherwise.
	--so we're gonna have to track the variables on our own

	self.rt_tb = self.rt_tb or {}

	for i,v in pairs( self.TrackedDtVars ) do
		self.rt_tb[i] = self["Get"..i](self)
		if self.rt_tb[i] == nil then self.rt_tb[i] = NULL end
		
		self.rt_tb[i] = tostring( self.rt_tb[i] )
	end

	return self.rt_tb
end

function ENT:Think()
end

function ENT:GetCurSA()
	return SA:GetSAById(self:GetAction())
end

function ENT:GetType()
	return self:GetCurSA():GetClass()
end

function ENT:GetKey()
	if not IsValid( self:GetSaController() ) then return 0 end
	return self:GetSaController():GetKey(self)
end

function ENT:SetKey(key_enum)
	if not IsValid( self:GetSaController() ) then return end
	return self:GetSaController():SetKey( self, key_enum )
end

function ENT:ResetKey()
	if not IsValid( self:GetSaController() ) then return end
	return self:GetSaController():ResetKey(self)
end

function ENT:TickRate()
	if not IsValid( self:GetSaController() ) then return engine.TickInterval() end
	return self:GetSaController():GetTickRate()
end

function ENT:IsKeyDown( movedata )
	local target = movedata or self:GetOwner()
	
	return target:KeyDown(self:GetKey())
end

function ENT:DoSpecialAction( actionstring , ... )
	if IsValid( self:GetOwner() ) then
		if self:GetOwner().CanRunAction and not self:GetOwner():CanRunAction( self , actionstring ) then
			return
		end
	end

	local func = self:GetCurSA():GetMethodByString(actionstring)

	self:GetCurSA():SetEntity( self )

	if func then
		return func(self:GetCurSA(), ... )
	end
end

--this is here just in case sounds are played on this entity instead of the player and so at least they'd play at the center of the player itself
function ENT:CalcAbsolutePosition()
	if IsValid( self:GetOwner() ) then
		return self:GetOwner():WorldSpaceCenter() , self:GetOwner():EyeAngles()
	end
end

function ENT:OnRemove()
	self:DoSpecialAction("Deinitialize")
end
