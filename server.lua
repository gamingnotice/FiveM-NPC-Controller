ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

ESX.RegisterServerCallback('getCoords', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)

    if xPlayer then
        cb(xPlayer.getCoords(true))
    else
        cb(nil)
    end
end)
