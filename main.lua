local Bridge = require('bridge/loader')
local Framework = Bridge.Load()
local isOnDuty = false
local currentOrder = nil
local waitingForOrder = false
local deliveryTimer = nil
local orderWaitTimer = nil
local reputation = 0
local orderStartTime = nil
local pickupBlip = nil
local deliveryBlip = nil
local showDeliveryMarker = false
local showPickupMarker = false
local isNearPickup = false
local isNearDelivery = false
local currentTimerText = ""
local currentInteractionText = ""

function UpdateTextUI()
    if currentTimerText == "" and currentInteractionText == "" then
        Framework.HideTextUI()
        return
    end
    local combinedText = ""
    local style = "default"
    if currentTimerText ~= "" then
        combinedText = currentTimerText
        style = "timer"
    end
    if currentInteractionText ~= "" then
        if combinedText ~= "" then
            combinedText = combinedText .. "\n" .. currentInteractionText
        else
            combinedText = currentInteractionText
            style = "pickup"
        end
    end
    Framework.ShowTextUI(combinedText, { style = style })
end

function SetTimerText(text)
    currentTimerText = text or ""
    UpdateTextUI()
end

function SetInteractionText(text)
    currentInteractionText = text or ""
    UpdateTextUI()
end

CreateThread(function()
    local npcHash = GetHashKey(Config.JobNPC.model)
    RequestModel(npcHash)
    while not HasModelLoaded(npcHash) do
        Wait(10)
    end
    local npc = CreatePed(4, npcHash, Config.JobNPC.coords.x, Config.JobNPC.coords.y, Config.JobNPC.coords.z - 1.0, Config.JobNPC.heading, false, true)
    SetEntityAsMissionEntity(npc, true, true)
    SetPedHearingRange(npc, 0.0)
    SetPedSeeingRange(npc, 0.0)
    SetPedAlertness(npc, 0.0)
    SetPedFleeAttributes(npc, 0, 0)
    SetBlockingOfNonTemporaryEvents(npc, true)
    SetPedCombatAttributes(npc, 46, true)
    SetPedFleeAttributes(npc, 0, 0)
    FreezeEntityPosition(npc, true)
    SetEntityInvincible(npc, true)
    if Config.JobNPC.blip.enabled then
        local blip = AddBlipForCoord(Config.JobNPC.coords)
        SetBlipSprite(blip, Config.JobNPC.blip.sprite)
        SetBlipColour(blip, Config.JobNPC.blip.color)
        SetBlipScale(blip, Config.JobNPC.blip.scale)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(_L('job_npc_blip_label'))
        EndTextCommandSetBlipName(blip)
    end
    Framework.Target.AddLocalEntity(npc, {
        {
            name = 'food_delivery_job',
            label = isOnDuty and _L('stop_food_delivery') or _L('start_food_delivery'),
            icon = 'fas fa-hamburger',
            onSelect = function()
                if isOnDuty then
                    StopDeliveryJob()
                else
                    StartDeliveryJob()
                end
            end,
            canInteract = function()
                return not waitingForOrder and not currentOrder
            end
        }
    })
    Framework.Debug("Job NPC created at " .. tostring(Config.JobNPC.coords), 'success')
end)

function StartDeliveryJob()
    Framework.Debug("Starting delivery job", 'info')
    lib.callback('anox-fooddelivery:getReputation', 5000, function(rep)
        if rep then
            reputation = rep
            isOnDuty = true
            waitingForOrder = true
            Framework.Notify(nil, _L('job_started_title'), _L('job_started_description'), 'success')
            local waitTime = CalculateWaitTime()
            ShowOrderCountdown(waitTime)
            Framework.Debug("Job started with reputation: " .. reputation .. ", wait time: " .. waitTime .. " seconds", 'info')
        end
    end)
end

function StopDeliveryJob()
    Framework.Debug("Stopping delivery job", 'info')
    isOnDuty = false
    waitingForOrder = false
    currentOrder = nil
    if orderWaitTimer then
        ClearTimeout(orderWaitTimer)
        orderWaitTimer = nil
    end
    if deliveryTimer then
        ClearTimeout(deliveryTimer)
        deliveryTimer = nil
    end
    RemoveBlips()
    SetTimerText("")
    SetInteractionText("")
    Framework.Notify(nil, _L('job_started_title'), _L('stopped_working'), 'info')
