local Bridge = require('bridge/loader')
local Framework = Bridge.Load()
local playerReputation = {}
local activeOrders = {}
local assignedRestaurants = {}
local assignedDeliveryPoints = {}
local playerCooldowns = {}

local function InitializePlayer(playerId)
    local xPlayer = Framework.GetPlayer(playerId)
    if not xPlayer then return end
    local identifier = Framework.GetPlayerIdentifier(playerId)
    MySQL.Async.fetchScalar('SELECT reputation FROM anox_fooddelivery_reputation WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    }, function(reputation)
        playerReputation[playerId] = reputation or 0
        Framework.Debug("Player " .. identifier .. " initialized with reputation: " .. playerReputation[playerId], 'info')
    end)
end

local function SavePlayerReputation(playerId)
    local identifier = Framework.GetPlayerIdentifier(playerId)
    if not identifier then return end
    local reputation = playerReputation[playerId] or 0
    MySQL.Async.execute('INSERT INTO anox_fooddelivery_reputation (identifier, reputation) VALUES (@identifier, @reputation) ON DUPLICATE KEY UPDATE reputation = @reputation', {
        ['@identifier'] = identifier,
        ['@reputation'] = reputation
    })
    Framework.Debug("Saved reputation " .. reputation .. " for player " .. identifier, 'info')
end

local function GenerateOrderId()
    return string.format('%s-%s', os.time(), math.random(1000, 9999))
end

