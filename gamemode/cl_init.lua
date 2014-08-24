include("shared.lua")
include( "cl_hud.lua")

function GM:Initialize()

	self:CreateHUD()

	--try to hook up the self.CustomInputs to actual buttons on the keyboard
	
	--TODO: not for now though, it would just confuse the user
	--if this is the first time playing scrap match, save it on a cookie
	--and show the user a configuration panel where he can bind the buttons

	for i , v in SortedPairsByMemberValue( self.CustomInputs , "Value" ) do
		self:BindInputToKey( i ,	v.Command )
	end

	gameevent.Listen( "player_hurt" )	--hit confirmation on players
end



function GM:InitPostEntity()

end

--BindCustomInputToKey( "IN_DROP_LEFT_ACTION" , "slot1" )
function GM:BindInputToKey( index , bindingname )

	if not self.CustomInputs[index] or not self.CustomInputs[index].ConVar then
		MsgN( self.CustomInputs[index].ConVar )
		return
	end

	--UNDONE for now
	--[[
	--don't try to rebind it if it was already bound before ( or the user set it manually )
	if self.CustomInputs[index].ConVar:GetInt() > 0 then
		MsgN( self.CustomInputs[index].ConVar:GetName() .. " already bound to " .. input.GetKeyName( self.CustomInputs[index].ConVar:GetInt() ) )
		return
	end
	]]

	local keyname = input.LookupBinding( bindingname )

	if not keyname then
		ErrorNoHalt( "User does not have a key bound to "..bindingname )
		return
	end


	local keynum = -1

	for i = BUTTON_CODE_NONE , BUTTON_CODE_LAST do
		if keyname == input.GetKeyName( i ) then
			keynum = i
			MsgN( bindingname.. " bound to : ".. input.GetKeyName( i ) )
			break
		end
	end

	if keynum == -1 then
		ErrorNoHalt( "Could not find a matching button to ".. keyname .. " from " .. bindingname )
		return
	end

	--we don't have a ConVar:Set YET so this will have to do
	RunConsoleCommand( self.CustomInputs[index].ConVar:GetName() , tostring( keynum ) )
end

--function GM:NetworkEntityCreated( ent )
function GM:OnEntityCreated( ent )
	if IsValid( ent ) and ent:IsPlayer() then
		ent:InstallDataTable()
		ent:SetupDataTables()
	end
end

--called from a net message from the server , these are probably not going to be used but it's nice to have them here
function GM:RoundStart()
end

function GM:RoundEnd()
end

--we handle the scoreboard showing in sh_player.lua with a custom key bindnig , so this is not needed at all
function GM:ScoreboardShow()
end

function GM:ScoreboardHide()
end

function GM:OnReloaded()
	self:CreateHUD()
end