end

function CalculateWaitTime()
    local baseTime = Config.BaseWaitTime
    local repModifier = reputation * Config.RepMultiplier
    local finalTime = math.max(5, baseTime - repModifier)
    return finalTime
end

function ShowOrderCountdown(waitTime)
    local endTime = GetGameTimer() + (waitTime * 1000)
    CreateThread(function()
        while waitingForOrder and isOnDuty do
            local remaining = math.max(0, math.ceil((endTime - GetGameTimer()) / 1000))
            if remaining > 0 then
                SetTimerText(_L('next_order_countdown', remaining, reputation))
            else
                SetTimerText("")
                break
            end
            Wait(100)
        end
        if waitingForOrder and isOnDuty then
            GenerateNewOrder()
        end
    end)
end

function GenerateNewOrder()
    Framework.Debug("Generating new order", 'info')
    waitingForOrder = false
    lib.callback('anox-fooddelivery:generateOrder', 5000, function(order)
        if order then
            currentOrder = order
            ShowOrderPrompt()
        else
            waitingForOrder = true
            local waitTime = CalculateWaitTime()
            ShowOrderCountdown(waitTime)
        end
    end)
end

function ShowOrderPrompt()
    if not currentOrder then return end
    local items = {}
    for _, item in ipairs(currentOrder.items) do
        local restaurantKey = string.lower(currentOrder.restaurant.name)
            :gsub("[^%w%s]", "")
            :gsub("%s+", "")
            .. "_items"
        local itemName = _L(restaurantKey .. '.' .. item.name) or item.name
        table.insert(items, string.format('x%d %s', item.quantity, itemName))
    end
    local itemsString = table.concat(items, ', ')
    local alert = Framework.AlertDialog({
        header = _L('new_order_dialog_header'),
        content = _L('new_order_dialog_content', currentOrder.restaurant.name, itemsString, Config.DeliveryTimeMinutes),
        centered = true,
        cancel = true,
        labels = {
            confirm = _L('accept_order'),
            cancel = _L('decline_order')
        }
    })
    if alert == 'confirm' then
        AcceptOrder()
    else
        DeclineOrder()
    end
end

function AcceptOrder()
    Framework.Debug("Order accepted", 'info')
    orderStartTime = GetGameTimer()
    pickupBlip = AddBlipForCoord(currentOrder.restaurant.coords)
    showPickupMarker = true
    SetBlipSprite(pickupBlip, currentOrder.restaurant.blip.sprite)
    SetBlipColour(pickupBlip, currentOrder.restaurant.blip.color)
    SetBlipScale(pickupBlip, currentOrder.restaurant.blip.scale)
    SetBlipRoute(pickupBlip, true)
    SetBlipRouteColour(pickupBlip, currentOrder.restaurant.blip.color)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(_L('pickup_blip', currentOrder.restaurant.name))
    EndTextCommandSetBlipName(pickupBlip)
    ShowDeliveryTimer()
    CreatePickupTarget()
    Framework.Notify(nil, _L('new_order_title'), _L('new_order_description'), 'info')
end

function DeclineOrder()
    Framework.Debug("Order declined", 'info')
    lib.callback('anox-fooddelivery:updateReputation', 5000, function(newRep)
        if newRep then
            reputation = newRep
            Framework.Notify(nil, _L('order_cancelled_title'), _L('order_cancelled_description', Config.Reputation.cancelledOrder), 'error')
            currentOrder = nil
            waitingForOrder = true
            local waitTime = CalculateWaitTime()
            ShowOrderCountdown(waitTime)
        end
    end, 'cancelled')
end

function ShowDeliveryTimer()
    local endTime = GetGameTimer() + (Config.DeliveryTime * 1000)
    CreateThread(function()
        while currentOrder and not currentOrder.pickedUp do
            local remaining = math.max(0, math.ceil((endTime - GetGameTimer()) / 1000))
            local minutes = math.floor(remaining / 60)
            local seconds = remaining % 60
            SetTimerText(_L('time_remaining', minutes, seconds, reputation))
            if remaining <= 0 then
                OrderFailed()
                break
            end
            Wait(100)
        end
    end)
end

