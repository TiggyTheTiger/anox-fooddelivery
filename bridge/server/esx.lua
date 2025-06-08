local Framework = {}
local ESX = nil

local function InitializeESX()
    if not ESX then
        ESX = exports['es_extended']:getSharedObject()
        if not ESX then
            error('Failed to get ESX shared object!')
        end
    end
    return ESX
end

function Framework.GetPlayer(playerId)
    local esx = InitializeESX()
    return esx.GetPlayerFromId(playerId)
end

function Framework.GetPlayerIdentifier(playerId)
    local esx = InitializeESX()
    local xPlayer = esx.GetPlayerFromId(playerId)
    return xPlayer and xPlayer.identifier or nil
end

function Framework.GetPlayers()
    local esx = InitializeESX()
    return esx.GetPlayers()
end

function Framework.AddMoney(playerId, amount, moneyType)
    local esx = InitializeESX()
    local xPlayer = esx.GetPlayerFromId(playerId)
    if not xPlayer then return false end
    moneyType = moneyType or 'money'
    if moneyType == 'cash' then
        moneyType = 'money'
    elseif moneyType == 'bank' then
        moneyType = 'bank'
    end
    xPlayer.addMoney(amount)
    return true
end

function Framework.RemoveMoney(playerId, amount, moneyType)
    local esx = InitializeESX()
    local xPlayer = esx.GetPlayerFromId(playerId)
    if not xPlayer then return false end
    moneyType = moneyType or 'money'
    if moneyType == 'cash' then
        moneyType = 'money'
    elseif moneyType == 'bank' then
        moneyType = 'bank'
    end
    xPlayer.removeMoney(amount)
    return true
end

function Framework.GetMoney(playerId, moneyType)
    local esx = InitializeESX()
    local xPlayer = esx.GetPlayerFromId(playerId)
    if not xPlayer then return 0 end
    moneyType = moneyType or 'money'
    if moneyType == 'cash' then
        return xPlayer.getMoney()
    elseif moneyType == 'bank' then
        return xPlayer.getAccount('bank').money
    end
    return xPlayer.getMoney()
end

function Framework.GetPlayerJob(playerId)
    local esx = InitializeESX()
    local xPlayer = esx.GetPlayerFromId(playerId)
    return xPlayer and xPlayer.job or nil
end

function Framework.SetPlayerJob(playerId, jobName, grade)
    local esx = InitializeESX()
    local xPlayer = esx.GetPlayerFromId(playerId)
    if not xPlayer then return false end
    grade = grade or 0
    xPlayer.setJob(jobName, grade)
    return true
end

function Framework.AddItem(playerId, itemName, count, metadata)
    local esx = InitializeESX()
    local xPlayer = esx.GetPlayerFromId(playerId)
    if not xPlayer then return false end
    xPlayer.addInventoryItem(itemName, count, metadata)
    return true
end

function Framework.RemoveItem(playerId, itemName, count)
    local esx = InitializeESX()
    local xPlayer = esx.GetPlayerFromId(playerId)
    if not xPlayer then return false end
    xPlayer.removeInventoryItem(itemName, count)
    return true
end

function Framework.GetItemCount(playerId, itemName)
    local esx = InitializeESX()
    local xPlayer = esx.GetPlayerFromId(playerId)
    if not xPlayer then return 0 end
    local item = xPlayer.getInventoryItem(itemName)
    return item and item.count or 0
end

function Framework.RegisterPlayerLoadedEvent(callback)
    RegisterNetEvent('esx:playerLoaded', function(playerId, xPlayer)
        callback(playerId, xPlayer)
    end)
end

function Framework.RegisterPlayerDroppedEvent(callback)
    RegisterNetEvent('esx:playerDropped', function(playerId, reason)
        callback(playerId, reason)
    end)
end

function Framework.RegisterJobUpdateEvent(callback)
    RegisterNetEvent('esx:setJob', function(playerId, job, lastJob)
        callback(playerId, job, lastJob)
    end)
end

function Framework.DoesPlayerExist(playerId)
    local esx = InitializeESX()
    return esx.GetPlayerFromId(playerId) ~= nil
end

function Framework.GetPlayerName(playerId)
    local esx = InitializeESX()
    local xPlayer = esx.GetPlayerFromId(playerId)
    return xPlayer and xPlayer.getName() or nil
end

return Framework