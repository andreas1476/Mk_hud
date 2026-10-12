local PlayerData = {}
local loggedIn = false
local lastPayload = nil

local function refreshData()
    local ok, data = pcall(function() return exports.qbx_core:GetPlayerData() end)
    if ok and data and data.citizenid then
        PlayerData = data
        loggedIn = true
    end
end

local function getBlackMoney()
    local money = PlayerData.money
    if money and money[Config.BlackMoneyAccount] then
        return money[Config.BlackMoneyAccount]
    end
    if Config.BlackMoneyItem and GetResourceState('ox_inventory') == 'started' then
        local ok, count = pcall(function()
            return exports.ox_inventory:Search('count', Config.BlackMoneyItem)
        end)
        if ok and count then return count end
    end
    return 0
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    refreshData()
    SendNUIMessage({ action = 'visible', show = true })
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    loggedIn = false
    PlayerData = {}
    SendNUIMessage({ action = 'visible', show = false })
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(data)
    if data then
        PlayerData = data
        loggedIn = true
    end
end)

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    Wait(500)
    refreshData()
    SendNUIMessage({ action = 'init', name = Config.ServerName, unit = Config.SpeedUnit })
    SendNUIMessage({ action = 'visible', show = loggedIn })
end)

CreateThread(function()
    Wait(1000)
    SendNUIMessage({ action = 'init', name = Config.ServerName, unit = Config.SpeedUnit })
    refreshData()
    SendNUIMessage({ action = 'visible', show = loggedIn })
end)

-- Skjul standard GTA HUD
CreateThread(function()
    if not Config.HideDefaultHud then return end
    local components = { 1, 2, 3, 4, 6, 7, 8, 9 }
    while true do
        for i = 1, #components do
            HideHudComponentThisFrame(components[i])
        end
        Wait(0)
    end
end)

-- Sørg for at minimappet vises, når spilleren er logget ind.
CreateThread(function()
    Wait(500)
    while true do
        DisplayRadar(loggedIn)
        Wait(1000)
    end
end)

-- Black money opdateres langsommere (item-tælling er dyrere)
local blackMoney = 0
CreateThread(function()
    while true do
        if loggedIn then blackMoney = getBlackMoney() end
        Wait(1500)
    end
end)

-- Hoved-loop
CreateThread(function()
    while true do
        local wait = 250

        if loggedIn then
            local ped = PlayerPedId()

            local maxHealth = GetEntityMaxHealth(ped) - 100
            local health = math.max(GetEntityHealth(ped) - 100, 0)
            local healthPct = maxHealth > 0 and math.floor(health / maxHealth * 100) or 0
            if IsEntityDead(ped) then healthPct = 0 end

            local armor = GetPedArmour(ped)
            local meta = PlayerData.metadata or {}
            local money = PlayerData.money or {}
            local job = PlayerData.job or {}

            local inVeh = IsPedInAnyVehicle(ped, false)
            local speed, fuel, showFuel = 0, 0, false

            if inVeh then
                wait = 100
                local veh = GetVehiclePedIsIn(ped, false)
                local mult = Config.SpeedUnit == 'mph' and 2.236936 or 3.6
                speed = math.floor(GetEntitySpeed(veh) * mult + 0.5)
                local class = GetVehicleClass(veh)
                showFuel = class ~= 13 -- cykler har ikke brændstof
                fuel = Entity(veh).state.fuel or GetVehicleFuelLevel(veh)
                fuel = math.floor(math.max(0, math.min(100, fuel)))
            end

            local payload = {
                action = 'update',
                health = healthPct,
                armor = armor,
                hunger = math.floor(meta.hunger or 100),
                thirst = math.floor(meta.thirst or 100),
                cash = money.cash or 0,
                black = blackMoney,
                job = job.label or 'Arbejdsløs',
                grade = job.grade and job.grade.name or '',
                inVehicle = inVeh,
                speed = speed,
                fuel = fuel,
                showFuel = showFuel,
                paused = IsPauseMenuActive()
            }

            local encoded = json.encode(payload)
            if encoded ~= lastPayload then
                lastPayload = encoded
                SendNUIMessage(payload)
            end
        end

        Wait(wait)
    end
end)
