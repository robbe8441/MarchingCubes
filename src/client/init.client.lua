--!native

local MainModule = require(game.ReplicatedStorage.Shared.MainModule)
local UIS = game:GetService("UserInputService")
local Plr = game.Players.LocalPlayer
local Cache = {}
local LoadedChunks = {}


function GetLOD(dis)
    if dis > 1200 then return 16 end
    if dis > 800 then return 8 end
    if dis > 400 then return 4 end
    if dis > 200 then return 2 end
    return 1
end

function RoundV3(Pos)
    return Vector3.new(math.round(Pos.X), math.round(Pos.Y), math.round(Pos.Z))
end

function PlaceBlock()
    local MouseRay = Plr:GetMouse().UnitRay
    local res = workspace:Raycast(MouseRay.Origin, MouseRay.Direction * 100)
    if not res then return end

    local Block = res.Position / 4
    Block = RoundV3(Block)
    local Chunk = RoundV3(Block) / 16

    for i,v in MainModule.Tables.voltexdata do
        local Pos = Block + Vector3.new(v[1],v[2],v[3]) / 2
        if table.find(MainModule.BuildBlocks, Pos) then continue end
        table.insert(MainModule.BuildBlocks, Pos)
    end
end


UIS.InputBegan:Connect(function(input, gameProcessedEvent)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        PlaceBlock()
        print("Placed")
    end
end)



task.spawn(function()
    local ChunkinBlocks = 64
    while task.wait() do
        local Char = Plr.Character or Plr.CharacterAdded:Wait()
        local PlayerPos = Char:GetPivot().Position / ChunkinBlocks
        
        local LoadRange = 50
        local Pos = RoundV3(PlayerPos) - Vector3.one * LoadRange / 2
        local Prio = {}

        for i=0, LoadRange^3 - 1 do
            local x = i % LoadRange + Pos.X
            local y = math.floor(i / LoadRange^2) % LoadRange + Pos.Y
            local z = math.floor(i / LoadRange) % LoadRange + Pos.Z
            if y < 0 or y > 100 then continue end
            local ChunkPos = Vector3.new(x,y,z)
            if table.find(LoadedChunks, ChunkPos) then continue end
            table.insert(LoadedChunks, ChunkPos)
            table.insert(Prio, ChunkPos)
        end

        table.sort(Prio, function(a,b)
            return (a - PlayerPos).Magnitude < (b - PlayerPos).Magnitude
        end)

        for i,ChunkPos in pairs(Prio) do
            local LOD = GetLOD((PlayerPos - ChunkPos).Magnitude * ChunkinBlocks)
            local data = MainModule.GenChunk(ChunkPos.X, ChunkPos.Y, ChunkPos.Z, LOD)
            game:GetService("RunService").RenderStepped:Wait()
            if #data == 1 then continue end
            table.insert(Cache, data)
        end
    end
end)



while task.wait() do
    for i, data in pairs(Cache) do
        MainModule.LoadChunk(data)
        table.remove(Cache, i)
        task.wait()
    end
end