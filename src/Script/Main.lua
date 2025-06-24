-- ================================================================================
-- SCHOOL FR RP SCRIPT - VERSION ORGANISÉE AVEC FLY SIMPLIFIÉ
-- Pré-Alpha by Napixx
-- ================================================================================

-- ================================================================================
-- VARIABLES GLOBALES ET SERVICES
-- ================================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

-- Charger Fluent UI et Addons
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- Variables pour Anti-Détention
local isEnColleActive = false
local enColleConnection = nil

-- Variables pour ESP
local highlights = {}
local points = {}
local ESP_Enabled = false
local espConnection = nil
local MAX_DISTANCE = 150

-- Variables pour le système de vol simplifié
local flySpeed = 50
local flyEnabled = false
local ctrl = {f = 0, b = 0, l = 0, r = 0}
local flyBodyObjects = {}

-- ================================================================================
-- CRÉATION DE L'INTERFACE
-- ================================================================================

-- Création de la fenêtre principale
local Window = Fluent:CreateWindow({
    Title = "School FR RP Script",
    SubTitle = "Pré-Alpha by Napixx",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl
})

-- Création des onglets
local Tabs = {
    Main = Window:AddTab({ Title = "Générale ", Icon = "home" }),
    Player = Window:AddTab({ Title = "Joueur", Icon = "user" }),
    Visuals = Window:AddTab({ Title = "Visuel", Icon = "eye" }),
    Settings = Window:AddTab({ Title = "Paramètres", Icon = "settings" })
}

local Options = Fluent.Options

-- ================================================================================
-- FONCTIONS UTILITAIRES
-- ================================================================================

-- Fonction pour obtenir les informations du joueur
local function getPlayerStats()
    local adminRank = player:FindFirstChild("AdminRank")
    local food = player:FindFirstChild("Food")
    local enColle = player:FindFirstChild("EnColle")
    
    return {
        name = player.Name,
        adminRank = adminRank and adminRank.Value or "Non trouvé",
        food = food and food.Value or "Non trouvé",
        enColle = enColle and enColle.Value or "Non trouvé",
        antiDetention = isEnColleActive and "ACTIF" or "INACTIF",
        flyStatus = flyEnabled and "ACTIF" or "INACTIF"
    }
end

-- Fonction pour afficher une notification
local function showNotification(title, message, duration)
    Fluent:Notify({
        Title = title,
        Content = message,
        Duration = duration or 3
    })
end

-- ================================================================================
-- FONCTIONS FLY SYSTEM SIMPLIFIÉ
-- ================================================================================

-- Nettoyer les objets de vol
local function cleanupFlyObjects()
    for _, obj in pairs(flyBodyObjects) do
        if obj and obj.Parent then
            obj:Destroy()
        end
    end
    flyBodyObjects = {}
end

-- Fonction principale de vol simplifiée
local function toggleFly()
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChildWhichIsA("Humanoid")
    if not humanoid then return end

    if flyEnabled then
        -- Désactiver le vol
        flyEnabled = false
        cleanupFlyObjects()

        -- Restaurer les états du Humanoid
        for _, state in pairs(Enum.HumanoidStateType:GetEnumItems()) do
            humanoid:SetStateEnabled(state, true)
        end
        humanoid:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
        humanoid.PlatformStand = false
        
        showNotification("Vol", "Vol désactivé")
    else
        -- Activer le vol
        flyEnabled = true
        
        -- Logique de vol simplifiée pour R6 et R15
        spawn(function()
            local rigType = humanoid.RigType
            local bodyPart = rigType == Enum.HumanoidRigType.R6 and character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
            
            if not bodyPart then return end
            
            local bodyGyro = Instance.new("BodyGyro")
            bodyGyro.P = 9e4
            bodyGyro.maxTorque = Vector3.new(9e9, 9e9, 9e9)
            bodyGyro.cframe = bodyPart.CFrame
            bodyGyro.Parent = bodyPart
            table.insert(flyBodyObjects, bodyGyro)
            
            local bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.velocity = Vector3.new(0, 0.1, 0)
            bodyVelocity.maxForce = Vector3.new(9e9, 9e9, 9e9)
            bodyVelocity.Parent = bodyPart
            table.insert(flyBodyObjects, bodyVelocity)
            
            humanoid.PlatformStand = true
            
            while flyEnabled and character.Parent and humanoid.Health > 0 do
                wait()
                
                -- Calcul de la direction sans accélération progressive
                local moveVector = Vector3.new(0, 0, 0)
                
                if ctrl.f == 1 or ctrl.b == -1 then
                    moveVector = moveVector + (workspace.CurrentCamera.CoordinateFrame.lookVector * (ctrl.f + ctrl.b))
                end
                
                if ctrl.l == -1 or ctrl.r == 1 then
                    moveVector = moveVector + (workspace.CurrentCamera.CoordinateFrame.rightVector * (ctrl.l + ctrl.r))
                end
                
                -- Appliquer la vitesse constante
                bodyVelocity.velocity = moveVector * flySpeed
                
                -- Orienter le personnage selon la caméra (sans animation)
                bodyGyro.cframe = workspace.CurrentCamera.CoordinateFrame
            end
            
            -- Nettoyage final
            humanoid.PlatformStand = false
            cleanupFlyObjects()
        end)
        
        showNotification("Vol", "Vol activé - Vitesse: " .. flySpeed)
    end
