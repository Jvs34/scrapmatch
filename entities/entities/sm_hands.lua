
AddCSLuaFile()

--[[
	TODO:	this is a bit of a mess since I'm using multiple viewmodels for this
				what'll end up happening is that during :BuildBonePositions of this entity I'll manually move the bones of the left arm
				to the first viewmodel and the right arm to the second viewmodel
				it might fuck up a bit because of the inverted drawing but I think that'd be fine
]]

ENT.Type 			= "anim"
ENT.Base             = "base_anim"

function ENT:Initialize()
	if SERVER then
	
	else
	
	end
end

function ENT:Think()

end