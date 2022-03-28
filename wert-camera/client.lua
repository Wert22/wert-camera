local QBCore = exports['qb-core']:GetCoreObject()
local active = false
local photoactive = false
local cameraprop = nil
local frontCam = false
local photoprop = nil

local WebHook = "https://discord.com/api/webhooks/948347278077333504/hrhqBMX3HBvTDlukWP-i1FEUO23YbP_pVZCyC9mSEFLz2JSuvPvflT034GDNzqsmsaec"

local fov_max = 70.0
local fov_min = 5.0 -- max zoom level (smaller fov is more zoom)
local zoomspeed = 10.0 -- camera zoom speed
local speed_lr = 8.0 -- speed by which the camera pans left-right
local speed_ud = 8.0 -- speed by which the camera pans up-down
local fov = (fov_max+fov_min)*0.5

local presstake = false

local function SharedRequestAnimDict(animDict, cb)
	if not HasAnimDictLoaded(animDict) then
		RequestAnimDict(animDict)

		while not HasAnimDictLoaded(animDict) do
			Citizen.Wait(1)
		end
	end
	if cb ~= nil then
		cb()
	end
end

local function LoadPropDict(model)
    while not HasModelLoaded(GetHashKey(model)) do
      RequestModel(GetHashKey(model))
      Wait(10)
    end
end

local function FullClose()
    active = false
    presstake = false
    if cameraprop then DeleteEntity(cameraprop) end
    ClearPedTasks(PlayerPedId())
end

--FUNCTIONS--

function HideHUDThisFrame()
    HideHelpTextThisFrame()
    HideHudAndRadarThisFrame()
    HideHudComponentThisFrame(1) -- Wanted Stars
    HideHudComponentThisFrame(2) -- Weapon icon
    HideHudComponentThisFrame(3) -- Cash
    HideHudComponentThisFrame(4) -- MP CASH
    HideHudComponentThisFrame(6)
    HideHudComponentThisFrame(7)
    HideHudComponentThisFrame(8)
    HideHudComponentThisFrame(9)
    HideHudComponentThisFrame(13) -- Cash Change
    HideHudComponentThisFrame(11) -- Floating Help Text
    HideHudComponentThisFrame(12) -- more floating help text
    HideHudComponentThisFrame(15) -- Subtitle Text
    HideHudComponentThisFrame(18) -- Game Stream
    HideHudComponentThisFrame(19) -- weapon wheel
end

function CheckInputRotation(cam, zoomvalue)
    local rightAxisX = GetDisabledControlNormal(0, 220)
    local rightAxisY = GetDisabledControlNormal(0, 221)
    local rotation = GetCamRot(cam, 2)
    if rightAxisX ~= 0.0 or rightAxisY ~= 0.0 then
        new_z = rotation.z + rightAxisX*-1.0*(speed_ud)*(zoomvalue+0.1)
        new_x = math.max(math.min(20.0, rotation.x + rightAxisY*-1.0*(speed_lr)*(zoomvalue+0.1)), -89.5)
        SetCamRot(cam, new_x, 0.0, new_z, 2)
        SetEntityHeading(PlayerPedId(),new_z)
    end
end

function HandleZoom(cam)
    local lPed = PlayerPedId()
    if not ( IsPedSittingInAnyVehicle( lPed ) ) then

        if IsControlJustPressed(0,241) then
            fov = math.max(fov - zoomspeed, fov_min)
        end
        if IsControlJustPressed(0,242) then
            fov = math.min(fov + zoomspeed, fov_max)
        end
        local current_fov = GetCamFov(cam)
        if math.abs(fov-current_fov) < 0.1 then
            fov = current_fov
        end
        SetCamFov(cam, current_fov + (fov - current_fov)*0.05)
    else
        if IsControlJustPressed(0,17) then
            fov = math.max(fov - zoomspeed, fov_min)
        end
        if IsControlJustPressed(0,16) then
            fov = math.min(fov + zoomspeed, fov_max)
        end
        local current_fov = GetCamFov(cam)
        if math.abs(fov-current_fov) < 0.1 then
            fov = current_fov
        end
        SetCamFov(cam, current_fov + (fov - current_fov)*0.05)
    end
