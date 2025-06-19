-- Admin Script épuré avec Fluent UI
-- Héberger sur GitHub et charger via: loadstring(game:HttpGet("URL"))()

local player = game.Players.LocalPlayer

-- Charger Fluent UI
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "School FR RP Script",
    SubTitle = " Pré-Alpha by Napixx",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Admin", Icon = "shield" }),
    Player = Window:AddTab({ Title = "Joueur", Icon = "user" }),
    Settings = Window:AddTab({ Title = "Paramètres", Icon = "settings" })
}

local Options = Fluent.Options
local isEnColleActive = false
local enColleConnection = nil

-- ================================
-- ONGLET ADMIN
-- ================================

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

-- ================================
-- ONGLET JOUEUR
-- ================================

Tabs.Player:AddButton({
    Title = "🍎 Nourriture Max",
    Description = "Restaurer la nourriture au maximum",
    Callback = function()
        local food = player:FindFirstChild("Food")
        if food then
            food.Value = 100
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

-- ================================
-- KEYBINDS
-- ================================

Tabs.Main:AddKeybind("AdminKeybind", {
    Title = "F1 - Admin Max",
    Mode = "Toggle",
    Default = "F1",
    Callback = function(active)
        if active then
            local adminRank = player:FindFirstChild("AdminRank")
            if adminRank then adminRank.Value = 60 end
        end
    end
})

Tabs.Player:AddKeybind("FoodKeybind", {
    Title = "F2 - Nourriture Max",
    Mode = "Toggle",
    Default = "F2",
    Callback = function(active)
        if active then
            local food = player:FindFirstChild("Food")
            if food then food.Value = 100 end
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
SaveManager:LoadAutoloadConfig()

game.Players.PlayerRemoving:Connect(function(plr)
    if plr == player and enColleConnection then
        enColleConnection:Disconnect()
    end
end)
