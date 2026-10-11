--[[
    Kyvweer.gg Combined
    - Panel name: Kyvweer.gg
    - Incluye sistema de configs en workspace
    - Incluye Spoofer estilo Kicia
    - Carga el script principal (UE/Kyvweer)
]]

if getgenv().KyvweerGG and getgenv().KyvweerGG.Unload then
    pcall(getgenv().KyvweerGG.Unload)
end

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players           = game:GetService("Players")
local HttpService       = game:GetService("HttpService")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local LocalPlayer       = Players.LocalPlayer

local K = {
    connections = {},
    cleanups    = {},
    destroyed   = false,
}
getgenv().KyvweerGG = K

-------------------------------------------------
-- 1. CARPETA DE CONFIGS EN WORKSPACE
-------------------------------------------------
local function ensureConfigFolder()
    local name = "KyvweerConfigs"
    local folder = workspace:FindFirstChild(name)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = name
        folder.Parent = workspace
    end
    return folder
end

local ConfigFolder = ensureConfigFolder()

local Config = {}
function Config.Save(name, data)
    if type(name) ~= "string" or name == "" then
        return false, "nombre inválido"
    end
    local ok, encoded = pcall(HttpService.JSONEncode, HttpService, data)
    if not ok then return false, "error encode" end

    local old = ConfigFolder:FindFirstChild(name)
    if old then old:Destroy() end

    local sv = Instance.new("StringValue")
    sv.Name  = name
    sv.Value = encoded
    sv.Parent = ConfigFolder
    return true
end

function Config.Load(name)
    local sv = ConfigFolder:FindFirstChild(name)
    if not sv or not sv:IsA("StringValue") then
        return nil, "no existe"
    end
    local ok, decoded = pcall(HttpService.JSONDecode, HttpService, sv.Value)
    if not ok then return nil, "error decode" end
    return decoded
end

function Config.List()
    local t = {}
    for _, v in ipairs(ConfigFolder:GetChildren()) do
        if v:IsA("StringValue") then
            table.insert(t, v.Name)
        end
    end
    return t
end

function Config.Delete(name)
    local sv = ConfigFolder:FindFirstChild(name)
    if sv then
        sv:Destroy()
        return true
    end
    return false
end

K.Config = Config
K.ConfigFolder = ConfigFolder
getgenv().KyvweerConfig = Config

-------------------------------------------------
-- 2. SPOFER ESTILO KICIA
-------------------------------------------------
local Spoofer = {}
Spoofer.__index = Spoofer

function Spoofer.new()
    return setmetatable({
        enabled     = false,
        connections = {},
    }, Spoofer)
end

function Spoofer:Arm()
    if self.enabled then return end
    self.enabled = true

    local function onCharacter(char)
        if not char then return end
        task.wait(0.25)
        -- Aquí puedes poner spoofs reales (nombre, description, clothes, etc.)
        -- Estructura lista para expandir
    end

    if LocalPlayer.Character then
        onCharacter(LocalPlayer.Character)
    end

    table.insert(self.connections, LocalPlayer.CharacterAdded:Connect(onCharacter))
end

function Spoofer:Disarm()
    self.enabled = false
    for _, c in ipairs(self.connections) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(self.connections)
end

local AvatarSpoofer = Spoofer.new()
K.AvatarSpoofer = AvatarSpoofer
getgenv().KyvweerSpoofer = AvatarSpoofer

-------------------------------------------------
-- 3. CARGAR SCRIPT PRINCIPAL (Kyvweer / UE)
-------------------------------------------------
local function loadMainScript()
    local url = "https://raw.githubusercontent.com/Kyvoxz/Kyvweer.lol.gg/refs/heads/main/Kyvweer.lol.gg.lua"
    local source = game:HttpGet(url)
    local fn, err = loadstring(source)
    if not fn then
        warn("[Kyvweer.gg] Error al compilar script principal:", err)
        return false
    end

    local ok, result = pcall(fn)
    if not ok then
        warn("[Kyvweer.gg] Error al ejecutar script principal:", result)
        return false
    end
    return true
end

task.spawn(function()
    local success = loadMainScript()
    if success then
        AvatarSpoofer:Arm()
        print("[Kyvweer.gg] Cargado | Configs → workspace.KyvweerConfigs | Spofer activo")
    else
        warn("[Kyvweer.gg] Falló la carga del script principal")
    end
end)

-------------------------------------------------
-- 4. UNLOAD
-------------------------------------------------
function K.Unload()
    if K.destroyed then return end
    K.destroyed = true

    AvatarSpoofer:Disarm()

    for _, c in ipairs(K.connections) do
        pcall(function() c:Disconnect() end)
    end
    for _, f in ipairs(K.cleanups) do
        pcall(f)
    end

    if getgenv().KyvweerGG == K then
        getgenv().KyvweerGG = nil
    end
end

print("[Kyvweer.gg] Combined listo")
