-- Admin Script avec Fluent UI Library
-- À héberger sur GitHub et charger avec loadstring(game:HttpGet("URL_DE_VOTRE_SCRIPT"))()

local player = game.Players.LocalPlayer

-- Charger la librairie Fluent
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- Créer la fenêtre principale
local Window = Fluent:CreateWindow({
    Title = "Admin Panel",
    SubTitle = "Alpha 1.0 - by Napixx",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl
})

-- Créer les onglets
local Tabs = {
    Main = Window:AddTab({ Title = "Admin", Icon = "shield" }),
    Player = Window:AddTab({ Title = "Joueur", Icon = "user" }),
    Settings = Window:AddTab({ Title = "Paramètres", Icon = "settings" })
}

local Options = Fluent.Options

-- Variables globales
local isEnColleActive = false
local enColleConnection = nil
local refreshing = false

-- Notification de chargement
Fluent:Notify({
    Title = "Admin Panel",
    Content = "Script chargé avec succès!",
    SubContent = "Prêt à utiliser",
    Duration = 5
})

-- ================================
-- ONGLET ADMIN
-- ================================

Tabs.Main:AddParagraph({
    Title = "🔑 Administration",
    Content = "Contrôles administrateur avancés\nModifiez vos privilèges en jeu"
})

local AdminRankSlider = Tabs.Main:AddSlider("AdminRank", {
    Title = "Rang Admin",
    Description = "Définir votre niveau d'administration",
    Default = 0,
    Min = 0,
    Max = 100,
    Rounding = 1,
    Callback = function(Value)
        if refreshing then return end
        local adminRank = player:FindFirstChild("AdminRank")
        if adminRank then
            adminRank.Value = Value
            })
        else
            Fluent:Notify({
                Title = "Erreur",
                Content = "AdminRank non trouvé!",
                Duration = 3
            })
        end
    end
})

Tabs.Main:AddButton({
    Title = "🔥 Admin Max (60)",
    Description = "Définir le rang admin au maximum",
Callback = function(Value)
    if refreshing then return end
    local adminRank = player:FindFirstChild("AdminRank")
    if adminRank then
        adminRank.Value = Value
    else
        Fluent:Notify({
            Title = "Erreur",
            Content = "AdminRank non trouvé!",
            Duration = 3
        })
    end
end

    end
})

Tabs.Main:AddParagraph({
    Title = "🛡️ Protection",
    Content = "Systèmes de protection automatique"
})

local AntiColleToggle = Tabs.Main:AddToggle("AntiColle", {
    Title = "Anti-Détention",
    Description = "Empêche automatiquement la détention",
    Default = false
})

AntiColleToggle:OnChanged(function()
    local enColle = player:FindFirstChild("EnColle")
    if not enColle then
        Fluent:Notify({
            Title = "Erreur",
            Content = "EnColle non trouvé!",
            Duration = 3
        })
        return
    end

    if Options.AntiColle.Value then
        isEnColleActive = true
        enColleConnection = game:GetService("RunService").Heartbeat:Connect(function()
            if enColle then
                enColle.Value = 0
            end
        end)
        Fluent:Notify({
            Title = "Anti-Détention",
            Content = "Protection activée!",
            Duration = 3
        })
    else
        isEnColleActive = false
        if enColleConnection then
            enColleConnection:Disconnect()
            enColleConnection = nil
        end
        Fluent:Notify({
            Title = "Anti-Détention",
            Content = "Protection désactivée",
            Duration = 3
        })
    end
end)

-- ================================
-- ONGLET JOUEUR
-- ================================

Tabs.Player:AddParagraph({
    Title = "📊 Statistiques",
    Content = "Gestion des statistiques du joueur"
})

local FoodSlider = Tabs.Player:AddSlider("Food", {
    Title = "Nourriture",
    Description = "Niveau de nourriture du joueur",
    Default = 50,
    Min = 0,
    Max = 100,
    Rounding = 1,
    Callback = function(Value)
        if refreshing then return end
        local food = player:FindFirstChild("Food")
        if food then
            food.Value = Value
            Fluent:Notify({
                Title = "Nourriture",
                Content = "Définie à " .. Value,
                Duration = 2
            })
        else
            Fluent:Notify({
                Title = "Erreur",
                Content = "Food non trouvé!",
                Duration = 3
            })
        end
    end
})

