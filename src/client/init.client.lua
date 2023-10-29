--!native

local MainModule = require(game.ReplicatedStorage.Shared.MainModule)
local Settings = require(game.ReplicatedStorage.Shared.GameSettigs)
local UIS = game:GetService("UserInputService")
local Plr = game.Players.LocalPlayer
local Cache = {}


MainModule.GenChunk(0,0,0)


--[[function GetLOD(dis) : number
    for i, v in Settings.LodLevelsDis do
        if dis >= v then return i end
    end
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


local ChunkinBlocks = 64
local Char = Plr.Character or Plr.CharacterAdded:Wait()
local PlayerPos = Char:GetPivot().Position / ChunkinBlocks


local LoadRange = Settings.MapSize
local Prio = {}

for i=0, LoadRange^3 - 1 do
    local x = i % LoadRange
    local y = math.floor(i / LoadRange^2) % LoadRange
    local z = math.floor(i / LoadRange) % LoadRange
    if y < 0 or y > 50 then continue end
    local ChunkPos = Vector3.new(x,y,z)

    local LOD = GetLOD((PlayerPos - ChunkPos).Magnitude * ChunkinBlocks)
    local data = MainModule.GenChunk(ChunkPos.X, ChunkPos.Y, ChunkPos.Z, LOD)
   

end]]



