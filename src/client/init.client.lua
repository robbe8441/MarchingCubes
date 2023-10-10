local MainModule = require(game.ReplicatedStorage.Shared.MainModule)
local Plr = game.Players.LocalPlayer
local Cache = {}
local LoadedChunks = {}


function GetLOD(dis)
    if dis > 800 then return 16 end
    if dis > 500 then return 8 end
    if dis > 300 then return 4 end
    return 2
end




task.spawn(function()
    local ChunkinBlocks = 64
    while task.wait() do
        local Char = Plr.Character or Plr.CharacterAdded:Wait()
        local PlayerPos = Char:GetPivot().Position / ChunkinBlocks
        
        local LoadRange = 20
        local Pos = Vector3.new(math.round(PlayerPos.X), math.round(PlayerPos.Y), math.round(PlayerPos.Z)) - Vector3.one * LoadRange / 2
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
            local LOD = GetLOD((PlayerPos - ChunkPos).Magnitude * ChunkinBlocks / 2)
            local data = MainModule.GenChunk(ChunkPos.X, ChunkPos.Y, ChunkPos.Z, LOD)
            if #data == 1 then continue end
            task.wait()
            table.insert(Cache, data)
        end
        task.wait(10)
    end
end)



while task.wait() do
    for i, data in pairs(Cache) do
        MainModule.LoadChunk(data)
        task.wait()
        table.remove(Cache, i)
    end
end