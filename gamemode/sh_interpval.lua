--[[
	Interpolated variables, similar to the system valve uses for the clientside DT vars
	This one is made in Lua and available in both states ( if you really needed to but ok )
	Generally this stuff should only be used clientside, such as a fuel bar for a jetpack
	This should never be used during prediction , even though it still might be safe to.
	
	usage:
	
	function PANEL:Init()
		self.PlayerHealth = LuaInterpolatedValue( "Health" , TYPE_NUMBER , 100 )
		self.PlayerLabel = self:Add( "DLabel" )
		self.PlayerHealthLabel:SetText( "100" )
	end
	
	function PANEL:Think()
		if IsValid( self.Player ) then
			self.PlayerHealth:Update( self.Player:Health() )
			self.PlayerHealthLabel:SetText( self.PlayerHealth:GetValue() )
		end
	end
]]

--interpolation flags

INTERP_ROUNDDOWN = 2 ^ 0
INTERP_ROUNDUP = 2 ^ 1


local interpvalmeta = {}

function interpvalmeta:ToString()
	return "LuaInterpolatedValue"
end

function interpvalmeta:GetType()
	return self.ValueType
end

function interpvalmeta:GetValue()
	return self.Value
end

--[[
	this is the function that runs the actual interpolation
	what it does is to try and approach the value inputted, based on a time fraction between
	the last update and the current time

]]

function interpvalmeta:Update( val )
	
	if type( val ) ~= self:GetType() then
		Error( "Value type mismatching" )
	end
	
	self.Value = self:Interpolate( val )
	self.LastUpdate = self:GetTime()
end

function interpvalmeta:Interpolate( currentvalue )
	
	local oldvalue = self.Value
	
	--no need to interpolate this
	
	if currentvalue == oldvalue then
		return currentvalue
	end
		
	local newvalue = nil
	
	if self:GetType() == TYPE_NUMBER then
		newvalue = self:InterpolateNumber( currentvalue , oldvalue )
	elseif self:GetType() == TYPE_VECTOR then
		newvalue = self:InterpolateVector( currentvalue , oldvalue )
	elseif self:GetType() == TYPE_ANGLE then
		newvalue = self:InterpolateAngle( currentvalue , oldvalue )
	elseif self:GetType() == TYPE_BOOL then
		newvalue = self:InterpolateBool( currentvalue , oldvalue )
	end
	
	return newvalue
end

function interpvalmeta:InterpolateVector( currentvalue , oldvalue )
	local vec = Vector( 0 , 0 , 0 )
	vec.x = self:InterpolateNumber( currentvalue.x , oldvalue.x )
	vec.y = self:InterpolateNumber( currentvalue.y , oldvalue.y )
	vec.z = self:InterpolateNumber( currentvalue.z , oldvalue.z )
	return vec
end

function interpvalmeta:InterpolateAngle( currentvalue , oldvalue )
	--might actually do some stuff with math.ApproachAngle here
	local ang = Angle( 0 , 0 , 0 )
	ang.p = self:InterpolateNumber( currentvalue.p , oldvalue.p )
	ang.y = self:InterpolateNumber( currentvalue.y , oldvalue.y )
	ang.r = self:InterpolateNumber( currentvalue.r , oldvalue.r )
	return ang
end

function interpvalmeta:InterpolateBool( currentvalue , oldvalue )
	return currentvalue
end

function interpvalmeta:InterpolateNumber( currentvalue , oldvalue )
	--[[
		self:HasFlag( INTERP_ROUNDDOWN )
		
	]]
end

function interpvalmeta:GetTime()
	return self.TimeFunction()
end

function interpvalmeta:SetTimeFunction( func )
	self.TimeFunction = func
end

function interpvalmeta:SetFlags( flags )
	self.Flags = flags
end

function interpvalmeta:GetFlags()
	return self.Flags
end

function interpvalmeta:HasFlag( flag )
	return bit.band( self:GetFlags() , flag ) ~= 0
end

function LuaInterpolatedValue( name , type , initialvalue , timefunction )
	local interp = {}
	
	setmetatable( interp , {
		__index = interpvalmeta,
	--	__call = interpvalmeta.GetPlayers,
		__tostring = interpvalmeta.ToString,
	} )
	
	interp:SetFlags( 0 )
	interp.ValueType = type
	interp.ValueName = name
	
	interp:SetTimeFunction( timefunction or CurTime )
	
	interp.Value = initialvalue
	interp.LastUpdate = self:GetTime()
	
	return interp
end