function CreatePickupTarget()
    CreateThread(function()
        local isShowingPrompt = false
        while currentOrder and not currentOrder.pickedUp do
            local playerCoords = GetEntityCoords(PlayerPedId())
            local distance = #(playerCoords - currentOrder.restaurant.coords)
            if distance < 3.0 then
                if not isShowingPrompt then
                    isShowingPrompt = true
                    SetInteractionText(_L('pickup_prompt'))
                end
                if IsControlJustPressed(0, 38) then
                    SetInteractionText("")
                    isShowingPrompt = false
                    PickupOrder()
                    break
                end
            else
                if isShowingPrompt then
                    SetInteractionText("")
                    isShowingPrompt = false
                end
            end
            Wait(0)
        end
        if isShowingPrompt then
            SetInteractionText("")
        end
    end)
end

function PickupOrder()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local distance = #(playerCoords - currentOrder.restaurant.coords)
    if distance > Config.AntiCheat.maxDistance then
        Framework.Debug("Player too far from pickup point: " .. distance, 'warning')
        return
    end
    if Framework.ProgressBar({
        duration = Config.ProgressBars.pickupOrder.duration,
        label = _L('pickup_order_label'),
        useWhileDead = false,
        canCancel = false,
        disable = {
            car = true,
            move = true,
            combat = true
        },
        anim = Config.ProgressBars.pickupOrder.animation
    }) then
        lib.callback('anox-fooddelivery:validatePickup', 5000, function(success)
            if success then
                currentOrder.pickedUp = true
                showPickupMarker = false
                if pickupBlip then
                    RemoveBlip(pickupBlip)
                    pickupBlip = nil
                end
                deliveryBlip = AddBlipForCoord(currentOrder.deliveryPoint)
                showDeliveryMarker = true
                SetBlipSprite(deliveryBlip, 1)
                SetBlipColour(deliveryBlip, 5)
                SetBlipScale(deliveryBlip, 0.8)
                SetBlipRoute(deliveryBlip, true)
                SetBlipRouteColour(deliveryBlip, 5)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString(_L('delivery_blip'))
                EndTextCommandSetBlipName(deliveryBlip)
                ShowDeliveryTimerToDestination()
                CreateDeliveryTarget()
                Framework.Notify(nil, _L('order_picked_up_title'), _L('order_picked_up_description'), 'success')
            else
                Framework.Debug("Pickup validation failed", 'error')
            end
        end, currentOrder.id)
    end
end


-- Pickup & Delivery marker thread
CreateThread(function()
    while true do
        Wait(0)

        if showPickupMarker and currentOrder then
            DrawMarker(2, currentOrder.restaurant.coords.x, currentOrder.restaurant.coords.y, currentOrder.restaurant.coords.z + 0.5, 
                0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                0.5, 0.5, 0.5,
                0, 100, 255, 150,
                false, true, 2, nil, nil, false)
        end

        if showDeliveryMarker and currentOrder then
            DrawMarker(2, currentOrder.deliveryPoint.x, currentOrder.deliveryPoint.y, currentOrder.deliveryPoint.z + 0.5, 
                0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                0.5, 0.5, 0.5,
                0, 255, 0, 150,
                false, true, 2, nil, nil, false)
        end
    end
end)


function ShowDeliveryTimerToDestination()
    local endTime = orderStartTime + (Config.DeliveryTime * 1000)
    CreateThread(function()
        while currentOrder and currentOrder.pickedUp and not currentOrder.delivered do
            local remaining = math.max(0, math.ceil((endTime - GetGameTimer()) / 1000))
            local minutes = math.floor(remaining / 60)
            local seconds = remaining % 60
            SetTimerText(_L('deliver_timer', minutes, seconds, reputation))
            if remaining <= 0 then
                OrderFailed()
                break
            end
            Wait(100)
        end
    end)
end

function CreateDeliveryTarget()
    CreateThread(function()
        local isShowingPrompt = false
        while currentOrder and currentOrder.pickedUp and not currentOrder.delivered do
            local playerCoords = GetEntityCoords(PlayerPedId())
            local distance = #(playerCoords - currentOrder.deliveryPoint)
            if distance < 3.0 then
                if not isShowingPrompt then
                    isShowingPrompt = true
                    SetInteractionText(_L('deliver_prompt'))
                end
                if IsControlJustPressed(0, 38) then
                    SetInteractionText("")
                    isShowingPrompt = false
                    DeliverOrder()
                    break
                end
            else
                if isShowingPrompt then
                    SetInteractionText("")
                    isShowingPrompt = false
                end
            end
            Wait(0)
        end
        if isShowingPrompt then
            SetInteractionText("")
        end
    end)
