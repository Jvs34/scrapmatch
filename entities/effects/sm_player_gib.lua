AddCSLuaFile()

--TODO: from the bitflags passed from sm_player_gib_main get the hitbox bounds of the player
--and use them for the physics instead of the convex meshes of the ragdoll
--then rotate the bounds by that bone matrix angle and then construct the physics mesh we're going to use

EFFECT.Mat = Material("models/wireframe")

function EFFECT:Init( data )
	
	GAMEMODE:IncreaseGibCount()
	
	self.Mesh = {}
	
	if GAMEMODE.ConVars["GibsPhysics"]:GetBool() then
		self:SetCollisionGroup( COLLISION_GROUP_NONE )
	else
		self:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
	end
	
	self.BoneMask = data:GetDamageType()
	--print( math.IntToBin( self.BoneMask ) )
	self.Direction = data:GetAngles()
	self.Speed = data:GetScale()
	
	self.Owner = data:GetEntity()
	self.EyeTarget = self.Owner:GetAimVector()
	self.Owner:SetupBones()
	
	local plyang = self.Owner:EyeAngles()
	plyang.p = 0
	plyang.r = 0
	
	self:SetLOD( 0 )	--this is gonna make gibs a bit more expensive, but technically we're never rendering this model, we just use it to setup the bones
	
	self:DrawShadow( true )
	self:SetModel( self.Owner:GetModel() )
	
	self:SetPos( self.Owner:GetPos() )
	self:SetAngles( plyang )
	self:SetRenderBounds( self.Owner:GetRenderBounds() )
	
	self.LifeTime = CurTime() + GAMEMODE.ConVars["GibsFadeOut"]:GetFloat()
	
	if GAMEMODE.ConVars["GibsFadeOut"]:GetFloat() == -1 then
		self.LifeTime = -1
	end
	
	self.BoneCache = {}
	self.PlayerColor = self.Owner:GetPlayerColor()
	
	
	for i = 0 , self.Owner:GetBoneCount() -1 do
		local bm = self.Owner:GetBoneMatrix( i )
		if bm then
			self.BoneCache[i] = {}
			self.BoneCache[i].Bm = bm
			
			local pos , ang = WorldToLocal( bm:GetTranslation(), bm:GetAngles() , self.Owner:GetPos() , plyang )
			bm:SetTranslation( pos )
			bm:SetAngles( ang )
			self.BoneCache[i].Pos = pos
			self.BoneCache[i].Ang = ang
		end
	end
	
	for i = 0 , self.Owner:GetHitBoxCount( 0 ) - 1 do
		local bone = self.Owner:GetHitBoxBone( i , 0 )
		local bonebit = 2 ^ i
		
		if bit.band( self.BoneMask , bonebit ) == 0 then
			self.BoneCache[bone] = nil
		else
			local bmin , bmax = self:GetHitBoxBounds( i , 0 )
			
			table.insert( self.Mesh , self:CreateBoxFromBounds( bmin , bmax , self.BoneCache[bone].Ang , self.BoneCache[bone].Pos ) )
		end
		
	end
	
	self:AddCallback( "BuildBonePositions" , self.BuildBonePositions )
	
	self:SetSolid( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	
	self:PhysicsInitMultiConvex( self.Mesh )
	
	local physobj = self:GetPhysicsObject()
	if IsValid( physobj ) then
		physobj:SetMass( 5 * #self.Mesh )
		physobj:SetMaterial( "metal" )
		physobj:Wake()
		physobj:SetVelocity( self.Direction:Forward() * self.Speed )
		--just for debugging , this will be removed when the player has a proper multimodel
		self.IMesh = Mesh()
		self.IMesh:BuildFromTriangles( physobj:GetMesh() )
	end
	
end

function EFFECT:CreateBoxFromBounds( minbounds , maxbounds , angle , pos )
		local verts = {}
		
		
		for i = 0 , 7 do
			local vecPos = Vector()
			vecPos.x  = ( bit.band( i , 0x1 ) ~=0 ) and maxbounds.x or minbounds.x
			vecPos.y  = ( bit.band( i , 0x2 ) ~=0 ) and maxbounds.y or minbounds.y
			vecPos.z  = ( bit.band( i , 0x4 ) ~=0 ) and maxbounds.z or minbounds.z
			--TODO: rotate around angle
			if angle then
				vecPos:Rotate( angle )
			end
			if pos then
				vecPos = vecPos + pos
			end
			table.insert( verts , vecPos )
		end
		
		return verts
	end

function EFFECT:IsBoneInBitMask( boneid )
	for i = 0 , self.Owner:GetHitBoxCount( 0 ) - 1 do
		local bone = self.Owner:GetHitBoxBone( i , 0 )
		local bonebit = 2 ^ i
		
		if bone == boneid and bit.band( self.BoneMask , bonebit ) ~= 0 then
			return true
		end
	end
end

function EFFECT:PhysicsCollide( data , physobj )
end

function EFFECT:BuildBonePositions()
	
	self:SetEyeTarget( self.EyeTarget )	--eye flexes are broooooken, they used to work when gmod13 got released tho
	
	for i , v in pairs( self.BoneCache ) do
		local mybm = self:GetBoneMatrix( i )
		if mybm then
			local pos , ang = LocalToWorld( v.Pos , v.Ang , self:GetPos() , self:GetAngles() )
			v.Bm:SetTranslation( pos )
			v.Bm:SetAngles( ang )
			self:SetBoneMatrix( i , v.Bm )
		end
	end
	
	--[[
	for i = 0 , self:GetBoneCount() - 1 do
		--check if the bone parent of this bone
		local bm = self:GetBoneMatrix( i )
		if not bm then continue end
		
		--don't shrink it
		if self:IsBoneInBitMask( i ) then continue end
		
		local boneparent = self:GetBoneParent( i )
		
		if boneparent and self:IsBoneInBitMask( boneparent ) then continue end
		
		--shrink this bone down, try to cut it off so it doesn't show on the model
		bm:Scale( vector_origin )
		
		self:SetBoneMatrix( i , bm )
	end
	]]
end

function EFFECT:GetPlayerColor()
	return self.PlayerColor or vector_origin
end

function EFFECT:Think()
	
	if not IsValid( self.Owner ) then
		GAMEMODE:DecreaseGibCount()
		return false
	end
	
	if self.LifeTime ~= -1 and self.LifeTime < CurTime() then
		GAMEMODE:DecreaseGibCount()
		return false
	end
	
	return true
end

function EFFECT:Render()
	--TODO: replace this with a call to self.Owner:DrawMultiModel( options )
	render.SetMaterial( self.Mat )
	if self.IMesh then
		local m = Matrix()
		m:SetTranslation( self:GetPos() )
		m:SetAngles( self:GetAngles() )
		cam.PushModelMatrix( m )
			self.IMesh:Draw()
		cam.PopModelMatrix()
	end
end

