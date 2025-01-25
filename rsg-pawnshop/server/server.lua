local RSGCore = exports['rsg-core']:GetCoreObject()

RegisterServerEvent('rsg-pawnshop:server:OpenMenu')
AddEventHandler('rsg-pawnshop:server:OpenMenu', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local sellableItems = {}

    for itemName, itemConfig in pairs(Config.SellableItems) do
        local itemAmount = Player.Functions.GetItemByName(itemName) and Player.Functions.GetItemByName(itemName).amount or 0
        
        if itemAmount > 0 then
            sellableItems[itemName] = {
                price = itemConfig.price,
                amount = itemAmount
            }
        end
    end

    TriggerClientEvent('rsg-pawnshop:client:OpenMenu', src, sellableItems)
end)

RegisterServerEvent('rsg-pawnshop:server:SellItem')
AddEventHandler('rsg-pawnshop:server:SellItem', function(itemName, amount)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local item = Player.Functions.GetItemByName(itemName)
    if not item then return end
    
    if item.amount >= amount then
        local price = Config.SellableItems[itemName].price * amount
        
        if Player.Functions.RemoveItem(itemName, amount) then
            Player.Functions.AddMoney('cash', price, "pawn-shop-sell")
            TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[itemName], "remove")
            TriggerClientEvent('pawnshop:client:SellSuccess', src, RSGCore.Shared.Items[itemName].label, amount, price)
            TriggerClientEvent('pawnshop:client:SellComplete', src)
        end
    else
        TriggerClientEvent('RSGCore:Notify', src, 'You don\'t have enough items!', 'error')
    end
end)

RegisterServerEvent('rsg-pawnshop:server:ProcessSale')
AddEventHandler('rsg-pawnshop:server:ProcessSale', function(itemName, quantity, price)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)

    if not itemName or not quantity or not price then
        TriggerClientEvent('RSGCore:Notify', src, 'Invalid sale parameters', 'error')
        return
    end

    local itemConfig = Config.SellableItems[itemName]
    if not itemConfig then
        TriggerClientEvent('RSGCore:Notify', src, 'Cannot sell this item', 'error')
        return
    end

    local currentAmount = Player.Functions.GetItemByName(itemName) and Player.Functions.GetItemByName(itemName).amount or 0
    if quantity <= 0 or quantity > currentAmount then
        TriggerClientEvent('RSGCore:Notify', src, 'Invalid quantity', 'error')
        return
    end

    local totalValue = quantity * itemConfig.price

    if Player.Functions.RemoveItem(itemName, quantity) then
        Player.Functions.AddMoney('cash', totalValue, "pawn-shop-sell")
        TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[itemName], "remove")
        TriggerClientEvent('pawnshop:client:SellSuccess', src, RSGCore.Shared.Items[itemName].label, quantity, totalValue)
        TriggerClientEvent('pawnshop:client:SellComplete', src)
    end
end)