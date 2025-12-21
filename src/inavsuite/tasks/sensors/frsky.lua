--[[
  Copyright (C) 2025 Inav Project
  GPLv3 — https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local inavsuite = require("inavsuite")

local arg = {...}
local config = arg[1]

local frsky = {}
local cacheExpireTime = 30
local lastCacheFlushTime = os.clock()
local sensorTlm = nil

frsky.name = "frsky"
frsky._provisioned = false
frsky.createSensorCache = {}
frsky.renameSensorCache = {}
frsky.dropSensorCache = {}

local sidLookup = {
  [0]  = {'0x1000'}, -- None
  [1]  = {'0x5100'}, -- Heartbeat

  [3]  = {'0x0210'}, -- Battery voltage
  [4]  = {'0x0200'}, -- Battery current
  [5]  = {'0x5250'}, -- Battery consumption
  [6]  = {'0x0600'}, -- Battery charge level (shares ID with BATTERY_FUEL in C)
  [7]  = {'0x5260'}, -- Battery cell count
  [8]  = {'0x0910'}, -- Battery cell voltage
  [9]  = {'0x102F'}, -- Battery all cell voltages (not present in your C list)

  [11] = {'0x5210'}, -- Heading
  [12] = {'0x0100'}, -- Altitude
  [13] = {'0x0110'}, -- Variometer

  [14] = {'0x0730'}, -- Attitude (packed)
  --[15] = {'0x1101'}, -- Attitude pitch (not present in your C list as separate IDs)
  --[16] = {'0x1102'}, -- Attitude roll  (not present in your C list as separate IDs)
  --[17] = {'0x1103'}, -- Attitude yaw   (not present in your C list as separate IDs)

  [18] = {'0x0700'}, -- Accel X
  [19] = {'0x0710'}, -- Accel Y
  [20] = {'0x0720'}, -- Accel Z

  [22] = {'0x0860'}, -- GPS sats
  [23] = {'0x526B'}, -- GPS HDOP
  [24] = {'0x0800'}, -- GPS coord (Lat/Lon)
  [25] = {'0x0820'}, -- GPS altitude
  [26] = {'0x0840'}, -- GPS heading
  [27] = {'0x0830'}, -- GPS groundspeed
  [28] = {'0x5269'}, -- GPS home distance
  [29] = {'0x5268'}, -- GPS home direction
  [30] = {'0x526A'}, -- GPS azimuth

  [31] = {'0x1131'}, -- ESC RPM (aggregate) (not present in your C list)
  [33] = {'0x5130'}, -- ESC1 RPM
  [35] = {'0x5131'}, -- ESC2 RPM
  [37] = {'0x5132'}, -- ESC3 RPM
  [39] = {'0x5133'}, -- ESC4 RPM

  [32] = {'0x1136'}, -- ESC temp (aggregate) (not present in your C list)
  [34] = {'0x5140'}, -- ESC1 temp
  [36] = {'0x5141'}, -- ESC2 temp
  [38] = {'0x5142'}, -- ESC3 temp
  [40] = {'0x5143'}, -- ESC4 temp

  [42] = {'0x51D0'}, -- CPU load
  [43] = {'0x5121'}, -- Flight mode
  [44] = {'0x5123'}, -- Profiles
  [45] = {'0x5122'}, -- Arming flags
}


local createSensorList = {}
-- Heartbeat / System
createSensorList[0x5100] = {name = "Heartbeat", unit = UNIT_RAW}
createSensorList[0x51D0] = {name = "CPU Load", unit = UNIT_RAW}

-- Flight state
createSensorList[0x5121] = {name = "Flight Mode", unit = UNIT_RAW}
createSensorList[0x5122] = {name = "Arming Flags", unit = UNIT_RAW}
createSensorList[0x5123] = {name = "Profiles", unit = UNIT_RAW}

-- Battery
createSensorList[0x5250] = {name = "Battery Consumption", unit = UNIT_RAW}
createSensorList[0x5260] = {name = "Battery Cell Count", unit = UNIT_RAW}

-- GPS
createSensorList[0x5268] = {name = "GPS Home Direction", unit = UNIT_RAW}
createSensorList[0x5269] = {name = "GPS Home Distance", unit = UNIT_RAW}
createSensorList[0x526A] = {name = "GPS Azimuth", unit = UNIT_RAW}
createSensorList[0x526B] = {name = "GPS HDOP", unit = UNIT_RAW}

-- ESC RPM
createSensorList[0x5130] = {name = "ESC1 RPM", unit = UNIT_RAW}
createSensorList[0x5131] = {name = "ESC2 RPM", unit = UNIT_RAW}
createSensorList[0x5132] = {name = "ESC3 RPM", unit = UNIT_RAW}
createSensorList[0x5133] = {name = "ESC4 RPM", unit = UNIT_RAW}

-- ESC Temperature
createSensorList[0x5140] = {name = "ESC1 Temp", unit = UNIT_RAW}
createSensorList[0x5141] = {name = "ESC2 Temp", unit = UNIT_RAW}
createSensorList[0x5142] = {name = "ESC3 Temp", unit = UNIT_RAW}
createSensorList[0x5143] = {name = "ESC4 Temp", unit = UNIT_RAW}




local log = inavsuite.utils.log

local dropSensorList = {}

local renameSensorList = {}
renameSensorList[0x0210] = {name = "Voltage", onlyifname = "VFAS"}


frsky.createSensorCache = {}
frsky.dropSensorCache = {}
frsky.renameSensorCache = {}

local function createSensor(physId, primId, appId, frameValue)

    if inavsuite.session.apiVersion == nil then return end

    if createSensorList[appId] ~= nil then

        local v = createSensorList[appId]

        if frsky.createSensorCache[appId] == nil then

            frsky.createSensorCache[appId] = system.getSource({category = CATEGORY_TELEMETRY_SENSOR, appId = appId})

            if frsky.createSensorCache[appId] == nil then

                log("Creating sensor: " .. v.name, "info")

                frsky.createSensorCache[appId] = model.createSensor()
                frsky.createSensorCache[appId]:name(v.name)
                frsky.createSensorCache[appId]:type(SENSOR_TYPE_SPORT)
                frsky.createSensorCache[appId]:appId(appId)
                frsky.createSensorCache[appId]:physId(physId)
                frsky.createSensorCache[appId]:module(inavsuite.session.telemetrySensor:module())

                frsky.createSensorCache[appId]:minimum(min or -1000000000)
                frsky.createSensorCache[appId]:maximum(max or 2147483647)
                if v.unit ~= nil then
                    frsky.createSensorCache[appId]:unit(v.unit)
                    frsky.createSensorCache[appId]:protocolUnit(v.unit)
                end
                if v.decimals ~= nil then
                    frsky.createSensorCache[appId]:decimals(v.decimals)
                    frsky.createSensorCache[appId]:protocolDecimals(v.decimals)
                end
                if v.minimum ~= nil then frsky.createSensorCache[appId]:minimum(v.minimum) end
                if v.maximum ~= nil then frsky.createSensorCache[appId]:maximum(v.maximum) end

            end

        end
    end

end

local function dropSensor(physId, primId, appId, frameValue)

    if inavsuite.session.apiVersion == nil then return end

    if inavsuite.session.apiVersion >= 2.06 then return end

    if dropSensorList[appId] ~= nil then
        local v = dropSensorList[appId]

        if frsky.dropSensorCache[appId] == nil then
            frsky.dropSensorCache[appId] = system.getSource({category = CATEGORY_TELEMETRY_SENSOR, appId = appId})

            if frsky.dropSensorCache[appId] ~= nil then
                log("Drop sensor: " .. v.name, "info")
                frsky.dropSensorCache[appId]:drop()
            end

        end

    end

end

local function renameSensor(physId, primId, appId, frameValue)

    if inavsuite.session.apiVersion == nil then return end

    if renameSensorList[appId] ~= nil then
        local v = renameSensorList[appId]

        if frsky.renameSensorCache[appId] == nil then
            frsky.renameSensorCache[appId] = system.getSource({category = CATEGORY_TELEMETRY_SENSOR, appId = appId})

            if frsky.renameSensorCache[appId] ~= nil then
                if frsky.renameSensorCache[appId]:name() == v.onlyifname then
                    log("Rename sensor: " .. v.name, "info")
                    frsky.renameSensorCache[appId]:name(v.name)
                end
            end

        end

    end

end

local function ensureSensorsFromConfig()

    if frsky._provisioned then return end

    local cfg = inavsuite and inavsuite.session and inavsuite.session.telemetryConfig
    if not cfg then return end

    local telePhysId, teleModule
    if sensorTlm then
        telePhysId = 27
        teleModule = sensorTlm:module()
    else
        return
    end

    for _, sid in ipairs(cfg) do
        local apps = sidLookup[sid]
        if apps then
            for _, hex in ipairs(apps) do
                local appId = tonumber(hex)
                if appId then

                    local meta = createSensorList[appId]
                    if meta then
                        if frsky.createSensorCache[appId] == nil then frsky.createSensorCache[appId] = system.getSource({category = CATEGORY_TELEMETRY_SENSOR, appId = appId}) end
                        if frsky.createSensorCache[appId] == nil then
                            log("Creating sensor: " .. meta.name, "info")
                            local s = model.createSensor()
                            s:name(meta.name)
                            s:appId(appId)
                            if telePhysId then s:physId(telePhysId) end
                            if teleModule then s:module(teleModule) end

                            s:minimum(-1000000000)
                            s:maximum(2147483647)
                            if meta.unit ~= nil then
                                s:unit(meta.unit)
                                s:protocolUnit(meta.unit)
                            end
                            if meta.decimals ~= nil then
                                s:decimals(meta.decimals)
                                s:protocolDecimals(meta.decimals)
                            end
                            if meta.minimum ~= nil then s:minimum(meta.minimum) end
                            if meta.maximum ~= nil then s:maximum(meta.maximum) end
                            frsky.createSensorCache[appId] = s
                        end
                    end

                    local rn = renameSensorList[appId]
                    if rn then
                        if frsky.renameSensorCache[appId] == nil then frsky.renameSensorCache[appId] = system.getSource({category = CATEGORY_TELEMETRY_SENSOR, appId = appId}) end
                        local src = frsky.renameSensorCache[appId]
                        if src and src:name() == rn.onlyifname then
                            log("Rename sensor: " .. rn.name, "info")
                            src:name(rn.name)
                        end
                    end

                    if inavsuite.session.apiVersion ~= nil and inavsuite.session.apiVersion < 12.08 then
                        local drop = dropSensorList[appId]
                        if drop then
                            if frsky.dropSensorCache[appId] == nil then frsky.dropSensorCache[appId] = system.getSource({category = CATEGORY_TELEMETRY_SENSOR, appId = appId}) end
                            local src = frsky.dropSensorCache[appId]
                            if src then
                                log("Drop sensor: " .. drop.name, "info")
                                src:drop()
                                frsky.dropSensorCache[appId] = nil
                            end
                        end
                    end

                end
            end
        end
    end
    frsky._provisioned = true
end

function frsky.wakeup()

    if not inavsuite.session.isConnected then return end
    if inavsuite.tasks and inavsuite.tasks.onconnect and inavsuite.tasks.onconnect.active and inavsuite.tasks.onconnect.active() then return end

    if not sensorTlm then
        sensorTlm = sport.getSensor()
        sensorTlm:module(inavsuite.session.telemetrySensor:module())

        if not sensorTlm then return false end
    end

    local function clearCaches()
        frsky.createSensorCache = {}
        frsky.renameSensorCache = {}
        frsky.dropSensorCache = {}
    end

    if os.clock() - lastCacheFlushTime >= cacheExpireTime then
        clearCaches()
        lastCacheFlushTime = os.clock()
    end

    if not inavsuite.session.telemetryState or not inavsuite.session.telemetrySensor then clearCaches() end

    ensureSensorsFromConfig()

end

function frsky.reset()
    frsky.createSensorCache = {}
    frsky.dropSensorCache = {}
    frsky.renameSensorCache = {}
    frsky._provisioned = false
end

return frsky
