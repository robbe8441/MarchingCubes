--!native





local UIS = game:GetService("UserInputService")

local MainModule = require(game.ReplicatedStorage.Shared.MainModule)
local Settings = require(game.ReplicatedStorage.Shared.GameSettigs)
local Plr = game.Players.LocalPlayer

local LoadRange = Settings.MapSize


--task.wait(5)

local ToLoad = {}


function GetLOD(dis)
    if dis > 1500 then return 16 end
    if dis > 1000 then return 8 end
    if dis > 600 then return 4 end
    if dis > 400 then return 2 end
    return 1
end



    
for i=0, LoadRange^3 - 1 do
    local x = i % LoadRange - LoadRange/2
    local y = (math.floor(i / LoadRange^2) % LoadRange)
    local z = (math.floor(i / LoadRange) % LoadRange) - LoadRange/2

    if y > 3 then continue end

    local dis = (game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()):GetPivot().Position -( Vector3.new(x,y,z) * Settings.ChunkSize * Settings.BlockSize)

    local Mesh = MainModule.GenChunk(x,y,z, GetLOD(dis.Magnitude))
    table.insert(ToLoad, Mesh)
    print(i / LoadRange^3 * 100 .. " %")
end


for i,v in pairs(ToLoad) do
    v:Load()
    task.wait()
end




