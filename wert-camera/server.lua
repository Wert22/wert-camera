local QBCore = exports['qb-core']:GetCoreObject()

QBCore.Functions.CreateUseableItem("camera", function(source, item)
    local src = source
    TriggerClientEvent("wert-camera:client:use-camera", src)
end)

QBCore.Functions.CreateUseableItem("photo", function(source, item)
    local src = source
    if item.info and item.info.photourl then
        TriggerClientEvent("wert-camera:client:use-photo", src, item.info.photourl)
    end
end)

RegisterNetEvent("wert-camera:server:add-photo-item", function(url)
    local src = source
    local ply = QBCore.Functions.GetPlayer(source)
    if ply then
        local info = {
            photourl = url
        }
        ply.Functions.AddItem("photo", 1, nil, info)
    end
end)