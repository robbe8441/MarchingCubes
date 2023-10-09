local MainModule = require(game.ReplicatedStorage.Shared.MainModule)
local Plr = game.Players.LocalPlayer
local Cache = {}
local LoadedChunks = {}

-- // Simulate MultiThreading for later

local Possible LODS = {1,2,4}

function GetLOD(dis)
    if dis > 600 then return 16 end
    if dis > 400 then return 8 end
    if dis > 300 then return 4 end
    if dis > 100 then return 2 end
    return 1
end



task.spawn(function()
    while task.wait() do
        local Char = Plr.Character or Plr.CharacterAdded:Wait()
        local Pos = Char:GetPivot().Position / 40
        
        local LoadRange = 20
        Pos = Vector3.new(math.round(Pos.X), math.round(Pos.Y), math.round(Pos.Z)) - Vector3.one * LoadRange / 2
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
            return (a*40-Pos).Magnitude < (b*40-Pos).Magnitude
        end)

        for i,ChunkPos in pairs(Prio) do
            local LOD = GetLOD((Pos - ChunkPos*40).Magnitude)
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
        task.wait(0.1)
        MainModule.LoadChunk(data)
        Cache[i] = nil
    end
end