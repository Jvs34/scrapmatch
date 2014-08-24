AddCSLuaFile()

ENT.Type 			= "anim"
ENT.Base 			= "base_entity"

function ENT:Initialize()
	if SERVER then
		self:SetNoDraw( true )
		self:SetName( self:GetClass() )
	end
	
end

function ENT:SetupDataTables()

end

function ENT:Think()

end

if SERVER then

	function ENT:UpdateTransmitState()
		return TRANSMIT_ALWAYS
	end

end