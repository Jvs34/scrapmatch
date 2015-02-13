--[[
	usage:
	
	local filter = LuaRecipientFilter( ply )	--the predicting player , can be nil
	filter:AddAllPlayers()
	
	net.Start( "whatever" )
		net.WriteString( "im gay" )
	net.Send( filter() )
	
	local effectdata = EffectData()
	effectdata:SetOrigin( vector_origin )
	effectdata:SetScale( 69 )
	
	util.Effect( "cum_explosion" , effectdata , true , filter( true ) )
	
	made by Alessio 'Jvs' Malato
	no copyright on this stuff because I don't give a shit, do whatever you want, see if I care
]]

local recipientmeta = {}

function recipientmeta:ToString()
	local str = ""
	
	if self.Recipients then
		str = str.."["..#self.Recipients.."]"
	end
	
	return Format( "LuaRecipientFilter %s" , str )
end

function recipientmeta:Length()
	return self.Recipients and #self.Recipients or 0
end

function recipientmeta:GetPlayers( useoldfiltertype )
	--compatibility for util.Effect which doesn't use a table for the recipients
	if useoldfiltertype then
		local oldfilter = RecipientFilter()
		for i ,v in pairs( self.Recipients ) do
			oldfilter:AddPlayer( v )
		end
		return oldfilter
	end
	return self.Recipients
end

function recipientmeta:AddAllPlayers()
	for i , v in pairs( player.GetAll() ) do
		self:AddPlayer( v )
	end
end

function recipientmeta:RemoveAllPlayers()
	for i , v in pairs( self.Recipients ) do
		self.Recipients[i] = nil
	end
end

function recipientmeta:AddPlayer( ply )
	if not IsValid( ply ) or not ply:IsPlayer() then return false end
	
	for i ,v in pairs( self.Recipients ) do
		if v == ply then return false end
	end

	if IsValid( self.PredictingPlayer ) and not IsFirstTimePredicted() then
		if ply == self.PredictingPlayer then
			return false
		end
	end
	
	if SERVER then
		if not ply:IsConnected() then return false end
	end
	
	if ply:IsBot() then return false end
	
	table.insert( self.Recipients , ply )
	return true
end

function recipientmeta:RemovePlayer( ply )
	for i ,v in pairs( self.Recipients ) do
		if v == ply then 
			self.Recipients[i] = nil
			return true
		end
	end
end

function recipientmeta:AddPlayersByTeam( teamid )
	for i , v in pairs( player.GetAll() ) do
		if v:Team() == teamid then
			self:AddPlayer( v )
		end
	end
end

function recipientmeta:RemovePlayersByTeam( teamid )
	for i , v in pairs( player.GetAll() ) do
		if v:Team() == teamid then
			self:RemovePlayer( v )
		end
	end
end

function recipientmeta:AddPlayersByCallback( callbackfunction )
	if not callbackfunction then return false end
	
	for i , v in pairs( player.GetAll() ) do
		local ret = callbackfunction( self , v )
		if ret ~= false then
			self:AddPlayer( v )
		end
	end
	return true
end

function recipientmeta:RemovePlayersByCallback( callbackfunction )
	if not callbackfunction then return false end
	
	for i , v in pairs( player.GetAll() ) do
		local ret = callbackfunction( self , v )
		if ret ~= false then
			self:RemovePlayer( v )
		end
	end
	return false
end

--TODO: I can't handle this PVS crap because it's defined in the engine , sending this shit to everyone is fine, it'll get culled by the entity not existing or some other shit
function recipientmeta:AddPlayersByPVS( origin )
	self:AddAllPlayers()
end

function recipientmeta:RemovePlayersByPVS( origin )
	self:RemoveAllPlayers()
end

--TODO
function recipientmeta:AddPlayersByBitmask( bitmask )
end

function recipientmeta:RemovePlayersByBitmask( bitmask )
end

function LuaRecipientFilter( predictingplayer )
	local filter = {}
	
	setmetatable( filter , {
		__index = recipientmeta,
		__call = recipientmeta.GetPlayers,
		__tostring = recipientmeta.ToString,
		__len = recipientmeta.Length,
	} )
	filter.PredictingPlayer = predictingplayer
	filter.Recipients = {}
	return filter
end