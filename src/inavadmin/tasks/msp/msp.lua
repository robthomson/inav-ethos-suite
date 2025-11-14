--[[
  Copyright (C) 2025 Inav Project
  GPLv3 — https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local inavadmin = require("inavadmin")

local MSP_PROTOCOL_VERSION = inavadmin.config.mspProtocolVersion or 1

local arg = {...}
local config = arg[1]

local msp = {}

msp.activeProtocol = nil
msp.onConnectChecksInit = true

local protocol = assert(loadfile("SCRIPTS:/" .. inavadmin.config.baseDir .. "/tasks/msp/protocols.lua"))()

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

msp.mspQueue = assert(loadfile("SCRIPTS:/" .. inavadmin.config.baseDir .. "/tasks/msp/mspQueue.lua"))()
msp.mspQueue.maxRetries = msp.protocol.maxRetries
msp.mspQueue.loopInterval = 0.031
msp.mspQueue.copyOnAdd = true
msp.mspQueue.timeout = 2.0

msp.mspHelper = assert(loadfile("SCRIPTS:/" .. inavadmin.config.baseDir .. "/tasks/msp/mspHelper.lua"))()
msp.api = assert(loadfile("SCRIPTS:/" .. inavadmin.config.baseDir .. "/tasks/msp/api.lua"))()
msp.common = assert(loadfile("SCRIPTS:/" .. inavadmin.config.baseDir .. "/tasks/msp/common.lua"))()
msp.common.setProtocolVersion(MSP_PROTOCOL_VERSION or 1)


local delayDuration = 2
local delayStartTime = nil
local delayPending = false

function msp.wakeup()

    if inavadmin.session.telemetrySensor == nil then return end

    if inavadmin.session.resetMSP and not delayPending then
        delayStartTime = os.clock()
        delayPending = true
        inavadmin.session.resetMSP = false
        inavadmin.utils.log("Delaying msp wakeup for " .. delayDuration .. " seconds", "info")
        return
    end

    if delayPending then
        if os.clock() - delayStartTime >= delayDuration then
            inavadmin.utils.log("Delay complete; resuming msp wakeup", "info")
            delayPending = false
        else
            inavadmin.tasks.msp.mspQueue:clear()
            return
        end
    end

    msp.activeProtocol = inavadmin.session.telemetryType

    if telemetryTypeChanged == true then

        msp.protocol = protocol.getProtocol()

        local transport = msp.protocolTransports[msp.protocol.mspProtocol]
        msp.protocol.mspRead = transport.mspRead
        msp.protocol.mspSend = transport.mspSend
        msp.protocol.mspWrite = transport.mspWrite
        msp.protocol.mspPoll = transport.mspPoll

        inavadmin.utils.session()
        msp.onConnectChecksInit = true
        telemetryTypeChanged = false
    end

    if inavadmin.session.telemetrySensor ~= nil and inavadmin.session.telemetryState == false then
        inavadmin.utils.session()
        msp.onConnectChecksInit = true
    end

    local state

    if inavadmin.session.telemetrySensor then
        state = inavadmin.session.telemetryState
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
    inavadmin.tasks.msp.mspQueue:clear()
    msp.activeProtocol = nil
    msp.onConnectChecksInit = true
    delayStartTime = nil
    delayPending = false
end

return msp
