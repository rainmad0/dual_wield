victimPeds = {}
victimPedCoords = {
    vector3(-978.47, -3001.0, 13.9450),
    vector3(-979.27, -3002.3, 13.9450),
    vector3(-980.08, -3003.8, 13.9450),
    vector3(-981.04, -3005.3, 13.9450),
    vector3(-981.92, -3006.8, 13.9450),
}
RegisterCommand('spawnpeds', function()
    for i = 1, #victimPedCoords do
        victimPeds[i] = CreatePed(5, GetHashKey('mp_m_freemode_01'), victimPedCoords[i]['xy'], victimPedCoords[i]['z'] - 1.0, 1.0, 1, 1, 0)
        SetEntityHeading(victimPeds[i], 70.0)
        SetBlockingOfNonTemporaryEvents(victimPeds[i], true)
    end
end)

dual = false
peds = {}
RegisterCommand('dual', function(a, args, c)
    if args[1] == nil or type(args[1]) ~= 'string' or not string.match(args[1], 'WEAPON_') or args[1] ~= 'reset' then
        print('select weapon, like this: /dual WEAPON_CARBINERIFLE')
        return
    end
    dual = not dual
    if dual then
        local ped = PlayerPedId()
        local pedCo = GetEntityCoords(ped)
        loadAnimDict('anim@veh@armordillo@turret@base')
        loadAnimDict('anim@cover@weapon@reloads@rifle@spcarbine')
        loadModel('mp_m_freemode_01')
        for i = 1, 2 do
            peds[i] = CreatePed(5, GetHashKey('mp_m_freemode_01'), pedCo['xy'] + 2.0, pedCo['z'], 1.0, 1, 1, 0)
            SetEntityAlpha(peds[i], 0, 1)
            FreezeEntityPosition(peds[i], true)
            SetBlockingOfNonTemporaryEvents(peds[i], true)
            GiveWeaponToPed(peds[i], args[1], 100, 1, 1)
            SetPedInfiniteAmmo(peds[i], true, args[1])
            SetPedInfiniteAmmoClip(peds[i], true)
            SetPedCanSwitchWeapon(peds[i], false)
            SetPedDropsWeaponsWhenDead(peds[i], false)
        end
        Wait(250)
        leftWeapon = GetCurrentPedWeaponEntityIndex(peds[1])
        rightWeapon = GetCurrentPedWeaponEntityIndex(peds[2])
        DetachEntity(leftWeapon, 1, 1)
        DetachEntity(rightWeapon, 1, 1)
        Wait(250)
        AttachEntityToEntity(leftWeapon, ped, GetPedBoneIndex(ped, 18905), 0.16, 0.031, -0.004, -90.0, 15.7399, -5.0, 0, 1, 1, 1, 0, 1)
        AttachEntityToEntity(rightWeapon, ped, GetPedBoneIndex(ped, 57005), 0.15, 0.021, -0.004, -70.0, -5.0, -21.0, 0, 1, 1, 1, 0, 1)
        Citizen.CreateThread(function()
            local ammoCount = 15
            while dual do
                endCoords = ScreenToWorld()
                if not IsEntityPlayingAnim(ped, "anim@veh@armordillo@turret@base", "sit_aim_down", 1) then
                    TaskPlayAnim(ped, "anim@veh@armordillo@turret@base", "sit_aim_down", 8.0, 8.0, -1, 48, 1, false, false, false)
                else
                    SetEntityAnimCurrentTime(ped, "anim@veh@armordillo@turret@base", "sit_aim_down", 0.5)
                end
                if IsDisabledControlJustPressed(0, 24) then
                    if ammoCount > 0 then
                        SetPedShootsAtCoord(peds[1], endCoords, 0)
                        SetPedShootsAtCoord(peds[2], endCoords, 0)
                        ammoCount = ammoCount - 1
                    end
                end
                if ammoCount <= 0 then
                    print('need reload')
                    TaskPlayAnim(ped, "anim@cover@weapon@reloads@rifle@spcarbine", "reload_low_left", 4.0, 4.0, -1, 48, 1, false, false, false)
                    Wait(2000)
                    ammoCount = 15
                end
                Citizen.Wait(1)
            end
        end)
    else
        DeletePed(peds[1])
        DeletePed(peds[2])
        DeleteEntity(leftWeapon)
        DeleteEntity(rightWeapon)
        ClearPedTasks(ped)
    end
end)