end

-- Gestion des contrôles de vol
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or not flyEnabled then return end
    
    if input.KeyCode == Enum.KeyCode.W then
        ctrl.f = 1
    elseif input.KeyCode == Enum.KeyCode.S then
        ctrl.b = -1
    elseif input.KeyCode == Enum.KeyCode.A then
        ctrl.l = -1
    elseif input.KeyCode == Enum.KeyCode.D then
        ctrl.r = 1
    elseif input.KeyCode == Enum.KeyCode.E then
        -- Monter
        local character = player.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            character.HumanoidRootPart.CFrame = character.HumanoidRootPart.CFrame * CFrame.new(0, 2, 0)
        end
    elseif input.KeyCode == Enum.KeyCode.Q then
        -- Descendre
        local character = player.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            character.HumanoidRootPart.CFrame = character.HumanoidRootPart.CFrame * CFrame.new(0, -2, 0)
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed or not flyEnabled then return end
    
    if input.KeyCode == Enum.KeyCode.W then
        ctrl.f = 0
    elseif input.KeyCode == Enum.KeyCode.S then
        ctrl.b = 0
    elseif input.KeyCode == Enum.KeyCode.A then
        ctrl.l = 0
    elseif input.KeyCode == Enum.KeyCode.D then
        ctrl.r = 0
    end
end)

-- Mettre à jour la vitesse de vol
local function updateFlySpeed(newSpeed)
    flySpeed = newSpeed
end

-- ================================================================================
-- FONCTIONS ESP (VERSION OPTIMISÉE)
-- ================================================================================

-- Nettoyer l'ESP d'un joueur spécifique
local function clearESP(plr)
    if highlights[plr] then
        highlights[plr]:Destroy()
        highlights[plr] = nil
    end
    if points[plr] then
        points[plr]:Destroy()
        points[plr] = nil
    end
end

-- Nettoyer tout l'ESP
local function clearAllESP()
    for plr, _ in pairs(highlights) do
        clearESP(plr)
    end
    for plr, _ in pairs(points) do
        clearESP(plr)
    end
    highlights = {}
    points = {}
end

-- Obtenir la couleur selon le statut du joueur
local function getPlayerColor(plr)
    local adminRank = plr:FindFirstChild("AdminRank")
    local teamChangeId = plr:FindFirstChild("TeamChangeId")
    local Grade = plr:FindFirstChild("Grade")

    -- Vérifier si les valeurs existent et sont chargées
    if adminRank and adminRank.Value and adminRank.Value > 0 then
        return Color3.fromRGB(255, 0, 0) -- Rouge pour admin
    elseif teamChangeId and teamChangeId.Value and teamChangeId.Value > 0 then
        return Color3.fromRGB(255, 165, 0) -- Orange pour staff
    elseif Grade and typeof(Grade.Value) == "string" and Grade.Value ~= "" and string.find(Grade.Value, "Élève") then
        return Color3.fromRGB(255, 255, 255) -- Blanc pour élèves
    else
        -- Couleur par défaut pour les nouveaux joueurs ou ceux sans données
        return Color3.fromRGB(0, 255, 0) -- Vert par défaut
    end
end

