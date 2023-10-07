--!native


local Main = require(game.ReplicatedStorage.Shared.MainModule)

local start = os.clock()

local ChunkSize = 20

for i=0, ChunkSize ^ 3 - 1 do
    local x = i % ChunkSize
    local y = math.floor(i / ChunkSize^2) % ChunkSize
    local z = math.floor(i / ChunkSize) % ChunkSize
    
    task.wait()
    Main.GenChunk(x,y,z)
end



warn("took : " .. os.clock() - start)