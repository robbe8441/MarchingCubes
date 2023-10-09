---------------------- // Variables \\ ----------------------
local ChunkSize = 16
local BlockSize = 4

local MainModule = {}
local Noise = require(script.Parent.Noise)()
local Tables = require(script.Parent.Tables)
Noise:Init()

local wedge = Instance.new("WedgePart");
wedge.Anchored = true;
wedge.TopSurface = Enum.SurfaceType.Smooth;
wedge.BottomSurface = Enum.SurfaceType.Smooth;

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

function GetBlock(x,y,z)
	local val = Noise:Get3DValue(x/50, y/50, z/50)
	local Reduce = math.max(1, (y-5)/5)
	local noise = math.noise(x/50, y/50, z/50) --Noise:Get3DValue(x/30, y/30, z/30)
	val += noise / 4

	return val/Reduce > 0.25
end

function MainModule.GenChunk(X,Y,Z, LodSize)
	LodSize = LodSize or 1
	local ChunkData = {{LodSize = LodSize}}
	local ChunkPos = Vector3.new(X,Y,Z) * ChunkSize
	local NewSize = ChunkSize / LodSize

	for i=0, NewSize ^ 3 - 1 do
		local LocalData = {}
		
		local x = (i % NewSize) * LodSize + ChunkPos.X
		local y = (math.floor(i / NewSize^2) % NewSize) * LodSize + ChunkPos.Y
		local z = (math.floor(i / NewSize) % NewSize) * LodSize + ChunkPos.Z

		for _,v in pairs(Tables.voltexdata) do
			local v = GetBlock(x + v[1]/2*LodSize, y + v[2]/2*LodSize, z + v[3]/2*LodSize) and 1 or 0
			table.insert(LocalData, v)
		end

		local BlockType = toDecimal(table.concat(LocalData))
		if BlockType == 0 or BlockType == 255 then continue end
		table.insert(ChunkData, {x,y,z, BlockType})
	end
	return ChunkData
end


---------------------- // Generate Blocks \\ ----------------------



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


function MainModule.LoadChunk(ChunkData)
	local ChunkModel = Instance.new("Model", workspace.Terrain)
	local LodSize = 1

	for g,block in ipairs(ChunkData) do
		if g==1 then LodSize = block.LodSize continue end
		local pos = Vector3.new(block[1], block[2], block[3])
		local typ = Tables.VoxelList[block[4]]

		for i=1, #typ, 3 do
			local a,b,c = Tables.PartEdgePoints[typ[i]], Tables.PartEdgePoints[typ[i+1]], Tables.PartEdgePoints[typ[i+2]]
			a,b,c = Vector3.new(a[1], a[2], a[3])/2 * LodSize + pos, Vector3.new(b[1], b[2], b[3])/2 * LodSize + pos, Vector3.new(c[1], c[2], c[3])/2 * LodSize + pos
			a,b,c = a*BlockSize, b*BlockSize, c*BlockSize
			
			draw3dTriangle(a,b,c, ChunkModel)
		end
	end
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
	local Pos = Vector3.new()
	
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



return MainModule