-- Créer un point ESP simple
local function createESPPoint(plr, color)
    local char = plr.Character
    if not char then return end

    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    -- Réutiliser l'ancien point si possible
    if points[plr] then
        points[plr].Frame.BackgroundColor3 = color
        return
    end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESPPoint_" .. plr.Name
    billboard.Adornee = root
    billboard.Size = UDim2.new(0, 10, 0, 10)
    billboard.AlwaysOnTop = true
    billboard.ResetOnSpawn = false

    local frame = Instance.new("Frame")
    frame.Name = "Frame"
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = color
    frame.BorderSizePixel = 0
    frame.BackgroundTransparency = 0.5
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    frame.Parent = billboard

    -- Style circulaire simple
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = frame

    billboard.Parent = char
    points[plr] = billboard
end

-- Créer un highlight ESP simple
local function createESPHighlight(plr, color)
    local char = plr.Character
    if not char then return end

    -- Réutiliser l'ancien highlight si possible
    if highlights[plr] then
        highlights[plr].OutlineColor = color
        return
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = "CustomESPHighlight_" .. plr.Name
    highlight.Adornee = char
    highlight.FillTransparency = 1
    highlight.OutlineTransparency = 0
    highlight.OutlineColor = color
    highlight.Parent = char
    highlights[plr] = highlight
end

-- Mettre à jour l'ESP (optimisé)
local function updateESP()
    if not ESP_Enabled then return end

    local localChar = player.Character
    if not localChar then return end
    
    local localRoot = localChar:FindFirstChild("HumanoidRootPart")
    if not localRoot then return end

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player then
            local char = plr.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local root = char.HumanoidRootPart
                local distance = (localRoot.Position - root.Position).Magnitude
                local color = getPlayerColor(plr)

                if distance <= MAX_DISTANCE then
                    -- Joueur proche : utiliser highlight
                    if points[plr] then
                        points[plr]:Destroy()
                        points[plr] = nil
                    end
                    createESPHighlight(plr, color)
                else
                    -- Joueur lointain : utiliser point
                    if highlights[plr] then
                        highlights[plr]:Destroy()
                        highlights[plr] = nil
                    end
                    createESPPoint(plr, color)
                end
            else
                -- Pas de personnage, nettoyer
                clearESP(plr)
            end
        end
    end
end

-- Activer/Désactiver l'ESP
local function toggleESP(enabled)
    ESP_Enabled = enabled
    
    if enabled then
        if not espConnection then
            espConnection = RunService.Heartbeat:Connect(updateESP)
        end
    else
        if espConnection then
            espConnection:Disconnect()
            espConnection = nil
        end
        clearAllESP()
    end
end

-- ================================================================================
-- ONGLET Main
-- ================================================================================

Tabs.Main:AddButton({
    Title = "🔥 Fake Admin",
    Description = "Définir le rang admin au maximum",
    Callback = function()
        local adminRank = player:FindFirstChild("AdminRank")
        if adminRank then
            adminRank.Value = 60
            showNotification("Admin", "Rang admin défini à 60!")
        else
            showNotification("Erreur", "AdminRank non trouvé!")
        end
    end
})

local AntiColleToggle = Tabs.Main:AddToggle("AntiColle", {
    Title = "Anti-Détention",
    Description = "Empêche automatiquement la détention",
    Default = false
})

AntiColleToggle:OnChanged(function()
    local enColle = player:FindFirstChild("EnColle")
    if not enColle then 
        showNotification("Erreur", "EnColle non trouvé!")
        return 
    end

    if Options.AntiColle.Value then
        isEnColleActive = true
        enColleConnection = RunService.Heartbeat:Connect(function()
            if enColle.Value ~= 0 then
                enColle.Value = 0
            end
        end)
        showNotification("Anti-Détention", "Protection activée!")
    else
        isEnColleActive = false
        if enColleConnection then
            enColleConnection:Disconnect()
            enColleConnection = nil
        end
        showNotification("Anti-Détention", "Protection désactivée!")
    end
end)

-- ================================================================================
-- ONGLET JOUEUR
-- ================================================================================

-- Section Vol
Tabs.Player:AddSection("Système de Vol")

local FlyToggle = Tabs.Player:AddToggle("FlyToggle", {
    Title = "Vol",
    Description = "Activer/désactiver le système de vol",
    Default = false
})

FlyToggle:OnChanged(function(value)
    if value ~= flyEnabled then
        toggleFly()
    end
end)

Tabs.Player:AddKeybind("FlyKeybind", {
    Title = "Raccourci Vol",
    Mode = "Toggle",
    Default = "P",
    Callback = function(active)
        FlyToggle:SetValue(active)
    end
})