end

RegisterNetEvent("wert-camera:client:use-camera", function()
    if not active then
        active = true

        local ped = PlayerPedId()
        SharedRequestAnimDict("amb@world_human_paparazzi@male@base", function()
            TaskPlayAnim(ped, "amb@world_human_paparazzi@male@base", "base", 2.0, 2.0, -1, 1, 0, false, false, false)
        end)
        local x,y,z = table.unpack(GetEntityCoords(ped))
        if not HasModelLoaded("prop_pap_camera_01") then
            LoadPropDict("prop_pap_camera_01")
        end
        cameraprop = CreateObject(GetHashKey("prop_pap_camera_01"), x, y, z+0.2,  true,  true, true)
        AttachEntityToEntity(cameraprop, ped, GetPedBoneIndex(ped, 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
        SetModelAsNoLongerNeeded("prop_pap_camera_01")

        CreateThread(function()
            while active do
                Wait(200)
                local lPed = PlayerPedId()
                local vehicle = GetVehiclePedIsIn(lPed)
                if active then
                    active = true
                    Wait(500)
        
                    SetTimecycleModifier("default")
                    SetTimecycleModifierStrength(0.3)
        
                    local cam = CreateCam("DEFAULT_SCRIPTED_FLY_CAMERA", true)
                    AttachCamToEntity(cam, lPed, 0.0, 1.0, 1.0, true)
                    SetCamRot(cam, 0.0,0.0,GetEntityHeading(lPed))
                    SetCamFov(cam, fov)
                    RenderScriptCams(true, false, 0, 1, 0)
        
                    while active and not IsEntityDead(lPed) and (GetVehiclePedIsIn(lPed) == vehicle) and true do
                        if IsControlJustPressed(0, 177) then -- Cancel | İptal
                            PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
                            FullClose()
                        elseif IsControlJustPressed(1, 176) then -- TAKE.. PIC
                            if not presstake then
                                presstake = true
                                exports['screenshot-basic']:requestScreenshotUpload(tostring(WebHook), "files[]", function(data)
                                    local image = json.decode(data)
                                    FullClose()
                                    TriggerServerEvent("wert-camera:server:add-photo-item", json.encode(image.attachments[1].proxy_url))
                                end)
                            end
                        end
        
                        local zoomvalue = (1.0/(fov_max-fov_min))*(fov-fov_min)
                        CheckInputRotation(cam, zoomvalue)
                        HandleZoom(cam)
                        HideHUDThisFrame()
                        Wait(1)
                    end
                    FullClose()
                    ClearTimecycleModifier()
                    fov = (fov_max+fov_min)*0.5
                    RenderScriptCams(false, false, 0, 1, 0)
                    DestroyCam(cam, false)
                    SetNightvision(false)
                    SetSeethrough(false)
                end
            end
        end)
    else
        FullClose()
    end
end)

RegisterNetEvent("wert-camera:client:use-photo", function(url)
    if not photoactive then
        photoactive = true
        SetNuiFocus(true, true)
        SendNUIMessage({action = "Show", photo = url})

        local ped = PlayerPedId()
        SharedRequestAnimDict("amb@world_human_tourist_map@male@base", function()
            TaskPlayAnim(ped, "amb@world_human_tourist_map@male@base", "base", 2.0, 2.0, -1, 1, 0, false, false, false)
        end)
        local x,y,z = table.unpack(GetEntityCoords(ped))
        if not HasModelLoaded("prop_tourist_map_01") then
            LoadPropDict("prop_tourist_map_01")
        end
        photoprop = CreateObject(GetHashKey("prop_tourist_map_01"), x, y, z+0.2,  true,  true, true)
        AttachEntityToEntity(photoprop, ped, GetPedBoneIndex(ped, 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
        SetModelAsNoLongerNeeded("prop_tourist_map_01")
    end
end)

RegisterNUICallback("Close", function()
    SetNuiFocus(false, false)
    photoactive = false
    if photoprop then DeleteEntity(photoprop) end
    ClearPedTasks(PlayerPedId())
end)