---------------------- // Variables \\ ----------------------
local MainModule = {}
local Noise = require(script.Parent.Noise)()
local Tables = require(script.Parent.Tables)
local MeshHandler = require(script.Parent.MeshHandler)
local Settings = require(script.Parent.GameSettigs)
MainModule.Tables = Tables
Noise:Init()
MainModule.BuildBlocks = {}

local ChunkSize = Settings.ChunkSize
local BlockSize = Settings.BlockSize

--------------- // Math \\ ---------------

function SmoothMin(a:number, b:number, k:number)
	local h = math.clamp((b - a + k) / (2 *k), 0,1);
	return a * h + b * (1 - h) - k * h * (1 - h);
end 

function Bias(x:number, bias:number)
	local k = (1-bias) ^ 3
	return (x * k) / (x * k - x + 1);
end

function FractionalNoise(Position:Vector3)
	local noiseSum = 0
	local amplitude = 1
	local frequency = 1

	for i=0, 4 do
		local Pos = Position / 300 * frequency
		noiseSum += math.noise(Pos.X, Pos.Y, Pos.Z) * amplitude
		frequency *= 2
		amplitude *= 0.5
	end
	return noiseSum
end






---------------------- // Generate ChunkData \\ ----------------------

function toDecimal(b)
	local num = 0
	local power = 1

	for char in b:gmatch("(.)") do
		num += char == "1" and power or 0
		power *= 2
	end
	return num
end

function GetBlock(x, y, z)
	local val = FractionalNoise(Vector3.new(x,y,z)) * 2
	local h = (y - 100) / 50

	local Multiplyer = (math.noise(x/500,y/500,z/500) + 1) * 2
	val = (val - h) * Multiplyer

    return val
end

function lerp(a, b, t)
	return a + (b - a) * t
end


function MainModule.GenChunk(X:number,Y:number,Z:number)
	local Mesh = MeshHandler.new()
	local ChunkPos = Vector3.new(X,Y,Z) * ChunkSize

	local IsBlockVal = 0.5
	
	for i=0, ChunkSize^3 - 1 do
		local x = (i % ChunkSize) + ChunkPos.X
		local y = (math.floor(i / ChunkSize^2) % ChunkSize) + ChunkPos.Y
		local z = (math.floor(i / ChunkSize) % ChunkSize) + ChunkPos.Z
		local BlockPos = (Vector3.new(x,y,z) + ChunkPos)

		local VertexData = table.create(8)
		local BlockData = table.create(8)
		local BlockEdges = table.create(12)
		local BlockIsEmpty = true

		for i=1, #Tables.VertexPoints do
			local Pos = (Tables.VertexPoints[i]/2 + BlockPos + ChunkPos) * BlockSize
			local val = GetBlock(Pos.X, Pos.Y, Pos.Z)
			if val >= IsBlockVal then BlockIsEmpty = false end

			local isBlock = val >= IsBlockVal and 0 or 1
			table.insert(VertexData, {val, Pos})
			table.insert(BlockData, isBlock)
		end

		if BlockIsEmpty then continue end
		local BlockType = toDecimal(table.concat(BlockData))
		local Triangles = Tables.VoxelList[BlockType]
		if #Triangles == 0 then continue end

		for i,a in Triangles do
			if BlockEdges[a+1] then continue end
			local v = Tables.Edges[a+1]
			local v1 = VertexData[v[1]]
			local v2 = VertexData[v[2]]

			local mu = (IsBlockVal - v1[1]) / (v2[1] - v1[1])
			local id = Mesh:AddVertex(lerp(v1[2], v2[2], mu))
			BlockEdges[a+1] = id
		end

		for i=1, #Triangles, 3 do
			local a = Triangles[i] +1
			local b = Triangles[i + 1] +1
			local c = Triangles[i + 2] +1

			Mesh:AddFace(BlockEdges[a],BlockEdges[b],BlockEdges[c])
		end
	end
	Mesh:Load()
end








--[[function MainModule.GenChunk(X:number,Y:number,Z:number, LodSize:number?)
	LodSize = LodSize or 1
	local ChunkPos = Vector3.new(X,Y,Z) * ChunkSize
	local LodChunkSize = ChunkSize / LodSize

	local ChunkTabLen = LodChunkSize ^ 3
	local ChunkData = table.create(ChunkTabLen + 1)
	table.insert(ChunkData, {LodSize = LodSize})
	local LastBlockGenerated = {}

	for i=0, ChunkTabLen - 1 do
		local BlockData = table.create(8)
		local x = (i % LodChunkSize) * LodSize + ChunkPos.X
		local y = (math.floor(i / LodChunkSize^2) % LodChunkSize) * LodSize + ChunkPos.Y
		local z = (math.floor(i / LodChunkSize) % LodChunkSize) * LodSize + ChunkPos.Z

		if LastBlockGenerated[1] == x-1 then 
			BlockData[1] = LastBlockGenerated[2]
			BlockData[4] = LastBlockGenerated[3]
			BlockData[5] = LastBlockGenerated[4]
			BlockData[8] = LastBlockGenerated[5]
		end

		for i=1, #Tables.voltexdata do
			if BlockData[i] then continue end
			local v = Tables.voltexdata[i]
			local Offset = Vector3.new(v[1], v[2], v[3])
			local Pos = Vector3.new(x, y, z) + Offset/2 * LodSize
			
			if table.find(MainModule.BuildBlocks, Pos) then BlockData[i] = 1 continue end
			local IsBlock =  GetBlock(Pos.X, Pos.Y, Pos.Z) and 1 or 0
			BlockData[i] = IsBlock
		end

		LastBlockGenerated = {x, BlockData[2], BlockData[3], BlockData[6], BlockData[7]}

		local BlockType = toDecimal(table.concat(BlockData))
		if BlockType == 0 or BlockType == 255 then continue end
		table.insert(ChunkData, {x,y,z, BlockType})
	end

	return ChunkData
end]]


