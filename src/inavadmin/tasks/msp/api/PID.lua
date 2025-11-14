--[[
  Copyright (C) 2025 Inav Project
  GPLv3 — https://www.gnu.org/licenses/gpl-3.0.en.html
]] --

local inavadmin = require("inavadmin")
local core = assert(loadfile("SCRIPTS:/" .. inavadmin.config.baseDir .. "/tasks/msp/api_core.lua"))()

local API_NAME = "PID"
local MSP_API_CMD_READ = 0x2030
local MSP_API_CMD_WRITE = 0x2031
local MSP_REBUILD_ON_WRITE = false

-- LuaFormatter off
local MSP_API_STRUCTURE_READ_DATA = {
    -- PID 0
    {field = "pid_0_P",  type = "U8", apiVersion = 2.04, simResponse = {15}, min = 0, max = 255, default = 0, help = "@i18n(api.PID_TUNING.pid_0_P)@"},
    {field = "pid_0_I",  type = "U8", apiVersion = 2.04, simResponse = {3},  min = 0, max = 255, default = 0, help = "@i18n(api.PID_TUNING.pid_0_I)@"},
    {field = "pid_0_D",  type = "U8", apiVersion = 2.04, simResponse = {7},  min = 0, max = 255, default = 0, help = "@i18n(api.PID_TUNING.pid_0_D)@"},
    {field = "pid_0_FF", type = "U8", apiVersion = 2.04, simResponse = {50}, min = 0, max = 255, default = 0, help = "@i18n(api.PID_TUNING.pid_0_F)@"},

    -- PID 1
    {field = "pid_1_P",  type = "U8", apiVersion = 2.04, simResponse = {15}, min = 0, max = 255, default = 0, help = "@i18n(api.PID_TUNING.pid_1_P)@"},
    {field = "pid_1_I",  type = "U8", apiVersion = 2.04, simResponse = {5},  min = 0, max = 255, default = 0, help = "@i18n(api.PID_TUNING.pid_1_I)@"},
    {field = "pid_1_D",  type = "U8", apiVersion = 2.04, simResponse = {5},  min = 0, max = 255, default = 0, help = "@i18n(api.PID_TUNING.pid_1_D)@"},
    {field = "pid_1_FF", type = "U8", apiVersion = 2.04, simResponse = {70}, min = 0, max = 255, default = 0, help = "@i18n(api.PID_TUNING.pid_1_F)@"},

    -- PID 2
    {field = "pid_2_P",  type = "U8", apiVersion = 2.04, simResponse = {20}, min = 0, max = 255, default = 0, help = "@i18n(api.PID_TUNING.pid_2_P)@"},
    {field = "pid_2_I",  type = "U8", apiVersion = 2.04, simResponse = {0},  min = 0, max = 255, default = 0, help = "@i18n(api.PID_TUNING.pid_2_I)@"},
    {field = "pid_2_D",  type = "U8", apiVersion = 2.04, simResponse = {0},  min = 0, max = 255, default = 0, help = "@i18n(api.PID_TUNING.pid_2_D)@"},
    {field = "pid_2_FF", type = "U8", apiVersion = 2.04, simResponse = {100},min = 0, max = 255, default = 0, help = "@i18n(api.PID_TUNING.pid_2_F)@"},

    -- PID 3
    {field = "pid_3_P",  type = "U8", apiVersion = 2.04, simResponse = {35}, min = 0, max = 255, default = 0, help = "@i18n(api.PID_TUNING.pid_3_P)@"},
    {field = "pid_3_I",  type = "U8", apiVersion = 2.04, simResponse = {5},  min = 0, max = 255, default = 0, help = "@i18n(api.PID_TUNING.pid_3_I)@"},
    {field = "pid_3_D",  type = "U8", apiVersion = 2.04, simResponse = {10}, min = 0, max = 255, default = 0, help = "@i18n(api.PID_TUNING.pid_3_D)@"},
    {field = "pid_3_FF", type = "U8", apiVersion = 2.04, simResponse = {30}, min = 0, max = 255, default = 0, help = "@i18n(api.PID_TUNING.pid_3_F)@"},

    -- PID 4
    {field = "pid_4_P",  type = "U8", apiVersion = 2.04, simResponse = {70}, min = 0, max = 255, default = 0, help = "@i18n(api.PID_TUNING.pid_4_P)@"},
    {field = "pid_4_I",  type = "U8", apiVersion = 2.04, simResponse = {5},  min = 0, max = 255, default = 0, help = "@i18n(api.PID_TUNING.pid_4_I)@"},
    {field = "pid_4_D",  type = "U8", apiVersion = 2.04, simResponse = {8},  min = 0, max = 255, default = 0, help = "@i18n(api.PID_TUNING.pid_4_D)@"},
    {field = "pid_4_FF", type = "U8", apiVersion = 2.04, simResponse = {0},  min = 0, max = 255, default = 0, help = "@i18n(api.PID_TUNING.pid_4_F)@"},

    -- PID 5
    {field = "pid_5_P",  type = "U8", apiVersion = 2.04, simResponse = {0}, min = 0, max = 255, default = 0},
    {field = "pid_5_I",  type = "U8", apiVersion = 2.04, simResponse = {0}, min = 0, max = 255, default = 0},
    {field = "pid_5_D",  type = "U8", apiVersion = 2.04, simResponse = {0}, min = 0, max = 255, default = 0},
    {field = "pid_5_FF", type = "U8", apiVersion = 2.04, simResponse = {0}, min = 0, max = 255, default = 0},

    -- PID 6
    {field = "pid_6_P",  type = "U8", apiVersion = 2.04, simResponse = {0}, min = 0, max = 255, default = 0},
    {field = "pid_6_I",  type = "U8", apiVersion = 2.04, simResponse = {0}, min = 0, max = 255, default = 0},
    {field = "pid_6_D",  type = "U8", apiVersion = 2.04, simResponse = {0}, min = 0, max = 255, default = 0},
    {field = "pid_6_FF", type = "U8", apiVersion = 2.04, simResponse = {0}, min = 0, max = 255, default = 0},

    -- PID 7
    {field = "pid_7_P",  type = "U8", apiVersion = 2.04, simResponse = {20}, min = 0, max = 255, default = 0},
    {field = "pid_7_I",  type = "U8", apiVersion = 2.04, simResponse = {5},  min = 0, max = 255, default = 0},
    {field = "pid_7_D",  type = "U8", apiVersion = 2.04, simResponse = {75}, min = 0, max = 255, default = 0},
    {field = "pid_7_FF", type = "U8", apiVersion = 2.04, simResponse = {0},  min = 0, max = 255, default = 0},

    -- PID 8
    {field = "pid_8_P",  type = "U8", apiVersion = 2.04, simResponse = {60}, min = 0, max = 255, default = 0},
    {field = "pid_8_I",  type = "U8", apiVersion = 2.04, simResponse = {0},  min = 0, max = 255, default = 0},
    {field = "pid_8_D",  type = "U8", apiVersion = 2.04, simResponse = {0},  min = 0, max = 255, default = 0},
    {field = "pid_8_FF", type = "U8", apiVersion = 2.04, simResponse = {0},  min = 0, max = 255, default = 0},

    -- PID 9
    {field = "pid_9_P",  type = "U8", apiVersion = 2.04, simResponse = {0}, min = 0, max = 255, default = 0},
    {field = "pid_9_I",  type = "U8", apiVersion = 2.04, simResponse = {0}, min = 0, max = 255, default = 0},
    {field = "pid_9_D",  type = "U8", apiVersion = 2.04, simResponse = {0}, min = 0, max = 255, default = 0},
    {field = "pid_9_FF", type = "U8", apiVersion = 2.04, simResponse = {0}, min = 0, max = 255, default = 0},

    -- PID 10
    {field = "pid_10_P",  type = "U8", apiVersion = 2.04, simResponse = {30}, min = 0, max = 255, default = 0},
    {field = "pid_10_I",  type = "U8", apiVersion = 2.04, simResponse = {2},  min = 0, max = 255, default = 0},
    {field = "pid_10_D",  type = "U8", apiVersion = 2.04, simResponse = {0},  min = 0, max = 255, default = 0},
    {field = "pid_10_FF", type = "U8", apiVersion = 2.04, simResponse = {0},  min = 0, max = 255, default = 0},
}

