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

----------------------------- // Math Functions \\ -----------------------------

function lerp(a, b, t)
	return a + (b - a) * t
end

function SmoothMin(a:number, b:number, k:number)
	local h = math.clamp((b - a + k) / (2*k), 0,1);
	return a * h + b * (1 - h) - k * h * (1 - h);
end 

function Bias(x:number, bias:number)
	local k = (1-bias) ^ 3
	return (x * k) / (x * k - x + 1);
end

function FractionalNoise(Position:Vector3)
	Position /= 1000
	local noiseSum = 0.5
	local amplitude = 1
	local frequency = 2

	for i=0, 5 do
		local Pos = Position /2 * frequency
		noiseSum += math.noise(Pos.X, Pos.Y, Pos.Z) * amplitude
		frequency *= 2
		amplitude *= 0.5
	end
	return noiseSum * 5
end


-- // function to get the VertexTable index of the block type
function toDecimal(b)
	local num = 0
	local power = 1

	for char in b:gmatch("(.)") do
		num += char == "1" and power or 0
		power *= 2
	end
	return num
end

-- This function runns for every Corner of a Cube
function GetBlock(x, y, z)
	local val = FractionalNoise(Vector3.new(x, y ,z)) * 4 -- lerp(0,y, Crazy/2)
	local h = (y - 300) / 20
	val = (val - h)

    return val
end



----------------------------- // Generate ChunkData \\ -----------------------------


function MainModule.GenChunk(X:number,Y:number,Z:number, LOD:number)
	local Mesh = MeshHandler.new()
	Mesh.Info.LOD = LOD
	local ChunkPos = Vector3.new(X,Y,Z)

	local SurfaceLevel = 0.5
	local ChunkSize = ChunkSize / LOD
	local BlockSize = BlockSize * LOD
	
	for i=0, ChunkSize^3 - 1 do
		
		if (i+1)% 3000 == 0 then task.wait() end
		local x = (i % ChunkSize)
		local y = (math.floor(i / ChunkSize^2) % ChunkSize)
		local z = (math.floor(i / ChunkSize) % ChunkSize)
		local offset = Vector3.one * BlockSize / 2
		local BlockPos = (Vector3.new(x,y,z) + ChunkPos*ChunkSize) * BlockSize + offset

		local VertexData = table.create(8)
		local BlockData = table.create(8)
		local BlockEdges = table.create(12)
		local BlockIsEmpty = true


		-- // Get Vertex Points
		for i=1, #Tables.VertexPoints do
			local Pos = (Tables.VertexPoints[i]/2) * BlockSize + BlockPos
			local val = GetBlock(Pos.X, Pos.Y, Pos.Z)
			if val >= SurfaceLevel then BlockIsEmpty = false end

			local isBlock = val >= SurfaceLevel and 0 or 1
			table.insert(VertexData, {val=val, pos=Pos})
			table.insert(BlockData, isBlock)
		end


		-- // Check if Empty and then skip the block
		if BlockIsEmpty then continue end
		local BlockType = toDecimal(table.concat(BlockData))
		local Triangles = Tables.VoxelList[BlockType]
		if #Triangles == 0 then continue end


		-- // Generate the Normals  <-------->  TODO needs to be fixed
		local UsedCorners = 0
		local NormalDir = Vector3.zero

		for i=1, #VertexData do
			local Vert = VertexData[i]
			if Vert.val > SurfaceLevel then continue end
			UsedCorners += 1
			NormalDir += Vert.pos - BlockPos
		end

		NormalDir = (NormalDir / UsedCorners).Unit


		-- // Get Vertex Position on Edge
		for i,a in Triangles do
			if BlockEdges[a+1] then continue end
			local Edge = Tables.Edges[a+1]
			local vert1 = VertexData[Edge[1]]
			local vert2 = VertexData[Edge[2]]

			local mu = (SurfaceLevel - vert1.val) / (vert2.val - vert1.val)
			local VertexPos = lerp(vert1.pos, vert2.pos, mu)

			local VertexId = Mesh:AddVertex(VertexPos, NormalDir)
			BlockEdges[a+1] = VertexId
		end


		-- // Split in to Triangles / Faces
		for i=1, #Triangles, 3 do
			local a = Triangles[i] +1
			local b = Triangles[i + 1] +1
			local c = Triangles[i + 2] +1

			Mesh:AddFace(BlockEdges[a],BlockEdges[b],BlockEdges[c])
		end
	end

	return Mesh
end




return MainModule