---------------------- // Generate Blocks \\ ----------------------






--[=[function MainModule.LoadChunk(ChunkData)
	local ChunkModel = Instance.new("Model", workspace.Terrain)
	local LodSize = 1

	for g=1, #ChunkData do
		local block = ChunkData[g]
		if g==1 then LodSize = block.LodSize continue end
		local pos = Vector3.new(block[1], block[2], block[3])
		local typ = Tables.VoxelList[block[4]]
		local Off = Vector3.new(LodSize, LodSize, LodSize) * BlockSize / 2

		for i=1, #typ, 3 do
			local a,b,c = Tables.PartEdgePoints[typ[i]], Tables.PartEdgePoints[typ[i+1]], Tables.PartEdgePoints[typ[i+2]]
			a,b,c = Vector3.new(a[1], a[2], a[3])/2 * LodSize + pos, Vector3.new(b[1], b[2], b[3])/2 * LodSize + pos, Vector3.new(c[1], c[2], c[3])/2 * LodSize + pos
			a,b,c = a*BlockSize + Off, b*BlockSize + Off, c*BlockSize + Off

			draw3dTriangle(a,b,c, ChunkModel)
		end
	end
	return ChunkModel
end




---------------------- // Voxel Functions \\ ----------------------


function MainModule.RayCast(vOrigin:Vector3, vGoal:Vector3)
	local vRayDir = (vGoal - vOrigin).Unit

    local RayUnitStepSize = {
        X = math.sqrt(1 + (vRayDir.Y / vRayDir.X)^2 + (vRayDir.Z / vRayDir.X)^2),
        Y = math.sqrt(1 + (vRayDir.X / vRayDir.Y)^2 + (vRayDir.Z / vRayDir.Y)^2),
        Z = math.sqrt(1 + (vRayDir.X / vRayDir.Z)^2 + (vRayDir.Y / vRayDir.Z)^2)}

	local Step = {}
	local RayLength1D = {}
	local MapCheck = Vector3.new(math.floor(vOrigin.X), math.floor(vOrigin.Y), math.floor(vOrigin.Z))

	-- // Setup Grid

	if vRayDir.X < 0 then
        RayLength1D.X = (vOrigin.X - MapCheck.X) * RayUnitStepSize.X
        Step.X = -1
    else
        RayLength1D.X = ((MapCheck.X + 1) - vOrigin.X) * RayUnitStepSize.X
        Step.X = 1
    end

    if vRayDir.Y < 0 then
        RayLength1D.Y = (vOrigin.Y - MapCheck.Y) * RayUnitStepSize.Y
        Step.Y = -1
    else
        RayLength1D.Y = ((MapCheck.Y + 1) - vOrigin.Y) * RayUnitStepSize.Y
        Step.Y = 1
    end

    if vRayDir.Z < 0 then
        RayLength1D.Z = (vOrigin.Z - MapCheck.Z) * RayUnitStepSize.Z
        Step.Z = -1
    else
        RayLength1D.Z = ((MapCheck.Z + 1) - vOrigin.Z) * RayUnitStepSize.Z
        Step.Z = 1
    end

	-- // RayCast

	local fMaxDis = 100
	local fCurrentDis = 0

	while fCurrentDis < fMaxDis do
		local minRayLength = math.min(RayLength1D.X, RayLength1D.Y, RayLength1D.Z)

		if minRayLength == RayLength1D.X then
			MapCheck += Vector3.new(Step.X, 0, 0)
			fCurrentDis = RayLength1D.X
			RayLength1D.X = RayLength1D.X + RayUnitStepSize.X

		elseif minRayLength == RayLength1D.Y then
			MapCheck += Vector3.new(0, Step.Y, 0)
			fCurrentDis = RayLength1D.Y
			RayLength1D.Y = RayLength1D.Y + RayUnitStepSize.Y

		else
			MapCheck += Vector3.new(0, 0, Step.Z)
			fCurrentDis = RayLength1D.Z
			RayLength1D.Z = RayLength1D.Z + RayUnitStepSize.Z
		end

		if GetBlock(MapCheck.X, MapCheck.Y, MapCheck.Z) then
			break
		end
	end
    return vOrigin + vRayDir * fCurrentDis
end

]=]

return MainModule