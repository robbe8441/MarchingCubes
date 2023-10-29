local Mesh = {}
Mesh.__index = Mesh

type Vertex = {x:number, y:number, z:number}
type Face = {a:Vertex, b:Vertex, c:Vertex}

local wedge = Instance.new("WedgePart");
wedge.Anchored = true;
wedge.TopSurface = Enum.SurfaceType.Smooth;
wedge.BottomSurface = Enum.SurfaceType.Smooth;

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




function Mesh.new()
    return setmetatable({
        Vertexes = {},
        Faces = {}
    }, Mesh)
end

function Mesh:AddVertex(pos:Vector3) : number
    table.insert(self.Vertexes, pos)
    return #self.Vertexes
end

function Mesh:AddFace(a:number, b:number, c:number) : number
    local data : Face = {a=a, b=b, c=c}
    table.insert(self.Faces, data)
    return #self.Faces
end

function Mesh:Load()
    for i=1, #self.Faces do
        if i%100 == 0 then task.wait() end
        local FaceData = self.Faces[i]
        draw3dTriangle(self.Vertexes[FaceData.a], self.Vertexes[FaceData.b], self.Vertexes[FaceData.c], workspace.Terrain)
    end
end

return Mesh