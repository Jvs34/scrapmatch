
--[[
	default team module overrides, I do this because I want to relay these calls to my team entities, so the whole thing can be a LITTLE more dynamic
	to be fair though the default team handling IS retarded, even valve uses entities for that ( although a single one with a set amount of networked vectors depending on the MAX_TEAMS)
]]

--dummy functions that aren't called at all in the gamemode
function team.SetUp() end
function team.SetClass( id, classtable ) end
function team.GetClass( id ) end

function team.GetSpawnPoint( id , ply )
	local teament = GAMEMODE:GetTeamEnt( id )

	if IsValid( teament ) then
		--TODO: actually run some avoidance logic here , copy it from the hl2:dm code in the sourcesdk2013
		--go trough all the spawn points, if ply is valid then use his bounds on the hull traces, otherwise use the default ones
	
		local foundspawnpoint = nil
		local minb = Vector( -16 , -16 , 0 )
		local maxb = Vector( 16 ,  16 ,  72 )
		
		for i ,v in pairs( ents.FindByClass( teament:GetTeamSpawnPoint() ) ) do
			
			local tr = {}
			tr.start = v:GetPos()
			tr.endpos = v:GetPos() + Vector( 0 , 0 , maxb.z )
			tr.mins = minb
			tr.maxs = minb * -1
			tr.mask = MASK_PLAYERSOLID
			tr.ignoreworld = true
			tr.filter = ply
			
			local trres = util.TraceHull( tr )
			if not tr.Hit then
				foundspawnpoint = v
				break
			end
		end
		
		return foundspawnpoint or table.Random( ents.FindByClass( teament:GetTeamSpawnPoint() ) )
	end
	
end

function team.GetSpawnPoints( id ) 
	local teament = GAMEMODE:GetTeamEnt( id )
	
	if IsValid( teament ) then
		return ents.FindByClass( teament:GetSpawnPoint() )
	end
end

function team.SetSpawnPoint( id, ent_name ) 
	local teament = GAMEMODE:GetTeamEnt( id )
	
	if IsValid( teament ) then
		teament:SetTeamSpawnPoint( ent_name )
	end
end

local returnedTeams = {}
--Try to return the info as closely as this as possible, to keep compatibility, even though I think only one panel in base uses this
--TeamInfo[TEAM_CONNECTING] 	= { Name = "Joining/Connecting", 	Color = DefaultColor, 	Score = 0, 	Joinable = false }

function team.GetAllTeams()

	for id = 1 , GAMEMODE.MAX_TEAMS do
		
		local teament = GAMEMODE:GetTeamEnt( id )
		
		if not IsValid( teament ) then
			returnedTeams[id] = nil
		else 
			returnedTeams[id] = returnedTeams[id] or {}
			returnedTeams[id].Name = teament:GetTeamName()
			returnedTeams[id].Color = teament:GetTeamColor()
			returnedTeams[id].Score = teament:GetTeamScore()
			returnedTeams[id].Joinable = teament:GetTeamDisabled()
		end
	end
	
	return returnedTeams
end

function team.Valid( id )
	return IsValid( GAMEMODE:GetTeamEnt( id ) )
end

function team.Joinable( id )
	local teament = GAMEMODE:GetTeamEnt( id )
	
	if IsValid( teament ) then
		return not teament:GetTeamDisabled()
	end
end

function team.TotalDeaths( index )
	local score = 0
	for id,pl in pairs( player.GetAll() ) do
		if pl:Team() == index then
			score = score + pl:Deaths()
		end
	end
	return score
end

function team.TotalFrags( index )
	local score = 0
	for id,pl in pairs( player.GetAll() ) do
		if pl:Team() == index then
			score = score + pl:Frags()
		end
	end
	return score
end

function team.NumPlayers( index )
	return #team.GetPlayers( index )
end

function team.GetPlayers( index )
	local TeamPlayers = {}

	for id,pl in pairs( player.GetAll() ) do
		if IsValid( pl ) and pl:Team() == index then
			table.insert( TeamPlayers , pl )
		end
	end
	return TeamPlayers
end

function team.GetScore( index )
	local teament = GAMEMODE:GetTeamEnt( index )
	
	if IsValid( teament ) then
		return teament:GetTeamScore()
	end
	
	return 0
end

function team.GetName( index )
	local teament = GAMEMODE:GetTeamEnt( index )
	
	if IsValid( teament ) then
		return teament:GetTeamName()
	end
	
	return "Invalid Team"
end

function team.SetColor( index, color )
	local teament = GAMEMODE:GetTeamEnt( index )
	
	if IsValid( teament ) then
		teament:SetTeamColor( color )
	end
end

function team.GetColor( index )
	local teament = GAMEMODE:GetTeamEnt( index )
	
	if IsValid( teament ) then
		return teament:GetTeamColor()
	end
	
	return color_white
end

function team.SetScore( index , score)
	local teament = GAMEMODE:GetTeamEnt( index )
	
	if IsValid( teament ) then
		teament:SetTeamScore( score )
	end
end

function team.AddScore( index , score)
	local teament = GAMEMODE:GetTeamEnt( index )
	
	if IsValid( teament ) then
		teament:SetTeamScore( teament:GetTeamScore() + score )
	end
end


function team.BestAutoJoinTeam()
	local SmallestTeam = - 1
	local SmallestPlayers = game.MaxPlayers()

	for id = 1 , GAMEMODE.MAX_TEAMS do
		local teament = GAMEMODE:GetTeamEnt( id )
		
		if IsValid( teament ) and id ~= GAMEMODE.TEAM_SPECTATORS and not teament:GetTeamDisabled() then

			local PlayerCount = team.NumPlayers( id )
			if PlayerCount < SmallestPlayers or ( PlayerCount == SmallestPlayers and id < SmallestTeam ) then
				SmallestPlayers = PlayerCount
				SmallestTeam = id
			end

		end

	end

	return SmallestTeam
end