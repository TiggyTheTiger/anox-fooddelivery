local Framework = {}
local QBX = nil

local function InitializeQBX()
    if not QBX then
        QBX = exports['qb-core']:GetCoreObject()
        if not QBX then
            error('Failed to get QBX object!')
        end
    end
    return QBX
end

function Framework.GetPlayerData()
    local qbx = InitializeQBX()
    return qbx.Functions.GetPlayerData()
end

function Framework.IsPlayerLoaded()
    local qbx = InitializeQBX()
    local PlayerData = qbx.Functions.GetPlayerData()
    return PlayerData and PlayerData.citizenid ~= nil
end

function Framework.GetPlayerIdentifier()
    local qbx = InitializeQBX()
    local PlayerData = qbx.Functions.GetPlayerData()
    return PlayerData.citizenid
end

function Framework.GetPlayerJob()
    local qbx = InitializeQBX()
    local PlayerData = qbx.Functions.GetPlayerData()
    return PlayerData.job
end

function Framework.HasJob(jobName)
    local qbx = InitializeQBX()
    local PlayerData = qbx.Functions.GetPlayerData()
    return PlayerData.job and PlayerData.job.name == jobName
end

function Framework.RegisterPlayerLoadedEvent(callback)
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
        local qbx = InitializeQBX()
        local PlayerData = qbx.Functions.GetPlayerData()
        callback(PlayerData)
    end)
end

function Framework.RegisterJobUpdateEvent(callback)
    RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
        callback(job)
    end)
end

return Framework