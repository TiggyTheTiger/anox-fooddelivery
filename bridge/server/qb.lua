local Framework = {}
local QBCore = nil

local function InitializeQB()
    if not QBCore then
        QBCore = exports['qb-core']:GetCoreObject()
        if not QBCore then
            error('Failed to get QB-Core object!')
        end
    end
    return QBCore
end

function Framework.GetPlayer(playerId)
    local qb = InitializeQB()
    return qb.Functions.GetPlayer(playerId)
end

function Framework.GetPlayerIdentifier(playerId)
    local qb = InitializeQB()
    local Player = qb.Functions.GetPlayer(playerId)
    return Player and Player.PlayerData.citizenid or nil
end

function Framework.GetPlayers()
    local qb = InitializeQB()
    local players = {}
    for playerId, _ in pairs(qb.Functions.GetPlayers()) do
        table.insert(players, playerId)
    end
    return players
end

function Framework.AddMoney(playerId, amount, moneyType)
    local qb = InitializeQB()
    local Player = qb.Functions.GetPlayer(playerId)
    if not Player then return false end
    moneyType = moneyType or 'cash'
    if moneyType == 'money' then
        moneyType = 'cash'
    end
    Player.Functions.AddMoney(moneyType, amount)
    return true
end

function Framework.RemoveMoney(playerId, amount, moneyType)
    local qb = InitializeQB()
    local Player = qb.Functions.GetPlayer(playerId)
    if not Player then return false end
    moneyType = moneyType or 'cash'
    if moneyType == 'money' then
        moneyType = 'cash'
    end
    Player.Functions.RemoveMoney(moneyType, amount)
    return true
end

function Framework.GetMoney(playerId, moneyType)
    local qb = InitializeQB()
    local Player = qb.Functions.GetPlayer(playerId)
    if not Player then return 0 end
    moneyType = moneyType or 'cash'
    if moneyType == 'money' then
        moneyType = 'cash'
    end
    return Player.PlayerData.money[moneyType] or 0
end

function Framework.GetPlayerJob(playerId)
    local qb = InitializeQB()
    local Player = qb.Functions.GetPlayer(playerId)
    return Player and Player.PlayerData.job or nil
end

function Framework.SetPlayerJob(playerId, jobName, grade)
    local qb = InitializeQB()
    local Player = qb.Functions.GetPlayer(playerId)
    if not Player then return false end
    grade = grade or 0
    Player.Functions.SetJob(jobName, grade)
    return true
end

function Framework.AddItem(playerId, itemName, count, metadata)
    local qb = InitializeQB()
    local Player = qb.Functions.GetPlayer(playerId)
    if not Player then return false end
    count = count or 1
    Player.Functions.AddItem(itemName, count, false, metadata)
    return true
end

function Framework.RemoveItem(playerId, itemName, count)
    local qb = InitializeQB()
    local Player = qb.Functions.GetPlayer(playerId)
    if not Player then return false end
    count = count or 1
    Player.Functions.RemoveItem(itemName, count)
    return true
end

function Framework.GetItemCount(playerId, itemName)
    local qb = InitializeQB()
    local Player = qb.Functions.GetPlayer(playerId)
    if not Player then return 0 end
    local item = Player.Functions.GetItemByName(itemName)
    return item and item.amount or 0
end

function Framework.RegisterPlayerLoadedEvent(callback)
    RegisterNetEvent('QBCore:Server:PlayerLoaded', function(Player)
        local playerId = Player.PlayerData.source
        callback(playerId, Player)
    end)
end

function Framework.RegisterPlayerDroppedEvent(callback)
    RegisterNetEvent('QBCore:Server:PlayerDropped', function(Player, reason)
        local playerId = Player.PlayerData.source
        callback(playerId, reason)
    end)
end

function Framework.RegisterJobUpdateEvent(callback)
    RegisterNetEvent('QBCore:Server:SetJob', function(Player, job)
        local playerId = Player.PlayerData.source
        callback(playerId, job)
    end)
end

function Framework.DoesPlayerExist(playerId)
    local qb = InitializeQB()
    return qb.Functions.GetPlayer(playerId) ~= nil
end

function Framework.GetPlayerName(playerId)
    local qb = InitializeQB()
    local Player = qb.Functions.GetPlayer(playerId)
    if not Player then return nil end
    local charinfo = Player.PlayerData.charinfo
    return charinfo.firstname .. ' ' .. charinfo.lastname
end

return Framework