Tabs.Player:AddSlider("FlySpeed", {
    Title = "Vitesse de Vol",
    Description = "Ajuster la vitesse du vol (20-100)",
    Default = 20,
    Min = 0,
    Max = 35,
    Rounding = 0,
    Increment = 5,
    Callback = function(value)
        updateFlySpeed(value)
    end
})

Tabs.Player:AddParagraph({
    Title = "Contrôles de Vol",
    Content = "WASD: Se déplacer\nE: Monter\nQ: Descendre\nP: Activer/Désactiver (par défaut)"
})

-- Section Vitesse
Tabs.Player:AddSection("Capacités")

local SpeedToggle = Tabs.Player:AddToggle("SpeedToggle", {
    Title = "Speed",
    Description = "Activer/désactiver la Vitesse",
    Default = false
})

SpeedToggle:OnChanged(function(value)
    local effectFolder = player:FindFirstChild("Effect")
    local speedEffect = effectFolder and effectFolder:FindFirstChild("SpeedEffect")

    if speedEffect then
        if value then
            speedEffect.Value = 1
            showNotification("Speed", "Vitesse activée")
        else
            speedEffect.Value = 0
            showNotification("Speed", "Vitesse désactivée")
        end
    else
        showNotification("Erreur", "SpeedEffect ou Humanoid non trouvé")
    end
end)

Tabs.Player:AddKeybind("SpeedEffectKeybind", {
    Title = "Raccourci Vitesse",
    Mode = "Toggle",
    Default = "B",
    Callback = function(active)
        SpeedToggle:SetValue(active)
    end
})

Tabs.Player:AddButton({
    Title = "🍎 Nourriture Infinie",
    Description = "Restaurer la nourriture au maximum en continu",
    Callback = function()
        local food = player:FindFirstChild("Food")
        if food then
            coroutine.wrap(function()
                while food and food.Parent do
                    food.Value = 100
                    wait(0.1)
                end
            end)()
            showNotification("Nourriture", "Nourriture infinie activée!")
        else
            showNotification("Erreur", "Food non trouvé!")
        end
    end
})

Tabs.Player:AddButton({
    Title = "💰 Reset Food",
    Description = "Remettre la nourriture à zéro",
    Callback = function()
        local food = player:FindFirstChild("Food")
        if food then
            food.Value = 0
            showNotification("Food", "Nourriture remise à zéro!")
        else
            showNotification("Erreur", "Food non trouvé!")
        end
    end
})

Tabs.Player:AddButton({
    Title = "ℹ️ Informations Joueur",
    Description = "Afficher vos statistiques complètes",
    Callback = function()
        local stats = getPlayerStats()
        
        local info = "=== INFORMATIONS JOUEUR ===\n\n"
        info = info .. "👤 Nom: " .. stats.name .. "\n"
        info = info .. "🔑 AdminRank: " .. stats.adminRank .. "\n"
        info = info .. "🍎 Food: " .. stats.food .. "\n"
        info = info .. "🏫 EnColle: " .. stats.enColle .. "\n"
        info = info .. "🛡️ Anti-Détention: " .. stats.antiDetention .. "\n"
        info = info .. "✈️ Vol: " .. stats.flyStatus .. "\n"
        info = info .. "👁️ ESP: " .. (ESP_Enabled and "ACTIF" or "INACTIF")

        Window:Dialog({
            Title = "Statistiques Joueur",
            Content = info,
            Buttons = {
                {
                    Title = "OK",
                    Callback = function()
                        print("Statistiques fermées")
                    end
                }
            }
        })
    end
})

-- ================================================================================
-- ONGLET VISUEL
-- ================================================================================

local ESPToggle = Tabs.Visuals:AddToggle("ESPToggle", {
    Title = "ESP Joueurs",
    Description = "Contour pour joueurs proches, points pour joueurs lointains",
    Default = false,
})

ESPToggle:OnChanged(function(value)
    toggleESP(value)
end)

Tabs.Visuals:AddKeybind("ESPToggleKeybind", {
    Title = "Raccourci ESP",
    Mode = "Toggle",
    Default = "N",
    Callback = function(active)
        ESPToggle:SetValue(active)
    end
})

Tabs.Visuals:AddSlider("ESPDistance", {
    Title = "Distance ESP",
    Description = "Distance maximale pour les contours (au-delà = points)",
    Default = 5,
    Min = 0,
    Max = 10,
    Rounding = 0,
    Increment = 1,
    Callback = function(value)
        MAX_DISTANCE = value * 70
    end
})

