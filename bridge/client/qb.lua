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

function Framework.GetPlayerData()
    local qb = InitializeQB()
    return qb.Functions.GetPlayerData()
end

function Framework.IsPlayerLoaded()
    local qb = InitializeQB()
    local PlayerData = qb.Functions.GetPlayerData()
    return PlayerData and PlayerData.citizenid ~= nil
end

function Framework.GetPlayerIdentifier()
    local qb = InitializeQB()
    local PlayerData = qb.Functions.GetPlayerData()
    return PlayerData.citizenid
end

function Framework.GetPlayerJob()
    local qb = InitializeQB()
    local PlayerData = qb.Functions.GetPlayerData()
    return PlayerData.job
end

function Framework.HasJob(jobName)
    local qb = InitializeQB()
    local PlayerData = qb.Functions.GetPlayerData()
    return PlayerData.job and PlayerData.job.name == jobName
end

function Framework.RegisterPlayerLoadedEvent(callback)
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
        local qb = InitializeQB()
        local PlayerData = qb.Functions.GetPlayerData()
        callback(PlayerData)
    end)
end

function Framework.RegisterJobUpdateEvent(callback)
    RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
        callback(job)
    end)
end

return Framework