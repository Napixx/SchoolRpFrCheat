-- Admin Script épuré avec Fluent UI
-- Héberger sur GitHub et charger via: loadstring(game:HttpGet("URL"))()

local player = game.Players.LocalPlayer

-- Charger Fluent UI et Addons
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

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

-- Création des onglets (ordre modifié pour mettre Visuel avant Paramètres)
local Tabs = {
    Main = Window:AddTab({ Title = "Admin", Icon = "shield" }),
    Player = Window:AddTab({ Title = "Joueur", Icon = "user" }),
    Visuals = Window:AddTab({ Title = "Visuel", Icon = "eye" }),
    Settings = Window:AddTab({ Title = "Paramètres", Icon = "settings" })
}

local Options = Fluent.Options
local isEnColleActive = false
local enColleConnection = nil

--------------------------------------------------------------------------------
-- ONGLET ADMIN
--------------------------------------------------------------------------------

Tabs.Main:AddButton({
    Title = "🔥 Admin Max (60)",
    Description = "Définir le rang admin au maximum",
    Callback = function()
        local adminRank = player:FindFirstChild("AdminRank")
        if adminRank then
            adminRank.Value = 60
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
    if not enColle then return end

    if Options.AntiColle.Value then
        isEnColleActive = true
        enColleConnection = game:GetService("RunService").Heartbeat:Connect(function()
            enColle.Value = 0
        end)
    else
        isEnColleActive = false
        if enColleConnection then
            enColleConnection:Disconnect()
            enColleConnection = nil
        end
    end
end)

--------------------------------------------------------------------------------
-- ONGLET JOUEUR
--------------------------------------------------------------------------------

Tabs.Player:AddButton({
    Title = "🍎 Nourriture Infini",
    Description = "Restaurer la nourriture au maximum",
    Callback = function()
        local food = player:FindFirstChild("Food")
        if food then
            coroutine.wrap(function()
                while true do
                    food.Value = 100
                    wait()
                end
            end)()
        end
    end
})

Tabs.Player:AddButton({
    Title = "ℹ️ Infos Joueur",
    Description = "Afficher vos statistiques",
    Callback = function()
        local adminRank = player:FindFirstChild("AdminRank")
        local food = player:FindFirstChild("Food")
        local enColle = player:FindFirstChild("EnColle")

        local info = "=== INFOS JOUEUR ===\n"
        info = info .. "👤 Nom: " .. player.Name .. "\n"
        info = info .. "🔑 AdminRank: " .. (adminRank and adminRank.Value or "Non trouvé") .. "\n"
        info = info .. "🍎 Food: " .. (food and food.Value or "Non trouvé") .. "\n"
        info = info .. "🏫 EnColle: " .. (enColle and enColle.Value or "Non trouvé") .. "\n"
        info = info .. "🛡️ Anti-Détention: " .. (isEnColleActive and "ACTIF" or "INACTIF")

        Window:Dialog({
            Title = "Statistiques",
            Content = info,
            Buttons = { { Title = "OK" } }
        })
    end
})

--------------------------------------------------------------------------------
-- ONGLET VISUEL (ESP Joueurs)
--------------------------------------------------------------------------------

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local highlights = {}
local points = {}
local ESP_Enabled = false

local MAX_DISTANCE = 150 -- Distance max pour contour, au-delà ce sera un point

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

local function clearAllESP()
    for plr, _ in pairs(highlights) do
        clearESP(plr)
    end
    for plr, _ in pairs(points) do
        clearESP(plr)
    end
end

local function getColor(plr)
    local adminRank = plr:FindFirstChild("AdminRank")
    local teamChangeId = plr:FindFirstChild("TeamChangeId")
    local Grade = plr:FindFirstChild("Grade")

    if adminRank and adminRank.Value > 0 then
        return Color3.fromRGB(255, 0, 0) -- rouge
    elseif teamChangeId and teamChangeId.Value > 0 then
        return Color3.fromRGB(255, 165, 0) -- orange
    elseif Grade and typeof(Grade.Value) == "string" and string.find(Grade.Value, "Élève") then
        return Color3.fromRGB(255, 255, 255) -- blanc
    else
        return nil -- ou autre couleur
    end
end


local function createPoint(plr, color)
    local char = plr.Character
    if not char then return end

    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    if points[plr] then
        points[plr].Frame.BackgroundColor3 = color
        return
    end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESPPoint"
    billboard.Adornee = root
    billboard.Size = UDim2.new(0, 10, 0, 10)
    billboard.AlwaysOnTop = true
    billboard.ResetOnSpawn = false

    local frame = Instance.new("Frame")
    frame.Name = "Frame"
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = color
    frame.BorderSizePixel = 0
    frame.BackgroundTransparency = 0.5 -- un peu transparent
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    frame.Parent = billboard

    -- Cercle (rond)
    frame.ClipsDescendants = true
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0) -- Cercle parfait
    corner.Parent = frame

    billboard.Parent = char
    points[plr] = billboard
