--[[
  Copyright (C) 2025 Rotorflight Project
  GPLv3 — https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local inavsuite = require("inavsuite")

local arg = {...}
local config = arg[1]

local simSensors = inavsuite.utils.simSensors
local round = inavsuite.utils.round

local telemetry = {}

local telemetryTypeChanged = false

local os_clock = os.clock
local sys_getSource = system.getSource
local sys_getVersion = system.getVersion
local t_insert = table.insert
local t_remove = table.remove
local t_pairs = pairs
local t_ipairs = ipairs
local t_type = type

local protocol, crsfSOURCE

local sensors = setmetatable({}, {__mode = "v"})

local cache_hits, cache_misses = 0, 0

local HOT_SIZE = 20
local hot_list, hot_index = {}, {}

local function rebuild_hot_index()
    hot_index = {}
    for i, k in t_ipairs(hot_list) do hot_index[k] = i end
end

local function mark_hot(key)
    local idx = hot_index[key]

    if idx and idx >= 1 and idx <= #hot_list then
        t_remove(hot_list, idx)
        rebuild_hot_index()

    elseif #hot_list >= HOT_SIZE then
        local old = t_remove(hot_list, 1)
        if old ~= nil then
            hot_index[old] = nil
            sensors[old] = nil
        end
        rebuild_hot_index()
    end

    t_insert(hot_list, key)
    hot_index[key] = #hot_list
end

function telemetry._debugStats() return {hits = cache_hits, misses = cache_misses, hot_size = #hot_list, hot_list = hot_list} end

local sensorRateLimit = os_clock()
local ONCHANGE_RATE = 5

local lastValidationResult = nil
local lastValidationTime = 0
local VALIDATION_RATE_LIMIT = 10

local telemetryState = false

local lastSensorValues = {}

telemetry.sensorStats = {}

local memo_listSensors, memo_listSwitchSensors, memo_listAudioUnits = nil, nil, nil

local filteredOnchangeSensors = nil
local onchangeInitialized = false

local sensorTable = {
    rssi = {
        name = "@i18n(sensors.rssi)@",
        mandatory = true,
        stats = true,
        switch_alerts = true,
        unit = UNIT_PERCENT,
        unit_string = "%",
        sensors = {
            sim = {{appId = 0xF010, subId = 0}},
            sport = {{appId = 0xF010, subId = 0}},
            crsf = {{crsfId = 0x14, subId = 2}},
            crsfLegacy = {{crsfId = 0x14, subIdStart = 0, subIdEnd = 1}}
        }
    },

    link = {
        name = "@i18n(sensors.link)@",
        mandatory = true,
        stats = true,
        switch_alerts = true,
        unit = UNIT_DB,
        unit_string = "dB",
        sensors = {
            sim = {{appId = 0xF101, subId = 0}},
            sport = {{appId = 0xF101, subId = 0}, "RSSI"},
            crsf = {{crsfId = 0x14, subIdStart = 0, subIdEnd = 1}, "Rx RSSI1"},
            crsfLegacy = {{crsfId = 0x14, subIdStart = 0, subIdEnd = 1}, "RSSI 1", "RSSI 2"}
        }
    },
}

function telemetry.getSensorProtocol() return protocol end

local function build_memo_lists()

    memo_listSensors, memo_listSwitchSensors, memo_listAudioUnits = {}, {}, {}
    for key, sensor in t_pairs(sensorTable) do
        t_insert(memo_listSensors, {key = key, name = sensor.name, mandatory = sensor.mandatory, set_telemetry_sensors = sensor.set_telemetry_sensors})
        if sensor.switch_alerts then t_insert(memo_listSwitchSensors, {key = key, name = sensor.name, mandatory = sensor.mandatory, set_telemetry_sensors = sensor.set_telemetry_sensors}) end
        if sensor.unit then memo_listAudioUnits[key] = sensor.unit end
    end
end

function telemetry.listSensors()
    if not memo_listSensors then build_memo_lists() end
    return memo_listSensors
end

function telemetry.listSensorAudioUnits()
    if not memo_listAudioUnits then build_memo_lists() end
    return memo_listAudioUnits
end

function telemetry.listSwitchSensors()
    if not memo_listSwitchSensors then build_memo_lists() end
    return memo_listSwitchSensors
end

local function checkCondition(sensorEntry)
    local sess = inavsuite.session
    if not (sess and sess.apiVersion) then return true end
    local roundedApiVersion = round(sess.apiVersion, 2)
    local gt, lt = sensorEntry.mspgt, sensorEntry.msplt
    if gt then return roundedApiVersion >= round(gt, 2) end
    if lt then return roundedApiVersion <= round(lt, 2) end
    return true
end

function telemetry.getSensorSource(name)

    local entry = sensorTable[name]
    if not entry then return nil end

    local src = sensors[name]
    if src then
        cache_hits = cache_hits + 1
        mark_hot(name)
        return src
    end

    local isSim = sys_getVersion().simulation == true

    if isSim then
        protocol = "sport"
        for _, sensor in t_ipairs(entry.sensors.sim or {}) do
            if sensor.uid then
                local sensorQ = {appId = sensor.uid, category = CATEGORY_TELEMETRY_SENSOR}
                local source = sys_getSource(sensorQ)
                if source then
                    cache_misses = cache_misses + 1
                    sensors[name] = source
                    mark_hot(name)
                    return source
                end
            else
                if checkCondition(sensor) and t_type(sensor) == "table" then
                    sensor.mspgt, sensor.msplt = nil, nil
                    local source = sys_getSource(sensor)
                    if source then
                        cache_misses = cache_misses + 1
                        sensors[name] = source
                        mark_hot(name)
                        return source
                    end
                end
            end
        end

    elseif inavsuite.session.telemetryType == "crsf" then

        if not crsfSOURCE then crsfSOURCE = sys_getSource({category = CATEGORY_TELEMETRY_SENSOR, appId = 0xEE01}) end
        if crsfSOURCE then
            protocol = "crsf"
            for _, sensor in t_ipairs(entry.sensors.crsf or {}) do
                if checkCondition(sensor) and t_type(sensor) == "table" then
                    sensor.mspgt, sensor.msplt = nil, nil
                    local source = sys_getSource(sensor)
                    if source then
                        cache_misses = cache_misses + 1
                        sensors[name] = source
                        mark_hot(name)
                        return source
                    end
                end
            end
        else
            protocol = "crsfLegacy"
            for _, sensor in t_ipairs(entry.sensors.crsfLegacy or {}) do
                local source = sys_getSource(sensor)
                if source then
                    cache_misses = cache_misses + 1
                    sensors[name] = source
                    mark_hot(name)
                    return source
                end
            end
        end

    elseif inavsuite.session.telemetryType == "sport" then
        protocol = "sport"
        for _, sensor in t_ipairs(entry.sensors.sport or {}) do
            if checkCondition(sensor) and t_type(sensor) == "table" then
                sensor.mspgt, sensor.msplt = nil, nil
                local source = sys_getSource(sensor)
                if source then
                    cache_misses = cache_misses + 1
                    sensors[name] = source
                    mark_hot(name)
                    return source
                end
            end
        end
    else
        protocol = "unknown"
    end

    return nil
end

function telemetry.getSensor(sensorKey, paramMin, paramMax, paramThresholds)
    local entry = sensorTable[sensorKey]

    if entry and t_type(entry.source) == "function" then
        local src = entry.source()
        if src and t_type(src.value) == "function" then
            local value, major, minor = src.value()
            major = major or entry.unit
            if entry.localizations and t_type(entry.localizations) == "function" then value, major, minor = entry.localizations(value) end
            return value, major, minor
        end
    end

    local source = telemetry.getSensorSource(sensorKey)
    if not source then return nil end

    local value = source:value()
    local major = entry and entry.unit or nil
    local minor = nil

    if entry and entry.transform and t_type(entry.transform) == "function" then value = entry.transform(value) end

    if entry and entry.localizations and t_type(entry.localizations) == "function" then return entry.localizations(value, paramMin, paramMax, paramThresholds) end

    return value, major, minor, paramMin, paramMax, paramThresholds
end

function telemetry.validateSensors(returnValid)
    local now = os_clock()
    if (now - lastValidationTime) < VALIDATION_RATE_LIMIT then return lastValidationResult or true end
    lastValidationTime = now

    if not inavsuite.session.telemetryState then
        if not memo_listSensors then build_memo_lists() end
        lastValidationResult = memo_listSensors
        return memo_listSensors
    end

    local resultSensors = {}
    for key, sensor in t_pairs(sensorTable) do
        local sensorSource = telemetry.getSensorSource(key)
        local isValid = (sensorSource ~= nil and sensorSource:state() ~= false)
        if returnValid then
            if isValid then t_insert(resultSensors, {key = key, name = sensor.name}) end
        else
            if not isValid and sensor.mandatory ~= false then t_insert(resultSensors, {key = key, name = sensor.name}) end
        end
    end

    lastValidationResult = resultSensors
    return resultSensors
end

function telemetry.simSensors(returnValid)
    local result = {}
    for _, sensor in t_pairs(sensorTable) do
        local firstSim = sensor.sensors.sim and sensor.sensors.sim[1]
        if firstSim then t_insert(result, {name = sensor.name, sensor = firstSim}) end
    end
    return result
end

function telemetry.active() return inavsuite.session.telemetryState or false end

function telemetry.reset()
    protocol, crsfSOURCE = nil, nil
    sensors = setmetatable({}, {__mode = "v"})
    hot_list, hot_index = {}, {}
    filteredOnchangeSensors = nil
    lastSensorValues = {}
    onchangeInitialized = false
    sensorRateLimit = os_clock()
    lastValidationResult = nil
    lastValidationTime = 0
    cache_hits, cache_misses = 0, 0
    memo_listSensors, memo_listSwitchSensors, memo_listAudioUnits = nil, nil, nil
end

function telemetry.wakeup()
    local now = os_clock()

    if inavsuite.session.mspBusy then return end

    if inavsuite.tasks and inavsuite.tasks.onconnect and inavsuite.tasks.onconnect.active and inavsuite.tasks.onconnect.active() then return end

    if (now - sensorRateLimit) >= ONCHANGE_RATE then
        sensorRateLimit = now

        if not filteredOnchangeSensors then
            filteredOnchangeSensors = {}
            for sensorKey, sensorDef in t_pairs(sensorTable) do if t_type(sensorDef.onchange) == "function" then filteredOnchangeSensors[sensorKey] = sensorDef end end
            onchangeInitialized = true
        end

        if onchangeInitialized then
            onchangeInitialized = false
        else
            for sensorKey, sensorDef in t_pairs(filteredOnchangeSensors) do
                local source = telemetry.getSensorSource(sensorKey)
                if source and source:state() then
                    local val = source:value()
                    if lastSensorValues[sensorKey] ~= val then
                        sensorDef.onchange(val)
                        lastSensorValues[sensorKey] = val
                    end
                end
            end
        end
    end

    if (not inavsuite.session.telemetryState) then telemetry.reset() end
end

function telemetry.getSensorStats(sensorKey) return telemetry.sensorStats[sensorKey] or {min = nil, max = nil} end

function telemetry.setTelemetryTypeChanged()
    telemetryTypeChanged = true
    telemetry.reset()
end

telemetry.sensorTable = sensorTable

return telemetry
