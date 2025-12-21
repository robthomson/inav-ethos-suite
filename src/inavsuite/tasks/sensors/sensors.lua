--[[
  Copyright (C) 2025 Inav Project
  GPLv3 — https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local inavsuite = require("inavsuite")

local arg = {...}
local config = arg[1]

local sensors = {}
local loadedSensorModule = nil

local delayDuration = 2
local delayStartTime = nil
local delayPending = false
local schedulerTick = 0

local msp = assert(loadfile("tasks/sensors/msp.lua"))(config)
local smart = assert(loadfile("tasks/sensors/smart.lua"))(config)
local log = inavsuite.utils.log
local tasks = inavsuite.tasks

local function loadSensorModule()
    if not tasks.active() then return nil end
    if not inavsuite.session.apiVersion then return nil end

    local protocol = tasks.msp.protocol.mspProtocol

    if system:getVersion().simulation == true then
        if not loadedSensorModule or loadedSensorModule.name ~= "sim" then loadedSensorModule = {name = "sim", module = assert(loadfile("tasks/sensors/sim.lua"))(config)} end
    elseif protocol == "crsf" then
        if not loadedSensorModule or loadedSensorModule.name ~= "elrs" then loadedSensorModule = {name = "elrs", module = assert(loadfile("tasks/sensors/elrs.lua"))(config)} end
    elseif protocol == "sport" then
        if inavsuite.utils.apiVersionCompare(">=", "2.06") then
            if not loadedSensorModule or loadedSensorModule.name ~= "frsky" then loadedSensorModule = {name = "frsky", module = assert(loadfile("tasks/sensors/frsky.lua"))(config)} end
        else
            if not loadedSensorModule or loadedSensorModule.name ~= "frsky_legacy" then loadedSensorModule = {name = "frsky_legacy", module = assert(loadfile("tasks/sensors/frsky_legacy.lua"))(config)} end
        end
    else
        loadedSensorModule = nil
    end
end

function sensors.wakeup()

    if inavsuite.tasks and inavsuite.tasks.onconnect and inavsuite.tasks.onconnect.active and inavsuite.tasks.onconnect.active() then return end

    schedulerTick = schedulerTick + 1

    if inavsuite.session.resetSensors and not delayPending then
        delayStartTime = os.clock()
        delayPending = true
        inavsuite.session.resetSensors = false

        log("Delaying sensor wakeup for " .. delayDuration .. " seconds", "info")
        return
    end

    if delayPending then
        if os.clock() - delayStartTime >= delayDuration then
            log("Delay complete; resuming sensor wakeup", "info")
            delayPending = false
        else
            return
        end
    end

    loadSensorModule()
    if loadedSensorModule and loadedSensorModule.module.wakeup then

        local cycleFlip = schedulerTick % 2
        if cycleFlip == 0 then
            loadedSensorModule.module.wakeup()
        else
            if inavsuite.session and inavsuite.session.isConnected then

                if msp and msp.wakeup then msp.wakeup() end

                if smart and smart.wakeup then smart.wakeup() end

            end
        end

    end

end

function sensors.reset()

    if loadedSensorModule and loadedSensorModule.module and loadedSensorModule.module.reset then loadedSensorModule.module.reset() end
    if smart and smart.reset then smart.reset() end
    if msp and msp.reset then msp.reset() end
    loadedSensorModule = nil

end

return sensors