Citizen.CreateThread(function() while true do if dual then DisablePlayerFiring(PlayerId(), true) ShowHudComponentThisFrame(14) DisableControlAction(0, 25, true) end Citizen.Wait(1) end end)

function ScreenToWorld()
    local camRot = GetGameplayCamRot(0)
    local camPos = GetGameplayCamCoord()
    local width,height = GetActiveScreenResolution()
    local cursor = vector2(0.5,0.5)
    local cam3DPos, forwardDir = ScreenRelToWorld(camPos, camRot, cursor)
    local direction = camPos + forwardDir * 50.0
    local rayHandle = StartShapeTestRay(cam3DPos['x'],cam3DPos['y'],cam3DPos['z'], direction['x'],direction['y'],direction['z'], -1, GetPlayerPed(-1), 0)
    local _, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(rayHandle)
    if entityHit >= 1 then
        entityType = GetEntityType(entityHit)
    end
    return endCoords
end
   
function ScreenRelToWorld(camPos, camRot, cursor)
    local camForward = RotationToDirection(camRot)
    local rotUp = vector3(camRot['x'] + 1.0, camRot['y'], camRot['z'])
    local rotDown = vector3(camRot['x'] - 1.0, camRot['y'], camRot['z'])
    local rotLeft = vector3(camRot['x'], camRot['y'], camRot['z'] - 1.0)
    local rotRight = vector3(camRot['x'], camRot['y'], camRot['z'] + 1.0)
    local camRight = RotationToDirection(rotRight) - RotationToDirection(rotLeft)
    local camUp = RotationToDirection(rotUp) - RotationToDirection(rotDown)
    local rollRad = -(camRot['y'] * math.pi / 180.0)
    local camRightRoll = camRight * math.cos(rollRad) - camUp * math.sin(rollRad)
    local camUpRoll = camRight * math.sin(rollRad) + camUp * math.cos(rollRad)
    local point3DZero = camPos + camForward * 1.0
    local point3D = point3DZero + camRightRoll + camUpRoll
    local point2D = World3DToScreen2D(point3D)
    local point2DZero = World3DToScreen2D(point3DZero)
    local scaleX = (cursor['x'] - point2DZero['x']) / (point2D['x'] - point2DZero['x'])
    local scaleY = (cursor['y'] - point2DZero['y']) / (point2D['y'] - point2DZero['y'])
    local point3Dret = point3DZero + camRightRoll * scaleX + camUpRoll * scaleY
    local forwardDir = camForward + camRightRoll * scaleX + camUpRoll * scaleY
    return point3Dret, forwardDir
end
   
function RotationToDirection(rotation)
    local x = rotation['x'] * math.pi / 180.0
    local z = rotation['z'] * math.pi / 180.0
    local num = math.abs(math.cos(x))
    return vector3((-math.sin(z) * num), (math.cos(z) * num), math.sin(x))
end
   
function World3DToScreen2D(pos)
    local _, sX, sY = GetScreenCoordFromWorldCoord(pos['x'], pos['y'], pos['z'])
    return vector2(sX, sY)
end

function loadAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        RequestAnimDict(dict)
        Citizen.Wait(50)
    end
end

function loadModel(model)
    if type(model) == 'number' then
        model = model
    else
        model = GetHashKey(model)
    end
    while not HasModelLoaded(model) do
        RequestModel(model)
        Citizen.Wait(0)
    end
end

ClearPedTasks(PlayerPedId())
DetachEntity(PlayerPedId(), 1, 1)
