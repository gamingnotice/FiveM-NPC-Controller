Citizen.CreateThread(function()
while ESX == nil do
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
Citizen.Wait(0)
end
end)

local MAX_PEDS_PER_PLAYER = 2
local pedList = {} -- Liste zum Speichern der erstellten NPCs

local playerPeds = {}

RegisterNetEvent('open:npcMenu')
AddEventHandler('open:npcMenu', function()
    local elements = {
        {label = "NPC erstellen", value = "create_npc"},
        {label = "NPC folgen lassen", value = "follow_npc"},
        {label = "NPC in Fahrzeug steigen lassen", value = "npc_enter_vehicle"},
        {label = "NPC aus Fahrzeug aussteigen lassen", value = "npc_leave_vehicle"},
        {label = "NPC auf aggressiv setzen", value = "npc_aggressive"},
        {label = "NPC auf passiv setzen", value = "npc_passive"}
    }

    ESX.UI.Menu.CloseAll()

    ESX.UI.Menu.Open(
        'default', GetCurrentResourceName(), 'npc_actions',
        {
            title    = 'NPC Menü',
            align    = 'top-left',
            elements = elements
        },
        function(data, menu)
            local val = data.current.value

           if val == "create_npc" then
                    OpenCreateNPCMenu()
           elseif val == "follow_npc" then
                ExecuteCommand("followme")
            elseif val == "npc_enter_vehicle" then
                ExecuteCommand("npcenter")
            elseif val == "npc_leave_vehicle" then
                ExecuteCommand("npcexit")
            elseif val == "npc_aggressive" then
                ExecuteCommand("npcaggressive")
            elseif val == "npc_passive" then
                ExecuteCommand("npcpassive")
            end
        end,
        function(data, menu)
            menu.close()
        end
    )
end)

-- Funktion, um den NPC-Erstellungsdialog anzuzeigen
function OpenCreateNPCMenu()
    ESX.UI.Menu.Open(
        'dialog', GetCurrentResourceName(), 'create_npc_dialog',
        {
            title = 'NPC erstellen',
        },
        function(data, menu)
            local pedName = data.value

            if not pedName or pedName == '' then
                exports["vms_notify"]:Notification("Fehler", "Bitte geben Sie den Namen des NPCs ein.", 5000, "#FF0000", "times")
                return
            end

            -- Überprüft die maximale Anzahl der NPCs pro Spieler
            local existingPeds = 0
            local playerServerId = GetPlayerServerId(PlayerId())
            for _, pedData in ipairs(pedList) do
                if pedData.owner == playerServerId then
                    existingPeds = existingPeds + 1
                end
            end

            if existingPeds >= MAX_PEDS_PER_PLAYER then
                exports["vms_notify"]:Notification("Fehler", "Sie haben bereits die maximale Anzahl an NPCs erstellt.", 5000, "#FF0000", "times")
                return
            end

            local playerPed = PlayerPedId()
            local coords    = GetEntityCoords(playerPed)

            createPed(pedName, coords, playerServerId)

            menu.close()
        end,
        function(data, menu)
            menu.close()
        end
    )
end


-- Funktion, um einen NPC zu erstellen
function createPed(pedName, position, owner)
local hash = GetHashKey(pedName)
RequestModel(hash)
while not HasModelLoaded(hash) do
    Wait(0)
end

local ped = CreatePed(4, hash, position.x, position.y, position.z, 0.0, false, true)
SetEntityInvincible(ped, true)
SetBlockingOfNonTemporaryEvents(ped, true)
SetPedCanRagdoll(ped, false)

-- Speichert den NPC in der Liste
table.insert(pedList, {ped = ped, owner = owner})

return ped
end

-- Befehl zum Erstellen eines NPCs
RegisterCommand("createnpc", function(source, args)
if #args < 2 then
exports["vms_notify"]:Notification("Fehler", "Verwendung: /createnpc [pedname] [count]", 5000, "#FF0000", "times")
return
end

local pedName = args[1]
local count = tonumber(args[2])

if count == nil or count < 1 then
    exports["vms_notify"]:Notification("Fehler", "Die Anzahl der zu erstellenden NPCs muss mindestens 1 betragen.", 5000, "#FF0000", "times")
    return
end

-- Überprüft die maximale Anzahl der NPCs pro Spieler
local existingPeds = 0
local playerServerId = GetPlayerServerId(PlayerId())
for _, pedData in ipairs(pedList) do
    if pedData.owner == playerServerId then
        existingPeds = existingPeds + 1
    end
end

if existingPeds + count > MAX_PEDS_PER_PLAYER then
    exports["vms_notify"]:Notification("Fehler", "Die maximale Anzahl der NPCs pro Spieler ist " .. MAX_PEDS_PER_PLAYER .. ".", 5000, "#FF0000", "times")
    return
end

local playerPed = PlayerPedId()
local coords    = GetEntityCoords(playerPed)

for i = 1, count do
    createPed(pedName, coords + vector3(i * 2, 0.0, 0.0), playerServerId)
end

end, false)

