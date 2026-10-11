--[[
    Kyvweer.lol Combined (UE + Kicia Spoofer + Workspace Configs)
    Panel name: Kyvweer.lol
    Auto-crea carpeta de configs en workspace
]]

if getgenv().KyvweerCombined and getgenv().KyvweerCombined.Unload then
    pcall(getgenv().KyvweerCombined.Unload)
end

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local K = {
    connections = {},
    cleanups = {},
    destroyed = false,
}
getgenv().KyvweerCombined = K

-- ====================== FOLDER DE CONFIGS EN WORKSPACE ======================
local function ensureWorkspaceConfigFolder()
    local folderName = "KyvweerConfigs"
    local folder = workspace:FindFirstChild(folderName)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = folderName
        folder.Parent = workspace
    end
    return folder
end

local ConfigFolder = ensureWorkspaceConfigFolder()

-- Helper para guardar/cargar configs en el Folder del workspace
local ConfigSystem = {}
function ConfigSystem.Save(name, data)
    if type(name) ~= "string" or name == "" then return false, "nombre inválido" end
    local ok, encoded = pcall(HttpService.JSONEncode, HttpService, data)
    if not ok then return false, "error encode" end

    local existing = ConfigFolder:FindFirstChild(name)
    if existing then existing:Destroy() end

    local val = Instance.new("StringValue")
    val.Name = name
    val.Value = encoded
    val.Parent = ConfigFolder
    return true
end

function ConfigSystem.Load(name)
    local val = ConfigFolder:FindFirstChild(name)
    if not val or not val:IsA("StringValue") then return nil, "no existe" end
    local ok, decoded = pcall(HttpService.JSONDecode, HttpService, val.Value)
    if not ok then return nil, "error decode" end
    return decoded
end

function ConfigSystem.List()
    local list = {}
    for _, v in ipairs(ConfigFolder:GetChildren()) do
        if v:IsA("StringValue") then
            table.insert(list, v.Name)
        end
    end
    return list
end

function ConfigSystem.Delete(name)
    local val = ConfigFolder:FindFirstChild(name)
    if val then val:Destroy() return true end
    return false
end

K.ConfigSystem = ConfigSystem
K.ConfigFolder = ConfigFolder

-- ====================== SPOFER ESTILO KICIA ======================
local Spoofer = {}
Spoofer.__index = Spoofer

function Spoofer.new()
    local self = setmetatable({
        enabled = false,
        connections = {},
        original = {},
    }, Spoofer)
    return self
end

function Spoofer:Arm()
    if self.enabled then return end
    self.enabled = true

    -- Ejemplo de spoof básico de avatar / character (estilo kicia)
    -- Puedes expandir esto con más propiedades
    local function applySpoof(character)
        if not character then return end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            -- Aquí puedes agregar spoofs reales (nombre, description, etc)
            -- Por seguridad solo dejamos la estructura
        end
    end

    local function onCharacter(char)
        task.wait(0.3)
        applySpoof(char)
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

-- ====================== CARGAR EL SCRIPT PRINCIPAL (Kyvweer / UE) ======================
local function loadKyvweer()
    local source = game:HttpGet("https://raw.githubusercontent.com/Kyvoxz/Kyvweer.lol.gg/refs/heads/main/Kyvweer.lol.gg.lua")
    local fn, err = loadstring(source)
    if not fn then
        warn("[Kyvweer Combined] Error al cargar script principal:", err)
        return false
    end

    local ok, result = pcall(fn)
    if not ok then
        warn("[Kyvweer Combined] Error al ejecutar script principal:", result)
        return false
    end
    return true
end

-- Ejecutar
task.spawn(function()
    local success = loadKyvweer()
    if success then
        -- Activar spofer automáticamente
        AvatarSpoofer:Arm()
        print("[Kyvweer.lol] Cargado correctamente | Configs en workspace.KyvweerConfigs | Spofer activo")
    else
        warn("[Kyvweer.lol] Falló la carga del script principal")
    end
end)

-- ====================== UNLOAD ======================
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

    if getgenv().KyvweerCombined == K then
        getgenv().KyvweerCombined = nil
    end
end

-- Exponer helpers globales útiles
getgenv().KyvweerConfig = ConfigSystem
getgenv().KyvweerSpoofer = AvatarSpoofer
