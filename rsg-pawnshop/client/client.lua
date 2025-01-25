-- Debug utilities
local debug = true
local function debugPrint(msg)
    if debug then
        print('^3Debug: ^7' .. tostring(msg))
    end
end

-- Core initialization
local RSGCore = exports['rsg-core']:GetCoreObject()
local lib = exports['ox_lib']
local menuOpen = false
local menuCooldown = 0
local MENU_COOLDOWN = 500

-- Prompt initialization
local prompts = {}
local promptGroup = GetRandomIntInRange(0, 0xffffff)

-- Function declarations (in correct order)
local function OpenPawnShopMenu()
    debugPrint('Opening menu attempt')
    
    if menuOpen then
        exports.ox_lib:hideContext()
        menuOpen = false
        Wait(200)
        debugPrint('Forced close of existing menu')
    end
    
    local PlayerData = RSGCore.Functions.GetPlayerData()
    if not PlayerData then 
        debugPrint('No player data')
        return 
    end
    
    local inventory = PlayerData.items
    if not inventory then 
        debugPrint('No inventory')
        return 
    end
    
    local contextOptions = {
        {
            title = 'Pawn Shop',
            icon = 'fas fa-store',
            disabled = true
        }
    }

    local itemCount = 0
    for k, v in pairs(inventory) do
        if Config.SellableItems[v.name] then
            itemCount = itemCount + 1
            table.insert(contextOptions, {
                title = v.label or v.name,
                description = ('Price: $%s | Amount: %s'):format(Config.SellableItems[v.name].price, v.amount),
                icon = 'fas fa-dollar-sign',
                onSelect = function()
                    menuOpen = false
                    exports.ox_lib:hideContext()
                    Wait(100)
                    TriggerEvent('pawnshop:sellItem', {
                        itemName = v.name,
                        price = Config.SellableItems[v.name].price,
                        amount = v.amount
                    })
                end
            })
            debugPrint('Added item: ' .. (v.label or v.name))
        end
    end

    if itemCount > 0 then
        debugPrint('Registering menu with ' .. itemCount .. ' items')
        exports.ox_lib:registerContext({
            id = 'pawnshop_menu',
            title = 'Pawn Shop',
            options = contextOptions,
            onClose = function()
                debugPrint('Menu closed via onClose')
                menuOpen = false
            end
        })
        Wait(100)
        menuOpen = true
        exports.ox_lib:showContext('pawnshop_menu')
        debugPrint('Menu opened successfully')
    else
        debugPrint('No items to sell')
        TriggerEvent('RSGCore:Notify', 'No items to sell!', 'error')
    end
end

local function ForceOpenMenu()
    local currentTime = GetGameTimer()
    
    if currentTime - menuCooldown < MENU_COOLDOWN then
        debugPrint('Menu on cooldown')
        return
    end
    
    menuCooldown = currentTime
    if menuOpen then
        exports.ox_lib:hideContext()
        menuOpen = false
        Wait(200)
    end
    
    OpenPawnShopMenu()
end

-- Initialize Prompts
CreateThread(function()
    Wait(2000)
    if not Config or not Config.Locations then 
        debugPrint('Config or Locations missing')
        return 
    end

    for k, v in pairs(Config.Locations) do
        local prompt = PromptRegisterBegin()
        PromptSetControlAction(prompt, 0x760A9C6F) -- G key
        PromptSetText(prompt, CreateVarString(10, 'LITERAL_STRING', "Open Pawn Shop"))
        PromptSetEnabled(prompt, true)
        PromptSetVisible(prompt, true)
        PromptSetHoldMode(prompt, true)
        PromptSetGroup(prompt, promptGroup)
        PromptRegisterEnd(prompt)
        prompts[k] = prompt

        -- Create blips
        local blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, v.coords)
        SetBlipSprite(blip, Config.Blip.sprite, 1)
        SetBlipScale(blip, Config.Blip.scale)
        Citizen.InvokeNative(0x9CB1A1623062F402, blip, Config.Blip.name)
        debugPrint('Created blip for location ' .. k)
    end
end)

-- Prompt check thread
CreateThread(function()
    while true do
        Wait(0)
        local playerCoords = GetEntityCoords(PlayerPedId())
        local isNearShop = false
        
        for k, v in pairs(Config.Locations) do
            local distance = #(playerCoords - v.coords)
            if distance <= 2.0 then
                isNearShop = true
                local group = CreateVarString(10, 'LITERAL_STRING', "Pawn Shop")
                PromptSetActiveGroupThisFrame(promptGroup, group)
                if PromptHasHoldModeCompleted(prompts[k]) then
                    OpenPawnShopMenu()
                end
            end
        end
        
        if not isNearShop then
            Wait(1000)
        end
    end
end)

-- Event handlers
RegisterNetEvent('pawnshop:sellItem')
AddEventHandler('pawnshop:sellItem', function(data)
    debugPrint('Selling item')
    menuOpen = false
    
    local input = exports['ox_lib']:inputDialog('Sell Item', {
        {
            type = 'number',
            label = 'Amount to sell (Max: ' .. data.amount .. ')',
            default = 1,
            min = 1,
            max = data.amount
        }
    })
    
    if input then
        local amount = tonumber(input[1])
        if amount and amount > 0 and amount <= data.amount then
            TriggerServerEvent('rsg-pawnshop:server:SellItem', data.itemName, amount)
        else
            TriggerEvent('RSGCore:Notify', 'Invalid amount!', 'error')
            Wait(500)
            ForceOpenMenu()
        end
    else
        debugPrint('Input dialog canceled')
        Wait(500)
        ForceOpenMenu()
    end
end)

RegisterNetEvent('pawnshop:client:SellSuccess')
AddEventHandler('pawnshop:client:SellSuccess', function(itemLabel, amount, price)
    debugPrint('Sale success')
    TriggerEvent('RSGCore:Notify', 'Sold ' .. amount .. 'x ' .. itemLabel .. ' for $' .. price, 'success')
    Wait(500)
    ForceOpenMenu()
end)