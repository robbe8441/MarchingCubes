local Mesh = {}
Mesh.__index = Mesh

local wedge = Instance.new("WedgePart");
wedge.Anchored = true;
wedge.TopSurface = Enum.SurfaceType.Smooth;
wedge.BottomSurface = Enum.SurfaceType.Smooth;
wedge.Color = Color3.fromRGB(104, 74, 49)

function draw3dTriangle(a, b, c, normal ,parent)
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

	local WorldUpDir = Vector3.new(0,1,0)
	local dot = normal:Dot(WorldUpDir)

	local grassVal = 0.9
	local GrassColor = Color3.fromRGB(49, 105, 49)

	if dot > grassVal then
		w1.Color = GrassColor
		w2.Color = GrassColor
	end

	return w1, w2;
end


-- No Optimisation = 9704 VertexPoints
-- Match Vertex = 2574 VertexPoints  == 377% Improvement



function Mesh.new()
    return setmetatable({
        Vertexes = {},
        Faces = {}
    }, Mesh)
end


function Mesh:AddVertex(pos:Vector3, Normal:Vector3) : number

	for i=1, #self.Vertexes do
		local v = self.Vertexes[i]
		if v.Position == pos then 
			self.Vertexes[i].Normal = (Normal + v.Normal) / 2
			return i 
		end
	end

    table.insert(self.Vertexes, {Position=pos, Normal=Normal})
    return #self.Vertexes
end

function Mesh:AddFace(a:number, b:number, c:number) : number
    local data = {a=a, b=b, c=c}
    table.insert(self.Faces, data)
    return #self.Faces
end



function Mesh:Optimise()

end






function Mesh:Load()
    for i=1, #self.Faces do
        if i%100 == 0 then task.wait() end
        local FaceData = self.Faces[i]
		local a = self.Vertexes[FaceData.a]
		local b = self.Vertexes[FaceData.b]
		local c = self.Vertexes[FaceData.c]

		local Normal = (a.Normal + b.Normal + c.Normal) / 3

        draw3dTriangle(a.Position, b.Position, c.Position, Normal ,workspace.Terrain)
    end

	print(#self.Vertexes)
end











function Mesh:ToObj()
	local res = {}

	for i=1, #self.Vertexes do
		local format = "v %f %f %f"
		local Pos = self.Vertexes[i].Position
		local v = string.format(format, Pos.X, Pos.Y, Pos.Z)
		table.insert(res, v)
	end

	for i=1, #self.Vertexes do
		local format = "vn %f %f %f"
		local Normal = self.Vertexes[i].Normal
		local v = string.format(format, Normal.X, Normal.Y, Normal.Z)
		table.insert(res, v)
	end

	for i=1, #self.Faces do
		local format = "f %i/1/%i %i/1/%i %i/1/%i"
		local Face = self.Faces[i]
		local v = string.format(format, Face.a, Face.a, Face.b, Face.b, Face.c, Face.c)
		table.insert(res, v)
	end

	print(res)
	warn(self)
	print(table.concat(res, "\n"))
end

return Mesh