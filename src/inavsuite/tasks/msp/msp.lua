--[[
  Copyright (C) 2025 Inav Project
  GPLv3 — https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local inavsuite = require("inavsuite")

local MSP_PROTOCOL_VERSION = inavsuite.config.mspProtocolVersion or 1

local arg = {...}
local config = arg[1]

local msp = {}

msp.activeProtocol = nil      -- Current telemetry protocol type in use
msp.onConnectChecksInit = true -- Flag to run initial checks on telemetry connect

local protocol = assert(loadfile("SCRIPTS:/" .. inavsuite.config.baseDir .. "/tasks/msp/protocols.lua"))()

local telemetryTypeChanged = false -- Set when switching CRSF/S.Port/etc.

msp.mspQueue = nil

-- Protocol parameters for current telemetry type
msp.protocol = protocol.getProtocol()

-- Load all transport modules
msp.protocolTransports = {}
for i, v in pairs(protocol.getTransports()) do
    msp.protocolTransports[i] = assert(loadfile(v))()
end

-- Bind protocol transport functions
local transport = msp.protocolTransports[msp.protocol.mspProtocol]
msp.protocol.mspRead  = transport.mspRead
msp.protocol.mspSend  = transport.mspSend
msp.protocol.mspWrite = transport.mspWrite
msp.protocol.mspPoll  = transport.mspPoll

-- Load MSP queue with protocol settings
msp.mspQueue = assert(loadfile("SCRIPTS:/" .. inavsuite.config.baseDir .. "/tasks/msp/mspQueue.lua"))()
msp.mspQueue.maxRetries   = msp.protocol.maxRetries
msp.mspQueue.loopInterval = 0.031            -- Queue processing rate
msp.mspQueue.copyOnAdd    = true             -- Clone messages on enqueue
msp.mspQueue.timeout      = msp.protocol.mspQueueTimeout or 2.0

-- Load helpers and API handlers
msp.mspHelper = assert(loadfile("SCRIPTS:/" .. inavsuite.config.baseDir .. "/tasks/msp/mspHelper.lua"))()
msp.api       = assert(loadfile("SCRIPTS:/" .. inavsuite.config.baseDir .. "/tasks/msp/api.lua"))()
msp.common    = assert(loadfile("SCRIPTS:/" .. inavsuite.config.baseDir .. "/tasks/msp/common.lua"))()
msp.common.setProtocolVersion(MSP_PROTOCOL_VERSION or 1)

-- Delay handling for clean protocol reset
local delayDuration  = 2
local delayStartTime = nil
local delayPending   = false

-- Main MSP poll loop (called by script wakeups)
function msp.wakeup()

    -- Nothing to do if no telemetry sensor
    if inavsuite.session.telemetrySensor == nil then return end

    -- Apply delay after reset request
    if inavsuite.session.resetMSP and not delayPending then
        delayStartTime = os.clock()
        delayPending = true
        inavsuite.session.resetMSP = false
        inavsuite.utils.log("Delaying msp wakeup for " .. delayDuration .. " seconds", "info")
        return
    end

    -- Hold off processing while in delay period
    if delayPending then
        if os.clock() - delayStartTime >= delayDuration then
            inavsuite.utils.log("Delay complete; resuming msp wakeup", "info")
            delayPending = false
        else
            inavsuite.tasks.msp.mspQueue:clear()
            return
        end
    end

    msp.activeProtocol = inavsuite.session.telemetryType

    -- Telemetry type changed (e.g., CRSF <-> S.Port)
    if telemetryTypeChanged == true then

        msp.protocol = protocol.getProtocol()

        local transport = msp.protocolTransports[msp.protocol.mspProtocol]
        msp.protocol.mspRead  = transport.mspRead
        msp.protocol.mspSend  = transport.mspSend
        msp.protocol.mspWrite = transport.mspWrite
        msp.protocol.mspPoll  = transport.mspPoll

        inavsuite.utils.session()
        msp.onConnectChecksInit = true
        telemetryTypeChanged = false
    end

    -- If telemetry was disconnected, re-run init handlers
    if inavsuite.session.telemetrySensor ~= nil and inavsuite.session.telemetryState == false then
        inavsuite.utils.session()
        msp.onConnectChecksInit = true
    end

    -- Determine telemetry connection state
    local state
    if inavsuite.session.telemetrySensor then
        state = inavsuite.session.telemetryState
    else
        state = false
    end

    -- Run queue when connected, otherwise clear it
    if state == true then
        msp.mspQueue:processQueue()
    else
        msp.mspQueue:clear()
    end
end

-- Mark that protocol should be reloaded on next wakeup
function msp.setTelemetryTypeChanged()
    telemetryTypeChanged = true
end

-- Reset MSP state and transport
function msp.reset()
    inavsuite.tasks.msp.mspQueue:clear()
    msp.activeProtocol = nil
    msp.onConnectChecksInit = true
    delayStartTime = nil
    delayPending = false
    if transport and transport.reset then transport.reset() end
end

return msp