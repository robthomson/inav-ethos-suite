--[[
  Copyright (C) 2025 Inav Project
  GPLv3 — https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local inavsuite = require("inavsuite")

local MSP_PROTOCOL_VERSION = inavsuite.config.mspProtocolVersion or 1

local arg = {...}
local config = arg[1]

local msp = {}

msp.activeProtocol = nil
msp.onConnectChecksInit = true

local protocol = assert(loadfile("SCRIPTS:/" .. inavsuite.config.baseDir .. "/tasks/msp/protocols.lua"))()

local telemetryTypeChanged = false

msp.mspQueue = nil

msp.protocol = protocol.getProtocol()

msp.protocolTransports = {}
for i, v in pairs(protocol.getTransports()) do msp.protocolTransports[i] = assert(loadfile(v))() end

local transport = msp.protocolTransports[msp.protocol.mspProtocol]
msp.protocol.mspRead = transport.mspRead
msp.protocol.mspSend = transport.mspSend
msp.protocol.mspWrite = transport.mspWrite
msp.protocol.mspPoll = transport.mspPoll

msp.mspQueue = assert(loadfile("SCRIPTS:/" .. inavsuite.config.baseDir .. "/tasks/msp/mspQueue.lua"))()
msp.mspQueue.maxRetries = msp.protocol.maxRetries
msp.mspQueue.loopInterval = 0.031
msp.mspQueue.copyOnAdd = true
msp.mspQueue.timeout = 2.0

msp.mspHelper = assert(loadfile("SCRIPTS:/" .. inavsuite.config.baseDir .. "/tasks/msp/mspHelper.lua"))()
msp.api = assert(loadfile("SCRIPTS:/" .. inavsuite.config.baseDir .. "/tasks/msp/api.lua"))()
msp.common = assert(loadfile("SCRIPTS:/" .. inavsuite.config.baseDir .. "/tasks/msp/common.lua"))()
msp.common.setProtocolVersion(MSP_PROTOCOL_VERSION or 1)


local delayDuration = 2
local delayStartTime = nil
local delayPending = false

function msp.wakeup()

    if inavsuite.session.telemetrySensor == nil then return end

    if inavsuite.session.resetMSP and not delayPending then
        delayStartTime = os.clock()
        delayPending = true
        inavsuite.session.resetMSP = false
        inavsuite.utils.log("Delaying msp wakeup for " .. delayDuration .. " seconds", "info")
        return
    end

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

    if telemetryTypeChanged == true then

        msp.protocol = protocol.getProtocol()

        local transport = msp.protocolTransports[msp.protocol.mspProtocol]
        msp.protocol.mspRead = transport.mspRead
        msp.protocol.mspSend = transport.mspSend
        msp.protocol.mspWrite = transport.mspWrite
        msp.protocol.mspPoll = transport.mspPoll

        inavsuite.utils.session()
        msp.onConnectChecksInit = true
        telemetryTypeChanged = false
    end

    if inavsuite.session.telemetrySensor ~= nil and inavsuite.session.telemetryState == false then
        inavsuite.utils.session()
        msp.onConnectChecksInit = true
    end

    local state

    if inavsuite.session.telemetrySensor then
        state = inavsuite.session.telemetryState
    else
        state = false
    end

    if state == true then
        msp.mspQueue:processQueue()
    else
        msp.mspQueue:clear()
    end

end

function msp.setTelemetryTypeChanged() telemetryTypeChanged = true end

function msp.reset()
    inavsuite.tasks.msp.mspQueue:clear()
    msp.activeProtocol = nil
    msp.onConnectChecksInit = true
    delayStartTime = nil
    delayPending = false
    if transport and transport.reset then transport.reset() end
end

return msp
