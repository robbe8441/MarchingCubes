local MainModule = require(game.ReplicatedStorage.Shared.MainModule)
local Plr = game.Players.LocalPlayer
local Cache = {}
local LoadedChunks = {}

-- // Simulate MultiThreading for later


task.spawn(function()
    while task.wait(1) do
        local Char = Plr.Character or Plr.CharacterAdded:Wait()
        local Pos = Char:GetPivot().Position / 40
        Pos = Vector3.new(math.round(Pos.X), math.round(Pos.Y), math.round(Pos.Z)) - Vector3.new(5,5,5)/2

        local LoadRange = 5

        for i=0, LoadRange^3 - 1 do
            local x = i % LoadRange + Pos.X
            local y = math.floor(i / LoadRange^2) % LoadRange + Pos.Y
            local z = math.floor(i / LoadRange) % LoadRange + Pos.Z
            local ChunkPos = Vector3.new(x,y,z)

            if table.find(LoadedChunks, ChunkPos) then continue end
            table.insert(LoadedChunks, ChunkPos)
            task.wait()

            table.insert(Cache, MainModule.GenChunk(x,y,z))
        end
    end
end)



while task.wait() do
    for i, data in pairs(Cache) do
        task.wait()
        print(#data)
        MainModule.LoadChunk(data)
        Cache[i] = nil
    end
end