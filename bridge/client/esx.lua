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

function Framework.GetPlayerData()
    local esx = InitializeESX()
    return esx.GetPlayerData()
end

function Framework.IsPlayerLoaded()
    local esx = InitializeESX()
    return esx.IsPlayerLoaded()
end

function Framework.GetPlayerIdentifier()
    local esx = InitializeESX()
    local playerData = esx.GetPlayerData()
    return playerData.identifier
end

function Framework.GetPlayerJob()
    local esx = InitializeESX()
    local playerData = esx.GetPlayerData()
    return playerData.job
end

function Framework.HasJob(jobName)
    local esx = InitializeESX()
    local playerData = esx.GetPlayerData()
    return playerData.job and playerData.job.name == jobName
end

function Framework.RegisterPlayerLoadedEvent(callback)
    RegisterNetEvent('esx:playerLoaded', function(xPlayer)
        callback(xPlayer)
    end)
end

function Framework.RegisterJobUpdateEvent(callback)
    RegisterNetEvent('esx:setJob', function(job)
        callback(job)
    end)
end

return Framework