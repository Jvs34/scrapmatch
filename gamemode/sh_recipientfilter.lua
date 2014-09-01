--[[
	usage:
	
	local filter = NewRecipientFilter( ply )	--the predicting player , can be nil
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

function NewRecipientFilter( predictingplayer )
	local filter = {}
	
	setmetatable( filter , {
		__index = recipientmeta,
	} )
	filter.PredictingPlayer
	filter.Recipients = {}
end

function recipientmeta:__call( useoldfiltertype )
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

function recipientmeta:AddPlayer( ply )
	for i ,v in pairs( self.Recipients ) do
		if v == ply then return false end
	end
	
	if IsValid( self.PredictingPlayer ) then
		if ply == self.PredictingPlayer and IsFirstTimePredicted() then
			return false
		end
	end
	
	table.insert( self.Recipients , ply )
	return true
end

function recipientmeta:AddPlayersByTeam( teamid )
	for i , v in pairs( player.GetAll() ) do
		if v:Team() == teamid then
			self:AddPlayer( v )
		end
	end
end

function recipientmeta:RemoveAllPlayers()
	for i , v in pairs( self.Recipients ) do
		self.Recipients[i] = nil
	end
end

function recipientmeta:RemovePlayer( ply )
	for i ,v in pairs( self.Recipients ) do
		if v == ply then 
			self.Recipients[i] = nil
			return true
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