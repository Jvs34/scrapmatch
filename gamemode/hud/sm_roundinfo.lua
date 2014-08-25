local PANEL = {}

PANEL.Font = "SM_Font_RoundInfo"..CurTime()

function PANEL:Init()
	self.BaseClass.Init( self )
	self:AssociateHUDBits( GAMEMODE.HUDBits.HUD_ROUNDSTATUS )
	
	surface.CreateFont( self.Font ,
	{
		font		= "Roboto",
		size		= ScreenScale( 10 ),
		antialias	= true,
		weight		= 300
	})
	
	self:SetSuggestedX( 0.5 )
	self:SetSuggestedY( 0.03 )
	self:SetSuggestedW( 0.3 )
	self:SetSuggestedH( 0.05 )
	
	self.RoundInfo = self:Add( "DLabel" )
	self.RoundInfo:Dock( TOP )
	self.RoundInfo:SetFont( self.Font )
	self.RoundInfo:SetText( "Lorem penis dick" )
	self.RoundInfo:SetContentAlignment( 5 )
	
	self.Timer = self:Add( "DLabel" )
	self.Timer:Dock( BOTTOM )
	self.Timer:SetFont( self.Font )
	self.Timer:SetText( "" )
	self.Timer:SetContentAlignment( 5 )
	
end


function PANEL:Think()
	
	self.BaseClass.Think( self )
	
	if IsValid( GAMEMODE:GetGameRules() ) and GAMEMODE:GetGameRules().dt then
		if GAMEMODE:GetGameRules():GetRoundDuration() ~= -1 then
			local pre = ""
			local seconds = GAMEMODE:GetGameRules():GetRoundTime() - CurTime()
			local value = string.NiceTime( seconds )
			
			if GAMEMODE:GetGameRules():IsRoundFlagOn( GAMEMODE.RoundFlags.INTERMISSION ) then
				pre = "Round starts in"
			else
				pre = "Round ends in"
			end
			
			--TODO: if the round is 25% away from completition turn the color of the timer label red
			
			self.Timer:SetText(pre.." "..value)
		end
		
		local roundinfo = ""
		
		if GAMEMODE:GetGameRules():GetMaxRounds() ~= -1 then
			roundinfo = roundinfo.."Round "..GAMEMODE:GetGameRules():GetCurrentRound().." of "..GAMEMODE:GetGameRules():GetMaxRounds().." "
		end
		
		if GAMEMODE:GetGameRules():GetMaxScore() ~= -1 then
			roundinfo = roundinfo.."Max Score "..GAMEMODE:GetGameRules():GetMaxScore()
		end
		
		
		self.RoundInfo:SetText( roundinfo )
	end
end

derma.DefineControl( "SM_RoundInfo", "The current round info.", PANEL, "SM_BaseHUDPanel" )