Tabs.Player:AddButton({
    Title = "🍎 Nourriture Max",
    Description = "Restaurer la nourriture au maximum",
    Callback = function()
        local food = player:FindFirstChild("Food")
        if food then
            food.Value = 100
            FoodSlider:SetValue(100)
            Fluent:Notify({
                Title = "Nourriture Max",
                Content = "Nourriture restaurée à 100!",
                Duration = 3
            })
        else
            Fluent:Notify({
                Title = "Erreur",
                Content = "Food non trouvé!",
                Duration = 3
            })
        end
    end
})

Tabs.Player:AddButton({
    Title = "ℹ️ Informations Joueur",
    Description = "Afficher toutes les statistiques",
    Callback = function()
        local adminRank = player:FindFirstChild("AdminRank")
        local food = player:FindFirstChild("Food")
        local enColle = player:FindFirstChild("EnColle")

        local info = "=== 📊 INFORMATIONS JOUEUR ===\n"
        info = info .. "👤 Nom: " .. player.Name .. "\n"
        info = info .. "🔑 AdminRank: " .. (adminRank and tostring(adminRank.Value) or "Non trouvé") .. "\n"
        info = info .. "🍎 Food: " .. (food and tostring(food.Value) or "Non trouvé") .. "\n"
        info = info .. "🏫 EnColle: " .. (enColle and tostring(enColle.Value) or "Non trouvé") .. "\n"
        info = info .. "🛡️ Anti-Détention: " .. (isEnColleActive and "ACTIF" or "INACTIF")

        print(info)

        Window:Dialog({
            Title = "Informations Joueur",
            Content = info,
            Buttons = {
                {
                    Title = "OK",
                    Callback = function()
                        print("Dialog fermé")
                    end
                }
            }
        })
    end
})

local AutoRefreshToggle = Tabs.Player:AddToggle("AutoRefresh", {
    Title = "Auto-Actualisation",
    Description = "Met à jour automatiquement les sliders avec les vraies valeurs",
    Default = true
})

local function autoRefresh()
    if Options.AutoRefresh.Value then
        refreshing = true

        local adminRank = player:FindFirstChild("AdminRank")
        local food = player:FindFirstChild("Food")

        if adminRank and AdminRankSlider then
            AdminRankSlider:SetValue(adminRank.Value)
        end

        if food and FoodSlider then
            FoodSlider:SetValue(food.Value)
        end

        refreshing = false
    end
end

game:GetService("RunService").Heartbeat:Connect(function()
    if Options.AutoRefresh and Options.AutoRefresh.Value then
        autoRefresh()
    end
end)

-- ================================
-- KEYBINDS
-- ================================

local AdminKeybind = Tabs.Main:AddKeybind("AdminKeybind", {
    Title = "Admin Rapide",
    Mode = "Toggle",
    Default = "F1",
    Callback = function(Value)
        if Value then
            local adminRank = player:FindFirstChild("AdminRank")
            if adminRank then
                adminRank.Value = 60
                AdminRankSlider:SetValue(60)
                Fluent:Notify({
                    Title = "Keybind Admin",
                    Content = "Admin activé via F1!",
                    Duration = 2
                })
            end
        end
    end
})

local FoodKeybind = Tabs.Player:AddKeybind("FoodKeybind", {
    Title = "Food Rapide",
    Mode = "Toggle",
    Default = "F2",
    Callback = function(Value)
        if Value then
            local food = player:FindFirstChild("Food")
            if food then
                food.Value = 100
                FoodSlider:SetValue(100)
                Fluent:Notify({
                    Title = "Keybind Food",
                    Content = "Nourriture max via F2!",
                    Duration = 2
                })
            end
        end
    end
})

-- ================================
-- CONFIGURATION
-- ================================

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("AdminPanel")
SaveManager:SetFolder("AdminPanel/Configs")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

Fluent:Notify({
    Title = "🎉 Prêt!",
    Content = "Admin Panel complètement chargé",
    SubContent = "F1: Admin | F2: Food",
    Duration = 8
})

SaveManager:LoadAutoloadConfig()

game.Players.PlayerRemoving:Connect(function(plr)
    if plr == player and enColleConnection then
        enColleConnection:Disconnect()
    end
end)
