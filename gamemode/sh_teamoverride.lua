
--[[
	default team module overrides, I do this because I want to relay these calls to my team entities, so the whole thing can be a LITTLE more dynamic
	to be fair though the default team handling IS retarded, even valve uses entities for that ( although a single one with a set amount of networked vectors depending on the MAX_TEAMS)
]]

--dummy functions that aren't called at all in the gamemode
function team.SetUp() end
function team.SetClass( id, classtable ) end
function team.GetClass( id ) end

function team.GetSpawnPoint( id ) 
	local teament = GAMEMODE:GetTeamEnt( id )
	
	--TODO: actually run some avoidance logic here , copy it from the hl2:dm code in the sourcesdk2013
	
	if IsValid( teament ) then
		return table.Random( ents.FindByClass( teament:GetTeamSpawnPoint() ) )
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
--TeamInfo[TEAM_CONNECTING] 	= { Name = "Joining/Connecting", 	Color = DefaultColor, 	Score = 0, 	Joinable = false }

function team.GetAllTeams()

	for id = 1 , GAMEMODE.MAX_TEAMS do
		
		local teament = GAMEMODE:GetTeamEnt( id )
		
		if not IsValid( teament ) then
			
			--[[
				if a team used to be here, clear out the details, shh it's ok, it never existed, OH HERE IT GOES AGAIN I WAS JUST LAGGING JK
				that's probably the only problem with this system, they're still entities and if they don't exist on the client for some time things MIGHT fuck up
				but it's ok, since this system is supposed to be dynamic I'm gonna add fail safes anyway
			]]
			
			if returnedTeams[id] then
				returnedTeams[id] = nil
			end
			
			continue 
		end
		
		if not returnedTeams[id] then returnedTeams[id] = {} end	--only happens the first time this function is called
		
		returnedTeams[id].Name = teament:GetTeamName()
		returnedTeams[id].Color = teament:GetTeamColor()
		returnedTeams[id].Score = teament:GetTeamScore()
		returnedTeams[id].Joinable = teament:GetTeamDisabled()
		
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
		if (pl:Team() == index) then
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
			table.insert(TeamPlayers, pl)
		end
	end

	return TeamPlayers

end

function team.GetScore( index )
	local teament = GAMEMODE:GetTeamEnt( index )
	
	if IsValid( teament ) then
		return teament:GetTeamScore()
	end
	
	return 0	--sigh?
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
	
	return color_white	--fail safe because the default chat system bullshit / killicons don't even check SHIT

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
			if PlayerCount < SmallestPlayers or (PlayerCount == SmallestPlayers and id < SmallestTeam ) then
				SmallestPlayers = PlayerCount
				SmallestTeam = id
			end

		end

	end

	return SmallestTeam

end