-- LuaFormatter on

local MSP_API_STRUCTURE_READ, MSP_MIN_BYTES, MSP_API_SIMULATOR_RESPONSE = core.prepareStructureData(MSP_API_STRUCTURE_READ_DATA)

local MSP_API_STRUCTURE_WRITE = MSP_API_STRUCTURE_READ

local mspData = nil
local mspWriteComplete = false
local payloadData = {}
local defaultData = {}

local handlers = core.createHandlers()

local MSP_API_UUID
local MSP_API_MSG_TIMEOUT

local lastWriteUUID = nil

local writeDoneRegistry = setmetatable({}, {__mode = "kv"})

local function processReplyStaticRead(self, buf)
    core.parseMSPData(API_NAME, buf, self.structure, nil, nil, function(result)
        mspData = result
        if #buf >= (self.minBytes or 0) then
            local getComplete = self.getCompleteHandler
            if getComplete then
                local complete = getComplete()
                if complete then complete(self, buf) end
            end
        end
    end)
end

local function processReplyStaticWrite(self, buf)
    mspWriteComplete = true

    if self.uuid then writeDoneRegistry[self.uuid] = true end

    local getComplete = self.getCompleteHandler
    if getComplete then
        local complete = getComplete()
        if complete then complete(self, buf) end
    end