end

function DeliverOrder()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local distance = #(playerCoords - currentOrder.deliveryPoint)
    if distance > Config.AntiCheat.maxDistance then
        Framework.Debug("Player too far from delivery point: " .. distance, 'warning')
        return
    end
    if Framework.ProgressBar({
        duration = Config.ProgressBars.deliverOrder.duration,
        label = _L('deliver_order_label'),
        useWhileDead = false,
        canCancel = false,
        disable = {
            car = true,
            move = true,
            combat = true
        },
        anim = Config.ProgressBars.deliverOrder.animation
    }) then
        local deliveryTime = (GetGameTimer() - orderStartTime) / 1000
        lib.callback('anox-fooddelivery:completeDelivery', 5000, function(result)
            if result then
                currentOrder.delivered = true
                if deliveryBlip then
                    RemoveBlip(deliveryBlip)
                    deliveryBlip = nil
                end
                SetTimerText("")
                reputation = result.reputation
                if result.deliveryType == 'fast' then
                    Framework.Notify(nil, _L('fast_delivery_title'), _L('fast_delivery_earnings', 
                        _L('fast_delivery_description', '+'..Config.Reputation.fastDelivery), 
                        result.totalPayout, 
                        result.tip
                    ), 'success', 8000)
                elseif result.deliveryType == 'late' then
                    Framework.Notify(nil, _L('order_late_title'), _L('late_delivery_earnings', 
                        _L('order_late_description', Config.Reputation.lateDelivery), 
                        result.totalPayout
                    ), 'warning', 8000)
                else
                    Framework.Notify(nil, _L('order_complete_title'), _L('normal_delivery_earnings', 
                        _L('order_complete_description'), 
                        result.totalPayout
                    ), 'success', 8000)
                end
                Wait(1000)
                ShowContinuePrompt()
                Framework.Debug("Delivery completed in " .. string.format("%.2f", deliveryTime) .. " seconds", 'success')
            else
                Framework.Debug("Delivery validation failed", 'error')
            end
        end, currentOrder.id, deliveryTime)
    end
end

function ShowContinuePrompt()
    local alert = Framework.AlertDialog({
        header = _L('delivery_complete_header'),
        content = _L('delivery_complete_content', reputation),
        centered = true,
        cancel = true,
        labels = {
            confirm = _L('continue_working'),
            cancel = _L('end_shift')
        }
    })
    if alert == 'confirm' then
        currentOrder = nil
        waitingForOrder = true
        local waitTime = CalculateWaitTime()
        ShowOrderCountdown(waitTime)
        Framework.Notify(nil, _L('waiting_next_order_title'), _L('waiting_next_order_description'), 'info')
    else
        StopDeliveryJob()
    end
end

function OrderFailed()
    Framework.Debug("Order failed - timeout", 'warning')
    lib.callback('anox-fooddelivery:orderFailed', 5000, function(newRep)
        if newRep then
            reputation = newRep
            RemoveBlips()
            SetTimerText("")
            SetInteractionText("")
            Framework.Target.RemoveZone('pickup_order')
            Framework.Target.RemoveZone('deliver_order')
            Framework.Notify(nil, _L('order_failed_title'), _L('order_failed_description', Config.Reputation.lateDelivery), 'error')
            currentOrder = nil
            waitingForOrder = true
            local waitTime = CalculateWaitTime()
            ShowOrderCountdown(waitTime)
        end
    end, currentOrder and currentOrder.id or nil)
end

function RemoveBlips()
    if pickupBlip then
        RemoveBlip(pickupBlip)
        pickupBlip = nil
    end
    if deliveryBlip then
        RemoveBlip(deliveryBlip)
        deliveryBlip = nil
    end
end

Framework.RegisterPlayerLoadedEvent(function(xPlayer)
    Framework.Debug("Player loaded event received", 'info')
end)

Framework.RegisterJobUpdateEvent(function(job)
    Framework.Debug("Job updated: " .. job.name, 'info')
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    RemoveBlips()
    SetTimerText("")
    SetInteractionText("")
end)

lib.callback.register('anox-fooddelivery:getPlayerCoords', function()
    return GetEntityCoords(PlayerPedId())
end)