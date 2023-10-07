local MainModule = {}
local Noise = require(script.Parent.Noise)()
local Tables = require(script.Parent.Tables)
Noise:Init()

local wedge = Instance.new("WedgePart");
wedge.Anchored = true;
wedge.TopSurface = Enum.SurfaceType.Smooth;
wedge.BottomSurface = Enum.SurfaceType.Smooth;

function toDecimal(b)
	local num = 0
	local power = 1

	for char in b:gmatch("(.)") do
		num += char == "1" and power or 0
		power *= 2
	end
	return num
end

function GetBlock(x,y,z)
	local val = Noise:Get3DValue(x/50, y/50, z/50)
	local Reduce = math.max(1, (y-5)/5)
	local noise = Noise:Get3DValue(x/30, y/30, z/30)
	val += noise / 4

	return val/Reduce > 0.25
end

function draw3dTriangle(a, b, c, parent)
	local ab, ac, bc = b - a, c - a, c - b;
	local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc);
	
	if (abd > acd and abd > bcd) then
		c, a = a, c;
	elseif (acd > bcd and acd > abd) then
		a, b = b, a;
	end
	
	ab, ac, bc = b - a, c - a, c - b;
	
	local right = ac:Cross(ab).unit;
	local up = bc:Cross(right).unit;
	local back = bc.unit;
	
	local height = math.abs(ab:Dot(up));
	
	local w1 = wedge:Clone();
	w1.Size = Vector3.new(0, height, math.abs(ab:Dot(back)));
	w1.CFrame = CFrame.fromMatrix((a + b)/2, right, up, back);
	w1.Parent = parent;
	
	local w2 = wedge:Clone();
	w2.Size = Vector3.new(0, height, math.abs(ac:Dot(back)));
	w2.CFrame = CFrame.fromMatrix((a + c)/2, -right, up, -back);
	w2.Parent = parent;
	
	return w1, w2;
end


function MainModule.GenChunk(X,Y,Z)
	local ChunkSize = 10
	local BlockSize = 4
	local ChunkData = {}
	local edgePoints = {}
	local ChunkPos = Vector3.new(X,Y,Z) * ChunkSize

	for i=0, ChunkSize ^ 3 - 1 do
		local LocalData = {}
		local x = i % ChunkSize  + ChunkPos.X
		local y = math.floor(i / ChunkSize^2) % ChunkSize  + ChunkPos.Y
		local z = math.floor(i / ChunkSize) % ChunkSize  + ChunkPos.Z

		for _,v in pairs(Tables.voltexdata) do
			local InTable = x + v[1]/2 + (y + v[2]/2) * ChunkSize^2 + (z + v[3]/2) * ChunkSize

			local v = edgePoints[InTable] or (GetBlock(x + v[1]/2, y + v[2]/2, z + v[3]/2) and 1 or 0)
			table.insert(LocalData, v)
		end

		local BlockType = toDecimal(table.concat(LocalData))
		table.insert(ChunkData, {x,y,z, BlockType})
	end

	local ChunkModel = Instance.new("Model", workspace.Terrain)

	for _,block in ipairs(ChunkData) do
		local pos = Vector3.new(block[1], block[2], block[3])
		local typ = Tables.VoxelList[block[4]]

		
		for i=1, #typ, 3 do
			local a,b,c = Tables.PartEdgePoints[typ[i]], Tables.PartEdgePoints[typ[i+1]], Tables.PartEdgePoints[typ[i+2]]
			a,b,c = Vector3.new(a[1], a[2], a[3])/2 + pos, Vector3.new(b[1], b[2], b[3])/2 + pos, Vector3.new(c[1], c[2], c[3])/2 + pos
			a,b,c = a*BlockSize, b*BlockSize, c*BlockSize
			
			draw3dTriangle(a,b,c, ChunkModel)
		end
	end
end


return MainModule