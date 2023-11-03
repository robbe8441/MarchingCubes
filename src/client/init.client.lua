--!native
local UIS = game:GetService("UserInputService")

local MainModule = require(game.ReplicatedStorage.Shared.MainModule)
local Settings = require(game.ReplicatedStorage.Shared.GameSettigs)
local Plr = game.Players.LocalPlayer
local Char = Plr.Character or Plr.CharacterAdded:Wait()

local LoadRange = Settings.MapSize

--task.wait(5)

local CurrentlyLoaded = {}
local ChunkOrder = {}

for i=0, LoadRange^3 - 1 do
    local y = (math.floor(i / LoadRange^2) % LoadRange)
    if y > 5 then continue end
    table.insert(ChunkOrder, i)
end

function GetDis(i)
    local x = i % LoadRange - LoadRange/2
    local y = (math.floor(i / LoadRange^2) % LoadRange)
    local z = (math.floor(i / LoadRange) % LoadRange) - LoadRange/2
    return Vector3.new(x,y,z).Magnitude
end

table.sort(ChunkOrder, function(a,b)
    return GetDis(a) < GetDis(b)
end)


function GetLOD(dis)
    if dis > 1500 then return 8 end
    if dis > 1000 then return 4 end
    if dis > 500 then return 2 end
    return 1
end

function OnUpdate()
    for i,v in pairs(CurrentlyLoaded) do 
        local x, y, z = i:match("(%d+)y(%d+)z(%d+)")
        local dis = Vector3.new(x,y,z) * Settings.ChunkSize * Settings.BlockSize
        if (Char:GetPivot().Position - dis).Magnitude > 5000 then v:Unload() CurrentlyLoaded[i]=nil break end
    end

    for _,i in ChunkOrder do
        local PlayerChunk = Char:GetPivot().Position // (Settings.ChunkSize * Settings.BlockSize)
        local x = i % LoadRange - LoadRange/2 + PlayerChunk.X
        local y = (math.floor(i / LoadRange^2) % LoadRange)
        local z = (math.floor(i / LoadRange) % LoadRange) - LoadRange/2 + PlayerChunk.Z
        local TabPos = string.format("x%iy%iz%i", x,y,z)
        
        local dis = (Char:GetPivot().Position - (Vector3.new(x,y,z) * Settings.ChunkSize * Settings.BlockSize))
        local LOD = GetLOD(dis.Magnitude)
        
        local Loaded = CurrentlyLoaded[TabPos]
        if Loaded and Loaded.Info.LOD == LOD then continue end
        
        local Mesh = MainModule.GenChunk(x,y,z, LOD)
        Mesh:Load()
        if Loaded then Loaded:Unload() end
        CurrentlyLoaded[TabPos] = Mesh
        return
    end
end

while task.wait() do
    OnUpdate()
end