-- Funktion, um alle NPCs eines Spielers folgen zu lassen
function taskPedsFollowPlayer(playerServerId, task)
    local playerPed = PlayerPedId()

    for _, pedData in ipairs(pedList) do
        if pedData.owner == playerServerId then
            task(pedData.ped, playerPed)
        end
    end

    exports["vms_notify"]:Notification("Erfolgreich", "NPC(s) folgen dir jetzt.", 5000, "#00FF00", "check")
end

RegisterCommand("followme", function()
    taskPedsFollowPlayer(GetPlayerServerId(PlayerId()), function(ped, playerPed)
        TaskFollowToOffsetOfEntity(ped, playerPed, 1.0, -1.0, 0.0, 5.0, -1, 2.0, true)
    end)
end, false)


-- Befehl, um NPCs stoppen zu lassen
RegisterCommand("unfollow", function()
taskPedsFollowPlayer(GetPlayerServerId(PlayerId()), function(ped, playerPed)
ClearPedTasks(ped)
end)
end, false)


-- NPC versucht, in das Fahrzeug zu steigen
RegisterCommand("npcenter", function()
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    if vehicle ~= nil then
        local seatIndex = nil -- Verwende nil, um einen geeigneten Sitz zu finden
        
        -- Durchlaufen Sie alle Sitze, um einen verfügbaren Sitz zu finden
        for i = -1, GetVehicleMaxNumberOfPassengers(vehicle) - 1 do
            if IsVehicleSeatFree(vehicle, i) then
                seatIndex = i
                break
            end
        end
        
        if seatIndex ~= nil then
            for _, pedData in ipairs(pedList) do
                if pedData.owner == GetPlayerServerId(PlayerId()) then
                    TaskEnterVehicle(pedData.ped, vehicle, -1, seatIndex, 1.0, 1, 0)
                    exports["vms_notify"]:Notification("Debug", "NPC steigt in Fahrzeug ein: " .. tostring(pedData.ped), 5000, "#00ff00", "info") -- Debug-Meldung
                end
            end
        else
            exports["vms_notify"]:Notification("Fehler", "Kein freier Sitzplatz im Fahrzeug!", 5000, "#ff0000", "error")
            
            -- Füge Debug-Meldungen hinzu, um mehr Informationen zu erhalten
            for i = -1, GetVehicleMaxNumberOfPassengers(vehicle) - 1 do
                if not IsVehicleSeatFree(vehicle, i) then
                    local pedInSeat = GetPedInVehicleSeat(vehicle, i)
                    exports["vms_notify"]:Notification("Debug", "Sitzplatz " .. tostring(i) .. " besetzt von: " .. tostring(pedInSeat), 5000, "#00ff00", "info") -- Debug-Meldung
                end
            end
        end
    else
        exports["vms_notify"]:Notification("Fehler", "Du bist in keinem Fahrzeug!", 5000, "#ff0000", "error")
    end

end, false)



-- NPC steigt aus dem Fahrzeug aus
RegisterCommand("npcexit", function()
    for _, pedData in ipairs(pedList) do
        if pedData.owner == GetPlayerServerId(PlayerId()) and IsPedInAnyVehicle(pedData.ped, false) then
            TaskLeaveAnyVehicle(pedData.ped, 0, 0)
        end
    end
end, false)

-- NPCs greifen den Spieler an, den der Eigentümer angreift
RegisterCommand("npcaggressive", function()
local playerServerId = GetPlayerServerId(PlayerId())

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        local playerPed = PlayerPedId()
        if IsPedInMeleeCombat(playerPed) then
            local enemy = GetMeleeTargetForPed(playerPed)
            if enemy and enemy ~= 0 then
                for _, pedData in ipairs(pedList) do
                    if pedData.owner == playerServerId then
                        TaskCombatPed(pedData.ped, enemy, 0, 16)
                    end
                end
            end
        end
    end
end)

end, false)

-- NPCs hören auf, andere Spieler anzugreifen
RegisterCommand("npcpassive", function()
local playerServerId = GetPlayerServerId(PlayerId())
for _, pedData in ipairs(pedList) do
    if pedData.owner == playerServerId then
        ClearPedTasks(pedData.ped)
    end
end
end, false)

Citizen.CreateThread(function()
while true do
Citizen.Wait(500)
    local playerPed = PlayerPedId()
    if IsPedInAnyVehicle(playerPed, true) then
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        if GetVehicleMaxNumberOfPassengers(vehicle) <= GetVehicleNumberOfPassengers(vehicle) then
            for _, pedData in ipairs(pedList) do
                if pedData.owner == GetPlayerServerId(PlayerId()) and not IsPedInAnyVehicle(pedData.ped, false) then
                    TaskFollowToOffsetOfEntity(pedData.ped, vehicle, 0.0, -5.0, 0.0, 1.0, -1, 2.0, true)
                end
            end
        end
    end
end
end)

-- Setzt die Lebenspunkte der NPCs
for _, pedData in ipairs(pedList) do
if pedData.owner == GetPlayerServerId(PlayerId()) then
SetEntityHealth(pedData.ped, 100) -- Dies stellt die Gesundheit auf einen niedrigeren Wert ein, sodass sie leichter zu töten sind. Anpassen nach Bedarf.
end
end

RegisterCommand("npc", function()
TriggerEvent('open:npcMenu')
end, false)