end

local function errorHandlerStatic(self, buf)
    local getError = self.getErrorHandler
    if getError then
        local err = getError()
        if err then err(self, buf) end
    end
end

local function read()
    if MSP_API_CMD_READ == nil then
        inavadmin.utils.log("No value set for MSP_API_CMD_READ", "debug")
        return
    end

    local message = {command = MSP_API_CMD_READ, structure = MSP_API_STRUCTURE_READ, minBytes = MSP_MIN_BYTES, processReply = processReplyStaticRead, errorHandler = errorHandlerStatic, simulatorResponse = MSP_API_SIMULATOR_RESPONSE, uuid = MSP_API_UUID, timeout = MSP_API_MSG_TIMEOUT, getCompleteHandler = handlers.getCompleteHandler, getErrorHandler = handlers.getErrorHandler, mspData = nil}
    inavadmin.tasks.msp.mspQueue:add(message)
end

local function write(suppliedPayload)
    if MSP_API_CMD_WRITE == nil then
        inavadmin.utils.log("No value set for MSP_API_CMD_WRITE", "debug")
        return
    end

    local payload = suppliedPayload or core.buildWritePayload(API_NAME, payloadData, MSP_API_STRUCTURE_WRITE, MSP_REBUILD_ON_WRITE)

    local uuid = MSP_API_UUID or inavadmin.utils and inavadmin.utils.uuid and inavadmin.utils.uuid() or tostring(os.clock())
    lastWriteUUID = uuid

    local message = {command = MSP_API_CMD_WRITE, payload = payload, processReply = processReplyStaticWrite, errorHandler = errorHandlerStatic, simulatorResponse = {}, uuid = uuid, timeout = MSP_API_MSG_TIMEOUT, getCompleteHandler = handlers.getCompleteHandler, getErrorHandler = handlers.getErrorHandler}

    inavadmin.tasks.msp.mspQueue:add(message)
end

local function readValue(fieldName)
    if mspData and mspData['parsed'][fieldName] ~= nil then return mspData['parsed'][fieldName] end
    return nil
end

local function setValue(fieldName, value) payloadData[fieldName] = value end

local function readComplete() return mspData ~= nil and #mspData['buffer'] >= MSP_MIN_BYTES end

local function writeComplete() return mspWriteComplete end

local function resetWriteStatus() mspWriteComplete = false end

local function data() return mspData end

local function setUUID(uuid) MSP_API_UUID = uuid end

local function setTimeout(timeout) MSP_API_MSG_TIMEOUT = timeout end

return {read = read, write = write, readComplete = readComplete, writeComplete = writeComplete, readValue = readValue, setValue = setValue, resetWriteStatus = resetWriteStatus, setCompleteHandler = handlers.setCompleteHandler, setErrorHandler = handlers.setErrorHandler, data = data, setUUID = setUUID, setTimeout = setTimeout}