local function SelectRandomRestaurant(playerId)
    local availableRestaurants = {}
    for index, restaurant in ipairs(Config.Restaurants) do
        if not assignedRestaurants[index] or assignedRestaurants[index] == playerId then
            table.insert(availableRestaurants, {index = index, data = restaurant})
        end
    end
    if #availableRestaurants == 0 then
        return nil
    end
    local selected = availableRestaurants[math.random(#availableRestaurants)]
    assignedRestaurants[selected.index] = playerId
    return selected
end

local function SelectRandomDeliveryPoint(playerId)
    local availablePoints = {}
    for index, point in ipairs(Config.DeliveryPoints) do
        if not assignedDeliveryPoints[index] or assignedDeliveryPoints[index] == playerId then
            table.insert(availablePoints, {index = index, coords = point})
        end
    end
    if #availablePoints == 0 then
        return nil
    end
    local selected = availablePoints[math.random(#availablePoints)]
    assignedDeliveryPoints[selected.index] = playerId
    return selected
end

local function GenerateOrderItems(restaurant)
    local items = {}
    local numItems = math.random(2, 4)
    for i = 1, numItems do
        local itemData = restaurant.items[math.random(#restaurant.items)]
        table.insert(items, {
            name = itemData.name,
            quantity = math.random(itemData.min, itemData.max)
        })
    end
    return items
end

local function ClearPlayerAssignments(playerId)
    for index, assignedPlayer in pairs(assignedRestaurants) do
        if assignedPlayer == playerId then
            assignedRestaurants[index] = nil
        end
    end
    for index, assignedPlayer in pairs(assignedDeliveryPoints) do
        if assignedPlayer == playerId then
            assignedDeliveryPoints[index] = nil
        end
    end
    activeOrders[playerId] = nil
    Framework.Debug("Cleared all assignments for player " .. playerId, 'info')
end

local function ValidatePlayerPosition(playerId, targetCoords, maxDistance)
    local playerCoords = lib.callback.await('anox-fooddelivery:getPlayerCoords', playerId)
    if not playerCoords then return false end
    local distance = #(playerCoords - targetCoords)
    return distance <= maxDistance
end

lib.callback.register('anox-fooddelivery:getReputation', function(source)
    local playerId = source
    if not playerReputation[playerId] then
        InitializePlayer(playerId)
        Wait(100)
    end
    return playerReputation[playerId] or 0
end)

lib.callback.register('anox-fooddelivery:generateOrder', function(source)
    local playerId = source
    if playerCooldowns[playerId] and playerCooldowns[playerId] > os.time() then
        Framework.Debug("Player " .. playerId .. " attempted to generate order too quickly", 'warning')
        return nil
    end
    local restaurant = SelectRandomRestaurant(playerId)
    if not restaurant then
        Framework.Debug("No available restaurants for player " .. playerId, 'warning')
        Framework.Notify(playerId, _L('no_restaurants_title'), _L('no_restaurants_description'), 'warning')
        return nil
    end
    local deliveryPoint = SelectRandomDeliveryPoint(playerId)
    if not deliveryPoint then
        assignedRestaurants[restaurant.index] = nil
        Framework.Debug("No available delivery points for player " .. playerId, 'warning')
        Framework.Notify(playerId, _L('no_delivery_points_title'), _L('no_delivery_points_description'), 'warning')
        return nil
    end
    local order = {
        id = GenerateOrderId(),
        restaurant = {
            index = restaurant.index,
            name = restaurant.data.name,
            coords = restaurant.data.coords,
            blip = restaurant.data.blip
        },
        deliveryPoint = deliveryPoint.coords,
        deliveryIndex = deliveryPoint.index,
        items = GenerateOrderItems(restaurant.data),
        startTime = os.time(),
        pickedUp = false,
        delivered = false
    }
    activeOrders[playerId] = order
    playerCooldowns[playerId] = os.time() + 5
    Framework.Debug("Generated order " .. order.id .. " for player " .. playerId, 'success')
    return order
end)

lib.callback.register('anox-fooddelivery:updateReputation', function(source, action)
    local playerId = source
    local currentRep = playerReputation[playerId] or 0
    if action == 'cancelled' then
        playerReputation[playerId] = currentRep + Config.Reputation.cancelledOrder
        ClearPlayerAssignments(playerId)
        SavePlayerReputation(playerId)
        Framework.Debug("Player " .. playerId .. " cancelled order, new reputation: " .. playerReputation[playerId], 'info')
    end
    return playerReputation[playerId]
end)

lib.callback.register('anox-fooddelivery:validatePickup', function(source, orderId)
    local playerId = source
    local order = activeOrders[playerId]
    if not order or order.id ~= orderId then
        Framework.Debug("Invalid order ID " .. (orderId or "nil") .. " for player " .. playerId, 'warning')
        return false
    end
    if Config.AntiCheat.serverValidation then
        local isValid = ValidatePlayerPosition(playerId, order.restaurant.coords, Config.AntiCheat.maxDistance)
        if not isValid then
            Framework.Debug("Player " .. playerId .. " failed position validation at pickup", 'warning')
            return false
        end
    end
    order.pickedUp = true
    order.pickupTime = os.time()
    Framework.Debug("Player " .. playerId .. " picked up order " .. orderId, 'success')
    return true
end)

lib.callback.register('anox-fooddelivery:completeDelivery', function(source, orderId, deliveryTime)
    local playerId = source
    local order = activeOrders[playerId]
    if not order or order.id ~= orderId then
        Framework.Debug("Invalid order ID " .. (orderId or "nil") .. " for player " .. playerId, 'warning')
        return false
    end
    if Config.AntiCheat.serverValidation then
        local isValid = ValidatePlayerPosition(playerId, order.deliveryPoint, Config.AntiCheat.maxDistance)
        if not isValid then
            Framework.Debug("Player " .. playerId .. " failed position validation at delivery", 'warning')
            return false
        end
    end
    if not Framework.DoesPlayerExist(playerId) then return false end
    local baseReward = math.random(Config.Rewards.min, Config.Rewards.max)
    local tip = 0
    local repChange = 0
    local deliveryType = 'normal'
    if deliveryTime <= Config.FastDeliveryTime then
        tip = math.random(Config.Rewards.tipMin, Config.Rewards.tipMax)
        repChange = Config.Reputation.fastDelivery
        deliveryType = 'fast'
    elseif deliveryTime <= Config.DeliveryTime then
        repChange = Config.Reputation.normalDelivery
        deliveryType = 'normal'
    else
        repChange = Config.Reputation.lateDelivery
        deliveryType = 'late'
    end
    local totalPayout = baseReward + tip
    Framework.AddMoney(playerId, totalPayout)
    playerReputation[playerId] = (playerReputation[playerId] or 0) + repChange
    SavePlayerReputation(playerId)
    ClearPlayerAssignments(playerId)
    Framework.Debug(string.format("Player %d completed delivery in %.2f seconds. Payout: $%d (base: $%d, tip: $%d), Rep change: %d", 
        playerId, deliveryTime, totalPayout, baseReward, tip, repChange), 'success')
    return {
        success = true,
        totalPayout = totalPayout,
        baseReward = baseReward,
        tip = tip,
        reputation = playerReputation[playerId],
        deliveryType = deliveryType
    }
end)

lib.callback.register('anox-fooddelivery:orderFailed', function(source, orderId)
    local playerId = source
    local order = activeOrders[playerId]
    if order and (not orderId or order.id == orderId) then
        playerReputation[playerId] = (playerReputation[playerId] or 0) + Config.Reputation.lateDelivery
        SavePlayerReputation(playerId)
        ClearPlayerAssignments(playerId)
        Framework.Debug("Player " .. playerId .. " failed order " .. (orderId or "unknown"), 'warning')
    end
    return playerReputation[playerId]
end)

Framework.RegisterPlayerLoadedEvent(function(playerId, xPlayer)
    InitializePlayer(playerId)
    Framework.Debug("Player " .. playerId .. " loaded", 'info')
end)

Framework.RegisterPlayerDroppedEvent(function(playerId, reason)
    ClearPlayerAssignments(playerId)
    playerReputation[playerId] = nil
    playerCooldowns[playerId] = nil
    Framework.Debug("Player " .. playerId .. " disconnected, cleared all data", 'info')
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `anox_fooddelivery_reputation` (
            `identifier` VARCHAR(60) NOT NULL,
            `reputation` INT(11) NOT NULL DEFAULT 0,
            PRIMARY KEY (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]], {}, function()
        Framework.Debug("Database table initialized", 'success')
    end)
    local players = Framework.GetPlayers()
    for i = 1, #players do
        InitializePlayer(players[i])
    end
    Framework.Debug("Resource started successfully", 'success')
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for playerId, reputation in pairs(playerReputation) do
        SavePlayerReputation(playerId)
    end
    Framework.Debug("Resource stopped, all data saved", 'info')
end)