-- Légende des couleurs
Tabs.Visuals:AddSection("Légende Couleurs ESP")
Tabs.Visuals:AddParagraph({
    Title = "🔴 Rouge",
    Content = "Administrateurs (joueur possedent un minmum de permision)"
})
Tabs.Visuals:AddParagraph({
    Title = "🟠 Orange", 
    Content = "Employer (joueur possedent un travaille)"
})
Tabs.Visuals:AddParagraph({
    Title = "⚪ Blanc",
    Content = "Élèves"
})
Tabs.Visuals:AddParagraph({
    Title = "🟢 Vert",
    Content = "Autres joueurs"
})

-- ================================================================================
-- ONGLET PARAMÈTRES
-- ================================================================================

Tabs.Settings:AddButton({
    Title = "🔄 Recharger Script",
    Description = "Recharger complètement le script",
    Callback = function()
        Window:Dialog({
            Title = "Confirmation",
            Content = "Êtes-vous sûr de vouloir recharger le script?\nToutes les configurations actuelles seront perdues.",
            Buttons = {
                {
                    Title = "Oui",
                    Callback = function()
                        -- Nettoyage complet
                        if enColleConnection then
                            enColleConnection:Disconnect()
                        end
                        if espConnection then
                            espConnection:Disconnect()
                        end
                        clearAllESP()
                        cleanupFlyObjects()
                        
                        -- Fermer la fenêtre
                        Window:Destroy()
                        
                        -- Recharger le script (vous devrez adapter cette partie)
                        showNotification("Script", "Rechargement...")
                    end
                },
                {
                    Title = "Non",
                    Callback = function()
                        print("Rechargement annulé")
                    end
                }
            }
        })
    end
})

Tabs.Settings:AddButton({
    Title = "🗑️ Nettoyer ESP",
    Description = "Supprimer tous les éléments ESP restants",
    Callback = function()
        clearAllESP()
        showNotification("Nettoyage", "ESP nettoyé!")
    end
})

Tabs.Settings:AddButton({
    Title = "🛑 Arrêter Vol",
    Description = "Forcer l'arrêt du système de vol",
    Callback = function()
        if flyEnabled then
            toggleFly()
        end
        cleanupFlyObjects()
        showNotification("Vol", "Système de vol forcé à l'arrêt!")
    end
})

-- ================================================================================
-- GESTION DES ÉVÉNEMENTS
-- ================================================================================

-- Nettoyage quand un joueur quitte
Players.PlayerRemoving:Connect(function(plr)
    clearESP(plr)
end)

-- Gestion des respawns
player.CharacterAdded:Connect(function(char)
    wait(0.7)
    local humanoid = char:FindFirstChildWhichIsA("Humanoid")
    if humanoid then
        humanoid.PlatformStand = false
    end
    
    -- Réinitialiser les variables de vol
    flyEnabled = false
    cleanupFlyObjects()
    if Options.FlyToggle then
        Options.FlyToggle:SetValue(false)
    end
end)

-- Nettoyage quand le joueur local quitte
Players.PlayerRemoving:Connect(function(plr)
    if plr == player then
        if enColleConnection then
            enColleConnection:Disconnect()
        end
        if espConnection then
            espConnection:Disconnect()
        end
        clearAllESP()
        cleanupFlyObjects()
    end
end)

-- ================================================================================
-- INITIALISATION
-- ================================================================================

-- Sélectionner l'onglet Admin par défaut
Window:SelectTab(1)

-- Charger la configuration automatique
SaveManager:LoadAutoloadConfig()

-- Initialiser AdminRank à 1 si trouvé
local adminRank = player:FindFirstChild("AdminRank")
if adminRank then
    adminRank.Value = 1
end

-- Notification de démarrage
showNotification("Script Chargé", "School FR RP Script avec Vol Simplifié prêt à l'emploi!", 5)

print("=== SCHOOL FR RP SCRIPT AVEC VOL SIMPLIFIÉ CHARGÉ ===")
print("Version: Pré-Alpha by Napixx + Fly System Simplifié")
print("Onglets: Admin, Joueur, Visuel, Paramètres")
print("Vol: Touche F pour activer/désactiver (par défaut)")
print("ESP: Touche N pour activer/désactiver")
print("Contrôles Vol: WASD + E/Q pour monter/descendre")
print("===============================================")