end

local function createHighlight(plr, color)
    local char = plr.Character
    if not char then return end

    if highlights[plr] then
        highlights[plr].OutlineColor = color
        return
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = "CustomESPHighlight"
    highlight.Adornee = char
    highlight.FillTransparency = 1
    highlight.OutlineTransparency = 0
    highlight.OutlineColor = color
    highlight.Parent = char
    highlights[plr] = highlight
end

local function updateESP()
    if not ESP_Enabled then
        clearAllESP()
        return
    end

    local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not localRoot then return end

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local root = plr.Character.HumanoidRootPart
            local dist = (localRoot.Position - root.Position).Magnitude
            local color = getColor(plr)

            if dist <= MAX_DISTANCE then
                -- Proche : Highlight contour, supprimer point s'il existe
                if points[plr] then
                    points[plr]:Destroy()
                    points[plr] = nil
                end
                createHighlight(plr, color)
            else
                -- Loin : Afficher point, supprimer highlight s'il existe
                if highlights[plr] then
                    highlights[plr]:Destroy()
                    highlights[plr] = nil
                end
                createPoint(plr, color)
            end
        else
            clearESP(plr)
        end
    end
end

RunService.Heartbeat:Connect(function()
    if ESP_Enabled then
        updateESP()
    else
        clearAllESP()
    end
end)

-- Toggle ESP dans onglet Visuel
local ESPToggle = Tabs.Visuals:AddToggle("ESPToggle", {
    Title = "ESP Joueurs",
    Description = "Afficher contour proche ou point rond loin selon AdminRank et TeamChangeId",
    Default = false,
})

ESPToggle:OnChanged(function(value)
    ESP_Enabled = value
    if not ESP_Enabled then
        clearAllESP()
    end
end)

-- Keybind pour toggle ESP (touche N)
Tabs.Visuals:AddKeybind("ESPToggleKeybind", {
    Title = "N - Activer/Désactiver ESP",
    Mode = "Toggle",
    Default = "N",
    Callback = function(active)
        ESPToggle:SetValue(active)
    end
})

--------------------------------------------------------------------------------
-- ONGLET PARAMÈTRES (sans configuration)
--------------------------------------------------------------------------------

-- Tu peux ajouter ici d'autres options dans Paramètres si besoin, mais
-- pour l'instant la section configuration est retirée car inutile.

--------------------------------------------------------------------------------
-- FERMETURE ET CLEANUP
--------------------------------------------------------------------------------

game.Players.PlayerRemoving:Connect(function(plr)
    if plr == player and enColleConnection then
        enColleConnection:Disconnect()
    end
end)

--------------------------------------------------------------------------------
-- INITIALISATION
--------------------------------------------------------------------------------

Window:SelectTab(1) -- Onglet Admin par défaut
SaveManager:LoadAutoloadConfig()
